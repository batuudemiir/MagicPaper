import Foundation
import OSLog
import SwiftUI

// MARK: - Profile Type
enum ProfileType: String, Codable {
    case child = "child"
    case parent = "parent"
    
    var displayName: String {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        switch self {
        case .child: return isEnglish ? "Child" : "Çocuk"
        case .parent: return isEnglish ? "Parent" : "Ebeveyn"
        }
    }
    
    var icon: String {
        switch self {
        case .child: return "figure.child"
        case .parent: return "person.fill"
        }
    }
}

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var age: Int
    var profileType: ProfileType
    var imageFileName: String?
    var createdAt: Date
    /// "Neleri sever?" (FAZ 12): interest ids from the catalog vocabulary,
    /// e.g. `animals`. Kept even when the catalog stops offering one, so an
    /// edit never silently drops a parent's choice; `ChildInterests` decides
    /// what is shown and what reaches the engine.
    var interests: [String]

    init(id: UUID = UUID(), name: String = "", age: Int = 6, profileType: ProfileType = .child,
         imageFileName: String? = nil, interests: [String] = []) {
        self.id = id
        self.name = name
        self.age = age
        self.profileType = profileType
        self.imageFileName = imageFileName
        self.createdAt = Date()
        self.interests = interests
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, age, profileType, imageFileName, createdAt, interests
    }

    /// Hand-written so a profile saved before FAZ 12 still loads.
    ///
    /// `loadProfiles` decodes the whole list with `try?`: one missing key in
    /// the synthesised decoder would have emptied the list, and every child
    /// would have disappeared on the first launch after the update.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        age = try container.decode(Int.self, forKey: .age)
        profileType = try container.decode(ProfileType.self, forKey: .profileType)
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        interests = try container.decodeIfPresent([String].self, forKey: .interests) ?? []
    }
}

/// A profile never prints what it holds: `"\(profile)"` in a log line would
/// otherwise carry the child's name, age and interests.
extension UserProfile: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    var description: String { "UserProfile(\(profileType.rawValue))" }
    var debugDescription: String { description }
    var customMirror: Mirror { Mirror(self, children: ["profileType": profileType]) }
}

// MARK: - Profile Manager
@MainActor
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var profiles: [UserProfile] = []
    @Published var currentProfile: UserProfile?
    @Published var hasCompletedOnboarding: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let profilesKey = "user_profiles"
    private let currentProfileKey = "current_profile_id"
    private let onboardingKey = "has_completed_onboarding"

    /// Profile bookkeeping goes to the unified log, never to `print`.
    ///
    /// `print` writes to stdout, which on a device is captured verbatim into
    /// the shared device console — readable by anything attached, kept after
    /// the app quits, and swept up into diagnostic bundles. Two of the lines
    /// that used to live here interpolated `profile_<UUID>.jpg`, which is a
    /// pseudonymous child identifier: paired with the `read_history_<UUID>` and
    /// `mp_avatarColor_<UUID>` keys it links a specific child to what they read.
    ///
    /// Nothing below interpolates a name, an age or a file name. Counts are
    /// marked `.private` so the log does not state how many children live in
    /// the house; only genuinely non-identifying values are `.public`.
    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids",
        category: "profiles"
    )

    /// An error rendered without its `userInfo`.
    ///
    /// `\(error)` on a Foundation file error prints `NSFilePath`, and that path
    /// ends in `profile_<UUID>.jpg`. The domain and code say what went wrong
    /// without saying whose file it was.
    private static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        return "\(nsError.domain) \(nsError.code)"
    }

    private init() {
        Self.log.debug("ProfileManager starting")
        loadProfiles()
        loadOnboardingStatus()
        
        // Migrate from old single-profile system if needed
        migrateFromLegacyProfile()
    }
    
    // MARK: - Load/Save
    
    private func loadProfiles() {
        if let data = userDefaults.data(forKey: profilesKey),
           let savedProfiles = try? JSONDecoder().decode([UserProfile].self, from: data) {
            self.profiles = savedProfiles
            Self.log.debug("Profiles loaded: \(savedProfiles.count, privacy: .private)")
            
            // Load current profile
            if let currentProfileId = userDefaults.string(forKey: currentProfileKey),
               let uuid = UUID(uuidString: currentProfileId),
               let profile = profiles.first(where: { $0.id == uuid }) {
                self.currentProfile = profile
                Self.log.debug("Active profile restored")
            } else if let firstProfile = profiles.first {
                self.currentProfile = firstProfile
                Self.log.debug("First profile made active")
            }
        } else {
            self.profiles = []
            Self.log.debug("No stored profiles")
        }
    }
    
    private func saveProfiles() {
        // `try?` here meant a failed encode lost every profile with no trace.
        // Nothing can be done about it at runtime, but it must not be silent.
        do {
            let data = try JSONEncoder().encode(profiles)
            userDefaults.set(data, forKey: profilesKey)
            Self.log.debug("Profiles saved: \(self.profiles.count, privacy: .private)")
        } catch {
            // Not `\(error)`: `EncodingError.invalidValue` carries the offending
            // value, which here would be a child's name.
            assertionFailure("Profiles could not be encoded: \(Self.describe(error))")
            Self.log.error("Profiles could not be encoded: \(Self.describe(error), privacy: .public)")
        }
    }
    
    private func loadOnboardingStatus() {
        hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
        Self.log.debug("Onboarding completed: \(self.hasCompletedOnboarding, privacy: .public)")
    }
    
    // MARK: - Profile Management
    
    /// Creates a profile and returns it.
    ///
    /// Returning the profile matters: callers previously recovered it with
    /// `profiles.last`, which is only correct while this method happens to
    /// append.
    @discardableResult
    func createProfile(name: String, age: Int, profileType: ProfileType, image: UIImage? = nil,
                       interests: [String] = []) -> UserProfile {
        let profile = UserProfile(name: name, age: age, profileType: profileType, interests: interests)

        // Append BEFORE saving the image. `saveProfileImage` records the file
        // name on the stored profile by looking it up in `profiles`; called
        // first, that lookup failed silently and every profile created with a
        // photo wrote a JPEG to Documents that nothing ever referenced again.
        profiles.append(profile)
        if let image {
            saveProfileImage(image, for: profile.id)
        }
        saveProfiles()

        // Set as current if this is the only profile.
        if profiles.count == 1 {
            switchProfile(to: profile)
        }

        Self.log.debug("Profile created")
        return profiles.last ?? profile
    }
    
    /// Edits the stored profile.
    ///
    /// This is the seam where an age edit has to reach the child's character.
    /// `UserProfile.age` is what the parent sees; `CharacterIdentity.ageYears`
    /// is what every illustration request is conditioned on, and writing one
    /// without the other is how a six-year-old keeps being drawn as five.
    ///
    /// `ProfileCharacterSource.syncing(_:with:)` performs that reconciliation
    /// and is idempotent, so the wiring is a load-sync-save around this call.
    /// It is deliberately not done here yet: the only character store today is
    /// `FileCharacterStore`, whose lifecycle belongs to the persistence work in
    /// flight. Until then no `CharacterProfile` exists to fall out of date.
    func updateProfile(_ profile: UserProfile, name: String? = nil, age: Int? = nil, image: UIImage? = nil) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        
        if let name = name {
            profiles[index].name = name
        }
        
        if let age = age {
            profiles[index].age = age
        }
        
        if let image = image {
            saveProfileImage(image, for: profile.id)
        }
        
        saveProfiles()
        
        // Update current profile if it's the one being edited
        if currentProfile?.id == profile.id {
            currentProfile = profiles[index]
        }
        
        Self.log.debug("Profile updated")
    }
    
    /// Replaces a child's interests (FAZ 12). The caller merges with what the
    /// screen did not show (`ChildInterests.merging`); this only stores.
    func setInterests(_ interests: [String], for profileID: UUID) {
        guard let index = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        var seen = Set<String>()
        profiles[index].interests = interests.filter { seen.insert($0).inserted }
        saveProfiles()
        if currentProfile?.id == profileID {
            currentProfile = profiles[index]
        }
        // A count only: which interests a child has is family content.
        Self.log.debug("Interests updated: \(self.profiles[index].interests.count, privacy: .private)")
    }

    /// Why a deletion did not happen, when it did not.
    enum DeletionRefusal: Error { case lastProfile }

    /// The stories that are deleted along with `profile`.
    ///
    /// The confirmation shows this count and `deleteProfile` deletes exactly
    /// this set, so what the parent is told and what is lost cannot drift apart.
    func storiesDeleted(
        with profile: UserProfile,
        library: StoryGenerationManager = .shared
    ) -> [Story] {
        library.stories.filter { $0.isSolelyOwned(by: profile, among: profiles) }
    }

    /// Deletes a profile and everything keyed to it, including the child's
    /// stories (`storiesDeleted(with:)`). Irreversible: callers confirm first.
    ///
    /// Returns a failure instead of silently doing nothing: the caller shows a
    /// delete button, and a button that sometimes does nothing with no
    /// explanation is worse than one that is disabled.
    @discardableResult
    func deleteProfile(
        _ profile: UserProfile,
        library: StoryGenerationManager = .shared
    ) -> Result<Void, DeletionRefusal> {
        guard profiles.count > 1 else {
            Self.log.notice("Refused to delete the last remaining profile")
            return .failure(.lastProfile)
        }

        // Before the profile leaves `profiles`: ownership is decided against
        // the full list, so a sibling with the same name still protects
        // pre-id stories.
        let stories = storiesDeleted(with: profile, library: library)
        library.deleteStories(ids: Set(stories.map(\.id)))

        deleteProfileImage(for: profile.id)
        // Side tables keyed by profile id. Left behind, these outlive the
        // profile and are inherited by the next profile to be given the same
        // UUID — and the avatar colour was visibly wrong for a recreated child.
        UserDefaults.standard.removeObject(forKey: "mp_avatarColor_\(profile.id.uuidString)")
        // Written until FAZ 14, read by nothing; removed so old devices do
        // not keep it. Its successor is `StoryUsageStore`, below.
        UserDefaults.standard.removeObject(forKey: "read_history_\(profile.id.uuidString)")
        // The reading ledger is per child too (MPStreak): it goes with the child.
        MPStreak.eraseLedger(for: profile.id)
        // So does the book character (B2). The child's books keep their own
        // copy and go with `storiesDeleted` above.
        let profileID = profile.id
        Task { await AvatarStore.shared.delete(for: profileID) }
        // Masal ailem belongs to the child; their stories keep the names as written.
        FamilyCharacterStore().delete(for: profileID)
        // So do their series (FAZ 13); the episodes already on the shelf went
        // with `storiesDeleted` above.
        StorySeriesStore().delete(for: profileID)
        // How the child read (FAZ 14): their own record and their events
        // still waiting to be sent.
        StoryUsageStore().delete(for: profileID)
        ReadingEventQueue().delete(for: profileID)

        profiles.removeAll { $0.id == profile.id }
        saveProfiles()

        if currentProfile?.id == profile.id {
            if let firstProfile = profiles.first {
                switchProfile(to: firstProfile)
            } else {
                currentProfile = nil
                userDefaults.removeObject(forKey: currentProfileKey)
            }
        }

        Self.log.debug("Profile deleted")
        return .success(())
    }
    
    func switchProfile(to profile: UserProfile) {
        currentProfile = profile
        userDefaults.set(profile.id.uuidString, forKey: currentProfileKey)
        
        Self.log.debug("Active profile switched")
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)
        Self.log.debug("Onboarding marked complete")
    }
    
    func hasProfile() -> Bool {
        return !profiles.isEmpty && currentProfile != nil
    }
    
    // MARK: - Profile Images
    
    private func saveProfileImage(_ image: UIImage, for profileId: UUID) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileName = "profile_\(profileId.uuidString).jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            
            // Update profile with image file name
            if let index = profiles.firstIndex(where: { $0.id == profileId }) {
                profiles[index].imageFileName = fileName
                saveProfiles()
            }
            
            Self.log.debug("Profile image written")
        } catch {
            Self.log.error("Profile image could not be written: \(Self.describe(error), privacy: .public)")
        }
    }
    
    func getProfileImage(for profile: UserProfile) -> UIImage? {
        guard let fileName = profile.imageFileName else { return nil }
        
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    func getProfileImage() -> UIImage? {
        guard let profile = currentProfile else { return nil }
        return getProfileImage(for: profile)
    }
    
    private func deleteProfileImage(for profileId: UUID) {
        guard let profile = profiles.first(where: { $0.id == profileId }),
              let fileName = profile.imageFileName else { return }
        
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            Self.log.debug("Profile image removed")
        } catch {
            Self.log.error("Profile image could not be removed: \(Self.describe(error), privacy: .public)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Legacy Support (for backward compatibility)
    
    private func migrateFromLegacyProfile() {
        // Check if we have the old profile format
        let legacyProfileKey = "userProfile"
        
        struct LegacyUserProfile: Codable {
            var name: String
            var age: Int
            var profileImageFileName: String?
            var createdAt: Date
        }
        
        if profiles.isEmpty,
           let data = userDefaults.data(forKey: legacyProfileKey),
           let legacyProfile = try? JSONDecoder().decode(LegacyUserProfile.self, from: data),
           !legacyProfile.name.isEmpty {
            
            Self.log.debug("Legacy profile detected, migrating")
            
            // Create new profile from legacy data
            let newProfile = UserProfile(
                name: legacyProfile.name,
                age: legacyProfile.age,
                profileType: .child, // Default to child profile
                imageFileName: legacyProfile.profileImageFileName
            )
            
            profiles.append(newProfile)
            saveProfiles()
            switchProfile(to: newProfile)
            
            // Clean up old profile data
            userDefaults.removeObject(forKey: legacyProfileKey)
            
            Self.log.debug("Legacy profile migrated")
        }
    }
    
    /// The current profile, or a blank one.
    ///
    /// Read-only on purpose. It used to be settable, and the setter silently
    /// discarded the write when there was no current profile, and silently
    /// dropped every field except name and age when there was. Callers that
    /// want to change a profile call `updateProfile` and can see what it does.
    var profile: UserProfile {
        currentProfile ?? UserProfile()
    }
    
    func updateProfile(name: String, image: UIImage? = nil) {
        if let current = currentProfile {
            updateProfile(current, name: name, image: image)
        } else {
            // Create first profile if none exists
            createProfile(name: name, age: 6, profileType: .child, image: image)
        }
    }
}

import Foundation
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
    
    init(id: UUID = UUID(), name: String = "", age: Int = 6, profileType: ProfileType = .child, imageFileName: String? = nil) {
        self.id = id
        self.name = name
        self.age = age
        self.profileType = profileType
        self.imageFileName = imageFileName
        self.createdAt = Date()
    }
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
    
    private init() {
        print("🎯 ProfileManager başlatılıyor...")
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
            print("✅ \(savedProfiles.count) profil yüklendi")
            
            // Load current profile
            if let currentProfileId = userDefaults.string(forKey: currentProfileKey),
               let uuid = UUID(uuidString: currentProfileId),
               let profile = profiles.first(where: { $0.id == uuid }) {
                self.currentProfile = profile
                print("✅ Aktif profil yüklendi")
            } else if let firstProfile = profiles.first {
                self.currentProfile = firstProfile
                print("✅ İlk profil aktif edildi")
            }
        } else {
            self.profiles = []
            print("ℹ️ Kayıtlı profil bulunamadı")
        }
    }
    
    private func saveProfiles() {
        // `try?` here meant a failed encode lost every profile with no trace.
        // Nothing can be done about it at runtime, but it must not be silent.
        do {
            let data = try JSONEncoder().encode(profiles)
            userDefaults.set(data, forKey: profilesKey)
            print("💾 \(profiles.count) profil kaydedildi")
        } catch {
            assertionFailure("Profiles could not be encoded: \(error)")
            print("❌ Profiller kaydedilemedi: \(error)")
        }
    }
    
    private func loadOnboardingStatus() {
        hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
        print("📱 Onboarding durumu: \(hasCompletedOnboarding)")
    }
    
    // MARK: - Profile Management
    
    /// Creates a profile and returns it.
    ///
    /// Returning the profile matters: callers previously recovered it with
    /// `profiles.last`, which is only correct while this method happens to
    /// append.
    @discardableResult
    func createProfile(name: String, age: Int, profileType: ProfileType, image: UIImage? = nil) -> UserProfile {
        let profile = UserProfile(name: name, age: age, profileType: profileType)

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

        print("✅ Yeni profil oluşturuldu (\(profileType.displayName))")
        return profiles.last ?? profile
    }
    
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
        
        print("✅ Profil güncellendi")
    }
    
    /// Why a deletion did not happen, when it did not.
    enum DeletionRefusal: Error { case lastProfile }

    /// Deletes a profile and everything keyed to it.
    ///
    /// Returns a failure instead of silently doing nothing: the caller shows a
    /// delete button, and a button that sometimes does nothing with no
    /// explanation is worse than one that is disabled.
    @discardableResult
    func deleteProfile(_ profile: UserProfile) -> Result<Void, DeletionRefusal> {
        guard profiles.count > 1 else {
            print("⚠️ Son profil silinemez")
            return .failure(.lastProfile)
        }

        deleteProfileImage(for: profile.id)
        // Side tables keyed by profile id. Left behind, these outlive the
        // profile and are inherited by the next profile to be given the same
        // UUID — and the avatar colour was visibly wrong for a recreated child.
        UserDefaults.standard.removeObject(forKey: "mp_avatarColor_\(profile.id.uuidString)")
        UserDefaults.standard.removeObject(forKey: "read_history_\(profile.id.uuidString)")

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

        print("✅ Profil silindi")
        return .success(())
    }
    
    func switchProfile(to profile: UserProfile) {
        currentProfile = profile
        userDefaults.set(profile.id.uuidString, forKey: currentProfileKey)
        
        print("✅ Profil değiştirildi (\(profile.profileType.displayName))")
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)
        print("✅ Onboarding tamamlandı")
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
            
            print("✅ Profil resmi kaydedildi: \(fileName)")
        } catch {
            print("❌ Profil resmi kaydetme hatası: \(error)")
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
            print("✅ Profil resmi silindi: \(fileName)")
        } catch {
            print("❌ Profil resmi silme hatası: \(error)")
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
            
            print("🔄 Eski profil sistemi tespit edildi, taşınıyor...")
            
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
            
            print("✅ Eski profil yeni sisteme taşındı")
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

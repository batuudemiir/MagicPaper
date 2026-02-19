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
                print("✅ Aktif profil: \(profile.name)")
            } else if let firstProfile = profiles.first {
                self.currentProfile = firstProfile
                print("✅ İlk profil aktif edildi: \(firstProfile.name)")
            }
        } else {
            self.profiles = []
            print("ℹ️ Kayıtlı profil bulunamadı")
        }
    }
    
    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            userDefaults.set(data, forKey: profilesKey)
            print("💾 \(profiles.count) profil kaydedildi")
        }
    }
    
    private func loadOnboardingStatus() {
        hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
        print("📱 Onboarding durumu: \(hasCompletedOnboarding)")
    }
    
    // MARK: - Profile Management
    
    func createProfile(name: String, age: Int, profileType: ProfileType, image: UIImage? = nil) {
        let profile = UserProfile(name: name, age: age, profileType: profileType)
        
        // Save image if provided
        if let image = image {
            saveProfileImage(image, for: profile.id)
        }
        
        profiles.append(profile)
        saveProfiles()
        
        // Set as current if first profile
        if profiles.count == 1 {
            switchProfile(to: profile)
        }
        
        print("✅ Yeni profil oluşturuldu: \(name) (\(profileType.displayName))")
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
        
        print("✅ Profil güncellendi: \(profiles[index].name)")
    }
    
    func deleteProfile(_ profile: UserProfile) {
        // Don't allow deleting the last profile
        guard profiles.count > 1 else {
            print("⚠️ Son profil silinemez")
            return
        }
        
        // Delete profile image
        deleteProfileImage(for: profile.id)
        
        // Remove from array
        profiles.removeAll { $0.id == profile.id }
        saveProfiles()
        
        // Switch to another profile if current was deleted
        if currentProfile?.id == profile.id {
            if let firstProfile = profiles.first {
                switchProfile(to: firstProfile)
            }
        }
        
        print("✅ Profil silindi: \(profile.name)")
    }
    
    func switchProfile(to profile: UserProfile) {
        currentProfile = profile
        userDefaults.set(profile.id.uuidString, forKey: currentProfileKey)
        
        print("✅ Profil değiştirildi: \(profile.name) (\(profile.profileType.displayName))")
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
            
            print("✅ Eski profil yeni sisteme taşındı: \(newProfile.name)")
        }
    }
    
    var profile: UserProfile {
        get {
            currentProfile ?? UserProfile()
        }
        set {
            if let current = currentProfile {
                updateProfile(current, name: newValue.name, age: newValue.age)
            }
        }
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

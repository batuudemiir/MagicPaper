import Foundation
import SwiftUI

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @AppStorage("isPremiumUser") var isPremium: Bool = false
    
    private let freeStoryLimit = 1
    
    private init() {}
    
    // Kullanıcının premium olup olmadığını kontrol et
    func checkPremiumStatus() -> Bool {
        return isPremium
    }
    
    // Kullanıcının yeni hikaye oluşturup oluşturamayacağını kontrol et
    func canCreateNewStory() -> Bool {
        // Premium kullanıcılar sınırsız hikaye oluşturabilir
        if isPremium {
            return true
        }
        
        // Ücretsiz kullanıcılar sadece 1 hikaye oluşturabilir
        let completedStories = StoryGenerationManager.shared.stories.filter { $0.status == .completed }
        return completedStories.count < freeStoryLimit
    }
    
    // Kalan hikaye hakkını döndür
    func remainingStories() -> Int {
        if isPremium {
            return -1 // Sınırsız
        }
        
        let completedStories = StoryGenerationManager.shared.stories.filter { $0.status == .completed }
        let remaining = freeStoryLimit - completedStories.count
        return max(0, remaining)
    }
    
    // Premium'a yükselt (test için)
    func upgradeToPremium() {
        isPremium = true
    }
    
    // Premium'dan düşür (test için)
    func downgradeToPremium() {
        isPremium = false
    }
}

// Route.swift
// One case per prototype screen (see docs/SCREENS.md). Parent routes must only be reachable after the parent gate.

import Foundation

enum AppRoot: Equatable { case onboarding, kid, parent }

enum KidRoute: Hashable {
    case kidCorner            // 12 Benim köşem
    case heroEditor           // 13 Kahraman oluşturucu
    case storyFamily          // 14 Masal ailem
    case newWords             // 15 Yeni kelimelerim
    case series(id: String)   // 18 Seri masal
    case storyActions(id: String) // 17 Masal aksiyonları (sheet)
}

enum CreateRoute: Hashable {
    case world                // 19 Yarat 1 · Dünya
    case details(worldId: String?) // 20 Yarat 2 · Ayarla (world strip on Ana sayfa jumps here)
    case generating(jobId: String) // 21 Masal yazılıyor / 43 Üretim başarısız
}

enum ReaderRoute: Hashable {
    case reader(storyId: String)   // 22 görselli / 23 metin / 27 iPad (layout by size class + story.hasImages)
    case settings                  // 24 Okuma ayarları (sheet)
    case storyEnd(storyId: String) // 25 Masal sonu
    case sleepMode                 // 26 Uyku modu
}

enum OnboardingRoute: Hashable {
    case welcome(page: Int)        // 02–04
    case signIn                    // 05
    case parentalConsent           // 06
    case childProfile              // 07
    case interests                 // 08
    case notificationPrePrompt     // 09
    case firstStory                // 10
}

enum ParentRoute: Hashable {
    case voiceRecording            // 33 Kendi sesin
    case familyMembers             // 34 Aile
    case bookExport                // 35 Masal kitabı
    case shareLink                 // 36 Aileyle paylaş
    case paywall                   // 37 Abonelik
    case subscriptionExpired       // 38 Abonelik bitti
    case deleteAccount             // 39 Hesabı sil
}

/// Deep links (notifications, widgets, Siri). Parent links always open the gate first.
enum DeepLink {
    case story(id: String), series(id: String), create, parentApprovals
    init?(url: URL) {
        guard url.scheme == "magicpaper" else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        switch (url.host, parts.first) {
        case ("story", let id?): self = .story(id: id)
        case ("series", let id?): self = .series(id: id)
        case ("create", _): self = .create
        case ("parent", "approvals"): self = .parentApprovals
        default: return nil
        }
    }
}

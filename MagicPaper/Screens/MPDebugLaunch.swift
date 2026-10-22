import Foundation

#if DEBUG
/// Simülatörde ekran görüntüsü için başlatma kancaları (yalnızca DEBUG).
///
/// `xcrun simctl launch <cihaz> <paket> -mpDemo YES -mpStartParent YES`
/// - `mpDemo`: karşılama geçilmiş sayılır, giriş bu açılış için ertelenir,
///   profil yoksa örnek bir çocuk ("İrem", 6) kurulur.
/// - `mpStartParent`: uygulama ebeveyn alanında açılır.
/// - `mpStartTab`: `home`, `gunluk`, `library` ya da `corner`.
/// - `mpParentTab`: `overview`, `safety` ya da `settings`.
/// - `mpParentRoute`: ebeveyn alt sayfası, ör. `bookExport`, `familyMembers` (FAZ 18).
/// - `mpDemoLibrary`: kitaplığa örnek masallar ve açılmış klasikler (yalnızca
///   kitaplık boşsa; kitaplık ekran görüntüleri için, 20 Ekim).
enum MPDebugLaunch {
    private static var defaults: UserDefaults { .standard }

    static var isDemo: Bool { defaults.bool(forKey: "mpDemo") }
    static var startsInParent: Bool { defaults.bool(forKey: "mpStartParent") }
    static var startTab: MPTab? { defaults.string(forKey: "mpStartTab").flatMap(MPTab.init(rawValue:)) }
    static var parentTab: MPParentTab? { defaults.string(forKey: "mpParentTab").flatMap(MPParentTab.init(rawValue:)) }
    static var demoLibrary: Bool { defaults.bool(forKey: "mpDemoLibrary") }
    static var parentRoute: MPParentRoute? { defaults.string(forKey: "mpParentRoute").flatMap(MPParentRoute.init(rawValue:)) }

    @MainActor
    static func applyBeforeGate() {
        guard isDemo else { return }
        let profiles = ProfileManager.shared
        if profiles.profiles.isEmpty {
            profiles.createProfile(name: "İrem", age: 6, profileType: .child)
        }
        profiles.hasCompletedOnboarding = true
        AccountService.shared.deferredSignIn = true
        if demoLibrary { seedLibrary(for: profiles.currentProfile) }
    }

    /// Her moddan birkaç masal (biri yarım, biri seri bölümü) ve üç klasik.
    @MainActor
    private static func seedLibrary(for profile: UserProfile?) {
        let library = StoryGenerationManager.shared
        guard let profile, !library.stories.contains(where: { $0.belongs(to: profile) }) else { return }
        let samples: [(String, String, String, Int?, Int?)] = [
            ("İrem ve Uykucu Ay", "bedtime", "kar", 2, nil),
            ("Yıldız Toplayan Kedi", "bedtime", "uzay", nil, nil),
            ("Bulutların Ninnisi", "bedtime", "peri", nil, nil),
            ("Yıldızlar Neden Parlar?", "learning", "uzay", nil, nil),
            ("Arıların Gizli Dili", "learning", "ciftlik", 1, nil),
            ("Ormandaki Gizli Yol", "adventure", "orman", nil, 2),
            ("Denizaltı Dostları", "adventure", "deniz", nil, nil),
            ("Dinozor Vadisi", "adventure", "dinozor", nil, nil),
        ]
        for (index, sample) in samples.enumerated() {
            var story = Story(title: sample.0, childName: profile.name, childProfileID: profile.id,
                              theme: .fantasy, language: .turkish, status: .completed,
                              pages: (0..<5).map { StoryPage(title: "", text: "Bir varmış, bir yokmuş. Sayfa \($0 + 1).",
                                                             imagePrompt: "") })
            story.origin = StoryOrigin(seed: "demo-\(index)", storyIdeaID: nil, blueprintID: "demo", settingID: "demo",
                                       companionID: "demo", discoveryID: "demo", fingerprint: "demo-\(index)",
                                       catalogVersion: "demo", worldID: sample.2, modeID: sample.1,
                                       selectionStrategy: "direct", ageBand: "5-6")
            story.origin?.seriesEpisode = sample.4
            story.createdAt = Date().addingTimeInterval(-Double(index) * 86_400)
            if let page = sample.3 {
                // Yeni kelimelerim için okunmuş ilk sayfaya bir sözlük kelimesi (21 Ekim).
                story.pages[0].text = "Gece oldu. \(profile.name) feneri yakıp usulca bahçeye çıktı. Ay gülümsedi."
                story.pages[0].words = [
                    StoryWord(id: "demo_fener_\(index)", term: index == 0 ? "fener" : "usulca",
                              meaning: index == 0 ? "Karanlıkta yolu aydınlatan, elde taşınan küçük ışık."
                                                  : "Kimseyi uyandırmadan, yavaşça ve sessizce.",
                              surface: index == 0 ? "feneri" : "usulca"),
                ]
                story.lastReadPage = page
                story.lastReadAt = Date().addingTimeInterval(-Double(index) * 3_600)
            }
            library.addStoryToLibrary(story)
        }
        let progress = ClassicProgressStore.shared
        for tale in ClassicsCatalog.bundled.standaloneTales.prefix(3) {
            progress.markOpened(tale.id, pageCount: tale.soft.pages.count, narration: .soft)
        }
        if let first = ClassicsCatalog.bundled.standaloneTales.first {
            progress.saveProgress(first.id, page: 1)
        }
    }
}
#endif

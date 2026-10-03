import Foundation
import OSLog
import StoryEngine

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "IllustratedBook")

/// Motorun ürettiği masalı görselli kitaba çevirir (B2).
///
/// Motor tipleriyle `SceneSelector`'ın düz değerleri arasındaki tek dikiş.
/// `OfflineStoryMapper.appPage` sayfanın rolünü, beat'lerini ve duygusunu
/// düşürüyor; bu yüzden seçim `ComposedStory` hâlâ eldeyken yapılır.
///
/// Ağ yok, uzak çağrı yok: yalnızca gömülü manifestler ve cihazdaki avatar
/// kaydı okunur.
enum IllustratedBookBinder {

    /// `createStory`'nin tek çağrısı: bayrak açık ve ebeveyn bir kitap karakteri
    /// kaydetmişse sahneleri ekler; değilse masalı **dokunmadan** döndürür —
    /// bugünkü metin masalının aynısı.
    ///
    /// Görselli kitap ebeveynin en az bir kez "Kaydet" dediği bir avatar ister;
    /// uygulama çocuğun tenini ya da saçını ebeveyn adına seçmez (plan §8.1).
    @MainActor
    static func illustrateIfEnabled(
        _ story: MagicPaper.Story,
        composed: ComposedStory,
        profile: UserProfile,
        mode: StoryMode?,
        ageBand: AgeBand?,
        existing: [MagicPaper.Story],
        isEnabled: Bool = IllustratedBookAccess.isEnabled(),
        avatars: AvatarStore = .shared,
        kit: AvatarKit? = .bundled,
        library: SceneLibrary? = .bundled
    ) async -> MagicPaper.Story {
        guard isEnabled, let kit, let library,
              let avatar = await avatars.avatar(for: profile.id) else { return story }

        let illustrated = illustrate(
            story, composed: composed, avatar: avatar, kit: kit, library: library,
            mode: mode, ageBand: ageBand,
            recentSceneIDs: recentSceneIDs(in: existing, for: profile, window: library.cooldown.window)
        )
        // Kapsama boşluğu: yalnızca içerik kimlikleri, çocuğa dair hiçbir şey.
        let gaps = illustrated.illustration?.gaps ?? []
        if !gaps.isEmpty {
            let summary = gaps.map { "\($0.settingID)·\($0.role)·s\($0.pageNumber)" }.joined(separator: ", ")
            logger.notice("Sahne bulunamayan sayfalar metin kaldı: \(summary, privacy: .public)")
        }
        return illustrated
    }

    /// Seçicinin girdisi, motorun çıktısından.
    static func selectorInput(
        from composed: ComposedStory,
        mode: StoryMode?,
        ageBand: AgeBand?,
        recentSceneIDs: [[String]]
    ) -> SceneSelector.Input {
        SceneSelector.Input(
            pages: composed.pages.map { page in
                SceneSelector.Page(
                    number: page.pageNumber,
                    role: page.role.rawValue,
                    beats: page.beats.map(\.rawValue),
                    emotion: page.emotion?.rawValue
                )
            },
            settingID: composed.content.setting.id.rawValue,
            settingTags: composed.content.setting.tags.map(\.rawValue),
            mode: mode?.rawValue,
            ageBand: ageBand?.description,
            seed: composed.seed,
            companionID: composed.content.companion.id.rawValue,
            companionKind: composed.content.companion.type,
            recentSceneIDs: recentSceneIDs
        )
    }

    /// Masala anlık görüntüyü ve sayfa sahnelerini ekler.
    ///
    /// Avatar **kopyalanır**: kit'in bugün tanıdığı parçalara oturtulmuş hâli
    /// masala yazılır, ebeveynin sonraki değişiklikleri bu kitabı etkilemez.
    ///
    /// `story.pages`, `OfflineStoryMapper.appStory` tarafından sayfa numarasına
    /// göre sıralanmış olarak gelir; eşleme bu sıraya dayanır.
    static func illustrate(
        _ story: MagicPaper.Story,
        composed: ComposedStory,
        avatar: AvatarSpec,
        kit: AvatarKit,
        library: SceneLibrary,
        mode: StoryMode?,
        ageBand: AgeBand?,
        recentSceneIDs: [[String]]
    ) -> MagicPaper.Story {
        let selection = SceneSelector(library: library).select(
            selectorInput(from: composed, mode: mode, ageBand: ageBand,
                          recentSceneIDs: recentSceneIDs)
        )

        var out = story
        let numbers = composed.pages.map(\.pageNumber).sorted()
        for (index, number) in numbers.enumerated() where out.pages.indices.contains(index) {
            out.pages[index].scene = selection.plates[number]
        }
        out.illustration = StoryIllustration(
            avatar: kit.resolved(avatar),
            avatarKitVersion: kit.version,
            avatarArtVersion: kit.artVersion,
            sceneLibraryVersion: library.version,
            gaps: selection.gaps
        )
        return out
    }

    /// Bu çocuğun son masallarında kullanılan sahneler, masal masal, en yenisi
    /// önce. Cooldown'un girdisi.
    ///
    /// Yeni bir kayıt anahtarı açmaz: geçmiş, kayıtlı masalların plate'lerinden
    /// türetilir (`recentModes(for:)` ile aynı desen). Profil silinince
    /// masallarla birlikte gider.
    static func recentSceneIDs(in stories: [MagicPaper.Story], for profile: UserProfile, window: Int) -> [[String]] {
        stories
            .filter { $0.belongs(to: profile) && $0.illustration != nil }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(max(window, 0))
            .map { $0.pages.compactMap { $0.scene?.sceneID } }
    }
}

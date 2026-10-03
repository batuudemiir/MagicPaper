import Foundation

/// Bir masalın hangi sayfasının hangi hazır sahneyi alacağını seçer.
///
/// Saf ve deterministik: aynı girdi her zaman aynı plate'leri verir. Rastgelelik
/// yalnızca masalın seed'inden türetilir. Okuma geçmişi de bir girdidir, bu
/// yüzden cooldown determinizmi bozmaz.
///
/// Yalnızca Foundation. Motor tipleri (`ComposedPage`) burada görünmez; çeviri
/// `StoryEngineBridge/IllustratedBookBinder` içinde yapılır. Bu tip ileride kod
/// değişmeden engine paketine taşınabilir (plan §3.2).
///
/// Uyan sahne yoksa sayfa metin sayfası kalır ve bir `CoverageGapRecord` döner.
/// Rastgele bir sahneye asla düşülmez.
struct SceneSelector {

    struct Page: Equatable {
        let number: Int
        /// `PageRole.rawValue` (`hook`, `discovery` …).
        let role: String
        /// İlki ana beat'tir.
        let beats: [String]
        let emotion: String?
    }

    struct Input: Equatable {
        let pages: [Page]
        let settingID: String
        let settingTags: [String]
        /// `StoryMode.rawValue`. `nil` her modu kabul eder.
        let mode: String?
        /// `"5-6"`.
        let ageBand: String?
        let seed: String
        /// Yol arkadaşı. Yalnızca tanışmadan sonraki sayfalara konur.
        let companionID: String?
        /// Yol arkadaşının türü (katalogdaki `type`).
        var companionKind: String? = nil
        /// Bu çocuğun son masallarında kullanılmış sahneler, masal masal, en
        /// yenisi önce.
        let recentSceneIDs: [[String]]

        init(pages: [Page], settingID: String, settingTags: [String], mode: String?, ageBand: String?,
             seed: String, companionID: String?, companionKind: String? = nil, recentSceneIDs: [[String]]) {
            self.pages = pages
            self.settingID = settingID
            self.settingTags = settingTags
            self.mode = mode
            self.ageBand = ageBand
            self.seed = seed
            self.companionID = companionID
            self.companionKind = companionKind
            self.recentSceneIDs = recentSceneIDs
        }
    }

    struct Selection: Equatable {
        /// Sayfa numarası → sahne.
        var plates: [Int: ScenePlate]
        var gaps: [CoverageGapRecord]
    }

    let library: SceneLibrary

    func select(_ input: Input) -> Selection {
        let pages = input.pages.sorted { $0.number < $1.number }
        let companionPage = pages.first { $0.role == "companion" }?.number

        var plates: [Int: ScenePlate] = [:]
        var gaps: [CoverageGapRecord] = []
        var used = Set<String>()

        for page in illustratedPages(pages, ageBand: input.ageBand) {
            guard let match = best(for: page, input: input, excluding: used) else {
                gaps.append(CoverageGapRecord(pageNumber: page.number, role: page.role,
                                              settingID: input.settingID,
                                              settingTags: input.settingTags))
                continue
            }
            let (scene, version) = match
            used.insert(scene.id)

            let metCompanion = companionPage.map { page.number > $0 } ?? false
            let showsCompanion = metCompanion && version.companionAnchor != nil && input.companionID != nil
            plates[page.number] = ScenePlate(
                sceneID: scene.id,
                sceneVersion: version.version,
                pose: pose(for: page, in: scene),
                facing: version.characterAnchor.facing,
                companionID: showsCompanion ? input.companionID : nil,
                companionKind: showsCompanion ? input.companionKind : nil
            )
        }
        return Selection(plates: plates, gaps: gaps)
    }

    // MARK: - Görselli sayfalar

    /// Yaş bandının yuvalarını masalın sayfalarına oturtur.
    ///
    /// Her yuva bir rol listesidir; yuva, listedeki rollerden masalda **ilk**
    /// bulunanın ilk sayfasına verilir. Aynı sayfa iki yuvaya verilmez.
    func illustratedPages(_ pages: [Page], ageBand: String?) -> [Page] {
        var chosen: [Page] = []
        for slot in library.slots(forAgeBand: ageBand) {
            for role in slot {
                if let page = pages.first(where: { $0.role == role && !chosen.contains($0) }) {
                    chosen.append(page)
                    break
                }
            }
        }
        return chosen.sorted { $0.number < $1.number }
    }

    // MARK: - Aday ve skor

    private func best(for page: Page, input: Input,
                      excluding used: Set<String>) -> (SceneLibrary.Scene, SceneLibrary.Version)? {
        let candidates: [(scene: SceneLibrary.Scene, version: SceneLibrary.Version, score: Double)] =
            library.scenes.compactMap { scene in
                guard !used.contains(scene.id),
                      let version = scene.latestApproved,
                      scene.roles.contains(page.role),
                      input.mode.map({ scene.modes.contains($0) }) ?? true
                else { return nil }

                let idMatch = scene.settingIDs.contains(input.settingID)
                let tagMatch = !Set(scene.settingTags).isDisjoint(with: input.settingTags)
                guard idMatch || tagMatch else { return nil }

                return (scene, version, score(scene, page: page, idMatch: idMatch, input: input))
            }

        // En yüksek skor; eşitlikte seed'den türeyen sıra. Swift'in `hashValue`'su
        // süreç başına tohumlanır, kullanılamaz.
        return candidates.max { a, b in
            if a.score != b.score { return a.score < b.score }
            return tieBreak(a.scene.id, page: page.number, seed: input.seed)
                 < tieBreak(b.scene.id, page: page.number, seed: input.seed)
        }.map { ($0.scene, $0.version) }
    }

    /// Önce özgüllük, sonra yenilik, en son ağırlık.
    ///
    /// En küçük özgüllük basamağı (10) azami ceza ile ağırlık aralığının
    /// toplamından büyük tutulur; `SceneLibraryTests` bunu manifest üzerinde
    /// denetler. Böylece daha özel bir eşleşme hiçbir zaman yenilikle ya da
    /// ağırlıkla geçilmez.
    private func score(_ scene: SceneLibrary.Scene, page: Page, idMatch: Bool, input: Input) -> Double {
        var s = 0.0
        if idMatch { s += 1000 }
        if let beat = page.beats.first, scene.beats.contains(beat) { s += 100 }
        if let beat = page.beats.first,
           let p = library.direction.beatPoses[beat], scene.allowedPoses.contains(p) { s += 20 }
        if let emotion = page.emotion, scene.emotions.contains(emotion) { s += 10 }
        s += scene.weight
        s -= cooldownPenalty(scene.id, recent: input.recentSceneIDs)
        return s
    }

    /// Son masallarda görülen sahneye ceza. Yasak değil: tek aday varsa yine
    /// seçilir. En yeni masaldaki sahne tam ceza alır, pencerenin sonuna doğru
    /// doğrusal azalır.
    func cooldownPenalty(_ sceneID: String, recent: [[String]]) -> Double {
        let window = max(library.cooldown.window, 0)
        guard window > 0,
              let index = recent.prefix(window).firstIndex(where: { $0.contains(sceneID) })
        else { return 0 }
        return library.cooldown.penalty * Double(window - index) / Double(window)
    }

    // MARK: - Poz

    /// Eylem sözleşmesi (plan §3.2.1): beat'in pozu, olmazsa rolün pozu,
    /// olmazsa sahnenin varsayılanı. Sahnenin izin vermediği poz çizilmez.
    func pose(for page: Page, in scene: SceneLibrary.Scene) -> String {
        let direction = library.direction
        if let beat = page.beats.first, let p = direction.beatPoses[beat],
           scene.allowedPoses.contains(p) { return p }
        if let p = direction.rolePoses[page.role], scene.allowedPoses.contains(p) { return p }
        // Manifest testi `defaultPose`'un izinli olduğunu garanti eder; yine de
        // bozuk bir kayıt çizilemeyen bir poza değil, ortak yedeğe düşsün.
        return scene.allowedPoses.contains(scene.defaultPose) ? scene.defaultPose : direction.fallbackPose
    }

    // MARK: - Kararlı karma

    /// FNV-1a; `EngineFoundation.StableHash.hash` ile bayt bayt aynı algoritma.
    /// Uygulama hedefi EngineFoundation'ı bağlamıyor; tip pakete taşındığında
    /// `StableHash`'e geçilir ve seçimler değişmez.
    static func stableHash(_ values: [String]) -> UInt64 {
        var result: UInt64 = 0xcbf2_9ce4_8422_2325
        for value in values {
            for byte in value.utf8 {
                result ^= UInt64(byte)
                result = result &* 0x100000001b3
            }
            result ^= 0x1F
            result = result &* 0x100000001b3
        }
        return result
    }

    private func tieBreak(_ sceneID: String, page: Int, seed: String) -> UInt64 {
        Self.stableHash([seed, String(page), sceneID])
    }
}

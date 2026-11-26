import Foundation
import StoryEngine

/// Yaratma akışının kararları, görünümün dışında ve test edilebilir.
///
/// Akış (karar: 3 Ekim ve 7 Kasım 2026; konu adımı 19 Kasım 2026, Batuhan):
/// mod → konu (yalnızca konusu olan modda) → "Masalda kimler olsun?" → masal.
/// Çubuktan okumaya 3 dokunuş, sürprizle 2. "Bana sürpriz yap" yalnızca seçecek
/// bir şey varken; ana sayfada seçilen bir mod akışı doğrudan ikinci adımdan açar.
enum StoryCreationSteps {

    /// Akışın hangi adımdan açılacağı.
    enum Opening: Equatable {
        case mode
        case companion(StoryMode)
    }

    /// "İrem için ▾" satırı yalnızca seçilecek bir şey varken (7 Kasım 2026).
    ///
    /// Ayrı bir adım değil: çoğu masal açık çocuk içindir ve soru yalnızca
    /// değiştirmek isteyene dokunuş kazandırır. Tek çocuklu evde cevabı belli
    /// bir soru olurdu.
    static func showsChildPicker(profileCount: Int) -> Bool {
        profileCount >= 2
    }

    /// Adım noktalarının erişilebilirlik etiketleri. Tek yerden üretiliyor ki
    /// nokta sayısı ile ekran sayısı ayrışmasın. Konu adımı yalnızca modun
    /// konusu varken sayılır (uyku öncesinde yok).
    static func stepLabels(hasTopicStep: Bool) -> [String] {
        hasTopicStep ? ["Masal", "Konu", "Kimler"] : ["Masal", "Kimler"]
    }

    /// Konu adımının sorusu modun sorusunu sürdürür: "öğrenelim" dedikten sonra
    /// "neyi", "maceraya çıkalım" dedikten sonra "nereye".
    static func topicQuestion(for mode: StoryMode) -> String {
        switch mode {
        case .learning:  return "Neyi öğrenelim?"
        case .adventure: return "Nereye gidelim?"
        case .bedtime:   return "Masal neyle ilgili olsun?"
        }
    }

    /// "Bana sürpriz yap" en az iki kurulabilir mod varken görünür (K6). Tek
    /// mod kaldıysa sürprizin seçeceği bir şey yok.
    static func showsSurprise(availableModes: [StoryMode]) -> Bool {
        availableModes.count >= 2
    }

    /// Uyku saatinde öne çıkan mod (31 · Güvenlik, karar 15 Ekim 2026).
    ///
    /// Akşam yalnızca uyku masalı demek değil: üç mod da seçilebilir, Uyku
    /// öncesi ilk sırada ve vurgulu. Bu bantta kurulamıyorsa vurgu yok.
    static func emphasizedMode(_ available: [StoryMode], isBedtime: Bool) -> StoryMode? {
        isBedtime && available.contains(.bedtime) ? .bedtime : nil
    }

    /// Kurulabilir modlar, ekran sırasıyla (K5). Kurulamayan mod gösterilmez;
    /// öne çıkan mod varsa ilk sırada.
    static func shownModes(_ available: [StoryMode], emphasized: StoryMode? = nil) -> [StoryMode] {
        let ordered = StoryMode.displayOrder.filter(available.contains)
        guard let emphasized, ordered.contains(emphasized) else { return ordered }
        return [emphasized] + ordered.filter { $0 != emphasized }
    }

    // MARK: - Desteklenen yaş

    /// Bu yaş için masal yazılmış mı (C turu, 21 Ekim 2026).
    ///
    /// `authored` listesi katalogdan gelir, buradan değil: bu fonksiyon
    /// "3-6 destekleniyor" kuralını bilmez, yalnızca verilen listeye bakar.
    /// Böylece 7-8 için ilk masal yazıldığında değişecek bir satır kalmıyor.
    ///
    /// Liste boşsa `true` döner. Katalog okunamadığında çocuğa "senin yaşın
    /// için masal yok" demek yanlış olur: hata içerikte değil yüklemede, ve o
    /// hatanın kendi ekranı var.
    static func supportsAge(_ age: Int, authored: [AgeBand]) -> Bool {
        authored.isEmpty || authored.contains(AgeBandResolver.band(forAge: age))
    }

    /// Masal yazılabilecek **başka** çocuklar, verilen çocuk dışında.
    ///
    /// Açıklama ekranı yalnızca bunlar varken "başka bir çocuk seç" diyebilir;
    /// yoksa teklif edilecek bir şey yok ve ekran yalnızca açıklar.
    static func supportedAlternatives(
        to childID: UUID, among profiles: [UserProfile], authored: [AgeBand]
    ) -> [UserProfile] {
        profiles.filter { $0.id != childID && supportsAge($0.age, authored: authored) }
    }

    // MARK: - Açılış

    /// Ana sayfadan bir modla gelindiyse ikinci adım, yoksa birinci.
    ///
    /// Preset bu çocuğun bandında kurulamıyorsa (profil değişti, ya da başka
    /// bir çağıran kurulamayan bir mod verdi) akış birinci adımdan açılır:
    /// seçildiğinde hiçbir şey üretemeyecek bir mod sessizce geçirilmez.
    ///
    /// Preset ile açılış fikir adımını bayrak açıkken de atlar. Bu bilinçli:
    /// ebeveyn ana sayfada kararını verdi ve kart "Masalda kimler olsun?"
    /// adımına söz veriyor.
    static func openingPhase(preset: StoryMode?, available: [StoryMode]) -> Opening {
        guard let preset, available.contains(preset) else { return .mode }
        return .companion(preset)
    }

    // MARK: - Okul öncesi: önce arkadaş (26 Kasım 2026, Batuhan K1-K4)

    /// Okul öncesi ızgarasının sabit sırası. Son seçilen öne alınmaz: çocuk
    /// arkadaşını yerinden tanır (`cocuk-akisi-is-tanimi.md`).
    static let littleFriendOrder = [
        "companion_hedgehog_pilot_001",  // Kestane
        "companion_bear_001",            // Böğürtlen
        "companion_fox_pilot_001",       // Tarçın
        "companion_owl_pilot_001",       // Yıldız
        "companion_city_cat_001",        // Simit
    ]

    /// Beş arkadaş ızgarası en çok beş arkadaş + Sürpriz: altı karo.
    static let littleFriendLimit = 5

    /// Kaynağın verdiği arkadaşlar, ızgaranın sabit sırasıyla; sırada olmayan
    /// (olmaması gerekir) sona, geldiği sırayla.
    static func orderedLittleFriends(_ friends: [CompanionChoice]) -> [CompanionChoice] {
        func rank(_ id: String) -> Int { littleFriendOrder.firstIndex(of: id) ?? littleFriendOrder.count }
        return Array(friends.enumerated()
            .sorted { (rank($0.element.id), $0.offset) < (rank($1.element.id), $1.offset) }
            .map(\.element)
            .prefix(littleFriendLimit))
    }

    /// Okul öncesi akış "önce arkadaş" sırasıyla mı açılır?
    ///
    /// Yalnızca beş arkadaş bu çocuğa en az bir modda yazabiliyorsa (bayrak
    /// açık, yaş ve güvenlik uygun). Masal ailem'den biriyle açılan akış
    /// bugünkü sırada kalır: aile isteği P56'ya gidemez, beşliyi göstermek
    /// tutulmayacak bir söz olurdu.
    static func littleUsesFriendFirst(pilotFriends: [CompanionChoice], hasPresetFamily: Bool) -> Bool {
        !pilotFriends.isEmpty && !hasPresetFamily
    }

    /// Masalı kim yazacak ve onay ekranı arkadaşı gösterebilir mi (K4).
    struct LittleCast: Equatable {
        /// Motora giden arkadaş; `nil` motor seçer.
        let companionID: String?
        /// Seçilen arkadaş masalda gerçekten olacak. `false` ise onay ekranı
        /// portre yerine Sürpriz gösterir.
        let keepsFriend: Bool
    }

    /// Konu yoksa istek beşliye gider ve arkadaş korunur. Konu seçildiyse istek
    /// eski motora düşer (K4): arkadaş eski katalogda bu konuda yazılabiliyorsa
    /// (`legacyCandidates`) onunla, yoksa motor seçer. Çocuğa tutulmayacak söz
    /// verilmez.
    static func littleCast(chosen: String?, topicID: String?, legacyCandidates: [String]) -> LittleCast {
        guard let chosen else { return LittleCast(companionID: nil, keepsFriend: false) }
        guard topicID != nil else { return LittleCast(companionID: chosen, keepsFriend: true) }
        return legacyCandidates.contains(chosen)
            ? LittleCast(companionID: chosen, keepsFriend: true)
            : LittleCast(companionID: nil, keepsFriend: false)
    }

    /// Okul öncesi "önce arkadaş" yolu: Kim gelsin? → {Arkadaş} ile ne yapalım?
    /// → (konu) → Hazır mısın?. Masal yalnızca onaydaki "Başla" ile yazılır.
    struct LittlePath: Equatable {
        enum Step: Equatable { case friend, mode, topic, confirm }
        /// Bir dokunuşun sonucu: bir adım göster, masalı yaz ya da akışı kapat.
        enum Outcome: Equatable { case show(Step), begin, close }

        private(set) var step: Step = .friend
        /// `nil`: Sürpriz.
        private(set) var companionID: String?
        private(set) var mode: StoryMode?
        private(set) var topicID: String?
        private(set) var hasTopicStep = false

        init() {}

        /// Adım noktalarının etiketleri; konu adımı yalnızca modun konusu varken.
        var labels: [String] {
            hasTopicStep ? ["Kim", "Masal", "Konu", "Hazır"] : ["Kim", "Masal", "Hazır"]
        }

        var stepIndex: Int {
            switch step {
            case .friend:  return 0
            case .mode:    return 1
            case .topic:   return 2
            case .confirm: return labels.count - 1
            }
        }

        /// Arkadaşa (ya da Sürpriz'e) dokunuş: sıradaki soru mod.
        mutating func chooseFriend(_ id: String?) -> Outcome {
            if id != companionID { mode = nil; topicID = nil; hasTopicStep = false }
            companionID = id
            step = .mode
            return .show(step)
        }

        mutating func chooseMode(_ chosen: StoryMode, hasTopicStep topics: Bool) -> Outcome {
            if chosen != mode { topicID = nil }
            mode = chosen
            hasTopicStep = topics
            step = topics ? .topic : .confirm
            return .show(step)
        }

        /// `nil`: "Fark etmez".
        mutating func chooseTopic(_ id: String?) -> Outcome {
            guard step == .topic else { return .show(step) }
            topicID = id
            step = .confirm
            return .show(step)
        }

        /// "Başla": masal yalnızca onay adımında yazılır.
        func start() -> Outcome {
            step == .confirm && mode != nil ? .begin : .show(step)
        }

        /// Geri seçimleri korur; ilk adımda akışı kapatır.
        mutating func back() -> Outcome {
            switch step {
            case .friend:  return .close
            case .mode:    step = .friend
            case .topic:   step = .mode
            case .confirm: step = hasTopicStep ? .topic : .mode
            }
            return .show(step)
        }
    }
}

import Foundation
import StoryEngine

/// Yaratma akışının kararları, görünümün dışında ve test edilebilir.
///
/// Akış (karar: 3 Ekim 2026): mod → "Masalda kimler olsun?". Fikir kartları
/// bayrak arkasında; "Bana sürpriz yap" yalnızca seçecek bir şey varken; ana
/// sayfada seçilen bir mod akışı doğrudan ikinci adımdan açar.
enum StoryCreationSteps {

    /// Akışın hangi adımdan açılacağı.
    enum Opening: Equatable {
        case mode
        case companion(StoryMode)
    }

    /// Fikir adımı yalnızca bayrak açıkken ve bu mod için fikir varken.
    static func showsIdeaStep(hasIdeas: Bool, flag: Bool = StoryIdeaStepAccess.isEnabled()) -> Bool {
        flag && hasIdeas
    }

    /// Adım noktalarının erişilebilirlik etiketleri.
    static func stepLabels(ideaStep: Bool) -> [String] {
        ideaStep ? ["Masal", "Fikir", "Kimler"] : ["Masal", "Kimler"]
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
}

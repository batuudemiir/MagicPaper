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

    /// "Hangi çocuk?" adımı yalnızca seçilecek bir şey varken (16 Ekim 2026).
    ///
    /// Tek çocuklu bir evde bu adım, cevabı belli bir soruyu sormaktır: tek
    /// kart, tek seçenek, bir dokunuş fazladan. Kütüphanedeki arama kutusuyla
    /// aynı kural — bir denetim, işe yarayabileceği kadar seçenek varken
    /// görünür.
    static func showsChildStep(profileCount: Int) -> Bool {
        profileCount >= 2
    }

    /// Alt kategori ayrı bir adım DEĞİL (karar: 16 Ekim 2026).
    ///
    /// Önce ayrı bir ekran olarak yazılmıştı; ürün kararı aynı adımda, modun
    /// kartının altında açılması yönünde. İkinci soru ancak birincisi
    /// cevaplandıktan sonra anlam kazanıyor, ve ayrı ekran ebeveyne ikinci bir
    /// "Devam et" bastırıyordu. Bu yüzden burada bir kural kalmadı: konular
    /// `StoryModeStep` içinde, mod seçilince beliriyor.

    /// Adım noktalarının erişilebilirlik etiketleri.
    ///
    /// Adım sayısı eve göre değişiyor: tek çocuklu evde "Çocuk" adımı yok.
    /// Etiketler tek yerden üretiliyor
    /// ki nokta sayısı ile ekran sayısı ayrışmasın — ayrıştığında kimse fark
    /// etmez, yalnızca "Adım 2 / 3" yanlış yazar.
    static func stepLabels(childStep: Bool = false) -> [String] {
        (childStep ? ["Çocuk"] : []) + ["Masal", "Kimler"]
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

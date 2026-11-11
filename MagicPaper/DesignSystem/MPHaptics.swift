import CoreHaptics
import UIKit

/// Dokunsal geri bildirim.
///
/// Sistemde böyle bir katman yoktu: `UIImpactFeedbackGenerator` doğrudan,
/// buton gövdelerinin içinde, hiçbir ayara bakmadan çağrılıyordu
/// (kaldırıldı — ölü kod, bkz. docs/MagicPaper_Wave0_Stabilization.md §6). Bu, kullanıcının titreşimi kapatmasının
/// hiçbir yolu olmaması demekti.
///
/// Burada üç şey toplanır: tek bir çağrı yüzeyi, kullanıcının açık ayarı, ve
/// jeneratörlerin önceden hazırlanması — hazırlanmamış bir jeneratör ilk
/// dokunuşu 100 ms'ye kadar geciktirir, ki sayfa çevirmede bu gecikme dokunuşu
/// hareketten koparır ve hissi tamamen bozar.
///
/// "Hareketi Azalt"a bakmaz. Titreşim hareket değildir; onu oraya bağlamak,
/// ekrandaki animasyonu azaltmak isteyen birinden dokunsal geri bildirimi de
/// almak olurdu. Kontrol, kullanıcının açıkça çevirdiği `MPSettingsStore.haptics`
/// anahtarıdır.
@MainActor
enum MPHaptics {

    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let notice = UINotificationFeedbackGenerator()
    private static let picker = UISelectionFeedbackGenerator()

    private static var enabled: Bool { MPSettingsStore.shared.haptics }

    // MARK: - Desenler (Faz 13)

    /// İki imza an için AHAP deseni: sayfa ve masal sonu. Dosyalar
    /// `DesignSystem/Haptics`; cihaz Core Haptics desteklemiyorsa ya da dosya
    /// açılmazsa bugünkü jeneratör çalar. Başka hiçbir an desen almaz.
    enum Pattern: String {
        case page = "mp_page"
        case ending = "mp_ending"
    }

    private static var engine: CHHapticEngine?

    private static func hapticEngine() -> CHHapticEngine? {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        if let engine { return engine }
        guard let made = try? CHHapticEngine() else { return nil }
        made.isAutoShutdownEnabled = true
        made.playsHapticsOnly = true
        made.resetHandler = { try? made.start() }
        try? made.start()
        engine = made
        return made
    }

    /// Deseni çalar; çalamazsa `false` döner ve çağıran yedeğe düşer.
    private static func play(_ pattern: Pattern) -> Bool {
        guard let engine = hapticEngine(),
              let url = Bundle.main.url(forResource: pattern.rawValue, withExtension: "ahap") else { return false }
        do {
            try engine.start()
            try engine.playPattern(from: url)
            return true
        } catch {
            return false
        }
    }

    /// Okuyucuya girerken çağrılır. Jeneratörler kısa süre "sıcak" kalır.
    static func prepare() {
        guard enabled else { return }
        light.prepare()
    }

    /// Sayfa yerine oturduğunda — kâğıdın masaya değmesi.
    ///
    /// Yalnızca tamamlanmış bir çevirmede, çevirme başına bir kez. Sürüklerken
    /// değil: parmak hareket ederken titreten bir okuyucu kitap değil, oyuncak
    /// olur.
    static func pageTurn() {
        MPSound.play(.page)
        guard enabled else { return }
        if play(.page) { return }
        light.impactOccurred(intensity: 0.45)
        light.prepare()
    }

    /// Bir seçim değiştiğinde: sekme, segment, anahtar.
    ///
    /// Yalnızca değer gerçekten değiştiyse çağrılır. Zaten seçili olana
    /// dokunmak titretmez, çünkü hiçbir şey olmadı.
    static func selection() {
        guard enabled else { return }
        picker.selectionChanged()
        picker.prepare()
    }

    /// Genel dokunma geri bildirimi.
    static func tap() {
        guard enabled else { return }
        medium.impactOccurred()
    }

    /// Masal sonu (Faz 13): `mp_ending` sesinin üç notasıyla aynı ritim.
    /// Masal başına bir kez; desen yoksa `success()`.
    static func storyEnding() {
        guard enabled else { return }
        if play(.ending) { return }
        notice.notificationOccurred(.success)
    }

    /// Bir şey tamamlandığında: kayıt, paylaşım, ciltleme.
    static func success() {
        guard enabled else { return }
        notice.notificationOccurred(.success)
    }
}

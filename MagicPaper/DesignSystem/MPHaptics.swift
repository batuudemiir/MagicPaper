import UIKit

/// Dokunsal geri bildirim.
///
/// Sistemde böyle bir katman yoktu: `UIImpactFeedbackGenerator` doğrudan,
/// buton gövdelerinin içinde, hiçbir ayara bakmadan çağrılıyordu
/// (`Helpers/PremiumComponents.swift`). Bu, kullanıcının titreşimi kapatmasının
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

    private static var enabled: Bool { MPSettingsStore.shared.haptics }

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
        guard enabled else { return }
        light.impactOccurred(intensity: 0.45)
        light.prepare()
    }

    /// Genel dokunma geri bildirimi.
    static func tap() {
        guard enabled else { return }
        medium.impactOccurred()
    }

    /// Bir şey tamamlandığında — masalın sonu gibi.
    static func success() {
        guard enabled else { return }
        notice.notificationOccurred(.success)
    }
}

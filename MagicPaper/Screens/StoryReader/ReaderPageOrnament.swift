import SwiftUI

/// Sayfanın süslemesi.
///
/// Çocuk kitaplarının sayfası çıplak bir metin bloğu değildir: versal harf,
/// başlık ve bitiş vinyetleri, ince iç çerçeve, süslü künye — bunlar sayfayı
/// "ekran" olmaktan çıkarıp "basılı sayfa" yapan şeyler.
///
/// Hepsi mevcut token'lardan kuruluyor: yeni renk, yeni font, yeni gölge yok.
/// Süsleme okunabilirliğin önüne geçmez (§14) ve hiçbiri animasyonlu değildir —
/// sayfa kıvrımı geçiş sırasında görüntüyü kopyaladığı için hareketli bir süs
/// çevirme boyunca yırtılırdı (§19).
enum ReaderPageOrnament: String, CaseIterable, Identifiable {
    /// Süsleme yok — bugünkü hâl.
    case sade
    /// Paragrafın ilk harfi büyük ve aksan renginde, sonda küçük bir vinyet.
    case versal
    /// Sayfanın içinde ince bir çerçeve, köşelerinde küçük işaretler.
    case cerceve
    /// Kenar boşluğunda küçük bir spot motif.
    case spot

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sade:    return "Sade"
        case .versal:  return "Süslü harf"
        case .cerceve: return "Çerçeve"
        case .spot:    return "Spot motif"
        }
    }

    /// Şimdilik ayar ekranında değil; karşılaştırma için `UserDefaults`'tan
    /// okunuyor. Hangisinin kalacağına bakıldıktan sonra ya varsayılan olur ya
    /// da okuma ayarlarına bir satır olarak girer.
    static var current: ReaderPageOrnament {
        let raw = UserDefaults.standard.string(forKey: "mp_readerOrnament") ?? ""
        return ReaderPageOrnament(rawValue: raw) ?? .sade
    }

    /// Çerçeve metni içeri iter; diğerleri itmez.
    var contentInset: CGFloat {
        self == .cerceve ? MP.S.x5 : 0
    }
}

// MARK: - Versal harf

/// Paragrafın ilk harfi büyük ve aksan renginde.
///
/// Gerçek bir drop cap satırların etrafından dolanır; SwiftUI'da bu, metni
/// elle satırlara bölmeden yapılamaz ve bölmek de Dynamic Type'ı kırar. Burada
/// klasik kitaplardaki *versal* yapılıyor: harf satır içinde kalır, yalnızca
/// daha büyük ve renklidir.
///
/// Çarpan 1.45. Önce 1.9 denendi ve harf ilk satırın satır yüksekliğini
/// şişirdiği için birinci ile ikinci satır arasında görünür bir boşluk açıldı —
/// süs, tam da korumaya çalıştığı satır gridini bozuyordu.
struct VersalParagraph: View {

    let text: String
    let size: CGFloat
    let accent: Color
    let ink: Color

    var body: some View {
        if let first = text.first {
            (
                Text(String(first))
                    .font(.custom(MP.F.display, size: size * 1.45).weight(.bold))
                    .foregroundColor(accent)
                + Text(String(text.dropFirst()))
                    .font(MP.F.read(size))
                    .foregroundColor(ink)
            )
            .lineSpacing(size * 0.72)
        } else {
            Text(text).font(MP.F.read(size)).foregroundColor(ink)
        }
    }
}

// MARK: - Vinyetler

/// Kenar boşluğunda duran küçük çizim.
///
/// Gerçek çocuk kitabında sayfanın süsü, metnin üstüne çekilmiş bir çizgi
/// değil — o klasik kitapların bölüm başı süsüdür. Çocuk kitabında görülen şey
/// kenarda duran küçük bir çizimdir: bir yaprak, bir iz, bir yıldız. Sayfaya
/// ait ama metne karışmayan, sessiz bir işaret.
struct SpotOrnament: View {
    let symbol: String
    let accent: Color

    var body: some View {
        MPIcon(symbol, size: 22, weight: .regular)
            .foregroundStyle(accent.opacity(0.22))
            .accessibilityHidden(true)
    }
}

/// Metnin bittiğini söyleyen üç nokta — klasik kitaplardaki bitiş süsü.
struct TailpieceOrnament: View {
    let accent: Color

    var body: some View {
        HStack(spacing: MP.S.x2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(accent.opacity(index == 1 ? 0.5 : 0.28))
                    .frame(width: index == 1 ? 5 : 4, height: index == 1 ? 5 : 4)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Çerçeve

/// Sayfanın içindeki ince çerçeve ve köşe işaretleri.
///
/// Kenardan içeride durur ve kâğıdın kendisini kesmez: kıvrım sayfanın
/// kenarını kıvırdığı için kenara yapışan bir çerçeve çevirme sırasında
/// bozulurdu.
struct PageFrameOrnament: View {
    let accent: Color

    var body: some View {
        RoundedRectangle(cornerRadius: MP.R.md, style: .continuous)
            .stroke(accent.opacity(0.20), lineWidth: 1)
            .overlay(alignment: .topLeading) { corner }
            .overlay(alignment: .topTrailing) { corner }
            .overlay(alignment: .bottomLeading) { corner }
            .overlay(alignment: .bottomTrailing) { corner }
            .accessibilityHidden(true)
    }

    private var corner: some View {
        Circle()
            .fill(accent.opacity(0.28))
            .frame(width: 5, height: 5)
            .padding(MP.S.x2)
    }
}

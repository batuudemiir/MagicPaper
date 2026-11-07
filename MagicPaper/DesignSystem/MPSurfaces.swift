import SwiftUI

// MARK: - MPAvatar

/// Harf madalyonu. MagicPaper bilinçli olarak çocuk fotoğrafı saklamaz.
struct MPAvatar: View {
    let name: String
    var color: Color? = nil
    var size: CGFloat = 48
    var ring: Bool = false

    /// Ad'dan renk türetmek için yedek küme.
    ///
    /// Burada ayrı bir liste vardı: 8 renkti, `UserProfile.mpColor`'ınki 6.
    /// İkisi de `sum % count` ile seçtiği için aynı çocuk, hangi bileşenin
    /// çizdiğine göre farklı renk alabiliyordu ve 7./8. renk hiçbir zaman
    /// kaydedilemiyordu (saklanan indeks 1–6). Tek kümeye indirildi.
    private static let palette: [Color] = MP.C.avatarAccents

    private var bg: Color {
        if let color { return color }
        let sum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Self.palette[sum % Self.palette.count]
    }

    /// Türkçe i/İ kuralı zorunlu.
    private var letter: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased(with: Locale(identifier: "tr_TR"))
    }

    var body: some View {
        Text(letter)
            .font(.custom(MP.F.display, size: round(size * 0.44)).weight(.heavy))
            // Madalyon bir görsel: harf daireden taşmasın (ad yanında yazılı).
            .dynamicTypeSize(...DynamicTypeSize.large)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundStyle(MP.Palette.kagit0)
            .frame(width: size, height: size)
            .background(Circle().fill(bg))
            .background {
                // Sistemin imzası: 3px koyu alt kenar (CSS: inset 0 -3px 0 rgba(43,29,36,.18))
                if !ring {
                    Circle().fill(MP.C.edgeCircle).offset(y: 3)
                }
            }
            .overlay {
                // Aktif profil: 0 0 0 3px kağıt, 0 0 0 6px zemin rengi
                if ring {
                    ZStack {
                        Circle().strokeBorder(bg, lineWidth: 3).padding(-6)
                        Circle().strokeBorder(MP.C.surfaceCard, lineWidth: 3).padding(-3)
                    }
                }
            }
            .accessibilityLabel(name)
    }
}
extension Color {
    /// CSS `color-mix(in oklab, <renk> <yüzde>%, white)` karşılığı.
    /// **Opak** sonuç üretir: yarı saydam bir zemin `mpEdge`'in düz kenar
    /// rengini altından geçiriyor ve seçili kart komple dolu renk görünüyordu.
    func mpMixedWithWhite(_ fraction: Double) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        let f = CGFloat(max(0, min(1, fraction)))
        return Color(.sRGB,
                     red: Double(r * f + (1 - f)),
                     green: Double(g * f + (1 - f)),
                     blue: Double(b * f + (1 - f)),
                     opacity: 1)
    }
}
// MARK: - MPToast

struct MPToast: View {
    enum Tone { case calm, reward, danger }

    let message: String
    var symbol: String = "checkmark"
    var tone: Tone = .calm

    private var colors: (bg: Color, fg: Color) {
        switch tone {
        case .calm:   return (MP.C.calm, MP.Palette.kagit0)
        case .reward: return (MP.C.reward, MP.Palette.murekkep900)
        case .danger: return (MP.C.danger, MP.Palette.kagit0)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            MPIcon(symbol, size: 18, weight: .bold)
            Text(message)
            Spacer(minLength: 0)
        }
        .font(MP.F.bodySM(.bold))
        .foregroundStyle(colors.fg)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .mpEdge(fill: colors.bg, edge: MP.C.edgeOnColor, radius: MP.R.md)
        .mpShadow(MP.Sh.lifted)
        .padding(.horizontal, MP.S.screenGutter)
        .allowsHitTesting(false)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// Toast sunucusu — 2200ms sonra kendini kapatır, alttan 96px yukarıda durur.
struct MPToastHost: ViewModifier {
    @Binding var toast: MPToastMessage?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast {
                MPToast(message: toast.message, symbol: toast.symbol, tone: toast.tone)
                    .padding(.bottom, 96)
                    .transition(.opacity.combined(with: .offset(y: 8)))
                    .task(id: toast.id) {
                        try? await Task.sleep(nanoseconds: 2_200_000_000)
                        withAnimation(MP.M.gated(MP.M.easeOut)) { self.toast = nil }
                    }
            }
        }
    }
}

struct MPToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    var symbol: String = "checkmark"
    var tone: MPToast.Tone = .calm
}

extension View {
    func mpToast(_ toast: Binding<MPToastMessage?>) -> some View {
        modifier(MPToastHost(toast: toast))
    }
}

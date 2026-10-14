import SwiftUI

/// Ekranın sağ üstündeki **Çocuk · Ebeveyn** anahtarı.
///
/// Ayrı bir Ebeveyn sekmesi vardı ve çocuğun parmağının altında, kilit
/// simgesiyle duruyordu: çocuğa "burada sana kapalı bir yer var" diyen bir
/// sekme. Artık uygulama iki modda yaşıyor; geçiş tek bir yerden, bu
/// anahtardan yapılıyor ve anahtar iki modun da her üst satırında aynı yerde.
///
/// Anahtar yalnızca **niyet** bildirir. Ebeveyn moduna geçişin kapıdan
/// geçmesi `MPAppState`'in işi; bu yüzden topuzun konumu isteğe değil gerçek
/// moda bağlı — kapı iptal edilirse topuz hiç kımıldamamış olur.
///
/// Yüzey Liquid Glass (iOS 26+). Bu, sistemin camı ve yalnızca bu kontrolde:
/// içerik kaydıkça altından geçen bir kontrol. iOS 26 öncesinde aynı rolü
/// sistem materyali üstleniyor. Tasarım dokümanındaki "glass morphism"
/// yasağı yapay cam taklitleri içindi; burada bilinçli bir istisna.
struct MPModeSwitch: View {
    let isParent: Bool
    let onSelect: (_ parent: Bool) -> Void

    @Namespace private var knob
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button { onSelect(!isParent) } label: {
            HStack(spacing: 0) {
                segment(symbol: "face.smiling", isActive: !isParent)
                segment(symbol: "shield", isActive: isParent)
            }
            .padding(MP.S.x1)
            .mpGlassSurface(in: Capsule(style: .continuous))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(MPPressStyle(scales: false))
        // Kaydırınca da çalışır: yön, istenen modu söyler. Karar parmak
        // kalkınca verilir — sürüklerken hiçbir şey hareket etmez.
        .highPriorityGesture(
            DragGesture(minimumDistance: MP.S.x2)
                .onEnded { value in
                    let dx = value.translation.width
                    if dx > 0, !isParent { onSelect(true) }
                    else if dx < 0, isParent { onSelect(false) }
                }
        )
        // Hareketi Azalt açıkken topuz kaymaz, yerinde çapraz geçer.
        .animation(reduceMotion ? MP.M.easeOut : MP.M.spring, value: isParent)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mod")
        .accessibilityValue(isParent ? "Ebeveyn modu" : "Çocuk modu")
        .accessibilityHint(isParent
            ? "Çocuk moduna dönmek için dokun"
            : "Ebeveyn moduna geçmek için dokun, küçük bir işlem sorulacak")
        .accessibilityAddTraits(.isButton)
    }

    /// Yalnızca simge. Hangi tarafın etkin olduğunu renk değil topuz söyler.
    private func segment(symbol: String, isActive: Bool) -> some View {
        MPIcon(symbol, size: MP.G.md, weight: isActive ? .bold : .semibold)
            .foregroundStyle(isActive ? MP.C.brand : MP.C.textMuted)
            .frame(width: MP.S.x8, height: MP.S.x8)
            .background {
                if isActive {
                    knobShape.transition(.opacity)
                }
            }
    }

    @ViewBuilder
    private var knobShape: some View {
        let shape = Circle()
            .fill(MP.C.surfaceCard)
            .mpShadow(MP.Sh.knob)
        if reduceMotion {
            shape
        } else {
            shape.matchedGeometryEffect(id: "knob", in: knob)
        }
    }
}

#Preview("MPModeSwitch") {
    struct Demo: View {
        @State private var parent = false
        var body: some View {
            MPModeSwitch(isParent: parent) { parent = $0 }
                .padding(MP.S.screenGutter)
                .mpScreenBackground()
        }
    }
    return Demo()
}

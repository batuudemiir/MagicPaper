import SwiftUI

// MARK: - MPStepDots

/// Sihirbazda her zaman 3 adım. Aktif nokta 30px'e uzar.
struct MPStepDots: View {
    var total: Int = 3
    var current: Int = 0
    var labels: [String]? = nil

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i < current ? MP.C.brandTrack : (i == current ? MP.C.brand : MP.C.borderHairline))
                    .frame(width: i == current ? 30 : 8, height: 8)
                    .accessibilityLabel(labels?[safe: i] ?? "Adım \(i + 1)")
            }
        }
        .animation(MP.M.gated(MP.M.spring), value: current)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - MPSheet

/// Sistem sheet'inin içerik düzeni: başlık ve Kapat, kayan içerik, alt düğme
/// (karar: 7 Kasım 2026). Sunumu, tutamağı ve karartmayı sistem yapar (`mpSheet`);
/// kendi katmanımız yok. `onClose` verilmezse zorunlu seçim içerir, aşağı çekilmez.
struct MPSheet<Content: View, Footer: View>: View {
    var title: String? = nil
    var onClose: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: MP.S.x3) {
                if let title {
                    Text(title).font(MP.F.displaySM()).foregroundStyle(MP.C.textTitle)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: 0)
                if let onClose {
                    MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat", action: onClose)
                }
            }
            .padding(.top, MP.S.x5)
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.bottom, MP.S.x2)

            ScrollView {
                content()
                    .padding(.horizontal, MP.S.screenGutter)
                    .padding(.bottom, MP.S.x5)
                    .padding(.top, MP.S.x1)
            }

            footer()
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.bottom, MP.S.x3)
        }
        .interactiveDismissDisabled(onClose == nil)
        .mpSheet(.half)
    }
}

extension MPSheet where Footer == EmptyView {
    init(title: String? = nil, onClose: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, onClose: onClose, content: content) { EmptyView() }
    }
}

import SwiftUI

// MARK: - MPSheet

/// Sistem sheet'inin içerik düzeni: başlık ve Kapat, kayan içerik, alt düğme
/// (karar: 7 Kasım 2026). Sunumu, tutamağı ve karartmayı sistem yapar (`mpSheet`);
/// kendi katmanımız yok. `onClose` verilmezse zorunlu seçim içerir, aşağı çekilmez.
struct MPSheet<Content: View, Footer: View>: View {
    var title: String? = nil
    var onClose: (() -> Void)? = nil
    /// Ebeveyn alanında açılan pencere ebeveyn zeminini alır (`mpSheet(area:)`).
    var area: MPArea = .kid
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
        .mpSheet(area == .parent ? .full : .half, area: area)
    }
}

extension MPSheet where Footer == EmptyView {
    init(title: String? = nil, onClose: (() -> Void)? = nil, area: MPArea = .kid,
         @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, onClose: onClose, area: area, content: content) { EmptyView() }
    }
}

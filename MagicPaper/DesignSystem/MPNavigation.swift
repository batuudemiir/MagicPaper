import SwiftUI

// MARK: - MPTabBar

/// Uygulamanın kök navigasyonu: 4 sekme + ortada yükseltilmiş (+).
/// Masal yaratma her yerden tek dokunuş uzakta olmalı.
struct MPTabBar: View {
    struct Item: Identifiable, Hashable {
        let value: String
        let label: String
        let symbol: String
        var id: String { value }
    }

    let items: [Item]           // tam olarak 4 öğe
    @Binding var selection: String
    var createLabel: String = "Masal yarat"
    let onCreate: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                ForEach(items.prefix(2)) { tab(for: $0) }
                Spacer().frame(width: 78)
                ForEach(items.dropFirst(2).prefix(2)) { tab(for: $0) }
            }
            .frame(height: MP.S.tabBarHeight, alignment: .bottom)

            Button(action: onCreate) {
                MPIcon("plus", size: 30, weight: .bold)
                    .foregroundStyle(MP.C.textOnBrand)
                    .frame(width: 64, height: 64)
                    .mpEdge(fill: MP.C.brand, edge: MP.C.brandEdge, radius: MP.R.pill, width: MP.E.widthLG)
                    .mpShadow(MP.Sh.brand)
            }
            .buttonStyle(MPPressStyle(scales: false))
            .offset(y: -22)
            .accessibilityLabel(createLabel)
        }
        .frame(height: MP.S.tabBarHeight)
        // Zemin alt güvenli alana taşar: bar 76px içerik + altında home
        // göstergesi boşluğu (02-COMPONENTS.md "76px + padding-bottom 22px").
        .background(alignment: .top) {
            barBackground.ignoresSafeArea(edges: .bottom)
        }
    }

    /// `rgba(255,255,255,.92)` + `blur(16px)` — sistem materyali değil;
    /// `.regularMaterial` bu paletin içinde griye çalıyordu.
    private var barBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(MP.Palette.kagit0.opacity(0.92))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(MP.C.borderHairline)
                    .frame(height: 2)
            }
    }

    private func tab(for item: Item) -> some View {
        let isActive = item.value == selection
        return Button {
            selection = item.value
        } label: {
            VStack(spacing: 3) {
                MPIcon(item.symbol, size: 24)
                Text(item.label).font(MP.F.caption(isActive ? .bold : .semibold))
            }
            .foregroundStyle(isActive ? MP.C.brand : MP.C.textFaint)
            .frame(maxWidth: .infinity)
            // Etiketler barın altına yakın dursun; üstten hizalıyken
            // altta ~26pt boşluk kalıyor, cihazın güvenli alanıyla birlikte
            // bar havada duruyor gibi görünüyordu.
            .padding(.bottom, 6)
        }
        .buttonStyle(.plain)
        .animation(MP.M.gated(MP.M.easeOut), value: isActive)
    }
}

// MARK: - MPNavBar

struct MPNavBar<Trailing: View>: View {
    var title: String? = nil
    var subtitle: String? = nil
    var onBack: (() -> Void)? = nil
    var backLabel: String = "Geri"
    var isTransparent: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                MPIconButton(symbol: "chevron.left", label: backLabel,
                             tone: isTransparent ? .glass : .paper, action: onBack)
            }
            VStack(alignment: .leading, spacing: 0) {
                if let title {
                    Text(title)
                        .font(MP.F.displaySM())
                        .mpTightTracking(21)
                        .foregroundStyle(MP.C.textTitle)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                if let subtitle {
                    Text(subtitle).font(MP.F.labelSM(.regular)).foregroundStyle(MP.C.textMuted)
                }
            }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, MP.S.screenGutter)
        .frame(minHeight: MP.S.navBarHeight)
        .background(isTransparent ? Color.clear : MP.C.surfaceApp)
    }
}

extension MPNavBar where Trailing == EmptyView {
    init(title: String? = nil, subtitle: String? = nil, onBack: (() -> Void)? = nil,
         backLabel: String = "Geri", isTransparent: Bool = false) {
        self.init(title: title, subtitle: subtitle, onBack: onBack,
                  backLabel: backLabel, isTransparent: isTransparent) { EmptyView() }
    }
}

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
                    .fill(i < current ? MP.Palette.gul200 : (i == current ? MP.C.brand : MP.Palette.kagit300))
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

/// Alt sayfa. MagicPaper'da her ikincil aksiyon ekran push etmek yerine burada açılır.
/// `onClose` verilmezse zorunlu seçim içerir ve dokunuşla kapanmaz.
struct MPSheet<Content: View, Footer: View>: View {
    var title: String? = nil
    var onClose: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        ZStack(alignment: .bottom) {
            MP.C.scrim
                .ignoresSafeArea()
                .onTapGesture { onClose?() }
                .transition(.opacity)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    if let title {
                        Text(title).font(MP.F.displaySM()).foregroundStyle(MP.C.textTitle)
                    }
                    Spacer(minLength: 0)
                    if let onClose {
                        Button(action: onClose) {
                            MPIcon("xmark", size: 17, weight: .bold)
                                .foregroundStyle(MP.C.textBody)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(MP.C.surfaceSunken))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Kapat")
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .overlay(alignment: .top) {
                    Capsule().fill(MP.C.borderStrong).frame(width: 44, height: 5).padding(.top, 8)
                }

                ScrollView { content().padding(.horizontal, 20).padding(.bottom, 20).padding(.top, 4) }

                footer().padding(.horizontal, 20).padding(.bottom, 12)
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.86)
            .background(
                MP.C.surfaceCard
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: MP.R.sheet, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: MP.R.sheet, style: .continuous))
            )
            .mpShadow(MP.Sh.sheet)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(MP.M.gated(MP.M.spring), value: true)
    }
}

extension MPSheet where Footer == EmptyView {
    init(title: String? = nil, onClose: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, onClose: onClose, content: content) { EmptyView() }
    }
}

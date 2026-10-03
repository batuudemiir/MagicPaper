import SwiftUI

// MARK: - MPTabBar

/// Uygulamanın kök navigasyonu.
///
/// Yaratma eylemi barın ÜSTÜNDE yükseltilmiş bir hap değil, barın İÇİNDE bir
/// öğe. Yükseltilmiş biçim iki bedel getiriyordu: içeriğin üstüne biniyordu —
/// ana sayfada bölüm başlıklarını kapatıyordu — ve barın kendi ritmini bozuyor,
/// sekmelerin ortasında hiçbir şeye ait olmayan bir boşluk bırakıyordu.
///
/// Eylem hâlâ gezinmeden ayrı duruyor, ama artık ayrımı yükseklikle değil
/// renkle yapıyor: marka rengindeki tek öğe odur, ve seçilebilir bir yer
/// olmadığı için hiçbir zaman "aktif sekme" gibi görünmez.
struct MPTabBar: View {
    struct Item: Identifiable, Hashable {
        /// Öğe bir yere mi götürüyor, yoksa bir iş mi yapıyor.
        enum Kind: Hashable { case destination, action }

        let value: String
        let label: String
        let symbol: String
        var kind: Kind = .destination
        var id: String { value }
    }

    let items: [Item]
    @Binding var selection: String
    let onCreate: () -> Void

    /// Ekranların alttan bırakması gereken boşluk. Artık taşma yok.
    static var reservedHeight: CGFloat { MP.S.tabBarHeight }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                switch item.kind {
                case .destination: tab(for: item)
                case .action:      actionTab(for: item)
                }
            }
        }
        .frame(height: MP.S.tabBarHeight, alignment: .bottom)
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
            guard item.value != selection else { return }
            MPHaptics.selection()
            // Gösterge bir sekmeden ötekine kayar. "Hareketi Azalt" açıkken
            // kaymaz, yerinde belirip söner: aynı anlam, hareketsiz.
            withAnimation(reduceMotion ? MP.M.easeOut : MP.M.base) {
                selection = item.value
            }
        } label: {
            slot(symbol: item.symbol, label: item.label,
                 tint: isActive ? MP.C.brand : MP.C.textFaint,
                 isBold: isActive, isActive: isActive)
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityLabel(item.label)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    @Namespace private var indicator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Seçili sekmenin simgesinin arkasındaki yumuşak hap.
    ///
    /// Seçimi yalnızca renk göstermesin diye var (Differentiate Without
    /// Color). Tek bir hap sekmeler arasında kayar; Hareketi Azalt açıkken
    /// her sekme kendi hapını çapraz geçişle gösterir.
    @ViewBuilder
    private func activeIndicator(_ isActive: Bool) -> some View {
        if isActive {
            let pill = Capsule().fill(MP.C.brandSoft)
                .frame(width: MP.S.x10 - MP.S.x2, height: MP.S.x7)
            if reduceMotion {
                pill.transition(.opacity)
            } else {
                pill.matchedGeometryEffect(id: "tab-indicator", in: indicator)
            }
        }
    }

    /// Eylem öğesi. Simgesi dolu bir dairenin içinde durur: aynı satırda,
    /// aynı yükseklikte, ama bir sekme olmadığı bir bakışta belli.
    private func actionTab(for item: Item) -> some View {
        Button {
            MPHaptics.tap()
            onCreate()
        } label: {
            VStack(spacing: 3) {
                MPIcon(item.symbol, size: 20, weight: .bold)
                    .foregroundStyle(MP.C.textOnBrand)
                    .frame(width: 38, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: MP.R.pill, style: .continuous)
                            .fill(MP.C.brand)
                    )
                Text(item.label)
                    .font(MP.F.caption())
                    .foregroundStyle(MP.C.brand)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 6)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(item.label)
    }

    private func slot(symbol: String, label: String, tint: Color, isBold: Bool,
                      isActive: Bool) -> some View {
        VStack(spacing: 3) {
            MPIcon(symbol, size: 24)
                .frame(height: 30)
                .background { activeIndicator(isActive) }
            Text(label)
                .font(MP.F.caption(isBold ? .bold : .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        // Sekmenin tamamı dokunulabilir: simge ile etiket arası ve kenarlar
        // dahil. Önceden yalnızca çizili pikseller tepki veriyordu.
        .contentShape(Rectangle())
        // Etiketler barın altına yakın dursun; üstten hizalıyken
        // altta ~26pt boşluk kalıyor, cihazın güvenli alanıyla birlikte
        // bar havada duruyor gibi görünüyordu.
        .padding(.bottom, 6)
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
                                // Görünen daire küçük kalır, dokunma alanı
                                // ~50pt; düzen değişmez.
                                .padding(MP.S.x2)
                                .contentShape(Rectangle())
                                .padding(-MP.S.x2)
                        }
                        .buttonStyle(MPPressStyle(.highlight))
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

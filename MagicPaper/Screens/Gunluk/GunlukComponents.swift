// GunlukComponents.swift
// Günlük (FAZ 20) yapı taşları: odak noktalı boyalı kapak, koyu seçimli çip,
// raf başlığı, raf kartı, sıralı seçki kartı, "Kaldığın yerden" kartı.
// Ekranlar: Gunluk, GunlukRaf, KlasikDetay, SeriKlasik (İrem'in demo canvas'ı).

import SwiftUI

// MARK: - Kapak

/// Boyalı kapak: yüzeyi doldurur, `focus` CSS `object-position` gibi neyin
/// görünür kalacağını seçer. Çizimi henüz gelmemiş kapak düz renkli bir yedek
/// olur (Rapunzel kuralının tek istisnası, `pendingCovers`).
struct ClassicCoverImage: View {
    let asset: String
    var focus: ClassicFocus = .center
    /// Yedek kapağın rengini seçmek için.
    var seed: String = ""
    /// Büyük sahnede (vitrin, detay, seri): yedek kapak koyu tonda çizilir ki
    /// üstündeki karartma çamurlu bir griye dönmesin.
    var onStage: Bool = false

    var body: some View {
        GeometryReader { geo in
            if let image = UIImage(named: asset) {
                let size = Self.fillSize(image: image.size, frame: geo.size)
                Image(uiImage: image)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .offset(x: (geo.size.width - size.width) * focus.x,
                            y: (geo.size.height - size.height) * focus.y)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                    .clipped()
            } else {
                let tone = Self.fallbackTone(seed)
                // Ana sayfanın dili: pastel ton yalnızca zeminde, simge koyu tonda.
                ZStack {
                    onStage ? tone.deep : tone.soft
                    MPIcon("book.closed", size: min(geo.size.width, geo.size.height) * (onStage ? 0.22 : 0.28),
                           weight: .regular)
                        .foregroundStyle(onStage ? tone.soft : tone.deep)
                        .offset(y: onStage ? -geo.size.height * 0.12 : 0)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// Çerçeveyi taşmadan dolduran boyut (scaledToFill).
    static func fillSize(image: CGSize, frame: CGSize) -> CGSize {
        guard image.width > 0, image.height > 0 else { return frame }
        let scale = max(frame.width / image.width, frame.height / image.height)
        return CGSize(width: image.width * scale, height: image.height * scale)
    }

    private static let fallbackTones: [MPWorldTone] = [.green, .peach, .sky, .lav, .mint, .pink, .yellow]

    static func fallbackTone(_ seed: String) -> MPWorldTone {
        let sum = seed.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return fallbackTones[abs(sum) % fallbackTones.count]
    }
}

/// Rafta duran kapak: köşe 14; derinlik Ana sayfadaki gibi sert alt kenardan
/// (`mpKidSurface`), gölgeden değil.
struct ClassicCoverTile: View {
    let asset: String
    var focus: ClassicFocus = .center
    var seed: String = ""
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ClassicCoverImage(asset: asset, focus: focus, seed: seed)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
            .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.md)
    }
}

// MARK: - Çip

/// Günlük'ün çipi: seçili olan mürekkep rengi, diğerleri gömük krem.
struct GunlukChip: View {
    let title: String
    var isSelected: Bool = false
    /// Sağdaki küçük simge: "Kategoriler"de aşağı ok, süzgeçte çarpı.
    var trailingIcon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.xxs) {
                Text(title).mpText(.callout).lineLimit(1)
                if let trailingIcon {
                    MPIcon(trailingIcon, size: MP.G.xs, weight: .bold).accessibilityHidden(true)
                }
            }
            .foregroundStyle(isSelected ? MPColor.textOnAction : MPColor.textPrimary)
            .padding(.horizontal, MPSpacing.md + 2)
            .frame(minHeight: 34)
            .background(isSelected ? MPColor.textPrimary : MPColor.backgroundSunken, in: Capsule())
            .contentShape(Capsule().inset(by: -(MP.S.tapMin - 34) / 2))
        }
        .buttonStyle(MPPressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Kartlar

/// Raftaki öğe: kapak, başlık, ikinci satır.
struct ClassicShelfCard: View {
    let title: String
    let meta: String
    let cover: String
    var focus: ClassicFocus = .center
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                ClassicCoverTile(asset: cover, focus: focus, seed: title, width: width, height: height)
                VStack(alignment: .leading, spacing: 1) {
                    // İki satır: "Kırmızı Başlıklı Kız" dar kartta kesilmesin.
                    Text(title).mpText(.callout).foregroundStyle(MPColor.textPrimary)
                        .lineLimit(2).multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(meta).mpText(.caption).foregroundStyle(MPColor.textSecondary).lineLimit(1)
                }
                .padding(.horizontal, MPSpacing.xxs / 2)
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(meta)")
    }
}

extension ClassicShelfCard {
    init(item: ClassicItem, width: CGFloat, height: CGFloat, action: @escaping () -> Void) {
        self.init(title: item.title, meta: item.meta, cover: item.cover, focus: item.coverFocus,
                  width: width, height: height, action: action)
    }
}

/// "Bu haftanın seçkisi": kapağın arkasında büyük sıra numarası.
struct RankedPickCard: View {
    let rank: Int
    let item: ClassicItem
    let action: () -> Void

    private let coverWidth: CGFloat = 112
    private let coverHeight: CGFloat = 168

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Text("\(rank)")
                    .font(.mpRankNumeral)
                    .tracking(-9)
                    .foregroundStyle(MPColor.classicRank)
                    .dynamicTypeSize(.large)
                    .fixedSize()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .offset(y: 14)
                    .accessibilityHidden(true)
                ClassicCoverTile(asset: item.cover, focus: item.coverFocus, seed: item.title,
                                 width: coverWidth, height: coverHeight)
            }
            .frame(width: rank >= 10 ? 176 : 150, height: coverHeight)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel("\(rank). \(item.title)")
    }
}

/// "Kaldığın yerden": yatay kırpım, ilerleme çubuğu, kalan süre.
struct ContinueClassicCard: View {
    let item: ClassicsLibrary.InProgress
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                ClassicCoverImage(asset: item.cover, focus: item.coverFocus, seed: item.title)
                    .frame(width: 252, height: 142)
                    .overlay(alignment: .bottom) {
                        GeometryReader { geo in
                            Capsule().fill(MPColor.backgroundSurface.opacity(0.6))
                                .overlay(alignment: .leading) {
                                    Capsule().fill(MPColor.textPrimary)
                                        .frame(width: geo.size.width * item.fraction)
                                }
                        }
                        .frame(height: 4)
                        .padding(.horizontal, MPSpacing.md)
                        .padding(.bottom, MPSpacing.sm + 2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                    .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.md)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title).mpText(.callout).foregroundStyle(MPColor.textPrimary).lineLimit(1)
                    Text("\(item.minutesLeft) dk kaldı").mpText(.caption).foregroundStyle(MPColor.textSecondary)
                }
                .padding(.horizontal, MPSpacing.xxs / 2)
            }
            .frame(width: 252, alignment: .leading)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.minutesLeft) dakika kaldı")
        .accessibilityHint("Kaldığın yerden devam eder")
    }
}

/// Yatay kaydırılan raf.
///
/// `inset` verilmezse ekran kenarından kenarına kayar (çip satırı). Bir
/// `GunlukSection` kartının içindeyken kartın iç boşluğuyla başlar ve kartın
/// kenarında kesilir: kart içinde kart görünmez, kenar temiz kalır.
struct GunlukRow<Content: View>: View {
    var spacing: CGFloat = 14
    var inset: CGFloat? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        if let inset {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: spacing) { content() }
                    .padding(.horizontal, inset)
                    // Kapakların sert alt kenarı kesilmesin.
                    .padding(.bottom, MP.E.widthLG + MPSpacing.xxs)
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: spacing) { content() }
                    .padding(.horizontal, MPSpacing.screenH)
                    .padding(.vertical, MPSpacing.xxs)
            }
            .scrollClipDisabled()
            .padding(.horizontal, -MPSpacing.screenH)
        }
    }
}

// MARK: - Bölüm kartı

/// Günlük'ün her rafı Ana sayfadaki bölüm kartı gibi tek bir kart: beyaz zemin,
/// lavanta kenar, sert alt kenar (`mpKidSurface`, `MPRadius.card`); başlık
/// kartın üst satırında, sağda "tümü" oku. Raf kartın içinde kayar.
struct GunlukSection<Content: View>: View {
    let title: String
    var action: (() -> Void)? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            HStack(alignment: .center, spacing: MPSpacing.sm) {
                Text(title).mpText(.headline).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                if let action {
                    Button(action: action) {
                        MPIcon("chevron.right", size: MP.G.md, weight: .bold)
                            .foregroundStyle(MPColor.actionPrimary)
                            .frame(width: MPSize.minTouchParent, height: MPSize.minTouchParent)
                            .background(MPWorldTone.lav.soft, in: Circle())
                    }
                    .buttonStyle(MPPressStyle())
                    .accessibilityLabel("\(title): tümü")
                }
            }
            .padding(.horizontal, MPSpacing.lg)
            content
        }
        .padding(.vertical, MPSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
    }
}

/// Alt barın (Ana sayfa · Günlük · Yarat · Kitaplık · Köşem) kapladığı yükseklik.
/// Günlük `NavigationStack` içinde durduğu için kök görünümdeki alt bar
/// boşluğu (`safeAreaInset`) kaydırma alanına ulaşmıyor; sayfalar bu kadar
/// alt boşlukla biter ki son kart barın altında kalmasın.
enum GunlukLayout {
    /// iOS 26'da alt bar `safeAreaBar` ile kaydırma alanına kendi boşluğunu
    /// verir; burada yalnızca Ana sayfadaki kadar nefes payı kalır (yoksa son
    /// kartın altında barın iki katı boşluk açılıyordu).
    static var bottomClearance: CGFloat {
        if #available(iOS 26.0, *) { return MPSpacing.xxxl }
        return MPSize.kidTabBarHeight + MPSize.minTouchKid
    }
}


// MARK: - Sahne

extension GunlukLayout {
    /// Sahnenin (vitrin, detay ve seri üst görseli) alt köşe yarıçapı.
    static let stageRadius: CGFloat = MPRadius.input
}

extension View {
    /// Tam genişlikte boyalı sahnenin bitişi: alt köşeler yuvarlak, altta Ana
    /// sayfanın kartları gibi sert kenar. Vitrin, detay ve seri aynı dili kullanır.
    func gunlukStage() -> some View {
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: GunlukLayout.stageRadius,
                                           bottomTrailingRadius: GunlukLayout.stageRadius, style: .continuous)
        return clipShape(shape)
            .background(alignment: .bottom) {
                shape.fill(MPColor.brandNight)
                    .frame(height: GunlukLayout.stageRadius * 2)
                    .offset(y: MP.E.widthLG)
            }
    }
}

/// Günlük'ün tek dolgun düğmesi: düz mor, sert alt kenar (butonda gradient yok).
struct GunlukPrimaryButton: View {
    let title: String
    var systemImage: String = "play"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.sm) {
                MPIcon(systemImage, size: MP.G.md, weight: .bold).accessibilityHidden(true)
                Text(title).mpText(.button)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(MPColor.textOnAction)
            .padding(.horizontal, MPSpacing.xl)
            .frame(maxWidth: .infinity, minHeight: MPSize.buttonHeight)
            .mpKidSurface(MPColor.actionPrimary, edge: MPColor.brandNight, radius: MPSize.buttonHeight / 2)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(title)
    }
}

/// Sahnenin tepesindeki geri ve paylaş düğmeleri: beyaz daire, sert kenar.
struct GunlukStageButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MPIcon(systemImage, size: MP.G.md, weight: .semibold)
                .foregroundStyle(MPColor.textPrimary)
                .frame(width: MPSize.circleButton, height: MPSize.circleButton)
                .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge,
                              radius: MPSize.circleButton / 2)
                .contentShape(Circle().inset(by: -4))
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(label)
    }
}

// MARK: - Sonsuz vitrin

/// Vitrinin sonsuz döngüsü: slaytlar `cycles` tur tekrarlanır, ortadan
/// başlanır; kullanıcı kenara iki tur kalana dek yaklaşınca ortadaki aynı
/// slayta görünmeden dönülür. Tek slayt döngü kurmaz.
enum GunlukLoop {
    static let cycles = 41

    static func length(count: Int) -> Int {
        count > 1 ? count * cycles : count
    }

    static func start(count: Int) -> Int {
        count > 1 ? count * (cycles / 2) : 0
    }

    /// Kenara yakınsa ortadaki eşi; değilse `nil` (yerinde kalır).
    static func recentered(_ position: Int, count: Int) -> Int? {
        guard count > 1 else { return nil }
        let cycle = position / count
        guard cycle < 2 || cycle > cycles - 3 else { return nil }
        return start(count: count) + position % count
    }
}

// MARK: - Raf simgesi

/// Rafın Ana sayfa dilindeki simge kutusu: pastel zemin, koyu simge.
extension ClassicShelf {
    var symbol: String {
        switch self {
        case .klasikler: return "crown"
        case .anadolu:   return "building.columns"
        case .fabllar:   return "sparkles"
        case .seriler:   return "bookmark"
        case .uyku:      return "moon"
        case .besDakika: return "clock"
        case .hayvanlar: return "tree"
        case .sesli:     return "speaker.wave.2"
        }
    }

    var tone: MPWorldTone {
        switch self {
        case .klasikler: return .lav
        case .anadolu:   return .peach
        case .fabllar:   return .mint
        case .seriler:   return .yellow
        case .uyku:      return .sky
        case .besDakika: return .pink
        case .hayvanlar: return .green
        case .sesli:     return .lav
        }
    }
}


// MARK: - Durum çubuğu

/// Sahne yukarı kayınca saat çubuğunun arkası krem olur; kartlar ve yazılar
/// saatin, Dynamic Island'ın altından geçerken okunmaz hale gelmez. Sahne
/// tepedeyken görünmez (boyalı görsel saatin arkasına kadar uzanır).
struct GunlukStatusBarBackdrop: View {
    let visible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Sıfır yükseklikli şerit güvenli alanın tepesinde durur; zemini
        // saat çubuğunun arkasına uzanır.
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: 0)
            .background(alignment: .top) { MPColor.backgroundKid.ignoresSafeArea(edges: .top) }
            .opacity(visible ? 1 : 0)
            .animation(reduceMotion ? nil : MP.M.easeOut, value: visible)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

extension View {
    /// Kaydırma içeriğinin tepesi saat çubuğunun altına girdi mi.
    func gunlukTracksScroll(_ scrolled: Binding<Bool>) -> some View {
        onGeometryChange(for: Bool.self) { $0.frame(in: .scrollView).minY < -MPSpacing.sm } action: {
            scrolled.wrappedValue = $0
        }
    }
}

// MARK: - Kenardan geri

/// Günlük sayfaları gezinme çubuğunu gizliyor; UIKit bu durumda kenardan
/// kaydırarak geri dönmeyi kapatır. Yığında geri dönülecek sayfa varken
/// hareketi yeniden açar (uygulamada çubuğu gizleyen yığın yalnızca Günlük).
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}

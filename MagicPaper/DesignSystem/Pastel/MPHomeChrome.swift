// MPHomeChrome.swift
// 11 · Ana sayfa yenilemesi (13 Ekim 2026): illüstrasyonlu sahne, başlık,
// hero kartı, okuma şeridi, mod kartı ve hepsinin ortak kart yüzeyi.
// Tasarım notu: docs/superpowers/specs/2026-10-13-ana-sayfa-yenileme-design.md

import SwiftUI

// MARK: - Kart yüzeyi: sert alt kenar

extension MPWorldTone {
    /// Kartın alt kenarı ve çerçevesi: tonun koyusundan ince bir iz.
    var edge: Color { deep.opacity(0.22) }
    /// Kitaplık kapağının alt kenarı: çocuğun seçtiği renk (`MPDecor`) burada
    /// görünür, bu yüzden `edge`'den belirgin.
    var coverEdge: Color { deep.opacity(0.55) }
}

extension View {
    /// Çocuk alanı kartı: dolgu, ince çerçeve ve altta sert kenar.
    /// Derinlik gölgeden değil bu kenardan gelir (tasarım yasası, `mpEdge`).
    func mpKidSurface(_ fill: Color, edge: Color, radius: CGFloat = MPRadius.card) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return mpEdge(fill: fill, edge: edge, radius: radius, width: MP.E.widthLG)
            .overlay(shape.strokeBorder(edge, lineWidth: 1))
    }
}

// MARK: - Gökyüzü bandı

/// Başlığın arkasındaki bulutlu bant. Uyku saatinde lacivert gece, hilal ve
/// yıldızlar; geçiş yavaş bir çapraz geçiştir. Bulutlar çok yavaş gidip gelir,
/// Reduce Motion açıkken durur. Tamamı süs: erişilebilirlikten gizli.
struct HomeSky: View {
    let isNight: Bool
    var height: CGFloat = 210
    /// Kayan içeriğin içinde durduğunda saat çubuğunun altına ve yukarı
    /// esnemeye taşan düz gökyüzü payı.
    var bleed: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        VStack(spacing: 0) {
            skyFill.frame(height: bleed)
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack(alignment: .topLeading) {
                    skyFill
                    if isNight { stars(w: w, h: h).transition(.opacity) }
                    cloud(width: w * 0.30, at: CGPoint(x: w * 0.08, y: h * 0.34), sway: 1)
                    cloud(width: w * 0.36, at: CGPoint(x: w * 0.62, y: h * 0.52), sway: -1)
                    cloud(width: w * 0.16, at: CGPoint(x: w * 0.46, y: h * 0.22), sway: 1)
                }
            }
            .frame(height: height)
        }
        .clipShape(WaveBottom())
        .offset(y: -bleed)
        .animation(MP.M.gated(MP.M.slow), value: isNight)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(MP.M.ambient) { drift = true }
        }
    }

    private var skyFill: some View {
        ZStack {
            Rectangle().fill(MPWorldTone.lav.soft)
            Rectangle().fill(MPColor.bedtimeSkyTop).opacity(isNight ? 1 : 0)
        }
    }

    private func cloud(width: CGFloat, at origin: CGPoint, sway: CGFloat) -> some View {
        CloudShape()
            .fill(isNight ? MPColor.readerNightWash : MPColor.backgroundSurface)
            .frame(width: width, height: width * 0.42)
            .offset(x: origin.x + (drift ? MP.S.x2 : -MP.S.x2) * sway, y: origin.y)
    }

    private func stars(w: CGFloat, h: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // Hilal: sarı daireyi gökyüzü renginde ikinci bir daire keser.
            Circle().fill(MPColor.washYellow)
                .overlay(Circle().fill(MPColor.bedtimeSkyTop).offset(x: MP.S.x2 + 3, y: -MP.S.x1))
                .clipShape(Circle())
                .frame(width: 30, height: 30)
                .offset(x: w * 0.52, y: h * 0.36)
            ForEach(Array(Self.starPoints.enumerated()), id: \.offset) { _, p in
                Circle().fill(MPWorldTone.yellow.soft)
                    .frame(width: p.z, height: p.z)
                    .offset(x: w * p.x, y: h * p.y)
            }
        }
    }

    private static let starPoints: [(x: CGFloat, y: CGFloat, z: CGFloat)] = [
        (0.10, 0.16, 3), (0.30, 0.10, 2), (0.52, 0.30, 3), (0.24, 0.46, 2), (0.92, 0.48, 2.5), (0.68, 0.08, 2)
    ]
}

// MARK: - Sahne (illüstrasyonlu başlık)

/// Sahnenin üstündeki Ragi: markanın kendi görseli, ayrı katman. Gündüz kitap
/// okur ve yavaşça nefes alır; gece uyur. Açılışta tepeye süzülür, dokununca
/// bir kez zıplar. Reduce Motion açıkken yerinde durur. Süs: erişilebilirlikten gizli.
struct HomeSceneMascot: View {
    let isNight: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var hop = false

    var body: some View {
        ZStack {
            MascotImage(mascot: .reading, width: 92).opacity(isNight ? 0 : 1)
            MascotImage(mascot: .sleeping, width: 104).opacity(isNight ? 1 : 0)
        }
        .offset(y: hop ? -14 : 0)
        .offset(y: appeared ? 0 : 24)
        .opacity(appeared ? 1 : 0)
        .animation(MP.M.gated(MP.M.slow), value: isNight)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !reduceMotion, !hop else { return }
            MPHaptics.tap()
            withAnimation(MP.M.spring) { hop = true }
            Task {
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(MP.M.spring) { hop = false }
            }
        }
        .onAppear {
            if reduceMotion { appeared = true; return }
            withAnimation(MP.M.spring.delay(0.15)) { appeared = true }
        }
        .accessibilityHidden(true)
    }
}

/// Başlığın altındaki tek satır: yıldız ve üst üste okunan günler (22 Ekim
/// 2026). Çip ve kutu yok; dokununca Benim köşem açılır (çağıran sarar).
struct HomeStatLine: View {
    let stars: Int
    let streak: Int
    /// Başlığın sağında (13 Kasım 2026): yalnızca sayılar ("12 · 3 gün"),
    /// sığmazsa sağa yaslı alt alta. Sesli okuma tam cümleyi söyler.
    var compact: Bool = false

    var body: some View {
        // Büyük yazıda sığmazsa kesilmez, alt alta düşer.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: MPSpacing.xs) {
                if stars > 0 { starItem }
                if stars > 0 && streak > 0 { Text("·").accessibilityHidden(true) }
                if streak > 0 { streakItem }
            }
            VStack(alignment: compact ? .trailing : .leading, spacing: MPSpacing.xxs) {
                if stars > 0 { starItem }
                if streak > 0 { streakItem }
            }
        }
        .mpText(.footnote)
        .fontWeight(compact ? .bold : nil)
        .foregroundStyle(MPColor.textSecondary)
        .frame(minHeight: MPSize.minTouchParent)
        .contentShape(Rectangle())
        .animation(MP.M.gated(MP.M.easeOut), value: stars)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([stars > 0 ? "\(stars) yıldız" : nil,
                             streak > 0 ? "\(streak) gün üst üste" : nil]
            .compactMap { $0 }.joined(separator: ", "))
    }

    private var starItem: some View {
        HStack(spacing: MPSpacing.xs) {
            MPStarMark(size: 15).accessibilityHidden(true)
            Text(compact ? "\(stars)" : "\(stars) yıldız")
                .contentTransition(.numericText(value: Double(stars)))
        }
    }

    private var streakItem: some View {
        HStack(spacing: MPSpacing.xs) {
            MPIcon("flame", size: MP.G.sm, weight: .semibold)
                .foregroundStyle(MPWorldTone.peach.deep)
                .accessibilityHidden(true)
            Text(compact ? "\(streak) gün" : "\(streak) gün üst üste")
                .contentTransition(.numericText(value: Double(streak)))
        }
    }
}

/// Üç tümsekli bulut.
struct CloudShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: r.minX, y: r.midY - r.height * 0.05, width: r.width * 0.5, height: r.height * 0.55))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.22, y: r.minY, width: r.width * 0.45, height: r.height * 0.9))
        p.addEllipse(in: CGRect(x: r.minX + r.width * 0.48, y: r.minY + r.height * 0.28, width: r.width * 0.52, height: r.height * 0.62))
        return p
    }
}

/// Alt kenarı yumuşak dalgalı dikdörtgen.
struct WaveBottom: Shape {
    func path(in r: CGRect) -> Path {
        let wave: CGFloat = 26
        var p = Path()
        p.move(to: .zero)
        p.addLine(to: CGPoint(x: r.maxX, y: 0))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - wave * 0.6))
        p.addQuadCurve(to: CGPoint(x: r.width * 0.5, y: r.maxY - wave * 0.4),
                       control: CGPoint(x: r.width * 0.75, y: r.maxY - wave * 1.4))
        p.addQuadCurve(to: CGPoint(x: 0, y: r.maxY - wave * 0.7),
                       control: CGPoint(x: r.width * 0.25, y: r.maxY + wave * 0.4))
        p.closeSubpath()
        return p
    }
}

// MARK: - Hero kartı

/// "Bu akşamın masalı", dört durum (SCREENS.md 11).
///
/// 22 Ekim 2026: sayfanın tepesindeki tam genişlik sahne bu kartın içine
/// taşındı. Üstte manzara (uyku saatinde gece) ve ekranın tek Ragi'si, altta
/// lavanta zeminde masal ve sayfanın tek birincil düğmesi. Ragi küçüldü ama
/// ön planda (16 Ekim kararı, Batuhan 22 Ekim onayı).
struct HomeHeroCard: View {
    /// 13 Kasım 2026: modlar üç satırdan yan yana üç karoya geçince sahne
    /// 130'dan 188'e çıktı (11 Kasım'da üçüncü satır alt çubuğun altında
    /// kaldığı için 130'a inmişti).
    static let sceneHeight: CGFloat = 188
    /// Sahnedeki kapağın ölçüsü (raf kapağıyla aynı oran).
    static let coverSize = CGSize(width: 66, height: 88)
    let state: TonightState
    var isNight: Bool = false
    /// Bu akşamın masalının kapağı: sahnede, Ragi'nin karşısında. Gece sahnesinde yok.
    var cover: (asset: String, focus: ClassicFocus)? = nil
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            scene
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text(eyebrow).mpText(.footnote).fontWeight(.bold).foregroundStyle(MPColor.actionPrimary)
                Text(title).mpText(.section).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(sub).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                MPButton(title: buttonTitle, systemImage: buttonIcon, size: .hero, fullWidth: true, action: onPrimary)
                    .padding(.top, MPSpacing.sm)
            }
            .padding(MPSpacing.lg)
        }
        .background(MPColor.cardSoft)
        .clipShape(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
    }

    /// Manzara sabit yükseklikte, üstten hizalı: kule, güneş ve ay hep
    /// görünür, kırpılan yalnızca alttaki çayır. Gündüz ve gece çapraz
    /// geçişle; Ragi sağ altta.
    private var scene: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack(alignment: .bottomLeading) {
                MPColor.sceneSkyDay
                Image("Scenes/homeSceneDay").resizable().aspectRatio(contentMode: .fill)
                    .frame(height: Self.sceneHeight, alignment: .top).clipped()
                ZStack {
                    MPColor.sceneSkyNight
                    Image("Scenes/homeSceneNight").resizable().aspectRatio(contentMode: .fill)
                        .frame(height: Self.sceneHeight, alignment: .top).clipped()
                }
                .opacity(isNight ? 1 : 0)
                if let cover, !isNight {
                    ClassicCoverImage(asset: cover.asset, focus: cover.focus, seed: cover.asset)
                        .frame(width: Self.coverSize.width, height: Self.coverSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: MPRadius.sm, style: .continuous))
                        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.deep, radius: MPRadius.sm)
                        .rotationEffect(.degrees(-5))
                        .padding(.leading, MPSpacing.xl)
                        .padding(.bottom, MPSpacing.md)
                        .transition(.opacity)
                }
            }
            .animation(MP.M.gated(MP.M.slow), value: isNight)
            .accessibilityHidden(true)
            HomeSceneMascot(isNight: isNight)
                .scaleEffect(0.8, anchor: .bottomTrailing)
                .padding(.trailing, MPSpacing.lg)
                .padding(.bottom, MPSpacing.sm)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.sceneHeight)
        .clipped()
    }


    private var eyebrow: String { switch state { case .resume: "Kaldığın yerden"; case .unread: "Bu akşamın masalı"; case .readToday: "Bugün okudun"; case .bedtime(let t): "Saat \(t)" } }
    private var title: String { switch state { case .resume(_, let t, _): t; case .unread(let t, _): t; case .readToday: "Yarın yeni bir masal var"; case .bedtime: "Uyku masalı zamanı" } }
    private var sub: String { switch state { case .resume(_, _, let m): m; case .unread(_, let m): m; case .readToday: "İstersen bu akşam bir tane daha yazalım."; case .bedtime: "Kısa, sakin bir masalla günü kapatalım." } }
    private var buttonTitle: String { switch state { case .resume: "Okumaya devam et"; case .unread: "Masalı oku"; case .readToday: "Yeni masal yaz"; case .bedtime: "Uyku masalı yaz" } }
    private var buttonIcon: String { switch state { case .resume: "book"; case .unread: "book"; case .readToday: "wand.and.sparkles"; case .bedtime: "moon.fill" } }
}

// MARK: - Bölüm

/// Ana sayfanın bölümü (15 Ekim, Apple düzeni): kalın başlık içeriğin üstünde,
/// sağında isteğe bağlı bağlantı ("Tümü"); içerik doğrudan beyaz zeminde: bölümü
/// panel değil boşluk ayırır (karar: 7 Kasım 2026). Bütün bölüm başlıkları aynı
/// font, boyut ve ağırlıkta (`title3`).
///
/// Köşe yarıçapı kuralı (15 Ekim): büyük yüzeyler (hero, mod kartları)
/// `card`; küçük bilgi kartları (çipler) `input`; içerideki kutular
/// (ikon kareleri, kapaklar) `md`; rozetler hap biçiminde.
struct HomeSection<Leading: View, Content: View>: View {
    let title: String
    /// Başlığın sağında küçük sayaç ("3 / 8"); bağlantıyla birlikte kullanılmaz.
    var note: String? = nil
    var noteSpoken: String? = nil
    var link: (title: String, action: () -> Void)? = nil
    @ViewBuilder var leading: Leading
    @ViewBuilder var content: Content

    var body: some View {
        // Başlık içeriğine yapışık (12), bölümler birbirinden uzak (32,
        // `HomeView`): her bölüm tek bir bütün gibi okunur.
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            MPSectionHeader(title: title, area: .kid, note: note, noteSpoken: noteSpoken,
                            link: link, leading: { leading })
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension HomeSection where Leading == EmptyView {
    init(title: String, note: String? = nil, noteSpoken: String? = nil,
         link: (title: String, action: () -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, note: note, noteSpoken: noteSpoken, link: link,
                  leading: { EmptyView() }, content: content)
    }
}

// MARK: - Yıldız

/// Markanın yıldızı (imza, 15 Ekim): tek çizim, tek sarı, ince koyu sarı
/// kontur. Yıldız sayacı bunu kullanır. Süs olarak çoğaltılmaz.
struct MPStarMark: View {
    var size: CGFloat

    var body: some View {
        StarShape().fill(MPColor.statusStarIcon)
            .overlay(StarShape().stroke(MPColor.yellowText.opacity(0.45), lineWidth: max(1, size / 24)))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Beş köşeli yıldız şekli.
struct StarShape: Shape {
    func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY)
        let outer = min(r.width, r.height) / 2, inner = outer * 0.45
        var p = Path()
        for i in 0..<10 {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let angle = Double(i) * .pi / 5 - .pi / 2
            let point = CGPoint(x: c.x + CGFloat(cos(angle)) * radius, y: c.y + CGFloat(sin(angle)) * radius)
            i == 0 ? p.move(to: point) : p.addLine(to: point)
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Mod kartı (yeni masal)

// MARK: - Günlük rafı

/// Ana sayfadaki Masallar rafı (15 Ekim, Apple Books rafı gibi): başlıkta "Tümü",
/// altında yatay kayan kapaklar, adı ve süresi. Sayfada tek "bugün" var: "Günün
/// masalı" (7 Kasım 2026). Kapaklar açılışta sırayla süzülür; Reduce Motion'da yerinde.
struct HomeGunlukPreview: View {
    struct Item: Identifiable {
        let id: UUID
        let title: String
        let minutes: Int
        let asset: String
        let focus: ClassicFocus
    }

    /// İlki günün klasiği.
    let items: [Item]
    /// Dokunulan kapağın masalı.
    let onOpen: (UUID) -> Void
    /// "Tümü": Masallar sekmesi.
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false

    var body: some View {
        HomeSection(title: "Masallar", link: ("Tümü", action)) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: MPSpacing.md) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        Button { onOpen(item.id) } label: { tile(item) }
                            .buttonStyle(MPPressStyle())
                            .accessibilityLabel(item.title)
                            .accessibilityHint("Masalın sayfasını açar")
                            .offset(y: arrived ? 0 : MP.S.x5)
                            .opacity(arrived ? 1 : 0)
                            .animation(reduceMotion ? nil : MP.M.spring.delay(0.1 + Double(index) * 0.06), value: arrived)
                    }
                }
                // Sert kenar kırpılmasın.
                .padding(.vertical, MPSpacing.sm)
                .padding(.horizontal, MPSpacing.screenH)
            }
            .padding(.horizontal, -MPSpacing.screenH)
            .padding(.vertical, -MPSpacing.sm)
        }
        .onAppear { arrived = true }
    }

    private func tile(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.xs) {
            ClassicCoverImage(asset: item.asset, focus: item.focus, seed: item.asset)
                .frame(width: 118, height: 158)
                .clipShape(RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.md)
            Text(item.title).mpText(.footnote).fontWeight(.bold).foregroundStyle(MPColor.textPrimary)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                .padding(.top, MPSpacing.xxs)
            Text("\(item.minutes) dakika").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
        }
        .frame(width: 118, alignment: .leading)
    }
}

// MARK: - Giriş

extension View {
    /// Ana sayfa bölümlerinin girişi: uygulama açılışında bir kez, sırayla
    /// hafifçe yukarı kayarak gelir. Sekme değiştirip dönünce tekrarlamaz.
    /// Reduce Motion açıkken yalnızca solma.
    func homeEntrance(_ index: Int) -> some View { modifier(HomeEntrance(index: index)) }
}

private struct HomeEntrance: ViewModifier {
    let index: Int
    /// Açılış başına bir kez.
    @MainActor static var played = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = HomeEntrance.played

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : MP.S.x4)
            .onAppear {
                guard !shown else { return }
                let delay = 0.05 + Double(index) * 0.06
                withAnimation((reduceMotion ? MP.M.easeOut : MP.M.spring).delay(delay)) { shown = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1))
                    HomeEntrance.played = true
                }
            }
    }
}

// MARK: - Mod kartı

/// "Bu akşam nasıl bir masal olsun?" kartının içindeki mod düğmesi: pastel
/// zemin, beyaz kutuda büyük ikon ve mod adı. Kenarsız: kart içinde kart olmaz.
///
/// `badge` öne çıkan modu işaretler (uyku saatinde "Bu akşam"): üst kenara
/// binen etiket ve mor çerçeve. Bilgi yalnızca renkle verilmez, etiket yazılı.
struct HomeModeTile: View {
    let title: String
    let systemImage: String
    let tone: MPWorldTone
    var badge: String? = nil
    /// Yan yana karolar aynı boyda dursun (ana sayfanın mod sırası).
    var fillHeight: Bool = false
    let action: () -> Void

    /// Etiketin yüksekliği: yarısı kadar yukarı çıkıp kenara biner (Dynamic Type ile büyür).
    @State private var badgeHeight: CGFloat = 0

    var body: some View {
        Button(action: action) {
            VStack(spacing: MPSpacing.sm) {
                MPIcon(systemImage, size: MP.G.xl, weight: .semibold)
                    .foregroundStyle(tone.deep)
                    .frame(width: MPSize.iconTile, height: MPSize.iconTile)
                    .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                    .accessibilityHidden(true)
                Text(title).mpText(.supporting).foregroundStyle(MPColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, MPSpacing.md)
            .padding(.horizontal, MPSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: 104, maxHeight: fillHeight ? .infinity : nil)
            .background(tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.input, style: .continuous))
            .overlay {
                if badge != nil {
                    RoundedRectangle(cornerRadius: MPRadius.input, style: .continuous)
                        .strokeBorder(MPColor.actionPrimary, lineWidth: 2)
                }
            }
            .overlay(alignment: .top) {
                if let badge {
                    Text(badge).mpText(.footnote)
                        .foregroundStyle(MPColor.textOnAction)
                        .lineLimit(1)
                        .padding(.horizontal, MPSpacing.sm)
                        .padding(.vertical, MPSpacing.xxs)
                        .background(MPColor.actionPrimary, in: Capsule())
                        // Okuma şeridi gibi tavanlı: etiket ikonu örtmez, mod
                        // adı ve erişilebilirlik etiketi büyümeye devam eder.
                        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { badgeHeight = $0 }
                        .offset(y: -badgeHeight / 2)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(MPPressStyle())
    }
}

#Preview("Ana sayfa parçaları") {
    ScrollView {
        VStack(spacing: MPSpacing.xl) {
            HomeHeroCard(state: .resume(progress: 0.37, title: "Şehri Kurtaran Gün", meta: "Sayfa 3 / 8")) {}
            HomeHeroCard(state: .unread(title: "Ormandaki Fısıltı", meta: "5 dakika")) {}
            HomeHeroCard(state: .readToday) {}
            HomeHeroCard(state: .bedtime(time: "20.30"), isNight: true) {}
            HStack(spacing: MPSpacing.sm) {
                HomeModeTile(title: "Uyku öncesi", systemImage: "moon", tone: .lav) {}
                HomeModeTile(title: "Öğrenelim", systemImage: "sparkles", tone: .mint) {}
                HomeModeTile(title: "Macera", systemImage: "tent", tone: .peach) {}
            }
        }
        .padding(MPSpacing.screenH)
    }
    .background(MPColor.backgroundKid)
}

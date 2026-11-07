// MPHomeChrome.swift
// 11 · Ana sayfa yenilemesi (13 Ekim 2026): illüstrasyonlu sahne, başlık,
// hero kartı, okuma şeridi, mod kartı ve hepsinin ortak kart yüzeyi.
// Tasarım notu: docs/superpowers/specs/2026-10-13-ana-sayfa-yenileme-design.md

import SwiftUI

// MARK: - Kart yüzeyi: sert alt kenar

extension MPWorldTone {
    /// Kartın alt kenarı ve çerçevesi: tonun koyusundan ince bir iz.
    var edge: Color { deep.opacity(0.22) }
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

/// Ana sayfanın üstündeki masal manzarası (13 Ekim, referans: editoryal uygulama
/// hero sahneleri). Görsel bir taslak: kalıcı sürümü illüstratör çizecek.
/// Uyku saatinde aynı sahnenin gece hâline çapraz geçer; alt kenarı sayfanın
/// krem zeminine karışır (malzeme maskesi, arayüz gradyanı değil). Süs:
/// erişilebilirlikten gizli.
struct HomeScene: View {
    let isNight: Bool
    var height: CGFloat = 300
    /// Kayan içeriğin içinde saat çubuğunun altına taşan pay.
    var bleed: CGFloat = 0
    /// Ragi'nin ayaklarının sahnenin alt kenarından yüksekliği: çiplerin üstünde kalır.
    var mascotLift: CGFloat = 44
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            backdrop
            HomeSceneMascot(isNight: isNight)
                .padding(.trailing, MPSpacing.screenH)
                .padding(.bottom, mascotLift)
        }
        .frame(height: height + bleed)
        .offset(y: -bleed)
    }

    /// Maskotsuz manzara: gündüz ve gece aynı kompozisyon, çapraz geçişle.
    /// Görsel ekran genişliğine sığar (kule ve ay kırpılmaz); üstündeki boşluk
    /// görselin en üst gökyüzü rengiyle devam eder.
    private var backdrop: some View {
        ZStack {
            layer(image: "Scenes/homeSceneDay", sky: MPColor.sceneSkyDay)
            layer(image: "Scenes/homeSceneNight", sky: MPColor.sceneSkyNight)
                .opacity(isNight ? 1 : 0)
        }
        .frame(height: height + bleed)
        .frame(maxWidth: .infinity)
        .clipped()
        .mask {
            VStack(spacing: 0) {
                Rectangle()
                LinearGradient(colors: [MPColor.backgroundSurface, MPColor.backgroundSurface.opacity(0)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 56)
            }
        }
        // İki görsel ve üç gradyan maskesi tek dokuya düzleşir: maskeler her
        // kaydırma karesinde ekran dışında yeniden birleştirilmez, hazır görüntü
        // taşınır (başlık bölgesindeki kasma, 16 Ekim).
        .drawingGroup()
        .animation(MP.M.gated(MP.M.slow), value: isNight)
        .accessibilityHidden(true)
    }

    /// Görsel tam genişlikte, doğal oranında; üst kenarı gökyüzü rengine
    /// yumuşakça karışır, dikiş görünmez.
    private func layer(image: String, sky: Color) -> some View {
        ZStack(alignment: .bottom) {
            sky
            Image(image).resizable().aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .mask {
                    VStack(spacing: 0) {
                        LinearGradient(colors: [MPColor.backgroundSurface.opacity(0), MPColor.backgroundSurface],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 110)
                        Rectangle()
                    }
                }
        }
    }
}

/// Sahnenin üstündeki Ragi: markanın kendi görseli, ayrı katman. Gündüz kitap
/// okur ve yavaşça nefes alır; gece uyur. Açılışta tepeye süzülür, dokununca
/// bir kez zıplar. Reduce Motion açıkken yerinde durur. Süs: erişilebilirlikten gizli.
struct HomeSceneMascot: View {
    let isNight: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var breathing = false
    @State private var hop = false

    var body: some View {
        ZStack {
            MascotImage(mascot: .reading, width: 92).opacity(isNight ? 0 : 1)
            MascotImage(mascot: .sleeping, width: 104).opacity(isNight ? 1 : 0)
        }
        .scaleEffect(breathing ? 1.025 : 1, anchor: .bottom)
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
            withAnimation(MP.M.idle.delay(0.6)) { breathing = true }
        }
        .accessibilityHidden(true)
    }
}

/// Başlığın altındaki tek satır: yıldız ve üst üste okunan günler (22 Ekim
/// 2026). Çip ve kutu yok; dokununca Benim köşem açılır (çağıran sarar).
struct HomeStatLine: View {
    let stars: Int
    let streak: Int

    var body: some View {
        // Büyük yazıda sığmazsa kesilmez, alt alta düşer.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: MPSpacing.xs) {
                starItem
                Text("·").accessibilityHidden(true)
                streakItem
            }
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                starItem
                streakItem
            }
        }
        .mpText(.footnote)
        .foregroundStyle(MPColor.textSecondary)
        .frame(minHeight: MPSize.minTouchParent)
        .contentShape(Rectangle())
        .animation(MP.M.gated(MP.M.easeOut), value: stars)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stars) yıldız, \(streak) gün üst üste")
    }

    private var starItem: some View {
        HStack(spacing: MPSpacing.xs) {
            MPStarMark(size: 15).accessibilityHidden(true)
            Text("\(stars) yıldız")
                .contentTransition(.numericText(value: Double(stars)))
        }
    }

    private var streakItem: some View {
        HStack(spacing: MPSpacing.xs) {
            MPIcon("flame", size: MP.G.sm, weight: .semibold)
                .foregroundStyle(MPWorldTone.peach.deep)
                .accessibilityHidden(true)
            Text("\(streak) gün üst üste")
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
    let state: TonightState
    var isNight: Bool = false
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            scene
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text(eyebrow).mpText(.footnote).fontWeight(.bold).foregroundStyle(MPColor.actionPrimary)
                Text(title).mpText(.title3).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(sub).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if case let .resume(progress, _, _) = state { progressBar(progress) }
                MPButton(title: buttonTitle, systemImage: buttonIcon, fullWidth: true, action: onPrimary)
                    .padding(.top, MPSpacing.md)
            }
            .padding(MPSpacing.lg)
        }
        .background(MPColor.cardSoft)
        .clipShape(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
    }

    /// Manzara doğal oranında (kule ve ay kırpılmaz), gündüz ve gece
    /// çapraz geçişle; Ragi sağ altta.
    private var scene: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                MPColor.sceneSkyDay
                Image("Scenes/homeSceneDay").resizable().aspectRatio(contentMode: .fit)
                ZStack {
                    MPColor.sceneSkyNight
                    Image("Scenes/homeSceneNight").resizable().aspectRatio(contentMode: .fit)
                }
                .opacity(isNight ? 1 : 0)
            }
            .animation(MP.M.gated(MP.M.slow), value: isNight)
            .accessibilityHidden(true)
            HomeSceneMascot(isNight: isNight)
                .scaleEffect(0.8, anchor: .bottomTrailing)
                .padding(.trailing, MPSpacing.lg)
                .padding(.bottom, MPSpacing.sm)
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private func progressBar(_ progress: Double) -> some View {
        GeometryReader { geo in
            Capsule().fill(MPColor.borderKid)
                .overlay(alignment: .leading) {
                    Capsule().fill(MPColor.actionPrimary)
                        .frame(width: geo.size.width * min(max(progress, 0), 1))
                }
        }
        .frame(height: MP.S.x1)
        .padding(.top, MPSpacing.sm)
        .accessibilityHidden(true)
    }

    private var eyebrow: String { switch state { case .resume: "Kaldığın yerden"; case .unread: "Bu akşamın masalı"; case .readToday: "Bugün okudun"; case .bedtime(let t): "Saat \(t)" } }
    private var title: String { switch state { case .resume(_, let t, _): t; case .unread(let t, _): t; case .readToday: "Harika gidiyorsun!"; case .bedtime: "Uyku masalı zamanı" } }
    private var sub: String { switch state { case .resume(_, _, let m): m; case .unread(_, let m): m; case .readToday: "Yarın yeni bir masal hazır olacak. Bir tane daha yazalım mı?"; case .bedtime: "Kısa, sakin bir masalla günü kapatalım." } }
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

/// "Yeni bir masal yaz" bölümündeki büyük mod kartı: pastel zemin, mod adı,
/// sağ altta taşan küçük sahnecik (15 Ekim); anlatımı resim taşır. Az yazı,
/// büyük hedef (araştırma: okumayan çocuk resimden seçer). Sahneciğin görseli
/// henüz yoksa beyaz daire içinde ikon gösterilir. Tek mod kaldığında (uyku
/// saati) yatay ve tam genişlik; gece görseli varsa gece göğü zemininde.
struct HomeModeCard: View {
    let title: String
    let systemImage: String
    let tone: MPWorldTone
    /// Sahneciğin varlık adı (`Scenes/mode-…`); yoksa ikon.
    var art: String? = nil
    var wide: Bool = false
    var night: Bool = false
    /// Öne çıkan mod (uyku saatinde "Bu akşam"): mor çerçeve ve üst kenara
    /// binen etiket, `HomeModeTile` ile aynı dil. Bilgi yalnızca renkle verilmez.
    var badge: String? = nil
    let action: () -> Void

    @State private var badgeHeight: CGFloat = 0

    private var artImage: UIImage? { art.flatMap { UIImage(named: $0) } }
    private var onNight: Bool { night && artImage != nil }

    var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(MPSpacing.lg)
                .frame(maxWidth: .infinity, minHeight: wide ? 120 : 166, alignment: .topLeading)
                // Sahnecik düzeni etkilemez: sağ altta, kenardan hafifçe taşar; kart kırpar.
                .background(alignment: .bottomTrailing) {
                    if let artImage {
                        Image(uiImage: artImage).resizable().scaledToFit()
                            .frame(width: wide ? 150 : 124, height: wide ? 112 : 98, alignment: .bottomTrailing)
                            .offset(x: MPSpacing.xs, y: MPSpacing.xs)
                            .accessibilityHidden(true)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
                .mpKidSurface(onNight ? MPColor.bedtimeSkyTop : tone.soft,
                              edge: onNight ? MPColor.brandNight : tone.edge)
                .overlay {
                    if badge != nil {
                        RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
                            .strokeBorder(MPColor.actionPrimary, lineWidth: 2)
                    }
                }
                .overlay(alignment: .top) {
                    if let badge {
                        Text(badge).mpText(.caption)
                            .foregroundStyle(MPColor.textOnAction)
                            .lineLimit(1)
                            .padding(.horizontal, MPSpacing.sm)
                            .padding(.vertical, MPSpacing.xxs)
                            .background(MPColor.actionPrimary, in: Capsule())
                            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { badgeHeight = $0 }
                            .offset(y: -badgeHeight / 2)
                            .accessibilityHidden(true)
                    }
                }
        }
        .buttonStyle(MPPressStyle())
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xxs) {
            if artImage == nil {
                MPIcon(systemImage, size: MP.G.xl, weight: .semibold)
                    .foregroundStyle(tone.deep)
                    .frame(width: 56, height: 56)
                    .background(MPColor.backgroundSurface, in: Circle())
                    .padding(.bottom, MPSpacing.sm)
                    .accessibilityHidden(true)
            }
            Text(title).mpText(.cardTitle)
                .foregroundStyle(onNight ? MPColor.textOnAction : MPColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

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
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false

    var body: some View {
        HomeSection(title: "Masallar", link: ("Tümü", action)) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: MPSpacing.md) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        Button(action: action) { tile(item) }
                            .buttonStyle(MPPressStyle())
                            .accessibilityLabel(item.title)
                            .accessibilityHint("Masallar sekmesini açar")
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
            Text("\(item.minutes) dakika").mpText(.caption).foregroundStyle(MPColor.textSecondary)
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
                Text(title).mpText(.callout).foregroundStyle(MPColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, MPSpacing.md)
            .padding(.horizontal, MPSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: 104)
            .background(tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.input, style: .continuous))
            .overlay {
                if badge != nil {
                    RoundedRectangle(cornerRadius: MPRadius.input, style: .continuous)
                        .strokeBorder(MPColor.actionPrimary, lineWidth: 2)
                }
            }
            .overlay(alignment: .top) {
                if let badge {
                    Text(badge).mpText(.caption)
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

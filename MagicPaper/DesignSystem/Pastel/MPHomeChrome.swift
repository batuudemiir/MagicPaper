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
        return background {
            ZStack {
                shape.fill(edge).offset(y: MP.E.widthLG)
                shape.fill(fill)
            }
        }
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

/// Sahnenin alt kenarına binen bilgi çipleri: yıldız ve okuma serisi.
struct HomeStatChips: View {
    let stars: Int
    let streak: Int
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: MPSpacing.sm))
            : AnyLayout(HStackLayout(spacing: MPSpacing.sm))
        layout {
            chip(tone: .yellow, label: "Yıldızların", value: "\(stars) yıldız", number: stars) {
                MPStarMark(size: 20)
            }
            chip(tone: .lav, label: "Okuma serisi", value: "\(streak) gün", number: streak) {
                MPIcon("flame", size: MP.G.md, weight: .bold).foregroundStyle(MPColor.actionPrimary)
            }
        }
    }

    private func chip<Glyph: View>(tone: MPWorldTone, label: String, value: String, number: Int,
                                   @ViewBuilder glyph: () -> Glyph) -> some View {
        HStack(spacing: MPSpacing.sm) {
            glyph()
                .frame(width: 36, height: 36)
                .background(tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).mpText(.caption).foregroundStyle(MPColor.textSecondary)
                Text(value).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                    .contentTransition(.numericText(value: Double(number)))
            }
            Spacer(minLength: 0)
        }
        .padding(MPSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.input)
        .animation(MP.M.gated(MP.M.spring), value: number)
        .accessibilityElement(children: .combine)
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

// MARK: - Başlık

/// Avatar (→ Benim köşem), selam ve ad, kilit (→ ebeveyn kapısı). Yıldız
/// sahnenin çipinde.
struct HomeHeader<Avatar: View>: View {
    let greeting: String
    let childName: String
    var isNight: Bool = false
    @ViewBuilder var avatar: Avatar
    let onAvatar: () -> Void
    let onLock: () -> Void

    var body: some View {
        HStack(spacing: MPSpacing.sm) {
            Button { MPHaptics.tap(); onAvatar() } label: {
                HStack(spacing: MPSpacing.md) {
                    avatar
                        .dynamicTypeSize(...DynamicTypeSize.large)
                        .frame(width: MPSize.headerAvatar, height: MPSize.headerAvatar)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(MPColor.backgroundSurface, lineWidth: 3))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(greeting).mpText(.footnote)
                            .foregroundStyle(isNight ? MPColor.readerNightText : MPColor.textPrimary)
                        Text(childName).mpText(.navTitle).fontWeight(.black)
                            .foregroundStyle(isNight ? MPColor.readerNightText : MPColor.textPrimary)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                }
                .frame(minHeight: MPSize.minTouchKid)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel("Benim köşem, \(childName)")
            Spacer(minLength: 0)
            MPCircleButton(systemImage: "lock", accessibilityLabel: "Ebeveyn bölümü", size: 40, action: onLock)
        }
    }
}

// MARK: - Hero kartı

/// "Bu akşamın masalı" kartının yeni yüzü, dört durum (SCREENS.md 11).
/// Metinler `TonightHeroCard` ile aynı. Sayfanın tek dolgun mor yüzeyi
/// (yön A, 13 Ekim): göz ilk buraya gider; diğer kartlar pastel ve sakin.
struct HomeHeroCard: View {
    let state: TonightState
    var coverIcon: String? = nil
    var coverTone: MPWorldTone = .yellow
    let onPrimary: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: MPSpacing.md))
                : AnyLayout(HStackLayout(alignment: .center, spacing: MPSpacing.lg))
            layout {
                art
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text(eyebrow).mpText(.eyebrow).foregroundStyle(MPWorldTone.lav.soft)
                    Text(title).mpText(.title3).foregroundStyle(MPColor.textOnAction)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(sub).mpText(.footnote).foregroundStyle(MPWorldTone.lav.soft)
                        .fixedSize(horizontal: false, vertical: true)
                    if case let .resume(progress, _, _) = state { progressBar(progress) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            MPButton(title: buttonTitle, systemImage: buttonIcon, kind: .secondary, fullWidth: true, action: onPrimary)
        }
        .padding(MPSpacing.lg)
        .mpKidSurface(fill, edge: MPColor.brandNight)
    }

    /// Sahnede Ragi zaten var (ekranda tek maskot): kart durumu bir simgeyle söyler.
    @ViewBuilder private var art: some View {
        switch state {
        case .readToday: stateTile("sparkles", rotation: 0)
        case .bedtime: stateTile("moon", rotation: 0)
        default: stateTile(coverIcon ?? "book", rotation: -3)
        }
    }

    private func stateTile(_ icon: String, rotation: Double) -> some View {
        // Mor kartın üstünde kapak markanın lavantası: masalın dünyası
        // simgeden okunur, renk bütünlüğü bozulmaz.
        MPIcon(icon, size: MP.G.xxl, weight: .semibold)
            .foregroundStyle(MPColor.actionPrimary)
            .frame(width: 84, height: 104)
            .background(MPWorldTone.lav.soft, in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
            .rotationEffect(.degrees(rotation))
            .accessibilityHidden(true)
    }

    private func progressBar(_ progress: Double) -> some View {
        GeometryReader { geo in
            Capsule().fill(MPColor.brandPurple)
                .overlay(alignment: .leading) {
                    Capsule().fill(MPColor.statusStarIcon)
                        .frame(width: geo.size.width * min(max(progress, 0), 1))
                }
        }
        .frame(height: MP.S.x2)
        .padding(.top, MPSpacing.sm)
        .accessibilityHidden(true)
    }

    /// Kart her durumda markanın moru; uyku saatinde başlıktaki gece gökyüzü.
    /// Durumu kapak ya da Ragi'nin pozu söyler.
    private var fill: Color {
        if case .bedtime = state { return MPColor.bedtimeSkyTop }
        return MPColor.actionPrimary
    }
    private var eyebrow: String { switch state { case .resume: "Kaldığın yerden"; case .unread: "Bu akşamın masalı"; case .readToday: "Bugün okudun"; case .bedtime(let t): "Saat \(t)" } }
    private var title: String { switch state { case .resume(_, let t, _): t; case .unread(let t, _): t; case .readToday: "Harika gidiyorsun!"; case .bedtime: "Uyku masalı zamanı" } }
    private var sub: String { switch state { case .resume(_, _, let m): m; case .unread(_, let m): m; case .readToday: "Yarın yeni bir masal hazır olacak. Bir tane daha yazalım mı?"; case .bedtime: "Kısa, sakin bir masalla günü kapatalım." } }
    private var buttonTitle: String { switch state { case .resume: "Devam et"; case .unread: "Masalı oku"; case .readToday: "Yeni masal yarat"; case .bedtime: "Uyku masalı oluştur" } }
    private var buttonIcon: String { switch state { case .resume: "play.fill"; case .unread: "book"; case .readToday: "wand.and.sparkles"; case .bedtime: "moon.fill" } }
}

// MARK: - Bölüm

/// Ana sayfanın bölümü (15 Ekim, Apple düzeni): kalın başlık içeriğin üstünde,
/// sağında isteğe bağlı bağlantı ("Tümü"); içerik hafif lavanta panelde ya da
/// (`contained: false`) doğrudan beyaz zeminde. Bütün bölüm başlıkları aynı
/// font, boyut ve ağırlıkta (`title3`).
///
/// Köşe yarıçapı kuralı (15 Ekim): büyük yüzeyler (hero, mod kartları,
/// paneller) `card`; küçük bilgi kartları (çipler) `input`; içerideki kutular
/// (ikon kareleri, kapaklar) `md`; rozetler hap biçiminde.
struct HomeSection<Leading: View, Content: View>: View {
    let title: String
    var contained: Bool = true
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
            HStack(alignment: .firstTextBaseline, spacing: MPSpacing.sm) {
                leading
                Text(title).mpText(.title3).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                if let note {
                    Text(note).mpText(.callout).monospacedDigit().foregroundStyle(MPColor.textSecondary)
                        .accessibilityLabel(noteSpoken ?? note)
                }
                if let link {
                    Button(action: link.action) {
                        HStack(spacing: MPSpacing.xxs) {
                            Text(link.title).mpText(.callout)
                            MPIcon("chevron.right", size: MP.G.xs, weight: .bold).accessibilityHidden(true)
                        }
                        .foregroundStyle(MPColor.actionPrimary)
                        // Dokunma alanı büyük, başlık satırını uzatmaz.
                        .contentShape(Rectangle().inset(by: -MPSpacing.md))
                    }
                    .buttonStyle(MPPressStyle())
                }
            }
            if contained {
                // Panel: beyazın üstünde hafif lavanta; mod kartlarının dolu
                // pastelinden açık, kenarı sakin (aynı aile, kopya değil).
                // İçerik tek kapta: birden fazla öğe verilse de tek panel olur.
                VStack(alignment: .leading, spacing: MPSpacing.md) { content }
                    .padding(MPSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(MPWorldTone.lav.soft.opacity(0.45),
                                in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
                    .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge.opacity(0.5))
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension HomeSection where Leading == EmptyView {
    init(title: String, contained: Bool = true, note: String? = nil, noteSpoken: String? = nil,
         link: (title: String, action: () -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, contained: contained, note: note, noteSpoken: noteSpoken, link: link,
                  leading: { EmptyView() }, content: content)
    }
}

// MARK: - Okuma şeridi

/// Haftalık okuma şeridi: gün adları, okunan gün tikli, bugün mor halka.
/// Sakin dil (CLAUDE.md §7): kayıp yok, geri sayım yok.
struct HomeStreakCard: View {
    let done: [Bool]
    let streak: Int
    let todayIndex: Int

    /// Seri sayısı sahnenin çipinde; kart haftayı gösterir.
    let title = "Bu hafta"

    private var spokenStreak: String {
        switch streak {
        case 0:  return "Okuma yolculuğun burada başlıyor"
        case 1:  return "Okuma yolculuğun devam ediyor"
        default: return "\(streak) gün üst üste okudun"
        }
    }

    var body: some View {
        HomeSection(title: title) {
            VStack(alignment: .leading, spacing: MPSpacing.md) {
                HStack(spacing: 0) {
                    ForEach(MPStreak.weekdayLabels.indices, id: \.self) { i in
                        VStack(spacing: MPSpacing.xs) {
                            dot(i)
                            Text(MPStreak.weekdayLabels[i]).mpText(.caption)
                                .fontWeight(i == todayIndex ? .heavy : .semibold)
                                .foregroundStyle(i == todayIndex ? MPColor.actionPrimary : MPColor.textSecondary)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                Text(caption).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .animation(MP.M.gated(MP.M.spring), value: done)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(spokenStreak). Bu hafta \(done.filter { $0 }.count) gün okudunuz")
    }

    /// Sakin süreklilik cümlesi (CLAUDE.md §7 örnekleri).
    private var caption: String {
        let read = done.filter { $0 }.count
        switch read {
        case 0:  return "Okuma yolculuğunuz bu hafta başlıyor."
        default: return "Bu hafta \(read) gün birlikte okudunuz."
        }
    }

    @ViewBuilder private func dot(_ i: Int) -> some View {
        let read = i < done.count && done[i]
        let today = i == todayIndex
        ZStack {
            if today {
                Circle().strokeBorder(MPColor.actionPrimary, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            }
            if read {
                MPStarMark(size: 26)
                    .transition(.scale.combined(with: .opacity))
            } else {
                // Tamamlanmamış gün soluk; bugün halkayla vurgulu.
                StarShape().fill(MPColor.backgroundSurface)
                    .overlay(StarShape().stroke(MPWorldTone.lav.deep.opacity(today ? 0.6 : 0.22), lineWidth: 1.5))
                    .frame(width: today ? 20 : 24, height: today ? 20 : 24)
            }
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Yıldız

/// Markanın yıldızı (imza, 15 Ekim): tek çizim, tek sarı, ince koyu sarı
/// kontur. Yıldız sayacı, "Bugün" kurdelesi ve okunan günler bunu kullanır;
/// tamamlanmamış günler soluk kalır. Süs olarak çoğaltılmaz.
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

/// Ana sayfadaki Günlük rafı (15 Ekim, Apple Books rafı gibi): başlıkta "Tümü",
/// altında yatay kayan kapaklar, adı ve süresi; ilki günün klasiği, "Bugün"
/// kurdeleli. Kapaklar açılışta sırayla süzülür; Reduce Motion'da yerinde.
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
        HomeSection(title: "Günlük", contained: false, link: ("Tümü", action)) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: MPSpacing.md) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        Button(action: action) { tile(item, today: index == 0) }
                            .buttonStyle(MPPressStyle())
                            .accessibilityLabel(index == 0 ? "Bugünün klasiği: \(item.title)" : item.title)
                            .accessibilityHint("Günlük sekmesini açar")
                            .offset(y: arrived ? 0 : MP.S.x5)
                            .opacity(arrived ? 1 : 0)
                            .animation(reduceMotion ? nil : MP.M.spring.delay(0.1 + Double(index) * 0.06), value: arrived)
                    }
                }
                // Kurdele ve sert kenar kırpılmasın.
                .padding(.vertical, MPSpacing.sm)
                .padding(.horizontal, MPSpacing.screenH)
            }
            .padding(.horizontal, -MPSpacing.screenH)
            .padding(.vertical, -MPSpacing.sm)
        }
        .onAppear { arrived = true }
    }

    private func tile(_ item: Item, today: Bool) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.xs) {
            ClassicCoverImage(asset: item.asset, focus: item.focus, seed: item.asset)
                .frame(width: 118, height: 158)
                .clipShape(RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.md)
                .overlay(alignment: .topLeading) { if today { todayRibbon } }
            Text(item.title).mpText(.footnote).fontWeight(.bold).foregroundStyle(MPColor.textPrimary)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                .padding(.top, MPSpacing.xxs)
            Text("\(item.minutes) dakika").mpText(.caption).foregroundStyle(MPColor.textSecondary)
        }
        .frame(width: 118, alignment: .leading)
    }

    /// Günün klasiğinin kurdelesi: sarı hap, markanın yıldızı ve "Bugün".
    private var todayRibbon: some View {
        HStack(spacing: MPSpacing.xxs) {
            MPStarMark(size: 12)
            Text("Bugün").mpText(.caption).fontWeight(.heavy).foregroundStyle(MPColor.yellowText)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .padding(.horizontal, MPSpacing.sm)
        .padding(.vertical, MPSpacing.xxs)
        .mpKidSurface(MPWorldTone.yellow.soft, edge: MPWorldTone.yellow.edge, radius: MPRadius.input)
        .padding(MPSpacing.xs)
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
            HomeHeroCard(state: .resume(progress: 0.37, title: "Şehri Kurtaran Gün", meta: "Sayfa 3 / 8"),
                         coverIcon: "bolt", coverTone: .yellow) {}
            HomeHeroCard(state: .unread(title: "Ormandaki Fısıltı", meta: "5 dakika"), coverIcon: "book", coverTone: .sky) {}
            HomeHeroCard(state: .readToday) {}
            HomeHeroCard(state: .bedtime(time: "20.30")) {}
            HomeStreakCard(done: [true, true, true, false, false, false, false], streak: 3, todayIndex: 3)
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

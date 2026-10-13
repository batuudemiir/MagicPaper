// MPHomeChrome.swift
// 11 · Ana sayfa yenilemesi (13 Ekim 2026): bulutlu gökyüzü bandı, başlık,
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack(alignment: .topLeading) {
                Rectangle().fill(MPWorldTone.lav.soft)
                Rectangle().fill(MPColor.bedtimeSkyTop).opacity(isNight ? 1 : 0)
                if isNight { stars(w: w, h: h).transition(.opacity) }
                cloud(width: w * 0.30, at: CGPoint(x: w * 0.08, y: h * 0.34), sway: 1)
                cloud(width: w * 0.36, at: CGPoint(x: w * 0.62, y: h * 0.52), sway: -1)
                cloud(width: w * 0.16, at: CGPoint(x: w * 0.46, y: h * 0.22), sway: 1)
            }
        }
        .frame(height: height)
        .clipShape(WaveBottom())
        .ignoresSafeArea(edges: .top)
        .animation(MP.M.gated(MP.M.slow), value: isNight)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(MP.M.ambient) { drift = true }
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

/// Avatar (→ Benim köşem), selam ve ad, yıldız hapı, kilit (→ ebeveyn kapısı).
struct HomeHeader<Avatar: View>: View {
    let greeting: String
    let childName: String
    let stars: Int
    var isNight: Bool = false
    @ViewBuilder var avatar: Avatar
    let onAvatar: () -> Void
    let onLock: () -> Void

    var body: some View {
        HStack(spacing: MPSpacing.sm) {
            Button(action: onAvatar) {
                HStack(spacing: MPSpacing.md) {
                    avatar
                        .dynamicTypeSize(...DynamicTypeSize.large)
                        .frame(width: MPSize.headerAvatar, height: MPSize.headerAvatar)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(MPColor.backgroundSurface, lineWidth: 3))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(greeting).mpText(.footnote)
                            .foregroundStyle(isNight ? MPColor.readerNightSecondary : MPWorldTone.lav.deep)
                        Text(childName).mpText(.navTitle).fontWeight(.black)
                            .foregroundStyle(isNight ? MPColor.readerNightText : MPColor.textPrimary)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                }
                .frame(minHeight: MPSize.minTouchKid)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Benim köşem, \(childName)")
            Spacer(minLength: 0)
            starPill
            MPCircleButton(systemImage: "lock", accessibilityLabel: "Ebeveyn bölümü", size: 40, action: onLock)
        }
    }

    private var starPill: some View {
        HStack(spacing: MPSpacing.xxs) {
            MPIcon("star.fill", size: MP.G.sm, weight: .bold).foregroundStyle(MPColor.statusStarIcon)
            Text("\(stars)").mpText(.callout).monospacedDigit()
                .foregroundStyle(MPColor.yellowText)
                .contentTransition(.numericText(value: Double(stars)))
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .padding(.horizontal, MPSpacing.md)
        .frame(minHeight: 36)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.yellow.edge, radius: MPRadius.input)
        .animation(MP.M.gated(MP.M.spring), value: stars)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stars) yıldız")
    }
}

// MARK: - Hero kartı

/// "Bu akşamın masalı" kartının yeni yüzü, dört durum (SCREENS.md 11).
/// Metinler `TonightHeroCard` ile aynı; iskelet her durumda aynı, durumu
/// kartın rengi ve görseli söyler.
struct HomeHeroCard: View {
    let state: TonightState
    var coverIcon: String? = nil
    var coverTone: MPWorldTone = .yellow
    let onPrimary: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wave: Double = 0

    /// Kartta Ragi var mı (ekranda tek maskot kuralı için ana sayfa okur).
    static func showsMascot(_ state: TonightState) -> Bool {
        switch state { case .readToday, .bedtime: true; default: false }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: MPSpacing.md))
                : AnyLayout(HStackLayout(alignment: .center, spacing: MPSpacing.lg))
            layout {
                art
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text(eyebrow).mpText(.eyebrow).foregroundStyle(tone.deep)
                    Text(title).mpText(.title3).foregroundStyle(MPColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(sub).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if case let .resume(progress, _, _) = state { progressBar(progress) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            MPButton(title: buttonTitle, systemImage: buttonIcon, fullWidth: true, action: onPrimary)
        }
        .padding(MPSpacing.lg)
        .mpKidSurface(fill, edge: tone.edge, radius: MPRadius.hero)
        .task(id: Self.showsMascot(state)) { await waveOnce() }
    }

    // Ragi ilk görünüşte bir kez sallanır; Reduce Motion açıkken durur.
    private func waveOnce() async {
        guard Self.showsMascot(state), !reduceMotion else { return }
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation(MP.M.spring) { wave = -8 }
        try? await Task.sleep(for: .milliseconds(260))
        withAnimation(MP.M.spring) { wave = 0 }
    }

    @ViewBuilder private var art: some View {
        switch state {
        case .readToday:
            MascotImage(mascot: .waving, width: 92)
                .rotationEffect(.degrees(wave), anchor: .bottom)
        case .bedtime:
            MascotImage(mascot: .sleeping, width: 104)
                .rotationEffect(.degrees(wave), anchor: .bottom)
        default:
            MPIcon(coverIcon ?? "book", size: MP.G.xxl, weight: .semibold)
                .foregroundStyle(coverTone.deep)
                .frame(width: 84, height: 104)
                .background(coverTone.soft, in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous).strokeBorder(coverTone.edge, lineWidth: 1))
                .rotationEffect(.degrees(-3))
                .accessibilityHidden(true)
        }
    }

    private func progressBar(_ progress: Double) -> some View {
        GeometryReader { geo in
            Capsule().fill(MPWorldTone.lav.soft)
                .overlay(alignment: .leading) {
                    Capsule().fill(MPColor.actionPrimary)
                        .frame(width: geo.size.width * min(max(progress, 0), 1))
                }
        }
        .frame(height: MP.S.x2)
        .padding(.top, MPSpacing.sm)
        .accessibilityHidden(true)
    }

    private var tone: MPWorldTone {
        switch state { case .resume, .bedtime: .lav; case .unread: .sky; case .readToday: .mint }
    }
    private var fill: Color {
        switch state {
        case .resume, .unread: MPColor.backgroundSurface
        case .readToday: MPWorldTone.mint.soft
        case .bedtime: MPWorldTone.lav.soft
        }
    }
    private var eyebrow: String { switch state { case .resume: "Kaldığın yerden"; case .unread: "Bu akşamın masalı"; case .readToday: "Bugün okudun"; case .bedtime(let t): "Saat \(t)" } }
    private var title: String { switch state { case .resume(_, let t, _): t; case .unread(let t, _): t; case .readToday: "Harika gidiyorsun!"; case .bedtime: "Uyku masalı zamanı" } }
    private var sub: String { switch state { case .resume(_, _, let m): m; case .unread(_, let m): m; case .readToday: "Yarın yeni bir masal hazır olacak. Bir tane daha yazalım mı?"; case .bedtime: "Kısa, sakin bir masal ve kısılan ışıklar." } }
    private var buttonTitle: String { switch state { case .resume: "Devam et"; case .unread: "Masalı oku"; case .readToday: "Yeni masal yarat"; case .bedtime: "Uyku modunu aç" } }
    private var buttonIcon: String { switch state { case .resume: "play.fill"; case .unread: "book"; case .readToday: "wand.and.sparkles"; case .bedtime: "moon.fill" } }
}

// MARK: - Okuma şeridi

/// Haftalık okuma şeridi: gün adları, okunan gün tikli, bugün mor halka.
/// Sakin dil (CLAUDE.md §7): kayıp yok, geri sayım yok.
struct HomeStreakCard: View {
    let done: [Bool]
    let streak: Int
    let todayIndex: Int

    var title: String {
        switch streak {
        case 0:  return "Okuma yolculuğun burada başlıyor"
        case 1:  return "Okuma yolculuğun devam ediyor"
        default: return "\(streak) gün üst üste okudun"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            HStack(spacing: MPSpacing.sm) {
                MPIcon("flame", size: MP.G.md, weight: .semibold).foregroundStyle(MPWorldTone.peach.deep)
                Text(title).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 0) {
                ForEach(MPStreak.weekdayLabels.indices, id: \.self) { i in
                    VStack(spacing: MPSpacing.xxs) {
                        dot(i)
                        Text(MPStreak.weekdayLabels[i]).mpText(.caption)
                            .foregroundStyle(i == todayIndex ? MPColor.actionPrimary : MPWorldTone.peach.deep)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
        .padding(MPSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mpKidSurface(MPWorldTone.peach.soft, edge: MPWorldTone.peach.edge)
        .animation(MP.M.gated(MP.M.spring), value: done)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). Bu hafta \(done.filter { $0 }.count) gün okudun")
    }

    @ViewBuilder private func dot(_ i: Int) -> some View {
        let read = i < done.count && done[i]
        let today = i == todayIndex
        ZStack {
            if read {
                Circle().fill(today ? MPColor.actionPrimary : MPWorldTone.peach.deep)
                MPIcon("checkmark", size: MP.G.xs, weight: .heavy).foregroundStyle(MPColor.textOnAction)
            } else if today {
                Circle().fill(MPColor.backgroundSurface)
                Circle().strokeBorder(MPColor.actionPrimary, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                MPIcon("book", size: MP.G.xs, weight: .bold).foregroundStyle(MPColor.actionPrimary)
            } else {
                Circle().fill(MPColor.backgroundSurface.opacity(0.7))
            }
        }
        .frame(width: 30, height: 30)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Mod kartı

/// "Bu akşam nasıl bir masal olsun?" altındaki mod kartı: beyaz kutuda büyük
/// ikon ve mod adı.
struct HomeModeTile: View {
    let title: String
    let systemImage: String
    let tone: MPWorldTone
    let action: () -> Void

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
            .frame(maxWidth: .infinity, minHeight: 112)
            .mpKidSurface(tone.soft, edge: tone.edge, radius: MPRadius.tile)
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

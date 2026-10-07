// MPStory.swift
// Story-domain components: world tile, story cover, home hero card, streak strip, progress ring + stage list,
// new-word popover, reader controls, hero avatar (Kahraman oluşturucu).

import SwiftUI

// MARK: World tile (Yarat 1 · Dünya grid, Ana sayfa world strip)

struct WorldTile: View {
    let title: String
    let systemImage: String
    let tone: MPWorldTone
    var isSelected: Bool = false
    var isLocked: Bool = false
    var compact: Bool = false        // Ana sayfa strip: 98 × 108, icon centered
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if compact {
                    VStack(spacing: 8) {
                        MPIconTile(systemImage: systemImage, tone: tone, size: 48, filled: false).mpShadow(.control)
                        Text(title).mpText(.footnote).fontWeight(.black).foregroundStyle(MPColor.textPrimary)
                    }
                    .frame(width: 98, height: 108)
                } else {
                    Text(title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        .padding(.top, 24)
                        .frame(maxWidth: .infinity, minHeight: 108)
                        .overlay(alignment: .topLeading) {
                            MPIconTile(systemImage: systemImage, tone: tone, size: 46, filled: false)
                                .rotationEffect(.degrees(-8)).mpShadow(.control).offset(x: -6, y: -8)
                        }
                        .overlay(alignment: .topTrailing) {
                            if isLocked {
                                Image(systemName: "lock.fill").font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(MPColor.statusWarning)
                                    .frame(width: 28, height: 28).background(.white, in: Circle()).padding(10)
                            }
                        }
                }
            }
            .background(tone.soft, in: RoundedRectangle(cornerRadius: compact ? MPRadius.tile : MPRadius.card))
            .overlay(RoundedRectangle(cornerRadius: compact ? MPRadius.tile : MPRadius.card).strokeBorder(isSelected ? MPColor.actionPrimary : .clear, lineWidth: 3))
            .opacity(isLocked ? 0.7 : 1)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(title + (isLocked ? ", kilitli" : ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: Story cover (Kitaplık grid 167 × 206, Ana sayfa / Okuyucu)

struct StoryCover: View {
    let title: String
    let systemImage: String
    let tone: MPWorldTone
    var badge: String? = nil          // "Görselli", "Yarım", "İndirildi"
    var actionTitle: String = "Oku"   // "Devam" for unfinished stories
    var illustration: Image? = nil    // real cover image when the story has pictures

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [tone.soft, tone.deep], startPoint: .topLeading, endPoint: .bottomTrailing)
            if let illustration { illustration.resizable().scaledToFill() }
            else { Image(systemName: systemImage).font(.system(size: 64, weight: .light)).foregroundStyle(.white.opacity(0.95)).frame(maxHeight: .infinity, alignment: .top).padding(.top, 26) }
            VStack(spacing: 8) {
                Text(actionTitle).font(.custom("Nunito", size: 12, relativeTo: .caption).weight(.black)).foregroundStyle(.white)
                    .padding(.horizontal, 16).frame(height: 28).background(LinearGradient.mpPrimary, in: Capsule())
                Text(title).font(.custom("Nunito", size: 13, relativeTo: .footnote).weight(.heavy)).foregroundStyle(.white).multilineTextAlignment(.center).lineLimit(2)
            }
            .padding(.horizontal, 12).padding(.bottom, 12).padding(.top, 40)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [Color(red: 20 / 255, green: 18 / 255, blue: 26 / 255).opacity(0), Color(red: 20 / 255, green: 18 / 255, blue: 26 / 255).opacity(0.62)], startPoint: .top, endPoint: .bottom))
        }
        .aspectRatio(167.0 / 206.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: MPRadius.tile))
        .overlay(alignment: .topLeading) {
            if let badge { Text(badge).mpText(.caption).fontWeight(.black).foregroundStyle(MPColor.textPrimary).padding(.horizontal, 10).padding(.vertical, 3).background(.white.opacity(0.92), in: Capsule()).padding(10) }
        }
        .mpShadow(.card)
        .accessibilityElement(children: .combine)
    }
}

// MARK: Home hero ("Bu akşamın masalı"): 4 states, see docs/SCREENS.md › Ana sayfa

enum TonightState { case resume(progress: Double, title: String, meta: String), unread(title: String, meta: String), readToday, bedtime(time: String) }

struct TonightHeroCard: View {
    let state: TonightState
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(eyebrow).mpText(.eyebrow).foregroundStyle(secondary)
                Text(title).mpText(.title3).foregroundStyle(primary)
                Text(sub).mpText(.footnote).foregroundStyle(secondary)
            }
            .frame(maxWidth: 200, minHeight: 120, alignment: .topLeading)
            if case let .resume(progress, _, _) = state {
                ProgressView(value: progress).tint(MPWorldTone.pink.deep).padding(.top, 14)
            }
            MPButton(title: buttonTitle, systemImage: buttonIcon, action: onPrimary).padding(.top, 16)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topTrailing) { art.offset(x: 14, y: -6) }
        .background(background, in: RoundedRectangle(cornerRadius: MPRadius.hero))
        .clipShape(RoundedRectangle(cornerRadius: MPRadius.hero))
        .mpShadow(.raised)
    }

    private var isNight: Bool { if case .bedtime = state { return true }; return false }
    private var primary: Color { isNight ? .white : MPColor.textPrimary }
    private var secondary: Color { isNight ? .white.opacity(0.82) : MPColor.textSecondary }
    private var eyebrow: String { switch state { case .resume: "Kaldığın yerden"; case .unread: "Bu akşamın masalı"; case .readToday: "Bugün okudun"; case .bedtime(let t): "Saat \(t)" } }
    private var title: String { switch state { case .resume(_, let t, _): t; case .unread(let t, _): t; case .readToday: "Harika gidiyorsun!"; case .bedtime: "Uyku masalı zamanı" } }
    private var sub: String { switch state { case .resume(_, _, let m): m; case .unread(_, let m): m; case .readToday: "Yarın yeni bir masal hazır olacak. Bir tane daha yazalım mı?"; case .bedtime: "Kısa, sakin bir masal ve kısılan ışıklar." } }
    private var buttonTitle: String { switch state { case .resume: "Devam et"; case .unread: "Masalı oku"; case .readToday: "Yeni masal yarat"; case .bedtime: "Uyku modunu aç" } }
    private var buttonIcon: String { switch state { case .resume: "play.fill"; case .unread: "book"; case .readToday: "wand.and.sparkles"; case .bedtime: "moon.fill" } }
    @ViewBuilder private var art: some View {
        switch state {
        case .readToday: MascotImage(mascot: .waving, width: 140).padding(.top, 20)
        case .bedtime: MascotImage(mascot: .sleeping, width: 160).padding(.top, 46)
        default: EmptyView() // story cover art (rotated 6°) goes here
        }
    }
    private var background: AnyShapeStyle {
        switch state {
        case .resume: AnyShapeStyle(LinearGradient(colors: [MPWorldTone.pink.soft, MPWorldTone.yellow.soft], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .unread: AnyShapeStyle(LinearGradient(colors: [MPWorldTone.sky.soft, MPWorldTone.lav.soft], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .readToday: AnyShapeStyle(LinearGradient(colors: [MPWorldTone.green.soft, MPWorldTone.mint.soft], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .bedtime: AnyShapeStyle(LinearGradient(colors: [Color(red: 0x2B / 255, green: 0x31 / 255, blue: 0x60 / 255), Color(red: 0x1E / 255, green: 0x22 / 255, blue: 0x38 / 255)], startPoint: .top, endPoint: .bottom))
        }
    }
}

// MARK: Streak strip (Ana sayfa): weekly, forgiving: today is dashed, no guilt copy

struct StreakStrip: View {
    let days: [String]          // ["P","S","Ç","P","C","C","P"]
    let doneCount: Int
    let todayIndex: Int
    var body: some View {
        HStack(spacing: 12) {
            MPIconTile(systemImage: "flame", tone: .peach, size: 42, filled: false)
            VStack(alignment: .leading, spacing: 8) {
                Text("\(doneCount) gün üst üste okudun").mpText(.bodyStrong).fontWeight(.black).foregroundStyle(MPColor.textPrimary)
                HStack(spacing: 5) {
                    ForEach(days.indices, id: \.self) { i in
                        Text(days[i]).font(.custom("Nunito", size: 11, relativeTo: .caption2).weight(.black))
                            .foregroundStyle(i < doneCount ? .white : MPColor.textSecondary)
                            .frame(width: 26, height: 26)
                            .background(i < doneCount ? MPColor.statusStreak : (i == todayIndex ? .white : .white.opacity(0.6)), in: Circle())
                            .overlay { if i == todayIndex { Circle().strokeBorder(MPColor.statusStreak, style: StrokeStyle(lineWidth: 2, dash: [3, 2])) } }
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MPWorldTone.peach.soft, in: RoundedRectangle(cornerRadius: MPRadius.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bu hafta \(doneCount) gün okudun")
    }
}

// MARK: Progress ring + stages (Masal yazılıyor, İlk masal hazırlanıyor)

enum StageState { case done, active, todo }

struct StoryProgressRing: View {
    let progress: Double   // 0...1
    var body: some View {
        ZStack {
            Circle().stroke(Color(red: 0xEF / 255, green: 0xE6 / 255, blue: 0xF7 / 255), lineWidth: 14)
            Circle().trim(from: 0, to: progress).stroke(MPColor.actionPrimary, style: StrokeStyle(lineWidth: 14, lineCap: .round)).rotationEffect(.degrees(-90))
            Text("%\(Int(progress * 100))").font(.custom("Nunito", size: 30, relativeTo: .largeTitle).weight(.black)).monospacedDigit().foregroundStyle(MPColor.textPrimary)
        }
        .frame(width: 150, height: 150)
        .animation(.easeInOut(duration: MPMotion.transition), value: progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Masal yüzde \(Int(progress * 100)) hazır")
    }
}

struct StageRow: View {
    let title: String
    let systemImage: String
    let state: StageState
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state == .done ? "checkmark" : systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(state == .done ? MPWorldTone.green.deep : state == .active ? MPColor.actionPrimary : Color(red: 0x8C / 255, green: 0x87 / 255, blue: 0x92 / 255))
                .frame(width: 32, height: 32)
                .background(state == .done ? MPWorldTone.green.soft : state == .active ? MPColor.actionSoft : MPWorldTone.gray.soft, in: Circle())
            Text(title).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(state == .active ? MPColor.backgroundSurface : .clear, in: RoundedRectangle(cornerRadius: 18))
        .modifier(StageShadow(on: state == .active))
        .opacity(state == .todo ? 0.45 : 1)
    }
}

private struct StageShadow: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View { if on { content.mpShadow(.card) } else { content } }
}

// MARK: New word card (Okuyucu popover, Yeni kelimelerim list)

struct NewWordCard: View {
    let word: String
    let meaning: String
    var source: String? = nil
    var tone: MPWorldTone = .yellow
    var isSpeaking: Bool = false
    var onSpeak: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                if onClose != nil { Text("Yeni kelime").mpText(.eyebrow).foregroundStyle(MPColor.actionPrimary) }
                Text(word).font(.custom("Nunito", size: 19, relativeTo: .headline).weight(.black)).foregroundStyle(MPColor.textPrimary)
                Text(meaning).mpText(.body).foregroundStyle(onClose != nil ? MPColor.textSecondary : MPColor.textPrimary)
                if let source { Text(source).mpText(.caption).foregroundStyle(MPColor.textSecondary) }
            }
            Spacer()
            if let onSpeak {
                Button(action: onSpeak) {
                    Image(systemName: "speaker.wave.2").font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSpeaking ? .white : MPColor.actionPrimary)
                        .frame(width: 46, height: 46)
                        .background(isSpeaking ? MPColor.actionPrimary : .white, in: Circle())
                        .mpShadow(.control)
                }
                .accessibilityLabel("\(word) kelimesini dinle")
            }
            if let onClose { MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat", size: 34, bordered: false, action: onClose) }
        }
        .padding(14)
        .background(onClose != nil ? MPColor.backgroundSurface : tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.tile))
        .modifier(StageShadow(on: onClose != nil))
    }
}

// MARK: Reader theme (Okuyucu · Tweaks: Gündüz / Sepya / Gece)

enum ReaderTheme: String, CaseIterable, Codable {
    case day, sepia, night
    var title: String { switch self { case .day: "Gündüz"; case .sepia: "Sepya"; case .night: "Gece" } }
    var background: Color { Color("Colors/reader\(key)Background") }
    var text: Color { Color("Colors/reader\(key)Text") }
    var secondary: Color { Color("Colors/reader\(key)Secondary") }
    var track: Color { Color("Colors/reader\(key)Track") }
    var heroName: Color { Color("Colors/reader\(key)HeroName") }
    var wash: Color { Color("Colors/reader\(key)Wash") }
    private var key: String { switch self { case .day: "Day"; case .sepia: "Sepia"; case .night: "Night" } }
}

// MARK: Hero avatar (Kahraman oluşturucu): vector, no photo of the child is ever used

struct HeroAvatar: Codable, Hashable {
    enum Hair: String, Codable, CaseIterable { case short, long, curly, ponytail
        var title: String { switch self { case .short: "Kısa"; case .long: "Uzun"; case .curly: "Kıvırcık"; case .ponytail: "At kuyruğu" } } }
    var skin: Int = 1          // index into HeroAvatar.skins
    var hair: Hair = .ponytail
    var hairColor: Int = 1     // index into HeroAvatar.hairColors
    var outfit: Int = 0        // index into HeroAvatar.outfits
    var glasses: Bool = false

    static let skins = ["#F6D3B8", "#E9B48E", "#C98B62", "#9A6440", "#6B4329"]
    static let hairColors = ["#2D2A32", "#6B3F22", "#B9772F", "#E2B65A", "#C2552E"]
    static let outfits = ["#2F86DB", "#E06A92", "#4E9A4A", "#8B6BD6", "#E07A3E", "#D9A21B"]
}

extension Color {
    init(hex: String) {
        var v: UInt64 = 0; Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}

/// Draws the avatar on a 200 × 200 grid, same geometry as the prototype SVG (ios/../reference/html/KahramanOlustur.dc.html).
struct HeroAvatarView: View {
    let avatar: HeroAvatar
    var size: CGFloat = 170
    var background: Color = MPWorldTone.sky.soft

    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 200
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path { Path(ellipseIn: CGRect(x: (cx - r) * s, y: (cy - r) * s, width: 2 * r * s, height: 2 * r * s)) }
            let skin = Color(hex: HeroAvatar.skins[avatar.skin]), hair = Color(hex: HeroAvatar.hairColors[avatar.hairColor]), outfit = Color(hex: HeroAvatar.outfits[avatar.outfit])
            let ink = MPColor.brandInk
            ctx.fill(circle(100, 100, 100), with: .color(background))
            // hair behind the head
            switch avatar.hair {
            case .long:
                var b = Path(); b.move(to: p(50, 84)); b.addCurve(to: p(100, 30), control1: p(48, 44), control2: p(76, 30)); b.addCurve(to: p(150, 84), control1: p(126, 30), control2: p(154, 44)); b.addLine(to: p(156, 160)); b.addLine(to: p(44, 160)); b.closeSubpath()
                ctx.fill(b, with: .color(hair))
            case .ponytail:
                ctx.fill(circle(152, 74, 20), with: .color(hair)); ctx.fill(circle(160, 98, 14), with: .color(hair))
            default: break
            }
            var body = Path(); body.move(to: p(36, 200)); body.addCurve(to: p(100, 132), control1: p(36, 152), control2: p(66, 132)); body.addCurve(to: p(164, 200), control1: p(134, 132), control2: p(164, 152)); body.closeSubpath()
            ctx.fill(body, with: .color(outfit))
            ctx.fill(Path(roundedRect: CGRect(x: 88 * s, y: 110 * s, width: 24 * s, height: 28 * s), cornerRadius: 10 * s), with: .color(skin))
            ctx.fill(circle(100, 90, 44), with: .color(skin))
            ctx.fill(circle(56, 94, 8), with: .color(skin)); ctx.fill(circle(144, 94, 8), with: .color(skin))
            // hair in front
            switch avatar.hair {
            case .short:
                var h = Path(); h.move(to: p(55, 88)); h.addCurve(to: p(100, 32), control1: p(50, 50), control2: p(76, 32)); h.addCurve(to: p(145, 90), control1: p(126, 32), control2: p(152, 48)); h.addCurve(to: p(100, 58), control1: p(138, 68), control2: p(122, 58)); h.addCurve(to: p(55, 88), control1: p(80, 58), control2: p(64, 68)); h.closeSubpath()
                ctx.fill(h, with: .color(hair))
            case .curly:
                for (x, y, r) in [(62.0, 76.0, 17.0), (74, 54, 19), (100, 44, 21), (126, 54, 19), (138, 76, 17)] { ctx.fill(circle(x, y, r), with: .color(hair)) }
            case .long, .ponytail:
                var f = Path(); f.move(to: p(58, 86)); f.addCurve(to: p(100, 42), control1: p(58, 54), control2: p(80, 42)); f.addCurve(to: p(142, 86), control1: p(122, 42), control2: p(142, 54)); f.addCurve(to: p(100, 62), control1: p(128, 68), control2: p(114, 62)); f.addCurve(to: p(58, 86), control1: p(86, 62), control2: p(70, 68)); f.closeSubpath()
                ctx.fill(f, with: .color(hair))
            }
            ctx.fill(circle(84, 93, 5), with: .color(ink)); ctx.fill(circle(116, 93, 5), with: .color(ink))
            ctx.fill(circle(76, 108, 7), with: .color(Color(hex: "#F08AA0").opacity(0.35))); ctx.fill(circle(124, 108, 7), with: .color(Color(hex: "#F08AA0").opacity(0.35)))
            var smile = Path(); smile.move(to: p(88, 110)); smile.addQuadCurve(to: p(112, 110), control: p(100, 120))
            ctx.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 3.5 * s, lineCap: .round))
            if avatar.glasses {
                ctx.stroke(circle(84, 92, 12), with: .color(ink), lineWidth: 3.5 * s); ctx.stroke(circle(116, 92, 12), with: .color(ink), lineWidth: 3.5 * s)
                var br = Path(); br.move(to: p(96, 92)); br.addLine(to: p(104, 92)); ctx.stroke(br, with: .color(ink), lineWidth: 3.5 * s)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("Kahraman avatarı")
    }
}

#Preview("Story components") {
    ScrollView {
        VStack(spacing: 16) {
            TonightHeroCard(state: .resume(progress: 0.37, title: "Şehri Kurtaran Gün", meta: "Sayfa 3 / 8 · 4 dakika kaldı")) {}
            TonightHeroCard(state: .bedtime(time: "20.30")) {}
            StreakStrip(days: ["P", "S", "Ç", "P", "C", "C", "P"], doneCount: 3, todayIndex: 3)
            HStack { WorldTile(title: "Uzay Macerası", systemImage: "airplane", tone: .sky, isSelected: true) {}; WorldTile(title: "Korsanlar", systemImage: "sailboat", tone: .sky, isLocked: true) {} }
            StoryProgressRing(progress: 0.36)
            HeroAvatarView(avatar: HeroAvatar())
        }
        .padding(20)
    }
    .background(MPColor.backgroundKid)
}

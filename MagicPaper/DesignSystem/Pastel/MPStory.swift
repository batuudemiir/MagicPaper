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

struct MPStoryCover: View {
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

#Preview("Story components") {
    ScrollView {
        VStack(spacing: 16) {
            TonightHeroCard(state: .resume(progress: 0.37, title: "Şehri Kurtaran Gün", meta: "Sayfa 3 / 8 · 4 dakika kaldı")) {}
            TonightHeroCard(state: .bedtime(time: "20.30")) {}
            StreakStrip(days: ["P", "S", "Ç", "P", "C", "C", "P"], doneCount: 3, todayIndex: 3)
            HStack { WorldTile(title: "Uzay Macerası", systemImage: "airplane", tone: .sky, isSelected: true) {}; WorldTile(title: "Korsanlar", systemImage: "sailboat", tone: .sky, isLocked: true) {} }
            StoryProgressRing(progress: 0.36)
        }
        .padding(20)
    }
    .background(MPColor.backgroundKid)
}

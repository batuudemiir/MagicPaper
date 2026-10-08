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
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MPSpacing.md)
                        .padding(.top, MPSpacing.xxl)
                        .frame(maxWidth: .infinity, minHeight: 108)
                        .overlay(alignment: .topLeading) {
                            MPIconTile(systemImage: systemImage, tone: tone, size: 46, filled: false)
                                .rotationEffect(.degrees(-8)).mpShadow(.control).offset(x: -6, y: -8)
                        }
                        .overlay(alignment: .topTrailing) {
                            if isLocked {
                                MPIcon("lock.fill", size: 12, weight: .bold)
                                    .foregroundStyle(MPColor.statusWarning)
                                    .frame(width: 28, height: 28).background(.white, in: Circle()).padding(MPSpacing.md)
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
            else {
                MPIcon(systemImage, size: 64, weight: .light).foregroundStyle(.white.opacity(0.95))
                    .frame(maxHeight: .infinity, alignment: .top).padding(.top, MPSpacing.xxl)
                    .accessibilityHidden(true)
            }
            VStack(spacing: MPSpacing.sm) {
                Text(actionTitle).mpText(.caption).fontWeight(.black).foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, MPSpacing.lg).frame(minHeight: 28).background(LinearGradient.mpPrimary, in: Capsule())
                Text(title).mpText(.footnote).fontWeight(.heavy).foregroundStyle(.white)
                    .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.75)
            }
            .padding(.horizontal, MPSpacing.md).padding(.bottom, MPSpacing.md).padding(.top, MPSpacing.xxxl)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [MPColor.coverScrim.opacity(0), MPColor.coverScrim.opacity(0.62)], startPoint: .top, endPoint: .bottom))
        }
        .aspectRatio(167.0 / 206.0, contentMode: .fit)
        // Kapak bir görsel karo: oranı sabit. Yazı en fazla xxLarge'a büyür;
        // başlığın tamamı erişilebilirlik etiketinde.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .clipShape(RoundedRectangle(cornerRadius: MPRadius.tile))
        .overlay(alignment: .topLeading) {
            if let badge {
                Text(badge).mpText(.caption).fontWeight(.black).foregroundStyle(MPColor.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, MPSpacing.sm).padding(.vertical, MPSpacing.xxs)
                    .background(.white.opacity(0.92), in: Capsule()).padding(MPSpacing.sm)
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            }
        }
        .mpShadow(.card)
        .accessibilityElement(children: .combine)
    }
}

// MARK: Home hero ("Bu akşamın masalı"): 4 states, see docs/SCREENS.md › Ana sayfa

enum TonightState { case resume(progress: Double, title: String, meta: String), unread(title: String, meta: String), readToday, bedtime(time: String) }

struct TonightHeroCard: View {
    let state: TonightState
    /// Yarım ya da bu akşamın masalının kapak simgesi ve dünyası.
    var coverIcon: String? = nil
    var coverTone: MPWorldTone = .yellow
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
                ProgressView(value: progress).tint(MPWorldTone.pink.deep).padding(.top, MPSpacing.md)
            }
            MPButton(title: buttonTitle, systemImage: buttonIcon, action: onPrimary).padding(.top, MPSpacing.lg)
        }
        .padding(MPSpacing.xl)
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
        case .readToday: MascotImage(mascot: .waving, width: 140).padding(.top, MPSpacing.xl)
        case .bedtime: MascotImage(mascot: .sleeping, width: 160).padding(.top, (MPSpacing.xxxl + MPSpacing.md))
        default:
            if let coverIcon {
                MPIcon(coverIcon, size: 64, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(width: 130, height: 150)
                    .background(LinearGradient(colors: [coverTone.soft, coverTone.deep], startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: MPRadius.tile))
                    .rotationEffect(.degrees(6))
                    .mpShadow(.raised)
                    .padding(.top, MPSpacing.md)
                    .accessibilityHidden(true)
            }
        }
    }
    private var background: AnyShapeStyle {
        switch state {
        case .resume: AnyShapeStyle(LinearGradient(colors: [MPWorldTone.pink.soft, MPWorldTone.yellow.soft], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .unread: AnyShapeStyle(LinearGradient(colors: [MPWorldTone.sky.soft, MPWorldTone.lav.soft], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .readToday: AnyShapeStyle(LinearGradient(colors: [MPWorldTone.green.soft, MPWorldTone.mint.soft], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .bedtime: AnyShapeStyle(LinearGradient(colors: [MPColor.bedtimeSkyTop, MPColor.bedtimeSkyBottom], startPoint: .top, endPoint: .bottom))
        }
    }
}

// MARK: Streak strip (Ana sayfa): weekly, forgiving: today is dashed, no guilt copy

struct StreakStrip: View {
    static let dayLetters = ["P", "S", "Ç", "P", "C", "C", "P"]
    /// Pazartesi'den Pazar'a, bu hafta okunan günler (`MPStreak.thisWeek`).
    let done: [Bool]
    /// Üst üste okunan gün (`MPStreak.currentStreak`).
    let streak: Int
    let todayIndex: Int

    /// Sakin süreklilik dili (CLAUDE.md §7): kayıp, geri sayım yok.
    var title: String {
        switch streak {
        case 0:  return "Okuma yolculuğun burada başlıyor"
        case 1:  return "Okuma yolculuğun devam ediyor"
        default: return "\(streak) gün üst üste okudun"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            MPIconTile(systemImage: "flame", tone: .peach, size: 42, filled: false)
            VStack(alignment: .leading, spacing: 8) {
                Text(title).mpText(.bodyStrong).fontWeight(.black).foregroundStyle(MPColor.textPrimary)
                HStack(spacing: 5) {
                    ForEach(Self.dayLetters.indices, id: \.self) { i in
                        let read = i < done.count && done[i]
                        Text(Self.dayLetters[i]).mpText(.caption).fontWeight(.black)
                            .foregroundStyle(read ? .white : MPColor.textSecondary)
                            .frame(width: 26, height: 26)
                            .background(read ? MPColor.statusStreak : (i == todayIndex ? .white : .white.opacity(0.6)), in: Circle())
                            .overlay { if i == todayIndex && !read { Circle().strokeBorder(MPColor.statusStreak, style: StrokeStyle(lineWidth: 2, dash: [3, 2])) } }
                    }
                }
            }
        }
        .padding(.horizontal, MPSpacing.lg).padding(.vertical, MPSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MPWorldTone.peach.soft, in: RoundedRectangle(cornerRadius: MPRadius.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). Bu hafta \(done.filter { $0 }.count) gün okudun")
    }
}

// MARK: Progress ring + stages (Masal yazılıyor, İlk masal hazırlanıyor)

enum StageState { case done, active, todo }

struct StoryProgressRing: View {
    let progress: Double   // 0...1
    var body: some View {
        ZStack {
            Circle().stroke(MPColor.ringTrack, lineWidth: 14)
            Circle().trim(from: 0, to: progress).stroke(MPColor.actionPrimary, style: StrokeStyle(lineWidth: 14, lineCap: .round)).rotationEffect(.degrees(-90))
            Text("%\(Int(progress * 100))").mpText(.display).monospacedDigit().foregroundStyle(MPColor.textPrimary)
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
            MPIcon(state == .done ? "checkmark" : systemImage, size: 14, weight: .bold)
                .foregroundStyle(state == .done ? MPWorldTone.green.deep : state == .active ? MPColor.actionPrimary : MPColor.stageTodo)
                .frame(width: 32, height: 32)
                .background(state == .done ? MPWorldTone.green.soft : state == .active ? MPColor.actionSoft : MPWorldTone.gray.soft, in: Circle())
            Text(title).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
            Spacer()
        }
        .padding(.horizontal, MPSpacing.lg).padding(.vertical, MPSpacing.md)
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
                Text(word).mpText(.headline).foregroundStyle(MPColor.textPrimary)
                Text(meaning).mpText(.body).foregroundStyle(onClose != nil ? MPColor.textSecondary : MPColor.textPrimary)
                if let source { Text(source).mpText(.caption).foregroundStyle(MPColor.textSecondary) }
            }
            Spacer()
            if let onSpeak {
                Button(action: onSpeak) {
                    MPIcon("speaker.wave.2", size: 20, weight: .semibold)
                        .foregroundStyle(isSpeaking ? .white : MPColor.actionPrimary)
                        .frame(width: 46, height: 46)
                        .background(isSpeaking ? MPColor.actionPrimary : .white, in: Circle())
                        .mpShadow(.control)
                }
                .accessibilityLabel("\(word) kelimesini dinle")
            }
            if let onClose { MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat", size: 34, bordered: false, action: onClose) }
        }
        .padding(MPSpacing.md)
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
            StreakStrip(done: [true, true, true, false, false, false, false], streak: 3, todayIndex: 3)
            HStack { WorldTile(title: "Uzay Macerası", systemImage: "airplane", tone: .sky, isSelected: true) {}; WorldTile(title: "Korsanlar", systemImage: "sailboat", tone: .sky, isLocked: true) {} }
            StoryProgressRing(progress: 0.36)
        }
        .padding(MPSpacing.xl)
    }
    .background(MPColor.backgroundKid)
}

import SwiftUI

/// 11 · Ana sayfa (`AnaSayfa`).
///
/// Sıra teslimdeki gibi: çocuğun başlığı, "Bu akşamın masalı" kartı (4 durum),
/// haftalık okuma şeridi, Ragi'nin sorusu ve mod şeridi, devam eden seri,
/// günün masalı. Dünya şeridinin yerinde modlar duruyor: dünyalar içerik
/// geldikçe eklenecek (karar 7 Ekim 2026). Yıldız sayacı yok.
struct HomeView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var streak = MPStreak.shared
    @StateObject private var dailyManager = DailyStoryManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                KidHeader(greeting: greeting, childName: activeName,
                          avatar: { MPAvatar(name: activeName, color: profileManager.currentProfile?.mpColor,
                                             size: MPSize.headerAvatar) },
                          onAvatar: { app.showKidCorner = true },
                          onLock: { app.requestParentMode() })
                    .padding(.top, MPSpacing.md)

                TonightHeroCard(state: tonightState, coverIcon: tonightCover?.icon,
                                coverTone: tonightCover?.tone ?? .yellow, onPrimary: tonightAction)

                Button { app.showKidCorner = true } label: {
                    StreakStrip(done: streak.thisWeek, streak: streak.currentStreak, todayIndex: todayIndex)
                }
                .buttonStyle(MPPressStyle())
                .accessibilityHint("Benim köşemi açar")

                if !shownModes.isEmpty { modeStrip }

                if let child = profileManager.currentProfile?.id,
                   SeriesManager.shared.cardState(for: child) != nil {
                    VStack(alignment: .leading, spacing: MPSpacing.md) {
                        MPSectionHeader(title: "Devam eden seri")
                        SeriesCard(childID: child)
                    }
                }

                if let daily = todaysDaily { dailySection(daily) }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(alignment: .top) { HeaderWash(height: 220) }
        .background(MPColor.backgroundKid.ignoresSafeArea())
    }

    // MARK: - Başlık

    private var activeName: String {
        profileManager.currentProfile?.name ?? "Arkadaşım"
    }

    /// Saate göre selam: akşam açılan bir masal uygulamasına "günaydın"
    /// demek, ürünün ne için var olduğunu bilmemek olurdu.
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11:  return "Günaydın,"
        case 11..<17: return "İyi günler,"
        case 17..<22: return "İyi akşamlar,"
        default:      return "İyi geceler,"
        }
    }

    private var todayIndex: Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7
    }

    // MARK: - Bu akşamın masalı

    private var todaysDaily: DailyStory? {
        dailyManager.todaysStory ?? dailyManager.dailyStories.first
    }

    /// Kural `MPTonight`'ta (SCREENS.md 11): widget ve Siri de aynı masalı
    /// seçer. Görünüm yalnızca metne çevirir.
    private var tonight: MPTonightSource.Resolved { MPTonightSource.current(settings: settings) }

    private var tonightState: TonightState {
        switch tonight.tonight() {
        case .bedtime(let bedtime):
            return .bedtime(time: bedtime.clockLabel)
        case .resume(let resume):
            return .resume(progress: resume.progress, title: resume.title,
                           meta: "Sayfa \(resume.page) / \(resume.pageCount)")
        case .unread(let daily):
            return .unread(title: daily.title, meta: "\(daily.minutes) dakika")
        case .readToday:
            return .readToday
        }
    }

    private var tonightCover: (icon: String, tone: MPWorldTone)? {
        let tonight = tonight
        switch tonight.tonight() {
        case .resume:
            guard let story = tonight.resumeStory else { return nil }
            return (story.mpWorld.icon, story.mpWorld.tone)
        case .unread:
            return ("book", .sky)
        default:
            return nil
        }
    }

    private func tonightAction() {
        app.openTonight()
    }

    // MARK: - Mod şeridi

    private var shownModes: [StoryMode] {
        let age = profileManager.currentProfile?.age ?? AgeBandResolver.mvp.upperBound
        let available = StoryCreationSteps.allowedModes(StoryChoiceSources.current.availableModes(forAge: age),
                                                        isBedtime: MPBedtime.isBedtime(settings: settings))
        return StoryCreationSteps.shownModes(available)
    }

    private var modeStrip: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            MascotSays(mascot: .curious, text: "Bu akşam nasıl bir masal olsun?")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MPSpacing.md) {
                    ForEach(shownModes, id: \.self) { mode in
                        WorldTile(title: mode.shortTitle, systemImage: mode.symbol, tone: mode.tone,
                                  compact: true) {
                            app.startStoryCreation(mode: mode)
                        }
                        .accessibilityLabel(mode.title)
                        .accessibilityHint("Masalda kimlerin olacağını seçmeye geçer")
                    }
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.vertical, MPSpacing.xs)
            }
            .scrollClipDisabled()
            .padding(.horizontal, -MPSpacing.screenH)
        }
    }

    // MARK: - Günün masalı

    private func dailySection(_ daily: DailyStory) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            MPSectionHeader(title: "Günün masalı")
            Button { app.dailyReading = daily } label: {
                MPCard(area: .kid, padding: MPSpacing.lg) {
                    HStack(spacing: MPSpacing.lg) {
                        MPIcon(daily.category.mpSymbol, size: 30, weight: .semibold)
                            .foregroundStyle(MPWorldTone.green.deep)
                            .frame(width: 72, height: 72)
                            .background(MPWorldTone.green.soft, in: RoundedRectangle(cornerRadius: MPRadius.tile))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                            Text("Herkes için").mpText(.caption).foregroundStyle(MPWorldTone.green.deep)
                            Text(daily.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(daily.readingTime) dakika").mpText(.footnote)
                                .foregroundStyle(MPColor.textSecondary)
                        }
                        Spacer(minLength: 0)
                        MPIcon("play.fill", size: 18, weight: .bold)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(LinearGradient.mpPrimary, in: Circle())
                            .accessibilityHidden(true)
                    }
                }
            }
            .buttonStyle(MPPressStyle())
            .accessibilityElement(children: .combine)
            .accessibilityHint("Masalı okur")
        }
    }
}

#Preview("11 · Ana sayfa") {
    HomeView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}

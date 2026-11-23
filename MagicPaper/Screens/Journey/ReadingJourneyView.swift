import SwiftUI

/// Menü → Okuma yolculuğum (23 Kasım 2026, İrem; prototip `yolculuk.js`).
///
/// Üstte ana sayfanın mor göğü, geri ve başlık; beyaz kartta sevinçli Ragi,
/// "N gün üst üste", sakin cümle ve Pazartesi–Pazar şeridi (okunan gün mor tik,
/// bugün halkalı, okunmayan gün boş daire, gelecek gün tarih). Altında okuma
/// zamanı, yıldız katı, yeni kelimeler ve son rozet. Kurallar `ReadingJourney`.
struct ReadingJourneyView: View {
    let profile: UserProfile

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var streak = MPStreak.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var journey: ReadingJourney?

    var body: some View {
        // Menü sayfalarının ortak çatısı (`MPSkyPage`, 23 Kasım 2026).
        MPSkyPage(title: "Okuma yolculuğum", onBack: { app.router.closeKidPage() }) {
            if let journey { weekCard(journey) }
        } content: {
            if let journey {
                VStack(alignment: .leading, spacing: MPSpacing.md) {
                    tiles(journey)
                    wordsRow(journey)
                    badgeRow(journey)
                }
            }
        }
        .task(id: profile.id) { refresh() }
        .onChange(of: streak.readDays) { _, _ in refresh() }
        .onChange(of: storyManager.stories) { _, _ in refresh() }
    }

    private func refresh() { journey = ReadingJourney.live(for: profile) }

    // MARK: - Başlık ve hafta kartı

    private func weekCard(_ journey: ReadingJourney) -> some View {
        VStack(spacing: MPSpacing.xs) {
            if !typeSize.isAccessibilitySize {
                MascotImage(mascot: .cheer, width: MPSize.minTouchHero * 2)
                    .padding(MPSpacing.sm)
                    .background(MPWorldTone.yellow.soft, in: Circle())
                    .accessibilityHidden(true)
            }
            Text(journey.headline).mpText(.page).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(journey.message).mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            weekStrip(journey).padding(.vertical, MPSpacing.sm)
            Text(journey.weekSummary).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MPSpacing.lg)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
    }

    private func weekStrip(_ journey: ReadingJourney) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(journey.days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: MPSpacing.xs) {
                    Text(day.label).mpText(.footnote).fontWeight(.bold)
                        .foregroundStyle(day.isToday ? MPColor.actionPrimary : MPColor.textSecondary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    dayMark(day)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(dayLabel(day))
            }
        }
        .padding(.vertical, MPSpacing.xs)
        .background(MP.C.surfaceSunken, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
    }

    @ViewBuilder
    private func dayMark(_ day: ReadingJourney.Day) -> some View {
        let size = MPSize.circleButton - MPSpacing.sm
        if day.read {
            MPIcon("checkmark", size: MP.G.sm, weight: .bold)
                .foregroundStyle(MPColor.textOnAction)
                .frame(width: size, height: size)
                .background(MPColor.actionPrimary, in: Circle())
                .overlay { if day.isToday { todayRing(size) } }
        } else if day.isFuture {
            Text("\(day.dayOfMonth)").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                .frame(width: size, height: size)
        } else {
            // Okunmamış gün: boş daire, başarısızlık işareti değil.
            Circle().strokeBorder(MPColor.borderKid, lineWidth: 2)
                .background(MPColor.backgroundSurface, in: Circle())
                .frame(width: size, height: size)
                .overlay { if day.isToday { todayRing(size) } }
        }
    }

    private func todayRing(_ size: CGFloat) -> some View {
        Circle().strokeBorder(MPColor.actionPrimary, lineWidth: 2)
            .frame(width: size + MPSpacing.sm, height: size + MPSpacing.sm)
    }

    private func dayLabel(_ day: ReadingJourney.Day) -> String {
        let name = ["Pzt": "Pazartesi", "Sal": "Salı", "Çar": "Çarşamba", "Per": "Perşembe",
                    "Cum": "Cuma", "Cmt": "Cumartesi", "Paz": "Pazar"][day.label] ?? day.label
        let today = day.isToday ? ", bugün" : ""
        if day.isFuture { return "\(name)\(today)" }
        return "\(name)\(today), \(day.read ? "okundu" : "okunmadı")"
    }

    // MARK: - Okuma zamanı ve yıldız katı

    private func tiles(_ journey: ReadingJourney) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: MPSpacing.sm))
            : AnyLayout(HStackLayout(alignment: .top, spacing: MPSpacing.sm))
        return layout {
            readingTime(journey)
            starTile(journey)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func readingTime(_ journey: ReadingJourney) -> some View {
        let peak = max(journey.days.map(\.minutes).max() ?? 0, 1)
        return VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text("Okuma zamanı").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
            HStack(alignment: .bottom, spacing: MPSpacing.xxs) {
                ForEach(Array(journey.days.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: MPSpacing.xxs) {
                        Capsule()
                            .fill(day.minutes > 0 ? MPColor.actionPrimary : MPColor.borderKid)
                            .frame(height: max(MPSpacing.sm, MPSize.minTouchHero * CGFloat(day.minutes) / CGFloat(peak)))
                        Text(String(day.label.prefix(1))).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: MPSize.minTouchHero + MPSpacing.xl, alignment: .bottom)
            .accessibilityHidden(true)
            Text("Bu hafta \(journey.minutesThisWeek) dakika").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MPSpacing.md)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
        .accessibilityElement(children: .combine)
    }

    /// Yıldız katı: yalnızca bugünkü kat, bir sonrakine ilerleme yok.
    private func starTile(_ journey: ReadingJourney) -> some View {
        VStack(spacing: MPSpacing.xs) {
            if let level = journey.level {
                MPStarLevelArt(level: level, size: MPSize.minTouchHero)
            } else {
                MPStarMark(size: MPSize.iconTile)
                    .frame(width: MPSize.minTouchHero, height: MPSize.minTouchHero)
                    .background(MPWorldTone.yellow.soft, in: Circle())
            }
            Text(journey.level?.title ?? "Yıldızların").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("\(journey.stars) yıldız").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(MPSpacing.md)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Kelimeler ve rozet

    private func wordsRow(_ journey: ReadingJourney) -> some View {
        Button {
            MPHaptics.tap()
            app.router.openKidPage(.newWords(profile.id))
        } label: {
            HStack(spacing: MPSpacing.md) {
                MPIconTile(systemImage: "textformat", tone: .mint, size: MPSize.iconTile - MPSpacing.xxs)
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text("Yeni kelimelerim").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    if journey.words.isEmpty {
                        Text("Masallarda yeni kelimeler seni bekliyor.").mpText(.supporting)
                            .foregroundStyle(MPColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        MPFlowLayout(spacing: MPSpacing.xs) {
                            ForEach(journey.words, id: \.self) { word in
                                Text(word).mpText(.footnote).fontWeight(.bold)
                                    .foregroundStyle(MPWorldTone.mint.deep)
                                    .padding(.horizontal, MPSpacing.sm)
                                    .padding(.vertical, MPSpacing.xxs)
                                    .background(MPColor.backgroundSurface, in: Capsule())
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
                if journey.wordCount > 0 {
                    Text("\(journey.wordCount) kelime").mpText(.footnote).fontWeight(.bold)
                        .foregroundStyle(MPWorldTone.mint.deep)
                        .padding(.horizontal, MPSpacing.sm)
                        .padding(.vertical, MPSpacing.xs)
                        .background(MPWorldTone.mint.soft, in: Capsule())
                }
            }
            .padding(MPSpacing.md)
            .frame(minHeight: MPSize.choiceRowKid)
            .background(MP.C.surfaceSunken, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Yeni kelimelerimi açar")
    }

    private func badgeRow(_ journey: ReadingJourney) -> some View {
        HomeListRow(systemImage: journey.lastBadge?.icon ?? "rosette",
                    tone: journey.lastBadge?.tone ?? .yellow,
                    title: journey.lastBadge.map { "Son rozetim: \($0.title)" } ?? "Rozetlerim",
                    subtitle: journey.lastBadge == nil ? "Bir masal okuyunca ilk rozetin açılır." : "Okudukça yenileri açılır.",
                    hint: "Rozetlerimi açar") {
            MPHaptics.tap()
            app.router.openKidPage(.badges(profile.id))
        }
    }
}

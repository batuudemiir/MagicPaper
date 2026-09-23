import SwiftUI

/// Ebeveyn paneli — 03-SCREENS.md §12. Uygulamada karşılığı olmayan yeni ekran.
struct ParentPanelView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore

    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var streak = MPStreak.shared

    @State private var exportFile: MPExportFile?
    @State private var isExporting = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ebeveyn")
                        .font(MP.F.displayLG())
                        .mpTightTracking(32)
                        .foregroundStyle(MP.C.textTitle)
                    // Bir ebeveynin bu sayfaya geldiğinde sorduğu soru "işe
                    // yarıyor mu?"dur. Sekiz blok o cevabı içinde taşıyordu ama
                    // hiçbiri söylemiyordu; okumak için kartları toplamak
                    // gerekiyordu. Cümle önce geliyor, ayrıntı arkasından.
                    Text(weekSummary)
                        .font(MP.F.bodySM())
                        .foregroundStyle(MP.C.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                MPIconButton(symbol: "gearshape", label: "Ayarlar") { app.showSettings = true }
            }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.vertical, 4)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    // Onay kuyruğu bu sayfadaki TEK eylem gerektiren şey ve
                    // altıncı sıradaydı: yapılacak iş, okunacak istatistiklerin
                    // altına gömülmüştü. Bir şey bekliyorsa önce o gelir.
                    if settings.approve && !pendingStories.isEmpty { approvalQueue }
                    statsGrid
                    if vocabulary.hasData { vocabularySection }
                    favoriteWorlds
                    profilesSection
                    subscriptionCard
                    MPButton(title: "Masalları indir / yazdır", variant: .outline,
                             icon: "arrow.down.circle", fullWidth: true,
                             isDisabled: isExporting || storyManager.stories.isEmpty) {
                        exportAll()
                    }
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .mpScreenBackground()
        .sheet(item: $exportFile) { file in
            ShareSheet(items: [file.url])
        }
    }

    /// Kütüphanedeki tüm masalları tek bir PDF kitapta toplar.
    private func exportAll() {
        guard !isExporting else { return }
        isExporting = true
        app.showToast("PDF hazırlanıyor", symbol: "printer")

        let snapshot = storyManager.stories
        Task.detached(priority: .userInitiated) {
            let url = MPStoryPDF.makePDF(stories: snapshot, fileName: "magicpaper-masallar.pdf")
            await MainActor.run {
                isExporting = false
                if let url {
                    exportFile = MPExportFile(url: url)
                } else {
                    app.showToast("PDF oluşturulamadı", symbol: "xmark", tone: .danger)
                }
            }
        }
    }

    // MARK: - İstatistikler

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            MPStatCard(symbol: "flame.fill", label: "Okuma serisi",
                       value: "\(streak.currentStreak)", unit: "gün", accent: MP.C.play)
            // Limit açıkken haftalık toplam ikinci plana düşer: ebeveynin
            // bakması gereken sayı, bugünün payından ne kadarının kullanıldığı.
            // Haftalık rakam zaten sayfanın tepesindeki cümlede duruyor.
            if settings.screenLimit {
                MPStatCard(symbol: "hourglass", label: "Bugün okuma",
                           value: "\(streak.minutesToday)",
                           unit: "/ \(settings.screenLimitMinutes) dk", accent: MP.C.calm)
            } else {
                MPStatCard(symbol: "clock", label: "Bu hafta okuma",
                           value: "\(weeklyMinutes)", unit: "dk", accent: MP.C.calm)
            }
            MPStatCard(symbol: "book", label: "Toplam masal",
                       value: "\(storyManager.stories.count)", accent: MP.C.brand)
            MPStatCard(symbol: "star.fill", label: "Kalan yıldız",
                       value: "\(stars)", accent: MP.C.reward)
        }
    }

    /// Sayfanın tepesindeki tek cümle.
    ///
    /// Sıfır durumu ayrı yazılıyor: "0 masal · 0 dk" teknik olarak doğru ve
    /// bir ebeveyne söylenecek en kötü şey. Henüz başlamamış olmak bir başarısızlık
    /// değil.
    private var weekSummary: String {
        let name = profileManager.currentProfile?.name ?? "Çocuğunuz"
        let minutes = weeklyMinutes
        guard minutes > 0 else { return "\(name) bu hafta henüz masal okumadı." }
        return "\(name) bu hafta \(minutes) dakika okudu"
            + (streak.currentStreak > 0 ? " · \(streak.currentStreak) günlük seri" : "")
    }

    /// Okuyucuda geçirilen gerçek süre (MPStreak.addReadingTime ile birikir).
    private var weeklyMinutes: Int {
        streak.minutesThisWeek
    }

    private var stars: Int {
        subscriptionManager.isPremium
            ? subscriptionManager.remainingImageStories
            : subscriptionManager.freeTrialCount
    }

    // MARK: - Kelime dağarcığı

    private var vocabulary: MPVocabulary.Summary {
        MPVocabulary.summary(for: storyManager.stories)
    }

    private var vocabularySection: some View {
        let data = vocabulary
        let peak = max(data.lastSevenDays.max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 16) {
            // "Yeni kelime" ölçülebilen bir şey değildi: bir kelimenin çocuk
            // için yeni olup olmadığını uygulama bilmiyor. Ölçülen şey, okunan
            // sayfalarda geçen FARKLI kelimeler — başlık da artık onu diyor.
            MPSectionHeader(title: "Kelime dağarcığı",
                            subtitle: "Bu ay okunan sayfalarda geçen farklı kelimeler")

            MPCard(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(data.uniqueThisMonth)")
                            .font(MP.F.displayHeavy(26))
                            .foregroundStyle(MP.C.textTitle)
                        Text(data.hasPreviousMonth
                             ? "farklı kelime · geçen aya göre \(signed(data.deltaVsLastMonth))"
                             : "farklı kelime")
                            .font(MP.F.labelSM())
                            .foregroundStyle(MP.C.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if data.hasChart {
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(Array(data.lastSevenDays.enumerated()), id: \.offset) { index, value in
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(index == data.lastSevenDays.count - 1
                                      ? MP.C.brand : MP.Palette.gul100)
                                .frame(height: max(6, 56 * CGFloat(value) / CGFloat(peak)))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 56, alignment: .bottom)
                    .accessibilityLabel("Son 7 günün yeni kelime sayısı")
                    .accessibilityValue(data.lastSevenDays.map(String.init).joined(separator: ", "))
                    }
                }
            }
        }
    }

    private func signed(_ n: Int) -> String {
        n >= 0 ? "+\(n)" : "\(n)"
    }

    // MARK: - Favori dünyalar

    private var favoriteWorlds: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Favori dünyalar")
            MPWrapRow(spacing: 10) {
                ForEach(topWorlds, id: \.self) { world in
                    // Tıklanabilir görünen bir kontrol bir şey yapmalı:
                    // dünyaya dokunmak sihirbazı o dünyayla açar.
                    MPChip(title: world.name, symbol: world.symbol, isSelected: true) {
                        app.startWizard(world: world)
                    }
                }
            }
        }
    }

    private var topWorlds: [MP.World] {
        let counts = Dictionary(grouping: storyManager.stories, by: { $0.mpWorld })
            .mapValues(\.count)
        let sorted = counts.sorted { $0.value > $1.value }.map(\.key)
        return sorted.isEmpty ? Array(MP.World.ordered.prefix(3)) : Array(sorted.prefix(3))
    }

    // MARK: - Profiller

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Çocuk profilleri",
                            actionLabel: "Ekle",
                            action: { app.showProfileAdd = true })

            MPCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(profileManager.profiles.enumerated()), id: \.element.id) { index, profile in
                        if index > 0 { MPRowDivider() }
                        MPListRow(
                            symbol: "person.crop.circle",
                            iconColor: profile.mpColor,
                            title: profile.name,
                            description: "\(profile.mpAgeRange.shortLabel) yaş · \(storyCount(profile)) masal",
                            action: { app.sheet = .profileEdit(profile.id) }
                        )
                    }
                }
            }
        }
    }

    private func storyCount(_ p: UserProfile) -> Int {
        storyManager.stories.filter { $0.belongs(to: p) }.count
    }

    // MARK: - Onay kuyruğu

    private var pendingStories: [Story] {
        storyManager.stories.filter { $0.status == .completed && !settings.isApproved($0.id) }
    }

    private var approvalQueue: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Onay bekleyen masallar",
                            subtitle: "Onaylayana kadar kütüphanede görünmüyor")

            MPCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(pendingStories.prefix(5).enumerated()), id: \.element.id) { index, story in
                        if index > 0 { MPRowDivider() }
                        MPListRow(
                            symbol: "eye.slash",
                            title: story.title,
                            description: "\(story.childName) için oluşturuldu"
                        ) {
                            MPButton(title: "Onayla", variant: .soft, size: .sm) {
                                settings.approveStory(story.id)
                                app.showToast("Masal onaylandı", symbol: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Abonelik

    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Abonelik")

            MPCard(tone: .reward, padding: 18) {
                HStack(spacing: 14) {
                    MPIcon("crown.fill", size: 24, weight: .semibold)
                        .foregroundStyle(MP.C.premiumInk)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscriptionManager.isPremium ? "Hikaye Kahramanı" : "Ücretsiz plan")
                            .font(MP.F.bodyMD(.bold))
                            .foregroundStyle(MP.C.textTitle)
                        Text(subscriptionManager.isPremium
                             ? "Aylık yenilenir"
                             : "\(stars) yıldız kaldı")
                            .font(MP.F.labelSM())
                            .foregroundStyle(MP.C.premiumInk)
                    }

                    Spacer(minLength: 0)

                    MPButton(title: subscriptionManager.isPremium ? "Yönet" : "Yükselt",
                             tone: .reward, size: .sm) {
                        app.openPaywall()
                    }
                }
            }
        }
    }
}

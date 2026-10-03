import SwiftUI

/// Ebeveyn modu · **Özet**.
///
/// Bir ebeveynin bu sayfaya geldiğinde sorduğu soru "işe yarıyor mu?"dur.
/// Cümle önce geliyor, ayrıntı arkasından. Yapılacak tek iş — onay bekleyen
/// masallar — okunacak sayıların önünde durur.
///
/// Eski tek parça Ebeveyn panelinin (03-SCREENS.md §12) ilk yarısı. Profiller
/// `ParentChildrenView`'a, abonelik `SettingsView`'a taşındı.
struct ParentOverviewView: View {
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
            MPParentHeader(title: "Özet", subtitle: weekSummary)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    if settings.approve && !pendingStories.isEmpty { approvalQueue }
                    statsGrid
                    if vocabulary.hasData { vocabularySection }
                    MPButton(title: "Masalları indir / yazdır", variant: .outline,
                             icon: "arrow.down.circle", fullWidth: true,
                             isDisabled: isExporting || storyManager.stories.isEmpty) {
                        exportAll()
                    }
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, MP.S.x3)
                .padding(.bottom, MP.S.x7)
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
            let url = await MPStoryPDF.makePDF(stories: snapshot, fileName: "magicpaper-masallar.pdf")
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
            + (streak.currentStreak > 0 ? " · \(streak.currentStreak) gün üst üste" : "")
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
                                      ? MP.C.brand : MP.C.brandSoftEdge)
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

    // MARK: - Onay kuyruğu

    private var pendingStories: [Story] {
        storyManager.stories.filter { $0.isReadable && !settings.isApproved($0.id) }
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
}

import SwiftUI

/// 17 · Masal aksiyonları (`MasalAksiyon`): Kitaplık'ta kapağa dokununca.
///
/// Favori, baştan oku, seri devamı serbest. Yazdır/paylaş ve sil çocuk
/// modunda ebeveyn kapısından geçer (teslimin çocuk güvenliği kuralı);
/// kapı bu sayfanın içinde açılır ve yalnızca o işlemi yapar, ebeveyn
/// alanına geçmez. Birincil eylem: Okumaya başla.
struct StoryActionsSheet: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let storyID: UUID
    let snapshot: Story
    /// Okuyucu sayfa kapandıktan sonra açılır (`baştan` ise ilk sayfadan).
    let onRead: (_ story: Story, _ fromStart: Bool) -> Void

    @EnvironmentObject private var app: MPAppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var series = SeriesManager.shared
    @StateObject private var favorites = MPFavorites.shared

    private enum Locked: Identifiable {
        case export, delete
        var id: Self { self }
    }

    @State private var gateFor: Locked?
    @State private var confirmDelete = false
    @State private var exportFile: MPExportFile?
    @State private var isExporting = false

    init(story: Story, onRead: @escaping (_ story: Story, _ fromStart: Bool) -> Void) {
        self.storyID = story.id
        self.snapshot = story
        self.onRead = onRead
    }

    private var story: Story { storyManager.stories.first { $0.id == storyID } ?? snapshot }
    private var isFavorite: Bool { favorites.contains(story.id) }
    private var isPartlyRead: Bool { story.mpProgress > 0 && story.mpProgress < 1 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            content
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MPButton(title: isPartlyRead ? "Okumaya devam et" : "Okumaya başla",
                     systemImage: "book", fullWidth: true) {
                onRead(story, false)
                dismiss()
            }
            .padding(.horizontal, MPSpacing.screenH + MPSpacing.lg)
            .padding(.vertical, MPSpacing.md)
            .background(MPColor.backgroundKid)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(MPRadius.sheet)
        .presentationBackground(MPColor.backgroundKid)
        .fullScreenCover(item: $gateFor) { action in
            ParentalGateView(onSuccess: {
                gateFor = nil
                switch action {
                case .export: export()
                case .delete: confirmDelete = true
                }
            }, onCancel: { gateFor = nil })
        }
        .confirmationDialog("Masalı sil", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Sil", role: .destructive) {
                storyManager.deleteStory(id: story.id)
                app.showToast("Masal silindi", symbol: "trash", tone: .danger)
                dismiss()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("\u{201C}\(story.title)\u{201D} kitaplıktan silinir. Bu işlem geri alınamaz.")
        }
        .sheet(item: $exportFile) { file in ShareSheet(items: [file.url]) }
    }

    private var content: some View {
        VStack(spacing: MPSpacing.lg) {
            header
            MPGroupedList(area: .kid) {
                row(icon: "heart", tone: .pink, title: isFavorite ? "Favorilerden çıkar" : "Favorilere ekle") {
                    let now = favorites.toggle(story.id)
                    MPHaptics.selection()
                    app.showToast(now ? "Favorilere eklendi" : "Favorilerden çıkarıldı", symbol: "heart.fill")
                }
                MPRowDivider(area: .kid)
                row(icon: "arrow.counterclockwise", tone: .lav, title: "Baştan oku") {
                    onRead(story, true)
                    dismiss()
                }
                seriesRow
                MPRowDivider(area: .kid)
                row(icon: "printer", tone: .sky, title: "Yazdır veya paylaş",
                    subtitle: app.isParentMode ? nil : "Ebeveyn onayı ister", locked: !app.isParentMode) {
                    if app.isParentMode { export() } else { gateFor = .export }
                }
                if AccountService.shared.canWriteFamily {
                MPRowDivider(area: .kid)
                row(icon: "trash", tone: .pink, title: "Masalı sil",
                    subtitle: app.isParentMode ? nil : "Ebeveyn onayı ister",
                    destructive: true, locked: !app.isParentMode) {
                    if app.isParentMode { confirmDelete = true } else { gateFor = .delete }
                }
                }
            }
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, MPSpacing.xxl)
        .padding(.bottom, MPSpacing.lg)
    }

    // MARK: - Başlık

    /// En büyük yazı boyutlarında kapak başlığın üstüne iner; başlık
    /// kelime ortasından bölünmez.
    private var header: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: MPSpacing.lg))
            : AnyLayout(HStackLayout(spacing: MPSpacing.lg))
        return layout {
            // Kitaplıktaki kapağın aynısı (20 Ekim): degrade karo yerine.
            MPBookCover(art: LibraryShelfModel.coverArt(story), width: 100)
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                Text(story.title).mpText(.title3).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                MPFlowLayout(spacing: MPSpacing.xs) {
                    MPPill(text: "\(story.pages.count) sayfa", tone: .gray)
                    if story.isIllustrated { MPPill(text: "Görselli", tone: .yellow) }
                    if let badge = SeriesCopy.episodeBadge(story) { MPPill(text: badge, tone: .peach) }
                    MPPill(text: story.childName, tone: .green)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Satırlar

    /// "Devam ettir" (FAZ 13) ya da başka bir seri sürerken sakin satır.
    @ViewBuilder
    private var seriesRow: some View {
        switch series.endingState(for: story) {
        case .offer:
            MPRowDivider(area: .kid)
            row(icon: "sparkles", tone: .peach, title: SeriesCopy.continueButton,
                subtitle: SeriesCopy.continueHint) {
                do {
                    try series.startSeries(from: story)
                    MPHaptics.success()
                    app.showToast(SeriesCopy.startedToast, symbol: "sparkles")
                } catch {
                    app.showToast(SeriesCopy.startFailed, symbol: "xmark")
                }
            }
            .accessibilityHint(SeriesCopy.continueAccessibilityHint)
        case .blocked:
            MPRowDivider(area: .kid)
            Text(SeriesCopy.blocked(child: story.childName))
                .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MPSpacing.lg)
        default:
            EmptyView()
        }
    }

    private func row(icon: String, tone: MPWorldTone, title: String, subtitle: String? = nil,
                     destructive: Bool = false, locked: Bool = false,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MPListRow(systemImage: icon, tone: tone, title: title, subtitle: subtitle,
                      isDestructive: destructive) {
                if locked {
                    MPIcon("lock", size: 18, weight: .semibold).foregroundStyle(MPColor.textSecondary)
                }
            }
            .frame(minHeight: MPSize.minTouchKid)
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - PDF

    private func export() {
        guard !isExporting else { return }
        isExporting = true
        app.showToast("PDF hazırlanıyor", symbol: "printer")
        let snapshot = story
        Task.detached(priority: .userInitiated) {
            let url = await MPStoryPDF.makePDF(for: snapshot)
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
}

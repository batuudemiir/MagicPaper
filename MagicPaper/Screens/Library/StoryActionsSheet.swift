import SwiftUI

/// 17 · Masal aksiyonları (`MasalAksiyon`): Kitaplık'ta kapağa dokununca.
///
/// Favori, baştan oku, seri devamı serbest. Yazdır/paylaş ve sil çocuk
/// modunda ebeveyn kapısından geçer (teslimin çocuk güvenliği kuralı);
/// kapı bu sayfanın içinde açılır ve yalnızca o işlemi yapar, ebeveyn
/// alanına geçmez. Birincil eylem: Okumaya başla.
///
/// iOS 26 düzeni (21 Ekim 2026): pencere içeriğin boyu kadar açılır. Üstte
/// kapak, ad ve tek satır künye; altında birincil düğme; onun altında ikincil
/// işlemler yazılı yuvarlak düğmeler hâlinde (Favori, Baştan, Paylaş, Sil).
/// Ebeveyn onayı isteyen düğmede küçük kilit var.
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
    /// İçeriğin ölçülen boyu: pencere bu kadar açılır.
    @State private var contentHeight: CGFloat = 0

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
            content.mpMeasureHeight($contentHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .mpSheet(.fitted(contentHeight))
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
            MPButton(title: isPartlyRead ? "Okumaya devam et" : "Okumaya başla",
                     systemImage: "book", fullWidth: true) {
                onRead(story, false)
                dismiss()
            }
            actionRow
            seriesRow
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, MPSpacing.xxl)
        .padding(.bottom, MPSpacing.lg)
    }

    // MARK: - İkincil işlemler

    /// Yazılı yuvarlak düğmeler. En büyük yazı boyutlarında ikişerli sıra.
    private var actionRow: some View {
        let columns = typeSize.isAccessibilitySize ? 2 : 4
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.sm), count: columns),
                         spacing: MPSpacing.md) {
            circleAction(icon: isFavorite ? "heart.fill" : "heart",
                         title: isFavorite ? "Favoride" : "Favori",
                         label: isFavorite ? "Favorilerden çıkar" : "Favorilere ekle",
                         tint: isFavorite ? MPColor.brandPink : MPColor.textPrimary) {
                let now = favorites.toggle(story.id)
                MPHaptics.selection()
                app.showToast(now ? "Favorilere eklendi" : "Favorilerden çıkarıldı", symbol: "heart.fill")
            }
            circleAction(icon: "arrow.counterclockwise", title: "Baştan", label: "Baştan oku") {
                onRead(story, true)
                dismiss()
            }
            circleAction(icon: "square.and.arrow.up", title: "Paylaş", label: "Yazdır veya paylaş",
                         locked: !app.isParentMode) {
                if app.isParentMode { export() } else { gateFor = .export }
            }
            if AccountService.shared.canWriteFamily {
                circleAction(icon: "trash", title: "Sil", label: "Masalı sil",
                             tint: MP.C.danger, locked: !app.isParentMode) {
                    if app.isParentMode { confirmDelete = true } else { gateFor = .delete }
                }
            }
        }
    }

    private func circleAction(icon: String, title: String, label: String,
                              tint: Color = MPColor.textPrimary, locked: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: MPSpacing.xs) {
                MPIcon(icon, size: MP.G.lg, weight: .semibold)
                    .foregroundStyle(tint)
                    .frame(width: MP.S.x10 - MP.S.x2, height: MP.S.x10 - MP.S.x2)
                    .background(MP.C.surfaceCard, in: Circle())
                    .overlay(alignment: .bottomTrailing) {
                        if locked {
                            MPIcon("lock.fill", size: MP.G.xs, weight: .bold)
                                .foregroundStyle(MPColor.textSecondary)
                                .frame(width: MP.S.x6, height: MP.S.x6)
                                .background(MP.C.surfaceSunken, in: Circle())
                                .accessibilityHidden(true)
                        }
                    }
                Text(title)
                    .font(MP.F.caption(.bold))
                    .foregroundStyle(MPColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: MP.S.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(label)
        .accessibilityHint(locked ? "Ebeveyn onayı ister" : "")
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
            MPBookCover(art: LibraryShelfModel.coverArt(story), width: 88)
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                Text(story.title).mpText(.title3).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                // Etiket kutucukları yerine kitabın künyesi gibi tek satır.
                Text(metaLine)
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if isPartlyRead {
                    Text("Yarım kaldı")
                        .font(MP.F.caption(.bold))
                        .foregroundStyle(MPColor.actionPrimary)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var metaLine: String {
        var parts = ["\(story.pages.count) sayfa", story.childName]
        if story.isIllustrated { parts.append("Görselli") }
        if let badge = SeriesCopy.episodeBadge(story) { parts.append(badge) }
        return parts.joined(separator: " · ")
    }

    // MARK: - Satırlar

    /// "Devam ettir" (FAZ 13) ya da başka bir seri sürerken sakin satır.
    @ViewBuilder
    private var seriesRow: some View {
        switch series.endingState(for: story) {
        case .offer:
            MPGroupedList(area: .kid) {
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
            }
        case .blocked:
            Text(SeriesCopy.blocked(child: story.childName))
                .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
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

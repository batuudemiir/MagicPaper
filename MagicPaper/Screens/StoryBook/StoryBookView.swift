import SwiftUI

/// 35 · Masal kitabı (`KitapSiparisi`): çocuğun masallarından PDF kitap.
///
/// Ebeveyn alanında, Ayarlar'dan açılır. Kitaba girecek masallar işaretlenir;
/// PDF `MPStoryPDF` ile cihazda çizilir ve sistemin paylaşım sayfasıyla
/// kaydedilir ya da gönderilir. Basılı kitap iş modeli kararına kadar yok;
/// tasarımdaki "PDF / Basılı kitap" seçimi ve "Aileyle paylaş" (FAZ 18) bu
/// yüzden gösterilmez.
struct StoryBookView: View {
    let profile: UserProfile
    let onClose: () -> Void

    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @State private var selected: Set<UUID> = []
    @State private var isExporting = false
    @State private var exportFile: MPExportFile?
    @State private var failed = false

    private var candidates: [Story] { StoryBookPlan.candidates(storyManager.stories, for: profile) }

    var body: some View {
        let all = candidates
        let chosen = StoryBookPlan.ordered(all, selected: selected)
        VStack(spacing: 0) {
            ParentHeader(title: "Masal kitabı", subtitle: "Masalları kitap haline getir", onBack: onClose)
                .padding(.horizontal, MPSpacing.screenH)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.xl) {
                    cover.frame(maxWidth: .infinity)

                    Text(summary(chosen))
                        .mpText(.callout).foregroundStyle(MPColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.updatesFrequently)

                    if all.isEmpty {
                        Text("Kitaba girecek bir masal yok. Okunan masallar burada görünür.")
                            .mpText(.body).foregroundStyle(MPColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Kitaba girecek masallar").mpText(.headline).foregroundStyle(MPColor.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        MPCard(area: .parent, padding: MPSpacing.lg) {
                            VStack(alignment: .leading, spacing: MPSpacing.md) {
                                ForEach(all) { story in row(story) }
                            }
                        }
                    }

                    if failed {
                        Text("PDF oluşturulamadı. Biraz sonra tekrar dene.")
                            .mpText(.footnote).foregroundStyle(MPColor.statusDanger)
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.vertical, MPSpacing.lg)
            }

            MPButton(title: "PDF oluştur", systemImage: "book", fullWidth: true, isLoading: isExporting) {
                export(chosen)
            }
            .disabled(chosen.isEmpty)
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.vertical, MPSpacing.md)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .onAppear { selected = StoryBookPlan.defaultSelection(candidates) }
        .sheet(item: $exportFile) { file in ShareSheet(items: [file.url]) }
    }

    // MARK: - Kapak

    private var cover: some View {
        VStack(spacing: MPSpacing.lg) {
            MPInitialAvatar(name: profile.name, color: profile.mpColor, size: 84)
                .padding(MPSpacing.sm)
                .background(MPColor.backgroundSurface.opacity(0.4), in: Circle())
            Text("\(SeriesCopy.genitive(profile.name))\nMasal Kitabı")
                .mpText(.title3)
                .foregroundStyle(MPColor.textOnAction)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MPSpacing.xl)
        .frame(width: 200)
        .frame(minHeight: 260)
        // Kapak sanatı: malzeme taklidi, gradyana izin var.
        .background(LinearGradient(colors: [MPWorldTone.sky.soft, MPWorldTone.sky.deep],
                                   startPoint: .top, endPoint: .bottom),
                    in: UnevenRoundedRectangle(bottomTrailingRadius: MPRadius.card, topTrailingRadius: MPRadius.card))
        .overlay(alignment: .leading) {
            MPColor.shadowInk.opacity(0.12).frame(width: 12)
        }
        .mpShadow(.raised)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(SeriesCopy.genitive(profile.name)) Masal Kitabı kapağı")
    }

    private func row(_ story: Story) -> some View {
        let on = selected.contains(story.id)
        return Button {
            MPHaptics.selection()
            if on { selected.remove(story.id) } else { selected.insert(story.id) }
        } label: {
            HStack(spacing: MPSpacing.md) {
                RoundedRectangle(cornerRadius: MPRadius.xs)
                    .fill(on ? MPColor.actionPrimary : MPColor.backgroundSurface)
                    .overlay(RoundedRectangle(cornerRadius: MPRadius.xs)
                        .strokeBorder(on ? MPColor.actionPrimary : MPColor.borderDashed, lineWidth: 2))
                    .overlay { if on { MPIcon("checkmark", size: 14, weight: .heavy).foregroundStyle(MPColor.textOnAction) } }
                    .frame(width: 26, height: 26)
                    .accessibilityHidden(true)
                Text(story.title).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: MPSpacing.sm)
                Text("\(story.pages.count) sayfa").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
            }
            .frame(minHeight: MPSize.minTouchParent)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    private func summary(_ chosen: [Story]) -> String {
        guard !chosen.isEmpty else { return "Kitaba girecek masalları seç." }
        return "\(chosen.count) masal, \(StoryBookPlan.pageCount(chosen)) sayfa. Yazdırmaya hazır PDF."
    }

    private func export(_ stories: [Story]) {
        guard !isExporting, !stories.isEmpty else { return }
        isExporting = true
        failed = false
        let name = StoryBookPlan.fileName(childName: profile.name)
        Task.detached(priority: .userInitiated) {
            let url = await MPStoryPDF.makePDF(stories: stories, fileName: name)
            await MainActor.run {
                isExporting = false
                if let url { exportFile = MPExportFile(url: url) } else { failed = true }
            }
        }
    }
}

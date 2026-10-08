import SwiftUI

/// 35 · Masal kitabı (`KitapSiparisi`, FAZ 18).
///
/// Bir çocuğun masallarından PDF kitap. "Basılı kitap" sekmesi görünür ama
/// sipariş yok: basılı kitabın iş modeli kararlaşana kadar sakin bir "yakında"
/// durumu gösterir. Seçim mantığı `BookExportSelection`'da.
struct BookExportView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dynamicTypeSize) private var typeSize

    enum Format: Hashable { case pdf, printed }

    @State private var format: Format = .pdf
    @State private var childID: UUID?
    @State private var selection: BookExportSelection?
    @State private var isExporting = false
    @State private var exportFile: MPExportFile?
    @State private var shareStories: ShareStories?

    let onClose: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                ParentHeader(title: "Masal kitabı", subtitle: "Masalları kitap haline getir", onBack: onClose)

                if profileManager.profiles.count > 1 { childPicker }

                if let selection {
                    BookCoverPreview(title: selection.bookTitle,
                                     childName: selection.childName,
                                     color: profile?.mpColor ?? MPColor.actionPrimary)
                        .frame(maxWidth: .infinity)

                    MPSegmented(options: [(Format.pdf, "PDF"), (Format.printed, "Basılı kitap")],
                                selection: $format, track: MPColor.segmentTrack)

                    switch format {
                    case .pdf: pdfContent(selection)
                    case .printed: printedContent
                    }
                } else {
                    MPNotice(kind: .info, text: "Kitap için önce bir çocuk profili ekle.", systemImage: "person")
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.lg)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if format == .pdf, let selection { bottomActions(selection) }
        }
        .sheet(item: $exportFile) { file in ShareSheet(items: [file.url]) }
        .onAppear {
            if childID == nil { childID = profileManager.currentProfile?.id ?? profileManager.profiles.first?.id }
            rebuild()
        }
        .onChange(of: childID) { _, _ in rebuild() }
    }

    private var profile: UserProfile? {
        profileManager.profiles.first { $0.id == childID }
    }

    private func rebuild() {
        guard let profile else { selection = nil; return }
        selection = BookExportSelection(profile: profile, stories: storyManager.stories)
    }

    // MARK: - Bölümler

    private var childPicker: some View {
        MPFlowLayout(spacing: MPSpacing.sm) {
            ForEach(profileManager.profiles) { child in
                MPChip(title: child.name, isSelected: child.id == childID) {
                    MPHaptics.selection()
                    childID = child.id
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Kimin kitabı")
    }

    @ViewBuilder
    private func pdfContent(_ selection: BookExportSelection) -> some View {
        Text(selection.summary)
            .mpText(.footnote)
            .foregroundStyle(MPColor.textSecondary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)

        if selection.candidates.isEmpty {
            MPNotice(kind: .info, text: "\(selection.childName) için henüz okunabilir masal yok. İlk masal yazılınca burada görünür.",
                     systemImage: "book")
        } else {
            ParentSection(title: "Kitaba girecek masallar") {
                ForEach(Array(selection.candidates.enumerated()), id: \.element.id) { index, story in
                    if index > 0 { MPRowDivider(area: .parent) }
                    storyRow(story, isOn: selection.isSelected(story))
                }
            }
        }
    }

    private func storyRow(_ story: Story, isOn: Bool) -> some View {
        Button {
            MPHaptics.selection()
            self.selection?.toggle(story)
        } label: {
            HStack(spacing: MPSpacing.md) {
                RoundedRectangle(cornerRadius: MPRadius.xs)
                    .fill(isOn ? MPColor.actionPrimary : MPColor.backgroundSurface)
                    .overlay(RoundedRectangle(cornerRadius: MPRadius.xs)
                        .strokeBorder(isOn ? MPColor.actionPrimary : MPColor.borderDashed, lineWidth: 2.5))
                    .overlay { if isOn { MPIcon("checkmark", size: 14, weight: .heavy).foregroundStyle(MPColor.textOnAction) } }
                    .frame(width: 26, height: 26)
                    .accessibilityHidden(true)
                Text(story.title)
                    .mpText(.bodyStrong)
                    .foregroundStyle(MPColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !typeSize.isAccessibilitySize {
                    Text("\(story.pages.count) sayfa").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
            }
            .padding(MPSpacing.md)
            .frame(minHeight: MPSize.minTouchParent)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityLabel(story.title)
        .accessibilityValue("\(story.pages.count) sayfa")
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isOn ? "Kitaptan çıkarır" : "Kitaba ekler")
    }

    private var printedContent: some View {
        MPCard(area: .parent, padding: MPSpacing.lg) {
            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text("Basılı kitap yakında").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                Text("Masallarını ciltli bir kitap olarak basmanın yolunu hazırlıyoruz. Hazır olduğunda burada göreceksin. O zamana kadar PDF'i evde ya da bir kırtasiyede yazdırabilirsin.")
                    .mpText(.footnote).fontWeight(.regular)
                    .foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func bottomActions(_ selection: BookExportSelection) -> some View {
        VStack(spacing: MPSpacing.xs) {
            MPButton(title: isExporting ? "PDF hazırlanıyor" : "PDF oluştur", systemImage: "book",
                     fullWidth: true, isLoading: isExporting) { export(selection) }
                .disabled(!selection.canExport)
            if FamilyFeatureAccess.isEnabled(.shareLink), selection.canExport {
                MPButton(title: "Aileyle paylaş", systemImage: "square.and.arrow.up", kind: .ghost) {
                    shareStories = ShareStories(ids: selection.selected.map(\.id))
                }
            }
        }
        .padding(.horizontal, MPSpacing.xxxl)
        .padding(.vertical, MPSpacing.md)
        .background(MPColor.backgroundParent)
    }

    private func export(_ selection: BookExportSelection) {
        guard !isExporting, selection.canExport else { return }
        isExporting = true
        let stories = selection.selected
        let (name, title) = (selection.fileName, selection.bookTitle)
        Task.detached(priority: .userInitiated) {
            let url = await MPStoryPDF.makePDF(stories: stories, fileName: name, bookTitle: title)
            await MainActor.run {
                isExporting = false
                if let url {
                    MPHaptics.success()
                    exportFile = MPExportFile(url: url)
                } else {
                    app.showToast("PDF oluşturulamadı", symbol: "xmark", tone: .danger)
                }
            }
        }
    }
}

/// Paylaşıma giden masallar (36 · Aileyle paylaş).
struct ShareStories: Identifiable {
    let ids: [UUID]
    var id: String { ids.map(\.uuidString).joined() }
}

/// 35'teki kitap kapağı: çocuğun harf madalyonu ve "İrem'in Masal Kitabı".
/// Kapak sanatı olduğu için degrade burada izinli.
private struct BookCoverPreview: View {
    let title: String
    let childName: String
    let color: Color

    var body: some View {
        VStack(spacing: MPSpacing.lg) {
            MPInitialAvatar(name: childName, color: color, size: 96)
                .padding(MPSpacing.md)
                .background(MPColor.backgroundSurface.opacity(0.35), in: Circle())
            Text(title)
                .mpText(.title3)
                .foregroundStyle(MPColor.textOnAction)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, MPSpacing.lg)
        }
        .frame(width: 200, height: 260)
        .background(LinearGradient(colors: [MPWorldTone.sky.soft, MPWorldTone.sky.deep],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: MPRadius.tile))
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .mpShadow(.raised)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Kapak: \(title)")
    }
}

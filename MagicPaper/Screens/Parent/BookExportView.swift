import SwiftUI
import TipKit

/// 35 · Masal kitabı (`KitapSiparisi`, FAZ 18).
///
/// Bir çocuğun masallarından PDF kitap ya da yılın kitabı (Faz 12, `MPYearbook`).
/// "Basılı kitap yakında" sekmesi kalktı (vizyon planı: gerçek olana kadar
/// yok); yerine "Baskıya hazır" anahtarı A5, taşma paylı ve kesim işaretli bir
/// PDF verir (`MPPrintSpec`). Seçim mantığı `BookExportSelection`'da.
struct BookExportView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dynamicTypeSize) private var typeSize

    enum Format: Hashable { case book, yearbook }

    @State private var format: Format = .book
    /// Baskıya hazır PDF (Faz 12).
    @State private var forPrint = false
    @State private var childID: UUID?
    @State private var selection: BookExportSelection?
    @State private var isExporting = false
    @State private var exportFile: MPExportFile?
    @State private var shareStories: ShareStories?

    let onClose: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                MPParentHeader(title: "Masal kitabı", subtitle: "Masalları kitap haline getir", onBack: onClose)

                if profileManager.profiles.count > 1 { childPicker }

                if let selection {
                    BookCoverPreview(title: selection.bookTitle,
                                     childName: selection.childName,
                                     color: profile?.mpColor ?? MPColor.actionPrimary)
                        .frame(maxWidth: .infinity)

                    MPSegmented(options: [(Format.book, "Masal kitabı"), (Format.yearbook, "Yıllık")],
                                selection: $format, track: MPColor.borderParent)
                    TipView(YearbookTip())

                    switch format {
                    case .book: pdfContent(selection)
                    case .yearbook: yearbookContent
                    }

                    ParentSection(title: "Baskı") {
                        ParentToggleRow(systemImage: "printer", tone: .sky, title: "Baskıya hazır",
                                        subtitle: forPrint
                                            ? "A5, 3 mm taşma payı ve kesim işaretleri. Matbaaya verilebilir."
                                            : "Evde yazdırmak ve ekranda okumak için.",
                                        isOn: $forPrint)
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
            if let selection { bottomActions(selection) }
        }
        .sheet(item: $exportFile) { file in ShareSheet(items: [file.url]) }
        .navigationDestination(item: $shareStories) { chosen in
            ShareLinkView(preselected: chosen.ids, onClose: { shareStories = nil })
                .toolbar(.hidden, for: .navigationBar)
        }
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
                    .mpText(.cardTitle)
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

    // MARK: - Yıllık (Faz 12)

    private var yearbook: MPYearbook? {
        guard let profile else { return nil }
        let service = OfflineStoryService.shared
        return MPYearbook(year: Calendar.current.component(.year, from: Date()),
                          childName: profile.name,
                          stories: storyManager.stories.filter { $0.belongs(to: profile) },
                          placeName: { service.place(id: $0)?.name },
                          companionName: { service.companionName(id: $0) })
    }

    @ViewBuilder
    private var yearbookContent: some View {
        if let book = yearbook, !book.isEmpty {
            Text(book.summaryLine)
                .mpText(.footnote)
                .foregroundStyle(MPColor.textSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            ParentSection(title: book.title) {
                ForEach(Array(book.sections.enumerated()), id: \.offset) { index, section in
                    if index > 0 { MPRowDivider(area: .parent) }
                    VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                        Text(section.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        ForEach(section.lines, id: \.self) { line in
                            Text(line).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(MPSpacing.md)
                    .accessibilityElement(children: .combine)
                }
            }
        } else {
            MPNotice(kind: .info, text: "Bu yıl henüz biten masal yok. İlk masal bitince yıllık burada büyümeye başlar.",
                     systemImage: "calendar")
        }
    }

    private func bottomActions(_ selection: BookExportSelection) -> some View {
        VStack(spacing: MPSpacing.xs) {
            MPButton(title: isExporting ? "PDF hazırlanıyor" : (format == .book ? "PDF oluştur" : "Yıllığı oluştur"),
                     systemImage: format == .book ? "book" : "calendar",
                     fullWidth: true, isLoading: isExporting) { export(selection) }
                .disabled(format == .book ? !selection.canExport : (yearbook?.isEmpty ?? true))
            if format == .book, FamilyFeatureAccess.isEnabled(.shareLink), selection.canExport {
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
        guard !isExporting else { return }
        let spec: MPPrintSpec? = forPrint ? .a5 : nil
        let stories: [Story]
        let name: String
        let title: String
        let book: MPYearbook?
        switch format {
        case .book:
            guard selection.canExport else { return }
            (stories, name, title, book) = (selection.selected, selection.fileName, selection.bookTitle, nil)
        case .yearbook:
            guard let yearbook, !yearbook.isEmpty else { return }
            (stories, name, title, book) = (yearbook.stories,
                                            MPStoryPDF.fileName(for: yearbook.title), yearbook.title, yearbook)
        }
        let fileName = spec == nil ? name : name.replacingOccurrences(of: ".pdf", with: "-baski.pdf")
        isExporting = true
        Task.detached(priority: .userInitiated) {
            let url = await MPStoryPDF.makePDF(stories: stories, fileName: fileName, bookTitle: title,
                                               print: spec, yearbook: book)
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
struct ShareStories: Identifiable, Hashable {
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
            MPAvatar(name: childName, color: color, size: 96).accessibilityHidden(true)
                .padding(MPSpacing.md)
                .background(MPColor.backgroundSurface.opacity(0.35), in: Circle())
            Text(title)
                .mpText(.section)
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

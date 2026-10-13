import SwiftUI

/// 36 · Aileyle paylaş (`Paylas`, FAZ 18): büyükler masalları kendi telefonundan okusun.
///
/// Süreli, salt okuma bağlantısı; web okuyucu Firebase Hosting'de (`/s/{token}`).
/// Bağlantıda çocuğun yalnızca adı ve masal metni (sesli paylaşımda ailenin
/// sesi de). "Sadece okuma" kapatılamaz: bağlantı hiçbir şeyi değiştiremez.
struct ShareLinkView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var account = AccountService.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var voices = VoiceRecordingStore.shared

    /// Masal kitabından gelen seçim; boşsa seçili çocuğun bütün masalları.
    var preselected: [UUID] = []
    let onClose: () -> Void
    var remote: ShareRemote = FirebaseShareRemote()

    @State private var includeVoice = false
    @State private var days = FamilyShareLink.defaultDays
    @State private var recipient = ""
    @State private var created: (token: String, count: Int, days: Int)?
    @State private var history: [ShareRecord] = []
    @State private var working = false
    @State private var failed = false
    @State private var shareText: ShareText?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                ParentHeader(title: "Aileyle paylaş", subtitle: "Büyükler masalları kendi telefonundan okusun", onBack: onClose)

                if account.account == nil {
                    MPNotice(kind: .info, text: "Paylaşım bağlantısı için önce giriş yap.", systemImage: "person.crop.circle")
                } else if !account.canWriteFamily {
                    MPNotice(kind: .info, text: "Bu ailede bağlantıyı ebeveynler paylaşır.", systemImage: "link")
                } else if stories.isEmpty {
                    MPNotice(kind: .info, text: "Paylaşılacak masal yok. İlk masal yazılınca burada görünür.", systemImage: "book")
                } else {
                    if let created { readyCard(created) }
                    optionsCard
                    MPTextField(label: "Kime gönderiyorsun?", placeholder: "Örneğin Ayşe Nine (isteğe bağlı)",
                                text: Binding(get: { recipient }, set: { recipient = String($0.prefix(40)) }),
                                helper: "Yalnızca senin listende görünür, bağlantıda yazmaz.")
                    if failed { MPNotice(kind: .danger, text: FamilyCopy.failed, systemImage: "wifi.slash") }
                    if !history.isEmpty { historySection }
                    Text("Bağlantıda çocuğunun yalnızca adı ve masal metni görünür. Hesap, yaş ya da diğer masallar görünmez.")
                        .mpText(.footnote).fontWeight(.regular)
                        .foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.lg)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if account.account != nil && account.canWriteFamily && !stories.isEmpty {
                MPButton(title: "Bağlantıyı paylaş", systemImage: "square.and.arrow.up", fullWidth: true, isLoading: working) {
                    Task { await share() }
                }
                .padding(.horizontal, MPSpacing.xxxl)
                .padding(.vertical, MPSpacing.md)
                .background(MPColor.backgroundParent)
            }
        }
        .sheet(item: $shareText) { ShareSheet(items: [$0.text]) }
        .task { await loadHistory() }
    }

    // MARK: - Veri

    private var stories: [Story] {
        let readable = storyManager.stories.filter { $0.isReadable && $0.hasReadableText }
        if !preselected.isEmpty {
            return preselected.compactMap { id in readable.first { $0.id == id } }
        }
        let profile = profileManager.currentProfile
        return readable.filter { profile == nil || $0.belongs(to: profile) }.sorted { $0.createdAt < $1.createdAt }
    }

    private var childName: String {
        stories.first?.childName.nilIfEmpty ?? profileManager.currentProfile?.name ?? ""
    }

    private var voiceAvailable: Bool {
        FamilyFeatureAccess.isEnabled(.voiceRecording) && stories.contains { voices.hasRecording($0.id) }
    }

    // MARK: - Bölümler

    private func readyCard(_ link: (token: String, count: Int, days: Int)) -> some View {
        MPCard(area: .parent, padding: MPSpacing.lg) {
            HStack(spacing: MPSpacing.md) {
                MPIconTile(systemImage: "link", tone: .sky, size: 52).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text("Paylaşım bağlantısı hazır").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    Text("\(link.count) masal · \(link.days) gün geçerli").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
                Spacer(minLength: MPSpacing.sm)
                MPButton(title: "Kopyala", systemImage: "doc.on.doc", kind: .soft, size: .small) {
                    UIPasteboard.general.url = FamilyShareLink.url(link.token)
                    MPHaptics.success()
                    app.showToast("Bağlantı kopyalandı", symbol: "doc.on.doc")
                }
            }
        }
    }

    private var optionsCard: some View {
        MPGroupedList(area: .parent) {
            MPListRow(systemImage: "eye", tone: .green, title: "Sadece okuma",
                      subtitle: "Bağlantıyı açan masalı okuyabilir, değiştiremez") {
                Toggle(isOn: .constant(true)) { EmptyView() }.toggleStyle(MPSwitchStyle()).fixedSize()
                    .disabled(true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue("Her zaman açık")
            if voiceAvailable {
                MPRowDivider(area: .parent)
                ParentToggleRow(systemImage: "waveform", tone: .lav, title: "Sesli okuma dahil",
                                subtitle: "Senin sesinle okunan kayıtlar da açılır", isOn: $includeVoice)
            }
            MPRowDivider(area: .parent)
            Menu {
                ForEach(FamilyShareLink.durations, id: \.self) { option in
                    Button("\(option) gün") { days = option }
                }
            } label: {
                MPListRow(systemImage: "clock", tone: .peach, title: "Süre",
                          subtitle: "\(days) gün sonra kendiliğinden kapanır")
            }
            .buttonStyle(MPPressStyle(.highlight))
            .accessibilityLabel("Süre, \(days) gün")
            .accessibilityHint("Bağlantının ne kadar açık kalacağını seç")
        }
    }

    private var historySection: some View {
        ParentSection(title: "Daha önce paylaştıkların") {
            ForEach(Array(history.enumerated()), id: \.element.id) { index, record in
                if index > 0 { MPRowDivider(area: .parent) }
                MPListRow(systemImage: "person", tone: index % 2 == 0 ? .pink : .yellow,
                          title: record.recipient ?? "Bağlantı",
                          subtitle: "\(record.storyCount) masal · \(FamilyCopy.expiry(record.expiresAt))") {
                    if record.isActive() {
                        Button("Kapat") { Task { await revoke(record) } }
                            .mpText(.callout)
                            .foregroundStyle(MPColor.statusDanger)
                            .frame(minHeight: MPSize.minTouchParent)
                            .accessibilityLabel("\(record.recipient ?? "Bağlantı") paylaşımını kapat")
                    }
                }
            }
        }
    }

    // MARK: - İşler

    private func loadHistory() async {
        guard let familyID = account.familyID, account.canWriteFamily else { return }
        history = (try? await remote.list(familyID: familyID)) ?? history
    }

    private func share() async {
        if let created {
            shareText = ShareText(text: FamilyShareLink.message(childName: childName, url: FamilyShareLink.url(created.token)))
            return
        }
        guard let familyID = account.familyID, let uid = account.account?.uid else { return }
        working = true
        defer { working = false }
        let withVoice = includeVoice && voiceAvailable
        if withVoice { for story in stories { await voices.prefetch(story.id) } }
        let document = ShareDocument(
            familyID: familyID, childName: childName, stories: stories, voice: withVoice,
            expiresAt: Date().addingTimeInterval(TimeInterval(days) * 86_400),
            // Yalnızca paylaşanın kendi sesi: başka bir yetişkinin kaydı onun
            // rızası olmadan bağlantıya girmez.
            recordedPages: { id in
                guard let set = voices.recordings(for: id) else { return [] }
                return set.pageIndexes.filter { page in
                    set.by?[String(page)] == uid && voices.localFile(id, page: page) != nil
                }
            })
        var files: [String: URL] = [:]
        for (index, story) in document.stories.enumerated() {
            let id = stories[index].id
            for page in story.audio { files["\(index)/\(page)"] = voices.localFile(id, page: page) }
        }
        let token = FamilyShareLink.makeToken()
        do {
            try await remote.create(token: token, document: document, recipient: recipient.trimmingCharacters(in: .whitespaces),
                                    audioFiles: files, createdBy: uid)
            created = (token, document.stories.count, days)
            failed = false
            MPHaptics.success()
            shareText = ShareText(text: FamilyShareLink.message(childName: childName, url: FamilyShareLink.url(token)))
            await loadHistory()
        } catch {
            failed = true
        }
    }

    private func revoke(_ record: ShareRecord) async {
        guard let familyID = account.familyID else { return }
        do {
            try await remote.revoke(record, familyID: familyID)
            if created?.token == record.token { created = nil }
            app.showToast("Bağlantı kapatıldı", symbol: "link")
            await loadHistory()
        } catch {
            app.showToast(FamilyCopy.failed, symbol: "xmark", tone: .danger)
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

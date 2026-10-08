import SwiftUI

/// 33 · Kendi sesin (`SesKaydi`, FAZ 18): masalı sayfa sayfa ebeveynin sesiyle kaydet.
///
/// Önce ses kaydı rızası (bir kez, kaydeden her yetişkin için), sonra masal
/// seçimi, sonra sayfa sayfa kayıt. Kayıtlar `VoiceRecordingStore`'da; okuyucu
/// "Kim okusun?" ile çalar.
struct VoiceRecordingView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var account = AccountService.shared
    @ObservedObject private var store = VoiceRecordingStore.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared

    @State private var consentGiven = false
    @State private var agreed = false
    @State private var working = false
    @State private var failed = false
    @State private var recordingStory: Story?
    @State private var confirmWithdraw = false

    let onClose: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                ParentHeader(title: "Kendi sesin", subtitle: "Masalı sen oku, çocuğun her akşam dinlesin", onBack: onClose)

                if account.account == nil {
                    MPNotice(kind: .info, text: "Ses kaydı için önce giriş yap. Kayıtlar yalnızca aile hesabında saklanır.",
                             systemImage: "person.crop.circle")
                } else if !account.canWriteFamily {
                    MPNotice(kind: .info, text: "Bu ailede masalları dinleyebilirsin; ses kaydını ebeveynler yapar.",
                             systemImage: "headphones")
                } else if !consentGiven {
                    consentCard
                } else {
                    storyList
                    privacyNote
                    withdrawRow
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.lg)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if account.account != nil && account.canWriteFamily && !consentGiven {
                MPButton(title: "Onaylıyorum", fullWidth: true, isLoading: working) { Task { await giveConsent() } }
                    .disabled(!agreed)
                    .padding(.horizontal, MPSpacing.xxxl)
                    .padding(.vertical, MPSpacing.md)
                    .background(MPColor.backgroundParent)
            }
        }
        .fullScreenCover(item: $recordingStory) { story in
            VoicePageRecorderView(story: story, onClose: { recordingStory = nil })
                .environmentObject(app)
        }
        .confirmationDialog("Ses kayıtların silinsin mi?", isPresented: $confirmWithdraw, titleVisibility: .visible) {
            Button("Kayıtlarımı sil ve rızamı geri çek", role: .destructive) { Task { await withdraw() } }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Senin sesinle kaydedilen bütün sayfalar bu cihazdan ve aile hesabından silinir.")
        }
        .onAppear {
            if let uid = account.account?.uid { consentGiven = VoiceConsent.isGiven(uid: uid) }
        }
    }

    // MARK: - Rıza

    private var consentCard: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            MPCard(area: .parent, padding: MPSpacing.lg) {
                VStack(alignment: .leading, spacing: MPSpacing.sm) {
                    Text("Ses kaydı onayı").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(VoiceConsent.text)
                        .mpText(.footnote).fontWeight(.regular)
                        .foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            MPCheckbox(isOn: $agreed, label: "Sesimin bu amaçla kaydedilmesine açık rıza veriyorum.")
            if failed {
                MPNotice(kind: .danger, text: FamilyCopy.failed, systemImage: "wifi.slash")
            }
        }
    }

    private func giveConsent() async {
        guard let uid = account.account?.uid, let familyID = account.familyID else { return }
        working = true
        defer { working = false }
        do {
            try await VoiceConsent.give(familyID: familyID, uid: uid)
            failed = false
            consentGiven = true
            MPHaptics.success()
        } catch {
            failed = true
        }
    }

    private func withdraw() async {
        guard let uid = account.account?.uid, let familyID = account.familyID else { return }
        store.deleteAll(recordedBy: uid)
        do {
            try await VoiceConsent.withdraw(familyID: familyID, uid: uid)
            consentGiven = false
            agreed = false
            app.showToast("Ses kayıtların silindi", symbol: "trash")
        } catch {
            app.showToast(FamilyCopy.failed, symbol: "xmark", tone: .danger)
        }
    }

    // MARK: - Masallar

    private var stories: [Story] {
        let profile = profileManager.currentProfile
        return storyManager.stories
            .filter { $0.isReadable && $0.hasReadableText && (profile == nil || $0.belongs(to: profile)) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    @ViewBuilder
    private var storyList: some View {
        if stories.isEmpty {
            MPNotice(kind: .info, text: "Kaydedilecek masal yok. İlk masal yazılınca burada görünür.", systemImage: "book")
        } else {
            ParentSection(title: "Hangi masalı okuyacaksın?") {
                ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                    if index > 0 { MPRowDivider(area: .parent) }
                    ParentRowButton(systemImage: store.hasRecording(story.id) ? "waveform" : "mic",
                                    tone: store.hasRecording(story.id) ? .lav : .gray,
                                    title: story.title,
                                    subtitle: VoiceCopy.progress(store.recordings(for: story.id), pages: story.pages.count)) {
                        recordingStory = story
                    }
                }
            }
        }
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: MPSpacing.sm) {
            MPIcon("lock", size: 13, weight: .semibold).foregroundStyle(MPColor.textSecondary).accessibilityHidden(true)
            Text(VoiceCopy.privacy).mpText(.footnote).fontWeight(.regular).foregroundStyle(MPColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var withdrawRow: some View {
        MPGroupedList(area: .parent) {
            ParentRowButton(systemImage: "trash", title: "Kayıtlarımı sil", subtitle: "Ses kaydı rızanı da geri çeker",
                            isDestructive: true) { confirmWithdraw = true }
        }
    }
}

enum VoiceCopy {
    /// Teslimdeki not, sesli paylaşım eklendiği için "sen paylaşmadıkça" ile.
    static let privacy = "Kaydın yalnızca bu aile hesabında kullanılır; sen sesli bir paylaşım bağlantısı oluşturmadıkça başka bir yerde açılmaz. Ayarlar'dan istediğin an silebilirsin."

    static func progress(_ set: VoiceRecordingSet?, pages: Int) -> String {
        let done = set?.pages.count ?? 0
        if done == 0 { return "\(pages) sayfa · henüz kaydedilmedi" }
        if done >= pages { return "Hepsi kaydedildi · \(pages) sayfa" }
        return "\(done) / \(pages) sayfa kaydedildi"
    }

    /// Ayarlar satırının alt yazısı: "1 masal kaydedildi".
    static func settingsLine(_ count: Int) -> String {
        count == 0 ? "Masalları senin sesinle okusun" : "\(count) masal kaydedildi"
    }
}

// MARK: - Sayfa sayfa kayıt

/// Bir masalın sayfaları tek tek: metni oku, kaydet, dinle, sonraki sayfa.
struct VoicePageRecorderView: View {
    let story: Story
    let onClose: () -> Void

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var store = VoiceRecordingStore.shared
    @StateObject private var recorder = MPVoiceRecorder()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var permissionDenied = false

    private var pageCount: Int { story.pages.count }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.lg) {
                ParentHeader(title: "Kendi sesin", subtitle: "Masalı sen oku, çocuğun her akşam dinlesin", onBack: close)

                MPCard(area: .parent, padding: MPSpacing.lg) {
                    HStack(spacing: MPSpacing.md) {
                        MPIconTile(systemImage: "book", tone: .yellow, size: 52).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                            Text(story.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                            Text("Sayfa \(page + 1) / \(pageCount)").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)

                MPCard(area: .parent, padding: MPSpacing.lg) {
                    VStack(alignment: .leading, spacing: MPSpacing.sm) {
                        Text("BU SAYFAYI OKU").mpText(.eyebrow).foregroundStyle(MPColor.textSecondary)
                        Text(pageText)
                            .mpText(.headline).fontWeight(.bold)
                            .foregroundStyle(MPColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VoiceLevelDots(level: recorder.level, active: recorder.state == .recording, reduceMotion: reduceMotion)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                controls

                if permissionDenied {
                    MPNotice(kind: .warning, text: "Mikrofon izni kapalı. Sistem Ayarları > MagicPaper'dan açabilirsin.",
                             systemImage: "mic.slash")
                }

                HStack(alignment: .top, spacing: MPSpacing.sm) {
                    MPIcon("lock", size: 13, weight: .semibold).foregroundStyle(MPColor.textSecondary).accessibilityHidden(true)
                    Text(VoiceCopy.privacy).mpText(.footnote).fontWeight(.regular).foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.lg)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MPButton(title: "Kaydı bitir", systemImage: "checkmark", fullWidth: true) { close() }
                .disabled(recorder.state == .recording)
                .padding(.horizontal, MPSpacing.xxxl)
                .padding(.vertical, MPSpacing.md)
                .background(MPColor.backgroundParent)
        }
        .onAppear { page = firstUnrecordedPage }
        .onDisappear { recorder.stop(); recorder.discard() }
    }

    private var pageText: String {
        story.pages.indices.contains(page) ? story.pages[page].text : ""
    }

    private var firstUnrecordedPage: Int {
        (0..<pageCount).first { !store.isRecorded(story.id, page: $0) } ?? 0
    }

    // MARK: - Denetimler

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: MPSpacing.md) {
            Text(hint).mpText(.bodyStrong).foregroundStyle(MPColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: MPSpacing.xl) {
                if case .recorded = recorder.state {
                    MPCircleButton(systemImage: "play.fill", accessibilityLabel: "Dinle") { recorder.play() }
                } else if recorder.state == .playing {
                    MPCircleButton(systemImage: "stop.fill", accessibilityLabel: "Dinlemeyi durdur") { recorder.stopPlayback() }
                } else if store.isRecorded(story.id, page: page), recorder.state == .idle {
                    MPCircleButton(systemImage: "play.fill", accessibilityLabel: "Kaydı dinle") { playSaved() }
                }

                MPRoundActionButton(
                    systemImage: recorder.state == .recording ? "stop.fill" : "mic.fill",
                    accessibilityLabel: recorder.state == .recording ? "Kaydı durdur" : "Kaydet",
                    size: 84,
                    fill: recorder.state == .recording ? AnyShapeStyle(MPColor.statusDanger) : AnyShapeStyle(LinearGradient.mpPrimary)
                ) { toggleRecording() }

                if case .recorded = recorder.state {
                    MPCircleButton(systemImage: "arrow.counterclockwise", accessibilityLabel: "Yeniden kaydet") { recorder.discard() }
                }
            }
            .frame(maxWidth: .infinity)

            HStack {
                MPButton(title: "Önceki", systemImage: "chevron.left", kind: .ghost) { go(page - 1) }
                    .disabled(page == 0 || recorder.state == .recording)
                Spacer()
                if case .recorded = recorder.state {
                    MPButton(title: page + 1 < pageCount ? "Kaydet, sonraki" : "Kaydet", kind: .soft, size: .small) { keep() }
                } else {
                    MPButton(title: "Sonraki", systemImage: "chevron.right", kind: .ghost) { go(page + 1) }
                        .disabled(page + 1 >= pageCount || recorder.state == .recording)
                }
            }
        }
    }

    private var hint: String {
        switch recorder.state {
        case .idle: return store.isRecorded(story.id, page: page) ? "Bu sayfa kaydedildi. Yeniden kaydedebilirsin." : "Hazır olduğunda dokun"
        case .recording: return "Kaydediliyor · \(Int(recorder.elapsed)) sn"
        case .recorded: return "Dinle, beğendiysen kaydet"
        case .playing: return "Dinliyorsun"
        }
    }

    private func toggleRecording() {
        if recorder.state == .recording {
            recorder.stop()
            MPHaptics.tap()
            return
        }
        Task {
            guard await MPVoiceRecorder.requestPermission() else { permissionDenied = true; return }
            permissionDenied = false
            do {
                try recorder.start()
                MPHaptics.tap()
            } catch {
                app.showToast("Kayıt başlatılamadı", symbol: "xmark", tone: .danger)
            }
        }
    }

    private func keep() {
        guard let taken = recorder.take() else { return }
        do {
            try store.save(recordingAt: taken.url, storyID: story.id, page: page, seconds: taken.seconds,
                           by: AccountService.shared.account?.uid)
            MPHaptics.success()
            if page + 1 < pageCount { page += 1 }
        } catch {
            app.showToast("Kayıt saklanamadı", symbol: "xmark", tone: .danger)
        }
    }

    private func playSaved() {
        if let file = store.localFile(story.id, page: page) {
            MPSpeech.shared.speak("", recording: file)
        }
    }

    private func go(_ target: Int) {
        guard (0..<pageCount).contains(target) else { return }
        recorder.discard()
        MPSpeech.shared.stop()
        page = target
    }

    private func close() {
        recorder.stop()
        recorder.discard()
        MPSpeech.shared.stop()
        if store.hasRecording(story.id) {
            app.showToast("Kayıt saklandı", symbol: "waveform")
        }
        onClose()
    }
}

/// Teslimdeki nokta dizisi: kayıt sürerken sesin gücüyle yükselir.
/// Reduce Motion'da yükselmez; yalnızca renk değişir (kayıt sürüyor bilgisi
/// metinde de var).
private struct VoiceLevelDots: View {
    let level: Double
    let active: Bool
    let reduceMotion: Bool
    private let count = 24

    var body: some View {
        HStack(spacing: MPSpacing.xxs) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(active ? MPColor.statusDanger.opacity(0.75) : MPColor.borderDashed)
                    .frame(width: 8, height: height(i))
            }
        }
        .frame(height: 40)
        .animation(reduceMotion ? nil : MPMotion.spring, value: level)
    }

    private func height(_ i: Int) -> CGFloat {
        guard active, !reduceMotion else { return 8 }
        // Ortadakiler daha çok yükselir.
        let middle = Double(count - 1) / 2
        let weight = 1 - abs(Double(i) - middle) / middle * 0.6
        return 8 + CGFloat(level * weight * 32)
    }
}

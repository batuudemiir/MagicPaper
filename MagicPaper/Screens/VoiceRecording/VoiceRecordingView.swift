import SwiftUI

/// 33 · Kendi sesin (`SesKaydi`): ebeveyn masalı sayfa sayfa okur, çocuk
/// okuyucuda "Kim okusun? Ailenin sesi" ile dinler.
///
/// Ebeveyn alanında, Ayarlar'dan; FAZ 18 bayrağının arkasında. Önce masal
/// seçilir, sonra her sayfa için kayıt. Kayıtlar yalnızca bu cihazda
/// (`VoiceRecordingStore`); hesaba yükleme onay metni değişince gelir.
struct VoiceRecordingView: View {
    let profile: UserProfile
    let onClose: () -> Void

    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @State private var story: Story?

    var body: some View {
        Group {
            if let story {
                VoiceRecordingPages(story: story) { self.story = nil }
            } else {
                picker
            }
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
    }

    // MARK: - Masal seçimi

    private var picker: some View {
        let stories = StoryBookPlan.candidates(storyManager.stories, for: profile).reversed()
        let store = VoiceRecordingStore.shared
        return VStack(spacing: 0) {
            ParentHeader(title: "Kendi sesin", subtitle: "Masalı sen oku, çocuğun her akşam dinlesin", onBack: onClose)
                .padding(.horizontal, MPSpacing.screenH)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.lg) {
                    Text("Hangi masalı okuyacaksın?").mpText(.headline).foregroundStyle(MPColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    if stories.isEmpty {
                        Text("Kitaplıkta henüz masal yok.").mpText(.body).foregroundStyle(MPColor.textSecondary)
                    }
                    MPCard(area: .parent, padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(stories.enumerated()), id: \.element.id) { index, item in
                                if index > 0 { MPRowDivider(area: .parent) }
                                let done = store.recordedPages(story: item.id).count
                                Button { story = item } label: {
                                    MPListRow(systemImage: item.mpWorld.icon, tone: item.mpWorld.tone, title: item.title,
                                              subtitle: done == 0 ? "\(item.pages.count) sayfa"
                                                                  : "\(done) / \(item.pages.count) sayfa kaydedildi")
                                }
                                .buttonStyle(MPPressStyle(.highlight))
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    VoicePrivacyNote()
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.vertical, MPSpacing.lg)
            }
        }
    }
}

/// Bir masalın sayfa sayfa kaydı.
private struct VoiceRecordingPages: View {
    let story: Story
    let onDone: () -> Void

    @StateObject private var recorder = VoiceRecorder()
    @ObservedObject private var speech = MPSpeech.shared
    @State private var page = 0
    @State private var recorded: Set<Int> = []

    private let store = VoiceRecordingStore.shared

    var body: some View {
        VStack(spacing: 0) {
            ParentHeader(title: "Kendi sesin", subtitle: "Masalı sen oku, çocuğun her akşam dinlesin", onBack: finish)
                .padding(.horizontal, MPSpacing.screenH)

            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.lg) {
                    MPCard(area: .parent, padding: MPSpacing.lg) {
                        HStack(spacing: MPSpacing.md) {
                            MPIconTile(systemImage: story.mpWorld.icon, tone: story.mpWorld.tone, size: 52)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                                Text(story.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                                Text("Sayfa \(page + 1) / \(story.pages.count)").mpText(.footnote)
                                    .foregroundStyle(MPColor.textSecondary)
                            }
                            Spacer(minLength: 0)
                            if recorded.contains(page) {
                                MPIcon("checkmark.circle", size: 22, weight: .semibold)
                                    .foregroundStyle(MPColor.statusSuccess)
                                    .accessibilityLabel("Bu sayfa kaydedildi")
                            }
                        }
                    }

                    MPCard(area: .parent, padding: MPSpacing.xl) {
                        VStack(alignment: .leading, spacing: MPSpacing.md) {
                            Text("Bu sayfayı oku").mpText(.eyebrow).foregroundStyle(MPColor.textSecondary)
                            Text(story.pages.indices.contains(page) ? story.pages[page].text : "")
                                .font(MP.F.read(MP.ReadSize.normal.points))
                                .lineSpacing(MP.ReadSize.normal.lineSpacing)
                                .foregroundStyle(MPColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    waveform
                    recordControls
                    VoicePrivacyNote()
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.vertical, MPSpacing.lg)
            }

            HStack(spacing: MPSpacing.md) {
                MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Önceki sayfa") { go(-1) }
                    .disabled(page == 0 || recorder.state == .recording)
                MPButton(title: page + 1 < story.pages.count ? "Sonraki sayfa" : "Kaydı bitir",
                         systemImage: page + 1 < story.pages.count ? nil : "checkmark", fullWidth: true) {
                    if page + 1 < story.pages.count { go(1) } else { finish() }
                }
                .disabled(recorder.state == .recording)
            }
            .padding(.horizontal, MPSpacing.xl)
            .padding(.vertical, MPSpacing.md)
        }
        .onAppear { recorded = Set(store.recordedPages(story: story.id)) }
        .onDisappear {
            recorder.stop()
            speech.stop()
        }
    }

    // MARK: - Kayıt

    private var waveform: some View {
        HStack(alignment: .center, spacing: MPSpacing.xxs) {
            ForEach(Array(recorder.levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(recorder.state == .recording ? MPColor.statusDanger : MPColor.borderParent)
                    .frame(width: 6, height: 10 + 50 * level)
            }
        }
        .frame(height: 64)
        .animation(MP.M.gated(MP.M.easeOut), value: recorder.levels)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var recordControls: some View {
        VStack(spacing: MPSpacing.md) {
            Text(statusLine)
                .mpText(.callout)
                .foregroundStyle(recorder.state == .recording ? MPColor.statusDanger : MPColor.textSecondary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.updatesFrequently)

            Button(action: toggleRecording) {
                Group {
                    if recorder.state == .recording {
                        RoundedRectangle(cornerRadius: MPRadius.xs).fill(MPColor.textOnAction).frame(width: 30, height: 30)
                    } else {
                        MPIcon("mic", size: 32, weight: .semibold).foregroundStyle(MPColor.textOnAction)
                    }
                }
                .frame(width: 76, height: 76)
                .background(recorder.state == .recording ? MPColor.statusDanger : MPColor.actionPrimary, in: Circle())
                .padding(MPSpacing.xs)
                .background(MPColor.backgroundSurface, in: Circle())
                .mpShadow(.raised)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel(recorder.state == .recording ? "Kaydı durdur" : (recorded.contains(page) ? "Yeniden kaydet" : "Kaydet"))

            if recorded.contains(page), recorder.state != .recording {
                HStack(spacing: MPSpacing.lg) {
                    MPButton(title: speech.isSpeaking ? "Durdur" : "Dinle",
                             systemImage: speech.isSpeaking ? "stop.fill" : "play.fill", kind: .soft, size: .small) {
                        if speech.isSpeaking { speech.stop() } else {
                            speech.speak("", recording: store.recording(story: story.id, page: page))
                        }
                    }
                    MPButton(title: "Sil", systemImage: "trash", kind: .ghost, size: .small) {
                        speech.stop()
                        store.delete(story: story.id, page: page)
                        recorded.remove(page)
                    }
                }
            }
        }
    }

    private var statusLine: String {
        switch recorder.state {
        case .recording: return "Kaydediliyor…"
        case .denied: return "Mikrofon izni yok. Ayarlar > MagicPaper > Mikrofon'dan açabilirsin."
        case .failed: return "Kayıt başlamadı. Biraz sonra tekrar dene."
        case .idle: return recorded.contains(page) ? "Bu sayfa kaydedildi. Yeniden kaydedebilirsin." : "Hazır olduğunda dokun"
        }
    }

    private func toggleRecording() {
        if recorder.state == .recording {
            recorder.stop()
            MPHaptics.success()
            return
        }
        speech.stop()
        guard let url = try? store.destination(story: story.id, page: page) else { return }
        let current = page
        Task {
            await recorder.start(to: url) { recorded.insert(current) }
        }
    }

    private func go(_ delta: Int) {
        speech.stop()
        page = min(max(0, page + delta), story.pages.count - 1)
    }

    private func finish() {
        recorder.stop()
        speech.stop()
        onDone()
    }
}

/// Gizlilik notu: kaydın nerede durduğu ve nasıl silindiği.
private struct VoicePrivacyNote: View {
    var body: some View {
        HStack(alignment: .top, spacing: MPSpacing.sm) {
            MPIcon("lock", size: 14, weight: .semibold).foregroundStyle(MPColor.textSecondary)
                .accessibilityHidden(true)
            Text("Kaydın yalnızca bu cihazda kalır, hiçbir yere gönderilmez. Masalı ya da kaydı istediğin an silebilirsin.")
                .mpText(.footnote).fontWeight(.regular)
                .foregroundStyle(MPColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

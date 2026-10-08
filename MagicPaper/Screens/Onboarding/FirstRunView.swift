import SwiftUI
import StoryEngine

/// İlk profil oluşunca bir kez: 09 · Bildirim izni, sonra 10 · İlk masal.
///
/// İzin yalnızca "Hatırlat"a basınca istenir; "Şimdi değil" eşit ağırlıkta.
/// İlk masal "Bana sürpriz yap" yoluyla kurulur (çocuk için mod motor seçer).
struct FirstRunView: View {
    let childName: String
    /// Masal hazırsa okunacak masal; `nil` ise ana sayfaya dönülür.
    let onFinish: (Story?) -> Void

    @ObservedObject private var settings = MPSettingsStore.shared
    @ObservedObject private var profileManager = ProfileManager.shared

    private enum Step { case reminder, firstStory }
    @State private var step: Step = .reminder
    @State private var story: Story?
    @State private var modeTitle: String?
    @State private var failed = false
    @State private var failureReason: StoryFailureReason = .general
    @State private var asking = false

    var body: some View {
        ZStack {
            MPColor.backgroundKid.ignoresSafeArea()
            switch step {
            case .reminder:
                ReminderPrePrompt(asking: asking, onRemind: remind, onLater: later)
                    .transition(.opacity)
            case .firstStory:
                if failed {
                    StoryCreationFailureView(onRetry: { failed = false; buildFirstStory() },
                                             onClose: { onFinish(nil) },
                                             message: failureReason.message)
                } else {
                    StoryPreparationView(
                        childName: childName,
                        modeTitle: modeTitle,
                        story: story,
                        onRead: { onFinish(story) },
                        onCancel: { onFinish(nil) },
                        title: "\(SeriesCopy.genitive(childName)) ilk masalı yazılıyor",
                        cancelTitle: "Sonra oku")
                    .transition(.opacity)
                }
            }
        }
        .animation(MP.M.gated(MP.M.base), value: step)
    }

    // MARK: 09

    private func remind(hour: Int, minute: Int) {
        asking = true
        Task {
            let result = await MPReminder.enable(hour: hour, minute: minute, childName: childName)
            settings.reminderHour = hour
            settings.reminderMinute = minute
            settings.reminder = (result == .scheduled)
            asking = false
            next()
        }
    }

    private func later() {
        settings.reminder = false
        MPReminder.disable()
        next()
    }

    private func next() {
        step = .firstStory
        buildFirstStory()
    }

    // MARK: 10

    private func buildFirstStory() {
        guard let profile = profileManager.currentProfile else { return onFinish(nil) }
        story = nil
        Task {
            do {
                let manager = StoryGenerationManager.shared
                let mode = try StoryChoiceSources.current.resolveMode(
                    strategy: .surprise, requested: nil, forAge: profile.age,
                    recent: manager.recentModes(for: profile))
                modeTitle = mode.shortTitle
                story = try await manager.createStory(
                    for: profile, mode: mode, strategy: .surprise,
                    storyIdeaID: nil, companionID: nil)
            } catch {
                // §29: the detail goes to the log, never to the parent.
                print("❌ İlk masal kurulamadı: \(storyFailureDetail(error))")
                failureReason = StoryFailureReason(error)
                failed = true
            }
        }
    }
}

/// 09 · Bildirim izni ön ekranı.
private struct ReminderPrePrompt: View {
    let asking: Bool
    let onRemind: (Int, Int) -> Void
    let onLater: () -> Void

    private static let times: [(hour: Int, minute: Int)] = [(19, 30), (20, 0), (20, 30), (21, 0)]
    @State private var selected = 2

    var body: some View {
        VStack(spacing: MPSpacing.xl) {
            Spacer(minLength: MPSpacing.lg)
            MascotImage(mascot: .sleepy, width: 170)
                .background(Circle().fill(MPWorldTone.yellow.soft).frame(width: 190, height: 170).offset(y: 14))
                .accessibilityHidden(true)
            VStack(spacing: MPSpacing.md) {
                Text("Masal saatini hatırlatalım mı?")
                    .mpText(.largeTitle).foregroundStyle(MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("Her akşam seçtiğin saatte tek bir hatırlatma. Başka bildirim göndermeyiz.")
                    .mpText(.body).foregroundStyle(MPColor.textSecondary)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            MPFlowLayout(spacing: MPSpacing.sm) {
                ForEach(Self.times.indices, id: \.self) { index in
                    let time = Self.times[index]
                    MPChip(title: MPReminder.clockLabel(hour: time.hour, minute: time.minute),
                           isSelected: selected == index) {
                        MPHaptics.selection()
                        selected = index
                    }
                }
            }

            VStack(spacing: MPSpacing.sm) {
                MPButton(title: "Hatırlat", fullWidth: true, isLoading: asking) {
                    let time = Self.times[selected]
                    onRemind(time.hour, time.minute)
                }
                MPButton(title: "Şimdi değil", kind: .outline, fullWidth: true, action: onLater)
                    .disabled(asking)
            }
            .padding(.horizontal, MPSpacing.lg)

            Spacer(minLength: MPSpacing.lg)
            Text("İzni sonra Ebeveyn bölümünden değiştirebilirsin.")
                .mpText(.caption).fontWeight(.regular)
                .foregroundStyle(MPColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, MPSpacing.xl)
        .padding(.bottom, MPSpacing.lg)
    }
}

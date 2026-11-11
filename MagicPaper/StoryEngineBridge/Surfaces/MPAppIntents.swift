import AppIntents

/// Siri ve Kısayollar (41 · Kilit ekranı ve Siri, FAZ 19).
///
/// İkisi de uygulamayı açar ve çocuk alanında bir yer gösterir; ebeveyn
/// alanına, satın almaya ya da ayarlara giden bir kısayol yok.

/// "Bu akşamın masalını oku": Ana sayfa kartının seçtiği masal (`MPTonight`).
struct ReadTonightIntent: AppIntent {
    static let title: LocalizedStringResource = "Bu akşamın masalını oku"
    static let description = IntentDescription("MagicPaper'ı bu akşamın masalında açar.")
    static let openAppWhenRun = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        MPSurfaceRouter.shared.pending = .tonight
        return .result()
    }
}

/// "Uyku modu": son uyku masalı sesli okunur, ekran yavaşça kararır.
/// Faz 11'de açıldı (`MPFeatures.sleepMode`). Bayrak uzaktan kapatılırsa
/// dokunuş bu akşamın masalına düşer (`MPAppState.open(_:childID:)`).
struct StartSleepModeIntent: AppIntent {
    static let title: LocalizedStringResource = "Uyku modunu aç"
    static let description = IntentDescription("Son uyku masalını sesli okur; ekran yavaşça kararır.")
    static let openAppWhenRun = true
    static let isDiscoverable = MPFeatures.sleepMode

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        MPSurfaceRouter.shared.pending = .sleep
        return .result()
    }
}

struct MagicPaperShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ReadTonightIntent(),
            phrases: [
                "\(.applicationName) ile masal oku",
                "\(.applicationName) ile bu akşamın masalını oku",
                "\(.applicationName) masal oku",
            ],
            shortTitle: "Masal oku",
            systemImageName: "book"
        )
        // Faz 11: uyku kapısı açıldı. Kısayollar derleme anında okunur.
        AppShortcut(
            intent: StartSleepModeIntent(),
            phrases: [
                "\(.applicationName) uyku modu",
                "\(.applicationName) ile uyku modunu aç",
            ],
            shortTitle: "Uyku modu",
            systemImageName: "moon.zzz"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .purple
}

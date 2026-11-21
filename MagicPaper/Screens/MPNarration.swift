import Foundation

/// "Kim okusun?" (FAZ 18): bir sayfayı ailenin sesi mi, masal anlatıcısı mı okur.
///
/// Kayıt cihazdaysa ve ebeveyn "Ailenin sesi"ni seçtiyse o kaydın dosyası;
/// yoksa nil ve `MPSpeech` masal anlatıcısına döner. Kaydı olmayan sayfa
/// sessiz kalmaz.
///
/// Sıra (20 Kasım 2026): ailenin sesi → masalın stüdyo seslendirmesi
/// (`MPStudioNarration`, uygulamayla gelir) → cihazın anlatıcısı.
@MainActor
enum MPNarration {
    static func isAvailable(for storyID: UUID, store: VoiceRecordingStore = .shared) -> Bool {
        FamilyFeatureAccess.isEnabled(.voiceRecording) && store.hasRecording(storyID)
    }

    static func recording(_ storyID: UUID, page: Int,
                          store: VoiceRecordingStore = .shared,
                          settings: MPSettingsStore = .shared) -> URL? {
        guard FamilyFeatureAccess.isEnabled(.voiceRecording), settings.familyVoice else { return nil }
        return store.localFile(storyID, page: page)
    }

    /// Sayfayı okuyacak ses dosyası: önce ailenin sesi, sonra stüdyo seslendirmesi.
    /// Stüdyo kaydı yumuşak metne göre okundu; klasik anlatım seçiliyse kullanılmaz.
    static func audio(_ storyID: UUID, page: Int,
                      progress: ClassicProgressStore = .shared) -> URL? {
        if let family = recording(storyID, page: page) { return family }
        guard progress.narration(for: storyID) != .classic else { return nil }
        return MPStudioNarration.file(storyID, page: page)
    }
}

/// Bir masalın uygulamayla gelen stüdyo seslendirmesi (20 Kasım 2026): sayfa başına
/// bir dosya, `narration-<ID>-NN.m4a` (NN 1'den başlar). Kaynak
/// `Content/Originals/published/<slug>/narration/`; uygulamaya
/// `Scripts/ClassicsCatalog/build_classics_catalog.py` kopyalar.
enum MPStudioNarration {
    /// `page` 0'dan başlayan okuyucu sayfası.
    static func file(_ storyID: UUID, page: Int, bundle: Bundle = .main) -> URL? {
        guard page >= 0 else { return nil }
        let name = String(format: "narration-%@-%02d", storyID.uuidString, page + 1)
        return bundle.url(forResource: name, withExtension: "m4a")
    }

    /// Masalın seslendirmesi var mı ("Sesli" rafı).
    static func exists(_ storyID: UUID, bundle: Bundle = .main) -> Bool {
        file(storyID, page: 0, bundle: bundle) != nil
    }
}

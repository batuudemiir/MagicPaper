import Foundation

/// "Kim okusun?" (FAZ 18): bir sayfayı ailenin sesi mi, masal anlatıcısı mı okur.
///
/// Kayıt cihazdaysa ve ebeveyn "Ailenin sesi"ni seçtiyse o kaydın dosyası;
/// yoksa nil ve `MPSpeech` masal anlatıcısına döner. Kaydı olmayan sayfa
/// sessiz kalmaz.
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
}

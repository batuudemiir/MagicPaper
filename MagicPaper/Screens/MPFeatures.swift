import Foundation

/// Lansmanda kapalı tutulan, kodu duran özellikler.
///
/// Uyku modu (26 · kararan ekran, süre, sesli oturum, Live Activity, Siri
/// "Uyku modu") v2'de çıkar (karar 15 Ekim 2026,
/// `docs/UYKU_MODU_V2_PLANI.md`). Kapalıyken giriş noktaları gizlenir:
/// Ana sayfanın akşam kartı uyku masalı penceresini açar, masal sonu
/// "İyi geceler" okuyucuyu kapatır, `magicpaper://sleep` bu akşamın
/// masalına düşer.
enum MPFeatures {
    static let sleepMode = false
}

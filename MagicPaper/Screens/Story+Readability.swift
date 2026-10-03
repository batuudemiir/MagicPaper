import Foundation

// MARK: - Takılı kalmış eski masallar

/// Kaldırılan bulut hattı masalları `.uploading`, `.writingStory`,
/// `.generatingImages` ya da `.failed` durumunda bırakmış olabilir; onları
/// artık hiçbir şey bitirmeyecek. Karar: metni olan masal metin masalı olarak
/// açılır, metni olmayan rafta gizlenir. Hiçbiri silinmez ve saklanan durum
/// yeniden yazılmaz — bu yüzden her şey burada, okunurken türetilir.
extension Story {

    /// En az bir sayfasında boşluktan başka bir şey yazıyor mu.
    var hasReadableText: Bool {
        pages.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// Çocuğa gösterilebilir mi: tamamlanmış ya da en azından okunacak metni var.
    var isReadable: Bool { status == .completed || hasReadableText }

    /// Tamamlanmamış ama metni olan masal: metin masalı olarak açılır, hiçbir
    /// çizim beklenmez.
    var opensAsTextOnly: Bool { status != .completed && hasReadableText }
}

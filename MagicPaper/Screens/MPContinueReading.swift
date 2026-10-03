import Foundation

/// "Kaldığın yer" — ana sayfanın en büyük kartına hangi masalın gireceği.
///
/// Eski kural tek satırdı ve iki ayrı şeyi yanlış yapıyordu:
///
/// ```swift
/// myStories.first { $0.mpProgress > 0 && $0.mpProgress < 1 }
/// ```
///
/// **Bir:** `stories` dizisi en yeniden eskiye sıralı (`insert(at: 0)`), yani
/// `first` "en son okunan" değil **"en son yaratılan"** demekti. Dün yaratılıp
/// bir sayfa okunup bırakılmış bir masal, bu akşam okunan iki haftalık masalın
/// önüne geçiyordu. Kart "kaldığın yer" diyordu ama kaldığı yeri değil, en son
/// *yarattığı* şeyi gösteriyordu — kullanıcının gördüğü "yanlış hikâye" buydu.
///
/// **İki:** `mpProgress > 0` bir masalın İLK sayfasını eliyor. Sekiz sayfalık
/// bir masalda `lastReadPage == 0` ilerleme olarak `0` verir (0 / 7), yani
/// açıp ilk sayfasını okuyup bırakan çocuğun masalı hiç açılmamış sayılıyordu.
/// Bu, okuyucu tarafında bir kez düzeltilmiş olan hatanın aynısıydı: bir kitabı
/// açıp ilk sayfasını okumak, o kitabı açmamış olmakla aynı şey değildir.
/// Ölçü artık ilerleme yüzdesi değil, **açılmış olması**.
enum MPContinueReading {

    /// Devam edilecek masal — yoksa `nil`.
    ///
    /// Gelen liste çağıranın işidir (hangi çocuk, onay kapısı); buradaki kural
    /// yalnızca "bunlardan hangisi".
    static func pick(from stories: [Story]) -> Story? {
        candidates(in: stories).first
    }

    /// Sıralanmış adaylar. Testler ve ileride bir "devam edenler" listesi için.
    static func candidates(in stories: [Story]) -> [Story] {
        stories.filter(isResumable).sorted(by: moreRecentlyRead)
    }

    /// Devam edilebilir mi?
    static func isResumable(_ story: Story) -> Bool {
        // Okunacak metni olmayan, takılı kalmış bir masalın "devamı" yok.
        guard story.isReadable else { return false }
        guard !story.pages.isEmpty else { return false }
        // Açılmış olmalı. `lastReadPage == nil` ile "ilerleme 0" aynı şey
        // değil — ilki hiç açılmamış, ikincisi açılmış ve ilk sayfasında.
        guard story.lastReadPage != nil else { return false }
        // Ve bitmemiş olmalı: biten masalın teklifi "tekrar oku"dur, başka bir
        // şeydir, ve bu kartın yeri değildir.
        return !story.isFinished
    }

    /// Hangisi daha yakın zamanda okundu.
    ///
    /// Damgası olan her masal, damgası olmayan her masaldan önce gelir:
    /// `lastReadAt` alanı eklenmeden önce okunan masallarda damga yok ve onlar
    /// için elimizdeki tek şey yaratılma tarihi — yani bir tahmin. Bilinen bir
    /// tarih, tahmin edilen bir tarihi her zaman yener. Damgasızlar kendi
    /// aralarında eski davranışı sürdürür (yeni yaratılan önce), ve çocuk o
    /// masalı bir kez daha açtığında damgasını alıp bu sıradan çıkar.
    private static func moreRecentlyRead(_ a: Story, _ b: Story) -> Bool {
        if let x = a.lastReadAt, let y = b.lastReadAt { return x > y }
        if a.lastReadAt != nil { return true }
        if b.lastReadAt != nil { return false }
        return a.createdAt > b.createdAt
    }
}

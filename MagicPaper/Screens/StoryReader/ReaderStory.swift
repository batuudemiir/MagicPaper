import SwiftUI

/// Okuyucunun gördüğü masal.
///
/// `Story`'nin yerine geçmez ve saklanmaz — okuyucu ekranda dururken yaşayan
/// bir izdüşümdür. Var olma sebebi tek bir satır: `Story.origin`
/// (`Models/Story.swift`) içinde `blueprintID`, `settingID`, `companionID`,
/// `discoveryID`, `fingerprint`, `catalogVersion` vardır. Yani okuyucuya bir
/// `Story` verildiğinde, motorun bütün iç sözlüğü bir property erişimi
/// uzaklıkta durur. Kimse bugün ona bakmıyor; mesele bakabilecek olması.
///
/// Sınır burada çizilir: okuyucuya geçen şey metin, görsel ve sayfa sırasıdır.
struct ReaderStory {
    let id: UUID
    let title: String
    let childName: String
    let accent: Color
    let symbol: String
    /// Masalın dünyası — dekorasyon ortamının ikincil sinyali.
    let world: MP.World
    /// Kapak yaprağı, masalın sayfaları, ve kapanış yaprağı.
    let leaves: [ReaderLeaf]
    /// Kapak varlığının adı; kapak yaprağı yoksa `nil`.
    let coverAsset: String?

    /// Gerçek masal sayfası sayısı — "3 / 8"deki 8.
    /// Kapanış yaprağı sayfa değildir, sayılmaz.
    let pageCount: Int

    var isEmpty: Bool { pageCount == 0 }

    /// Kapak yaprağı varsa sayfalar bir kaydırılmış demektir.
    ///
    /// Sayfa numarası ile yaprak numarası artık aynı şey değil: kitabın kapağı
    /// 1. sayfa değildir. Bu kayma tek yerde söyleniyor ki künye, kayıtlı
    /// ilerleme ve gezinme aynı şeyi anlasın.
    var pageLeafOffset: Int { coverAsset == nil ? 0 : 1 }

    func leafIndex(forPage page: Int) -> Int { page + pageLeafOffset }
}

/// Kitabın bir yaprağı.
///
/// Kapanış bir katman ya da sayfa üstü bir kart değil, gerçek bir yapraktır:
/// son sayfayı çevirerek varılır. Bir kitabın son yaprağı da böyledir. Bunun
/// üç karşılığı var — masalı bitiren hareket masalı anlatan hareketin aynısı
/// olur, "bitti" belirsiz kalmaz, ve okuyucu çocuk hâlâ resme bakarken kendini
/// kapatmaz.
enum ReaderLeaf: Identifiable {
    /// Kitabın kapağı — illüstrasyon, yay biçiminde başlık, marka satırı.
    case cover
    case page(ReaderPage)
    case ending

    var id: String {
        switch self {
        case .cover:       return "cover"
        case .page(let p): return "page-\(p.index)"
        case .ending:      return "ending"
        }
    }

    var page: ReaderPage? {
        if case .page(let p) = self { return p }
        return nil
    }

    var isEnding: Bool {
        if case .ending = self { return true }
        return false
    }

    var isCover: Bool {
        if case .cover = self { return true }
        return false
    }
}

/// Tek bir masal sayfası, dizilmeye hazır.
struct ReaderPage: Equatable {
    /// 0'dan başlayan sayfa sırası — masal sayfaları içinde.
    let index: Int
    /// Genelde boş: çevrimdışı motor sayfa başlığı yazmaz
    /// (`StoryEngineBridge/OfflineStoryMapper.swift`). Boşsa sayfa başlığa yer
    /// ayırmaz, düzen kapanır.
    let title: String
    /// Sayfanın kendi metni, paragraflara ayrılmış hâlde.
    let paragraphs: [String]
    /// Çizimin dosya adı. Yoksa sayfa metin sayfasıdır — ki ürünün bugünkü
    /// yaygın hâli budur, istisnası değil.
    let imageRef: String?
    /// VoiceOver'ın çizim için okuyacağı şey. Görsel yoksa `nil`.
    let imageLabel: String?
    /// Sayfanın sahne yönergesi (motorun `visualScene`'i).
    ///
    /// Ekranda hiç gösterilmez — İngilizce yazılmış, okura ait olmayan bir
    /// metin. Yalnızca sınıflandırılır: sayfa başına ortam sinyali veren tek
    /// şey bu, ve bugüne kadar hiçbir yerde okunmuyordu.
    let sceneHint: String

    /// Sayfanın tamamı, tek parça. VoiceOver sayfayı dört parça hâlinde değil,
    /// sürekli bir metin olarak okusun diye.
    var spokenText: String { paragraphs.joined(separator: "\n\n") }

    var isBlank: Bool { paragraphs.isEmpty && imageRef == nil }
}

// MARK: - Story → ReaderStory

extension ReaderStory {

    init(from story: Story) {
        self.id = story.id
        self.title = story.title
        self.childName = story.childName
        self.accent = story.mpAccent
        self.symbol = story.mpSymbol
        self.world = story.mpWorld

        let pages = story.pages.enumerated().map { index, page in
            ReaderPage(
                index: index,
                title: page.title,
                paragraphs: ReaderStory.paragraphs(of: page.text),
                imageRef: ReaderStory.imageRef(for: page),
                imageLabel: ReaderStory.imageLabel(for: page, in: story, at: index),
                sceneHint: page.imagePrompt
            )
        }

        self.pageCount = pages.count
        // Metin masallarının kendi kapağı yok; ortak illüstrasyon kapak
        // yaprağı olarak kitabın başına konur. Görselli masal kendi kapağını
        // taşıdığı için burada yaprak eklenmez.
        let cover = story.mpDefaultCoverAsset
        self.coverAsset = cover
        self.leaves = (cover == nil ? [] : [ReaderLeaf.cover])
            + pages.map(ReaderLeaf.page)
            + [.ending]
    }

    /// Metni paragraflara böler.
    ///
    /// Motor metni boş satırla ayırıyor ama `lineSpacing` tek başına paragrafı
    /// satırdan ayırt edemez — hepsi aynı aralıkta akar ve diyalog gövdenin
    /// içinde kaybolur. Paragrafları ayrı ayrı dizmek, konuşmayı balonsuz ve
    /// ikinci bir yazı stili olmadan ayıran şeydir (§15).
    static func paragraphs(of text: String) -> [String] {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .split(whereSeparator: \.isEmpty)
            .map { $0.joined(separator: " ") }
    }

    /// Hangi dosya adının yükleneceği.
    ///
    /// `imageFileName` önce denenir. Eski okuyucu tersini yapıyordu
    /// (`imageUrl ?? imageFileName`) ve sonucu *dosya adı* bekleyen bir
    /// yükleyiciye veriyordu: gerçek bir uzak URL taşıyan her sayfa sessizce
    /// görselsiz kalıyordu. Motorun ürettiği masallarda iki alan da aynı
    /// değeri taşıdığı için bu fark bugüne kadar görünmedi.
    static func imageRef(for page: StoryPage) -> String? {
        if let file = page.imageFileName, !file.isEmpty { return file }
        if let url = page.imageUrl, !url.isEmpty { return url }
        return nil
    }

    /// Çizimin sesli karşılığı.
    ///
    /// `imagePrompt` burada kullanılmaz ve bu kasıtlıdır. Alan, motorun
    /// `visualScene`'ini taşır ve İngilizce yazılmış sahne yönergesidir —
    /// "child pausing mid-step at the edge of the place". Alt metin gibi
    /// görünür, alt metin değildir: VoiceOver'a verilseydi Türkçe bir masalın
    /// ortasında İngilizce sahne notu okunurdu.
    ///
    /// Görsel yoksa etiket de yok. Metin sayfasında tarif edilecek bir şey
    /// yoktur; uydurulan her cümle gürültüdür.
    static func imageLabel(for page: StoryPage, in story: Story, at index: Int) -> String? {
        guard imageRef(for: page) != nil else { return nil }
        let name = story.title.isEmpty ? "Masal" : story.title
        return "\(name), sayfa \(index + 1) çizimi"
    }
}

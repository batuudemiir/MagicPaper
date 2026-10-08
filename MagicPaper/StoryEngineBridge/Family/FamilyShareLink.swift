import Foundation

/// Aileyle paylaş (FAZ 18, 36): süreli, salt okuma bağlantısı.
///
/// Bağlantı belgesi `shares/{token}` herkese açıktır (bağlantıyı bilen,
/// süresi dolana kadar okur) ve yalnızca çocuğun adını ve masal metnini taşır;
/// kurallar başka bir alanı reddeder. Kime gönderildiği ("Ayşe Nine") ailenin
/// özel listesinde, `families/{fid}/shares/{token}`.
enum FamilyShareLink {
    static let durations = [1, 7, 30]
    static let defaultDays = 7

    static func url(_ token: String) -> URL {
        URL(string: "https://magicpaper-393a7.web.app/s/\(token)")!
    }

    /// 128 bit, URL'de güvenli base64 (22 karakter).
    static func makeToken<G: RandomNumberGenerator>(using generator: inout G) -> String {
        let bytes = (0..<16).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func makeToken() -> String {
        var generator = SystemRandomNumberGenerator()
        return makeToken(using: &generator)
    }

    static func message(childName: String, url: URL) -> String {
        "\(childName) için yazılan masallar: \(url.absoluteString)"
    }
}

/// Bağlantıda ne var: yalnızca ad ve metin (+ sesli sayfaların dizini).
struct ShareDocument: Equatable, Sendable {
    struct SharedStory: Equatable, Sendable {
        let title: String
        let pages: [String]
        /// Ailenin sesiyle kaydı paylaşılan sayfaların dizinleri.
        let audio: [Int]
    }

    let familyID: String
    let childName: String
    let stories: [SharedStory]
    let voice: Bool
    let expiresAt: Date

    init(familyID: String, childName: String, stories: [Story], voice: Bool, expiresAt: Date,
         recordedPages: (UUID) -> [Int] = { _ in [] }) {
        self.familyID = familyID
        self.childName = String(childName.prefix(40))
        self.stories = stories.prefix(20).map { story in
            let pages = story.pages.prefix(60).map(\.text)
            let audio = voice ? recordedPages(story.id).filter { $0 < pages.count } : []
            return SharedStory(title: String(story.title.prefix(200)), pages: pages, audio: audio)
        }
        self.voice = voice && self.stories.contains { !$0.audio.isEmpty }
        self.expiresAt = expiresAt
    }

    /// Sunucuya giden alanlar (sunucu saati `createdAt`'ı uzak taraf ekler).
    var fields: [String: Any] {
        [
            "familyID": familyID,
            "childName": childName,
            "stories": stories.map { ["title": $0.title, "pages": $0.pages, "audio": $0.audio] as [String: Any] },
            "voice": voice,
        ]
    }

    /// Storage'daki ses kopyaları: `shares/{token}/{story}/{page}.m4a`.
    var audioKeys: [String] {
        stories.enumerated().flatMap { index, story in story.audio.map { "\(index)/\($0)" } }
    }
}

/// Ailenin paylaştıkları (36 · "Daha önce paylaştıkların").
struct ShareRecord: Identifiable, Equatable, Sendable {
    let token: String
    let recipient: String?
    let storyCount: Int
    let voice: Bool
    let expiresAt: Date
    let audio: [String]
    var id: String { token }

    func isActive(at now: Date = Date()) -> Bool { expiresAt > now }
}

protocol ShareRemote: Sendable {
    /// Açık belgeyi yazar, sesleri kopyalar, ailenin listesine ekler.
    func create(token: String, document: ShareDocument, recipient: String?, audioFiles: [String: URL], createdBy: String) async throws
    func list(familyID: String) async throws -> [ShareRecord]
    /// Bağlantıyı kapatır: sesler, açık belge, liste satırı.
    func revoke(_ record: ShareRecord, familyID: String) async throws
}

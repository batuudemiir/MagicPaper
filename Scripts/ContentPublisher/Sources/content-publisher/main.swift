import Foundation
import PublisherKit

let usage = """
content-publisher — MagicPaper uzaktan içerik yayını (FAZ 15)

  keygen                 İmza anahtarı üretir (~/.magicpaper/content-signing.key), açık anahtarı yazar.
  public-key             Mevcut anahtarın açık yarısını yazar (Info.plist MPContentSigningKey).
  build-package          Doğrulayıcı + motor denetimi; hosting/public/content/catalog/<sürüm>.json yazar.
  publish                Content/DailyFeed/stories'ten feed.json + feed.json.sig yazar.
      --package keep|latest|none|<sürüm>   (varsayılan keep: önceki akışın paketi)
      --date yyyy-MM-dd                    (varsayılan bugün)
      --deploy                             Yazdıktan sonra `firebase deploy --only hosting`.
      --first                              Yalnız ilk yayında: önceki feed.json yokken.
  fallback               Uygulamanın yedek masal dosyasını stories'ten yeniden yazar.
  verify --public-key K  Yazılmış akışın imzasını ve paket özetini denetler.

Ortak: --repo <yol>   --key <yol>
"""

var arguments = Array(CommandLine.arguments.dropFirst())
func option(_ name: String) -> String? {
    guard let index = arguments.firstIndex(of: name), index + 1 < arguments.count else { return nil }
    let value = arguments[index + 1]
    arguments.removeSubrange(index...(index + 1))
    return value
}
func flag(_ name: String) -> Bool {
    guard let index = arguments.firstIndex(of: name) else { return false }
    arguments.remove(at: index)
    return true
}

func today() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
}

do {
    guard let command = arguments.first else { print(usage); exit(0) }
    arguments.removeFirst()
    let keyPath = option("--key").map { URL(fileURLWithPath: $0) } ?? Signer.defaultKeyPath
    let repo = try option("--repo").map { Repo(root: URL(fileURLWithPath: $0)) }
        ?? Repo.find(from: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
    let publisher = Publisher(repo: repo)

    switch command {
    case "keygen":
        let signer = try Signer.generate(at: keyPath)
        print("Anahtar yazıldı: \(keyPath.path) (yalnız sizin okuyabileceğiniz izinle; repoya koymayın, yedekleyin).")
        print("Info.plist MPContentSigningKey:\n\(signer.publicKeyBase64)")
    case "public-key":
        print(try Signer(contentsOf: keyPath).publicKeyBase64)
    case "build-package":
        try publisher.buildPackage()
    case "publish":
        let choice: Publisher.PackageChoice
        switch option("--package") ?? "keep" {
        case "keep": choice = .keep
        case "latest": choice = .latest
        case "none": choice = .none
        case let version: choice = .version(version)
        }
        let date = option("--date") ?? today()
        let deploy = flag("--deploy")
        let first = flag("--first")
        try publisher.publishFeed(signer: try Signer(contentsOf: keyPath), package: choice, today: date, first: first)
        if deploy { try publisher.deploy() }
    case "fallback":
        try publisher.writeFallback()
    case "verify":
        guard let key = option("--public-key") else { throw PublishError.message("--public-key gerekli") }
        let feed = try Data(contentsOf: repo.feed)
        let signature = try Data(contentsOf: repo.signature)
        guard Signer.verify(signature, for: feed, publicKey: key) else { throw PublishError.message("İmza GEÇERSİZ.") }
        let decoded = try JSONDecoder().decode(FeedFile.self, from: feed)
        if let package = decoded.catalogPackage {
            let data = try Data(contentsOf: repo.content.appendingPathComponent(package.path))
            guard Digest.sha256(data) == package.sha256 else { throw PublishError.message("Paket özeti uyuşmuyor.") }
        }
        print("Akış \(decoded.feedVersion): imza geçerli, \(decoded.stories.count) masal, paket \(decoded.catalogPackage?.version ?? "yok").")
    default:
        print(usage)
        exit(2)
    }
} catch {
    FileHandle.standardError.write(Data("HATA: \(error)\n".utf8))
    exit(1)
}

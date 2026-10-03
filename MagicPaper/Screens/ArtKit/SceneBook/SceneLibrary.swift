import Foundation

/// Görselli masalın hazır sahneleri (B2).
///
/// Sahneler geliştirme zamanında bir kez çizilir ve uygulamaya gömülür; çalışma
/// anında yalnızca katmanlar üst üste konur. Masal başına üretim yok, ağ yok.
///
/// `art_kits.json`'dan ayrı bir manifest, çünkü ikisi farklı şeyler: sanat seti
/// bir masal ailesine bağlı rollü slotlardır (hero, cover, spot); sahne ise
/// sayfa başına seçilen, anchor taşıyan, skorlanan bir kayıttır (plan §3.1).
///
/// Yalnızca Foundation: seçici (`SceneSelector`) bu tipi okur ve SwiftUI'ye
/// bağlı olmamalı.
struct SceneLibrary: Decodable, Equatable {
    let schemaVersion: Int
    let version: String
    let canvas: Canvas
    /// Yaş bandı → görsel yuvaları. Her yuva bir rol listesidir; yuva, masalda
    /// bulunan ilk role verilir. `"default"` anahtarı her bandı karşılar.
    let illustratedPages: [String: [[String]]]
    /// Eylem sözleşmesi: beat → poz (plan §3.2.1).
    let direction: Direction
    let cooldown: Cooldown
    let scenes: [Scene]

    struct Canvas: Decodable, Equatable {
        /// `"4:3"`. Sözleşme testi her sürümün bu oranda olduğunu denetler.
        let aspect: String
        let minWidth: Int
        let minHeight: Int

        var aspectRatio: Double {
            let parts = aspect.split(separator: ":").compactMap { Double($0) }
            guard parts.count == 2, parts[1] > 0 else { return 4.0 / 3.0 }
            return parts[0] / parts[1]
        }
    }

    struct Direction: Decodable, Equatable {
        let beatPoses: [String: String]
        let rolePoses: [String: String]
        let fallbackPose: String
    }

    struct Cooldown: Decodable, Equatable {
        /// Son kaç masalın sahneleri cezalanır.
        let window: Int
        /// En yeni masaldaki sahnenin cezası; pencerenin sonuna doğru doğrusal azalır.
        let penalty: Double
    }

    struct Scene: Decodable, Equatable, Identifiable {
        let id: String
        /// Daha özel eşleşme. MVP sahneleri bununla yazılır: `garden` tag'i hem
        /// Gece Bahçesi'ni hem Yaşlı Meyve Bahçesi'ni karşılıyor (plan §1.4).
        let settingIDs: [String]
        /// İçerik kütüphanesindeki tag sözlüğü.
        let settingTags: [String]
        let modes: [String]
        let roles: [String]
        /// Boşsa sahne yalnızca rol düzeyinde eşleşir.
        let beats: [String]
        let emotions: [String]
        let timeOfDay: String?
        /// Bu kompozisyonda çocuğun alabileceği pozlar.
        let allowedPoses: [String]
        let defaultPose: String
        /// VoiceOver için Türkçe kısa tarif. `visualScene` İngilizce olduğu
        /// için kullanılamaz (`ReaderStory.imageLabel`).
        let altTextTR: String
        let weight: Double
        let versions: [Version]

        /// Yeni bir kitaba verilebilecek sürüm: en yüksek numaralı onaylı sürüm.
        var latestApproved: Version? {
            versions.filter { $0.lifecycle == ContentLifecycle.approved }
                    .max { $0.version < $1.version }
        }

        /// Kayıtlı bir kitabın çizileceği sürüm (plan §4.2).
        ///
        /// Kitap kendi sürümüyle açılır — iki bilinçli istisna dışında:
        /// yer tutucu sürüm sabitlenmez (gerçek sanat gelince kitap yükselir),
        /// emekliye ayrılmış ya da artık bulunmayan sürüm en yeni onaylı sürüme
        /// düşer. Hiç onaylı sürüm yoksa `nil`: sayfa metin sayfası çizilir.
        func renderable(pinned: Int) -> Version? {
            if let exact = versions.first(where: { $0.version == pinned }),
               !exact.placeholder,
               exact.lifecycle == ContentLifecycle.approved
                || exact.lifecycle == ContentLifecycle.deprecated {
                return exact
            }
            return latestApproved
        }
    }

    struct Version: Decodable, Equatable {
        let version: Int
        let lifecycle: String
        /// Yer tutucu sanat: kod çizer, gerçek varlık gelince aynı ID'nin yeni
        /// sürümüyle değiştirilir.
        let placeholder: Bool
        /// İçerik güvenliği onayı (plan §9.1). Gerçek bir varlık bunlarsız
        /// onaylı sayılmaz; `SceneLibraryTests` denetler.
        let approvedBy: String?
        let approvedAt: String?
        /// Arkadan öne. `avatar` ve `companion` rollerinin yeri derinliği belirler.
        let layers: [Layer]
        let characterAnchor: Anchor
        /// Yol arkadaşının yeri. Yoksa sahne onsuz da geçerlidir.
        let companionAnchor: Anchor?
        /// Sessiz bant, kadraj kesri. Bugün okuyucuda kullanılmıyor.
        let quietBand: Band?
        /// Yer tutucu çizimin ipuçları: ufuk ve ayak çizgisi, motifler.
        let placeholderArt: PlaceholderArt?
    }

    struct Layer: Decodable, Equatable {
        /// `background`, `midground`, `props`, `avatar`, `companion`,
        /// `foreground`, `lighting`.
        let role: String
        /// Varlık kataloğundaki ad (`Scenes/...`). `avatar` ve `companion`
        /// rollerinde yok.
        let asset: String?
        let optional: Bool?
        /// `lighting` için karışım modu (`multiply`).
        let blend: String?
    }

    /// Kadraj kesri, sol üstten. Piksel asla saklanmaz.
    struct Anchor: Decodable, Equatable {
        /// Ayak noktası.
        let x: Double
        let y: Double
        /// Figürün yüksekliği, kadraj yüksekliğine oranla.
        let scale: Double
        /// `left` | `right`. Varlık sağa bakar; `left` aynalanır.
        let facing: String
        /// Yalnızca yol arkadaşı için.
        let pose: String?
    }

    struct Band: Decodable, Equatable {
        let x: Double, y: Double, width: Double, height: Double
    }

    struct PlaceholderArt: Decodable, Equatable {
        /// Ufuk çizgisi, kadraj kesri.
        let horizon: Double
        /// Zemin tonu (`forest`, `meadow`, `garden` …) — yer tutucu çizimin
        /// paletini seçer.
        let tone: String
        /// Onaylı `Storybook/` süs varlıkları.
        let motifs: [String]
    }

    // MARK: - Sorgular

    func scene(_ id: String) -> Scene? { scenes.first { $0.id == id } }

    /// Bir yaş bandının görsel yuvaları.
    func slots(forAgeBand band: String?) -> [[String]] {
        if let band, let slots = illustratedPages[band] { return slots }
        return illustratedPages["default"] ?? []
    }
}

/// Kanonik katman rolleri.
enum SceneLayerRole {
    static let background = "background"
    static let midground = "midground"
    static let props = "props"
    static let avatar = "avatar"
    static let companion = "companion"
    static let foreground = "foreground"
    static let lighting = "lighting"

    static let all: Set<String> = [background, midground, props, avatar, companion, foreground, lighting]
}

// MARK: - Katalog

extension SceneLibrary {
    /// Gömülü kütüphane. Okunamazsa `nil`: görselli kitap kurulmaz, masal metin
    /// olarak çıkar — sessizce yanlış bir sete düşülmez.
    static let bundled: SceneLibrary? = load(from: .main)

    static func load(from bundle: Bundle) -> SceneLibrary? {
        guard let url = bundle.url(forResource: "scene_library", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SceneLibrary.self, from: data)
    }
}

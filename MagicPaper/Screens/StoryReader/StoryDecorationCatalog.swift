import SwiftUI

/// Tek bir dekoratif varlık.
///
/// Çizim değil, *tarif*: hangi görsel, nereye ait, ne kadar ağır. Çizimi
/// `Tools/make_decorations.py` yapıyor ve PNG olarak duruyor (§34).
struct StoryDecorationAsset: Identifiable, Hashable {
    let id: String
    /// Asset katalogundaki ad.
    let imageName: String
    let category: DecorationCategory
    let motifZone: MotifZone
    /// Hangi ortamlara uygun. Boşsa yalnızca kategorisiyle eşleşir.
    let environments: Set<StoryEnvironment>
    let moods: Set<StoryMood>
    /// 0…1 — sayfadaki görsel ağırlık. Yoğunluk bütçesi bununla harcanır,
    /// adetle değil: üç ağır motif, altı hafif motiften daha kalabalıktır.
    let visualWeight: Double
}

/// Bir varlığın kürasyon durumu.
enum DecorationStatus: String, CaseIterable, Identifiable {
    case approved, reviewRequired, rejected
    var id: String { rawValue }

    var label: String {
        switch self {
        case .approved:       return "Onaylı"
        case .reviewRequired: return "İncelemede"
        case .rejected:       return "Elenen"
        }
    }
}

/// Katalogdaki bir kayıt — üretime girmeyenler dâhil.
///
/// `StoryDecorationAsset` yalnızca üretime giren varlığı tarif eder; bu ise
/// *kürasyonun* kaydı. Elenen bir varlığın neden elendiği galeride görünmeli:
/// eksikliği gizlemek, sessizce yanlış dekorasyona yol açar.
struct StoryDecorationCatalogEntry: Identifiable, Hashable {
    let id: String
    /// Yalnızca onaylı varlıklar uygulamaya kopyalanır; ötekiler `nil`.
    let imageName: String?
    let category: DecorationCategory
    let motifZone: MotifZone
    let environments: Set<StoryEnvironment>
    let status: DecorationStatus
    let license: String
    /// Elenme gerekçesi ya da not.
    let note: String
}

/// Onaylı varlıkların dizini.
///
/// İçerik `StoryDecorationCatalog+Generated.swift` içinde ve elle yazılmıyor;
/// `AssetCatalog/assets.json`'dan üretiliyor. Elenen ve incelemede olan
/// varlıklar katalogda kalır ama buraya geçmez.
enum StoryDecorationCatalog {

    static var all: [StoryDecorationAsset] { generated }

    static func asset(id: String) -> StoryDecorationAsset? {
        generated.first { $0.id == id }
    }

    static func assets(category: DecorationCategory) -> [StoryDecorationAsset] {
        generated.filter { $0.category == category }
    }

    /// Hangi kategorilerde hiç onaylı varlık yok.
    ///
    /// Galeride ve raporda görünür olması bilinçli: eksik kategoriyi generic
    /// ikonla doldurmak §35'in yasakladığı şey, ama eksikliği gizlemek de
    /// sessizce yanlış dekorasyona yol açar.
    static var emptyCategories: [DecorationCategory] {
        DecorationCategory.allCases.filter { assets(category: $0).isEmpty }
    }

    /// Ortam başına onaylı varlık sayısı.
    ///
    /// Yoğunluk hedefi sayfa başına 4–7; bunu besleyebilmek için ortam başına
    /// en az ~6 varlık gerekiyor. Galeride görünür olması bilinçli: sistemin
    /// darboğazı motor değil, kütüphanenin inceliği.
    static func approvedCount(for environment: StoryEnvironment) -> Int {
        generated.filter { $0.environments.contains(environment) }.count
    }
}

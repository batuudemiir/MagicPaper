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
    let type: DecorationType
    /// Hangi ortamlara uygun. Boşsa yalnızca kategorisiyle eşleşir.
    let environments: Set<StoryEnvironment>
    let moods: Set<StoryMood>
    let preferredZones: Set<DecorationZone>
    /// 0…1 — sayfadaki görsel ağırlık. Yoğunluk bütçesi bununla harcanır,
    /// adetle değil: üç ağır motif, altı hafif motiften daha kalabalıktır.
    let visualWeight: Double
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
}

// ÜRETİLMİŞ DOSYA — elle düzenlemeyin.
// Kaynak: AssetCatalog/assets.json · Üretici: Tools/sync_decorations.py
//
// Yalnızca `status: approved` varlıklar buraya girer. Elenen ve incelemede
// olanlar katalogda kalır ama uygulamaya geçmez.

import Foundation

extension StoryDecorationCatalog {

    /// Üretime onaylanmış dekorasyonlar.
    static let generated: [StoryDecorationAsset] = [
        StoryDecorationAsset(
            id: "adventure_feather_01",
            imageName: "Storybook/adventure_feather_01",
            category: .adventure,
            type: .floating,
            environments: [.adventure, .sky],
            moods: [.calm, .adventurous],
            preferredZones: [.topTrailing, .leadingEdge, .trailingEdge, .bottomTrailing],
            visualWeight: 0.55
        ),
        StoryDecorationAsset(
            id: "bedtime_moon_01",
            imageName: "Storybook/bedtime_moon_01",
            category: .bedtime,
            type: .sky,
            environments: [.bedtime, .space, .magic],
            moods: [.dreamy, .calm],
            preferredZones: [.topLeading, .topTrailing, .topCenter],
            visualWeight: 0.65
        ),
        StoryDecorationAsset(
            id: "forest_branch_corner_01",
            imageName: "Storybook/forest_branch_corner_01",
            category: .forest,
            type: .corner,
            environments: [.forest, .garden],
            moods: [.calm, .magical],
            preferredZones: [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing],
            visualWeight: 0.85
        ),
        StoryDecorationAsset(
            id: "forest_grass_cluster_01",
            imageName: "Storybook/forest_grass_cluster_01",
            category: .forest,
            type: .ground,
            environments: [.forest, .garden, .adventure],
            moods: [.calm, .happy],
            preferredZones: [.bottomLeading, .bottomTrailing, .bottomCenter],
            visualWeight: 0.7
        ),
        StoryDecorationAsset(
            id: "forest_leaf_cluster_01",
            imageName: "Storybook/forest_leaf_cluster_01",
            category: .forest,
            type: .floating,
            environments: [.forest, .garden],
            moods: [.calm, .dreamy],
            preferredZones: [.topTrailing, .leadingEdge, .trailingEdge, .bottomTrailing],
            visualWeight: 0.55
        ),
        StoryDecorationAsset(
            id: "forest_mushroom_pair_01",
            imageName: "Storybook/forest_mushroom_pair_01",
            category: .forest,
            type: .ground,
            environments: [.forest],
            moods: [.magical, .calm],
            preferredZones: [.bottomLeading, .bottomTrailing, .bottomCenter],
            visualWeight: 0.75
        ),
        StoryDecorationAsset(
            id: "garden_butterfly_01",
            imageName: "Storybook/garden_butterfly_01",
            category: .garden,
            type: .floating,
            environments: [.garden, .forest, .magic],
            moods: [.happy, .magical],
            preferredZones: [.topTrailing, .leadingEdge, .trailingEdge, .bottomTrailing],
            visualWeight: 0.5
        ),
        StoryDecorationAsset(
            id: "garden_flower_cluster_01",
            imageName: "Storybook/garden_flower_cluster_01",
            category: .garden,
            type: .ground,
            environments: [.garden, .forest],
            moods: [.happy, .calm],
            preferredZones: [.bottomLeading, .bottomTrailing, .bottomCenter],
            visualWeight: 0.8
        ),
        StoryDecorationAsset(
            id: "garden_vine_edge_01",
            imageName: "Storybook/garden_vine_edge_01",
            category: .garden,
            type: .edge,
            environments: [.garden, .forest],
            moods: [.calm, .magical],
            preferredZones: [.leadingEdge, .trailingEdge],
            visualWeight: 0.8
        ),
        StoryDecorationAsset(
            id: "ocean_seaweed_01",
            imageName: "Storybook/ocean_seaweed_01",
            category: .ocean,
            type: .edge,
            environments: [.ocean],
            moods: [.calm, .mysterious],
            preferredZones: [.leadingEdge, .trailingEdge],
            visualWeight: 0.7
        ),
        StoryDecorationAsset(
            id: "ocean_wave_mark_01",
            imageName: "Storybook/ocean_wave_mark_01",
            category: .ocean,
            type: .accent,
            environments: [.ocean],
            moods: [.calm],
            preferredZones: [.bottomCenter, .topCenter],
            visualWeight: 0.45
        ),
        StoryDecorationAsset(
            id: "sky_birds_trio_01",
            imageName: "Storybook/sky_birds_trio_01",
            category: .sky,
            type: .sky,
            environments: [.sky, .adventure, .forest],
            moods: [.calm, .happy],
            preferredZones: [.topLeading, .topTrailing, .topCenter],
            visualWeight: 0.4
        ),
    ]
}

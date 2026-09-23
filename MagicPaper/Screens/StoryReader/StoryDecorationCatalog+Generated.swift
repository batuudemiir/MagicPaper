// ÜRETİLMİŞ DOSYA — elle düzenlemeyin.
// Prototype Mock for MagicPaper V1 Decoration Concept

import Foundation

extension StoryDecorationCatalog {

    /// Üretime onaylanmış dekorasyonlar (Prototip).
    static let generated: [StoryDecorationAsset] = [
        // 1. Enchanted Forest
        StoryDecorationAsset(
            id: "forest_foreground_cluster_01",
            imageName: "Storybook/forest_grass_cluster_01", // Reusing existing image as placeholder
            category: .forest,
            motifZone: .foregroundBottom,
            environments: [.forest, .magic, .garden],
            moods: [.calm, .magical],
            visualWeight: 0.9
        ),
        StoryDecorationAsset(
            id: "forest_branch_corner_01",
            imageName: "Storybook/forest_branch_corner_01",
            category: .forest,
            motifZone: .atmosphericTop,
            environments: [.forest, .magic],
            moods: [.calm, .magical],
            visualWeight: 0.85
        ),

        // 2. Magical Ocean
        StoryDecorationAsset(
            id: "ocean_kelp_bottom_01",
            imageName: "Storybook/ocean_kelp_edge_01",
            category: .ocean,
            motifZone: .foregroundBottom,
            environments: [.ocean],
            moods: [.calm, .mysterious],
            visualWeight: 0.8
        ),
        StoryDecorationAsset(
            id: "ocean_bubbles_particles_01",
            imageName: "Storybook/ocean_fish_pair_01", // Placeholder
            category: .ocean,
            motifZone: .backgroundParticles,
            environments: [.ocean],
            moods: [.calm, .mysterious],
            visualWeight: 0.4
        ),

        // 3. Bedtime Sky
        StoryDecorationAsset(
            id: "bedtime_moon_clouds_01",
            imageName: "Storybook/bedtime_moon_01",
            category: .bedtime,
            motifZone: .atmosphericTop,
            environments: [.bedtime, .space],
            moods: [.dreamy, .calm],
            visualWeight: 0.7
        ),
        StoryDecorationAsset(
            id: "bedtime_stars_01",
            imageName: "Storybook/sky_cloud_wisp_01", // Placeholder
            category: .bedtime,
            motifZone: .backgroundParticles,
            environments: [.bedtime, .space],
            moods: [.dreamy, .calm],
            visualWeight: 0.3
        ),

        // 4. Adventure Mountain
        StoryDecorationAsset(
            id: "adventure_rock_frame_01",
            imageName: "Storybook/adventure_fern_01", // Placeholder
            category: .adventure,
            motifZone: .asymmetricalFrame,
            environments: [.adventure],
            moods: [.adventurous, .calm],
            visualWeight: 0.9
        ),
        StoryDecorationAsset(
            id: "adventure_sky_birds_01",
            imageName: "Storybook/sky_birds_trio_01",
            category: .adventure,
            motifZone: .atmosphericTop,
            environments: [.adventure, .sky],
            moods: [.adventurous, .happy],
            visualWeight: 0.5
        )
    ]

    static let catalogEntries: [StoryDecorationCatalogEntry] = []
}

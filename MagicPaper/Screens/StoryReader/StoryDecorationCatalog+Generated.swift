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
            id: "adventure_fern_01",
            imageName: "Storybook/adventure_fern_01",
            category: .adventure,
            type: .edge,
            environments: [.adventure, .forest],
            moods: [.calm, .adventurous],
            preferredZones: [.leadingEdge, .trailingEdge],
            visualWeight: 0.7
        ),
        StoryDecorationAsset(
            id: "adventure_pennant_01",
            imageName: "Storybook/adventure_pennant_01",
            category: .adventure,
            type: .ground,
            environments: [.adventure],
            moods: [.happy, .adventurous],
            preferredZones: [.bottomLeading, .bottomTrailing, .bottomCenter],
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
            id: "bedtime_night_hills_01",
            imageName: "Storybook/bedtime_night_hills_01",
            category: .bedtime,
            type: .background,
            environments: [.bedtime, .adventure],
            moods: [.dreamy, .calm],
            preferredZones: [.bottomCenter],
            visualWeight: 0.4
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
            id: "forest_fallen_leaves_01",
            imageName: "Storybook/forest_fallen_leaves_01",
            category: .forest,
            type: .ground,
            environments: [.forest, .garden],
            moods: [.calm, .dreamy],
            preferredZones: [.bottomLeading, .bottomTrailing, .bottomCenter],
            visualWeight: 0.5
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
            id: "magic_swirl_01",
            imageName: "Storybook/magic_swirl_01",
            category: .magic,
            type: .floating,
            environments: [.magic, .bedtime],
            moods: [.magical, .dreamy],
            preferredZones: [.topTrailing, .leadingEdge, .trailingEdge, .bottomTrailing],
            visualWeight: 0.55
        ),
        StoryDecorationAsset(
            id: "magic_wisp_trail_01",
            imageName: "Storybook/magic_wisp_trail_01",
            category: .magic,
            type: .accent,
            environments: [.magic, .sky],
            moods: [.magical, .dreamy],
            preferredZones: [.bottomCenter, .topCenter],
            visualWeight: 0.45
        ),
        StoryDecorationAsset(
            id: "ocean_fish_pair_01",
            imageName: "Storybook/ocean_fish_pair_01",
            category: .ocean,
            type: .floating,
            environments: [.ocean],
            moods: [.happy, .calm],
            preferredZones: [.topTrailing, .leadingEdge, .trailingEdge, .bottomTrailing],
            visualWeight: 0.45
        ),
        StoryDecorationAsset(
            id: "ocean_kelp_edge_01",
            imageName: "Storybook/ocean_kelp_edge_01",
            category: .ocean,
            type: .edge,
            environments: [.ocean],
            moods: [.calm, .mysterious],
            preferredZones: [.leadingEdge, .trailingEdge],
            visualWeight: 0.75
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
        StoryDecorationAsset(
            id: "sky_cloud_wisp_01",
            imageName: "Storybook/sky_cloud_wisp_01",
            category: .sky,
            type: .sky,
            environments: [.sky, .adventure, .bedtime],
            moods: [.calm, .dreamy],
            preferredZones: [.topLeading, .topTrailing, .topCenter],
            visualWeight: 0.35
        ),
        StoryDecorationAsset(
            id: "sky_sun_rays_01",
            imageName: "Storybook/sky_sun_rays_01",
            category: .sky,
            type: .corner,
            environments: [.sky, .adventure, .garden],
            moods: [.happy, .calm],
            preferredZones: [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing],
            visualWeight: 0.5
        ),
        StoryDecorationAsset(
            id: "space_moon_arc_01",
            imageName: "Storybook/space_moon_arc_01",
            category: .space,
            type: .sky,
            environments: [.space, .bedtime, .magic],
            moods: [.dreamy, .mysterious],
            preferredZones: [.topLeading, .topTrailing, .topCenter],
            visualWeight: 0.6
        ),
        StoryDecorationAsset(
            id: "space_orbit_arcs_01",
            imageName: "Storybook/space_orbit_arcs_01",
            category: .space,
            type: .sky,
            environments: [.space],
            moods: [.adventurous, .mysterious],
            preferredZones: [.topLeading, .topTrailing, .topCenter],
            visualWeight: 0.55
        ),
    ]

    /// Bütün katalog — kürasyon ekranı için. Üretim yalnızca `generated`.
    static let catalogEntries: [StoryDecorationCatalogEntry] = [
        StoryDecorationCatalogEntry(
            id: "adventure_feather_01",
            imageName: "Storybook/adventure_feather_01",
            category: .adventure,
            type: .floating,
            environments: [.adventure, .sky],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "adventure_fern_01",
            imageName: "Storybook/adventure_fern_01",
            category: .adventure,
            type: .edge,
            environments: [.adventure, .forest],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "adventure_hill_01",
            imageName: nil,
            category: .adventure,
            type: .background,
            environments: [.adventure],
            status: .reviewRequired,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "adventure_pennant_01",
            imageName: "Storybook/adventure_pennant_01",
            category: .adventure,
            type: .ground,
            environments: [.adventure],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "adventure_rope_01",
            imageName: nil,
            category: .adventure,
            type: .accent,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Düğüm çentikleri bacak gibi okunuyor; halat değil kırkayak."
        ),
        StoryDecorationCatalogEntry(
            id: "adventure_stones_01",
            imageName: nil,
            category: .adventure,
            type: .ground,
            environments: [.adventure, .ocean],
            status: .reviewRequired,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "bedtime_moon_01",
            imageName: "Storybook/bedtime_moon_01",
            category: .bedtime,
            type: .sky,
            environments: [.bedtime, .space, .magic],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "bedtime_moon_wisp_01",
            imageName: nil,
            category: .bedtime,
            type: .sky,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Hilal sağdan kırpılmış, bulut çizgileri hilalle çakışıyor."
        ),
        StoryDecorationCatalogEntry(
            id: "bedtime_night_hills_01",
            imageName: "Storybook/bedtime_night_hills_01",
            category: .bedtime,
            type: .background,
            environments: [.bedtime, .adventure],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "bedtime_sleepy_cloud_01",
            imageName: nil,
            category: .bedtime,
            type: .sky,
            environments: [.bedtime],
            status: .reviewRequired,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "bedtime_star_pair_01",
            imageName: nil,
            category: .bedtime,
            type: .sky,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Aynı: yıldızlar generic vector icon."
        ),
        StoryDecorationCatalogEntry(
            id: "forest_branch_corner_01",
            imageName: "Storybook/forest_branch_corner_01",
            category: .forest,
            type: .corner,
            environments: [.forest, .garden],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "forest_fallen_leaves_01",
            imageName: "Storybook/forest_fallen_leaves_01",
            category: .forest,
            type: .ground,
            environments: [.forest, .garden],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "forest_grass_cluster_01",
            imageName: "Storybook/forest_grass_cluster_01",
            category: .forest,
            type: .ground,
            environments: [.forest, .garden, .adventure],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "forest_leaf_cluster_01",
            imageName: "Storybook/forest_leaf_cluster_01",
            category: .forest,
            type: .floating,
            environments: [.forest, .garden],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "forest_mushroom_pair_01",
            imageName: "Storybook/forest_mushroom_pair_01",
            category: .forest,
            type: .ground,
            environments: [.forest],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "garden_butterfly_01",
            imageName: "Storybook/garden_butterfly_01",
            category: .garden,
            type: .floating,
            environments: [.garden, .forest, .magic],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "garden_flower_cluster_01",
            imageName: "Storybook/garden_flower_cluster_01",
            category: .garden,
            type: .ground,
            environments: [.garden, .forest],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "garden_vine_edge_01",
            imageName: "Storybook/garden_vine_edge_01",
            category: .garden,
            type: .edge,
            environments: [.garden, .forest],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "magic_firefly_01",
            imageName: nil,
            category: .magic,
            type: .particle,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Neredeyse görünmüyor; kâğıt üstünde boş daire."
        ),
        StoryDecorationCatalogEntry(
            id: "magic_glow_grass_01",
            imageName: nil,
            category: .magic,
            type: .ground,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Uçtaki ışık top gibi kalıyor; kibrit çöpü/lolipop."
        ),
        StoryDecorationCatalogEntry(
            id: "magic_particle_trail_01",
            imageName: nil,
            category: .magic,
            type: .particle,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Boncuk dizisi gibi okunuyor, mekanik."
        ),
        StoryDecorationCatalogEntry(
            id: "magic_sparkle_cluster_01",
            imageName: nil,
            category: .magic,
            type: .particle,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "4 uçlu yıldızlar UI parıltı ikonu hâline geliyor (§4 yasaklıyor)."
        ),
        StoryDecorationCatalogEntry(
            id: "magic_swirl_01",
            imageName: "Storybook/magic_swirl_01",
            category: .magic,
            type: .floating,
            environments: [.magic, .bedtime],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "magic_wisp_trail_01",
            imageName: "Storybook/magic_wisp_trail_01",
            category: .magic,
            type: .accent,
            environments: [.magic, .sky],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "ocean_bubbles_01",
            imageName: nil,
            category: .ocean,
            type: .floating,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Düz daireler; UI öğesi gibi."
        ),
        StoryDecorationCatalogEntry(
            id: "ocean_coral_01",
            imageName: nil,
            category: .ocean,
            type: .ground,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Çıplak kış ağacı gibi okunuyor; mercan olmuyor."
        ),
        StoryDecorationCatalogEntry(
            id: "ocean_fish_pair_01",
            imageName: "Storybook/ocean_fish_pair_01",
            category: .ocean,
            type: .floating,
            environments: [.ocean],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "ocean_kelp_edge_01",
            imageName: "Storybook/ocean_kelp_edge_01",
            category: .ocean,
            type: .edge,
            environments: [.ocean],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "ocean_seaweed_01",
            imageName: "Storybook/ocean_seaweed_01",
            category: .ocean,
            type: .edge,
            environments: [.ocean],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "ocean_shell_01",
            imageName: nil,
            category: .ocean,
            type: .ground,
            environments: [.ocean],
            status: .reviewRequired,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "ocean_wave_mark_01",
            imageName: "Storybook/ocean_wave_mark_01",
            category: .ocean,
            type: .accent,
            environments: [.ocean],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "sky_birds_trio_01",
            imageName: "Storybook/sky_birds_trio_01",
            category: .sky,
            type: .sky,
            environments: [.sky, .adventure, .forest],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "sky_cloud_small_01",
            imageName: nil,
            category: .sky,
            type: .sky,
            environments: [.sky, .adventure],
            status: .reviewRequired,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "sky_cloud_wisp_01",
            imageName: "Storybook/sky_cloud_wisp_01",
            category: .sky,
            type: .sky,
            environments: [.sky, .adventure, .bedtime],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "sky_star_cluster_01",
            imageName: nil,
            category: .sky,
            type: .sky,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Aynı: yıldızlar generic vector icon."
        ),
        StoryDecorationCatalogEntry(
            id: "sky_sun_rays_01",
            imageName: "Storybook/sky_sun_rays_01",
            category: .sky,
            type: .corner,
            environments: [.sky, .adventure, .garden],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "space_comet_01",
            imageName: nil,
            category: .space,
            type: .sky,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Kuyruk boncuk dizisi; mekanik."
        ),
        StoryDecorationCatalogEntry(
            id: "space_constellation_01",
            imageName: nil,
            category: .space,
            type: .sky,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Nokta-çizgi diyagramı; UI grafiği gibi."
        ),
        StoryDecorationCatalogEntry(
            id: "space_moon_arc_01",
            imageName: "Storybook/space_moon_arc_01",
            category: .space,
            type: .sky,
            environments: [.space, .bedtime, .magic],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "space_orbit_arcs_01",
            imageName: "Storybook/space_orbit_arcs_01",
            category: .space,
            type: .sky,
            environments: [.space],
            status: .approved,
            license: "Proprietary — MagicPaper Kids",
            note: ""
        ),
        StoryDecorationCatalogEntry(
            id: "space_planet_01",
            imageName: nil,
            category: .space,
            type: .sky,
            environments: [],
            status: .rejected,
            license: "Proprietary — MagicPaper Kids",
            note: "Daire + çizgi = gezegen ikonu, illüstrasyon değil."
        ),
    ]
}

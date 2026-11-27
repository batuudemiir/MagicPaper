/// App presentation assets keyed only by canonical companion identity.
/// Unknown and legacy identities deliberately retain their existing symbol.
enum CompanionPortraitCatalog {
    static func assetName(for companionID: String) -> String? {
        switch companionID {
        case "companion_fox_pilot_001": "companion_portrait_tarcin_v4"
        case "companion_hedgehog_pilot_001": "companion_portrait_kestane_v4"
        case "companion_owl_pilot_001": "companion_portrait_yildiz_v4"
        case "companion_city_cat_001": "companion_portrait_simit_v4"
        case "companion_bear_001": "companion_portrait_bogurtlen_v4"
        default: nil
        }
    }
}

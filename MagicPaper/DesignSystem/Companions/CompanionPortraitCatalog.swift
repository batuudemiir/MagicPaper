/// App presentation assets keyed only by canonical companion identity.
/// Unknown and legacy identities deliberately retain their existing symbol.
enum CompanionPortraitCatalog {
    static func assetName(for companionID: String) -> String? {
        switch companionID {
        case "companion_fox_pilot_001": "companion_portrait_tarcin_v1"
        case "companion_hedgehog_pilot_001": "companion_portrait_kestane_v1"
        case "companion_owl_pilot_001": "companion_portrait_yildiz_v1"
        case "companion_city_cat_001": "companion_portrait_simit_v1"
        case "companion_bear_001": "companion_portrait_bogurtlen_v1"
        default: nil
        }
    }
}

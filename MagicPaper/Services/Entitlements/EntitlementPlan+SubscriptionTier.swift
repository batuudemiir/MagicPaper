import Foundation

// MARK: - Kademe eşlemesi

/// `SubscriptionManager.SubscriptionTier` ile `EntitlementPlan` arasındaki tek köprü.
///
/// Ayrı dosyada duruyor çünkü bu eşleme RevenueCat'e bağlı değil: politika ve
/// testler onu RevenueCat modülü olmadan da derleyip yürütebilmeli.
///
/// `public` DEĞİL — `SubscriptionTier` internal, ve internal bir tipi public bir
/// imzada açığa çıkarmak derlenmez. Tek modüllü uygulamada fark yok.

extension EntitlementPlan {
    /// `SubscriptionManager` kademesinden entitlement planına. Eşlemenin tek yeri.
    init(_ tier: SubscriptionManager.SubscriptionTier) {
        switch tier {
        case .none:     self = .free
        case .basic:    self = .basic
        case .premium:  self = .premium
        case .ultimate: self = .ultimate
        }
    }

    var tier: SubscriptionManager.SubscriptionTier {
        switch self {
        case .free:     return .none
        case .basic:    return .basic
        case .premium:  return .premium
        case .ultimate: return .ultimate
        }
    }
}

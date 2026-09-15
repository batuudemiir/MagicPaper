import SwiftUI

/// Paywall — 03-SCREENS.md §14.
/// Kural: **önce değer, sonra fiyat.** Ekran açıldığında fiyat gösterilmez;
/// planlar yalnızca "Planları gör"e basıldıktan sonra görünür.
struct PaywallView: View {
    @EnvironmentObject private var app: MPAppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @StateObject private var revenueCat = RevenueCatManager.shared

    @State private var showPlans = false
    @State private var selectedTier: SubscriptionManager.SubscriptionTier = .premium
    @State private var showPurchaseSheet = false
    @State private var cycle: Cycle = .monthly
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    enum Cycle: Hashable { case monthly, yearly }

    private var period: RevenueCatManager.BillingPeriod {
        cycle == .yearly ? .yearly : .monthly
    }

    /// Fiyat önce StoreKit'ten yerelleştirilmiş olarak okunur; ürün henüz
    /// tanımlı değilse tasarımın referans değerine düşülür.
    private func price(_ tier: SubscriptionManager.SubscriptionTier) -> String {
        if let live = revenueCat.localizedPrice(for: tier, period: period) {
            return live
        }
        switch (tier, cycle) {
        case (.premium, .yearly): return "₺1.190"
        case (.basic, .yearly):   return "₺690"
        default:                  return tier.price
        }
    }

    private var periodLabel: String { cycle == .yearly ? "/yıl" : "/ay" }

    /// Seçilen plan için gerçek bir StoreKit ürünü var mı?
    private var hasLiveProduct: Bool {
        revenueCat.hasPackage(for: selectedTier, period: period)
    }

    private struct Benefit {
        let text: String
        let symbol: String
    }

    private let benefits: [Benefit] = [
        Benefit(text: "Sınırsız metin masalı", symbol: "sparkles"),
        Benefit(text: "12 masal dünyasının tamamı", symbol: "building.columns"),
        Benefit(text: "Aylık görselli masal hakkı", symbol: "star.fill"),
        Benefit(text: "Uzun masallar ve sesli okuma", symbol: "speaker.wave.2"),
        Benefit(text: "Yazdırılabilir PDF kitap", symbol: "printer")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                MPIconButton(symbol: "xmark", label: "Kapat") { dismiss() }
            }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.top, 4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    valueSection
                    benefitList
                    if showPlans { planSection }
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            footer
        }
        .mpScreenBackground()
        .task { revenueCat.fetchOfferings() }
        .fullScreenCover(isPresented: $showPurchaseSheet) {
            // Gerçek satın alma RevenueCat üzerinden yürür.
            SimpleSubscriptionView()
                .onDisappear {
                    if subscriptionManager.isPremium {
                        dismiss()
                        app.showToast("Premium açıldı, iyi masallar",
                                      symbol: "crown.fill", tone: .reward)
                    }
                }
        }
    }

    // MARK: - Değer bölümü

    private var valueSection: some View {
        VStack(spacing: 10) {
            MPBadge(title: "Premium", tone: .reward, symbol: "crown.fill")

            Text("Her akşam yeni bir masal")
                .font(MP.F.displayLG())
                .mpTightTracking(32)
                .foregroundStyle(MP.C.textTitle)
                .multilineTextAlignment(.center)

            Text("Sınırsız metin masalı, tüm dünyalar açık ve her ay görselli maceralar.")
                .font(MP.F.bodyMD())
                .foregroundStyle(MP.C.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var benefitList: some View {
        VStack(spacing: 12) {
            ForEach(benefits, id: \.text) { benefit in
                HStack(spacing: 12) {
                    MPIcon(benefit.symbol, size: 17, weight: .semibold)
                        .foregroundStyle(MP.C.calm)
                        .frame(width: 34, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: MP.R.sm, style: .continuous)
                                .fill(MP.C.calmSoft)
                        )
                    Text(benefit.text)
                        .font(MP.F.bodyMD(.bold))
                        .foregroundStyle(MP.C.textTitle)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - Fiyat bölümü

    private var planSection: some View {
        VStack(spacing: 12) {
            MPSegmentedControl(
                options: [(Cycle.monthly, "Aylık"), (Cycle.yearly, "Yıllık")],
                selection: $cycle
            )
            .padding(.bottom, 2)

            MPPlanCard(
                name: "Hikaye Kahramanı",
                price: price(.premium),
                period: periodLabel,
                stars: "Ayda 5 görselli masal",
                note: "Sınırsız metin masalı",
                isRecommended: true,
                isSelected: selectedTier == .premium
            ) { selectedTier = .premium }

            MPPlanCard(
                name: "Yıldız Kaşifi",
                price: price(.basic),
                period: periodLabel,
                stars: "Ayda 1 görselli masal",
                note: "Sınırsız metin masalı",
                isSelected: selectedTier == .basic
            ) { selectedTier = .basic }

            Text("İstediğin zaman iptal edebilirsin. İlk 7 gün ücretsiz.")
                .font(MP.F.caption(.regular))
                .foregroundStyle(MP.C.textFaint)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .transition(.opacity.combined(with: .offset(y: 12)))
    }

    // MARK: - Satın alma

    /// Seçilen plan için gerçek ürün varsa doğrudan satın alınır; ürün
    /// tanımlı değilse (ör. yıllık henüz açılmadıysa) RevenueCat'in kendi
    /// paywall'ına düşülür — kullanıcı hiçbir durumda çıkmaza girmez.
    private func startPurchase() {
        guard hasLiveProduct else {
            showPurchaseSheet = true
            return
        }
        isPurchasing = true
        purchaseError = nil

        revenueCat.purchaseTier(selectedTier, period: period) { success, error in
            isPurchasing = false
            if success {
                dismiss()
                app.showToast("Premium açıldı, iyi masallar",
                              symbol: "crown.fill", tone: .reward)
            } else if let error {
                purchaseError = error.localizedDescription
            }
            // success=false ve error=nil ise kullanıcı vazgeçmiştir; sessiz kalınır.
        }
    }

    // MARK: - Alt butonlar

    private var footer: some View {
        VStack(spacing: 8) {
            if let purchaseError {
                Text(purchaseError)
                    .font(MP.F.labelSM())
                    .foregroundStyle(MP.C.danger)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            MPButton(
                title: isPurchasing ? "İşleniyor…"
                                    : (showPlans ? "7 gün ücretsiz dene" : "Planları gör"),
                tone: .reward,
                size: .lg,
                fullWidth: true,
                isDisabled: isPurchasing
            ) {
                if showPlans {
                    startPurchase()
                } else {
                    withAnimation(MP.M.gated(MP.M.base)) { showPlans = true }
                }
            }

            MPButton(title: "Şimdi değil", variant: .ghost, size: .sm) { dismiss() }
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.bottom, 12)
        .background(MP.C.surfaceApp)
    }
}

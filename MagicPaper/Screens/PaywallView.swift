import SwiftUI

/// 37 · Abonelik (`Paywall`). Yalnızca ebeveyn alanından açılır.
/// Kural: **önce değer, sonra fiyat.** Ekran açıldığında fiyat gösterilmez;
/// planlar yalnızca "Planları gör"e basıldıktan sonra görünür.
struct PaywallView: View {
    @EnvironmentObject private var app: MPAppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @StateObject private var revenueCat = RevenueCatManager.shared

    @State private var showPlans = false
    @State private var selectedTier: SubscriptionManager.SubscriptionTier = .premium
    @State private var cycle: Cycle = .monthly
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var isRestoring = false

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
        let tone: MPWorldTone
    }

    private let benefits: [Benefit] = [
        Benefit(text: "Sınırsız metin masalı", symbol: "sparkles", tone: .lav),
        Benefit(text: "12 masal dünyasının tamamı", symbol: "building.columns", tone: .pink),
        Benefit(text: "Aylık görselli masal hakkı", symbol: "star", tone: .yellow),
        Benefit(text: "Uzun masallar ve sesli okuma", symbol: "speaker.wave.2", tone: .sky),
        Benefit(text: "Yazdırılabilir PDF masal kitabı", symbol: "printer", tone: .green)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xxl) {
                    hero
                    valueSection
                    if showPlans { planSection } else { benefitList }
                }
                .padding(.bottom, MPSpacing.xxl)
            }
            footer
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat") { dismiss() }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.top, MPSpacing.sm)
        }
        .task { revenueCat.fetchOfferings() }
    }

    // MARK: - Değer bölümü

    private var hero: some View {
        ZStack(alignment: .bottom) {
            HeaderWash(height: 290)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 200, bottomTrailingRadius: 200))
                .ignoresSafeArea(edges: .top)
            MascotImage(mascot: .onBook, width: 200)
                .padding(.bottom, MPSpacing.xxl)
                .accessibilityHidden(true)
            HStack(spacing: MPSpacing.xs) {
                MPIcon("crown", size: 16, weight: .semibold)
                Text("Premium").mpText(.callout)
            }
            .foregroundStyle(MPWorldTone.yellow.deep)
            .padding(.horizontal, MPSpacing.lg)
            .padding(.vertical, MPSpacing.xs)
            .background(MPColor.backgroundSurface, in: Capsule())
            .offset(y: 14)
        }
    }

    private var valueSection: some View {
        VStack(spacing: MPSpacing.sm) {
            Text("Her akşam yeni bir masal")
                .mpText(.largeTitle)
                .foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("Sınırsız metin masalı, tüm dünyalar açık ve her ay görselli maceralar.")
                .mpText(.body)
                .foregroundStyle(MPColor.textSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, MPSpacing.xl)
    }

    private var benefitList: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            ForEach(benefits, id: \.text) { benefit in
                HStack(spacing: MPSpacing.lg) {
                    MPIcon(benefit.symbol, size: 20, weight: .semibold)
                        .foregroundStyle(benefit.tone.deep)
                        .frame(width: 42, height: 42)
                        .background(benefit.tone.soft, in: Circle())
                        .accessibilityHidden(true)
                    Text(benefit.text).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, MPSpacing.xxl)
    }

    // MARK: - Fiyat bölümü

    private var planSection: some View {
        VStack(spacing: MPSpacing.md) {
            MPSegmented(options: [(Cycle.monthly, "Aylık"), (Cycle.yearly, "Yıllık")], selection: $cycle)
                .padding(.bottom, MPSpacing.sm)
            planCard(.premium, name: "Hikaye Kahramanı", allowance: "Ayda 5 görselli masal", recommended: true)
            planCard(.basic, name: "Yıldız Kaşifi", allowance: "Ayda 1 görselli masal", recommended: false)
            Text("İstediğin zaman iptal edebilirsin. İlk 7 gün ücretsiz.")
                .mpText(.caption).fontWeight(.regular)
                .foregroundStyle(MPColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, MPSpacing.xs)
        }
        .padding(.horizontal, MPSpacing.xl)
        .transition(.opacity)
    }

    private func planCard(_ tier: SubscriptionManager.SubscriptionTier, name: String,
                          allowance: String, recommended: Bool) -> some View {
        let selected = selectedTier == tier
        return Button { selectedTier = tier } label: {
            HStack(alignment: .center, spacing: MPSpacing.md) {
                Circle()
                    .strokeBorder(selected ? MPColor.actionPrimary : MPColor.borderKid, lineWidth: 2.5)
                    .background(Circle().fill(selected ? MPColor.actionPrimary : .clear).padding(5))
                    .frame(width: 26, height: 26)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text(name).mpText(.headline).foregroundStyle(MPColor.textPrimary)
                    Text(allowance).mpText(.callout).foregroundStyle(MPWorldTone.yellow.deep)
                    Text("Sınırsız metin masalı").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(price(tier)).mpText(.title2).foregroundStyle(MPColor.textPrimary)
                    Text(periodLabel).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
            }
            .padding(MPSpacing.lg)
            .padding(.top, recommended ? MPSpacing.xs : 0)
            .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
                .strokeBorder(selected ? MPColor.actionPrimary : MPColor.borderKid, lineWidth: selected ? 3 : 1.5))
            .overlay(alignment: .topLeading) {
                if recommended {
                    Text("En çok seçilen").mpText(.caption)
                        .foregroundStyle(MPColor.textPrimary)
                        .padding(.horizontal, MPSpacing.md)
                        .padding(.vertical, MPSpacing.xxs)
                        .background(MPColor.brandStar, in: Capsule())
                        .offset(x: MPSpacing.lg, y: -12)
                }
            }
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Satın alma

    /// Seçilen plan için gerçek ürün varsa doğrudan satın alınır; ürün
    /// tanımlı değilse (ör. yıllık henüz açılmadıysa) sakin bir mesaj
    /// gösterilir; başka bir ekran açılmaz. Paywall işi Premium kararını bekler.
    private func startPurchase() {
        guard hasLiveProduct else {
            // Paywall kendi örtüsünde açık; kökteki toast onun arkasında kalır,
            // bu yüzden mesaj mevcut satır içi alanda gösterilir.
            purchaseError = "Abonelik şu an açılamıyor. Biraz sonra yeniden dene."
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
        VStack(spacing: MPSpacing.xs) {
            if let purchaseError {
                Text(purchaseError)
                    .mpText(.footnote)
                    .foregroundStyle(MPColor.statusDanger)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            MPButton(title: showPlans ? "7 gün ücretsiz dene" : "Planları gör",
                     fullWidth: true, isLoading: isPurchasing) {
                if showPlans {
                    startPurchase()
                } else {
                    withAnimation(MP.M.gated(MP.M.base)) { showPlans = true }
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)

            MPButton(title: "Şimdi değil", kind: .ghost) { dismiss() }

            HStack(spacing: MPSpacing.lg) {
                Button(isRestoring ? "Geri yükleniyor…" : "Satın alımları geri yükle", action: restore)
                    .disabled(isRestoring)
                Link("Koşullar", destination: URL(string: "https://magicpaper.app/terms")!)
                Link("Gizlilik", destination: URL(string: "https://magicpaper.app/privacy")!)
            }
            .mpText(.caption)
            .foregroundStyle(MPColor.actionPrimary)
            .frame(minHeight: MPSize.minTouchParent)
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.bottom, MPSpacing.xs)
        .background(MPColor.backgroundKid)
    }

    private func restore() {
        isRestoring = true
        purchaseError = nil
        revenueCat.restorePurchases { success, error in
            isRestoring = false
            if success {
                dismiss()
                app.showToast("Satın alımlar geri yüklendi", symbol: "crown.fill", tone: .reward)
            } else if let error {
                purchaseError = error.localizedDescription
            } else {
                purchaseError = "Geri yüklenecek bir abonelik bulunamadı."
            }
        }
    }
}

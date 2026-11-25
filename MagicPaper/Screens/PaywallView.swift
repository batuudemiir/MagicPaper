import SwiftUI

/// 37 · Abonelik (`Paywall`). Yalnızca ebeveyn alanından açılır.
///
/// Son tasarım (21 Kasım 2026, İrem): prototipteki "C · Sade ve güven" düzeni,
/// olduğu gibi (`design-preview/app/paywall.js`). Sıra: "MagicPaper Premium" ve
/// tek cümle, yan yana Yıllık/Aylık (yıllık varsayılan, İrem'in kararı), onay
/// işaretli beş fayda, deneme takvimi (yalnızca mağazada deneme varsa), güven
/// satırı, App Store 3.1.2 yenileme metni. Satın alma yetişkin ekranı: Ragi yok.
/// Fiyat baştan görünür. Model: tek plan MagicPaper Premium (karar: Batuhan 20 Kasım 2026).
struct PaywallView: View {
    @EnvironmentObject private var app: MPAppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @StateObject private var revenueCat = RevenueCatManager.shared

    @State private var cycle: Cycle = .yearly
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var isRestoring = false

    enum Cycle: Hashable { case monthly, yearly }

    /// Tek plan (karar: Batuhan 20 Kasım 2026).
    private let tier: SubscriptionManager.SubscriptionTier = .premium

    private func period(_ c: Cycle) -> RevenueCatManager.BillingPeriod { c == .yearly ? .yearly : .monthly }
    private var period: RevenueCatManager.BillingPeriod { period(cycle) }

    /// Fiyat önce StoreKit'ten yerelleştirilmiş olarak okunur; ürün henüz
    /// tanımlı değilse kararın referans fiyatına düşülür.
    private func priceLabel(_ c: Cycle) -> String {
        if let live = revenueCat.localizedPrice(for: tier, period: period(c)) { return live }
        return c == .yearly ? "₺999" : tier.price   // karar: 20 Kasım 2026
    }

    private func periodLabel(_ c: Cycle) -> String { c == .yearly ? "/yıl" : "/ay" }

    /// Yıllığın aylığa göre avantajı, gerçek mağaza fiyatlarından. Ürünler
    /// gelmemişse rozet hiç görünmez: sabit bir yüzde yazılmaz.
    private var yearlySaving: Int? {
        guard let yearly = revenueCat.priceAmount(for: tier, period: .yearly),
              let monthly = revenueCat.priceAmount(for: tier, period: .monthly), monthly > 0 else { return nil }
        let ratio = NSDecimalNumber(decimal: yearly / (monthly * 12)).doubleValue
        let percent = Int(((1 - ratio) * 100).rounded())
        return percent >= 5 ? percent : nil
    }

    /// Aynı avantajın tutarı: aylık × 12 − yıllık, mağaza para birimiyle
    /// (₺149 × 12 − ₺999 = ₺789). Yüzde tek başına küçük fiyatta büyük,
    /// büyük fiyatta küçük görünebilir; ikisi yan yana yazılır.
    private var yearlySavingAmount: String? {
        guard yearlySaving != nil,
              let yearly = revenueCat.priceAmount(for: tier, period: .yearly),
              let monthly = revenueCat.priceAmount(for: tier, period: .monthly) else { return nil }
        return revenueCat.localizedAmount(monthly * 12 - yearly, for: tier, period: .yearly)
    }

    /// Çocuğun kitaplığındaki masallar, en son okunan önce.
    private var childStories: [Story] {
        guard let profile = ProfileManager.shared.currentProfile else { return [] }
        return StoryGenerationManager.shared.stories
            .filter { $0.isReadable && $0.belongs(to: profile) }
            .sorted { ($0.lastReadAt ?? $0.createdAt) > ($1.lastReadAt ?? $1.createdAt) }
    }

    /// Çocuğun kitaplığındaki gerçek masal sayısı (değer önerisi 4, 26 Kasım
    /// 2026). Masal yoksa sahiplik cümlesi kurulmaz.
    private var libraryLine: String? {
        guard let profile = ProfileManager.shared.currentProfile, !childStories.isEmpty else { return nil }
        return "\(SeriesCopy.genitive(profile.name)) kitaplığında \(childStories.count) masal var."
    }

    /// Seçilen plan için gerçek bir StoreKit ürünü var mı?
    private var hasLiveProduct: Bool {
        revenueCat.hasPackage(for: tier, period: period)
    }

    /// Abonelik kararı (Batuhan 20 Kasım 2026): yalnızca bugün gerçekten
    /// açılan şeyler. Dünyalar ücretsiz; kendi sesinle okuma ve görselli
    /// masal Release'te kapalı olduğu için satılmaz.
    private let benefits = [
        "Gün boyu yeni masal",
        "Bütün klasikler ve seriler",
        "Masal ailem",
        "Ailedeki her çocuk",
        "PDF masal kitabı"
    ]

    /// Mağazada tanımlı ücretsiz deneme (gün); yoksa deneme sözü verilmez.
    private var trialDays: Int? {
        revenueCat.freeTrialDays(for: tier, period: period)
    }

    /// App Store 3.1.2: dönem, fiyat ve otomatik yenileme satın alma düğmesinin yanında.
    private var renewalNote: String {
        let trial = trialDays.map { "İlk \($0) gün ücretsiz, sonra " } ?? ""
        return "\(trial)\(priceLabel(cycle))\(periodLabel(cycle)). Ödeme Apple Kimliği hesabından alınır. "
            + "Abonelik, dönem bitmeden en az 24 saat önce iptal edilmezse aynı fiyatla kendiliğinden yenilenir."
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                    header
                    plans
                    benefitList
                    if let trialDays { trialTimeline(days: trialDays) }
                    VStack(alignment: .leading, spacing: MPSpacing.md) {
                        trustLine
                        Text(renewalNote)
                            .mpText(.footnote).fontWeight(.regular)
                            .foregroundStyle(MPColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, MPSpacing.screenH)
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

    // MARK: - Başlık (C)

    private var header: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xs) {
            Text("MagicPaper Premium").mpText(.page).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text([libraryLine, "Her akşamın masalı ücretsiz kalır. Premium kitaplığı büyütür."]
                    .compactMap { $0 }.joined(separator: " "))
                .mpText(.body).foregroundStyle(MPColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            // Çocuğun gerçek kapakları, en fazla üç: büyüyecek kitaplık bu.
            if !childStories.isEmpty {
                HStack(spacing: MPSpacing.sm) {
                    ForEach(childStories.prefix(3), id: \.id) { story in
                        MPBookCover(art: LibraryShelfModel.coverArt(story), width: 64)
                    }
                }
                .padding(.top, MPSpacing.xs)
                .accessibilityHidden(true)
            }
        }
        // Kapat düğmesinin altından başlar.
        .padding(.top, MPSize.minTouchHero)
    }

    // MARK: - Planlar (C)

    private var plans: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: MPSpacing.md))
            : AnyLayout(HStackLayout(alignment: .top, spacing: MPSpacing.sm))
        return layout {
            planCard(.yearly)
            planCard(.monthly)
        }
        .padding(.top, MPSpacing.sm)
    }

    private func planCard(_ c: Cycle) -> some View {
        let selected = cycle == c
        let perMonth = revenueCat.localizedPricePerMonth(for: tier, period: .yearly).map { "Ayda \($0)" }
        let yearlyParts = [perMonth, yearlySavingAmount.map { "aylığa göre yılda \($0) az" }].compactMap { $0 }
        let note = c == .yearly
            ? (yearlyParts.isEmpty ? "Yılda bir ödeme" : yearlyParts.joined(separator: ", "))
            : "İstediğin ay bırak"
        return Button {
            withAnimation(MP.M.gated(MP.M.press)) { cycle = c }
        } label: {
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                HStack {
                    Text(c == .yearly ? "Yıllık" : "Aylık").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    Spacer(minLength: MPSpacing.xs)
                    MPIcon(selected ? "checkmark.circle.fill" : "circle", size: MP.G.md, weight: .semibold)
                        .foregroundStyle(selected ? MPColor.actionPrimary : MPColor.borderKid)
                        .accessibilityHidden(true)
                }
                Text(note).mpText(.footnote).fontWeight(.regular).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: MPSpacing.sm)
                HStack(alignment: .firstTextBaseline, spacing: MPSpacing.xxs) {
                    Text(priceLabel(c)).mpText(.section).foregroundStyle(MPColor.textPrimary)
                    Text(periodLabel(c)).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
            }
            .padding(MPSpacing.lg)
            .padding(.top, c == .yearly && yearlySaving != nil ? MPSpacing.xs : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
                .strokeBorder(selected ? MPColor.actionPrimary : MPColor.borderKid, lineWidth: selected ? 3 : 1.5))
            .overlay(alignment: .topLeading) {
                if c == .yearly, let yearlySaving {
                    Text("%\(yearlySaving) avantajlı").mpText(.footnote)
                        .foregroundStyle(MPColor.textPrimary)
                        .padding(.horizontal, MPSpacing.md)
                        .padding(.vertical, MPSpacing.xxs)
                        .background(MPColor.brandStar, in: Capsule())
                        .offset(x: MPSpacing.md, y: -MPSpacing.md)
                }
            }
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Fayda, deneme, güven (C)

    private var benefitList: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            ForEach(benefits, id: \.self) { text in
                HStack(alignment: .firstTextBaseline, spacing: MPSpacing.md) {
                    MPIcon("checkmark", size: MP.G.md, weight: .bold)
                        .foregroundStyle(MPColor.statusSuccess)
                        .accessibilityHidden(true)
                    Text(text).mpText(.body).foregroundStyle(MPColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// Deneme takvimi: "unutursam para kesilir" korkusunu alır. Yalnızca mağazada
    /// gerçekten deneme tanımlıysa görünür; hatırlatma gününü de deneme süresinden alır.
    private func trialTimeline(days: Int) -> some View {
        let steps: [(icon: String, title: String, body: String)] = [
            ("sparkles", "Bugün", "Her şey açılır, ücret alınmaz."),
            ("bell", "\(max(1, days - 2)). gün", "Deneme bitmeden sana hatırlatırız."),
            ("star", "\(days). gün", "Abonelik başlar. Öncesinde tek dokunuşla iptal edebilirsin.")
        ]
        return VStack(alignment: .leading, spacing: MPSpacing.md) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: MPSpacing.md) {
                    MPIcon(step.icon, size: MP.G.sm, weight: .semibold)
                        .foregroundStyle(index == 0 ? MPColor.textOnAction : MPColor.actionPrimary)
                        .frame(width: MPSize.circleButton - MPSpacing.sm, height: MPSize.circleButton - MPSpacing.sm)
                        .background(index == 0 ? MPColor.actionPrimary : MPColor.actionSoft, in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                        Text(step.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        Text(step.body).mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var trustLine: some View {
        HStack(spacing: MPSpacing.xs) {
            MPIcon("lock", size: MP.G.sm, weight: .semibold).accessibilityHidden(true)
            Text("Reklam yok · Veriler satılmaz · İnternetsiz çalışır").mpText(.footnote)
        }
        .foregroundStyle(MPColor.statusSuccess)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Satın alma

    /// Seçilen plan için gerçek ürün varsa doğrudan satın alınır; ürün
    /// tanımlı değilse sakin bir mesaj gösterilir; başka bir ekran açılmaz.
    private func startPurchase() {
        guard hasLiveProduct else {
            // Paywall kendi örtüsünde açık; kökteki toast onun arkasında kalır,
            // bu yüzden mesaj mevcut satır içi alanda gösterilir.
            purchaseError = "Abonelik şu an açılamıyor. Biraz sonra yeniden dene."
            return
        }
        isPurchasing = true
        purchaseError = nil

        revenueCat.purchaseTier(tier, period: period) { success, error in
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

            MPButton(title: trialDays.map { "\($0) gün ücretsiz başla" } ?? "Abone ol",
                     fullWidth: true, isLoading: isPurchasing) {
                startPurchase()
            }

            MPButton(title: "Şimdi değil", kind: .ghost) { dismiss() }

            // "Aboneliği yönet": App Store abonelik sayfası (3.1.2). Sistem sayfasına
            // gider; Paywall'un üstüne ikinci bir modal açılmaz.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: MPSpacing.lg) { legalLinks }
                VStack(spacing: MPSpacing.xs) {
                    HStack(spacing: MPSpacing.lg) {
                        restoreButton
                        Link("Aboneliği yönet", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                    }
                    HStack(spacing: MPSpacing.lg) {
                        Link("Koşullar", destination: URL(string: "https://magicpaper.app/terms")!)
                        Link("Gizlilik", destination: URL(string: "https://magicpaper.app/privacy")!)
                    }
                }
            }
            .mpText(.footnote)
            .foregroundStyle(MPColor.actionPrimary)
            .frame(minHeight: MPSize.minTouchParent)
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, MPSpacing.sm)
        .padding(.bottom, MPSpacing.xs)
        .background(MPColor.backgroundKid)
    }

    private var restoreButton: some View {
        Button(isRestoring ? "Geri yükleniyor…" : "Satın alımları geri yükle", action: restore)
            .disabled(isRestoring)
    }

    @ViewBuilder private var legalLinks: some View {
        restoreButton
        Link("Aboneliği yönet", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
        Link("Koşullar", destination: URL(string: "https://magicpaper.app/terms")!)
        Link("Gizlilik", destination: URL(string: "https://magicpaper.app/privacy")!)
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

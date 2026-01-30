import SwiftUI

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedTab: PricingTab = .subscription
    @State private var selectedPlan: SubscriptionPlan = .yearly
    
    enum PricingTab {
        case oneTime
        case subscription
        
        var title: String {
            switch self {
            case .oneTime: return "Tek Seferlik"
            case .subscription: return "Abonelik"
            }
        }
    }
    
    enum SubscriptionPlan {
        case monthly
        case yearly
        
        var title: String {
            switch self {
            case .monthly: return "Aylık Premium"
            case .yearly: return "Yıllık Premium"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "₺149"
            case .yearly: return "₺1.199"
            }
        }
        
        var period: String {
            switch self {
            case .monthly: return "/ay"
            case .yearly: return "/yıl"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "%33 İndirim"
            }
        }
        
        var monthlyEquivalent: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Ayda sadece ₺99.9"
            }
        }
        
        var features: [String] {
            return [
                "10 görselli hikaye/ay",
                "Sınırsız metin hikaye",
                "Reklamsız deneyim",
                "Öncelikli destek",
                "Ekstra görselli: ₺19/adet"
            ]
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Sabit beyaz arka plan
                Color.white
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Tab Selector
                        tabSelector
                        
                        // Content based on selected tab
                        if selectedTab == .oneTime {
                            oneTimePurchaseSection
                        } else {
                            subscriptionSection
                        }
                        
                        // Terms
                        termsSection
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.light)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.3))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.15),
                                Color(red: 0.85, green: 0.35, blue: 0.85).opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.29, blue: 0.98),
                                Color(red: 0.85, green: 0.35, blue: 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("MagicPaper Premium")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Sınırsız hikaye, premium özellikler")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach([PricingTab.oneTime, PricingTab.subscription], id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.title)
                        .font(.system(size: 16, weight: selectedTab == tab ? .bold : .medium))
                        .foregroundColor(selectedTab == tab ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            selectedTab == tab ?
                            LinearGradient(
                                colors: [
                                    Color(red: 0.58, green: 0.29, blue: 0.98),
                                    Color(red: 0.85, green: 0.35, blue: 0.85)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) : nil
                        )
                        .cornerRadius(12)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - One Time Purchase Section
    
    private var oneTimePurchaseSection: some View {
        VStack(spacing: 16) {
            // Single Story Cards
            oneTimeCard(
                icon: "photo.on.rectangle.angled",
                title: "Görselli Hikaye",
                description: "7 sayfa, kişiselleştirilmiş görseller",
                price: "₺29",
                gradient: [Color(red: 0.58, green: 0.29, blue: 0.98), Color(red: 0.75, green: 0.32, blue: 0.92)],
                badge: "Popüler"
            )
            
            oneTimeCard(
                icon: "text.book.closed",
                title: "Metin Hikaye",
                description: "7 sayfa, sadece metin",
                price: "₺9",
                gradient: [Color(red: 0.85, green: 0.35, blue: 0.85), Color(red: 0.95, green: 0.40, blue: 0.75)],
                badge: nil
            )
            
            // Bundle Cards
            Divider()
                .padding(.vertical, 8)
            
            Text("Paket Teklifleri")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            bundleCard(
                title: "5'li Karma Paket",
                description: "5 hikaye (görselli veya metin)",
                originalPrice: "₺145",
                price: "₺119",
                discount: "%18 İndirim"
            )
            
            bundleCard(
                title: "10'lu Karma Paket",
                description: "10 hikaye (görselli veya metin)",
                originalPrice: "₺290",
                price: "₺199",
                discount: "%31 İndirim"
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func oneTimeCard(icon: String, title: String, description: String, price: String, gradient: [Color], badge: String?) -> some View {
        Button(action: {
            purchaseOneTime(type: title)
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: gradient,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Price
                Text(price)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .shadow(color: gradient[0].opacity(0.15), radius: 12, x: 0, y: 4)
            )
        }
    }
    
    private func bundleCard(title: String, description: String, originalPrice: String, price: String, discount: String) -> some View {
        Button(action: {
            purchaseBundle(type: title)
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text(discount)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(originalPrice)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .strikethrough()
                    
                    Text(price)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.2), lineWidth: 2)
                    )
            )
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            // Plan Cards
            subscriptionPlanCard(plan: .yearly)
            subscriptionPlanCard(plan: .monthly)
            
            // Subscribe Button
            Button(action: {
                subscribeToPremium()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Premium'a Geç")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.58, green: 0.29, blue: 0.98),
                            Color(red: 0.85, green: 0.35, blue: 0.85)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.3), radius: 12, x: 0, y: 6)
            }
            
            // Features
            VStack(spacing: 12) {
                Text("Premium Özellikler")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(SubscriptionPlan.yearly.features, id: \.self) { feature in
                    featureRow(text: feature)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func subscriptionPlanCard(plan: SubscriptionPlan) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedPlan = plan
            }
        }) {
            HStack(spacing: 16) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.58, green: 0.29, blue: 0.98), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if selectedPlan == plan {
                        Circle()
                            .fill(Color(red: 0.58, green: 0.29, blue: 0.98))
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Plan info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical: 2)
                                .background(
                                    Capsule()
                                        .fill(Color.orange)
                                )
                        }
                    }
                    
                    if let monthly = plan.monthlyEquivalent {
                        Text(monthly)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(plan.period)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedPlan == plan ? Color(red: 0.58, green: 0.29, blue: 0.98).opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(selectedPlan == plan ? Color(red: 0.58, green: 0.29, blue: 0.98) : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
    
    private func featureRow(text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.black)
            
            Spacer()
        }
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            if selectedTab == .subscription {
                Text("7 gün ücretsiz deneme")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
            }
            
            Text("İstediğiniz zaman iptal edebilirsiniz")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            Button(action: {
                // Restore purchases
            }) {
                Text("Satın Alımları Geri Yükle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                    .underline()
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Actions
    
    private func purchaseOneTime(type: String) {
        print("💳 Tek seferlik satın alma: \(type)")
        // TODO: StoreKit implementation
        
        // Simüle et
        let alert = UIAlertController(
            title: "✅ Satın Alındı",
            message: "\(type) başarıyla satın alındı!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            dismiss()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
    
    private func purchaseBundle(type: String) {
        print("💳 Paket satın alma: \(type)")
        // TODO: StoreKit implementation
        
        // Simüle et
        let alert = UIAlertController(
            title: "✅ Satın Alındı",
            message: "\(type) başarıyla satın alındı!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            dismiss()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
    
    private func subscribeToPremium() {
        print("💳 Premium abonelik: \(selectedPlan.title)")
        // TODO: StoreKit implementation
        
        // Simüle et
        subscriptionManager.isPremium = true
        
        let alert = UIAlertController(
            title: "🎉 Hoş Geldiniz!",
            message: "Premium üyeliğiniz başarıyla aktif edildi!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Harika!", style: .default) { _ in
            dismiss()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

#Preview {
    PremiumView()
}

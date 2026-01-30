import SwiftUI

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPlan: PremiumPlan = .yearly
    
    enum PremiumPlan {
        case monthly
        case yearly
        
        var title: String {
            switch self {
            case .monthly: return "Aylık"
            case .yearly: return "Yıllık"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "₺49,99"
            case .yearly: return "₺399,99"
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
            case .yearly: return "Ayda sadece ₺33,33"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.58, green: 0.29, blue: 0.98),
                        Color(red: 0.75, green: 0.32, blue: 0.92),
                        Color(red: 0.85, green: 0.35, blue: 0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("MagicPaper Premium")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Sınırsız hikaye, premium temalar ve daha fazlası")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 24)
                        
                        // Features
                        VStack(spacing: 16) {
                            featureRow(icon: "infinity", title: "Sınırsız Hikaye", description: "İstediğiniz kadar hikaye oluşturun")
                            featureRow(icon: "sparkles", title: "Premium Temalar", description: "Özel tema ve karakterlere erişin")
                            featureRow(icon: "photo.stack", title: "Yüksek Kalite Görseller", description: "Daha detaylı ve kaliteli görseller")
                            featureRow(icon: "bolt.fill", title: "Öncelikli İşlem", description: "Hikayeleriniz daha hızlı oluşturulsun")
                            featureRow(icon: "rectangle.slash", title: "Reklamsız Deneyim", description: "Hiç reklam görmeden kullanın")
                        }
                        .padding(.horizontal, 20)
                        
                        // Plan Selection
                        VStack(spacing: 16) {
                            Text("Plan Seçin")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                planCard(plan: .yearly)
                                planCard(plan: .monthly)
                            }
                        }
                        .padding(.horizontal, 20)
                        
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
                            .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Terms
                        VStack(spacing: 8) {
                            Text("7 gün ücretsiz deneme")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("İstediğiniz zaman iptal edebilirsiniz")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Restore Purchase
                        Button(action: {
                            // Restore purchases
                        }) {
                            Text("Satın Alımları Geri Yükle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .underline()
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func planCard(plan: PremiumPlan) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedPlan = plan
            }
        }) {
            HStack(spacing: 16) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if selectedPlan == plan {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Plan info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.58, green: 0.29, blue: 0.98))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(.white)
                                )
                        }
                    }
                    
                    if let monthly = plan.monthlyEquivalent {
                        Text(monthly)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(plan.period)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedPlan == plan ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(selectedPlan == plan ? 0.5 : 0.2), lineWidth: 2)
                    )
            )
        }
    }
    
    private func subscribeToPremium() {
        // Simulate subscription
        subscriptionManager.isPremium = true
        dismiss()
    }
}

#Preview {
    PremiumView()
}

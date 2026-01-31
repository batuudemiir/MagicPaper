import SwiftUI

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPackage: CreditPackage = .standard
    
    enum CreditPackage: CaseIterable {
        case starter
        case standard
        case plus
        case premium
        
        var icon: String {
            switch self {
            case .starter: return "💰"
            case .standard: return "📦"
            case .plus: return "🎁"
            case .premium: return "👑"
            }
        }
        
        var title: String {
            switch self {
            case .starter: return "Başlangıç"
            case .standard: return "Standart"
            case .plus: return "Artı"
            case .premium: return "Premium"
            }
        }
        
        var price: String {
            switch self {
            case .starter: return "₺79"
            case .standard: return "₺149"
            case .plus: return "₺249"
            case .premium: return "₺399"
            }
        }
        
        var credits: Int {
            switch self {
            case .starter: return 10
            case .standard: return 25
            case .plus: return 50
            case .premium: return 100
            }
        }
        
        var visualStories: Int {
            return credits / 3
        }
        
        var badge: String? {
            switch self {
            case .starter: return nil
            case .standard: return "ÖNERİLEN"
            case .plus: return nil
            case .premium: return "EN AVANTAJLI"
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .starter:
                return [Color(red: 0.85, green: 0.35, blue: 0.85), Color(red: 0.95, green: 0.40, blue: 0.75)]
            case .standard:
                return [Color(red: 0.58, green: 0.29, blue: 0.98), Color(red: 0.75, green: 0.32, blue: 0.92)]
            case .plus:
                return [Color(red: 1.0, green: 0.45, blue: 0.55), Color(red: 1.0, green: 0.55, blue: 0.45)]
            case .premium:
                return [Color.orange, Color.yellow]
            }
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
                        
                        // Credit Info
                        creditInfoSection
                        
                        // Packages
                        packagesSection
                        
                        // How it works
                        howItWorksSection
                        
                        // Benefits
                        benefitsSection
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
                                Color.yellow.opacity(0.2),
                                Color.orange.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text("⭐")
                    .font(.system(size: 56))
            }
            
            VStack(spacing: 8) {
                Text("Kredi Satın Al")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text("İstediğin kadar al, istediğin zaman kullan!")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Credit Info Section
    
    private var creditInfoSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                creditUsageCard(
                    icon: "📝",
                    title: "Metin Hikaye",
                    credits: "1 kredi",
                    color: Color(red: 0.85, green: 0.35, blue: 0.85)
                )
                
                creditUsageCard(
                    icon: "🎨",
                    title: "Görselli Hikaye",
                    credits: "3 kredi",
                    color: Color(red: 0.58, green: 0.29, blue: 0.98)
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func creditUsageCard(icon: String, title: String, credits: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 40))
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Text(credits)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: color.opacity(0.15), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Packages Section
    
    private var packagesSection: some View {
        VStack(spacing: 16) {
            ForEach(CreditPackage.allCases, id: \.self) { package in
                packageCard(package: package)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func packageCard(package: CreditPackage) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedPackage = package
            }
        }) {
            VStack(spacing: 0) {
                // Badge
                if let badge = package.badge {
                    HStack {
                        Spacer()
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: package.gradient,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .offset(y: -12)
                        Spacer()
                    }
                }
                
                HStack(spacing: 20) {
                    // Icon
                    Text(package.icon)
                        .font(.system(size: 48))
                    
                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(package.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: package.gradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("\(package.credits) kredi")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: package.gradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        
                        Text("~\(package.visualStories) görselli hikaye")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Price
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(package.price)
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.black)
                        
                        // Radio button
                        ZStack {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: package.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 24, height: 24)
                            
                            if selectedPackage == package {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: package.gradient,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 14, height: 14)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(selectedPackage == package ? Color(red: 0.98, green: 0.98, blue: 1.0) : .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                selectedPackage == package ?
                                LinearGradient(
                                    colors: package.gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: selectedPackage == package ? 2 : 1
                            )
                    )
                    .shadow(
                        color: selectedPackage == package ? package.gradient[0].opacity(0.2) : .black.opacity(0.05),
                        radius: selectedPackage == package ? 16 : 8,
                        x: 0,
                        y: selectedPackage == package ? 8 : 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - How It Works Section
    
    private var howItWorksSection: some View {
        VStack(spacing: 20) {
            Text("Nasıl Çalışır?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                howItWorksStep(
                    number: "1",
                    title: "Kredi Paketi Al",
                    description: "İhtiyacına göre paket seç",
                    color: Color(red: 0.58, green: 0.29, blue: 0.98)
                )
                
                howItWorksStep(
                    number: "2",
                    title: "İstediğin Zaman Kullan",
                    description: "Metin veya görselli hikaye oluştur",
                    color: Color(red: 0.85, green: 0.35, blue: 0.85)
                )
                
                howItWorksStep(
                    number: "3",
                    title: "Kredi Bitince Yenile",
                    description: "Dilediğin zaman yeni paket al",
                    color: Color(red: 1.0, green: 0.45, blue: 0.55)
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func howItWorksStep(number: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Text(number)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(spacing: 20) {
            Text("Neden Kredi Sistemi?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                benefitRow(icon: "checkmark.circle.fill", text: "Esnek kullanım - istediğin zaman", color: .green)
                benefitRow(icon: "checkmark.circle.fill", text: "Param boşa gitmiyor", color: .green)
                benefitRow(icon: "checkmark.circle.fill", text: "Metin mi görselli mi sen karar ver", color: .green)
                benefitRow(icon: "checkmark.circle.fill", text: "Üyelik yok, bağlayıcı değil", color: .green)
            }
            
            // Purchase Button
            Button(action: {
                purchasePackage(selectedPackage)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("\(selectedPackage.credits) Kredi Al - \(selectedPackage.price)")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: selectedPackage.gradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: selectedPackage.gradient[0].opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
    }
    
    private func benefitRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.black)
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func purchasePackage(_ package: CreditPackage) {
        print("💳 Paket satın alma: \(package.title) - \(package.credits) kredi")
        // TODO: StoreKit implementation
        
        // Simüle et
        let alert = UIAlertController(
            title: "✅ Satın Alındı!",
            message: "\(package.credits) kredi hesabınıza eklendi!",
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

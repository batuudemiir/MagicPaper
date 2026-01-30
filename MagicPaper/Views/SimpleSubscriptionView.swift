import SwiftUI

struct SimpleSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPackage: SubscriptionManager.SubscriptionPackage?
    @State private var showingPurchaseAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                        .padding(.top, 20)
                    
                    // Mevcut Durum
                    if subscriptionManager.subscriptionTier != .none {
                        currentSubscriptionCard
                            .padding(.horizontal, 20)
                    } else if subscriptionManager.freeTrialCount > 0 {
                        freeTrialCard
                            .padding(.horizontal, 20)
                    }
                    
                    // Abonelik Paketleri
                    subscriptionPackagesSection
                        .padding(.horizontal, 20)
                    
                    // Satın Al Butonu
                    if selectedPackage != nil {
                        purchaseButton
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.98, blue: 0.94),
                        Color(red: 0.98, green: 0.95, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Abonelik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Abonelik", isPresented: $showingPurchaseAlert) {
            Button("Tamam") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(subscriptionManager.isPremium ? "👑" : "✨")
                    .font(.system(size: 56))
            }
            
            VStack(spacing: 8) {
                Text(subscriptionManager.isPremium ? "Premium Üye" : "Çocuğunuz Kahramanı Olsun")
                    .font(.title.bold())
                    .foregroundColor(.primary)
                
                if subscriptionManager.isPremium {
                    Text("Sınırsız hikaye keyfini çıkarın!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    VStack(spacing: 4) {
                        Text("☕️ Bir kahveden daha ucuz!")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("Günde 3₺ ile çocuğunuzun hayal gücünü geliştirin")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            // Faydalar - Sadece abone değilse göster
            if !subscriptionManager.isPremium {
                VStack(spacing: 12) {
                    benefitRow(icon: "brain.head.profile", text: "Hayal gücünü geliştirin", color: .purple)
                    benefitRow(icon: "heart.fill", text: "Özgüven kazandırın", color: .pink)
                    benefitRow(icon: "book.fill", text: "Okuma sevgisi aşılayın", color: .blue)
                    benefitRow(icon: "moon.stars.fill", text: "Uyku rutini oluşturun", color: .indigo)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 32)
            }
        }
    }
    
    private func benefitRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    // MARK: - Current Subscription Card
    
    private var currentSubscriptionCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mevcut Paketiniz")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(subscriptionManager.subscriptionTier.displayName)
                        .font(.title2.bold())
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Text("👑")
                    .font(.system(size: 40))
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Görselli Hikaye")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text("\(subscriptionManager.remainingImageStories)")
                            .font(.title.bold())
                            .foregroundColor(.indigo)
                        Text("/ \(subscriptionManager.subscriptionTier.monthlyImageStories)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Metin & Günlük")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Sınırsız")
                        .font(.title3.bold())
                        .foregroundColor(.green)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .orange.opacity(0.15), radius: 16, x: 0, y: 4)
        )
    }
    
    // MARK: - Free Trial Card
    
    private var freeTrialCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Text("🎁")
                    .font(.system(size: 28))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Ücretsiz Deneme")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text("\(subscriptionManager.freeTrialCount) hikaye hakkınız kaldı")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .green.opacity(0.15), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Subscription Packages
    
    private var subscriptionPackagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Abonelik Paketleri")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(SubscriptionManager.subscriptionPackages, id: \.tier) { package in
                    subscriptionCard(package: package)
                }
            }
        }
    }
    
    private func subscriptionCard(package: SubscriptionManager.SubscriptionPackage) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedPackage = package
            }
        }) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(package.title)
                                .font(.headline.bold())
                                .foregroundColor(.primary)
                            
                            if package.isPopular {
                                Text("EN POPÜLER")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.orange, Color.yellow],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Text(package.price)
                                .font(.title2.bold())
                                .foregroundColor(.orange)
                            Text("/ ay")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Günlük maliyet vurgusu
                        Text("Günde sadece \(Int(package.priceValue / 30))₺")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.top, 2)
                    }
                    
                    Spacer()
                    
                    // Checkbox
                    ZStack {
                        Circle()
                            .stroke(selectedPackage?.tier == package.tier ? Color.orange : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        if selectedPackage?.tier == package.tier {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(package.features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 16))
                            Text(feature)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Değer vurgusu
                if package.tier == .premium {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("Her görselli hikaye 14₺ değerinde - 70₺ tasarruf!")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                selectedPackage?.tier == package.tier ?
                                LinearGradient(
                                    colors: [Color.orange, Color.yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: selectedPackage?.tier == package.tier ? Color.orange.opacity(0.2) : .clear,
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        Button(action: makePurchase) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16, weight: .bold))
                
                if let package = selectedPackage {
                    Text("Abone Ol - \(package.price)/ay")
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)
            )
        }
    }
    
    // MARK: - Purchase
    
    private func makePurchase() {
        guard let package = selectedPackage else { return }
        
        // TODO: Gerçek abonelik satın alma (StoreKit)
        subscriptionManager.purchaseSubscription(tier: package.tier)
        
        let dailyCost = Int(package.priceValue / 30)
        
        alertMessage = """
        🎉 Harika Seçim!
        
        \(package.title) aktif edildi.
        
        ✨ Çocuğunuz artık kendi hikayelerinin kahramanı!
        
        📚 Sınırsız metin hikaye
        🌟 Sınırsız günlük hikaye
        🎨 \(package.tier.monthlyImageStories) görselli hikaye/ay
        
        Günde sadece \(dailyCost)₺ ile çocuğunuzun hayal gücünü geliştirin!
        """
        
        showingPurchaseAlert = true
    }
}

#Preview {
    SimpleSubscriptionView()
}

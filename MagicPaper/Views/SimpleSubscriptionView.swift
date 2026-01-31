import SwiftUI

struct SimpleSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPackage: SubscriptionManager.SubscriptionPackage?
    @State private var showingPurchaseAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Hero Header
                    heroHeader
                        .padding(.top, 20)
                    
                    // Social Proof
                    socialProofBanner
                        .padding(.horizontal, 20)
                    
                    // Mevcut Durum
                    if subscriptionManager.subscriptionTier != .none {
                        currentSubscriptionCard
                            .padding(.horizontal, 20)
                    } else if subscriptionManager.freeTrialCount > 0 {
                        freeTrialCard
                            .padding(.horizontal, 20)
                    } else {
                        freePackageCard
                            .padding(.horizontal, 20)
                    }
                    
                    // Hikaye Kulübü Paketleri
                    subscriptionPackagesSection
                        .padding(.horizontal, 20)
                    
                    // Satın Al Butonu
                    if selectedPackage != nil {
                        purchaseButton
                            .padding(.horizontal, 20)
                    }
                    
                    // Güven Göstergeleri
                    trustIndicators
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray6))
                                .frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .alert("🎉 Tebrikler!", isPresented: $showingPurchaseAlert) {
            Button("Harika!") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        VStack(spacing: 20) {
            // Animated Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                
                Text(subscriptionManager.isPremium ? "👑" : "✨")
                    .font(.system(size: 50))
            }
            
            VStack(spacing: 12) {
                if subscriptionManager.isPremium {
                    Text("Sınırsız Hikaye Dünyası")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Kulüp üyeliğinizin keyfini çıkarın!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 8) {
                        Text("Çocuğunuza Okuma")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Alışkanlığı Kazandırın 📚")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Text("☕️")
                                .font(.title3)
                            Text("Bir kahveden ucuz!")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        Text("Günde sadece 3₺ ile çocuğunuzun hayal dünyasını zenginleştirin ve okuma sevgisini geliştirin")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 8)
                }
            }
            
            // Faydalar - Sadece üye değilse göster
            if !subscriptionManager.isPremium {
                VStack(spacing: 14) {
                    benefitRow(icon: "book.fill", text: "Okuma sevgisi ve alışkanlığı", color: .blue)
                    benefitRow(icon: "brain.head.profile", text: "Hayal gücü ve yaratıcılık", color: .purple)
                    benefitRow(icon: "heart.fill", text: "Özgüven ve mutluluk", color: .pink)
                    benefitRow(icon: "moon.stars.fill", text: "Huzurlu uyku rutini", color: .indigo)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func benefitRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))
        }
    }
    
    // MARK: - Social Proof Banner
    
    private var socialProofBanner: some View {
        HStack(spacing: 12) {
            HStack(spacing: -8) {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("👶")
                                .font(.system(size: 16))
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
                
                Text("1000+ mutlu aile")
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Current Subscription Card
    
    private var currentSubscriptionCard: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Aktif Paketiniz")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack(spacing: 8) {
                        Text("👑")
                            .font(.title2)
                        Text(subscriptionManager.subscriptionTier.displayName)
                            .font(.title2.bold())
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Görselli Hikaye")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text("\(subscriptionManager.remainingImageStories)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.indigo)
                        Text("/ \(subscriptionManager.subscriptionTier.monthlyImageStories)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("kalan hakkınız")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("Metin & Günlük")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text("∞")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    Text("sınırsız")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: .orange.opacity(0.2), radius: 20, x: 0, y: 8)
        )
    }
    
    // MARK: - Free Trial Card
    
    private var freeTrialCard: some View {
        VStack(spacing: 16) {
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
                        .frame(width: 60, height: 60)
                    
                    Text("🎁")
                        .font(.system(size: 32))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ücretsiz Deneme Aktif")
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text("\(subscriptionManager.freeTrialCount)")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                        Text("hikaye hakkınız kaldı")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Text("Deneme hakkınız bittikten sonra kulübe katılın ve sınırsız hikaye keyfini yaşayın!")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .green.opacity(0.15), radius: 16, x: 0, y: 6)
        )
    }
    
    // MARK: - Free Package Card
    
    private var freePackageCard: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mevcut Paketiniz")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack(spacing: 8) {
                        Text("📦")
                            .font(.title2)
                        Text("Ücretsiz Paket")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "checkmark.circle.fill", text: "12 saatte 1 metin hikaye", color: .green, isAvailable: true)
                featureRow(icon: "xmark.circle.fill", text: "Görselli hikaye", color: .red, isAvailable: false)
                featureRow(icon: "xmark.circle.fill", text: "Günlük hikaye", color: .red, isAvailable: false)
                featureRow(icon: "xmark.circle.fill", text: "Sınırsız erişim", color: .red, isAvailable: false)
            }
            
            // Yükseltme teşviki
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.system(size: 18))
                    
                    Text("Okuma alışkanlığı kazandırın!")
                        .font(.subheadline.bold())
                        .foregroundColor(.purple)
                }
                
                Text("Günde 3₺ ile çocuğunuzun okuma sevgisini geliştirin ve hayal gücünü sınırsız zenginleştirin")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: .gray.opacity(0.15), radius: 20, x: 0, y: 8)
        )
    }
    
    private func featureRow(icon: String, text: String, color: Color, isAvailable: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color.opacity(isAvailable ? 1.0 : 0.5))
                .font(.system(size: 18))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(isAvailable ? .primary : .secondary)
                .strikethrough(!isAvailable, color: .secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Subscription Packages
    
    private var subscriptionPackagesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("📚 Hikaye Kulübü Paketleri")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("Çocuğunuza okuma alışkanlığı kazandırın, hayal dünyasını zenginleştirin!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 14) {
                ForEach(SubscriptionManager.subscriptionPackages, id: \.tier) { package in
                    subscriptionCard(package: package)
                }
            }
        }
    }
    
    private func subscriptionCard(package: SubscriptionManager.SubscriptionPackage) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedPackage = package
            }
        }) {
            VStack(spacing: 0) {
                // Popular Badge
                if package.isPopular {
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("EN POPÜLER")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
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
                        Spacer()
                    }
                    .padding(.bottom, 16)
                }
                
                VStack(spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(package.title)
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(package.price)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.orange)
                                Text("/ ay")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Günlük maliyet vurgusu
                            HStack(spacing: 4) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.caption)
                                Text("Günde \(Int(package.priceValue / 30))₺")
                                    .font(.caption.bold())
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.1))
                            )
                        }
                        
                        Spacer()
                        
                        // Checkbox
                        ZStack {
                            Circle()
                                .stroke(selectedPackage?.tier == package.tier ? Color.orange : Color.gray.opacity(0.3), lineWidth: 3)
                                .frame(width: 32, height: 32)
                            
                            if selectedPackage?.tier == package.tier {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 20, height: 20)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(package.features, id: \.self) { feature in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 18))
                                Text(feature)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                    
                    // Değer vurgusu
                    if package.tier == .premium {
                        VStack(spacing: 8) {
                            Divider()
                            
                            HStack(spacing: 10) {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 18))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Süper Tasarruf!")
                                        .font(.caption.bold())
                                        .foregroundColor(.orange)
                                    Text("Her görselli hikaye 14₺ değerinde - Ayda 70₺ tasarruf!")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    } else if package.tier == .ultimate {
                        VStack(spacing: 8) {
                            Divider()
                            
                            HStack(spacing: 10) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.purple)
                                    .font(.system(size: 18))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Maksimum Değer!")
                                        .font(.caption.bold())
                                        .foregroundColor(.purple)
                                    Text("Her görselli hikaye 14₺ değerinde - Ayda 140₺ tasarruf!")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.purple.opacity(0.1))
                            )
                        }
                    }
                }
                .padding(20)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
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
                                lineWidth: selectedPackage?.tier == package.tier ? 3 : 1
                            )
                    )
                    .shadow(
                        color: selectedPackage?.tier == package.tier ? Color.orange.opacity(0.3) : Color.black.opacity(0.05),
                        radius: selectedPackage?.tier == package.tier ? 20 : 12,
                        x: 0,
                        y: selectedPackage?.tier == package.tier ? 8 : 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedPackage?.tier == package.tier ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPackage?.tier == package.tier)
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button(action: makePurchase) {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .bold))
                    
                    if let package = selectedPackage {
                        Text("Kulübe Katıl - \(package.price)/ay")
                            .font(.system(size: 18, weight: .bold))
                    }
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.4), radius: 16, x: 0, y: 8)
                )
            }
            
            Text("İstediğiniz zaman iptal edebilirsiniz")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Trust Indicators
    
    private var trustIndicators: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.vertical, 8)
            
            HStack(spacing: 20) {
                trustBadge(icon: "lock.shield.fill", text: "Güvenli Ödeme", color: .green)
                trustBadge(icon: "arrow.clockwise", text: "7 Gün İade", color: .blue)
                trustBadge(icon: "checkmark.seal.fill", text: "KVKK Uyumlu", color: .purple)
            }
            
            Text("Üyeliğinizi istediğiniz zaman iOS ayarlarından iptal edebilirsiniz")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    private func trustBadge(icon: String, text: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(text)
                .font(.caption2.bold())
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Purchase
    
    private func makePurchase() {
        guard let package = selectedPackage else { return }
        
        // TODO: Gerçek üyelik satın alma (StoreKit)
        subscriptionManager.purchaseSubscription(tier: package.tier)
        
        let dailyCost = Int(package.priceValue / 30)
        
        alertMessage = """
        \(package.title) başarıyla aktif edildi!
        
        🎨 \(package.tier.monthlyImageStories) görselli hikaye/ay
        📚 Sınırsız metin hikaye
        🌟 Sınırsız günlük hikaye
        
        Günde sadece \(dailyCost)₺ ile çocuğunuza okuma alışkanlığı kazandırın ve hayal dünyasını zenginleştirin!
        
        Hemen ilk hikayenizi oluşturmaya başlayın! ✨
        """
        
        showingPurchaseAlert = true
    }
}

#Preview {
    SimpleSubscriptionView()
}

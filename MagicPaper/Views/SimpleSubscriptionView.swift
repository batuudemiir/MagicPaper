import SwiftUI

struct SimpleSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPackage: SubscriptionManager.SubscriptionPackage?
    @State private var showingPurchaseAlert = false
    @State private var alertMessage = ""
    @State private var showingParentalGate = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DeviceHelper.isIPad ? 36 : 28) {
                    // Hero Header
                    heroHeader
                        .padding(.top, DeviceHelper.isIPad ? 32 : 20)
                    
                    // Social Proof
                    socialProofBanner
                        .padding(.horizontal, DeviceHelper.isIPad ? 40 : 20)
                    
                    // Mevcut Durum
                    if subscriptionManager.subscriptionTier != .none {
                        currentSubscriptionCard
                            .padding(.horizontal, DeviceHelper.isIPad ? 40 : 20)
                    } else if subscriptionManager.freeTrialCount > 0 {
                        freeTrialCard
                            .padding(.horizontal, DeviceHelper.isIPad ? 40 : 20)
                    } else {
                        freePackageCard
                            .padding(.horizontal, DeviceHelper.isIPad ? 40 : 20)
                    }
                    
                    // Hikaye Kulübü Paketleri
                    subscriptionPackagesSection
                        .padding(.horizontal, DeviceHelper.isIPad ? 40 : 20)
                    
                    // Satın Al Butonu
                    if selectedPackage != nil {
                        purchaseButton
                            .padding(.horizontal, DeviceHelper.isIPad ? 40 : 20)
                    }
                    
                    // Güven Göstergeleri
                    trustIndicators
                        .padding(.horizontal, DeviceHelper.isIPad ? 40 : 20)
                }
                .padding(.bottom, DeviceHelper.isIPad ? 60 : 40)
            }
            .background(
                ZStack {
                    // Premium gradient background
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.98, blue: 0.94),
                            Color(red: 0.98, green: 0.95, blue: 1.0),
                            Color(red: 1.0, green: 0.96, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Animated mesh overlay
                    GeometryReader { geometry in
                        // Top left glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.purple.opacity(0.15), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: DeviceHelper.isIPad ? 300 : 200
                                )
                            )
                            .frame(width: DeviceHelper.isIPad ? 400 : 250, height: DeviceHelper.isIPad ? 400 : 250)
                            .offset(x: -100, y: -100)
                            .blur(radius: 40)
                        
                        // Bottom right glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.orange.opacity(0.15), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: DeviceHelper.isIPad ? 300 : 200
                                )
                            )
                            .frame(width: DeviceHelper.isIPad ? 400 : 250, height: DeviceHelper.isIPad ? 400 : 250)
                            .offset(x: geometry.size.width - 150, y: geometry.size.height - 150)
                            .blur(radius: 40)
                    }
                }
                .ignoresSafeArea()
            )
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: DeviceHelper.isIPad ? 44 : 36, height: DeviceHelper.isIPad ? 44 : 36)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: DeviceHelper.isIPad ? 16 : 14, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primary, .secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .alert(L.congratulations, isPresented: $showingPurchaseAlert) {
            Button(L.great) {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingParentalGate) {
            ParentalGateView(onSuccess: {
                makePurchase()
            })
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        VStack(spacing: DeviceHelper.isIPad ? 24 : 20) {
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
                    .frame(width: DeviceHelper.isIPad ? 140 : 110, height: DeviceHelper.isIPad ? 140 : 110)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: DeviceHelper.isIPad ? 110 : 90, height: DeviceHelper.isIPad ? 110 : 90)
                
                Text(subscriptionManager.isPremium ? "👑" : "✨")
                    .font(.system(size: DeviceHelper.isIPad ? 64 : 50))
            }
            
            VStack(spacing: DeviceHelper.isIPad ? 16 : 12) {
                if subscriptionManager.isPremium {
                    Text(L.unlimitedStoryWorld)
                        .font(.system(size: DeviceHelper.isIPad ? 36 : 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(L.tr("Kulüp üyeliğinizin keyfini çıkarın!", "Enjoy your club membership!"))
                        .font(.system(size: DeviceHelper.isIPad ? 18 : 16))
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: DeviceHelper.isIPad ? 10 : 8) {
                        Text(L.tr("Çocuğunuza Okuma", "Build Your Child's Reading"))
                            .font(.system(size: DeviceHelper.isIPad ? 36 : 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(L.tr("Alışkanlığı Kazandırın 📚", "Habit 📚"))
                            .font(.system(size: DeviceHelper.isIPad ? 36 : 28, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: DeviceHelper.isIPad ? 8 : 6) {
                        HStack(spacing: DeviceHelper.isIPad ? 8 : 6) {
                            Text("☕️")
                                .font(.system(size: DeviceHelper.isIPad ? 24 : 20))
                            Text(L.cheaperThanCoffee)
                                .font(.system(size: DeviceHelper.isIPad ? 20 : 17, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                        
                        Text(L.tr("Günde sadece 3₺ ile çocuğunuzun hayal dünyasını zenginleştirin ve okuma sevgisini geliştirin", "Enrich your child's imagination and develop reading love for only $1/day"))
                            .font(.system(size: DeviceHelper.isIPad ? 17 : 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DeviceHelper.isIPad ? 40 : 20)
                    }
                    .padding(.top, DeviceHelper.isIPad ? 12 : 8)
                }
            }
            
            // Faydalar - Sadece üye değilse göster
            if !subscriptionManager.isPremium {
                VStack(spacing: DeviceHelper.isIPad ? 18 : 14) {
                    benefitRow(icon: "book.fill", text: L.tr("Okuma sevgisi ve alışkanlığı", "Reading love and habit"), color: .blue)
                    benefitRow(icon: "brain.head.profile", text: L.tr("Hayal gücü ve yaratıcılık", "Imagination and creativity"), color: .purple)
                    benefitRow(icon: "heart.fill", text: L.tr("Özgüven ve mutluluk", "Confidence and happiness"), color: .pink)
                    benefitRow(icon: "moon.stars.fill", text: L.tr("Huzurlu uyku rutini", "Peaceful sleep routine"), color: .indigo)
                }
                .padding(DeviceHelper.isIPad ? 28 : 20)
                .background(
                    RoundedRectangle(cornerRadius: DeviceHelper.isIPad ? 28 : 20, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.08), radius: DeviceHelper.isIPad ? 16 : 12, x: 0, y: DeviceHelper.isIPad ? 6 : 4)
                )
                .padding(.horizontal, DeviceHelper.isIPad ? 40 : 20)
            }
        }
    }
    
    private func benefitRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: DeviceHelper.isIPad ? 18 : 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: DeviceHelper.isIPad ? 52 : 40, height: DeviceHelper.isIPad ? 52 : 40)
                
                Image(systemName: icon)
                    .font(.system(size: DeviceHelper.isIPad ? 22 : 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(text)
                .font(.system(size: DeviceHelper.isIPad ? 17 : 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: DeviceHelper.isIPad ? 24 : 20))
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
                
                Text(L.tr("1000+ mutlu aile", "1000+ happy families"))
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
                    Text(L.yourActivePackage)
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
                    Text(L.illustratedStory)
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
                    
                    Text(L.yourRemainingQuota)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(L.textAndDaily)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text("∞")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    Text(L.unlimited)
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
                    Text(L.freeTrialActive)
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text("\(subscriptionManager.freeTrialCount)")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                        Text(L.tr("hikaye hakkınız kaldı", "stories remaining"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Text(L.tr("Deneme hakkınız bittikten sonra kulübe katılın ve sınırsız hikaye keyfini yaşayın!", "After your trial ends, join the club and enjoy unlimited stories!"))
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
                    Text(L.currentPackage)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack(spacing: 8) {
                        Text("📦")
                            .font(.title2)
                        Text(L.freePackage)
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "checkmark.circle.fill", text: L.textStoryEvery12Hours, color: .green, isAvailable: true)
                featureRow(icon: "xmark.circle.fill", text: L.illustratedStory, color: .red, isAvailable: false)
                featureRow(icon: "xmark.circle.fill", text: L.dailyStory, color: .red, isAvailable: false)
                featureRow(icon: "xmark.circle.fill", text: L.tr("Sınırsız erişim", "Unlimited access"), color: .red, isAvailable: false)
            }
            
            // Yükseltme teşviki
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.system(size: 18))
                    
                    Text(L.buildReadingHabit)
                        .font(.subheadline.bold())
                        .foregroundColor(.purple)
                }
                
                Text(L.tr("Günde 3₺ ile çocuğunuzun okuma sevgisini geliştirin ve hayal gücünü sınırsız zenginleştirin", "Develop your child's reading love and enrich imagination for $1/day"))
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
                
                Text(L.clubDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 14) {
                ForEach(SubscriptionManager.subscriptionPackages, id: \.tier) { package in
                    subscriptionCard(package: package)
                }
            }
            
            // Required Subscription Information - Apple Guidelines 3.1.2
            VStack(alignment: .leading, spacing: 12) {
                Text("📋 Abonelik Bilgileri")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .padding(.top, 8)
                
                // Paket Detayları
                VStack(alignment: .leading, spacing: 8) {
                    subscriptionInfoRow(title: "⭐ Yıldız Kaşifi", price: "₺89/ay", duration: "Aylık (30 gün)", stories: "1 görselli hikaye/ay")
                    subscriptionInfoRow(title: "👑 Hikaye Kahramanı", price: "₺149/ay", duration: "Aylık (30 gün)", stories: "5 görselli hikaye/ay")
                    subscriptionInfoRow(title: "🌟 Sihir Ustası", price: "₺349/ay", duration: "Aylık (30 gün)", stories: "10 görselli hikaye/ay")
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Genel Bilgiler
                VStack(alignment: .leading, spacing: 6) {
                    Text("• Tüm paketlerde sınırsız metin ve günlük hikaye")
                    Text("• Abonelikler otomatik olarak yenilenir")
                    Text("• Ödeme iTunes hesabınızdan çekilir")
                    Text("• Yenileme: Süre bitmeden 24 saat önce otomatik")
                    Text("• İptal: iOS Ayarlar > Apple ID > Abonelikler")
                    Text("• İptal edilmezse otomatik yenilenir")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
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
                                    Text(L.superSavings)
                                        .font(.caption.bold())
                                        .foregroundColor(.orange)
                                    Text(L.tr("Her görselli hikaye 14₺ değerinde - Ayda 70₺ tasarruf!", "Each illustrated story worth $5 - Save $25/month!"))
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
                                    Text(L.maximumValue)
                                        .font(.caption.bold())
                                        .foregroundColor(.purple)
                                    Text(L.tr("Her görselli hikaye 14₺ değerinde - Ayda 140₺ tasarruf!", "Each illustrated story worth $5 - Save $50/month!"))
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
        VStack(spacing: DeviceHelper.isIPad ? 16 : 12) {
            Button(action: {
                // COPPA Compliance: Parental gate before purchase
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
                showingParentalGate = true
            }) {
                HStack(spacing: DeviceHelper.isIPad ? 14 : 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: DeviceHelper.isIPad ? 22 : 18, weight: .bold))
                    
                    if let package = selectedPackage {
                        Text(L.tr("Kulübe Katıl - \(package.price)/ay", "Join Club - \(package.price)/month"))
                            .font(.system(size: DeviceHelper.isIPad ? 22 : 18, weight: .bold))
                    }
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: DeviceHelper.isIPad ? 22 : 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DeviceHelper.isIPad ? 24 : 18)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: DeviceHelper.isIPad ? 20 : 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        // Shine effect
                        RoundedRectangle(cornerRadius: DeviceHelper.isIPad ? 20 : 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(color: .orange.opacity(0.5), radius: DeviceHelper.isIPad ? 24 : 16, x: 0, y: DeviceHelper.isIPad ? 12 : 8)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text("İstediğiniz zaman iptal edebilirsiniz")
                .font(.system(size: DeviceHelper.isIPad ? 15 : 13))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Trust Indicators
    
    private var trustIndicators: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.vertical, 8)
            
            HStack(spacing: 20) {
                trustBadge(icon: "lock.shield.fill", text: L.securePayment, color: .green)
                trustBadge(icon: "arrow.clockwise", text: L.dayRefund, color: .blue)
                trustBadge(icon: "checkmark.seal.fill", text: L.kvkkCompliant, color: .purple)
            }
            
            VStack(spacing: 8) {
                Text("Üyeliğinizi istediğiniz zaman iOS ayarlarından iptal edebilirsiniz")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Terms of Use and Privacy Policy Links
                HStack(spacing: 16) {
                    Button(action: {
                        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Terms of Use")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .underline()
                    }
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        if let url = URL(string: "https://www.magicpaperkids.com/gizlilik") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Privacy Policy")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                .padding(.top, 4)
            }
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
    
    private func subscriptionInfoRow(title: String, price: String, duration: String, stories: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                Spacer()
                Text(price)
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }
            Text("Süre: \(duration)")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("İçerik: \(stories) + Sınırsız metin/günlük")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Purchase
    
    private func makePurchase() {
        guard let package = selectedPackage else { return }
        
        // TODO: Gerçek üyelik satın alma (StoreKit)
        subscriptionManager.purchaseSubscription(tier: package.tier)
        
        let dailyCost = Int(package.priceValue / 30)
        
        alertMessage = L.tr("""
        \(package.title) başarıyla aktif edildi!
        
        🎨 \(package.tier.monthlyImageStories) görselli hikaye/ay
        📚 Sınırsız metin hikaye
        🌟 Sınırsız günlük hikaye
        
        Günde sadece \(dailyCost)₺ ile çocuğunuza okuma alışkanlığı kazandırın ve hayal dünyasını zenginleştirin!
        
        Hemen ilk hikayenizi oluşturmaya başlayın! ✨
        """, """
        \(package.title) successfully activated!
        
        🎨 \(package.tier.monthlyImageStories) illustrated stories/month
        📚 Unlimited text stories
        🌟 Unlimited daily stories
        
        Build reading habit and enrich imagination for only $\(dailyCost)/day!
        
        Start creating your first story now! ✨
        """)
        
        showingPurchaseAlert = true
    }
}

#Preview {
    SimpleSubscriptionView()
}

import SwiftUI
#if canImport(RevenueCat)
import RevenueCat
#endif
#if canImport(RevenueCatUI)
import RevenueCatUI
#endif

struct SimpleSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingParentalGate = false
    @State private var parentalGateApproved = false
    @State private var showFallback = false
    
    var body: some View {
        #if canImport(RevenueCatUI)
        ZStack {
            // RevenueCat Paywall - presentPaywallIfNeeded modifier kullan
            Color.clear
                .presentPaywallIfNeeded(
                    requiredEntitlementIdentifier: "premium",
                    purchaseCompleted: { customerInfo in
                        print("✅ Purchase completed!")
                        print("Entitlements: \(customerInfo.entitlements)")
                        
                        // Premium kontrolü ve SubscriptionManager güncelleme
                        if customerInfo.entitlements["premium"]?.isActive == true {
                            print("🎉 Premium aktif!")
                            
                            // Hangi paketi aldığını belirle ve SubscriptionManager'ı güncelle
                            if customerInfo.activeSubscriptions.contains("magicpaper_ultimate_monthly") {
                                SubscriptionManager.shared.purchaseSubscription(tier: .ultimate)
                            } else if customerInfo.activeSubscriptions.contains("magicpaper_premium_monthly") {
                                SubscriptionManager.shared.purchaseSubscription(tier: .premium)
                            } else if customerInfo.activeSubscriptions.contains("magicpaper_basic_monthly") {
                                SubscriptionManager.shared.purchaseSubscription(tier: .basic)
                            }
                        }
                        
                        dismiss()
                    },
                    restoreCompleted: { customerInfo in
                        print("🔄 Restore completed!")
                        print("Entitlements: \(customerInfo.entitlements)")
                        
                        // Premium kontrolü ve SubscriptionManager güncelleme
                        if customerInfo.entitlements["premium"]?.isActive == true {
                            print("✅ Premium restored!")
                            
                            // Hangi paketi aldığını belirle ve SubscriptionManager'ı güncelle
                            if customerInfo.activeSubscriptions.contains("magicpaper_ultimate_monthly") {
                                SubscriptionManager.shared.purchaseSubscription(tier: .ultimate)
                            } else if customerInfo.activeSubscriptions.contains("magicpaper_premium_monthly") {
                                SubscriptionManager.shared.purchaseSubscription(tier: .premium)
                            } else if customerInfo.activeSubscriptions.contains("magicpaper_basic_monthly") {
                                SubscriptionManager.shared.purchaseSubscription(tier: .basic)
                            }
                        }
                        
                        dismiss()
                    }
                )
                .overlay(
                    // Fallback message eğer offerings yok ise
                    VStack(spacing: 20) {
                        Text("📦")
                            .font(.system(size: 60))
                        
                        Text("RevenueCat Dashboard Setup Gerekli")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        
                        Text("Offerings henüz oluşturulmamış. Lütfen RevenueCat Dashboard'a gidin ve offerings oluşturun.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Adımlar:")
                                .font(.headline)
                            
                            Text("1. app.revenuecat.com'a gidin")
                            Text("2. MagicPaper projesini seçin")
                            Text("3. Offerings > + New Offering")
                            Text("4. Identifier: default")
                            Text("5. 3 Package ekleyin")
                            Text("6. Current offering olarak işaretleyin")
                        }
                        .font(.caption)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button("Dashboard'a Git") {
                            if let url = URL(string: "https://app.revenuecat.com/") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .opacity(showFallback ? 1 : 0)
                )
            
            // Custom close button (üstte sağda)
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingParentalGate) {
            ParentalGateView(onSuccess: {
                parentalGateApproved = true
                // Parental gate onaylandı, satın alma devam edecek
            })
        }
        .onAppear {
            // 2 saniye sonra offerings yoksa fallback göster
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                #if canImport(RevenueCat)
                Purchases.shared.getOfferings { offerings, error in
                    if offerings?.current == nil {
                        showFallback = true
                    }
                }
                #endif
            }
        }
        #else
        // RevenueCatUI yok, fallback
        VStack(spacing: 20) {
            Text("⚠️ RevenueCatUI Yüklenmedi")
                .font(.title2.bold())
            
            Text("RevenueCatUI package'ını target'a ekleyin:")
                .font(.body)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Xcode > Project > Target")
                Text("2. General > Frameworks")
                Text("3. + butonuna tıkla")
                Text("4. RevenueCatUI seç")
                Text("5. Add")
            }
            .font(.caption)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            Button("Kapat") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        #endif
    }
}

#Preview {
    SimpleSubscriptionView()
}

import SwiftUI

/// Ayarlar — 03-SCREENS.md §13.
struct SettingsView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPrivacy = false

    /// Kalan görselli masal hakkı — birim adı her zaman "Yıldız".
    private var stars: Int {
        subscriptionManager.isPremium
            ? subscriptionManager.remainingImageStories
            : subscriptionManager.freeTrialCount
    }

    var body: some View {
        VStack(spacing: 0) {
            MPNavBar(title: "Ayarlar", onBack: { dismiss() })

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    readingSection
                    childModeSection
                    notificationsSection
                    accountSection
                    #if DEBUG
                    developerSection
                    #endif
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .mpScreenBackground()
        .fullScreenCover(isPresented: $showPrivacy) {
            PrivacyAndDataView()
        }
    }

    // MARK: - Okuma

    private var readingSection: some View {
        section(title: "Okuma") {
            MPListRow(symbol: "textformat.size", title: "Yazı boyutu") {
                Text(settings.readSize.rawValue)
                    .font(MP.F.labelMD())
                    .foregroundStyle(MP.C.textMuted)
            }
            MPRowDivider()
            MPListRow(symbol: "speaker.wave.2", title: "Sesli okuma") {
                MPSwitch(isOn: $settings.readAloud, label: "Sesli okuma")
            }
        }
    }

    // MARK: - Çocuk modu

    private var childModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Çocuk modu",
                            subtitle: "Satın alma ve ebeveyn bölümü gizlenir")
            MPCard(padding: 0) {
                MPListRow(
                    symbol: "shield",
                    title: "Çocuk modunu aç",
                    description: settings.childMode
                        ? "Açık — çıkmak için ebeveyn kapısı sorulur"
                        : "Kapalı"
                ) {
                    MPSwitch(isOn: Binding(
                        get: { settings.childMode },
                        set: { on in
                            settings.childMode = on
                            if on {
                                app.parentUnlocked = false
                                app.showToast("Çocuk modu açıldı", symbol: "lock.fill")
                            }
                        }
                    ), label: "Çocuk modu")
                }
            }
        }
    }

    // MARK: - Bildirimler ve limitler

    private var notificationsSection: some View {
        section(title: "Bildirimler ve limitler") {
            MPListRow(symbol: "bell", title: "Masal saati hatırlatması",
                      description: "Her akşam 20.30") {
                MPSwitch(isOn: $settings.reminder, label: "Masal saati hatırlatması")
            }
            MPRowDivider()
            MPListRow(symbol: "eye.slash", title: "Masalları onaylamadan gösterme") {
                MPSwitch(isOn: $settings.approve, label: "Masalları onaylamadan gösterme")
            }
            MPRowDivider()
            MPListRow(symbol: "clock", title: "Ekran süresi limiti",
                      description: "Günde 30 dakika") {
                MPSwitch(isOn: $settings.screenLimit, label: "Ekran süresi limiti")
            }
        }
    }

    // MARK: - Hesap

    private var accountSection: some View {
        section(title: "Hesap") {
            MPListRow(symbol: "crown.fill", title: "Aboneliği yönet", action: {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            })
            MPRowDivider()
            MPListRow(symbol: "lock.fill", title: "Gizlilik ve veri",
                      description: "Çocuk fotoğrafı toplanmaz",
                      action: { showPrivacy = true })
        }
    }

    // MARK: - Geliştirici
    //
    // Yalnızca DEBUG derlemesinde görünür. Yayınlanan uygulamada satın almayı
    // baypas eden bir yol bulunmamalı.

    #if DEBUG
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Geliştirici",
                            subtitle: "Yalnızca test derlemesinde görünür")

            MPCard(padding: 0) {
                VStack(spacing: 0) {
                    MPListRow(
                        symbol: "book-open",
                        iconColor: MP.C.calm,
                        title: "Dekorasyon galerisi",
                        description: "Varlık kataloğu, kürasyon durumu, ortam kapsamı",
                        action: { app.showDecorationGallery = true }
                    ) { EmptyView() }

                    MPRowDivider()

                    MPListRow(
                        symbol: "sparkles",
                        iconColor: MP.C.brand,
                        title: "Dekorasyon demoları",
                        description: "Orman · Deniz · Uyku · Macera, debug katmanıyla",
                        action: { app.showDecorationDemo = true }
                    ) { EmptyView() }

                    MPRowDivider()

                    MPListRow(
                        symbol: "star.fill",
                        iconColor: MP.C.reward,
                        title: "Deneme yıldızı ekle",
                        description: "5 yıldız ekler, görselli masal kilidini açar",
                        action: {
                            subscriptionManager.grantTrialStars(5)
                            app.showToast("5 yıldız eklendi",
                                          symbol: "star.fill", tone: .reward)
                        }
                    ) {
                        Text("\(stars)")
                            .font(MP.F.labelMD())
                            .foregroundStyle(MP.C.textMuted)
                    }

                    MPRowDivider()

                    MPListRow(
                        symbol: "crown.fill",
                        iconColor: MP.C.premiumInk,
                        title: subscriptionManager.isPremium
                            ? "Aboneliği kapat" : "Aboneliği aç",
                        description: subscriptionManager.isPremium
                            ? "Ücretsiz plana döner" : "Hikaye Kahramanı planını açar",
                        action: {
                            if subscriptionManager.isPremium {
                                subscriptionManager.cancelSubscription()
                                app.showToast("Abonelik kapatıldı", symbol: "crown.fill")
                            } else {
                                subscriptionManager.purchaseSubscription(tier: .premium)
                                app.showToast("Premium açıldı, iyi masallar",
                                              symbol: "crown.fill", tone: .reward)
                            }
                        }
                    )
                }
            }
        }
    }
    #endif

    @ViewBuilder
    private func section<Content: View>(title: String,
                                        @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: title)
            MPCard(padding: 0) {
                VStack(spacing: 0) { content() }
            }
        }
    }
}

// MARK: - Gizlilik ve veri
//
// Tasarımda tek satır olarak geçiyor. Eski Ayarlar ekranındaki "tüm verileri
// sil" ve yasal bağlantılar App Store uyumluluğu için gerekli olduğundan
// bu satırın altına taşındı.

struct PrivacyAndDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    var body: some View {
        VStack(spacing: 0) {
            MPNavBar(title: "Gizlilik ve veri", onBack: { dismiss() })

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    MPCard(padding: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Çocuk fotoğrafı toplanmaz")
                                .font(MP.F.displaySM())
                                .foregroundStyle(MP.C.textTitle)
                            Text("MagicPaper yalnızca çocuğun adını ve avatar rengini saklar. Masallar ve görseller cihazında tutulur.")
                                .font(MP.F.bodyMD())
                                .lineSpacing(16 * 0.55)
                                .foregroundStyle(MP.C.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        MPSectionHeader(title: "Yasal")
                        MPCard(padding: 0) {
                            VStack(spacing: 0) {
                                MPListRow(symbol: "shield", title: "Gizlilik politikası", action: {
                                    open("https://magicpaper.app/privacy")
                                })
                                MPRowDivider()
                                MPListRow(symbol: "book", title: "Kullanım koşulları", action: {
                                    open("https://magicpaper.app/terms")
                                })
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        MPSectionHeader(title: "Veriler")
                        MPCard(padding: 0) {
                            MPListRow(symbol: "trash", title: "Tüm verileri sil",
                                      description: "Masallar, profiller ve ayarlar cihazdan kaldırılır",
                                      isDanger: true,
                                      action: { confirmClear = true })
                        }
                    }
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .mpScreenBackground()
        // Onay dili sistem alert'i değil, sistemin kendi alt sayfasıdır:
        // "her ikincil aksiyon ekran push etmek yerine sheet'te açılır".
        .overlay {
            if confirmClear {
                MPSheet(title: "Tüm verileri sil", onClose: { confirmClear = false }) {
                    Text("Masallar, profiller ve okuma ilerlemen cihazdan kaldırılır. Bu işlem geri alınamaz.")
                        .font(MP.F.bodyMD())
                        .lineSpacing(16 * 0.55)
                        .foregroundStyle(MP.C.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } footer: {
                    VStack(spacing: 8) {
                        MPButton(title: "Sil", tone: .play, size: .lg, fullWidth: true) {
                            confirmClear = false
                            clearAll()
                        }
                        MPButton(title: "Vazgeç", variant: .ghost, size: .sm) {
                            confirmClear = false
                        }
                    }
                }
            }
        }
    }

    private func open(_ url: String) {
        guard let u = URL(string: url) else { return }
        UIApplication.shared.open(u)
    }

    private func clearAll() {
        let d = UserDefaults.standard
        for key in ["stories", "user_profiles", "current_profile_id",
                    "mp_favoriteStoryIDs", "mp_readDays", "mp_approvedStoryIDs"] {
            d.removeObject(forKey: key)
        }
        dismiss()
    }
}

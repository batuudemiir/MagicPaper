import SwiftUI

/// Ebeveyn modu · **Ayarlar** — 03-SCREENS.md §13.
///
/// Eskiden Ebeveyn panelindeki bir dişliden tam ekran açılıyordu; artık
/// ebeveyn menüsünün bir sayfası. Abonelik kartı da panelden buraya geldi:
/// plan bir ayar, istatistik değil.
struct SettingsView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var showPrivacy = false
    /// iOS bildirimi reddettiyse anahtar açık kalamaz; ekran bunu söylemek
    /// zorunda, yoksa ebeveyn açık bir anahtara bakıp hiç bildirim almaz.
    @State private var notificationsDenied = false

    /// Kalan görselli masal hakkı — birim adı her zaman "Yıldız".
    private var stars: Int {
        subscriptionManager.isPremium
            ? subscriptionManager.remainingImageStories
            : subscriptionManager.freeTrialCount
    }

    var body: some View {
        VStack(spacing: 0) {
            MPParentHeader(title: "Ayarlar")

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    subscriptionCard
                    readingSection
                    notificationsSection
                    accountSection
                    #if DEBUG
                    developerSection
                    #endif
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, MP.S.x3)
                .padding(.bottom, MP.S.x7)
            }
        }
        .mpScreenBackground()
        .fullScreenCover(isPresented: $showPrivacy) {
            PrivacyAndDataView()
        }
        // Ekranı açtığında gerçeği göster: izin Sistem Ayarları'ndan geri
        // alınmış olabilir ve bizim anahtarımız bunu bilmiyor.
        .task {
            guard settings.reminder else { return }
            notificationsDenied = await !MPReminder.isAuthorised()
        }
    }

    // MARK: - Abonelik

    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Abonelik")

            MPCard(tone: .reward, padding: 18) {
                HStack(spacing: 14) {
                    MPIcon("crown.fill", size: 24, weight: .semibold)
                        .foregroundStyle(MP.C.premiumInk)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscriptionManager.isPremium ? "Hikaye Kahramanı" : "Ücretsiz plan")
                            .font(MP.F.bodyMD(.bold))
                            .foregroundStyle(MP.C.textTitle)
                        Text(subscriptionManager.isPremium
                             ? "Aylık yenilenir"
                             : "\(stars) yıldız kaldı")
                            .font(MP.F.labelSM())
                            .foregroundStyle(MP.C.premiumInk)
                    }

                    Spacer(minLength: 0)

                    MPButton(title: subscriptionManager.isPremium ? "Yönet" : "Yükselt",
                             tone: .reward, size: .sm) {
                        app.openPaywall()
                    }
                }
            }
        }
    }

    // MARK: - Okuma

    /// Yazı boyutu satırı bir değeri **gösteriyordu** ama dokunulacak bir şeyi
    /// yoktu: eylemi olmayan, seçeneği olmayan bir satır. Boyut yalnızca
    /// okuyucunun kendi sheet'inden değişebiliyordu, yani Ayarlar'daki satır
    /// bir ayar değil bir etiketti.
    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Okuma")
            MPCard(padding: 0) {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 14) {
                            MPIcon("textformat.size", size: 20, weight: .semibold)
                                .foregroundStyle(MP.C.brand)
                                .frame(width: 38, height: 38)
                                .background(RoundedRectangle(cornerRadius: MP.R.sm, style: .continuous)
                                    .fill(MP.C.brand.opacity(0.13)))
                            Text("Yazı boyutu")
                                .font(MP.F.bodyMD(.bold))
                                .foregroundStyle(MP.C.textTitle)
                            Spacer(minLength: 0)
                        }
                        MPWrapRow(spacing: 10) {
                            ForEach(MP.ReadSize.allCases) { size in
                                MPChip(title: size.rawValue, isSelected: settings.readSize == size) {
                                    settings.readSize = size
                                    // Okuyucu oturum durumundan okuyor; ikisi
                                    // birlikte değişmezse ayar bir sonraki
                                    // açılışa kadar görünmez kalır.
                                    app.readSize = size
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)

                    MPRowDivider()
                    MPListRow(symbol: "speaker.wave.2", title: "Sesli okuma") {
                        MPSwitch(isOn: $settings.readAloud, label: "Sesli okuma")
                    }
                }
            }
        }
    }

    // MARK: - Bildirimler ve limitler

    /// Bu bölümdeki üç anahtarın üçü de hiçbir şey yapmıyordu: `reminder` ve
    /// `screenLimit` kodun hiçbir yerinde okunmuyordu, `approve` ise yalnızca
    /// Ebeveyn panelindeki kuyruğu açıyor, masalı gizlemiyordu. Üçü de
    /// varsayılan olarak AÇIK geliyordu — yani uygulama, hiç sormadan üç şey
    /// vaat edip üçünü de yapmıyordu.
    private var notificationsSection: some View {
        section(title: "Bildirimler ve limitler") {
            MPListRow(symbol: "bell", title: "Masal saati hatırlatması",
                      description: reminderDescription) {
                MPSwitch(isOn: Binding(
                    get: { settings.reminder && !notificationsDenied },
                    set: { on in setReminder(on) }
                ), label: "Masal saati hatırlatması")
            }

            if notificationsDenied {
                MPRowDivider()
                MPListRow(symbol: "exclamationmark.triangle",
                          iconColor: MP.C.danger,
                          title: "Bildirimlere izin verilmedi",
                          description: "Sistem Ayarları'ndan açabilirsiniz",
                          action: { openSystemSettings() })
            } else if settings.reminder {
                MPRowDivider()
                MPListRow(symbol: "clock", title: "Hatırlatma saati") {
                    DatePicker("", selection: reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }

            MPRowDivider()
            MPListRow(symbol: "eye.slash", title: "Masalları onaylamadan gösterme",
                      description: settings.approve
                        ? "Yeni masallar siz onaylayana kadar kütüphanede görünmez"
                        : nil) {
                MPSwitch(isOn: Binding(
                    get: { settings.approve },
                    set: { on in setApproval(on) }
                ), label: "Masalları onaylamadan gösterme")
            }

            MPRowDivider()
            MPListRow(symbol: "hourglass", title: "Ekran süresi limiti",
                      description: settings.screenLimit
                        ? "Günde \(settings.screenLimitMinutes) dakika okuma"
                        : nil) {
                MPSwitch(isOn: $settings.screenLimit, label: "Ekran süresi limiti")
            }

            if settings.screenLimit {
                MPRowDivider()
                MPWrapRow(spacing: 10) {
                    ForEach(MPReadingBudget.choices, id: \.self) { minutes in
                        MPChip(title: "\(minutes) dk",
                               isSelected: settings.screenLimitMinutes == minutes) {
                            settings.screenLimitMinutes = minutes
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
        }
    }

    private var reminderDescription: String {
        guard settings.reminder, !notificationsDenied else { return "Kapalı" }
        return "Her akşam \(MPReminder.clockLabel(hour: settings.reminderHour, minute: settings.reminderMinute))"
    }

    /// DatePicker saat/dakika ile çalışır; sakladığımız şey iki sayı.
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents()
                c.hour = settings.reminderHour
                c.minute = settings.reminderMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                settings.reminderHour = c.hour ?? 20
                settings.reminderMinute = c.minute ?? 30
                guard settings.reminder else { return }
                let (h, m, who) = (settings.reminderHour, settings.reminderMinute, childName)
                Task { @MainActor in
                    _ = await MPReminder.enable(hour: h, minute: m, childName: who)
                }
            }
        )
    }

    private var childName: String? { profileManager.currentProfile?.name }

    /// İzin tam burada isteniyor: ebeveyn ne için olduğunu okuyup anahtara
    /// dokunduğu anda. Açılışta, ortada hiçbir masal yokken değil.
    private func setReminder(_ on: Bool) {
        guard on else {
            settings.reminder = false
            MPReminder.disable()
            return
        }
        Task { @MainActor in
            let result = await MPReminder.enable(hour: settings.reminderHour,
                                                 minute: settings.reminderMinute,
                                                 childName: childName)
            switch result {
            case .scheduled:
                settings.reminder = true
                notificationsDenied = false
                app.showToast("Her akşam \(MPReminder.clockLabel(hour: settings.reminderHour, minute: settings.reminderMinute)) hatırlatılacak",
                              symbol: "bell")
            case .denied:
                settings.reminder = false
                notificationsDenied = true
            }
        }
    }

    private func setApproval(_ on: Bool) {
        settings.approve = on
        guard on else { return }
        // Kapı ileriye doğru çalışır — açıklaması `approveStories` üzerinde.
        settings.approveStories(storyManager.stories.map(\.id))
        app.showToast("Yeni masallar onayınızı bekleyecek", symbol: "eye.slash")
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
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
        // `mp_readSeconds` was missing here: "delete all data" cleared the reading
        // *days* but left the reading *time* ledger behind, so the parent panel
        // kept showing minutes for a profile that no longer existed.
        for key in ["stories", "user_profiles", "current_profile_id",
                    "mp_favoriteStoryIDs", "mp_readDays", "mp_readSeconds",
                    "mp_approvedStoryIDs"] {
            d.removeObject(forKey: key)
        }
        // Reading ledgers are per child now; their keys carry the profile id,
        // so they cannot be listed above.
        MPStreak.eraseAllLedgers(in: d)
        dismiss()
    }
}

import SwiftUI
import StoreKit

/// 32 · Ebeveyn · Ayarlar (`Ayarlar`).
///
/// Gruplanmış liste: çocuk profilleri, aile ve ses, bildirimler, okuma,
/// hesap, destek, hesabı sil. Çocuk profilleri eski "Çocuklar" sekmesinden
/// buraya geldi (FAZ 17). Henüz altyapısı olmayan satırlar (Aile üyeleri,
/// Kendi sesin, Haftalık özet) `FamilyFeatureAccess` kapalıyken görünmez.
struct SettingsView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @Environment(\.requestReview) private var requestReview
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var account = AccountService.shared
    @State private var showPrivacy = false
    @State private var confirmDelete = false
    @State private var confirmClear = false
    @State private var exportFile: MPExportFile?
    @State private var isExporting = false
    @State private var interestChoices: [InterestChoice] = []
    /// iOS bildirimi reddettiyse anahtar açık kalamaz; ekran bunu söylemek
    /// zorunda, yoksa ebeveyn açık bir anahtara bakıp hiç bildirim almaz.
    @State private var notificationsDenied = false
    #if DEBUG
    @State private var illustratedBooks = IllustratedBookAccess.isEnabled()
    @State private var ideaStep = StoryIdeaStepAccess.isEnabled()
    @State private var familyFlags: [FamilyFeature: Bool] = Dictionary(
        uniqueKeysWithValues: FamilyFeature.allCases.map { ($0, FamilyFeatureAccess.isEnabled($0)) })
    #endif

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                MPParentHeader(title: "Ayarlar")
                    .padding(.horizontal, -MPSpacing.screenH)
                profilesSection
                if showsFamilySection { familySection }
                notificationsSection
                readingSection
                accountSection
                supportSection
                deleteSection
                #if DEBUG
                developerSection
                #endif
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .fullScreenCover(isPresented: $showPrivacy) { PrivacyAndDataView() }
        .sheet(item: $exportFile) { file in ShareSheet(items: [file.url]) }
        .overlay {
            if confirmDelete { AccountDeletionSheet(onClose: { confirmDelete = false }) }
        }
        .confirmationDialog("Tüm verileri sil", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Sil", role: .destructive) {
                LocalDataEraser.eraseFamilyData(keepingOnboarding: true)
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Masallar, profiller ve okuma ilerlemen cihazdan kaldırılır. Bu işlem geri alınamaz.")
        }
        .onAppear { interestChoices = StoryChoiceSources.current.interestChoices() }
        // Ekranı açtığında gerçeği göster: izin Sistem Ayarları'ndan geri
        // alınmış olabilir ve bizim anahtarımız bunu bilmiyor.
        .task {
            guard settings.reminder else { return }
            notificationsDenied = await !MPReminder.isAuthorised()
        }
    }

    // MARK: - Çocuk profilleri

    private static let profileTones: [MPWorldTone] = [.green, .pink, .sky, .yellow, .lav, .mint]

    private var profilesSection: some View {
        ParentSection(title: "Çocuk profilleri") {
            ForEach(Array(profileManager.profiles.enumerated()), id: \.element.id) { index, profile in
                if index > 0 { MPRowDivider(area: .parent) }
                ParentRowButton(systemImage: "person",
                                tone: Self.profileTones[index % Self.profileTones.count],
                                title: profile.name,
                                subtitle: profileLine(profile)) {
                    app.sheet = .profileEdit(profile.id)
                }
            }
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "plus", tone: .sky, title: "Profil ekle") {
                app.showProfileAdd = true
            }
        }
    }

    /// "5-6 yaş · Hayvanlar, Doğa" ya da ilgi alanı yoksa "5-6 yaş · 3 masal".
    private func profileLine(_ profile: UserProfile) -> String {
        let age = "\(profile.mpAgeRange.shortLabel) yaş"
        if ChildInterests.isShown(interestChoices) {
            let offered = Set(ChildInterests.offered(profile.interests, from: interestChoices))
            let names = interestChoices.filter { offered.contains($0.id) }.map(\.name)
            if !names.isEmpty { return "\(age) · \(names.joined(separator: ", "))" }
        }
        let count = storyManager.stories.filter { $0.isReadable && $0.belongs(to: profile) }.count
        return "\(age) · \(count) masal"
    }

    // MARK: - Aile ve ses (FAZ 18, bayrakta)

    private var showsFamilySection: Bool {
        FamilyFeatureAccess.isEnabled(.familyMembers) || FamilyFeatureAccess.isEnabled(.voiceRecording)
    }

    private var familySection: some View {
        ParentSection(title: "Aile ve ses") {
            if FamilyFeatureAccess.isEnabled(.familyMembers) {
                ParentRowButton(systemImage: "person.2", tone: .sky, title: "Aile üyeleri",
                                subtitle: "Davet et, birlikte okuyun") { app.parentRoute = .familyMembers }
            }
            if FamilyFeatureAccess.isEnabled(.familyMembers) && FamilyFeatureAccess.isEnabled(.voiceRecording) {
                MPRowDivider(area: .parent)
            }
            if FamilyFeatureAccess.isEnabled(.voiceRecording) {
                ParentRowButton(systemImage: "mic", tone: .lav, title: "Kendi sesin",
                                subtitle: "Masalları senin sesinle okusun") { app.parentRoute = .voiceRecording }
            }
        }
    }

    // MARK: - Bildirimler

    private var notificationsSection: some View {
        ParentSection(title: "Bildirimler") {
            ParentToggleRow(systemImage: "bell", tone: .yellow, title: "Masal saati hatırlatması",
                            subtitle: reminderDescription,
                            isOn: Binding(get: { settings.reminder && !notificationsDenied },
                                          set: setReminder))
            if notificationsDenied {
                MPRowDivider(area: .parent)
                ParentRowButton(systemImage: "exclamationmark.triangle", tone: .pink,
                                title: "Bildirimlere izin verilmedi",
                                subtitle: "Sistem Ayarları'ndan açabilirsin", action: openSystemSettings)
            } else if settings.reminder {
                MPRowDivider(area: .parent)
                MPListRow(systemImage: "clock", tone: .yellow, title: "Hatırlatma saati") {
                    DatePicker("Hatırlatma saati", selection: reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(MPColor.actionPrimary)
                }
            }
            if FamilyFeatureAccess.isEnabled(.weeklyEmail) {
                MPRowDivider(area: .parent)
                ParentToggleRow(systemImage: "envelope", tone: .sky, title: "Haftalık özet e-postası",
                                subtitle: "Pazar sabahları", isOn: .constant(false))
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
    /// dokunduğu anda.
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

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Okuma

    private var readingSection: some View {
        ParentSection(title: "Okuma") {
            VStack(alignment: .leading, spacing: MPSpacing.md) {
                Text("Yazı boyutu").mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                MPFlowLayout(spacing: MPSpacing.sm) {
                    ForEach(MP.ReadSize.allCases) { size in
                        MPChip(title: size.rawValue, isSelected: settings.readSize == size) {
                            settings.readSize = size
                            // Okuyucu oturum durumundan okuyor; ikisi birlikte
                            // değişmezse ayar bir sonraki açılışa kadar görünmez.
                            app.readSize = size
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MPSpacing.lg)
            MPRowDivider(area: .parent)
            ParentToggleRow(systemImage: "speaker.wave.2", tone: .mint, title: "Sesli okuma",
                            subtitle: "Masal sayfaları sesli okunur", isOn: $settings.readAloud)
        }
    }

    // MARK: - Hesap

    private var accountSection: some View {
        ParentSection(title: "Hesap") {
            AccountStatusRows(onSignOut: { app.sheet = .signOut })
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "crown", tone: .yellow, title: "Abonelik",
                            subtitle: subscriptionManager.isPremium ? "Hikaye Kahramanı" : "Ücretsiz plan") {
                app.openPaywall()
            }
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "lock", tone: .gray, title: "Gizlilik ve veri",
                            subtitle: "Ne tuttuğumuz, nasıl sildiğimiz") { showPrivacy = true }
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "arrow.down.circle", tone: .green, title: "Masal kitabı",
                            subtitle: isExporting ? "PDF hazırlanıyor" : "Masalların PDF kitap olarak") {
                exportBook()
            }
        }
    }

    /// Kitaplıktaki masalları tek bir PDF kitapta toplar (35 · Masal kitabı'nın
    /// PDF yolu; basılı kitap iş modeli kararına kadar yok).
    private func exportBook() {
        guard !isExporting, !storyManager.stories.isEmpty else { return }
        isExporting = true
        let snapshot = storyManager.stories
        Task.detached(priority: .userInitiated) {
            let url = await MPStoryPDF.makePDF(stories: snapshot, fileName: "magicpaper-masallar.pdf")
            await MainActor.run {
                isExporting = false
                if let url {
                    exportFile = MPExportFile(url: url)
                } else {
                    app.showToast("PDF oluşturulamadı", symbol: "xmark", tone: .danger)
                }
            }
        }
    }

    // MARK: - Destek

    private var supportSection: some View {
        ParentSection(title: "Destek") {
            ParentRowButton(systemImage: "message", tone: .lav, title: "Bize yaz") {
                if let url = URL(string: "mailto:support@magicpaperkids.com") { UIApplication.shared.open(url) }
            }
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "star", tone: .yellow, title: "Uygulamayı değerlendir") {
                requestReview()
            }
        }
    }

    // MARK: - Hesabı sil

    /// Giriş yapılmışken yalnız cihazı silmek eşitlemeyle geri gelirdi; gerçek
    /// silme hesabınki (FAZ 16).
    private var deleteSection: some View {
        MPGroupedList(area: .parent) {
            ParentRowButton(systemImage: "trash", title: account.account != nil
                                ? "Hesabı ve tüm verileri sil" : "Tüm verileri sil",
                            subtitle: "Geri alınamaz", isDestructive: true) {
                if account.account != nil { confirmDelete = true } else { confirmClear = true }
            }
        }
    }

    // MARK: - Geliştirici
    //
    // Yalnızca DEBUG derlemesinde görünür. Yayınlanan uygulamada satın almayı
    // baypas eden bir yol bulunmamalı.

    #if DEBUG
    private var developerSection: some View {
        ParentSection(title: "Geliştirici", subtitle: "Yalnızca test derlemesinde görünür") {
            ParentToggleRow(systemImage: "sparkles", title: "Görselli kitap (B2)",
                            subtitle: "Kitap karakteri ve hazır sahneler",
                            isOn: Binding(get: { illustratedBooks },
                                          set: { illustratedBooks = $0; IllustratedBookAccess.setDeveloperFlag($0) }))
            MPRowDivider(area: .parent)
            ParentToggleRow(systemImage: "sparkles", title: "Fikir kartları adımı",
                            subtitle: "Moddan sonra isteğe bağlı fikir kartları",
                            isOn: Binding(get: { ideaStep },
                                          set: { ideaStep = $0; StoryIdeaStepAccess.setDeveloperFlag($0) }))
            ForEach(FamilyFeature.allCases, id: \.self) { feature in
                MPRowDivider(area: .parent)
                ParentToggleRow(systemImage: "person.2", tone: .sky, title: feature.title,
                                subtitle: "FAZ 18 ekranı (bayrak)",
                                isOn: Binding(get: { familyFlags[feature] ?? false },
                                              set: { familyFlags[feature] = $0; FamilyFeatureAccess.setDeveloperFlag(feature, $0) }))
            }
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "clock", title: SeriesCopy.debugAdvance,
                            subtitle: "Seri bölümünü simülatörde açmak için") {
                let key = SeriesClock.debugDayOffsetKey
                UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
                if let id = ProfileManager.shared.currentProfile?.id {
                    SeriesManager.shared.refreshUnlocks(for: id)
                }
                app.showToast("Seri saati +1 gün", symbol: "clock")
            }
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "clock", tone: .gray, title: SeriesCopy.debugReset) {
                UserDefaults.standard.removeObject(forKey: SeriesClock.debugDayOffsetKey)
                UserDefaults.standard.removeObject(forKey: SeriesClock.highWaterKey)
                app.showToast("Seri saati sıfırlandı", symbol: "clock")
            }
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "book", tone: .green, title: "Dekorasyon galerisi",
                            subtitle: "Varlık kataloğu, kürasyon durumu, ortam kapsamı") {
                app.showDecorationGallery = true
            }
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "sparkles", title: "Dekorasyon demoları",
                            subtitle: "Orman · Deniz · Uyku · Macera, debug katmanıyla") {
                app.showDecorationDemo = true
            }
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "crown", tone: .yellow,
                            title: subscriptionManager.isPremium ? "Aboneliği kapat" : "Aboneliği aç",
                            subtitle: subscriptionManager.isPremium ? "Ücretsiz plana döner" : "Hikaye Kahramanı planını açar") {
                if subscriptionManager.isPremium {
                    subscriptionManager.cancelSubscription()
                    app.showToast("Abonelik kapatıldı", symbol: "crown.fill")
                } else {
                    subscriptionManager.purchaseSubscription(tier: .premium)
                    app.showToast("Premium açıldı, iyi masallar", symbol: "crown.fill", tone: .reward)
                }
            }
        }
    }
    #endif
}

// MARK: - Gizlilik ve veri
//
// Tasarımda tek satır olarak geçiyor. Eski Ayarlar ekranındaki "tüm verileri
// sil" ve yasal bağlantılar App Store uyumluluğu için gerekli olduğundan
// bu satırın altına taşındı.

struct PrivacyAndDataView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = MPSettingsStore.shared
    @ObservedObject private var account = AccountService.shared
    @State private var confirmClear = false
    @State private var confirmDelete = false

    var body: some View {
        VStack(spacing: 0) {
            MPNavBar(title: "Gizlilik ve veri", onBack: { dismiss() })

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    LegacyMPCard(padding: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Çocuk fotoğrafı toplanmaz")
                                .font(MP.F.displaySM())
                                .foregroundStyle(MP.C.textTitle)
                            Text("Profiller ve masallar cihazınızda ve yalnızca sizin erişebildiğiniz ebeveyn hesabınızda saklanır. Çocuk fotoğrafı hiçbir yere gönderilmez.")
                                .font(MP.F.bodyMD())
                                .lineSpacing(16 * 0.55)
                                .foregroundStyle(MP.C.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        LegacyMPSectionHeader(title: "Yasal")
                        LegacyMPCard(padding: 0) {
                            VStack(spacing: 0) {
                                LegacyMPListRow(symbol: "shield", title: "Gizlilik politikası", action: {
                                    open("https://magicpaper.app/privacy")
                                })
                                LegacyMPRowDivider()
                                LegacyMPListRow(symbol: "book", title: "Kullanım koşulları", action: {
                                    open("https://magicpaper.app/terms")
                                })
                            }
                        }
                    }

                    usageSection

                    VStack(alignment: .leading, spacing: 16) {
                        LegacyMPSectionHeader(title: "Veriler")
                        LegacyMPCard(padding: 0) {
                            // Signed in, a device-only erase would come back
                            // with the next sync: the real erase is the
                            // account's (FAZ 16).
                            if account.account != nil {
                                LegacyMPListRow(symbol: "trash", title: AccountCopy.deleteAccount,
                                          description: AccountCopy.deleteAccountRow,
                                          isDanger: true,
                                          action: { confirmDelete = true })
                            } else {
                                LegacyMPListRow(symbol: "trash", title: "Tüm verileri sil",
                                          description: "Masallar ve profiller cihazdan kaldırılır",
                                          isDanger: true,
                                          action: { confirmClear = true })
                            }
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
            if confirmDelete {
                AccountDeletionSheet(onClose: { confirmDelete = false })
            }
        }
        // The account is gone: this screen and the parent area close with it.
        .onChange(of: account.account == nil) { _, signedOut in
            if signedOut && confirmDelete { confirmDelete = false; dismiss() }
        }
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
                        LegacyMPButton(title: "Sil", tone: .play, size: .lg, fullWidth: true) {
                            confirmClear = false
                            clearAll()
                        }
                        LegacyMPButton(title: "Vazgeç", variant: .ghost, size: .sm) {
                            confirmClear = false
                        }
                    }
                }
            }
        }
    }

    /// Anonim okuma bilgisi (FAZ 14). Kapatmak bekleyenleri de siler.
    /// Çocuğun kendi okuma kaydı — sıradaki masalın ona göre seçilmesi —
    /// cihazda kalır ve bu anahtardan etkilenmez.
    private var usageSection: some View {
        VStack(alignment: .leading, spacing: MP.S.x4) {
            LegacyMPSectionHeader(title: "Okuma bilgisi")
            LegacyMPCard(padding: 0) {
                LegacyMPListRow(symbol: "eye.slash", title: "Okuma bilgisini paylaş",
                          description: "Hangi masalların bitirildiği; ad, yaş, hesap ve cihaz bilgisi olmadan, hesabınıza bağlanmadan. Masalları iyileştirmek için. Kapatınca bekleyen bilgiler silinir.") {
                    MPSwitch(isOn: $settings.shareUsageData, label: "Okuma bilgisini paylaş")
                }
            }
        }
    }

    private func open(_ url: String) {
        guard let u = URL(string: url) else { return }
        UIApplication.shared.open(u)
    }

    private func clearAll() {
        // One list of what "everything" is, shared with signing out and
        // deleting the account (FAZ 16).
        LocalDataEraser.eraseFamilyData(keepingOnboarding: true)
        dismiss()
    }
}

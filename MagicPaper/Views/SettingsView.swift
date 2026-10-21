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
    @State private var interestChoices: [InterestChoice] = []
    /// iOS bildirimi reddettiyse anahtar açık kalamaz; ekran bunu söylemek
    /// zorunda, yoksa ebeveyn açık bir anahtara bakıp hiç bildirim almaz.
    @State private var notificationsDenied = false
    /// Haftalık özet (FAZ 18): sunucudaki ayar; açılışta okunur.
    @State private var weeklyEmail = false
    #if DEBUG
    @State private var illustratedBooks = IllustratedBookAccess.isEnabled()
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
        .fullScreenCover(isPresented: $confirmDelete) {
            AccountDeletionSheet(onClose: { confirmDelete = false })
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
            guard FamilyFeatureAccess.isEnabled(.weeklyEmail), account.isFounder, let familyID = account.familyID else { return }
            weeklyEmail = (try? await FirestoreWeeklyEmailRemote().isEnabled(familyID: familyID)) ?? false
        }
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
            if account.canWriteFamily {
                MPRowDivider(area: .parent)
                ParentRowButton(systemImage: "plus", tone: .sky, title: "Profil ekle") {
                    app.showProfileAdd = true
                }
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
                                subtitle: account.isFounder ? "Davet et, birlikte okuyun" : (account.role.map { "\($0.title) olarak katıldın" } ?? "")) { app.parentRoute = .familyMembers }
            }
            if FamilyFeatureAccess.isEnabled(.familyMembers) && FamilyFeatureAccess.isEnabled(.voiceRecording) {
                MPRowDivider(area: .parent)
            }
            if FamilyFeatureAccess.isEnabled(.voiceRecording) {
                ParentRowButton(systemImage: "mic", tone: .lav, title: "Kendi sesin",
                                subtitle: VoiceCopy.settingsLine(VoiceRecordingStore.shared.recordedStoryCount)) { app.parentRoute = .voiceRecording }
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
            if FamilyFeatureAccess.isEnabled(.weeklyEmail) && account.account != nil {
                MPRowDivider(area: .parent)
                ParentToggleRow(systemImage: "envelope", tone: .sky, title: WeeklyEmailCopy.title,
                                subtitle: WeeklyEmailCopy.subtitle(enabled: weeklyEmail, email: account.accountEmail,
                                                                   isFounder: account.isFounder),
                                isOn: Binding(get: { weeklyEmail }, set: setWeeklyEmail))
                    .disabled(!account.isFounder || account.accountEmail == nil)
            }
        }
    }

    /// Haftalık özeti açar ya da kapatır; adres hesabın e-postası.
    private func setWeeklyEmail(_ on: Bool) {
        guard account.isFounder, let familyID = account.familyID, let email = account.accountEmail else { return }
        let previous = weeklyEmail
        weeklyEmail = on
        Task { @MainActor in
            do {
                try await FirestoreWeeklyEmailRemote().set(enabled: on, email: email,
                                                           timeZone: TimeZone.current.identifier, familyID: familyID)
                if on { app.showToast("Pazar sabahları özet gelecek", symbol: "envelope") }
            } catch {
                weeklyEmail = previous
                app.showToast(FamilyCopy.failed, symbol: "xmark", tone: .danger)
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
            ParentRowButton(systemImage: "book", tone: .green, title: "Masal kitabı",
                            subtitle: "PDF ya da basılı kitap") {
                app.parentRoute = .bookExport
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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                ParentHeader(title: "Gizlilik ve veri", onBack: { dismiss() })

                MPCard(area: .parent, padding: MPSpacing.lg) {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text("Çocuk fotoğrafı toplanmaz").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        Text("Profiller ve masallar cihazında ve yalnızca senin erişebildiğin ebeveyn hesabında saklanır. Çocuk fotoğrafı hiçbir yere gönderilmez.")
                            .mpText(.footnote).fontWeight(.regular)
                            .foregroundStyle(MPColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ParentSection(title: "Yasal") {
                    ParentRowButton(systemImage: "shield", tone: .lav, title: "Gizlilik politikası") {
                        open("https://magicpaper.app/privacy")
                    }
                    MPRowDivider(area: .parent)
                    ParentRowButton(systemImage: "book", tone: .sky, title: "Kullanım koşulları") {
                        open("https://magicpaper.app/terms")
                    }
                }

                // Anonim okuma bilgisi (FAZ 14). Kapatmak bekleyenleri de
                // siler. Çocuğun kendi okuma kaydı cihazda kalır.
                ParentSection(title: "Okuma bilgisi") {
                    ParentToggleRow(systemImage: "eye.slash", tone: .gray, title: "Okuma bilgisini paylaş",
                                    subtitle: "Hangi masalların bitirildiği; ad, yaş, hesap ve cihaz bilgisi olmadan. Kapatınca bekleyen bilgiler silinir.",
                                    isOn: $settings.shareUsageData)
                }

                ParentSection(title: "Veriler") {
                    // Signed in, a device-only erase would come back with the
                    // next sync: the real erase is the account's (FAZ 16).
                    if account.account != nil {
                        ParentRowButton(systemImage: "trash", tone: .pink, title: AccountCopy.deleteAccount,
                                        subtitle: AccountCopy.deleteAccountRow) { confirmDelete = true }
                    } else {
                        ParentRowButton(systemImage: "trash", tone: .pink, title: "Tüm verileri sil",
                                        subtitle: "Masallar ve profiller cihazdan kaldırılır") { confirmClear = true }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .fullScreenCover(isPresented: $confirmDelete) {
            AccountDeletionSheet(onClose: { confirmDelete = false })
        }
        // The account is gone: this screen and the parent area close with it.
        .onChange(of: account.account == nil) { _, signedOut in
            if signedOut && confirmDelete { confirmDelete = false; dismiss() }
        }
        .confirmationDialog("Tüm verileri sil", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Sil", role: .destructive, action: clearAll)
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Masallar, profiller ve okuma ilerlemen cihazdan kaldırılır. Bu işlem geri alınamaz.")
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

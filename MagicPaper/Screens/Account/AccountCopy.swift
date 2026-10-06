import Foundation

/// Hesap ekranlarının metni (FAZ 16). İrem'in gözden geçirmesini bekliyor.
enum AccountCopy {
    // Giriş
    static let signInTitle = "Ebeveyn hesabı"
    static let signInBody = "Masallar ve profiller hesabınızda saklanır; telefon değişse de kaybolmaz. Çocuğunuz giriş yapmaz."
    static let continueWithApple = "Apple ile devam et"
    static let continueWithGoogle = "Google ile devam et"
    static let emulatorSignIn = "Test hesabıyla gir (emülatör)"
    static let signInFootnote = "E-posta adresiniz ve adınız MagicPaper tarafından saklanmaz."
    static let offlineMessage = "İnternet bağlantısı yok. Bağlanınca tekrar deneyin."
    static let failedMessage = "Giriş yapılamadı. Biraz sonra tekrar deneyin."
    static let googleUnavailable = "Google ile giriş bu sürümde henüz açık değil."
    static let deferSignIn = "Şimdilik masallara dön"
    static let deferFootnote = "Masallarınız cihazda. Bağlantı gelince giriş yapabilirsiniz."

    // Onay
    static let usageRowTitle = "Okuma bilgisini paylaş"
    static let usageRowBody = "Hangi masalların bitirildiği; ad, yaş ve hesap bilgisi olmadan."
    static let agreeLabel = "Onaylıyorum"
    static let agreeButton = "Onayla ve devam et"
    static func versionLine(_ version: String) -> String { "Onay metni sürümü: \(version)" }

    // Geri yükleme
    static let restoringTitle = "Masallarınız getiriliyor"
    static let restoringBody = "Hesabınızdaki profiller ve masallar bu cihaza geliyor."
    static let restoreFailedTitle = "Şu an getirilemedi"
    static let restoreFailedBody = "İnternet bağlantısı gelince masallarınız kendiliğinden gelir."
    static let retry = "Tekrar dene"
    static let startFresh = "Yeni profil oluştur"

    // Ayarlar
    static func signedIn(with provider: SignInProvider) -> String {
        switch provider {
        case .apple: return "Apple ile giriş yapıldı"
        case .google: return "Google ile giriş yapıldı"
        case .emulator: return "Test hesabı (emülatör)"
        }
    }
    static let notSignedIn = "Giriş yapılmadı"
    static let syncing = "Eşitleniyor"
    static let syncOffline = "İnternet yok; değişiklikler cihazda bekliyor"
    static let syncFailed = "Eşitlenemedi; daha sonra yeniden denenecek"
    static let syncIdle = "Eşitlemek için dokunun"
    static func synced(at time: String) -> String { "Son eşitleme \(time)" }

    static let signOut = "Çıkış yap"
    static let signOutBody = "Bu cihazdaki profiller ve masallar kaldırılır; hepsi hesabınızda kalır. Tekrar giriş yapınca geri gelir."
    static let signOutUnsent = "Bu cihazda hesaba henüz gitmemiş değişiklikler var. İnternete bağlanınca tekrar deneyin."

    static let deleteAccount = "Hesabı sil"
    static let deleteAccountRow = "Hesap ve sunucudaki bütün bilgiler kalıcı olarak silinir"
    static let deleteAccountBody = "Hesabınız, çocuk profilleri, masallar, seriler ve okuma ilerlemesi sunucudan ve bu cihazdan kalıcı olarak silinir. Bu işlem geri alınamaz. Devam etmek için bir kez daha giriş yapmanız istenecek."
    static let deleteConfirm = "Hesabı kalıcı olarak sil"
    static let deleteFailed = "Hesap silinemedi. İnternet bağlantınızı kontrol edip tekrar deneyin."
    static func deletionStep(_ step: AccountService.DeletionStep) -> String {
        switch step {
        case .reauthenticating: return "Giriş doğrulanıyor"
        case .deletingData: return "Sunucudaki bilgiler siliniyor"
        case .deletingAccount: return "Hesap siliniyor"
        case .erasingDevice: return "Cihazdaki bilgiler siliniyor"
        }
    }

    static func message(for error: Error) -> String? {
        switch error as? AccountError {
        case .cancelled: return nil
        case .offline: return offlineMessage
        case .googleUnavailable: return googleUnavailable
        case .unsentChanges: return signOutUnsent
        default: return failedMessage
        }
    }
}

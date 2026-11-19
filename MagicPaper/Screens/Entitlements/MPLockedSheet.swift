import SwiftUI

/// Çocuk alanında kapalı bir şeye dokunulunca açılan sakin pencere (E7,
/// karar: Batuhan 19 Kasım 2026).
///
/// Satış yapmaz: sayı, geri sayım, fiyat yok. Paywall yalnızca ebeveyn
/// kapısının arkasında açılır ("Büyüklere göster" → kapı → paywall).
/// Ücretsiz günün masalı yazıldıysa bekleme metni yarına bakar, saate değil.
struct MPLockedSheet: View {
    let capability: Capability
    @EnvironmentObject private var app: MPAppState

    var body: some View {
        MPSheet(onClose: close) {
            VStack(alignment: .leading, spacing: MP.S.x4) {
                MascotSays(mascot: copy.mascot, text: copy.ragi, mascotWidth: 72)
                Text(copy.title)
                    .font(MP.F.displaySM())
                    .foregroundStyle(MP.C.textTitle)
                    .accessibilityAddTraits(.isHeader)
                Text(copy.message)
                    .mpText(.body)
                    .foregroundStyle(MP.C.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } footer: {
            VStack(spacing: MP.S.x2) {
                if isDailyLimit {
                    MPButton(title: "Kitaplığa bak", fullWidth: true) {
                        app.router.closeSheet { app.router.tab = .library }
                    }
                    MPButton(title: "Büyükler için", kind: .ghost, fullWidth: true, action: showParents)
                } else {
                    MPButton(title: "Büyüklere göster", fullWidth: true, action: showParents)
                    MPButton(title: "Şimdi değil", kind: .ghost, fullWidth: true, action: close)
                }
            }
        }
    }

    private var isDailyLimit: Bool { capability == .unlimitedTextStories }

    private func close() { app.router.sheet = nil }

    /// Sheet kapanır, sonra kapı, sonra paywall: üst üste modal açılmaz.
    private func showParents() {
        app.router.closeSheet {
            app.router.requestGate { app.openPaywall() }
        }
    }

    private var copy: MPLockedCopy { MPLockedCopy(capability) }
}

/// Kilit penceresinin sözleri. Görünümden ayrı ki testte okunabilsin.
struct MPLockedCopy: Equatable {
    let mascot: Mascot
    let ragi: String
    let title: String
    let message: String

    init(_ capability: Capability) {
        switch capability {
        case .unlimitedTextStories, .unlimitedDailyStories, .illustratedStory, .longStories:
            mascot = .sleepy
            ragi = "Bugün güzel bir masal yazdık."
            title = "Bugünün masalı yazıldı"
            message = "Yarın yeni bir masal yazabiliriz. O zamana kadar kitaplıktaki masallar seni bekliyor."
        case .classicLibrary:
            mascot = .reading
            ragi = "Bu masal büyüklerle açılır."
            title = "Büyüklerle açılan bir masal"
            message = "Bu masalı birlikte açmak için bir büyüğe göster."
        case .seriesStories:
            mascot = .reading
            ragi = "Masalın devamı büyüklerle açılır."
            title = "Masalın devamı"
            message = "Serinin sonraki bölümleri için bir büyüğe göster."
        case .familyCast:
            mascot = .waving
            ragi = "Masal ailene yeni biri büyüklerle katılır."
            title = "Masal ailem"
            message = "Ailenden bir kişi daha masala katmak için bir büyüğe göster."
        case .multipleChildren:
            mascot = .waving
            ragi = "Yeni bir arkadaş büyüklerle eklenir."
            title = "Yeni bir çocuk"
            message = "Kardeşini ya da bir arkadaşını eklemek için bir büyüğe göster."
        case .premiumWorlds, .premiumThemes:
            mascot = .curious
            ragi = "Bu dünya büyüklerle açılır."
            title = "Büyüklerle açılan bir dünya"
            message = "Bu dünyada masal yazmak için bir büyüğe göster."
        case .ownVoice, .pdfBook:
            mascot = .calm
            ragi = "Bunu büyükler açabilir."
            title = "Büyüklerle açılır"
            message = "Bunun için bir büyüğe göster."
        }
    }
}

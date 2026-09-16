import SwiftUI

/// Yaratma akışının kapak ekranı.
///
/// Kendi kapak düzeni yok: uygulamadaki tek kapak olan `StoryCover`'ı tam
/// sayfa gösterir ve altına tek bir eylem koyar. Eskiden burada kart içine
/// yerleştirilmiş ayrı bir kapak vardı; aynı masalın kapağı kapakta bir türlü,
/// okuyucuda başka türlü görünüyordu.
///
/// Artık kapaktan sayfaya geçiş, aynı kâğıdın üstünde aynı kapağın çevrilmesi.
struct StoryCoverView: View {

    let story: Story
    let childName: String
    let onOpen: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            StoryCover(story: story, childName: childName)

            MPButton(title: "Hikâyeyi Başlat", size: .lg, icon: "book", fullWidth: true) {
                onOpen()
            }
            .mpGutter()
            .padding(.bottom, MP.S.x5)
        }
        .accessibilityAction(named: "Hikâyeyi başlat", onOpen)
    }
}

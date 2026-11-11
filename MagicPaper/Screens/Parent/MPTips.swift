import SwiftUI
import TipKit

/// Ebeveyn alanının ipuçları (Faz 14, TipKit). En çok üç, yalnızca ebeveyn
/// alanında, haftada en fazla bir tane; çocuk alanında hiç ipucu yok.
/// Her biri yeni bir değeri bir kez anlatır, sonra bir daha görünmez.
enum MPTips {
    static func configure() {
        try? Tips.configure([.displayFrequency(.weekly)])
    }
}

/// Masal kitabı: yıllık sekmesi (Faz 12).
struct YearbookTip: Tip {
    var title: Text { Text("Yılın kitabı") }
    var message: Text? { Text("Yıllık sekmesi bu yılın bütün masallarını, gidilen yerleri ve dostları tek kitapta toplar.") }
    var image: Image? { Image(systemName: "calendar") }
}

/// Güvenlik: okuyucuda "Konuşalım" (Faz 11).
struct TalkPromptsTip: Tip {
    var title: Text { Text("Birlikte konuşalım") }
    var message: Text? { Text("Okurken birkaç sayfada size bir soru önerilir. Cevabı yok, kaydedilmez. İsterseniz buradan kapatabilirsiniz.") }
    var image: Image? { Image(systemName: "bubble.left.and.bubble.right") }
}

/// Ayarlar: akıllı hatırlatma (Faz 14).
struct SmartReminderTip: Tip {
    var title: Text { Text("Sakin hatırlatma") }
    var message: Text? { Text("Masal okunan akşam hatırlatma gelmez. Gelen bildirim o akşamın masalını söyler.") }
    var image: Image? { Image(systemName: "bell") }
}

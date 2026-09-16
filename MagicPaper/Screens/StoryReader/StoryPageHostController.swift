import SwiftUI
import UIKit

/// Tek bir yaprağı taşıyan denetleyici.
///
/// `UIPageViewController` sayfaları denetleyici olarak ister; bu, SwiftUI
/// sayfasının UIKit tarafındaki karşılığı. Taşıdığı tek ek bilgi kendi
/// indeksi — veri kaynağı "bundan önceki/sonraki hangisi" sorusunu yalnızca
/// bununla cevaplayabilir.
final class StoryPageHostController<Content: View>: UIHostingController<Content> {

    let leafIndex: Int

    init(leafIndex: Int, rootView: Content, paper: UIColor) {
        self.leafIndex = leafIndex
        super.init(rootView: rootView)

        // Yaprak opak olmak zorunda. Kıvrım sayfanın *arkasını* gösterir;
        // saydam bir sayfa kıvrıldığında arkasındaki her ne varsa görünür ve
        // hata gibi okunur.
        view.backgroundColor = paper
        view.isOpaque = true

        // Güvenli alan bilerek sıfırlanmıyor.
        //
        // Önce `safeAreaRegions = []` denendi ve metin Dynamic Island'ın
        // altında kaldı: bölge sıfırlanınca `GeometryReader`'ın okuduğu
        // `safeAreaInsets` de sıfırlanıyor, yani boşluğu geri eklemek için
        // okunacak bir değer kalmıyor. Kâğıdın baştan başa uzanmasını
        // `ReaderPaper`ın kendi `ignoresSafeArea`sı sağlıyor; metin ise
        // güvenli alanın içinde kalıyor — olması gereken de bu.
    }

    @available(*, unavailable)
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) kullanılmıyor")
    }
}

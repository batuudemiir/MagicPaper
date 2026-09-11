import SwiftUI
import UIKit

/// `UIActivityViewController` sarmalayıcısı.
/// StoryViewerView ve TextOnlyStoryViewerView bu tipi çağırıyordu ama projede
/// hiçbir yerde tanımlı değildi — eksik tanım burada tamamlandı.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

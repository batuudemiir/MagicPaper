import SwiftUI

/// Kaydırılan bir sayfada saat çubuğunun arkası. Sayfa tepedeyken görünmez;
/// içerik saat çubuğunun altına girince sayfanın zemin rengiyle dolar, yazı
/// saatin arkasından geçmez. Günlük'te doğdu (`GunlukStatusBarBackdrop`),
/// 23 Ekim 2026'da çocuk sekmelerinin hepsine taşındı.
///
/// Kullanım: kaydırma içeriğinin ilk kabına `.mpTracksScroll($scrolled)`,
/// kaydırma görünümüne `.overlay(alignment: .top) { MPStatusBarBackdrop(visible: scrolled) }`.
struct MPStatusBarBackdrop: View {
    let visible: Bool
    /// Sayfanın zemini; ayrı bir şerit gibi durmasın.
    var fill: Color = MPColor.backgroundKid
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Sıfır yükseklikli şerit güvenli alanın tepesinde durur; zemini
        // saat çubuğunun arkasına uzanır.
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: 0)
            .background(alignment: .top) { fill.ignoresSafeArea(edges: .top) }
            .opacity(visible ? 1 : 0)
            .animation(reduceMotion ? nil : MP.M.easeOut, value: visible)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

extension View {
    /// Kaydırma içeriğinin tepesi saat çubuğunun altına girdi mi.
    func mpTracksScroll(_ scrolled: Binding<Bool>) -> some View {
        onGeometryChange(for: Bool.self) { $0.frame(in: .scrollView).minY < -MPSpacing.sm } action: {
            scrolled.wrappedValue = $0
        }
    }
}

// MPCreateOverTabBar.swift
// iOS 26: sistemin Liquid Glass sekme çubuğundaki "Masal yaz" dairesinin
// üstüne eski mor Masal yaz düğmesi (27 Kasım 2026, Batuhan: "eski masal yaz
// butonu geri gelsin, diğer nav bar liquid glass devam etsin").

import SwiftUI
import UIKit

/// Masal yaz: marka renginde, sert kenarlı daire (eski `KidTabBar` dairesiyle aynı).
struct MPCreateCircle: View {
    let size: CGFloat

    static let symbol = "wand.and.sparkles"

    var body: some View {
        MPIcon(Self.symbol, size: MP.G.lg, weight: .semibold, symbolOnly: true)
            .foregroundStyle(MP.C.textOnBrand)
            .frame(width: size, height: size)
            .mpEdge(fill: MP.C.brand, edge: MP.C.brandEdge, radius: size / 2)
    }
}

/// Sistemin `.search` rollü "Masal yaz" sekmesinin dairesini bulur ve mor
/// daireyi tam üstüne koyar. Sekmenin kendisi yerinde kalır: VoiceOver,
/// sürükleyerek seçme ve basılı tutunca büyük içerik onunla çalışır. Daire
/// bulunamazsa (sistem düzeni değişirse) hiçbir şey çizilmez, sistemin cam
/// dairesi görünür ve masal yazma yine açılır.
@available(iOS 26.0, *)
struct MPCreateOverTabBar: View {
    /// Sistem sekmesinin adı; daire bu adla bulunur.
    let label: String
    let onCreate: () -> Void
    var zoom: Namespace.ID? = nil

    /// Sistem dairesinin pencere koordinatlarındaki çerçevesi.
    @State private var target: CGRect?

    var body: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            ZStack(alignment: .topLeading) {
                MPTabItemLocator(label: label) { frame in
                    if frame != target { target = frame }
                }
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)

                if let target {
                    // Düğme alanı camdan büyük olabilir: eski dairenin çapını aşmaz.
                    let size = min(target.width, target.height, MP.S.tapMin + MP.S.x4 - MP.E.width)
                    Button(action: onCreate) {
                        MPCreateCircle(size: size)
                            .contentShape(Circle())
                    }
                    .buttonStyle(MPPressStyle(.highlight))
                    .mpZoomSource(KidTabBar.createZoomID, in: zoom)
                    // VoiceOver sistemin sekmesini okur; bu yalnızca görünüm.
                    .accessibilityHidden(true)
                    .position(x: target.midX - origin.x, y: target.midY - origin.y)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .ignoresSafeArea()
    }
}

/// Pencerede `UITabBar` içinde verilen adı taşıyan görünümü arar.
@available(iOS 26.0, *)
private struct MPTabItemLocator: UIViewRepresentable {
    let label: String
    let onFrame: (CGRect?) -> Void

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.label = label
        view.onFrame = onFrame
        return view
    }

    func updateUIView(_ view: ProbeView, context: Context) {
        view.label = label
        view.onFrame = onFrame
        view.measureSoon()
    }

    final class ProbeView: UIView {
        var label = ""
        var onFrame: ((CGRect?) -> Void)?
        private var last: CGRect?
        private var timer: Timer?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            timer?.invalidate()
            guard window != nil else { return }
            measureSoon()
            // Sekme çubuğu döndürme, yazı boyutu ya da sekme değişiminde
            // yeniden yerleşebilir; hafif bir yoklama yeter.
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.measure()
            }
        }

        override func removeFromSuperview() {
            timer?.invalidate()
            super.removeFromSuperview()
        }

        func measureSoon() {
            DispatchQueue.main.async { [weak self] in self?.measure() }
        }

        private func measure() {
            guard let window else { return }
            let frame = Self.tabBars(in: window)
                .lazy
                .compactMap { bar -> CGRect? in
                    guard !bar.isHidden, bar.alpha > 0.01,
                          let item = Self.view(labelled: self.label, in: bar) else { return nil }
                    return item.convert(item.bounds, to: window)
                }
                .first
                .flatMap { $0.width > 1 && $0.height > 1 ? $0 : nil }
            guard frame != last else { return }
            last = frame
            onFrame?(frame)
        }

        private static func tabBars(in view: UIView) -> [UITabBar] {
            if let bar = view as? UITabBar { return [bar] }
            return view.subviews.flatMap { tabBars(in: $0) }
        }

        /// Adı taşıyan en dıştaki görünüm (düğmenin kendisi, içindeki ikon değil).
        private static func view(labelled label: String, in view: UIView) -> UIView? {
            if view.accessibilityLabel == label, !view.isHidden { return view }
            for sub in view.subviews {
                if let found = self.view(labelled: label, in: sub) { return found }
            }
            return nil
        }
    }
}

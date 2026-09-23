import SwiftUI
import UIKit

/// SwiftUI ile `UIPageViewController` arasındaki köprü.
///
/// İnce olması kasıtlı: sayfanın ne içerdiğine karar vermez, hiçbir şey
/// kaydetmez, kendi başına hiçbir şeyi animasyonlamaz. Bütün durum
/// `StoryReaderModel`'da; koordinatör yalnızca UIKit geri çağrılarını modele
/// çevirir ve veri kaynağı sorularını modelden cevaplar.
///
/// Sayfa kıvrımı yerli olarak buradan gelir (§2): `transitionStyle = .pageCurl`
/// parmağı takip eden, yarıda bırakılabilen, kendi ışığı olan bir çevirme verir.
/// SwiftUI wrapper switching between the legacy UIPageViewController and the custom MagicPaperPageTurn system.
struct StoryReaderContainer<Page: View>: View {
    @ObservedObject var model: StoryReaderModel
    let theme: MP.ReadTheme
    let page: (Int) -> Page
    let onTurnCompleted: () -> Void
    let onTap: () -> Void
    let reduceMotion: Bool

    var body: some View {
        if MagicPaperPageTurnConfiguration.useCustomRenderer {
            if reduceMotion {
                page(model.leafIndex)
                    .transition(.opacity)
                    .id(model.leafIndex)
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { location in
                        let width = UIScreen.main.bounds.width
                        let edgeTapWidth = width * MagicPaperPageTurnConfiguration.edgeTapWidthRatio
                        if location.x < edgeTapWidth {
                            if model.leafIndex > 0 { 
                                withAnimation(MP.M.easeOut) { model.previous() }
                            }
                        } else if location.x > width - edgeTapWidth {
                            if model.leafIndex < model.leafCount - 1 { 
                                withAnimation(MP.M.easeOut) { model.next() }
                            }
                        } else {
                            onTap()
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                                guard isHorizontal else { return }
                                if value.translation.width < -50 && model.leafIndex < model.leafCount - 1 {
                                    withAnimation(MP.M.easeOut) { model.next() }
                                } else if value.translation.width > 50 && model.leafIndex > 0 {
                                    withAnimation(MP.M.easeOut) { model.previous() }
                                }
                            }
                    )
            } else {
                MagicPaperPageTurnContainer(
                    theme: theme,
                    leafIndex: model.leafIndex,
                    leafCount: model.leafCount,
                    page: page,
                    onTurnCompleted: { direction in
                        if direction == .forward {
                            model.next()
                        } else {
                            model.previous()
                        }
                        onTurnCompleted()
                    },
                    onTap: onTap
                )
            }
        } else {
            LegacyStoryReaderContainer(
                model: model,
                theme: theme,
                page: page,
                onTurnCompleted: onTurnCompleted,
                onTap: onTap,
                reduceMotion: reduceMotion
            )
        }
    }
}

struct LegacyStoryReaderContainer<Page: View>: UIViewControllerRepresentable {

    @ObservedObject var model: StoryReaderModel
    let theme: MP.ReadTheme
    /// Bir yaprağın içeriğini üretir. Container sayfanın ne olduğunu bilmez.
    let page: (Int) -> Page
    /// Bir çevirme tamamlandığında — yarıda bırakılan kıvrımda çağrılmaz.
    let onTurnCompleted: () -> Void
    /// Sayfaya dokunulduğunda — kontrolleri açıp kapatır (§10).
    ///
    /// Dokunma UIKit tarafında dinlenir. SwiftUI'da sayfanın üstüne konan
    /// şeffaf bir dokunma katmanı denendi ve sayfayı çevirmeyi tamamen bozdu:
    /// katman bütün dokunuşları önce kendisi alıyor, kaydırma hiç kıvrım
    /// tanıyıcısına ulaşmıyordu. Dokunma, yarıştığı jestle aynı yerde
    /// dinlenmek zorunda.
    let onTap: () -> Void

    /// "Hareketi Azalt" açıkken kıvrım yerine kaydırma.
    ///
    /// Gezinme, sınırlar, geri çağrılar, künye ve tamamlanma aynı kalır;
    /// yalnızca görsel değişir. §18'in istediği "daha basit geçiş, mantıksal
    /// gezinme korunarak" — ikinci bir kod yolu yazarak değil, kurulumla.
    let reduceMotion: Bool

    private var transitionStyle: UIPageViewController.TransitionStyle {
        reduceMotion ? .scroll : .pageCurl
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model, page: page, theme: theme,
                    onTurnCompleted: onTurnCompleted, onTap: onTap)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: transitionStyle,
            navigationOrientation: .horizontal,
            options: [
                .spineLocation: UIPageViewController.SpineLocation.min.rawValue
            ]
        )

        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        // Yaprağın arkası otomatik çizilir; iki yüzlü kitap MVP'de yok (§24).
        controller.isDoubleSided = false

        // Kıvrım sırasında yaprağın arkasında kalan boşluk kâğıt olmalı, siyah
        // değil.
        controller.view.backgroundColor = UIColor(theme.paper)

        // `UIPageViewController` kendi dokunma tanıyıcılarını kurar ve onlar
        // sayfayı çevirir. §10'da dokunmanın işi kontrolleri açıp kapatmak;
        // kaydırma tanıyıcısı kalır, dokunma olanlar kapatılır.
        for recognizer in controller.gestureRecognizers {
            if recognizer is UITapGestureRecognizer {
                recognizer.isEnabled = false
            }
        }

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        // Kıvrımın kaydırma tanıyıcısıyla yarışmaz: farklı türler, ve dokunma
        // yalnızca parmak hareket etmediğinde tetiklenir.
        tap.cancelsTouchesInView = false
        controller.view.addGestureRecognizer(tap)

        context.coordinator.attach(to: controller)
        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        context.coordinator.model = model
        context.coordinator.theme = theme
        context.coordinator.page = page
        controller.view.backgroundColor = UIColor(theme.paper)
        context.coordinator.syncIfNeeded(controller)
    }

    static func dismantleUIViewController(_ controller: UIPageViewController,
                                          coordinator: Coordinator) {
        // Okuyucu geçiş sırasında kapatılabilir; geç gelen geri çağrının
        // ölü bir modele yazmaması için bağlar önce koparılır (§25).
        controller.dataSource = nil
        controller.delegate = nil
        coordinator.detach()
    }

    // MARK: - Koordinatör

    @MainActor
    final class Coordinator: NSObject, UIPageViewControllerDataSource,
                             UIPageViewControllerDelegate {

        var model: StoryReaderModel?
        var theme: MP.ReadTheme
        var page: (Int) -> Page
        let onTurnCompleted: () -> Void
        let onTap: () -> Void

        /// Etkileşimli bir geçiş sürerken `setViewControllers` çağırmak
        /// `UIPageViewController`'ın klasik çökme sebebidir. Hızlı ve tekrarlı
        /// kaydırmalarda (§25) tam olarak bu olur.
        private var isTransitioning = false
        private weak var controller: UIPageViewController?

        init(model: StoryReaderModel,
             page: @escaping (Int) -> Page,
             theme: MP.ReadTheme,
             onTurnCompleted: @escaping () -> Void,
             onTap: @escaping () -> Void) {
            self.model = model
            self.page = page
            self.theme = theme
            self.onTurnCompleted = onTurnCompleted
            self.onTap = onTap
        }

        @objc func handleTap() {
            onTap()
        }

        func attach(to controller: UIPageViewController) {
            self.controller = controller
            guard let model else { return }
            controller.setViewControllers(
                [host(at: model.leafIndex)], direction: .forward, animated: false
            )
        }

        func detach() {
            model = nil
            controller = nil
        }

        // MARK: Yaprak üretimi

        func host(at index: Int) -> StoryPageHostController<Page> {
            StoryPageHostController(
                leafIndex: index,
                rootView: page(index),
                paper: UIColor(theme.paper)
            )
        }

        // MARK: Veri kaynağı

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerBefore viewController: UIViewController)
        -> UIViewController? {
            // Zorlama açma yok: beklenmedik bir denetleyici sınır demektir.
            guard let host = viewController as? StoryPageHostController<Page>,
                  host.leafIndex > 0 else { return nil }
            return self.host(at: host.leafIndex - 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerAfter viewController: UIViewController)
        -> UIViewController? {
            guard let host = viewController as? StoryPageHostController<Page>,
                  let model,
                  host.leafIndex < model.leafCount - 1 else { return nil }
            return self.host(at: host.leafIndex + 1)
        }

        // MARK: Temsilci

        func pageViewController(_ pageViewController: UIPageViewController,
                                willTransitionTo pendingViewControllers: [UIViewController]) {
            isTransitioning = true
        }

        func pageViewController(_ pageViewController: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            isTransitioning = false

            // Yarıda bırakılmış bir kıvrım — çocuk yarım sayfa sürükleyip
            // bıraktı — modeli oynatmaz.
            guard completed,
                  let model,
                  let current = pageViewController.viewControllers?.first
                    as? StoryPageHostController<Page> else { return }

            model.syncFromPageController(leafIndex: current.leafIndex)
            onTurnCompleted()
        }

        // MARK: Programlı gezinme

        /// Model UIKit'in dışında değiştiyse (erişilebilirlik eylemi, "Tekrar
        /// oku", kapaktan açılış) sayfa denetleyicisini ona getirir.
        func syncIfNeeded(_ controller: UIPageViewController) {
            guard let model, !isTransitioning else { return }
            guard let current = controller.viewControllers?.first
                    as? StoryPageHostController<Page> else { return }
            guard current.leafIndex != model.leafIndex else { return }

            let direction: UIPageViewController.NavigationDirection =
                model.leafIndex > current.leafIndex ? .forward : .reverse

            isTransitioning = true
            controller.setViewControllers(
                [host(at: model.leafIndex)], direction: direction, animated: true
            ) { [weak self] _ in
                self?.isTransitioning = false
            }
        }
    }
}

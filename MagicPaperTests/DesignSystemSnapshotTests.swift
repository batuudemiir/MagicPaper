import SnapshotTesting
import SwiftUI
import XCTest
@testable import MagicPaper

/// Faz 0 korkuluğu (`docs/STARTUP_PLANI.md`): ortak bileşenlerin ve masal
/// sayfasının görüntü testleri. Sonraki yazı, düğme ve kart işleri (Faz 1) buradan
/// geçer: fark bir hatadır ya da bilinçli değişikliktir, bilinçliyse referans
/// yenilenir. Referanslar `iPhone 17 Pro` (iOS 27) simülatöründe üretildi; başka
/// cihazda değil yalnız bu cihazda çalıştır.
///
/// Tam ekranlar henüz burada değil: saate ve tekil servislere bağlılar, kararlı
/// görüntü vermezler. Bağımlılıklar `@Environment`'a geçtikçe eklenir (Faz 2).
@MainActor
final class DesignSystemSnapshotTests: XCTestCase {

    private static let width: CGFloat = 402

    /// 1x: düzen ve renk değişikliğini yakalamaya yeter, referanslar depoyu şişirmez.
    private static let traits = UITraitCollection(displayScale: 1)

    /// Hem normal hem en büyük erişilebilirlik yazısında; kesilme ikincisinde görünür.
    private func assertBoth<V: View>(_ view: V, height: CGFloat, largeHeight: CGFloat,
                                     file: StaticString = #filePath, testName: String = #function,
                                     line: UInt = #line) {
        let framed = view
            .padding(MP.S.screenGutter)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(MPColor.backgroundSurface)

        assertSnapshot(of: framed.environment(\.dynamicTypeSize, .large),
                       as: .image(perceptualPrecision: 0.98,
                                  layout: .fixed(width: Self.width, height: height),
                                  traits: Self.traits),
                       named: "normal", file: file, testName: testName, line: line)
        assertSnapshot(of: framed.environment(\.dynamicTypeSize, .accessibility3),
                       as: .image(perceptualPrecision: 0.98,
                                  layout: .fixed(width: Self.width, height: largeHeight),
                                  traits: Self.traits),
                       named: "buyuk", file: file, testName: testName, line: line)
    }

    func testSnapshotButtons() {
        assertBoth(
            VStack(spacing: MP.S.x3) {
                MPButton(title: "Masalı oku", fullWidth: true) {}
                MPButton(title: "Masalı oku", fullWidth: true) {}.disabled(true)
                MPButton(title: "Planlar", kind: .secondary, fullWidth: true) {}
                MPButton(title: "Kopyala", kind: .soft, fullWidth: true) {}
                MPButton(title: "Şimdi değil", kind: .ghost) {}
                MPButton(title: "Profili sil", kind: .danger, fullWidth: true) {}
                MPButton(title: "Düzenle", kind: .secondary, size: .small) {}
                MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri") {}
            },
            height: 560, largeHeight: 900)
    }

    func testSnapshotTabHeaders() {
        assertBoth(
            VStack(spacing: MP.S.x6) {
                MPKidTabHeader(title: "İrem", eyebrow: "İyi akşamlar,")
                MPKidTabHeader(title: "Profil")
                MPKidTabHeader(title: "Masallar") {
                    MPCircleButton(systemImage: "magnifyingglass", accessibilityLabel: "Masal ara") {}
                }
                MPTopBar(title: "Masal ailem", subtitle: "Masallarında tekrar görünen karakterler", onBack: {})
            },
            height: 340, largeHeight: 760)
    }

    func testSnapshotSectionHeaders() {
        assertBoth(
            VStack(spacing: MP.S.x6) {
                MPSectionHeader(title: "Masallar", link: ("Tümü", {}))
                MPSectionHeader(title: "Rozetlerim", note: "3 / 8")
                MPSectionHeader(title: "Son masallar", area: .parent)
            },
            height: 200, largeHeight: 420)
    }

    func testSnapshotHeroCardStates() {
        assertBoth(
            VStack(spacing: MP.S.x4) {
                HomeHeroCard(state: .resume(progress: 0.37, title: "Şehri Kurtaran Gün", meta: "Sayfa 3 / 8")) {}
                HomeHeroCard(state: .readToday) {}
            },
            height: 860, largeHeight: 1500)
    }

    func testSnapshotChoiceRows() {
        assertBoth(
            VStack(spacing: MP.S.x3) {
                CreationChoiceRow(title: "Uyku öncesi", subtitle: "Günü sakin bir hikâyeyle kapatalım.",
                                  isSelected: true, action: {}) { Color.clear.frame(width: 48, height: 48) }
                CreationChoiceRow(title: "Maceraya çıkalım", subtitle: "Birlikte bir maceraya çıkalım.",
                                  isSelected: false, action: {}) { Color.clear.frame(width: 48, height: 48) }
            },
            height: 240, largeHeight: 520)
    }

    func testSnapshotStateView() {
        assertBoth(
            MPStateView(mascot: .reading, title: "Kitaplığın henüz boş",
                        message: "İlk masalını yaz, burada seni beklesin.") {
                EmptyView()
            } actions: {
                MPButton(title: "İlk masalını yaz") {}
            },
            height: 520, largeHeight: 900)
    }

    /// Masal metni beş kâğıtta: kontrast ve satır düzeni okumanın kendisi.
    func testSnapshotReaderPageOnEveryPaper() {
        let page = ReaderPage(index: 0, title: "",
                              paragraphs: ["İrem sabah uyandığında pencerenin önünde küçük bir kuş gördü. Kuş pıt pıt kanatlarını çırptı."],
                              imageRef: nil, imageLabel: nil, sceneHint: "")
        for theme in MP.ReadTheme.allCases {
            assertSnapshot(
                of: StoryPageView(page: page, theme: theme, readSize: .normal, childName: "İrem",
                                  folio: "1", showsFolio: true, accent: MP.C.brand, symbol: "book"),
                as: .image(perceptualPrecision: 0.98, layout: .fixed(width: Self.width, height: 600),
                           traits: Self.traits),
                named: theme.rawValue)
        }
    }
}

import SwiftUI

/// Dört ortam için görsel doğrulama (§32).
///
/// Amaç dekorasyonun *yeniden kullanılabilir ve masala duyarlı* olduğunu
/// kanıtlamak: aynı motor, aynı yerleştirme kuralları, dört farklı sayfa.
/// Ortam değiştiğinde süsler de değişmiyorsa sistem çalışmıyor demektir.
struct StoryDecorationDemoView: View {

    /// Demo sayfası: sahne ipucu ortamı belirler, tıpkı gerçek masalda olduğu
    /// gibi — burada elle ortam seçilmiyor, `visualScene` metni veriliyor.
    private struct Demo: Identifiable {
        let id: String
        let title: String
        let scene: String
        let text: String
        let density: DecorationDensity
        let theme: MP.ReadTheme
    }

    private static let demos: [Demo] = [
        Demo(id: "forest", title: "Orman · Büyülü",
             scene: "child stepping into the forest, a faint glow between the trees",
             text: "Yeliz ağaçların arasından geçen ince bir ışık gördü.\n\n“Bu da ne?” diye fısıldadı.",
             density: .rich, theme: .light),
        Demo(id: "ocean", title: "Deniz · Sakin",
             scene: "child standing at the shore, the sea very calm, shells in the sand",
             text: "Deniz o sabah hiç dalgalanmıyordu.\n\nYeliz kumda küçük bir kabuk buldu.",
             density: .normal, theme: .light),
        Demo(id: "bedtime", title: "Uyku · Rüyalı",
             scene: "child looking at the night sky, the moon low and soft, ready to sleep",
             text: "Gökyüzü bu gece çok sessizdi.\n\nAy, tam pencerenin hizasındaydı.",
             density: .sparse, theme: .night),
        Demo(id: "adventure", title: "Macera · Gündüz",
             scene: "child climbing the mountain path, the journey ahead, wind on the hill",
             text: "Patika yukarı doğru kıvrılıyordu.\n\nYeliz bir kez daha yukarı baktı.",
             density: .normal, theme: .light),
    ]

    @State private var index = 0
    @State private var showsDebug = false
    @Environment(\.dismiss) private var dismiss

    private var demo: Demo { Self.demos[index] }

    var body: some View {
        ZStack(alignment: .top) {
            page
            controls
        }
    }

    private var page: some View {
        let page = ReaderPage(
            index: 2, title: "",
            paragraphs: ReaderStory.paragraphs(of: demo.text),
            imageRef: nil, imageLabel: nil, sceneHint: demo.scene
        )
        let env = StoryEnvironment.fromScene(demo.scene) ?? .neutral
        let context = StoryDecorationContext(
            environment: env, mood: nil, timeOfDay: .day,
            density: demo.density,
            seed: UInt64(abs(demo.id.hashValue)),
            textSafeRect: CGRect(x: 0.06, y: 0.30, width: 0.88, height: 0.42),
            illustrationSafeRect: nil
        )
        return StoryPageView(
            page: page, theme: demo.theme, readSize: .normal,
            folio: "3 / 8", showsFolio: true,
            accent: MP.C.brand, symbol: "book",
            ornament: .sade,
            decoration: context,
            showsDecorationDebug: showsDebug
        )
        .id(demo.id + "\(showsDebug)")
    }

    private var controls: some View {
        VStack(spacing: MP.S.x2) {
            HStack {
                MPIconButton(symbol: "xmark", label: "Kapat") { dismiss() }
                Spacer(minLength: 0)
                MPChip(title: showsDebug ? "Debug açık" : "Debug",
                       isSelected: showsDebug) { showsDebug.toggle() }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MP.S.x2) {
                    ForEach(Array(Self.demos.enumerated()), id: \.element.id) { i, d in
                        MPChip(title: d.title, isSelected: i == index) { index = i }
                    }
                }
            }
        }
        .mpGutter()
        .padding(.top, MP.S.x1)
    }
}

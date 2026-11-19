import SwiftUI

/// Bir masal sayfası, dizilmiş hâlde.
///
/// Kart değil. Yuvarlak köşesi, kenar boşluğu içinde ikinci bir yüzeyi, gölgesi
/// yok — sayfanın kendisi baştan başa kâğıt, metin doğrudan onun üstünde. §7'nin
/// "sayfayı yuvarlak bir uygulama kartı gibi ele alma" dediği şey bu, ve sayfa
/// kıvrımının da çalışması için gereken şey aynı şey.
struct StoryPageView: View {

    let page: ReaderPage
    let theme: MP.ReadTheme
    let readSize: MP.ReadSize
    /// Satır aralığı ve kolay okuma (Okuma ayarları · Yazı).
    var spacing: MP.ReadSpacing = .normal
    var easyReading: Bool = false
    /// Nefes satırları (3-6 yaş) ya da paragraf ve cümle takibi (7-10).
    var layout: ReaderTextLayout = .paragraphs
    /// Metinde vurgulanan ad: masal çocuğa ait.
    var childName: String? = nil
    /// Sesli okumada okunan yer (cümle takibi, yalnızca paragraf düzeninde).
    @ObservedObject private var spoken = MPSpokenPosition.shared
    let folio: String?
    /// Alt künye görünür mü. Kontroller görünürken sayfa numarası alt çubukta
    /// yazılı; künye yalnızca kontroller çekilince belirir (21 Ekim 2026).
    let showsFolio: Bool
    /// Masalın dünya rengi.
    let accent: Color
    /// Masalın dünya işareti; çağıranların ortak sunum sözleşmesinde kalır.
    let symbol: String
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.verticalSizeClass) private var verticalClass
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var unavailableImageRef: String?

    private var illustrationKey: String? {
        page.imageRef ?? (page.art?.isBundledSpot == true ? page.art?.assetDigest : nil)
    }

    private var composition: ReaderPageComposition {
        if page.scene == nil, let key = illustrationKey, unavailableImageRef == key { return .text }
        return page.composition
    }

    private var bottomClearance: CGFloat {
        ReaderPageLayout.bottomChromeClearance(accessibility: typeSize.isAccessibilitySize, compactHeight: verticalClass == .compact)
    }

    var body: some View {
        ZStack {
            ReaderPaper(theme: theme)

            GeometryReader { geo in
                if isSpread(geo) {
                    spread(in: geo)
                } else {
                // Çizim kenardan kenara ve sayfanın en üstünden başlar; cam
                // kontroller onun üstünde yüzer. Metin kenar boşluğunda kalır.
                VStack(spacing: 0) {
                    if composition == .scene {
                        illustration(in: geo)
                            .overlay(alignment: .bottom) { PaperLip(theme: theme) }
                        Spacer(minLength: MP.S.x6)
                    }
                    if composition == .spot {
                        spotHeader(in: geo)
                    }
                    textColumn(in: geo)
                        .padding(.horizontal, StoryPageView.gutter)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Resimsiz sayfada metin üst denetimlerin (kapat, kalp, Aa)
                // altından başlar; en büyük yazı boyutunda kapatın altına akmaz.
                .padding(.top, composition == .scene ? 0 : MP.S.navBarHeight + MP.S.x6)
                .padding(.bottom, bottomClearance)
                }
            }

            folioLine
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(pageAccessibilityLabel)
    }

    /// Dış kenar boşluğu.
    ///
    /// `MPStoryPDF` A5'i 40/420 ≈ %9,5 ile basıyor; 393 puntoluk bir iPhone'da
    /// bu ~37 punto eder. `MP.S.x7` en yakın token ve her boyutta doğru okunuyor.
    static let gutter: CGFloat = MP.S.x7

    /// Satır uzunluğu sınırı.
    ///
    /// Geniş bir iPhone'da 20 kelimelik satırlar basılmasın diye: göz satır
    /// sonundan başına dönerken yerini kaybeder ve çocuk için bu, okumayı
    /// bırakma sebebidir.
    private var measure: CGFloat { readSize.points * 30 }

    // MARK: - Çizim

    @ViewBuilder
    private func illustration(in geo: GeometryProxy) -> some View {
        if let scene = page.scene {
            StorySceneView(scene: scene)
                .frame(height: sceneHeight(in: geo))
                .frame(maxWidth: .infinity)
        } else {
            fileIllustration(in: geo)
        }
    }

    /// Hazır sahnenin yüksekliği (B2): sütun genişliğinde 4:3, ama hiçbir
    /// zaman normal yazıda kullanılabilir yüksekliğin %40'ından fazla değil. Kare kutuyu
    /// doldurmaz; metne yer bırakır (docs/B2_SCENE_LIBRARY_PLAN.md §5.2).
    private func sceneHeight(in geo: GeometryProxy) -> CGFloat {
        ReaderPageLayout.sceneHeight(width: geo.size.width, height: geo.size.height,
                                     readPoints: readSize.points, accessibility: typeSize.isAccessibilitySize)
    }


    @ViewBuilder
    private func fileIllustration(in geo: GeometryProxy) -> some View {
        let height = sceneHeight(in: geo)

        PageIllustration(
            fileName: page.imageRef ?? "",
            label: page.imageLabel,
            theme: theme,
            art: page.art,
            bleeds: true,
            onUnavailable: { unavailableImageRef = illustrationKey }
        )
        .frame(height: height)
        .clipped()
    }

    @ViewBuilder
    private func spotHeader(in geo: GeometryProxy) -> some View {
        let top = MP.S.navBarHeight + MP.S.x6
        let size = ReaderPageLayout.spotHeaderSize(
            width: max(0, geo.size.width - StoryPageView.gutter * 2),
            pageHeight: geo.size.height,
            contentHeight: max(0, geo.size.height - top - bottomClearance),
            accessibility: typeSize.isAccessibilitySize)
        if size.height > 0 {
            PageIllustration(fileName: page.imageRef ?? "", label: page.imageLabel, theme: theme,
                             art: page.art, bleeds: false,
                             onUnavailable: { unavailableImageRef = illustrationKey })
                .frame(width: size.width, height: size.height)
                .frame(maxWidth: .infinity)
                .padding(.bottom, MP.S.x6)
        }
    }

    // MARK: - 27 · iPad yatay açık kitap

    /// iPad yatayda (geniş boyut sınıfı, yatay sayfa) sayfa açık kitap olur:
    /// solda resim, sağda metin, ortada sırt gölgesi. En büyük yazı
    /// boyutlarında metin tüm genişliği alır.
    private func isSpread(_ geo: GeometryProxy) -> Bool {
        composition == .scene && sizeClass == .regular
            && geo.size.width > geo.size.height * 1.15 && !typeSize.isAccessibilitySize
    }

    private func spread(in geo: GeometryProxy) -> some View {
        let half = geo.size.width / 2
        return HStack(spacing: 0) {
            spreadArt
                .frame(width: half, height: geo.size.height)
                .clipped()
                .accessibilityHidden(page.imageLabel == nil)
            GeometryReader { right in
                textColumn(in: right)
                    .padding(.horizontal, StoryPageView.gutter + MP.S.x4)
                    .padding(.top, MP.S.navBarHeight)
                    .padding(.bottom, bottomClearance)
            }
            .frame(width: half, height: geo.size.height)
            // Kitabın sırtı: kâğıt gölgelemesi (malzeme taklidi).
            .overlay(alignment: .leading) {
                LinearGradient(colors: [MPColor.shadowInk.opacity(0.10), MPColor.shadowInk.opacity(0)],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(width: MP.S.x8)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    /// Açık kitabın sol sayfası yalnızca gerçek bir sahne taşır.
    @ViewBuilder
    private var spreadArt: some View {
        if let scene = page.scene {
            StorySceneView(scene: scene)
                .aspectRatio(StorySceneView.aspectRatio, contentMode: .fill)
        } else if let file = page.imageRef {
            PageIllustration(fileName: file, label: page.imageLabel, theme: theme,
                             onUnavailable: { unavailableImageRef = illustrationKey })

        }
    }

    // MARK: - Metin

    /// Metin sütunu.
    ///
    /// Kaydırılabilir olması, eski üretim hattından gelen masallar yüzünden:
    /// onların sayfaları 1500 karaktere kadar çıkabiliyor ve sabit bir sayfada
    /// alt kısmı okunamadan kesiliyordu. Yeni motor sayfaları zaten kısa
    /// kesiyor, dolayısıyla tipik masalda kaydırma hiç devreye girmez —
    /// `.basedOnSize` içerik sığdığında sekmeyi de kapatır, yani sığan sayfa
    /// sabit bir sayfa gibi davranır.
    ///
    /// Metin üstten başlar; uzun metin aynı sütunda kaydırılabilir.
    /// Yeni kelimenin rengi: okuma temasının kahraman adı tonu (teslimde
    /// `reader.*.heroName`), üç temada da kâğıda karşı okunur.
    private var wordHighlight: Color { theme.highlight }

    /// Metin sütununun kendi yüksekliği ölçülür, sayfanınki değil. Önceden
    /// sayfanın tam yüksekliği kullanılıyordu; sütun ise üst ve alt boşluk
    /// kadar kısaydı, bu yüzden kısa metin bile her zaman biraz taşıyor ve
    /// parmakla yukarı aşağı oynuyordu (21 Ekim 2026). Sığan metin artık
    /// kıpırdamaz; kaydırma yalnızca gerçekten sığmayan eski uzun sayfalarda.
    private func textColumn(in geo: GeometryProxy) -> some View {
        GeometryReader { viewport in
            textScroll(available: viewport.size)
        }
    }

    private func textScroll(available: CGSize) -> some View {
        ScrollView(.vertical) {
            narrative
            .frame(maxWidth: measure, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: max(available.height, 0), alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    private var narrative: some View {
        VStack(alignment: .leading, spacing: readSize.points * 0.55) {
            if !page.title.isEmpty {
                Text(page.title)
                    .font(MP.F.displaySM())
                    .mpTightTracking(21)
                    .foregroundStyle(theme.foreground)
                    .padding(.bottom, MP.S.x1)
            }
            switch layout {
            case .breath: breathLines
            case .paragraphs: paragraphs
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(page.spokenText)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityTextContentType(.narrative)
        .modifier(WordActions(words: ReaderWords.words(in: page.paragraphs, from: page.words)))
        .environment(\.openURL, OpenURLAction { url in
            ReaderWordSelection.shared.handle(url, in: page.words)
        })
    }

    /// 7-10 yaş: paragraflar ayrı ayrı dizilir. `lineSpacing` tek başına
    /// paragrafı satırdan ayırt edemez; diyalog da böylece balonsuz ve ikinci
    /// bir yazı stili olmadan ayrılır (§15). Sesli okurken okunan cümle
    /// fosforlu kalemle işaretlenir, öncesi söner: kelime kelime değil cümle
    /// cümle, çünkü her kelimeyi işaretlemek dikkati dağıtır.
    @ViewBuilder
    private var paragraphs: some View {
        let mark = readAlongMark
        ForEach(Array(page.paragraphs.enumerated()), id: \.offset) { i, paragraph in
            Text(ReaderWords.attributed(paragraph, words: page.words, size: readSize.points,
                                        ink: theme.body, highlight: wordHighlight,
                                        childName: childName,
                                        readAlong: readAlong(for: i, mark: mark, in: paragraph)))
                .lineSpacing(readSize.points * spacing.factor)
                // Kolay okuma: harf arası açılır, font Nunito kalır.
                .tracking(ReaderText.tracking(readSize.points, easyReading: easyReading))
                .tint(wordHighlight)
                .fixedSize(horizontal: false, vertical: true)
                // Konuşma paragrafı solda ince bir çizgiyle ayrılır.
                .padding(.leading, ReaderText.isDialogue(paragraph) ? MP.S.x3 : 0)
                .overlay(alignment: .leading) {
                    if ReaderText.isDialogue(paragraph) {
                        Capsule().fill(theme.muted.opacity(0.35))
                            .frame(width: MP.E.width)
                            .accessibilityHidden(true)
                    }
                }
        }
    }

    /// 3-6 yaş: her cümle kendi satırında, seçilen boyutun bir üstünde ve en
    /// az "Rahat" satır arasıyla. Sağ kenar serbest, heceleme yok. Paragraflar
    /// arasında daha geniş bir nefes.
    @ViewBuilder
    private var breathLines: some View {
        let size = readSize.larger.points
        let lineGap = size * max(spacing.factor, MP.ReadSpacing.rahat.factor)
        let word = breathWordMark
        ForEach(Array(ReaderText.breathLines(of: page.paragraphs).enumerated()), id: \.offset) { p, lines in
            VStack(alignment: .leading, spacing: size * 0.55) {
                ForEach(Array(lines.enumerated()), id: \.offset) { l, line in
                    // Sesli okumada okunan kelime fosforlu kalemle; satırın gerisi olduğu gibi.
                    let mark = word.flatMap { $0.paragraph == p && $0.line == l ? $0 : nil }
                    Text(ReaderWords.attributed(line, words: page.words, size: size,
                                                ink: theme.body, highlight: wordHighlight,
                                                childName: childName,
                                                readAlong: mark.map { .init(start: $0.start, end: $0.end,
                                                                            fill: theme.readAlong, readInk: theme.body) }))
                        .lineSpacing(lineGap)
                        .tracking(ReaderText.tracking(size, easyReading: easyReading))
                        .tint(wordHighlight)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, size * 0.5)
        }
    }

    /// 3-6 yaş: anlatıcı bu sayfayı okuyorsa okunan kelime (Faz 5). Küçük okur
    /// kelimeyi sesle eşler; 7-10 yaşta cümle takibi kalır.
    private var breathWordMark: BreathWordMark? {
        guard layout == .breath, let value = spoken.value,
              value.text == page.spokenText.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        return ReaderText.breathWordMark(paragraphs: page.paragraphs, location: value.location, length: value.length)
    }

    /// Anlatıcı bu sayfayı okuyorsa okunan cümle.
    private var readAlongMark: ReadAlongMark? {
        guard layout == .paragraphs, let value = spoken.value,
              value.text == page.spokenText.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        return ReaderText.readAlongMark(paragraphs: page.paragraphs, spokenLocation: value.location)
    }

    private func readAlong(for index: Int, mark: ReadAlongMark?, in paragraph: String) -> ReaderWords.ReadAlong? {
        guard let mark, index <= mark.paragraph else { return nil }
        let whole = (paragraph as NSString).length
        // Önceki paragraflar bütünüyle okunmuş; okunan paragrafta cümleye kadar.
        return index < mark.paragraph
            ? .init(start: whole, end: whole, fill: .clear, readInk: theme.muted)
            : .init(start: mark.start, end: mark.end, fill: theme.readAlong, readInk: theme.muted)
    }

    // MARK: - Künye

    @ViewBuilder
    private var folioLine: some View {
        if let folio {
            VStack {
                Spacer(minLength: 0)
                // Kitaptaki gibi yalnızca sayfa numarası, ortada ve sessiz.
                Text("— \(page.index + 1) —")
                    .font(MP.F.caption())
                    .foregroundStyle(theme.muted)
                    .opacity(showsFolio ? 0.75 : 0)
                    .animation(MP.M.gated(MP.M.easeOut), value: showsFolio)
                    .padding(.bottom, MP.S.x2)
            }
            .accessibilityHidden(true)   // konum, sayfa etiketinde zaten var
        }
    }

    private var pageAccessibilityLabel: String {
        guard let folio else { return "Masalın sonu" }
        return "Sayfa \(folio.replacingOccurrences(of: " / ", with: ", toplam "))"
    }
}

// MARK: - Çizim yükleme

/// Sayfanın çizimi.
///
/// Yükleme asenkron; beklerken dönen bir çark değil kâğıt gösterilir. Bir
/// kitabın sayfası yüklenmez, oradadır — ve 200 ms'lik bir çark o izlenimi
/// bozacak tek şeydir.
private struct PageIllustration: View {

    let fileName: String
    let label: String?
    let theme: MP.ReadTheme
    var art: StoryPageArt? = nil
    /// Kenardan kenara: kutuyu doldurur, köşesiz. iPad açık kitabın sol
    /// sayfası da böyle; telefonda dikey sayfa da artık böyle (21 Ekim 2026).
    var bleeds: Bool = true
    var onUnavailable: () -> Void = {}
    @Environment(\.displayScale) private var displayScale

    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: bleeds ? .fill : .fit)
                        .frame(width: geo.size.width, height: geo.size.height)
                        // Çerçevesiz ve köşesiz: çizim kâğıdın bir parçası,
                        // listedeki bir küçük resim gibi kutulanmaz (§12).
                        .clipped()
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id: "\(fileName):\(art?.assetDigest ?? "")@\(Int(geo.size.width * displayScale))") {
                guard !fileName.isEmpty || art?.isBundledSpot == true else { return }
                let width = geo.size.width * displayScale
                let loaded: UIImage?
                if let art, art.isBundledSpot {
                    loaded = await ReaderImageLoader.shared.image(art: art, targetPixelWidth: width)
                } else {
                    loaded = await ReaderImageLoader.shared.image(named: fileName, targetPixelWidth: width)
                }
                guard !Task.isCancelled else { return }
                if loaded == nil { onUnavailable() }
                withAnimation(MP.M.gated(MP.M.easeOut)) { image = loaded }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(label ?? "")
        .accessibilityHidden(label == nil)
    }
}


/// Kenardan kenara çizimin alt kenarı: kâğıt, çizimin üstüne hafif bir yayla
/// biner. Çizim kutu gibi düz bir çizgiyle bitmez, sayfaya karışır.
private struct PaperLip: View {
    let theme: MP.ReadTheme

    var body: some View {
        LipShape()
            .fill(theme.paper)
            .frame(height: MP.S.x5)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private struct LipShape: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.35))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.35),
                           control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.6))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.closeSubpath()
            return p
        }
    }
}

/// VoiceOver: sayfa tek parça okunur; her yeni kelime bir eylem olarak
/// eklenir ("Yeni kelime: müjdelemek"), seçilince kartı açar.
private struct WordActions: ViewModifier {
    let words: [StoryWord]
    func body(content: Content) -> some View {
        words.reduce(AnyView(content)) { view, word in
            AnyView(view.accessibilityAction(named: "Yeni kelime: \(word.term)") {
                ReaderWordSelection.shared.selected = word
            })
        }
    }
}

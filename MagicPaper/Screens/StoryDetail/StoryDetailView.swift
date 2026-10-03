import SwiftUI

/// Masalın detayı — raftan bir kitaba dokunulduğunda açılan sayfa.
///
/// Referans uygulamaların "Book Details" ekranının MagicPaper karşılığı, ama
/// sayaçsız: okunma sayısı, beğeni, puan yok (CLAUDE.md §7). Bir masalı
/// anlatan şey kimin için yazıldığı, ne kadar sürdüğü ve nasıl başladığıdır.
///
/// Düzen: sahne (sanat setinin hero'su ya da masalın kendi mozaik kapağı)
/// ve üstünde başlık; altında künye, kaldığı yer, ilk cümleler, eylemler; en
/// altta sabit duran tek birincil eylem.
///
/// İlk sürüm, İrem'in tasarımından önce kuruldu. Veri ve davranış
/// (`StoryDetailModel`, `StoryActionList`) tasarımdan bağımsızdır; tasarım
/// gelince değişmesi beklenen yalnızca bu dosyanın düzenidir.
struct StoryDetailView: View {
    let storyID: UUID
    /// İlk çizim için; masal silinirse ya da yüklenmeden önce.
    let snapshot: Story

    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var reading: Story?

    init(story: Story) {
        self.storyID = story.id
        self.snapshot = story
    }

    /// Okuyucudan dönünce ilerleme güncel olsun diye kayıttan okunur.
    private var story: Story {
        storyManager.stories.first { $0.id == storyID } ?? snapshot
    }

    private var isPartlyRead: Bool { story.mpProgress > 0 && story.mpProgress < 1 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    tags
                    if isPartlyRead { progress }
                    if let excerpt = story.mpExcerpt { opening(excerpt) }
                    StoryActionList(story: story, onDeleted: { dismiss() })
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, MP.S.x6)
                .padding(.bottom, MP.S.x10)
            }
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topLeading) { closeButton }
        .safeAreaInset(edge: .bottom, spacing: 0) { readBar }
        .background(MP.C.surfaceApp.ignoresSafeArea())
        .mpToast($app.toast)
        // Okuyucu bu sayfanın üstünde açılır; kapanınca masalın sayfasına
        // dönülür, rafa değil — kitabı kapatan kitabı elinde tutar.
        .fullScreenCover(item: $reading) { story in
            StoryReaderView(story: story).environmentObject(app).environmentObject(settings)
        }
    }

    // MARK: - Sahne

    private var hero: some View {
        MPArtHero(backdrop: { heroBackdrop }) {
            if let mode = story.mpMode {
                Label {
                    Text(mode.title)
                } icon: {
                    MPIcon(mode.symbol, size: MP.G.sm, weight: .bold)
                }
                .font(MP.F.labelSM())
                .foregroundStyle(MP.C.textOnArtMuted)
            }
            Text(story.title)
                .font(MP.F.displayLG())
                .mpTightTracking(32)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(metaLine)
                .font(MP.F.bodySM(.semibold))
                .foregroundStyle(MP.C.textOnArtMuted)
        }
    }

    @ViewBuilder
    private var heroBackdrop: some View {
        if let art = story.mpHeroArt() {
            MPArtLayer(art: art)
        } else {
            // Sanat seti henüz görsel taşımıyor: masalın kendi kapağı, büyük.
            // Rafta gördüğü kitabın aynısı olduğu için sayfa tanıdık açılır.
            MagicPaperCoverView.thumbnail(for: story.mpMosaicCover)
        }
    }

    private var metaLine: String {
        var parts: [String] = []
        if !story.childName.isEmpty { parts.append("\(story.childName) için") }
        parts.append("\(story.pages.count) sayfa")
        parts.append("\(story.mpReadingMinutes) dk")
        return parts.joined(separator: " · ")
    }

    private var closeButton: some View {
        MPIconButton(symbol: "chevron.down", label: "Kapat", tone: .glass) { dismiss() }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.top, MP.S.x2)
    }

    // MARK: - Künye

    private var tags: some View {
        MPWrapRow(spacing: MP.S.x2) {
            if let mode = story.mpMode {
                MPBadge(title: mode.title, tone: .calm, symbol: mode.symbol)
            }
            MPBadge(title: story.mpWorld.name, tone: .neutral, symbol: story.mpWorld.symbol)
            MPBadge(title: "Sesli okuma \(story.mpReadingMinutes) dk", tone: .neutral, symbol: "clock")
            if story.isIllustrated {
                MPBadge(title: "Görselli", tone: .reward, symbol: "crown.fill")
            }
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: MP.S.x2) {
            Text("Kaldığınız yer")
                .font(MP.F.labelMD())
                .foregroundStyle(MP.C.textTitle)
            Capsule().fill(MP.C.surfaceSunken)
                .frame(height: MP.S.x2)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule().fill(MP.C.brand)
                            .frame(width: max(MP.S.x2, geo.size.width * story.mpProgress))
                    }
                }
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Kaldığınız yer: yüzde \(Int(story.mpProgress * 100))")
    }

    /// Masalın ilk cümleleri, büyük bir başharfle — kitabın ilk sayfası gibi.
    private func opening(_ excerpt: String) -> some View {
        let first = String(excerpt.prefix(1))
        let rest = String(excerpt.dropFirst())
        return VStack(alignment: .leading, spacing: MP.S.x3) {
            Text("Masal böyle başlıyor")
                .font(MP.F.labelMD())
                .foregroundStyle(MP.C.textTitle)
            (Text(first).font(MP.F.displayMD()).foregroundStyle(MP.C.brand)
             + Text(rest).font(MP.F.bodyLG()).foregroundStyle(MP.C.textBody))
                .lineSpacing(MP.S.x1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MP.S.x5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mpEdge(fill: MP.C.surfaceCard, edge: MP.C.edgeCard, radius: MP.R.card)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Birincil eylem

    private var readBar: some View {
        MPButton(
            title: isPartlyRead ? "Okumaya devam et" : "Oku",
            size: .lg,
            icon: "book",
            fullWidth: true
        ) {
            reading = story
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.top, MP.S.x3)
        .padding(.bottom, MP.S.x2)
        .background {
            MP.C.surfaceApp
                .overlay(alignment: .top) {
                    Rectangle().fill(MP.C.borderHairline).frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

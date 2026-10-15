import SwiftUI

/// Günlük · Klasik detay (`KlasikDetay`).
///
/// Kremle eriyen boyalı üst görsel, başlık, "Okumaya başla", dört eylem
/// (Dinle · Uyku modu · Listem; "Kahramanı ben" motor desteğine kadar gizli),
/// özet, anlatım seçimi, Benzerleri ve kaynak satırı.
struct ClassicDetailView: View {
    let tale: ClassicTale
    @Binding var path: [GunlukRoute]

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var library = ClassicsLibrary.shared
    @ObservedObject private var progress = ClassicProgressStore.shared
    @ObservedObject private var favorites = MPFavorites.shared
    @State private var narration: ClassicNarration = .soft
    @State private var gate = false
    @State private var sharing = false
    @State private var scrolled = false

    private let artHeight: CGFloat = 470

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MPSpacing.xxl) {
                art

                // Ana sayfanın kart dili: düz mor düğme, beyaz kartlar (lavanta
                // kenar, sert alt kenar), pastel tonlar yalnızca kutu zeminlerinde.
                VStack(spacing: MPSpacing.xxl) {
                    GunlukPrimaryButton(title: startTitle, systemImage: "play") {
                        app.readClassic(tale)
                    }
                    .padding(.top, -MPSpacing.sm)

                    GunlukSection(title: "Bu masalla") {
                        actions.padding(.horizontal, MPSpacing.lg)
                    }

                    GunlukSection(title: "Masal hakkında") {
                        VStack(alignment: .leading, spacing: MPSpacing.lg) {
                            Text(tale.summary).mpText(.body).foregroundStyle(MPColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            if tale.classic != nil { narrationPicker }
                            Text(tale.creditLine).mpText(.caption).foregroundStyle(MPColor.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, MPSpacing.lg)
                    }

                    similar
                }
                .padding(.horizontal, MPSpacing.screenH)
            }
            .padding(.bottom, GunlukLayout.bottomClearance)
            .gunlukTracksScroll($scrolled)
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) { GunlukStatusBarBackdrop(visible: scrolled) }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { narration = progress.narration(for: tale.id) }
        .fullScreenCover(isPresented: $gate) {
            ParentalGateView(onSuccess: { gate = false; sharing = true }, onCancel: { gate = false })
        }
        .sheet(isPresented: $sharing) {
            ShareSheet(items: ["Bu akşam MagicPaper'da \"\(tale.title)\" masalını okuduk."])
        }
    }

    /// Yarım kaldıysa "Devam et".
    private var startTitle: String {
        guard let entry = progress.entries[tale.id], !entry.isFinished, entry.page > 0,
              entry.narration == narration else { return "Okumaya başla" }
        return "Kaldığın yerden devam et"
    }

    // MARK: - Üst görsel

    /// Vitrinle aynı sahne: tam genişlik boyalı görsel, altta karartma ve
    /// masalın adı, alt köşeler yuvarlak ve sert kenarlı (`gunlukStage`).
    private var art: some View {
        ClassicCoverImage(asset: tale.cover, focus: tale.coverFocus, seed: tale.title, onStage: true)
            .frame(height: artHeight)
            .frame(maxWidth: .infinity)
            .overlay {
                LinearGradient(stops: [.init(color: MP.Scrim.ink.opacity(0), location: 0.5),
                                       .init(color: MP.Scrim.solid, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .clipped()
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text(tale.title).mpText(.heroTitle).foregroundStyle(MP.C.textOnArt)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(tale.fullMeta).mpText(.callout).foregroundStyle(MP.C.textOnArtMuted)
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.bottom, MPSpacing.xxl)
                // Sabit yükseklikli sahne: en büyük yazı boyutunda geri düğmesine binmez.
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
            }
            .overlay(alignment: .top) {
                HStack {
                    GunlukStageButton(systemImage: "chevron.left", label: "Geri") {
                        if !path.isEmpty { path.removeLast() }
                    }
                    Spacer()
                    GunlukStageButton(systemImage: "square.and.arrow.up", label: "Paylaş") { gate = true }
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.top, MPSize.minTouchKid)
            }
            .gunlukStage()
    }

    // MARK: - Eylemler

    /// Ana sayfadaki mod kartları gibi: pastel kutu, beyaz kare içinde simge.
    private var actions: some View {
        let saved = favorites.contains(tale.id)
        return HStack(spacing: MPSpacing.sm) {
            HomeModeTile(title: "Dinle", systemImage: "speaker.wave.2", tone: .lav) {
                MPHaptics.tap()
                app.readClassic(tale, listen: true)
            }
            .accessibilityHint("Masalı sesli okuyarak açar")
            HomeModeTile(title: "Uyku modu", systemImage: "moon", tone: .sky) {
                MPHaptics.tap()
                app.sleepSession = MPSleepSession(title: tale.title, pages: tale.text(narration).pages,
                                                  storyID: tale.id)
            }
            HomeModeTile(title: saved ? "Listemde" : "Listeme ekle", systemImage: saved ? "checkmark" : "plus",
                         tone: .peach) {
                let now = favorites.toggle(tale.id)
                MPHaptics.tap()
                app.showToast(now ? "Listene eklendi" : "Listenden çıkarıldı", symbol: now ? "checkmark" : "minus")
            }
        }
    }

    // MARK: - Anlatım

    private var narrationPicker: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text("Anlatım").mpText(.eyebrow).foregroundStyle(MPColor.textSecondary)
            MPSegmented(options: ClassicNarration.allCases.map { ($0, $0.title) },
                        selection: Binding(get: { narration }, set: { value in
                            narration = value
                            progress.setNarration(value, for: tale.id)
                        }),
                        track: MPColor.backgroundSunken)
            // Yaş yazılmaz: masalın kendi yaş aralığıyla (üstte) çelişmesin.
            Text(narration == .soft
                 ? "Küçükler için: korkutucu sahneler çıkarıldı."
                 : "Büyükler için: \(tale.byline) metnine yakın.")
                .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Benzerleri

    @ViewBuilder
    private var similar: some View {
        let items = library.catalog.similar(to: tale)
        if !items.isEmpty {
            GunlukSection(title: "Benzerleri") {
                GunlukRow(inset: MPSpacing.lg) {
                    ForEach(items) { item in
                        ClassicShelfCard(item: item, width: 120, height: 166) {
                            switch item {
                            case .tale(let t): path.append(.tale(t.id))
                            case .series(let s, _): path.append(.series(s.id))
                            }
                        }
                    }
                }
            }
        }
    }
}

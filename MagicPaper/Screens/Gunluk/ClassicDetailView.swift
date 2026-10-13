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

    private let artHeight: CGFloat = 470

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                art
                VStack(spacing: MPSpacing.xs) {
                    Text(tale.title).mpText(.title1).foregroundStyle(MPColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text(tale.fullMeta).mpText(.callout).foregroundStyle(MPColor.textSecondary)
                }
                .padding(.top, -(MPSize.buttonHeight + 2))

                MPButton(title: startTitle, systemImage: "book.fill", fullWidth: true) {
                    app.readClassic(tale)
                }
                .padding(.top, MPSpacing.xl)

                actions.padding(.top, MPSpacing.lg + 2)

                Text(tale.summary).mpText(.body).foregroundStyle(MPColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, MPSpacing.xxl)

                if tale.classic != nil { narrationPicker.padding(.top, MPSpacing.xxl) }

                similar

                Text(tale.creditLine).mpText(.caption).foregroundStyle(MPColor.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, MPSpacing.xxl + 2)
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl + MPSpacing.sm)
        }
        .ignoresSafeArea(edges: .top)
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

    private var art: some View {
        ClassicCoverImage(asset: tale.cover, focus: tale.coverFocus, seed: tale.title)
            .frame(height: artHeight)
            .frame(maxWidth: .infinity)
            .overlay {
                // Görselin alt kenarı kâğıda erir (malzeme taklidi).
                LinearGradient(stops: [.init(color: MPColor.backgroundKid.opacity(0), location: 0.46),
                                       .init(color: MPColor.backgroundKid, location: 0.92)],
                               startPoint: .top, endPoint: .bottom)
            }
            .clipped()
            .overlay(alignment: .top) {
                HStack {
                    glassButton("chevron.left", label: "Geri") { if !path.isEmpty { path.removeLast() } }
                    Spacer()
                    glassButton("square.and.arrow.up", label: "Paylaş") { gate = true }
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.top, MPSize.minTouchKid)
            }
            .padding(.horizontal, -MPSpacing.screenH)
    }

    private func glassButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MPIcon(icon, size: 18, weight: .semibold)
                .foregroundStyle(MPColor.textPrimary)
                .frame(width: MPSize.minTouchParent, height: MPSize.minTouchParent)
                .background(.ultraThinMaterial, in: Circle())
                .background(MPColor.backgroundSurface.opacity(0.6), in: Circle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(label)
    }

    // MARK: - Eylemler

    private var actions: some View {
        let saved = favorites.contains(tale.id)
        return HStack(alignment: .top, spacing: 0) {
            action("speaker.wave.2.fill", "Dinle") { app.readClassic(tale, listen: true) }
            action("moon.stars.fill", "Uyku modu") {
                app.sleepSession = MPSleepSession(title: tale.title, pages: tale.text(narration).pages,
                                                  storyID: tale.id)
            }
            action(saved ? "checkmark" : "plus", saved ? "Listemde" : "Listem") {
                let now = favorites.toggle(tale.id)
                MPHaptics.tap()
                app.showToast(now ? "Listene eklendi" : "Listenden çıkarıldı", symbol: now ? "checkmark" : "minus")
            }
        }
    }

    private func action(_ icon: String, _ title: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: MPSpacing.xs) {
                MPIcon(icon, size: 20, weight: .semibold)
                    .foregroundStyle(MPColor.textPrimary)
                    .frame(width: 48, height: 48)
                    .background(MPColor.backgroundSunken, in: Circle())
                Text(title).mpText(.caption).foregroundStyle(MPColor.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: MPSize.minTouchKid)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Anlatım

    private var narrationPicker: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md - 2) {
            Text("Anlatım").mpText(.eyebrow).foregroundStyle(MPColor.textSecondary)
            MPSegmented(options: ClassicNarration.allCases.map { ($0, $0.title) },
                        selection: Binding(get: { narration }, set: { value in
                            narration = value
                            progress.setNarration(value, for: tale.id)
                        }),
                        track: MPColor.backgroundSunken)
            Text(narration == .soft
                 ? "3-5 yaş için. Korkutucu sahneler çıkarıldı."
                 : "6 yaş ve üstü. \(tale.byline) metnine yakın.")
                .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Benzerleri

    @ViewBuilder
    private var similar: some View {
        let items = library.catalog.similar(to: tale)
        if !items.isEmpty {
            GunlukSectionHeader(title: "Benzerleri").padding(.top, MPSpacing.xxxl + 2)
            GunlukRow {
                ForEach(items) { item in
                    ClassicShelfCard(item: item, width: 120, height: 166) {
                        switch item {
                        case .tale(let t): path.append(.tale(t.id))
                        case .series(let s, _): path.append(.series(s.id))
                        }
                    }
                }
            }
            .padding(.top, MPSpacing.md + 2)
        }
    }
}

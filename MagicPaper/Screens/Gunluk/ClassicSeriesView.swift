import SwiftUI

/// Günlük · Seri klasik (`SeriKlasik`): Keloğlan, Nasreddin Hoca …
///
/// Üst görsel, başlık, "N. masaldan devam et", özet ve bölüm listesi.
/// Bölümler hepsi açık: Günlük'te seri günde bir bölüm açılan Seri masal
/// (FAZ 13) değil, bir kitabın bölümleri.
struct ClassicSeriesView: View {
    let series: ClassicSeries
    @Binding var path: [GunlukRoute]

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var library = ClassicsLibrary.shared
    @ObservedObject private var favorites = MPFavorites.shared
    @State private var scrolled = false

    private var episodes: [ClassicTale] { library.catalog.episodes(of: series.id) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MPSpacing.xxl) {
                art

                // Detay ekranıyla aynı kart dili.
                VStack(spacing: MPSpacing.xxl) {
                    if let next = library.nextEpisode(of: series.id) {
                        GunlukPrimaryButton(title: continueTitle(next), systemImage: "play") {
                            app.readClassic(next)
                        }
                        .padding(.top, -MPSpacing.sm)
                    }

                    GunlukSection(title: series.bookTitle) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(series.summary).mpText(.body).foregroundStyle(MPColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, MPSpacing.md)
                            ForEach(episodes) { episode in
                                EpisodeRow(series: series, episode: episode, state: library.state(of: episode)) {
                                    app.readClassic(episode)
                                }
                            }
                            Text(series.creditLine).mpText(.caption).foregroundStyle(MPColor.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, MPSpacing.md)
                        }
                        .padding(.horizontal, MPSpacing.lg)
                    }
                }
                .padding(.horizontal, MPSpacing.screenH)
            }
            .padding(.bottom, GunlukLayout.bottomClearance)
            .mpTracksScroll($scrolled)
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) { MPStatusBarBackdrop(visible: scrolled) }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func continueTitle(_ next: ClassicTale) -> String {
        let n = next.episode ?? 1
        if n == 1 && library.state(of: next).status == .unread { return "Okumaya başla" }
        return "\(n). \(series.unitName == "masal" ? "masaldan" : "bölümden") devam et"
    }

    private static let artHeight: CGFloat = 400

    private var art: some View {
        let saved = favorites.contains(series.id)
        return MPArtHero(height: Self.artHeight) {
            ClassicCoverImage(asset: series.cover, focus: series.coverFocus, seed: series.title, onStage: true)
                .frame(height: Self.artHeight)
                .frame(maxWidth: .infinity)
        } content: {
            Text(series.title).mpText(.heroTitle).foregroundStyle(MP.C.textOnArt)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text("\(series.byline) · \(episodes.count) \(series.unitName) · \(series.ageLabel)")
                .mpText(.callout).foregroundStyle(MP.C.textOnArtMuted)
        }
        // Sabit yükseklikli sahne: en büyük yazı boyutunda geri düğmesine binmez.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .lineLimit(3)
        .minimumScaleFactor(0.6)
        .frame(height: Self.artHeight)
        .overlay(alignment: .top) {
            HStack {
                GunlukStageButton(systemImage: "chevron.left", label: "Geri") {
                    if !path.isEmpty { path.removeLast() }
                }
                Spacer()
                GunlukStageButton(systemImage: saved ? "checkmark" : "plus",
                                  label: saved ? "Listemden çıkar" : "Listeme ekle") {
                    let now = favorites.toggle(series.id)
                    MPHaptics.tap()
                    app.showToast(now ? "Listene eklendi" : "Listenden çıkarıldı", symbol: now ? "checkmark" : "minus")
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSize.minTouchKid)
        }
        .gunlukStage()
    }
}

/// Bölüm satırı: seri kapağından yatay kırpım, numara, ilerleme; başlık,
/// tek satır özet, durum.
struct EpisodeRow: View {
    let series: ClassicSeries
    let episode: ClassicTale
    let state: ClassicsLibrary.EpisodeState
    let action: () -> Void

    private var status: String {
        switch state.status {
        case .finished: return "Okundu"
        case .current: return "Kaldığın yer"
        case .unread: return "\(episode.minutes) dk"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.md + 2) {
                ClassicCoverImage(asset: series.cover, focus: series.coverFocus, seed: series.title)
                    .frame(width: 118, height: 70)
                    .overlay(MP.Scrim.solid.opacity(0.45))
                    .overlay {
                        Text("\(episode.episode ?? 0)").mpText(.title2).foregroundStyle(MP.C.textOnArt)
                    }
                    .overlay(alignment: .bottom) {
                        if state.fraction > 0 {
                            GeometryReader { geo in
                                Capsule().fill(MP.C.textOnArt.opacity(0.4))
                                    .overlay(alignment: .leading) {
                                        Capsule().fill(MP.C.textOnArt).frame(width: geo.size.width * state.fraction)
                                    }
                            }
                            .frame(height: 3)
                            .padding(.horizontal, MPSpacing.sm)
                            .padding(.bottom, MPSpacing.xs + 1)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: MPRadius.sm, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(episode.title).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(episode.summary).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        .lineLimit(2).multilineTextAlignment(.leading)
                    Text(status).mpText(.caption)
                        .foregroundStyle(state.status == .current ? MPColor.textPrimary : MPColor.textSecondary)
                        .padding(.top, MPSpacing.xxs / 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, MPSpacing.md + 2)
            .overlay(alignment: .top) { Rectangle().fill(MPColor.borderKidDivider).frame(height: 1) }
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(episode.episode ?? 0). \(series.unitName): \(episode.title). \(status)")
    }
}

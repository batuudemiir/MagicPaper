import SwiftUI

/// "Devam eden seri" satırı: Ana sayfa (11) ve Kitaplık (16), FAZ 13.
///
/// İki sakin durum: bölüm hazır, ya da bir sonraki bölüm öncekinden sonraki
/// gün açılır. Geri sayım yok, saat yok, "kaçırma" yok: kart ailenin bir
/// sonraki bölümü bulduğu yer, geri gelmek için bir sebep değil.
struct SeriesCard: View {

    let childID: UUID

    @ObservedObject private var series = SeriesManager.shared
    @ObservedObject private var library = StoryGenerationManager.shared
    @EnvironmentObject private var app: MPAppState

    var body: some View {
        switch series.cardState(for: childID) {
        case .ready(let storyID, let episode, let title):
            Button { openSeries() } label: {
                row(title: title, subtitle: SeriesCopy.readyTitle(episode), showsChevron: true)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(SeriesCopy.readyAccessibility(episode, title))
            .accessibilityAddTraits(.isButton)
        case .waiting(let episode, let title):
            Button { openSeries() } label: {
                row(title: title, subtitle: SeriesCopy.waitingTitle(episode), showsChevron: true)
            }
            .buttonStyle(MPPressStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(SeriesCopy.waitingAccessibility(episode, title))
                .accessibilityHint(SeriesCopy.waitingNote)
        case nil:
            EmptyView()
        }
    }

    private func row(title: String, subtitle: String, showsChevron: Bool) -> some View {
        HStack(spacing: MPSpacing.lg) {
            MPIcon("pawprint", size: 30, weight: .semibold)
                .foregroundStyle(MPWorldTone.peach.deep)
                .frame(width: 62, height: 62)
                .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.tile))
                .mpShadow(.control)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text(title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                if let progress = series.readProgress(for: childID) {
                    HStack(spacing: MPSpacing.xxs) {
                        ForEach(0..<progress.total, id: \.self) { i in
                            Capsule()
                                .fill(i < progress.read ? MPWorldTone.peach.deep : MPColor.backgroundSurface)
                                .frame(height: 5)
                        }
                    }
                    .frame(maxWidth: 200)
                    .padding(.top, MPSpacing.xs)
                }
            }
            Spacer(minLength: 0)
            if showsChevron { MPChevron().accessibilityHidden(true) }
        }
        .padding(MPSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mpKidSurface(MPWorldTone.peach.soft, edge: MPWorldTone.peach.edge)
    }

    /// 18 · Seri masal; bölüm oradan okunur.
    private func openSeries() {
        series.refreshUnlocks(for: childID)
        withAnimation(MP.M.gated(MP.M.base)) { app.seriesChildID = childID }
    }
}

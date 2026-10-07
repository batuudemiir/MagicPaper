import SwiftUI

/// 18 · Seri masal (`SeriMasal`).
///
/// Beş bölüm: okunanlar tikli, açılan bölüm "Bu akşam hazır", bir sonraki
/// "Yarın". Bölüm kilidi FAZ 13 kuralı: bir bölüm, öncekinin okunduğu günün
/// ertesi günü açılır. Geri sayım yok.
struct SeriesView: View {
    let childID: UUID

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var series = SeriesManager.shared
    @ObservedObject private var library = StoryGenerationManager.shared

    private struct Row: Identifiable {
        enum State { case read, ready(UUID), tomorrow, later }
        let id: Int
        let title: String
        let detail: String
        let state: State
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if let current = series.openSeries(for: childID) {
                VStack(alignment: .leading, spacing: MPSpacing.lg) {
                    header(current)
                    progressCard(rows(current))
                    VStack(spacing: MPSpacing.md) {
                        ForEach(rows(current)) { row in episodeRow(row) }
                    }
                    Text("Her akşam yeni bir bölüm açılır. Bölümler bir öncekinin kaldığı yerden devam eder.")
                        .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.bottom, MPSpacing.xxxl)
            } else {
                VStack {
                    backButton
                    MPStateView(mascot: .reading, tone: .peach, title: SeriesCopy.completedTitle,
                                message: SeriesCopy.completedBody) {
                        MPButton(title: "Kitaplığa dön") { close() }
                    }
                }
                .padding(.horizontal, MPSpacing.screenH)
            }
        }
        .background(alignment: .top) {
            HeaderWash(height: 300, colors: [MPWorldTone.peach.soft, MPWorldTone.yellow.soft, MPWorldTone.pink.soft])
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .onAppear { series.refreshUnlocks(for: childID) }
    }

    private func close() {
        withAnimation(MP.M.gated(MP.M.base)) { app.seriesChildID = nil }
    }

    private var backButton: some View {
        HStack {
            MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri", action: close)
            Spacer()
        }
        .padding(.top, MPSpacing.sm)
    }

    private func header(_ s: StorySeries) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            backButton
            HStack(spacing: MPSpacing.lg) {
                MPIcon("pawprint", size: 44, weight: .semibold)
                    .foregroundStyle(MPWorldTone.peach.deep)
                    .frame(width: 104, height: 104)
                    .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.hero))
                    .rotationEffect(.degrees(-4))
                    .mpShadow(.raised)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text("Seri masal").mpText(.eyebrow).foregroundStyle(MPColor.textSecondary)
                    Text(s.firstStoryTitle).mpText(.title1).foregroundStyle(MPColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(s.childName) için").mpText(.callout).foregroundStyle(MPColor.textSecondary)
                }
            }
        }
    }

    private func rows(_ s: StorySeries) -> [Row] {
        var out = [Row(id: 1, title: s.firstStoryTitle,
                       detail: "\(library.getStory(id: s.firstStoryID)?.pages.count ?? 0) sayfa", state: .read)]
        var previousRead = true
        for episode in s.episodes {
            let state: Row.State
            if episode.read != nil { state = .read }
            else if let id = episode.storyID { state = .ready(id) }
            else { state = previousRead ? .tomorrow : .later }
            previousRead = episode.read != nil
            out.append(Row(id: episode.number, title: episode.title,
                           detail: "\(episode.pages.count) sayfa", state: state))
        }
        return out
    }

    private func progressCard(_ rows: [Row]) -> some View {
        let read = rows.filter { if case .read = $0.state { return true }; return false }.count
        return HStack(spacing: MPSpacing.md) {
            Text("\(read) / \(rows.count) bölüm").mpText(.bodyStrong).fontWeight(.black)
                .foregroundStyle(MPColor.textPrimary)
            GeometryReader { geo in
                Capsule().fill(MPColor.backgroundSunken)
                    .overlay(alignment: .leading) {
                        Capsule().fill(MPWorldTone.peach.deep)
                            .frame(width: geo.size.width * CGFloat(read) / CGFloat(max(rows.count, 1)))
                    }
            }
            .frame(height: 10)
        }
        .padding(.horizontal, MPSpacing.lg)
        .padding(.vertical, MPSpacing.md)
        .background(MPColor.backgroundSurface.opacity(0.85), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rows.count) bölümden \(read) bölüm okundu")
    }

    @ViewBuilder
    private func episodeRow(_ row: Row) -> some View {
        let isReady: Bool = { if case .ready = row.state { return true }; return false }()
        let isLocked: Bool = { switch row.state { case .tomorrow, .later: return true; default: return false } }()
        HStack(spacing: MPSpacing.md) {
            Text("\(row.id)").mpText(.cardTitle).foregroundStyle(MPWorldTone.peach.deep)
                .frame(width: 40, height: 40)
                .background(MPWorldTone.peach.soft, in: RoundedRectangle(cornerRadius: MPRadius.sm))
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(isReady ? "Bu akşam hazır" : row.detail).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
            }
            Spacer(minLength: MPSpacing.sm)
            switch row.state {
            case .read:
                MPIcon("checkmark.circle", size: 26, weight: .semibold).foregroundStyle(MPColor.statusSuccess)
                    .accessibilityLabel("Okundu")
            case .ready(let id):
                MPButton(title: "Oku", systemImage: "play.fill", size: .small) {
                    if let story = library.getStory(id: id) { app.read(story) }
                }
            case .tomorrow:
                Label("Yarın", systemImage: "lock").mpText(.callout).foregroundStyle(MPColor.textSecondary)
            case .later:
                MPIcon("lock", size: 18, weight: .semibold).foregroundStyle(MPColor.textTertiary)
                    .accessibilityLabel("Daha sonra")
            }
        }
        .padding(MPSpacing.lg)
        .background(isReady ? MPWorldTone.sky.soft : (isLocked ? MPColor.backgroundSunken : MPColor.backgroundSurface),
                    in: RoundedRectangle(cornerRadius: MPRadius.card))
        .opacity(isLocked ? 0.8 : 1)
        .accessibilityElement(children: .combine)
    }
}

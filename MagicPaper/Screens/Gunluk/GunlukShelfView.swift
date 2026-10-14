import SwiftUI

/// Günlük · Kategori rafı (`GunlukRaf`) ve arama.
///
/// Başlık, alt başlık, çipler (Hepsi · Seriler · 5 dakika · Sesli) ve iki
/// sütunlu kapak ızgarası. Kategoriler'den gelindiyse yaş bandı çipi de var.
struct GunlukShelfView: View {
    let shelf: ClassicShelf?
    var ageBand: MPAgeRange? = nil
    var startsSearching = false
    @Binding var path: [GunlukRoute]

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var library = ClassicsLibrary.shared
    @State private var narrow: Narrow = .all
    @State private var query = ""
    @State private var band: MPAgeRange?
    @FocusState private var searchFocused: Bool

    enum Narrow: Hashable { case all, series, short, voiced }

    init(shelf: ClassicShelf?, ageBand: MPAgeRange? = nil, startsSearching: Bool = false,
         path: Binding<[GunlukRoute]>) {
        self.shelf = shelf
        self.ageBand = ageBand
        self.startsSearching = startsSearching
        _path = path
        _band = State(initialValue: ageBand)
    }

    private var title: String {
        if startsSearching { return "Masal ara" }
        return shelf?.title ?? "Bütün masallar"
    }

    private var subtitle: String {
        if startsSearching { return "Adını hatırladığın masalı bul" }
        return shelf?.subtitle ?? "Günlük'teki her masal"
    }

    private var items: [ClassicItem] {
        var items = startsSearching ? library.catalog.search(query) : library.items(in: shelf, ageBand: band)
        if startsSearching, let band {
            items = items.filter { $0.ageMin <= band.band.upperBound && $0.ageMax >= band.band.lowerBound }
        }
        switch narrow {
        case .all: return items
        case .series: return items.filter { if case .series = $0 { return true } else { return false } }
        case .short: return items.filter { if case .tale(let t) = $0 { return t.minutes <= 5 } else { return false } }
        case .voiced: return []
        }
    }

    private var originals: [ClassicsLibrary.Original] {
        guard shelf == .uyku, narrow == .all, !startsSearching else { return [] }
        return library.originals(in: .uyku)
    }

    var body: some View {
        GeometryReader { geo in
            // Izgara rafın kartının içinde: iki sütun, kart iç boşluğu kadar içeride.
            let cardWidth = max((geo.size.width - MPSpacing.screenH * 2 - MPSpacing.lg * 2 - 14) / 2, 96)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                    VStack(alignment: .leading, spacing: MPSpacing.lg) {
                        HStack(spacing: MPSpacing.md) {
                            GunlukStageButton(systemImage: "chevron.left", label: "Geri") {
                                if !path.isEmpty { path.removeLast() }
                            }
                            if let shelf {
                                MPIcon(shelf.symbol, size: MP.G.md, weight: .semibold)
                                    .foregroundStyle(shelf.tone.deep)
                                    .frame(width: MPSize.circleButton, height: MPSize.circleButton)
                                    .background(shelf.tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.md,
                                                                                       style: .continuous))
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.top, MPSpacing.sm)

                        VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                            Text(title).mpText(.pageTitle).foregroundStyle(MPColor.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                            Text(subtitle).mpText(.body).foregroundStyle(MPColor.textSecondary)
                        }

                        if startsSearching { searchField }

                        GunlukRow(spacing: MPSpacing.sm) {
                            if let current = band {
                                GunlukChip(title: current.title, isSelected: true, trailingIcon: "xmark") { band = nil }
                                    .accessibilityLabel("\(current.title) süzgecini kaldır")
                            }
                            GunlukChip(title: "Hepsi", isSelected: narrow == .all) { narrow = .all }
                            if shelf != .seriler {
                                GunlukChip(title: "Seriler", isSelected: narrow == .series) { narrow = .series }
                            }
                            if shelf != .besDakika {
                                GunlukChip(title: "5 dakika", isSelected: narrow == .short) { narrow = .short }
                            }
                            // "Sesli": seslendirilmiş masal gelince görünür.
                            if !library.items(in: .sesli).isEmpty {
                                GunlukChip(title: "Sesli", isSelected: narrow == .voiced) { narrow = .voiced }
                            }
                        }
                    }

                    results(cardWidth: cardWidth)
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.bottom, GunlukLayout.bottomClearance)
            }
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { if startsSearching { searchFocused = true } }
    }

    /// Ana sayfa dilinde arama alanı: beyaz, lavanta kenar, sert alt kenar.
    private var searchField: some View {
        HStack(spacing: MPSpacing.md - 2) {
            MPIcon("magnifyingglass", size: MP.G.md, weight: .semibold).foregroundStyle(MPColor.actionPrimary)
                .accessibilityHidden(true)
            TextField("Masal ara", text: $query)
                .mpText(.bodyStrong)
                .foregroundStyle(MPColor.textPrimary)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .accessibilityLabel("Masal ara")
            if !query.isEmpty {
                Button { query = "" } label: {
                    MPIcon("xmark", size: MP.G.sm, weight: .bold).foregroundStyle(MPColor.textSecondary)
                        .frame(width: MPSize.minTouchParent, height: MPSize.minTouchParent)
                }
                .buttonStyle(MPPressStyle())
                .accessibilityLabel("Aramayı temizle")
            }
        }
        .padding(.leading, MPSpacing.lg)
        .padding(.trailing, MPSpacing.xs)
        .frame(minHeight: MPSize.inputHeight)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.input)
    }

    private var count: Int { items.count + originals.count }

    /// Sonuçlar tek kartta, başlığı sayı: "12 masal".
    @ViewBuilder
    private func results(cardWidth: CGFloat) -> some View {
        let height = (cardWidth * 4 / 3).rounded()
        let columns = [GridItem(.fixed(cardWidth), spacing: 14, alignment: .top),
                       GridItem(.fixed(cardWidth), spacing: 14, alignment: .top)]
        if count == 0 {
            emptyState
        } else {
            GunlukSection(title: "\(count) masal") {
                LazyVGrid(columns: columns, alignment: .leading, spacing: MPSpacing.xl) {
                    ForEach(originals) { original in
                        ClassicShelfCard(title: original.story.title, meta: original.meta, cover: original.cover.cover,
                                         focus: original.cover.coverFocus, width: cardWidth, height: height) {
                            app.readOriginal(original.story)
                        }
                    }
                    ForEach(items) { item in
                        ClassicShelfCard(item: item, width: cardWidth, height: height) {
                            switch item {
                            case .tale(let tale): path.append(.tale(tale.id))
                            case .series(let series, _): path.append(.series(series.id))
                            }
                        }
                    }
                }
                .padding(.horizontal, MPSpacing.lg)
                .padding(.bottom, MP.E.widthLG)
            }
        }
    }

    /// Sonuç yok: suçlamayan, sakin bir cümle ve düşünceli Ragi (ekranda tek maskot).
    private var emptyState: some View {
        VStack(spacing: MPSpacing.md) {
            MascotImage(mascot: .thinking, width: 120).accessibilityHidden(true)
            Text(startsSearching && !query.isEmpty ? "Bu adla bir masal bulamadık." : "Bu rafta henüz masal yok.")
                .mpText(.headline).foregroundStyle(MPColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(startsSearching ? "Başka bir kelimeyle dene ya da raflara göz at." : "Yeni masallar yolda.")
                .mpText(.body).foregroundStyle(MPColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(MPSpacing.xl)
        .frame(maxWidth: .infinity)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
    }
}

import SwiftUI

/// Profil → Masal dolabım: tam boy insan kahraman (22 Kasım 2026, İrem; teslim
/// "MagicPaper-Tam-Dolap-v2", `design-handoff/dolap/01-iOS-Handoff.md`).
///
/// Üstte prova nişinde kahraman (tam boy ya da yakın yüz), altında üç sabit
/// bölüm (Kahramanım · Giysiler · Aksesuarlar), her birinde yatay kayan sekmeler
/// ve dikey kayan raf. Yüzle ilgili seçimde kamera yaklaşır, giysi seçiminde
/// tam boya döner; çocuk elle değiştirebilir. Ekranda tek mor eylem: kaydet.
///
/// Kurallar `HeroFigure.selecting` (paketin `secim.js`'i): başlangıç yüzü
/// yalnızca kimliği, kombin yalnızca giysiyi değiştirir; başörtüsü saçı saklar.
/// Kayıt çocuk profiline tek işlemde (`HeroLookStore`), hayvan kahramanlar eski
/// dolapta (`HeroWardrobeView`).
struct HeroStudioView: View {
    let profile: UserProfile
    /// "Tür" rafında bir hayvan seçildi: eski dolaba geçilir (`HeroDressingRoom`).
    var onChooseAnimal: (HeroLook.Kind) -> Void = { _ in }

    @EnvironmentObject private var app: MPAppState
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let catalog = HeroFigureCatalog.shared

    @State private var family: Family = .clothes
    @State private var shelf: Shelf = .outfits
    @State private var draft = HeroFigure.starter
    @State private var saved = HeroFigure.starter
    /// Tam boy kaydı hiç yoksa ilk kayıt da bir değişikliktir.
    @State private var hasSavedFigure = false
    @State private var history: [HeroFigure] = []
    @State private var zoomed = false
    @State private var tilt: Double = 0
    @State private var asksToLeave = false

    // MARK: Bölümler

    enum Family: String, CaseIterable, Identifiable {
        case me, clothes, accessories
        var id: String { rawValue }
        var title: String {
            switch self {
            case .me: "Kahramanım"
            case .clothes: "Giysiler"
            case .accessories: "Aksesuarlar"
            }
        }
        var shelves: [Shelf] {
            switch self {
            case .me: [.kind, .starters, .slot(.skin), .slot(.face), .slot(.eye), .slot(.eyeShape), .slot(.brow),
                       .slot(.nose), .slot(.hair), .slot(.dye), .slot(.expression), .slot(.detail)]
            case .clothes: [.outfits, .slot(.top), .slot(.bottom), .slot(.one), .slot(.shoe)]
            case .accessories: [.slot(.head), .slot(.glasses), .slot(.bag)]
            }
        }
    }

    enum Shelf: Hashable {
        case kind, starters, outfits
        case slot(HeroFigure.Slot)

        var tab: String {
            switch self {
            case .kind: "Tür"
            case .starters: "Başlangıçlar"
            case .outfits: "Takımlar"
            case .slot(let slot):
                switch slot {
                case .skin: "Ten"
                case .face: "Yüz"
                case .eye: "Göz rengi"
                case .eyeShape: "Göz biçimi"
                case .brow: "Kaş"
                case .nose: "Burun"
                case .hair: "Saç"
                case .dye: "Saç rengi"
                case .expression: "İfade"
                case .detail: "Yüz detayı"
                case .top: "Üst"
                case .bottom: "Alt"
                case .one: "Tek parça"
                case .shoe: "Ayakkabı"
                case .head: "Başlık ve örtü"
                case .glasses: "Gözlük"
                case .bag: "Çanta"
                }
            }
        }

        var heading: String {
            switch self {
            case .kind: "Kahramanın kim?"
            case .starters: "Bir başlangıç yüzü seç"
            case .outfits: "Masal takımları"
            case .slot(let slot):
                switch slot {
                case .skin: "Ten tonları"
                case .face: "Yüz biçimleri"
                case .eye: "Göz renkleri"
                case .eyeShape: "Göz biçimleri"
                case .brow: "Kaş biçimleri"
                case .nose: "Burun biçimleri"
                case .hair: "Saç modelleri"
                case .dye: "Saç renkleri"
                case .expression: "Yüz ifadeleri"
                case .detail: "Yüz detayları"
                case .top: "Üst giysiler"
                case .bottom: "Alt giysiler"
                case .one: "Tek parça giysiler"
                case .shoe: "Ayakkabılar"
                case .head: "Şapkalar ve başörtüleri"
                case .glasses: "Gözlükler"
                case .bag: "Çantalar"
                }
            }
        }

        /// Yüzle ilgili raf: kamera yaklaşır (`studio.js faceSlots`).
        var showsFace: Bool {
            switch self {
            case .starters: true
            case .kind, .outfits: false
            case .slot(let slot): [.skin, .eye, .eyeShape, .brow, .nose, .face, .hair, .dye, .detail,
                                   .expression, .head, .glasses].contains(slot)
            }
        }
    }

    /// Başlangıç yüzlerinin adları: saçlarından (`studio.js startNames`).
    private static let starterNames = ["Çift örgü", "Kısa dalga", "Kıvırcık çift topuz", "Küt kahkül",
                                       "Uzun dalga", "Yüksek topuz", "Kısacık", "Saçsız"]

    private var dirty: Bool { draft != saved || !hasSavedFigure }

    // MARK: Gövde

    var body: some View {
        VStack(spacing: 0) {
            // Üst bölüm krem kâğıtta: başlık ve prova nişi (referans: Dolap-ve-yuz.png).
            VStack(spacing: 0) {
                MPTopBar(title: "Masal dolabım", onBack: leave) {
                    MPCircleButton(systemImage: "arrow.uturn.backward", accessibilityLabel: "Son seçimi geri al", action: undo)
                        .disabled(history.isEmpty)
                        .opacity(history.isEmpty ? 0.4 : 1)
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.top, MPSpacing.lg)

                stage
                    .padding(.horizontal, MPSpacing.screenH)
                    .padding(.top, MPSpacing.md)
            }
            .background(MP.C.homePaper.ignoresSafeArea(edges: .top))

            familyRow
                .padding(.top, MPSpacing.sm)
            shelfRow
                .padding(.top, MPSpacing.md)

            ScrollView(showsIndicators: false) {
                rack
                    .padding(.horizontal, MPSpacing.screenH)
                    .padding(.vertical, MPSpacing.lg)
            }

            MPButton(title: "Kahramanımı kaydet", size: .hero, fullWidth: true, action: save)
                .disabled(!dirty)
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.top, MPSpacing.sm)
                .padding(.bottom, GunlukLayout.bottomClearance)
        }
        .background(MPColor.backgroundSurface.ignoresSafeArea())
        .task(id: profile.id) { load() }
        .confirmationDialog("Dolaptan çıkalım mı?", isPresented: $asksToLeave, titleVisibility: .visible) {
            Button("Kaydetmeden çık", role: .destructive) { close() }
            Button("Denemeye devam et", role: .cancel) {}
        } message: {
            Text("Son değişikliklerini kaydedebilir ya da önceki görünümüne dönebilirsin.")
        }
    }

    // MARK: Prova nişi

    private var stage: some View {
        let height: CGFloat = typeSize.isAccessibilitySize ? 200 : 290
        return ZStack(alignment: .bottomTrailing) {
            // Kemerli prova nişi: üstü yarım daire, altı kâğıdın kenarına iner.
            GeometryReader { geo in
                let width = min(geo.size.width * 0.62, geo.size.height * 0.85)
                UnevenRoundedRectangle(topLeadingRadius: width / 2, topTrailingRadius: width / 2, style: .continuous)
                    .fill(MP.C.heroNiche)
                    .frame(width: width, height: geo.size.height - MPSpacing.lg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .accessibilityHidden(true)
            HeroFigureView(figure: draft, frame: zoomed ? .face : .body)
                .rotationEffect(.degrees(tilt), anchor: .bottom)
                .padding(.top, MPSpacing.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .animation(MP.M.gated(MP.M.base), value: zoomed)
            Button {
                MPHaptics.tap()
                zoomed.toggle()
            } label: {
                Text(zoomed ? "Tam boy gör" : "Yüzü gör").mpText(.supporting).fontWeight(.bold)
                    .foregroundStyle(MPColor.textPrimary)
                    .padding(.horizontal, MPSpacing.md)
                    .frame(minHeight: MPSize.chipHeightKid)
                    .background(MPColor.backgroundSurface, in: Capsule())
                    .overlay(Capsule().strokeBorder(MPColor.borderKid, lineWidth: 1))
            }
            .buttonStyle(MPPressStyle())
            .padding(.bottom, MPSpacing.md)
            .accessibilityHint(zoomed ? "Kahramanın tamamını gösterir" : "Kahramanın yüzünü yakından gösterir")
        }
        .frame(height: height)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Kahramanın provası")
    }

    // MARK: Bölüm ve sekme satırı

    /// Üç sabit bölüm, alt çizgili sekme: seçili olan mor ve çizgili.
    private var familyRow: some View {
        HStack(spacing: 0) {
            ForEach(Family.allCases) { item in
                let selected = item == family
                Button {
                    MPHaptics.selection()
                    family = item
                    show(item.shelves[0])
                } label: {
                    VStack(spacing: MPSpacing.xs) {
                        Text(item.title).mpText(.cardTitle)
                            .foregroundStyle(selected ? MPColor.actionPrimary : MPColor.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Capsule().fill(selected ? MPColor.actionPrimary : Color.clear)
                            .frame(height: MP.E.widthLG)
                    }
                    .frame(maxWidth: .infinity, minHeight: MP.S.tapMin)
                    .contentShape(Rectangle())
                }
                .buttonStyle(MPPressStyle(.highlight))
                .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.horizontal, MPSpacing.screenH)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Dolap bölümleri")
    }

    private var shelfRow: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MPSpacing.xs) {
                    // Alt sekmeler yumuşak haplar: seçili olan lavanta.
                    ForEach(family.shelves, id: \.self) { item in
                        let selected = item == shelf
                        Button {
                            MPHaptics.selection()
                            show(item)
                        } label: {
                            Text(item.tab).mpText(.supporting).fontWeight(.bold)
                                .foregroundStyle(MPColor.textPrimary)
                                .padding(.horizontal, MPSpacing.md)
                                .frame(minHeight: MPSize.chipHeightKid)
                                .background(selected ? MPColor.cardSoft : MPColor.segmentTrack, in: Capsule())
                        }
                        .buttonStyle(MPPressStyle())
                        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
                        .id(item)
                    }
                }
                .padding(.horizontal, MPSpacing.screenH)
            }
            .onChange(of: shelf) { _, item in
                withAnimation(MP.M.gated(MP.M.base)) { proxy.scrollTo(item, anchor: .center) }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Seçim türü")
    }

    private func show(_ next: Shelf) {
        shelf = next
        zoomed = next.showsFace
    }

    // MARK: Raf

    private var rack: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text(shelf.heading).mpText(.section).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let note = hairNote {
                Text(note).mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.sm),
                                     count: typeSize.isAccessibilitySize ? 2 : 3),
                      spacing: MPSpacing.sm) {
                ForEach(tiles) { tile in tileView(tile) }
            }
        }
    }

    /// Başörtüsü takılıyken saç seçimi saklanır; saçsızken renk sonra görünür.
    private var hairNote: String? {
        guard case .slot(let slot) = shelf, slot == .hair || slot == .dye else { return nil }
        if draft.isHijab { return "Saç seçimin başörtünün altında korunur." }
        if slot == .dye && draft[.hair] == "bald" { return "Bu rengi bir saç modeli seçtiğinde göreceksin." }
        return nil
    }

    private struct Tile: Identifiable {
        let id: String
        let name: String
        let action: Action
        enum Action { case figure(HeroFigure.Choice), animal(HeroLook.Kind), child }
    }

    private var tiles: [Tile] {
        switch shelf {
        case .kind:
            return [Tile(id: "child", name: "Çocuk", action: .child)]
                + HeroLook.Kind.allCases.filter(\.isAnimal).map { Tile(id: $0.rawValue, name: $0.title, action: .animal($0)) }
        case .starters:
            return catalog.starters.indices.map { i in
                Tile(id: "starter-\(i)", name: Self.starterNames.indices.contains(i) ? Self.starterNames[i] : catalog.starters[i].name,
                     action: .figure(.starter(i)))
            }
        case .outfits:
            return catalog.outfits.map { Tile(id: $0.id, name: $0.name, action: .figure(.outfit($0.id))) }
        case .slot(let slot):
            return catalog.options(slot).map { Tile(id: $0.id, name: $0.name, action: .figure(.item(slot, $0.id))) }
        }
    }

    private func isSelected(_ tile: Tile) -> Bool {
        switch tile.action {
        case .child: true
        case .animal: false
        case .figure(let choice): draft.isSelected(choice, catalog: catalog)
        }
    }

    private func tileView(_ tile: Tile) -> some View {
        let selected = isSelected(tile)
        let shape = RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous)
        return Button { choose(tile) } label: {
            // Küçük resim krem kâğıtta, adı altta beyaz şeritte (referans).
            VStack(spacing: 0) {
                thumbnail(tile)
                    .padding(MPSpacing.sm)
                    .frame(height: MPSize.minTouchHero + MPSpacing.xl)
                    .frame(maxWidth: .infinity)
                    .background(MP.C.homePaper)
                Text(tile.name).mpText(.footnote).fontWeight(.bold).foregroundStyle(MPColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, MPSpacing.xs)
                    .padding(.vertical, MPSpacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(MPColor.backgroundSurface)
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(selected ? MPColor.actionPrimary : MPColor.borderKid, lineWidth: selected ? 2 : 1))
            .overlay(alignment: .topTrailing) {
                if selected {
                    MPIcon("checkmark.circle.fill", size: MP.G.md, weight: .bold)
                        .foregroundStyle(MPColor.actionPrimary)
                        .padding(MPSpacing.xs)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(tile.name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// Küçük resim: renk dairesi, "çıkar" simgesi, boyalı parçanın kendisi ya da
    /// kahramanın o seçimle küçük bir provası (`studio.js thumb`).
    @ViewBuilder
    private func thumbnail(_ tile: Tile) -> some View {
        switch tile.action {
        case .child:
            HeroFigureView(figure: draft, frame: .face)
        case .animal(let kind):
            HeroAvatarView(look: HeroLook(kind: kind), backdrop: MPWorldTone.lav.soft)
        case .figure(let choice):
            switch choice {
            case .starter:
                HeroFigureView(figure: starterPreview(choice), frame: .face)
            case .outfit:
                HeroFigureView(figure: draft.selecting(choice, catalog: catalog), frame: .body)
            case .item(let slot, let id):
                itemThumbnail(slot: slot, id: id, choice: choice)
            }
        }
    }

    @ViewBuilder
    private func itemThumbnail(slot: HeroFigure.Slot, id: String, choice: HeroFigure.Choice) -> some View {
        if let hex = catalog.option(id, in: slot)?.hex, let rgb = HeroRGB(string: hex) {
            Circle().fill(rgb.color)
                .frame(width: MPSize.iconTile, height: MPSize.iconTile)
                .overlay(Circle().strokeBorder(MPColor.borderKid, lineWidth: 1))
        } else if id == "none" {
            MPIcon("circle.slash", size: MP.G.xl, weight: .semibold)
                .foregroundStyle(MPColor.textSecondary)
        } else if Self.hasPicture(id) {
            Image("HeroFigure/\(id)").resizable().aspectRatio(contentMode: .fit)
        } else {
            HeroFigureView(figure: itemPreview(slot: slot, choice: choice), frame: Self.thumbFrame(slot))
        }
    }

    /// Başlangıç yüzünün provası: yüz açık görünsün diye başlıksız ve gözlüksüz.
    private func starterPreview(_ choice: HeroFigure.Choice) -> HeroFigure {
        var look = draft.selecting(choice, catalog: catalog)
        look[.head] = "none"
        look[.glasses] = "none"
        return look
    }

    /// Yüz ayrıntısının provası gözlüksüz: kaş, göz ve ifade görünsün.
    private func itemPreview(slot: HeroFigure.Slot, choice: HeroFigure.Choice) -> HeroFigure {
        var look = draft.selecting(choice, catalog: catalog)
        if [.face, .expression, .detail, .brow, .nose, .eyeShape].contains(slot) { look[.glasses] = "none" }
        return look
    }

    /// Boyalı PNG'si olan parça: üst, alt, tek parça, ayakkabı, saç ve şapkanın ilk altısı.
    private static func hasPicture(_ id: String) -> Bool {
        let parts = id.split(separator: "-")
        guard parts.count == 2, let n = Int(parts[1]) else { return false }
        return ["top", "bottom", "one", "shoe", "hair", "hat"].contains(String(parts[0])) && n <= 6
    }

    /// `studio.js thumbBox`: çanta, üst, alt ve gözlükte yakın kadraj.
    private static func thumbFrame(_ slot: HeroFigure.Slot) -> HeroFigureArt.Frame {
        switch slot {
        case .bag: .custom(CGRect(x: 92, y: 148, width: 75, height: 83))
        case .top: .custom(CGRect(x: 72, y: 142, width: 98, height: 96))
        case .bottom: .custom(CGRect(x: 76, y: 207, width: 88, height: 113))
        case .glasses: .custom(CGRect(x: 80, y: 78, width: 80, height: 43))
        case .skin, .eye, .eyeShape, .brow, .nose, .face, .hair, .dye, .detail, .expression, .head: .face
        case .one, .shoe: .body
        }
    }

    // MARK: Eylemler

    private func choose(_ tile: Tile) {
        switch tile.action {
        case .child:
            return
        case .animal(let kind):
            MPHaptics.selection()
            onChooseAnimal(kind)
        case .figure(let choice):
            let next = draft.selecting(choice, catalog: catalog)
            guard next != draft else { return }
            MPHaptics.selection()
            history.append(draft)
            if history.count > 60 { history.removeFirst() }
            draft = next
            wear()
            var message = "\(tile.name) seçildi."
            if hairNote != nil, draft.isHijab { message += " Saç seçimin başörtünün altında korunur." }
            AccessibilityNotification.Announcement(message).post()
        }
    }

    /// Prova hareketi: ayağı yere basan küçük bir yana eğilme, tek seferlik.
    /// Hareketi Azalt açıkken parça doğrudan değişir.
    private func wear() {
        guard !reduceMotion else { return }
        withAnimation(MP.M.press) { tilt = -3 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(160))
            withAnimation(MP.M.spring) { tilt = 0 }
        }
    }

    private func undo() {
        guard let previous = history.popLast() else { return }
        MPHaptics.tap()
        draft = previous
        AccessibilityNotification.Announcement("Son seçim geri alındı.").post()
    }

    private func load() {
        let look = HeroLookStore().look(for: profile.id)
        let figure = look?.figure ?? .starter
        hasSavedFigure = look?.figure != nil && look?.kind == .child
        draft = figure
        saved = figure
        history = []
        family = .clothes
        shelf = .outfits
        zoomed = false
    }

    private func save() {
        guard dirty else { return }
        let base = HeroLookStore().look(for: profile.id) ?? .standard
        HeroLookStore().save(base.wearing(draft), for: profile.id)
        saved = draft
        hasSavedFigure = true
        history = []
        MPHaptics.success()
        app.showToast("Kahramanın kaydedildi", symbol: "sparkles")
    }

    private func leave() {
        if dirty && !history.isEmpty { asksToLeave = true } else { close() }
    }

    /// Çocuk alanında yığından, ebeveyn odasında odanın sayfasından çıkar (`closeKidPage`).
    private func close() { app.router.closeKidPage() }
}

// MARK: - Dolap: insan ya da hayvan

/// Kahramanın dolabı (Profil → kahraman kartı). Çocuk kahraman yeni tam boy
/// dolapta, hayvan kahraman eski büst dolabında giyinir. "Tür" rafında hayvan
/// seçilince eski dolaba, orada "Çocuk" seçilince yeni dolaba geçilir; iki
/// kahramanın son kaydı da saklı kalır.
struct HeroDressingRoom: View {
    let profile: UserProfile

    private enum Mode: Equatable {
        case human
        case animal(HeroLook.Kind?)
    }

    @State private var mode: Mode?

    var body: some View {
        Group {
            switch mode {
            case .human:
                HeroStudioView(profile: profile) { kind in mode = .animal(kind) }
            case .animal(let kind):
                HeroWardrobeView(profile: profile, initialKind: kind) { mode = .human }
            case nil:
                MPColor.backgroundSurface.ignoresSafeArea()
            }
        }
        .task(id: profile.id) {
            let look = HeroLookStore().look(for: profile.id)
            mode = (look?.kind.isAnimal ?? false) ? .animal(nil) : .human
        }
    }
}

import SwiftUI

// Ana sayfa yeni düzen (23 Kasım 2026, İrem; prototip `design-preview/app/home.js`,
// referans: alışkanlık uygulaması ekranı). Üstte mor gökten beyaza inen başlık:
// menü, bildirim ve arama (MPCircleButton), "Merhaba, <ad>", el sallayan Ragi ve
// üç bilgi kartı. Ortada koyu mor "bu akşamın masalı" kartı, altında modların
// liste satırları. Gece/gündüz ayrımı yok.

// MARK: - Bilgi kartı

/// Başlıktaki üç karttan biri: ortalı simge karosu, ad, sayı ve birim.
struct HomeStatCard: View {
    let systemImage: String
    let tone: MPWorldTone
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: MPSpacing.xxs) {
            MPIconTile(systemImage: systemImage, tone: tone, size: MPSize.iconTile - MPSpacing.sm)
                .padding(.bottom, MPSpacing.xxs)
            Text(label).mpText(.footnote).fontWeight(.bold).foregroundStyle(MPColor.textSecondary)
            Text(value).mpText(.section).foregroundStyle(MPColor.textPrimary).monospacedDigit()
            Text(unit).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.md)
        .padding(.horizontal, MPSpacing.xs)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value) \(unit)")
    }
}

// MARK: - Bu akşamın masalı

/// Koyu mor kart: solda Ragi (ayakları kartın alt çizgisinde), sağda masal,
/// yarım masalda beş parçalı ilerleme, bilgi hapı ve ikincil düğme. Dört durum
/// `TonightState` (widget ve Siri ile aynı kural).
struct HomeTonightBoard: View {
    let state: TonightState
    /// Masalın boyalı kapağı (26 Kasım 2026, Batuhan: "ana sayfa gibi duran"
    /// kahraman öğe). Boyalı kapakta kartın üstü resim olur; başlık kapağında ya
    /// da kapaksız durumda (uyku, bugün okudun) kart eskisi gibi.
    var cover: MPBookCover.Art? = nil
    let onPrimary: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Ragi'nin genişliği; metin onun yanından başlar.
    private static let ragiWidth: CGFloat = 112

    var body: some View {
        VStack(spacing: 0) {
            if let art = paintedCover { artBand(art) }
            details
        }
        .mpEdge(fill: MP.C.homeTonight, edge: MP.C.homeTonightEdge, radius: MPRadius.card, width: MP.E.widthLG)
        // Ragi yerleşimi büyütmez: ayakları kartın alt çizgisinde, başı yazı
        // bölümünün üstüne (resim varsa resmin altına) taşar. En büyük yazıda
        // metne yer kalsın diye çizilmez.
        .overlay(alignment: .bottomLeading) {
            if !typeSize.isAccessibilitySize {
                MascotImage(mascot: mascot, width: Self.ragiWidth)
                    .offset(x: -MPSpacing.xs)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text(copy.eyebrow).mpText(.footnote).fontWeight(.bold).foregroundStyle(MP.C.textOnArtMuted)
            Text(copy.title).font(MP.F.displaySM()).foregroundStyle(MP.C.textOnArt)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if case .resume(let progress, _, _) = state { progressBar(progress) }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: MPSpacing.xs) { tag; button }
                VStack(alignment: .leading, spacing: MPSpacing.xs) { tag; button }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, MPSpacing.lg)
        .padding(.trailing, MPSpacing.lg)
        .padding(.leading, typeSize.isAccessibilitySize ? MPSpacing.lg : Self.ragiWidth)
    }

    /// Yalnızca masal sunan durumlarda ve boyalı kapakta.
    private var paintedCover: (name: String, focus: ClassicFocus)? {
        switch state {
        case .resume, .unread:
            if case let .image(name, focus)? = cover { return (name, focus) }
            return nil
        case .readToday, .bedtime:
            return nil
        }
    }

    /// Kartın üstündeki resim: kapak sanatı, kartın köşesiyle kırpılır.
    private func artBand(_ art: (name: String, focus: ClassicFocus)) -> some View {
        ClassicCoverImage(asset: art.name, focus: art.focus, seed: art.name)
            .frame(maxWidth: .infinity)
            .frame(height: Self.artHeight)
            .clipped()
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: MPRadius.card, bottomLeadingRadius: 0,
                                              bottomTrailingRadius: 0, topTrailingRadius: MPRadius.card,
                                              style: .continuous))
            .accessibilityHidden(true)
    }

    private static let artHeight: CGFloat = 168

    private var tag: some View {
        // Yalnızca yazı (24 Kasım 2026): dolgulu kutu düğmeye benziyordu.
        Text(copy.tag).mpText(.footnote).fontWeight(.bold).foregroundStyle(MP.C.textOnArtMuted)
            .frame(minHeight: MPSize.buttonHeightSmall)
    }

    private var button: some View {
        MPButton(title: copy.button, systemImage: copy.icon, kind: .secondary, size: .small, action: onPrimary)
    }

    /// Beş parça: okunanlar açık mor, şu anki parça yıldız sarısı, kalanlar iz.
    private func progressBar(_ progress: Double) -> some View {
        let total = 5
        let done = min(max(Int((progress * Double(total)).rounded(.up)), 1), total)
        return HStack(spacing: MPSpacing.xxs) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == done - 1 ? MP.C.homeProgressNow
                          : i < done ? MP.C.homeProgressDone : MP.C.textOnArt.opacity(0.22))
                    .frame(height: MPSpacing.sm)
            }
            Text("\(done)/\(total)").mpText(.footnote).fontWeight(.bold).foregroundStyle(MP.C.textOnArt)
                .monospacedDigit()
                .padding(.leading, MPSpacing.xxs)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(total) parçanın \(done). parçası")
    }

    private var mascot: Mascot {
        switch state {
        case .resume, .unread: .reading
        case .readToday: .happy
        case .bedtime: .sleepy
        }
    }

    private var copy: HomeTonightCopy { .make(state) }
}

/// Bu akşamın kartının metinleri (24 Kasım 2026): görünüm yalnızca çizer.
/// "Bugün okudun" sakin: masal bitirmek bir olay, kart yeni masal önermez,
/// kitaplığa çağırır (Batuhan). Yazmak isteyen mod satırlarını kullanır.
struct HomeTonightCopy: Equatable {
    let eyebrow: String
    let title: String
    let tag: String
    let button: String
    let icon: String

    static func make(_ state: TonightState) -> HomeTonightCopy {
        switch state {
        case .resume(_, let title, let meta):
            .init(eyebrow: "Kaldığın yerden", title: title, tag: meta, button: "Devam et", icon: "play.fill")
        case .unread(let title, let meta):
            .init(eyebrow: "Bu akşamın masalı", title: title, tag: meta, button: "Masalı oku", icon: "book")
        case .readToday:
            .init(eyebrow: "Bugün okudun", title: "Yarın yeni bir masal var", tag: "Kitaplığın hazır",
                  button: "Kitaplığına bak", icon: "books.vertical")
        case .bedtime(let time):
            // Lucide ay (`MPIconMap`); "moon.fill" eşlemesizdi, düğmede boş yer kalıyordu.
            .init(eyebrow: "Saat \(time)", title: "Uyku masalı zamanı", tag: "Kısa ve sakin",
                  button: "Uyku masalı yaz", icon: "moon")
        }
    }
}

// MARK: - Mod satırı

/// "Yeni bir masal yaz" satırı: renkli simge karosu, mod adı, kısa sözü ve ok.
struct HomeModeRow: View {
    let mode: StoryMode
    var emphasized: Bool = false
    let action: () -> Void

    var body: some View {
        HomeListRow(systemImage: mode.symbol, tone: mode.tone, title: mode.title,
                    subtitle: emphasized ? "Bu akşam için önerilen" : mode.promise,
                    emphasized: emphasized,
                    accessibilityLabel: emphasized ? "\(mode.title), bu akşam için önerilen" : mode.title,
                    hint: "Masalda kimlerin olacağını seçmeye geçer", action: action)
    }
}

/// Ana sayfa ve menünün ortak satırı (23 Kasım 2026): renkli simge karosu, ad,
/// kısa açıklama ve çember içinde ok; zemin `surfaceSunken`.
struct HomeListRow: View {
    let systemImage: String
    let tone: MPWorldTone
    let title: String
    let subtitle: String
    var emphasized: Bool = false
    var accessibilityLabel: String? = nil
    var hint: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.md) {
                MPIconTile(systemImage: systemImage, tone: tone, size: MPSize.iconTile - MPSpacing.xxs)
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text(title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    Text(subtitle)
                        .mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: MPSpacing.xs)
                MPIcon("chevron.right", size: MP.G.sm, weight: .semibold)
                    .foregroundStyle(MPColor.textSecondary)
                    .frame(width: MPSize.circleButton - MPSpacing.sm, height: MPSize.circleButton - MPSpacing.sm)
                    .overlay(Circle().strokeBorder(MPColor.borderKid, lineWidth: 2))
                    .accessibilityHidden(true)
            }
            .padding(MPSpacing.md)
            .frame(minHeight: MPSize.choiceRowKid)
            .background(MP.C.surfaceSunken, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
            .overlay {
                if emphasized {
                    RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
                        .strokeBorder(MPColor.actionPrimary, lineWidth: 2)
                }
            }
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel ?? title)
        .accessibilityHint(hint ?? "")
    }
}

// MARK: - Bu akşamın kartı (27 Kasım 2026)

/// Ana sayfanın kahraman kartı (27 Kasım 2026, Batuhan: "tam profesyonel bir
/// uygulama ana sayfası"). Ragi başlığın manzarasında olduğu için kart Ragi'siz:
/// solda masalın kapağı, sağda üst yazı, ad ve bilgi; altta ekranın tek birincil
/// düğmesi (`MPButton(size: .hero)`). Metinler `HomeTonightCopy`'den: masal
/// okunduysa kart yeni masal önermez, kitaplığa çağırır (24 Kasım kararı).
struct HomeTonightCard: View {
    let state: TonightState
    var cover: MPBookCover.Art? = nil
    let onPrimary: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private static let coverWidth: CGFloat = 96

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            HStack(alignment: .top, spacing: MPSpacing.lg) {
                if let cover, !typeSize.isAccessibilitySize {
                    MPBookCover(art: cover, badge: badge, width: Self.coverWidth)
                } else if !typeSize.isAccessibilitySize {
                    MPIconTile(systemImage: copy.icon, tone: .lav, size: MPSize.iconTile)
                }
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text(copy.eyebrow).mpText(.footnote).fontWeight(.bold).foregroundStyle(MPColor.actionPrimary)
                    Text(copy.title).mpText(.section).foregroundStyle(MPColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(copy.tag).mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            MPButton(title: copy.button, systemImage: copy.icon, size: .hero, fullWidth: true, action: onPrimary)
        }
        .padding(MPSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
    }

    private var badge: MPBookCover.Badge? {
        if case .resume(let progress, _, _) = state, progress > 0 { return .progress(progress) }
        return nil
    }

    private var copy: HomeTonightCopy { .make(state) }
}

// MARK: - Mod karosu (27 Kasım 2026)

/// "Yeni bir masal yaz"ın resimli karosu: modun illüstrasyonu (`Scenes/mode-*`,
/// yatak, filiz, çadır), altında adı. Üçü yan yana; en büyük yazıda liste
/// satırına (`HomeModeRow`) döner. Okumayan çocuk modu resminden tanır.
struct HomeModeArtTile: View {
    let mode: StoryMode
    var emphasized: Bool = false
    var isNight: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MPSpacing.sm) {
                Image(asset).resizable().aspectRatio(contentMode: .fit)
                    .frame(height: Self.artHeight)
                    .accessibilityHidden(true)
                Text(mode.shortTitle).mpText(.supporting).fontWeight(.bold).foregroundStyle(MPColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, MPSpacing.md)
            .padding(.horizontal, MPSpacing.xs)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .mpKidSurface(mode.tone.soft, edge: mode.tone.edge)
            .overlay {
                if emphasized {
                    RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
                        .strokeBorder(MPColor.actionPrimary, lineWidth: 2)
                }
            }
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(emphasized ? "\(mode.title), bu akşam için önerilen" : mode.title)
        .accessibilityHint("Masalda kimlerin olacağını seçmeye geçer")
    }

    private static let artHeight: CGFloat = 64

    private var asset: String {
        switch mode {
        case .bedtime: return isNight ? "Scenes/mode-bedtime-night" : "Scenes/mode-bedtime"
        case .learning: return "Scenes/mode-learning"
        case .adventure: return "Scenes/mode-adventure"
        }
    }
}

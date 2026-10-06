import SwiftUI

// MARK: - MPCard

/// Kart tonları. MPCard generic olduğu için tipin dışında tanımlı.
enum MPCardTone { case paper, sunken, brand, night, reward }

struct MPCard<Content: View>: View {
    typealias Tone = MPCardTone

    var tone: MPCardTone = .paper
    var padding: CGFloat = 20
    var radius: CGFloat = MP.R.card
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mpEdge(fill: skin.bg, edge: skin.edge, radius: radius, width: skin.edgeWidth)
            .modifier(MPCardShadow(tone: tone))
    }

    private var skin: (bg: Color, edge: Color, edgeWidth: CGFloat) {
        switch tone {
        case .paper:  return (MP.C.surfaceCard, MP.C.edgeCard, MP.E.widthLG)
        case .sunken: return (MP.C.surfaceSunken, MP.C.borderStrong, MP.E.width)
        case .brand:  return (MP.C.brand, MP.C.brandEdge, MP.E.widthLG)
        case .night:  return (MP.C.surfaceInverse, MP.C.edgeInverse, MP.E.widthLG)
        case .reward: return (MP.C.rewardSoft, MP.Palette.hardal200, MP.E.widthLG)
        }
    }

    /// Kart üstündeki metin rengi tonla birlikte değişir.
    static func foreground(for tone: MPCardTone) -> Color {
        switch tone {
        case .brand: return MP.C.textOnBrand
        case .night: return MP.Palette.gece25
        default: return MP.C.textBody
        }
    }

}

/// Kart tonuna göre ikincil gölge.
/// MPCard generic olduğu için bu modifier üst seviyede durur — aksi hâlde
/// `Content` adı ViewModifier'ın associatedtype'ını gölgeliyor.
private struct MPCardShadow: ViewModifier {
    let tone: MPCardTone
    @ViewBuilder func body(content: Content) -> some View {
        switch tone {
        case .paper: content.mpShadow(MP.Sh.card)
        case .brand: content.mpShadow(MP.Sh.brand)
        case .night: content.mpShadow(MP.Sh.lifted)
        default:     content
        }
    }
}

/// Basılabilir kart — `pressable` prop'unun karşılığı.
struct MPPressableCard<Content: View>: View {
    var tone: MPCardTone = .paper
    var padding: CGFloat = 20
    let action: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        Button(action: action) {
            MPCard(tone: tone, padding: padding, content: content)
        }
        .buttonStyle(MPPressStyle(scales: false))
    }
}

// MARK: - MPSectionHeader

struct MPSectionHeader: View {

    /// Bölümün ekrandaki ağırlığı.
    ///
    /// Her başlık aynı puntodayken ekran hiyerarşisiz olur: çocuğun kendi
    /// masalları ile en alttaki ikincil bir yol aynı sesle bağırır. Göz o zaman
    /// sırayı konumdan çıkarmak zorunda kalır, ki en yavaş okuma biçimidir.
    enum Emphasis { case primary, secondary }

    let title: String
    var subtitle: String? = nil
    var emphasis: Emphasis = .primary
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(emphasis == .primary ? MP.F.displaySM() : MP.F.bodyLG(.bold))
                    .mpTightTracking(emphasis == .primary ? 21 : 18)
                    .foregroundStyle(emphasis == .primary ? MP.C.textTitle : MP.C.textBody)
                if let subtitle {
                    Text(subtitle).font(MP.F.bodySM()).foregroundStyle(MP.C.textMuted)
                }
            }
            Spacer(minLength: 0)
            if let actionLabel, let action {
                Button(action: action) {
                    HStack(spacing: 3) {
                        Text(actionLabel)
                        MPIcon("chevron.right", size: 16, weight: .bold)
                    }
                    .font(MP.F.labelMD())
                    .foregroundStyle(MP.C.textLink)
                    // Dokunma alanı görünür boyuttan büyük, düzen değişmez.
                    .padding(.vertical, MP.S.x3)
                    .contentShape(Rectangle())
                    .padding(.vertical, -MP.S.x3)
                }
                .buttonStyle(MPPressStyle(.highlight))
            }
        }
    }
}

// MARK: - MPAvatar

/// Harf madalyonu. MagicPaper bilinçli olarak çocuk fotoğrafı saklamaz.
struct MPAvatar: View {
    let name: String
    var color: Color? = nil
    var size: CGFloat = 48
    var ring: Bool = false

    /// Ad'dan renk türetmek için yedek küme.
    ///
    /// Burada ayrı bir liste vardı: 8 renkti, `UserProfile.mpColor`'ınki 6.
    /// İkisi de `sum % count` ile seçtiği için aynı çocuk, hangi bileşenin
    /// çizdiğine göre farklı renk alabiliyordu ve 7./8. renk hiçbir zaman
    /// kaydedilemiyordu (saklanan indeks 1–6). Tek kümeye indirildi.
    private static let palette: [Color] = MP.C.avatarAccents

    private var bg: Color {
        if let color { return color }
        let sum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Self.palette[sum % Self.palette.count]
    }

    /// Türkçe i/İ kuralı zorunlu.
    private var letter: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased(with: Locale(identifier: "tr_TR"))
    }

    var body: some View {
        Text(letter)
            .font(.custom(MP.F.display, size: round(size * 0.44)).weight(.heavy))
            .foregroundStyle(MP.Palette.kagit0)
            .frame(width: size, height: size)
            .background(Circle().fill(bg))
            .background {
                // Sistemin imzası: 3px koyu alt kenar (CSS: inset 0 -3px 0 rgba(43,29,36,.18))
                if !ring {
                    Circle().fill(MP.C.edgeCircle).offset(y: 3)
                }
            }
            .overlay {
                // Aktif profil: 0 0 0 3px kağıt, 0 0 0 6px zemin rengi
                if ring {
                    ZStack {
                        Circle().strokeBorder(bg, lineWidth: 3).padding(-6)
                        Circle().strokeBorder(MP.C.surfaceCard, lineWidth: 3).padding(-3)
                    }
                }
            }
            .accessibilityLabel(name)
    }
}

// MARK: - MPStarPill

/// Kalan görselli masal hakkı. Birim adı her zaman "Yıldız" — asla "kredi".
struct MPStarPill: View {
    let count: Int
    var label: String = "Yıldız"
    var action: (() -> Void)? = nil

    private var content: some View {
        HStack(spacing: 6) {
            MPIcon("star.fill", size: 16, weight: .bold)
            Text("\(count)")
        }
        .font(.custom(MP.F.display, size: 15).weight(.heavy))
        .foregroundStyle(MP.Palette.murekkep900)
        .padding(.horizontal, 14)
        .frame(height: 40)
        .mpEdge(fill: MP.C.reward, edge: MP.C.rewardEdge, radius: MP.R.pill)
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) { content }.buttonStyle(MPPressStyle(scales: false))
            } else {
                content
            }
        }
        .accessibilityLabel("\(count) \(label)")
    }
}

// MARK: - MPChoiceTile

/// Sihirbazın cevap kontrolü — tek dokunuş, tek cevap. Sistemde dropdown yoktur.
struct MPChoiceTile: View {
    enum Layout { case row, column }

    let title: String
    var description: String? = nil
    var symbol: String? = nil
    var accent: Color = MP.C.brand
    var isSelected: Bool = false
    var isLocked: Bool = false
    var layout: Layout = .row
    let action: () -> Void

    private var isColumn: Bool { layout == .column }
    private var bg: Color { isSelected ? accent.mpMixedWithWhite(0.09) : MP.C.surfaceCard }
    private var borderColor: Color { isSelected ? accent : MP.C.borderHairline }
    private var edgeColor: Color { isSelected ? accent : MP.C.borderStrong }

    var body: some View {
        Button(action: action) {
            Group {
                if isColumn { columnBody } else { rowBody }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .mpEdge(fill: bg, edge: edgeColor, radius: MP.R.tile, width: MP.E.widthLG)
            .overlay(
                RoundedRectangle(cornerRadius: MP.R.tile, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 2)
                    .padding(.bottom, MP.E.widthLG)
            )
            .opacity(isLocked ? 0.68 : 1)
            .animation(MP.M.gated(MP.M.easeOut), value: isSelected)
        }
        .buttonStyle(MPPressStyle(scales: false))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var rowBody: some View {
        HStack(spacing: 14) {
            if let symbol { iconBox(box: 46, glyph: 24) }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(MP.F.displaySM()).foregroundStyle(MP.C.textTitle)
                if let description {
                    Text(description).font(MP.F.bodySM()).foregroundStyle(MP.C.textMuted)
                }
            }
            Spacer(minLength: 0)
            marker
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var columnBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let symbol { iconBox(box: 52, glyph: 26) }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(MP.F.displaySM()).foregroundStyle(MP.C.textTitle)
                if let description {
                    Text(description).font(MP.F.bodySM()).foregroundStyle(MP.C.textMuted)
                }
            }
        }
        .padding(18)
        // Izgara kartları eşit yükseklikte dursun: başlığı tek satıra sığan
        // dünyalar (Uzay) iki satıra taşanlardan (Orman Macerası) kısa kalıyor,
        // satırlar tırtıklı görünüyordu.
        .frame(minHeight: 156, alignment: .topLeading)
        .overlay(alignment: .topTrailing) {
            if isLocked {
                MPIcon("lock.fill", size: 18).foregroundStyle(MP.C.textFaint).padding(12)
            } else if isSelected {
                MPIcon("checkmark", size: 15, weight: .heavy)
                    .foregroundStyle(MP.Palette.kagit0)
                    .frame(width: 24, height: 24).background(Circle().fill(accent)).padding(12)
            }
        }
    }

    @ViewBuilder private func iconBox(box: CGFloat, glyph: CGFloat) -> some View {
        MPIcon(symbol ?? "questionmark", size: glyph, weight: .semibold)
            .foregroundStyle(accent)
            .frame(width: box, height: box)
            .background(RoundedRectangle(cornerRadius: MP.R.md, style: .continuous)
                .fill(accent.mpMixedWithWhite(0.14)))
    }

    @ViewBuilder private var marker: some View {
        if isLocked {
            MPIcon("lock.fill", size: 20).foregroundStyle(MP.C.textFaint)
        } else if isSelected {
            MPIcon("checkmark", size: 16, weight: .heavy)
                .foregroundStyle(MP.Palette.kagit0)
                .frame(width: 26, height: 26).background(Circle().fill(accent))
        } else {
            Circle().strokeBorder(MP.C.borderStrong, lineWidth: 2).frame(width: 26, height: 26)
        }
    }
}

extension Color {
    /// CSS `color-mix(in oklab, <renk> <yüzde>%, white)` karşılığı.
    /// **Opak** sonuç üretir: yarı saydam bir zemin `mpEdge`'in düz kenar
    /// rengini altından geçiriyor ve seçili kart komple dolu renk görünüyordu.
    func mpMixedWithWhite(_ fraction: Double) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        let f = CGFloat(max(0, min(1, fraction)))
        return Color(.sRGB,
                     red: Double(r * f + (1 - f)),
                     green: Double(g * f + (1 - f)),
                     blue: Double(b * f + (1 - f)),
                     opacity: 1)
    }
}

// MARK: - MPListRow

struct MPListRow<Trailing: View>: View {
    var symbol: String? = nil
    var iconColor: Color = MP.C.brand
    let title: String
    var description: String? = nil
    var isDanger: Bool = false
    var action: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> Trailing

    private var tint: Color { isDanger ? MP.C.danger : iconColor }

    private var content: some View {
        HStack(spacing: 14) {
            if let symbol {
                MPIcon(symbol, size: 20, weight: .semibold)
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: MP.R.sm, style: .continuous).fill(tint.opacity(0.13)))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(MP.F.bodyMD(.bold)).foregroundStyle(isDanger ? MP.C.danger : MP.C.textTitle)
                if let description {
                    Text(description).font(MP.F.labelSM(.regular)).foregroundStyle(MP.C.textMuted)
                }
            }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(minHeight: MP.S.tapMin)
        .background(RoundedRectangle(cornerRadius: MP.R.md, style: .continuous).fill(MP.C.surfaceCard))
    }

    var body: some View {
        if let action {
            Button(action: action) { content.contentShape(Rectangle()) }
                .buttonStyle(MPPressStyle(.highlight))
        } else {
            content
        }
    }
}

extension MPListRow where Trailing == EmptyView {
    init(symbol: String? = nil, iconColor: Color = MP.C.brand, title: String,
         description: String? = nil, isDanger: Bool = false, action: (() -> Void)? = nil) {
        self.init(symbol: symbol, iconColor: iconColor, title: title, description: description,
                  isDanger: isDanger, action: action) { EmptyView() }
    }
}

/// ListRow gruplarının arasındaki 1px ayırıcı.
struct MPRowDivider: View {
    var body: some View {
        Rectangle().fill(MP.C.borderHairline).frame(height: 1).padding(.horizontal, 16)
    }
}

// MARK: - MPStoryCard

struct MPStoryCard: View {
    enum Layout { case shelf, row }

    let title: String
    var meta: String? = nil
    var symbol: String = "book"
    var accent: Color = MP.C.brand
    /// Kapakta gösterilecek masal adı.
    ///
    /// Kartlar önce ortak bir illüstrasyon gösteriyordu. Bir masalı ayırt eden
    /// şey hepsinde aynı olan resim değil, kendi adıdır — raf, aynı resimden
    /// beş tane değil, beş farklı kitap gibi okunmalı. Kapak artık masalın
    /// adını taşıyor; dünya işareti kimlik olarak üstünde kalıyor.
    var coverTitle: String? = nil
    /// Generative mosaic cover configuration for text-only stories.
    ///
    /// When set, the card renders a `MagicPaperCoverView` mosaic instead of
    /// the typographic `StoryCoverFace`. Illustrated stories leave this `nil`.
    var mosaicCover: MagicPaperCoverConfiguration? = nil
    /// Sanat setinin teslim edilmiş kapak görseli. Varsa mozaiğin önüne geçer.
    var coverAsset: String? = nil
    /// Masalın okuma durumu.
    ///
    /// Kütüphane bunu söylemiyordu: beş kart yan yana duruyor ve hangisinin
    /// okunduğu, hangisinin hiç açılmadığı görünmüyordu. Bir masal kitaplığının
    /// cevaplaması gereken ilk soru budur — "bunu okuduk mu?" — ve tarih onun
    /// yerine geçmiyor, çünkü dün yaratılmış bir masal dün okunmuş demek değil.
    var status: Status? = nil

    enum Status {
        /// Hiç açılmamış.
        case unread
        /// Sonuna kadar okunmuş.
        case finished
    }
    var badge: String? = nil
    /// The badge's look. Defaults to the illustrated-book crown; a series
    /// episode (FAZ 13) passes a neutral one, so "2. bölüm" does not read as
    /// something premium.
    var badgeTone: MPBadge.Tone = .reward
    var badgeSymbol: String = "crown.fill"
    var progress: Double? = nil
    var layout: Layout = .shelf
    let action: () -> Void

    private var isShelf: Bool { layout == .shelf }

    /// Raf kartının genişliği.
    ///
    /// 152pt'den büyütüldü. Masal başlıkları uzun — "Mercan Denizi'ne Cesur
    /// Yolculuk", "Yeliz ve Eski Meyve Bahçesi" — ve 152pt'de hangi puntoyla
    /// yazılırsa yazılsın kesiliyorlardı: rafta üç kart yan yana duruyor,
    /// üçünün de adı yarım. Başlığı okunmayan bir kart seçilebilir bir kart
    /// değildir, ve raf tam olarak seçim yapmak için var.
    ///
    /// Daha az kart görünüyor. Bu bir kayıp değil: ikinci kartın yarısını
    /// göstermek zaten "sağa kaydır" demenin yoluydu, ve kaydırma ipucu için
    /// okunurluk feda edilmez.
    static let shelfWidth: CGFloat = 184

    /// Raf kapağı kare değil, kitap gibi 3:4.
    ///
    /// Kare kapak rafı bir uygulama ızgarasına benzetiyordu; dikey kapak bir
    /// kitaplığa. Sanat seti kapakları da 3:4 üretiliyor (`art_kits.json`).
    static let shelfCoverHeight: CGFloat = shelfWidth * 4 / 3

    var body: some View {
        Button(action: action) {
            Group {
                if isShelf {
                    VStack(alignment: .leading, spacing: 0) {
                        cover(width: Self.shelfWidth, height: Self.shelfCoverHeight,
                              glyph: 46, rounded: false)
                        textBlock.padding(EdgeInsets(top: 12, leading: 14, bottom: 14, trailing: 14))
                    }
                    .frame(width: Self.shelfWidth)
                } else {
                    HStack(spacing: 14) {
                        cover(width: 72, height: 72, glyph: 30, rounded: true)
                        textBlock
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                }
            }
            .background(RoundedRectangle(cornerRadius: MP.R.card, style: .continuous).fill(MP.C.surfaceCard))
            .clipShape(RoundedRectangle(cornerRadius: MP.R.card, style: .continuous))
            .mpEdge(fill: .clear, edge: MP.C.edgeCard, radius: MP.R.card, width: MP.E.widthLG)
            .mpShadow(MP.Sh.card)
        }
        .buttonStyle(MPPressStyle(scales: false))
    }

    /// Kapak alanı: mozaik kapak, tipografik kapak yüzü, veya dünya ikonu.
    private func cover(width: CGFloat, height: CGFloat, glyph: CGFloat, rounded: Bool) -> some View {
        let side = min(width, height)
        return Group {
            if let coverAsset {
                Image(coverAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .accessibilityHidden(true)
            } else if let mosaicCover {
                // Generative paper-mosaic cover for text-only stories.
                MagicPaperCoverView.thumbnail(for: mosaicCover)
                    .frame(width: width, height: height)
            } else if let coverTitle {
                // Kitabın tipografik yüzü: kâğıt, yay biçiminde ad, marka
                // satırı — okuyucunun kapak yaprağıyla aynı dil.
                StoryCoverFace(title: coverTitle)
                    .frame(width: width, height: height)
                    // Dünya işareti kimlik olarak kalıyor: ad okunmadan da
                    // hangi dünyaya ait olduğu bir bakışta anlaşılsın.
                    .overlay(alignment: .bottomTrailing) {
                        MPIcon(symbol, size: glyph * 0.44, weight: .bold)
                            .foregroundStyle(MP.Palette.kagit0)
                            .frame(width: glyph * 0.86, height: glyph * 0.86)
                            .background(Circle().fill(accent))
                            .overlay(Circle().stroke(MP.Palette.kagit0.opacity(0.9), lineWidth: 2))
                            .padding(side >= 80 ? MP.S.x2 : 3)
                    }
            } else {
                MPIcon(symbol, size: glyph, weight: .semibold)
                    .foregroundStyle(accent)
                    .frame(width: width, height: height)
                    .background(accent.opacity(0.16))
            }
        }
            .clipShape(RoundedRectangle(cornerRadius: rounded ? MP.R.md : 0, style: .continuous))
            .overlay(alignment: .topLeading) {
                // Rozet yalnızca raf kapağına sığar. `row` düzeninde
                // kapak küçük olduğu için rozet metin bloğuna taşındı.
                if isShelf, let badge {
                    MPBadge(title: badge, tone: badgeTone, symbol: badgeSymbol).padding(10)
                }
            }
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Raf kartında kapak zaten masalın adını taşıyor; altında bir kez
            // daha yazmak aynı şeyi iki kez söylemek olur. Satır düzeninde
            // kapak küçük ve ad orada okunmuyor, dolayısıyla orada kalıyor.
            if !(isShelf && coverTitle != nil) {
                Text(title)
                // Rafta bir punto küçük: 21pt'de iki satıra iki kelime
                // sığıyordu. Başlığın tamamının görünmesi, başlığın büyük
                // görünmesinden önemli.
                // Hem rafta hem satırda bir punto küçük. 21pt'de iki satırlık
                // bir başlık, tek satırlıkların neredeyse iki katı yükseklikte
                // bir kart üretiyordu ve liste dalgalanıyordu.
                .font(MP.F.bodyLG(.bold))
                .foregroundStyle(MP.C.textTitle)
                // Rafta iki satır YER TUTAR, tek satırlık başlıklarda da.
                // Aksi hâlde "Yeliz ve Kıpır" kartı "Yeliz ve Eski Meyve
                // Bahçesi" kartından alçak kalıyor ve yan yana dizilen kartların
                // altı tırtıklı görünüyordu — kartların kendisi kusursuzken.
                // Dikey listede sorun değil, çünkü orada zaten alt alta.
                .lineLimit(2, reservesSpace: isShelf)
                .multilineTextAlignment(.leading)
            }
            HStack(spacing: MP.S.x2) {
                if let meta {
                    Text(meta).font(MP.F.labelSM(.semibold))
                        .foregroundStyle(MP.C.textMuted).lineLimit(1)
                }
                switch status {
                case .unread:
                    // Okunmamış olan öne çıkar; okunmuş olan geri çekilir.
                    // Tersi, listenin çoğunu vurgulamak olurdu ve vurgu her
                    // yerde olduğunda hiçbir yerdedir.
                    Text("Yeni")
                        .font(MP.F.caption())
                        .foregroundStyle(MP.C.textOnBrand)
                        .padding(.horizontal, MP.S.x2)
                        .padding(.vertical, 2)
                        .background(Capsule(style: .continuous).fill(MP.C.brand))
                case .finished:
                    MPIcon("checkmark.circle.fill", size: 14, weight: .semibold)
                        .foregroundStyle(MP.C.success)
                        .accessibilityLabel("Okundu")
                case nil:
                    EmptyView()
                }
            }
            if !isShelf, let badge {
                MPBadge(title: badge, tone: badgeTone, symbol: badgeSymbol)
                    .padding(.top, 2)
            }
            // İlerleme çubuğu yalnızca yarım kalmış masalda. Bitmiş masalda
            // %100 dolu çubuk kartı kaplayan bir blok gibi görünüyordu.
            if let progress, progress > 0, progress < 1 {
                Capsule().fill(MP.C.surfaceSunken)
                    .frame(height: 6)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            Capsule().fill(accent).frame(width: geo.size.width * progress)
                        }
                    }
                    .padding(.top, 6)
            }
        }
    }
}

// MARK: - MPStatCard

struct MPStatCard: View {
    let symbol: String
    let label: String
    let value: String
    var unit: String? = nil
    var accent: Color = MP.C.brand

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MPIcon(symbol, size: 19, weight: .semibold)
                .foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: MP.R.sm, style: .continuous).fill(accent.opacity(0.14)))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(MP.F.displayHeavy(26)).foregroundStyle(MP.C.textTitle)
                if let unit { Text(unit).font(MP.F.labelSM()).foregroundStyle(MP.C.textMuted) }
            }
            Text(label).font(MP.F.labelSM(.semibold)).foregroundStyle(MP.C.textMuted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .mpEdge(fill: MP.C.surfaceCard, edge: MP.C.edgeCard, radius: MP.R.card)
    }
}

// MARK: - MPPlanCard

struct MPPlanCard: View {
    let name: String
    let price: String
    var period: String = "/ay"
    var stars: String? = nil
    var note: String? = nil
    var isRecommended: Bool = false
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(name).font(MP.F.displaySM()).foregroundStyle(MP.C.textTitle)
                        if isRecommended { MPBadge(title: "En çok seçilen", tone: .reward) }
                    }
                    if let stars {
                        HStack(spacing: 5) {
                            MPIcon("star.fill", size: 14, weight: .bold)
                            Text(stars)
                        }
                        .font(MP.F.bodySM(.bold))
                        .foregroundStyle(MP.C.premiumInk)
                    }
                    if let note { Text(note).font(MP.F.labelSM(.regular)).foregroundStyle(MP.C.textMuted) }
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(price).font(MP.F.displayHeavy(26)).foregroundStyle(MP.C.textTitle)
                    Text(period).font(MP.F.caption()).foregroundStyle(MP.C.textMuted)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mpEdge(
                fill: isSelected ? MP.C.rewardSoft : MP.C.surfaceCard,
                edge: isSelected ? MP.C.rewardEdge : MP.C.borderStrong,
                radius: MP.R.card, width: MP.E.widthLG
            )
            .overlay(
                RoundedRectangle(cornerRadius: MP.R.card, style: .continuous)
                    .strokeBorder(isSelected ? MP.C.reward : MP.C.borderHairline, lineWidth: 2)
                    .padding(.bottom, MP.E.widthLG)
            )
        }
        .buttonStyle(MPPressStyle(scales: false))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - MPProgressRing

struct MPProgressRing: View {
    var value: Double = 0
    var size: CGFloat = 120
    var thickness: CGFloat = 12
    var color: Color = MP.C.brand
    var label: String? = nil
    var caption: String? = nil

    var body: some View {
        ZStack {
            Circle().fill(MP.C.surfaceCard)
            Circle()
                .stroke(MP.Palette.kagit300, lineWidth: thickness)
                .padding(thickness / 2)
            Circle()
                .trim(from: 0, to: max(0, min(1, value)))
                .stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .butt))
                .rotationEffect(.degrees(-90))
                .padding(thickness / 2)
            VStack(spacing: 2) {
                if let label {
                    Text(label).font(MP.F.displayHeavy(round(size * 0.24))).foregroundStyle(MP.C.textTitle)
                }
                if let caption {
                    Text(caption).font(MP.F.caption()).foregroundStyle(MP.C.textMuted)
                }
            }
        }
        .frame(width: size, height: size)
        .animation(MP.M.gated(MP.M.base), value: value)
        .accessibilityLabel("İlerleme")
        .accessibilityValue("\(Int((value * 100).rounded())) yüzde")
    }
}

// MARK: - MPEmptyState

struct MPEmptyState: View {
    let title: String
    var description: String? = nil
    var illustration: String? = nil
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil
    var secondaryLabel: String? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            if let illustration {
                Image(illustration)
                    .resizable().scaledToFit()
                    .frame(width: 168, height: 168)
                    .mpShadow(MP.Sh.art)
            }
            VStack(spacing: 6) {
                Text(title).font(MP.F.displayMD()).foregroundStyle(MP.C.textTitle)
                if let description {
                    Text(description)
                        .font(MP.F.bodyMD())
                        .lineSpacing(16 * 0.55)
                        .foregroundStyle(MP.C.textMuted)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: 320)

            if let actionLabel, let action {
                MPButton(title: actionLabel, icon: "wand.and.stars", action: action)
            }
            if let secondaryLabel, let secondaryAction {
                MPButton(title: secondaryLabel, variant: .ghost, size: .sm, action: secondaryAction)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - MPToast

struct MPToast: View {
    enum Tone { case calm, reward, danger }

    let message: String
    var symbol: String = "checkmark"
    var tone: Tone = .calm

    private var colors: (bg: Color, fg: Color) {
        switch tone {
        case .calm:   return (MP.C.calm, MP.Palette.kagit0)
        case .reward: return (MP.C.reward, MP.Palette.murekkep900)
        case .danger: return (MP.C.danger, MP.Palette.kagit0)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            MPIcon(symbol, size: 18, weight: .bold)
            Text(message)
            Spacer(minLength: 0)
        }
        .font(MP.F.bodySM(.bold))
        .foregroundStyle(colors.fg)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .mpEdge(fill: colors.bg, edge: MP.C.edgeOnColor, radius: MP.R.md)
        .mpShadow(MP.Sh.lifted)
        .padding(.horizontal, MP.S.screenGutter)
        .allowsHitTesting(false)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// Toast sunucusu — 2200ms sonra kendini kapatır, alttan 96px yukarıda durur.
struct MPToastHost: ViewModifier {
    @Binding var toast: MPToastMessage?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast {
                MPToast(message: toast.message, symbol: toast.symbol, tone: toast.tone)
                    .padding(.bottom, 96)
                    .transition(.opacity.combined(with: .offset(y: 8)))
                    .task(id: toast.id) {
                        try? await Task.sleep(nanoseconds: 2_200_000_000)
                        withAnimation(MP.M.gated(MP.M.easeOut)) { self.toast = nil }
                    }
            }
        }
    }
}

struct MPToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    var symbol: String = "checkmark"
    var tone: MPToast.Tone = .calm
}

extension View {
    func mpToast(_ toast: Binding<MPToastMessage?>) -> some View {
        modifier(MPToastHost(toast: toast))
    }
}

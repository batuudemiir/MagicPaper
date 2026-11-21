import SwiftUI

// Ana sayfa "Okuma köşesi" (19 Kasım 2026, İrem; tasarım: GPT teslimi
// `MagicPaper-Okuma-Kosesi`, referans görseller ve ölçüler). Sıra: selam + avatar,
// tam genişlik okuma köşesi sahnesi, "Bu akşam" daveti ve tek birincil düğme,
// "Başka bir dünya seç", "Kitaplığından", "Masal bul". Zemin `MP.C.homePaper`.

// MARK: - Okuma köşesi sahnesi

/// Pencere önünde kitap okuyan Ragi: ekranın tek Ragi'si, süs (erişilebilirlikten
/// gizli). Üst ve alt kenar kısa bir maskeyle kâğıda erir: görselin kırpılan
/// üstü (yaprak, perde, kemer) ve pembe kalan altı keskin çizgi bırakmasın (21 Kasım, İrem). Bu bir arayüz yüzeyi değil,
/// illüstrasyonun kendi maskesidir. Küçük ekranda yükseklik kısılır, yanlar kırpılır.
struct HomeReadingNook: View {
    var height: CGFloat

    var body: some View {
        Image("Scenes/homeReadingNook")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .mask {
                LinearGradient(stops: [.init(color: .white.opacity(0), location: 0),
                                       .init(color: .white, location: 0.16),
                                       .init(color: .white, location: 0.84),
                                       .init(color: .white.opacity(0), location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .accessibilityHidden(true)
    }

    /// Görselin oranı (852 × 779): tam genişlikte doğal yükseklik.
    static let aspect: CGFloat = 779.0 / 852.0
}

// MARK: - Bu akşamın daveti

/// "Bu akşam / Bir masal daha?" ve sayfanın tek birincil düğmesi. Dört durum
/// `HomeHeroCard` ile aynı (`TonightState`); kart yüzeyi yok, sahnenin altında
/// kâğıdın üstünde durur.
struct HomeTonightInvite: View {
    let state: TonightState
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xs) {
            Text(eyebrow).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
            Text(title).mpText(.cover).foregroundStyle(MPColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let sub {
                Text(sub).mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            MPButton(title: buttonTitle, systemImage: buttonIcon, size: .hero, fullWidth: true, action: onPrimary)
                .padding(.top, MPSpacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var eyebrow: String {
        switch state {
        case .resume: "Kaldığın yerden"
        case .unread: "Bu akşamın masalı"
        case .readToday: "Bu akşam"
        case .bedtime(let time): "Saat \(time)"
        }
    }
    private var title: String {
        switch state {
        case .resume(_, let t, _): t
        case .unread(let t, _): t
        case .readToday: "Bir masal daha?"
        case .bedtime: "Uyku masalı zamanı"
        }
    }
    private var sub: String? {
        switch state {
        case .resume(_, _, let m): m
        case .unread(_, let m): m
        case .readToday, .bedtime: nil
        }
    }
    private var buttonTitle: String {
        switch state {
        case .resume: "Okumaya devam et"
        case .unread: "Masalı oku"
        case .readToday: "Yeni masal yaz"
        case .bedtime: "Uyku masalı yaz"
        }
    }
    private var buttonIcon: String {
        switch state {
        case .readToday: "wand.and.sparkles"
        default: "book"
        }
    }
}

// MARK: - Başka bir dünya seç

/// Resimli mod karosu: pastel zemin, üstte saydam zeminli çizim, altta adı.
/// Çizimi olmayan mod (Uyku öncesi) simgesiyle gelir.
struct HomeWorldTile: View {
    let title: String
    let art: String?
    let systemImage: String
    let tone: MPWorldTone
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MPSpacing.xs) {
                Group {
                    if let art {
                        Image(art).resizable().aspectRatio(contentMode: .fit)
                    } else {
                        MPIcon(systemImage, size: MP.G.xxl, weight: .semibold).foregroundStyle(tone.deep)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: MPSize.minTouchHero + MPSpacing.md)
                .accessibilityHidden(true)
                Text(title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, MPSpacing.md)
            .padding(.horizontal, MPSpacing.sm)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Masalda kimlerin olacağını seçmeye geçer")
    }
}

extension StoryMode {
    /// Ana sayfa dünya karosunun çizimi; yoksa simge.
    var homeWorldArt: String? {
        switch self {
        case .learning: "Scenes/homeWorldLearning"
        case .adventure: "Scenes/homeWorldAdventure"
        case .bedtime: nil
        }
    }
}

// MARK: - Kitaplığından

/// Kitaplıktan bir kitap: kapak ve ad tek dokunma hedefi. Yarım kitap kaldığı
/// sayfadan, okunmamış kitap ilk sayfadan açılır (çağıran karar verir).
struct HomeShelfBook: View {
    let item: LibraryItem
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                MPBookCover(art: item.art, badge: item.isPartlyRead ? .progress(item.progress) : nil, width: width)
                Text(item.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(status).mpText(.supporting).foregroundStyle(MPColor.textSecondary)
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(item.isPartlyRead ? "Kaldığın sayfadan açar" : "Masalı açar")
    }

    private var status: String {
        if item.progress >= 1 { return "Okundu" }
        if item.progress <= 0 { return "Henüz okunmadı" }
        return item.pageLabel
    }
}

// MARK: - Masal bul

/// Arama girişi gibi görünen düğme: dokununca Masallar'da arama odakla açılır.
struct HomeFindField: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.md) {
                MPIcon("magnifyingglass", size: MP.G.md, weight: .semibold)
                    .foregroundStyle(MPColor.textPrimary)
                    .accessibilityHidden(true)
                Text("Masal adı veya konu").mpText(.body).foregroundStyle(MPColor.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, MPSpacing.lg)
            .frame(minHeight: MPSize.inputHeight)
            .background(MPColor.actionSoft, in: RoundedRectangle(cornerRadius: MPRadius.input, style: .continuous))
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityLabel("Masal ara")
        .accessibilityHint("Masallar'da aramayı açar")
    }
}

/// Aramanın altındaki tek editoryal öneri: kapak, ad, kaynak ve süre.
struct HomePickRow: View {
    let title: String
    let meta: String
    let cover: String
    let focus: ClassicFocus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.md) {
                ClassicCoverImage(asset: cover, focus: focus, seed: title)
                    .frame(width: MPSize.minTouchHero * 1.75, height: MPSize.minTouchHero * 1.6)
                    .clipShape(RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text(title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(meta).mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                }
                Spacer(minLength: 0)
                MPIcon("chevron.right", size: MP.G.sm, weight: .semibold)
                    .foregroundStyle(MPColor.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Masalın sayfasını açar")
    }
}

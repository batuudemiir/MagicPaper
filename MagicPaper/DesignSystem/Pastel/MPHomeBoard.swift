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
    let onPrimary: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Ragi'nin genişliği; metin onun yanından başlar.
    private static let ragiWidth: CGFloat = 112

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text(eyebrow).mpText(.footnote).fontWeight(.bold).foregroundStyle(MP.C.textOnArtMuted)
            Text(title).font(MP.F.displaySM()).foregroundStyle(MP.C.textOnArt)
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
        .mpEdge(fill: MP.C.homeTonight, edge: MP.C.homeTonightEdge, radius: MPRadius.card, width: MP.E.widthLG)
        // Ragi yerleşimi büyütmez: ayakları kartın alt çizgisinde, başı kartın
        // üstüne taşar. En büyük yazıda metne yer kalsın diye çizilmez.
        .overlay(alignment: .bottomLeading) {
            if !typeSize.isAccessibilitySize {
                MascotImage(mascot: mascot, width: Self.ragiWidth)
                    .offset(x: -MPSpacing.xs)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    private var tag: some View {
        Text(tagText).mpText(.footnote).fontWeight(.bold).foregroundStyle(MP.C.textOnArt)
            .padding(.horizontal, MPSpacing.md)
            .frame(minHeight: MPSize.buttonHeightSmall)
            .background(MP.C.textOnArt.opacity(0.14), in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
    }

    private var button: some View {
        MPButton(title: buttonTitle, systemImage: buttonIcon, kind: .secondary, size: .small, action: onPrimary)
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

    private var eyebrow: String {
        switch state {
        case .resume: "Kaldığın yerden"
        case .unread: "Bu akşamın masalı"
        case .readToday: "Bugün okudun"
        case .bedtime(let t): "Saat \(t)"
        }
    }
    private var title: String {
        switch state {
        case .resume(_, let t, _), .unread(let t, _): t
        case .readToday: "Yarın yeni bir masal var"
        case .bedtime: "Uyku masalı zamanı"
        }
    }
    private var tagText: String {
        switch state {
        case .resume(_, _, let m), .unread(_, let m): m
        case .readToday(let canWrite): canWrite ? "Bir tane daha?" : "Kitaplığın hazır"
        case .bedtime: "Kısa ve sakin"
        }
    }
    private var buttonTitle: String {
        switch state {
        case .resume: "Devam et"
        case .unread: "Masalı oku"
        case .readToday(let canWrite): canWrite ? "Yeni masal yaz" : "Kitaplığına bak"
        case .bedtime: "Uyku masalı yaz"
        }
    }
    private var buttonIcon: String {
        switch state {
        case .resume: "play.fill"
        case .unread: "book"
        case .readToday(let canWrite): canWrite ? "wand.and.sparkles" : "books.vertical"
        case .bedtime: "moon.fill"
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

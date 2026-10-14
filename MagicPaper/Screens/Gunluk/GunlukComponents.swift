// GunlukComponents.swift
// Günlük (FAZ 20) yapı taşları: odak noktalı boyalı kapak, koyu seçimli çip,
// raf başlığı, raf kartı, sıralı seçki kartı, "Kaldığın yerden" kartı.
// Ekranlar: Gunluk, GunlukRaf, KlasikDetay, SeriKlasik (İrem'in demo canvas'ı).

import SwiftUI

// MARK: - Kapak

/// Boyalı kapak: yüzeyi doldurur, `focus` CSS `object-position` gibi neyin
/// görünür kalacağını seçer. Çizimi henüz gelmemiş kapak düz renkli bir yedek
/// olur (Rapunzel kuralının tek istisnası, `pendingCovers`).
struct ClassicCoverImage: View {
    let asset: String
    var focus: ClassicFocus = .center
    /// Yedek kapağın rengini seçmek için.
    var seed: String = ""

    var body: some View {
        GeometryReader { geo in
            if let image = UIImage(named: asset) {
                let size = Self.fillSize(image: image.size, frame: geo.size)
                Image(uiImage: image)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .offset(x: (geo.size.width - size.width) * focus.x,
                            y: (geo.size.height - size.height) * focus.y)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                    .clipped()
            } else {
                let tone = Self.fallbackTone(seed)
                // Ana sayfanın dili: pastel ton yalnızca zeminde, simge koyu tonda.
                ZStack {
                    tone.soft
                    MPIcon("book.closed", size: min(geo.size.width, geo.size.height) * 0.28, weight: .regular)
                        .foregroundStyle(tone.deep)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// Çerçeveyi taşmadan dolduran boyut (scaledToFill).
    static func fillSize(image: CGSize, frame: CGSize) -> CGSize {
        guard image.width > 0, image.height > 0 else { return frame }
        let scale = max(frame.width / image.width, frame.height / image.height)
        return CGSize(width: image.width * scale, height: image.height * scale)
    }

    private static let fallbackTones: [MPWorldTone] = [.green, .peach, .sky, .lav, .mint, .pink, .yellow]

    static func fallbackTone(_ seed: String) -> MPWorldTone {
        let sum = seed.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return fallbackTones[abs(sum) % fallbackTones.count]
    }
}

/// Rafta duran kapak: köşe 14; derinlik Ana sayfadaki gibi sert alt kenardan
/// (`mpKidSurface`), gölgeden değil.
struct ClassicCoverTile: View {
    let asset: String
    var focus: ClassicFocus = .center
    var seed: String = ""
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ClassicCoverImage(asset: asset, focus: focus, seed: seed)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
            .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.md)
    }
}

// MARK: - Çip

/// Günlük'ün çipi: seçili olan mürekkep rengi, diğerleri gömük krem.
struct GunlukChip: View {
    let title: String
    var isSelected: Bool = false
    var trailingChevron: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.xxs) {
                Text(title).mpText(.callout).lineLimit(1)
                if trailingChevron {
                    MPIcon("chevron.down", size: 11, weight: .bold).accessibilityHidden(true)
                }
            }
            .foregroundStyle(isSelected ? MPColor.textOnAction : MPColor.textPrimary)
            .padding(.horizontal, MPSpacing.md + 2)
            .frame(minHeight: 34)
            .background(isSelected ? MPColor.textPrimary : MPColor.backgroundSunken, in: Capsule())
            .contentShape(Capsule().inset(by: -6))
        }
        .buttonStyle(MPPressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Kartlar

/// Raftaki öğe: kapak, başlık, ikinci satır.
struct ClassicShelfCard: View {
    let title: String
    let meta: String
    let cover: String
    var focus: ClassicFocus = .center
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                ClassicCoverTile(asset: cover, focus: focus, seed: title, width: width, height: height)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).mpText(.callout).foregroundStyle(MPColor.textPrimary).lineLimit(1)
                    Text(meta).mpText(.caption).foregroundStyle(MPColor.textSecondary).lineLimit(1)
                }
                .padding(.horizontal, MPSpacing.xxs / 2)
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(meta)")
    }
}

extension ClassicShelfCard {
    init(item: ClassicItem, width: CGFloat, height: CGFloat, action: @escaping () -> Void) {
        self.init(title: item.title, meta: item.meta, cover: item.cover, focus: item.coverFocus,
                  width: width, height: height, action: action)
    }
}

/// "Bu haftanın seçkisi": kapağın arkasında büyük sıra numarası.
struct RankedPickCard: View {
    let rank: Int
    let item: ClassicItem
    let action: () -> Void

    private let coverWidth: CGFloat = 112
    private let coverHeight: CGFloat = 168

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Text("\(rank)")
                    .font(.mpRankNumeral)
                    .tracking(-9)
                    .foregroundStyle(MPColor.classicRank)
                    .dynamicTypeSize(.large)
                    .fixedSize()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .offset(y: 14)
                    .accessibilityHidden(true)
                ClassicCoverTile(asset: item.cover, focus: item.coverFocus, seed: item.title,
                                 width: coverWidth, height: coverHeight)
            }
            .frame(width: rank >= 10 ? 176 : 150, height: coverHeight)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel("\(rank). \(item.title)")
    }
}

/// "Kaldığın yerden": yatay kırpım, ilerleme çubuğu, kalan süre.
struct ContinueClassicCard: View {
    let item: ClassicsLibrary.InProgress
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                ClassicCoverImage(asset: item.cover, focus: item.coverFocus, seed: item.title)
                    .frame(width: 252, height: 142)
                    .overlay(alignment: .bottom) {
                        GeometryReader { geo in
                            Capsule().fill(MPColor.backgroundSurface.opacity(0.6))
                                .overlay(alignment: .leading) {
                                    Capsule().fill(MPColor.textPrimary)
                                        .frame(width: geo.size.width * item.fraction)
                                }
                        }
                        .frame(height: 4)
                        .padding(.horizontal, MPSpacing.md)
                        .padding(.bottom, MPSpacing.sm + 2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                    .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.md)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title).mpText(.callout).foregroundStyle(MPColor.textPrimary).lineLimit(1)
                    Text("\(item.minutesLeft) dk kaldı").mpText(.caption).foregroundStyle(MPColor.textSecondary)
                }
                .padding(.horizontal, MPSpacing.xxs / 2)
            }
            .frame(width: 252, alignment: .leading)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.minutesLeft) dakika kaldı")
        .accessibilityHint("Kaldığın yerden devam eder")
    }
}

/// Yatay kaydırılan raf.
///
/// `inset` verilmezse ekran kenarından kenarına kayar (çip satırı). Bir
/// `GunlukSection` kartının içindeyken kartın iç boşluğuyla başlar ve kartın
/// kenarında kesilir: kart içinde kart görünmez, kenar temiz kalır.
struct GunlukRow<Content: View>: View {
    var spacing: CGFloat = 14
    var inset: CGFloat? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        if let inset {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: spacing) { content() }
                    .padding(.horizontal, inset)
                    // Kapakların sert alt kenarı kesilmesin.
                    .padding(.bottom, MP.E.widthLG + MPSpacing.xxs)
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: spacing) { content() }
                    .padding(.horizontal, MPSpacing.screenH)
                    .padding(.vertical, MPSpacing.xxs)
            }
            .scrollClipDisabled()
            .padding(.horizontal, -MPSpacing.screenH)
        }
    }
}

// MARK: - Bölüm kartı

/// Günlük'ün her rafı Ana sayfadaki bölüm kartı gibi tek bir kart: beyaz zemin,
/// lavanta kenar, sert alt kenar (`mpKidSurface`, `MPRadius.card`); başlık
/// kartın üst satırında, sağda "tümü" oku. Raf kartın içinde kayar.
struct GunlukSection<Content: View>: View {
    let title: String
    var action: (() -> Void)? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            HStack(alignment: .center, spacing: MPSpacing.sm) {
                Text(title).mpText(.headline).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                if let action {
                    Button(action: action) {
                        MPIcon("chevron.right", size: MP.G.md, weight: .bold)
                            .foregroundStyle(MPColor.actionPrimary)
                            .frame(width: MPSize.minTouchParent, height: MPSize.minTouchParent)
                            .background(MPWorldTone.lav.soft, in: Circle())
                    }
                    .buttonStyle(MPPressStyle())
                    .accessibilityLabel("\(title): tümü")
                }
            }
            .padding(.horizontal, MPSpacing.lg)
            content
        }
        .padding(.vertical, MPSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
    }
}

/// Alt barın (Ana sayfa · Günlük · Yarat · Kitaplık · Köşem) kapladığı yükseklik.
/// Günlük `NavigationStack` içinde durduğu için kök görünümdeki alt bar
/// boşluğu (`safeAreaInset`) kaydırma alanına ulaşmıyor; sayfalar bu kadar
/// alt boşlukla biter ki son kart barın altında kalmasın.
enum GunlukLayout {
    static let bottomClearance: CGFloat = MPSize.kidTabBarHeight + MPSize.minTouchKid
}

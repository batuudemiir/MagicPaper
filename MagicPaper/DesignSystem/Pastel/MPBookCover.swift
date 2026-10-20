// MPBookCover.swift
// Kitaplığın tek kapağı (karar 20 Ekim 2026).
//
// Kitaplıkta iki tür kitap yan yana durur: Günlük'ün boyalı klasikleri ve
// çocuğun kendi masalları. Klasikler Günlük'teki kapaklarıyla durur; kendi
// masalı okuyucudaki kâğıt mozaik kapağıyla (aynı kitap, rafta ve okuyucuda).
// Bütünlük biçimden gelir: hepsi Günlük rafının ölçüsünde (128 × 176 oranı),
// aynı köşe ve aynı sert alt kenarla; başlık kapağın altında.
// Sağ üstte tek rozet yeri; öncelik yarım → bölüm → favori.

import SwiftUI

struct MPBookCover: View {
    enum Art: Equatable {
        /// Boyalı ya da illüstrasyon kapak.
        case image(String, focus: ClassicFocus = .center)
        /// Metin masalının üretilmiş kâğıt mozaiği.
        case mosaic(MagicPaperCoverConfiguration)
        /// Kapağı olmayan masal: dünya simgesi.
        case symbol(String, MPWorldTone)

        static func == (lhs: Art, rhs: Art) -> Bool {
            switch (lhs, rhs) {
            case let (.image(a, fa), .image(b, fb)): return a == b && fa == fb
            case let (.mosaic(a), .mosaic(b)): return a.seed == b.seed && a.bookID == b.bookID
            case let (.symbol(a, ta), .symbol(b, tb)): return a == b && ta == tb
            default: return false
            }
        }
    }

    enum Badge: Equatable {
        case progress(Double)
        case episode(Int, of: Int)
        case favorite
    }

    let art: Art
    var badge: Badge? = nil
    let width: CGFloat

    /// Günlük rafının kapak oranı (128 × 176).
    static let aspect: CGFloat = 176.0 / 128.0

    var body: some View {
        artwork
            .frame(width: width, height: width * Self.aspect)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if let badge { badgeView(badge).padding(MPSpacing.xs) }
            }
            .clipShape(RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
            .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.md)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var artwork: some View {
        switch art {
        case let .image(name, focus):
            ClassicCoverImage(asset: name, focus: focus, seed: name)
        case let .mosaic(configuration):
            MagicPaperCoverView(configuration: configuration, showsBrand: false, fillsProposedSize: true)
        case let .symbol(symbol, tone):
            ZStack {
                tone.soft
                MPIcon(symbol, size: width * 0.3, weight: .regular)
                    .foregroundStyle(tone.deep)
            }
        }
    }

    @ViewBuilder
    private func badgeView(_ badge: Badge) -> some View {
        switch badge {
        case let .progress(fraction):
            HStack(spacing: MPSpacing.xxs) {
                ZStack {
                    Circle().stroke(MPColor.ringTrack, lineWidth: 2.5)
                    Circle().trim(from: 0, to: fraction)
                        .stroke(MPColor.actionPrimary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: MP.G.xs, height: MP.G.xs)
                Text("Yarım").mpText(.caption)
            }
            .foregroundStyle(MPColor.textPrimary)
            .padding(.horizontal, MPSpacing.sm)
            .padding(.vertical, MPSpacing.xxs)
            .background(MPColor.backgroundSurface, in: Capsule())
        case let .episode(number, total):
            Text("\(number)/\(total)")
                .mpText(.caption)
                .monospacedDigit()
                .foregroundStyle(MPColor.textPrimary)
                .padding(.horizontal, MPSpacing.sm)
                .padding(.vertical, MPSpacing.xxs)
                .background(MPColor.backgroundSurface, in: Capsule())
        case .favorite:
            MPIcon("heart.fill", size: MP.G.xs, weight: .bold)
                .foregroundStyle(MPWorldTone.pink.deep)
                .frame(width: MP.G.xs + MPSpacing.md, height: MP.G.xs + MPSpacing.md)
                .background(MPColor.backgroundSurface, in: Circle())
        }
    }
}

/// Rafta duran kitap: kapak, altında başlık ve tek satır bilgi (kategori · süre).
/// Başlık kapağın üstüne binmez; uzun başlık iki satıra iner. Kapaklar her
/// kartta aynı boyda ve raflar/ızgara üstten hizalı; kısa başlığın altında
/// boş satır bırakılmaz, bilgi satırı başlığa yapışır (Batuhan, 21 Ekim).
struct MPBookCard: View {
    let title: String
    let meta: String
    let art: MPBookCover.Art
    var badge: MPBookCover.Badge? = nil
    let width: CGFloat
    /// VoiceOver'da rozetin anlamı.
    var accessibilityStatus: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                MPBookCover(art: art, badge: badge, width: width)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).mpText(.callout).foregroundStyle(MPColor.textPrimary)
                        .lineLimit(2).multilineTextAlignment(.leading)
                        // Yatay rafta da iki satıra insin, tek satırda kesilmesin.
                        .fixedSize(horizontal: false, vertical: true)
                    Text(meta).mpText(.caption).foregroundStyle(MPColor.textSecondary).lineLimit(1)
                }
                .padding(.horizontal, MPSpacing.xxs / 2)
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([title, meta, accessibilityStatus].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
    }
}

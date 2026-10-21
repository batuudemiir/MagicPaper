// MPBookCover.swift
// Kitaplığın tek kapağı (karar 20 Ekim 2026; başlık kapağı 21 Ekim 2026).
//
// Kitaplıkta iki tür kitap yan yana durur: Günlük'ün boyalı klasikleri ve
// çocuğun kendi masalları. Klasikler Günlük'teki kapaklarıyla durur. Kendi
// masalının kapağı başlık kapağıdır (Batuhan, 21 Ekim): mod renginde kâğıt,
// ortada masalın adı, üstte mod simgesi, altta dünya simgesi ve yıldız.
// Mozaik kapaklar birbirine çok benziyordu; masalı ayırt eden adı, kapağın
// kendisi o. Masal setinin illüstrasyon kapağı gelirse o kullanılır.
// Bütünlük biçimden gelir: hepsi Günlük rafının ölçüsünde (128 × 176 oranı),
// aynı köşe ve aynı sert alt kenarla. Sağ üstte tek rozet yeri; öncelik
// yarım → bölüm → favori.

import SwiftUI

struct MPBookCover: View {
    enum Art: Equatable {
        /// Boyalı ya da illüstrasyon kapak.
        case image(String, focus: ClassicFocus = .center)
        /// Başlık kapağı: mod tonunda kâğıt, ortada masalın adı.
        /// `modeSymbol` yoksa (modu bilinmeyen eski masal) simge çizilmez.
        case title(String, tone: MPWorldTone, modeSymbol: String?, worldSymbol: String)
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
        case let .title(title, tone, modeSymbol, worldSymbol):
            TitleCoverFace(title: title, tone: tone, modeSymbol: modeSymbol,
                           worldSymbol: worldSymbol, width: width)
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

extension MPBookCover.Art {
    /// Kapak masalın adını taşıyor mu.
    var showsTitle: Bool {
        if case .title = self { return true }
        return false
    }
}

extension MPWorldTone {
    /// Kapak başlığının rengi: büyük metin için zemine karşı en az 3:1.
    /// Sarı ve yeşilin koyu tonu açık zeminde yetmiyor (2.0 ve 3.0).
    var coverTitle: Color {
        switch self {
        case .yellow: return MPColor.yellowText
        case .green, .mint: return MPColor.greenText
        default: return deep
        }
    }
}

/// Başlık kapağının yüzü. Dar kapakta (Kaldığın yerden kartı) ad yazılmaz,
/// yanında zaten yazıyor; yalnızca dünya simgesi büyür.
private struct TitleCoverFace: View {
    let title: String
    let tone: MPWorldTone
    let modeSymbol: String?
    let worldSymbol: String
    let width: CGFloat

    private var compact: Bool { width < 90 }

    var body: some View {
        ZStack {
            tone.soft
            Image(uiImage: ReaderGrain.tile).resizable(resizingMode: .tile)
                .opacity(0.06).blendMode(.multiply)
            if compact {
                MPIcon(worldSymbol, size: width * 0.4, weight: .semibold)
                    .foregroundStyle(tone.coverTitle.opacity(0.8))
            } else {
                VStack(spacing: MPSpacing.sm) {
                    HStack {
                        if let modeSymbol {
                            MPIcon(modeSymbol, size: MP.G.xs, weight: .bold)
                                .foregroundStyle(tone.coverTitle)
                                .frame(width: MP.G.xs + MPSpacing.md, height: MP.G.xs + MPSpacing.md)
                                .background(MPColor.backgroundSurface, in: Circle())
                        }
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                    Text(title)
                        .font(MP.F.displaySM())
                        .foregroundStyle(tone.coverTitle)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 0)
                    HStack(spacing: MPSpacing.xs) {
                        MPIcon(worldSymbol, size: MP.G.sm, weight: .semibold)
                            .foregroundStyle(tone.coverTitle.opacity(0.75))
                        Spacer(minLength: 0)
                        MPStarMark(size: MP.G.sm)
                    }
                }
                .padding(MPSpacing.md)
            }
        }
    }
}

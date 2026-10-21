// LibraryComponents.swift
// Kitaplığın yapı taşları (20 Ekim 2026): arama alanı, "Kaldığın yerden"
// kartı, kitap ızgarası. Dil Ana sayfa ve Günlük'le aynı: beyaz yüzey,
// sert alt kenar (`mpKidSurface`), kapaklar `MPBookCover`.

import SwiftUI

/// Kitap arama alanı: başlık, mod, dünya ve çocuk adında arar.
struct LibrarySearchField: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            MPIcon("magnifyingglass", size: MP.G.md, weight: .semibold)
                .foregroundStyle(MPColor.textSecondary)
                .accessibilityHidden(true)
            TextField("Masal, dünya ya da mod ara", text: $text)
                .font(.mp(.bodyStrong))
                .foregroundStyle(MPColor.textPrimary)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .focused(focused)
            if !text.isEmpty {
                Button { text = "" } label: {
                    MPIcon("xmark", size: MP.G.sm, weight: .bold).foregroundStyle(MPColor.textSecondary)
                        .frame(width: MP.S.tapMin, height: MP.S.tapMin)
                }
                .accessibilityLabel("Aramayı temizle")
            }
        }
        .padding(.leading, MPSpacing.lg)
        .padding(.trailing, text.isEmpty ? MPSpacing.lg : 0)
        .frame(minHeight: MPSize.inputHeight)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.input)
    }
}

/// "Kaldığın yerden": küçük kapak, başlık, ilerleme çubuğu, "Devam".
struct LibraryContinueCard: View {
    let item: LibraryItem
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // En büyük yazı boyutlarında kapak yazının üstüne çıkar; başlık
        // dar bir sütunda ezilmez.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: MPSpacing.md))
            : AnyLayout(HStackLayout(spacing: MPSpacing.lg))
        Button(action: action) {
            layout {
                MPBookCover(art: item.art, width: typeSize.isAccessibilitySize ? 96 : 64)
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text(item.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        .lineLimit(2).multilineTextAlignment(.leading)
                    Text(item.meta).mpText(.caption).foregroundStyle(MPColor.textSecondary)
                    GeometryReader { geo in
                        Capsule().fill(MPColor.ringTrack)
                            .overlay(alignment: .leading) {
                                Capsule().fill(MPColor.actionPrimary)
                                    .frame(width: geo.size.width * item.progress)
                            }
                    }
                    .frame(height: 6)
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                MPIcon("play.fill", size: MP.G.sm, weight: .bold)
                    .foregroundStyle(MPColor.textOnAction)
                    .frame(width: MP.S.tapMin, height: MP.S.tapMin)
                    .background(MPColor.actionPrimary, in: Circle())
                    .accessibilityHidden(true)
            }
            .padding(MPSpacing.md)
            .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.card)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.title), \(item.meta), yüzde \(Int(item.progress * 100)) okundu")
        .accessibilityHint("Kaldığın yerden devam eder")
        .accessibilityAddTraits(.isButton)
    }
}

/// Kitaplık rafı (21 Ekim 2026): kapaklar sıra sıra ince bir rafın üstünde
/// durur, adı ve "Dün · 4 dk" rafın altında, kitabın etiketi gibi. Kitap
/// sırtı yok (20 Ekim'deki sırt rafı geri alınmıştı). İki sütun; en büyük
/// yazı boyutlarında tek sütun.
struct LibraryShelfGrid: View {
    let items: [LibraryItem]
    let pageWidth: CGFloat
    let singleColumn: Bool
    let open: (LibraryItem) -> Void

    private var columns: Int { singleColumn ? 1 : 2 }
    private var inner: CGFloat { max(0, pageWidth - MPSpacing.screenH * 2) }
    private var coverWidth: CGFloat {
        singleColumn ? min(inner, 220) : (inner - MPSpacing.lg) / 2
    }

    private var rows: [[LibraryItem]] {
        stride(from: 0, to: items.count, by: columns).map { Array(items[$0..<min($0 + columns, items.count)]) }
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: MPSpacing.xl) {
            ForEach(rows, id: \.first?.id) { row in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .bottom, spacing: MPSpacing.lg) {
                        ForEach(row) { item in
                            Button { open(item) } label: {
                                MPBookCover(art: item.art, badge: item.badge, width: coverWidth)
                            }
                            .buttonStyle(MPPressStyle())
                            .accessibilityLabel([item.title, item.meta, item.accessibilityStatus]
                                .compactMap { $0 }.joined(separator: ", "))
                        }
                    }
                    .padding(.horizontal, MPSpacing.xs)
                    ShelfPlank()
                    HStack(alignment: .top, spacing: MPSpacing.lg) {
                        ForEach(row) { item in
                            Button { open(item) } label: { label(item) }
                                .buttonStyle(MPPressStyle())
                                // VoiceOver kapağın düğmesini okur; etiket tekrar etmesin.
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, MPSpacing.xs)
                    .padding(.top, MPSpacing.sm)
                }
            }
        }
    }

    /// Rafın altındaki etiket: başlık kapağında ad zaten kapakta, yalnızca
    /// bilgi; boyalı kapakta ad ve bilgi.
    private func label(_ item: LibraryItem) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            if !item.art.showsTitle {
                Text(item.title).mpText(.callout).foregroundStyle(MPColor.textPrimary)
                    .lineLimit(2).multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(item.meta).mpText(.caption).foregroundStyle(MPColor.textSecondary).lineLimit(1)
        }
        .frame(width: coverWidth, alignment: .leading)
    }
}

/// İnce raf tahtası: sıcak kâğıt tonunda, sistemin sert alt kenarıyla.
private struct ShelfPlank: View {
    var body: some View {
        Color.clear
            .frame(height: MP.S.x2)
            .mpKidSurface(MPColor.segmentTrack, edge: MPWorldTone.peach.edge, radius: MPRadius.xs)
            .padding(.top, MP.E.widthLG)
            .accessibilityHidden(true)
    }
}

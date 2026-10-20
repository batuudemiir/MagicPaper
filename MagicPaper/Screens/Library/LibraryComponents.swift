// LibraryComponents.swift
// Kitaplığın yapı taşları (20 Ekim 2026): arama alanı, "Kaldığın yerden"
// kartı, yatay kitap rafı. Dil Ana sayfa ve Günlük'le aynı: beyaz yüzey,
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

/// Yatay kitap rafı: ekran kenarından kenarına kayar.
struct LibraryShelfRow: View {
    let items: [LibraryItem]
    let width: CGFloat
    let open: (LibraryItem) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: MPSpacing.lg) {
                ForEach(items) { item in
                    MPBookCard(title: item.title, meta: item.meta, art: item.art, badge: item.badge,
                               width: width, accessibilityStatus: item.accessibilityStatus) { open(item) }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            // Alt kenar (mpKidSurface) kesilmesin.
            .padding(.bottom, MP.E.widthLG)
        }
        .padding(.horizontal, -MPSpacing.screenH)
    }
}

/// İki sütun kitap ızgarası; en büyük yazı boyutlarında tek sütun.
struct LibraryGrid: View {
    let items: [LibraryItem]
    let pageWidth: CGFloat
    let singleColumn: Bool
    let open: (LibraryItem) -> Void

    private var columns: Int { singleColumn ? 1 : 2 }

    private var cardWidth: CGFloat {
        let inner = max(0, pageWidth - MPSpacing.screenH * 2)
        return singleColumn ? min(inner, 220) : (inner - MPSpacing.lg) / 2
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.lg, alignment: .top),
                                 count: columns),
                  spacing: MPSpacing.xl) {
            ForEach(items) { item in
                MPBookCard(title: item.title, meta: item.meta, art: item.art, badge: item.badge,
                           width: cardWidth, accessibilityStatus: item.accessibilityStatus) { open(item) }
            }
        }
    }
}

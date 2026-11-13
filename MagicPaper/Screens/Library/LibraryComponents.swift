// LibraryComponents.swift
// Kitaplığın yapı taşları (20 Ekim 2026; rafsız düzen 13 Kasım 2026): arama
// alanı, "Kaldığın yerden" kartı, kapak duvarı. Dil Ana sayfa ve Günlük'le aynı: beyaz yüzey,
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
                .font(.mp(.cardTitle))
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

/// "Kaldığın yerden": küçük kapak, başlık, "Sayfa 2 / 6", "Devam". İlerleme
/// çubuğu yok (vizyon planı düzen 3): sayfa sayısı yeter, çubuk yarışı çağırır.
/// 13 Kasım 2026: alçak tek satır; bölüm başlığı yerine kartın içinde küçük
/// üst yazı (`eyebrow`, yalnızca ilk kartta).
struct LibraryContinueCard: View {
    let item: LibraryItem
    var eyebrow: String? = nil
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
                MPBookCover(art: item.art, width: typeSize.isAccessibilitySize ? 96 : 52)
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    if let eyebrow {
                        Text(eyebrow).mpText(.footnote).fontWeight(.bold).foregroundStyle(MPColor.actionPrimary)
                    }
                    Text(item.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        .lineLimit(2).multilineTextAlignment(.leading)
                    Text(item.pageLabel).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
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
        .accessibilityLabel([eyebrow, item.title, item.meta, item.pageLabel].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Kaldığın yerden devam eder")
        .accessibilityAddTraits(.isButton)
    }
}

/// Kitaplığın kapak duvarı (13 Kasım 2026, Batuhan: raf sistemi kalktı).
/// Üç sütun, raf çizgisi yok; her kapak sert alt kenarıyla kendi başına durur,
/// adı ve "Dün · 4 dk" altında. En büyük yazı boyutlarında iki sütun.
/// Çocuğun yıldızla aldığı renk (`MPDecor`) kapakların alt kenarında.
///
/// Kapağa dokununca `open`; basılı tutunca kapak yükselir ve altında
/// `menu` açılır (sistemin `contextMenu`'su).
struct LibraryCoverGrid<QuickActions: View>: View {
    let items: [LibraryItem]
    let pageWidth: CGFloat
    /// En büyük yazı boyutları: iki sütun.
    let wide: Bool
    let open: (LibraryItem) -> Void
    @ViewBuilder let menu: (LibraryItem) -> QuickActions
    /// Çocuğun seçtiği renk; `nil` sistemin lavanta kenarı.
    var tone: MPWorldTone? = nil

    @Environment(\.mpReaderZoom) private var readerZoom
    @EnvironmentObject private var app: MPAppState

    private var columns: Int { wide ? 2 : 3 }
    private var gap: CGFloat { MPSpacing.md }
    private var coverWidth: CGFloat {
        let inner = max(0, pageWidth - MPSpacing.screenH * 2)
        return (inner - gap * CGFloat(columns - 1)) / CGFloat(columns)
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(coverWidth), spacing: gap, alignment: .top), count: columns),
                  alignment: .leading, spacing: MPSpacing.xl) {
            ForEach(items) { item in
                Button {
                    // Faz 13: okuyucu bu kapaktan büyüyerek açılır.
                    app.readerZoomID = item.id
                    open(item)
                } label: {
                    VStack(alignment: .leading, spacing: MPSpacing.sm) {
                        MPBookCover(art: item.art, badge: item.badge, width: coverWidth, edge: tone?.coverEdge)
                            .mpZoomSource(item.id.uuidString, in: readerZoom)
                        label(item)
                    }
                }
                .buttonStyle(MPPressStyle())
                .contextMenu { menu(item) }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel([item.title, item.meta, item.accessibilityStatus]
                    .compactMap { $0 }.joined(separator: ", "))
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    /// Kapağın altındaki etiket: başlık kapağında ad zaten kapakta, yalnızca
    /// bilgi; boyalı kapakta ad ve bilgi.
    private func label(_ item: LibraryItem) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            if !item.art.showsTitle {
                Text(item.title).mpText(.footnote).fontWeight(.bold).foregroundStyle(MPColor.textPrimary)
                    .lineLimit(2).multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(item.meta).mpText(.footnote).foregroundStyle(MPColor.textSecondary).lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(width: coverWidth, alignment: .leading)
    }
}

// GunlukHeader.swift
// Masallar'ın öne çıkan kitabı: sayfa başlığının altında, kapağı bütün
// görünen bir kitap kartı. Sıra `ClassicsCatalog.headerSlides`'ta.

import SwiftUI

/// Kaydırılan "öne çıkan kitap" kartı (13 Kasım 2026: tam ekran vitrinin yerine).
///
/// - Kapak kırpılmış bir sahne değil, raflardaki gibi dik bir kitap: çocuk
///   aynı kapağı rafta da tanır (Batuhan, 13 Kasım: slaytta kapak belirsizdi).
/// - Yanında etiket, ad, meta ve küçük "Oku"; kart beyaz, sert alt kenarlı.
/// - Sayfa noktaları kartın altında.
/// - Kendiliğinden geçiş yavaş (7 sn) ve tek yönlü; kullanıcı kaydırınca durur,
///   Hareketi Azalt açıkken hiç başlamaz (sakin UX, tasarım yasası: hareket).
struct GunlukHeaderCarousel: View {
    let slides: [ClassicHeaderSlide]
    let onOpen: (ClassicTale) -> Void
    let onRead: (ClassicTale) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Döngüdeki konum (`GunlukLoop`): slayt `position % slides.count`.
    @State private var selection: Int?
    @State private var userTookOver = false


    private static let coverWidth: CGFloat = 120
    private static let coverHeight: CGFloat = 168

    private static let autoAdvance: UInt64 = 7_000_000_000

    private var current: Int {
        guard !slides.isEmpty else { return 0 }
        return (selection ?? 0) % slides.count
    }

    var body: some View {
        VStack(spacing: MPSpacing.md) {
            pager
            if slides.count > 1 {
                MPPageDots(count: slides.count, current: current)
                    .accessibilityHidden(true)
            }
        }
        .task(id: selection) { await advanceLater() }
        .onAppear { if selection == nil { selection = GunlukLoop.start(count: slides.count) } }
        // Kenara yaklaşınca ortadaki aynı slayta görünmeden atlar: sondan sonra
        // baş gelir, kaydırma iki yönde de bitmez.
        .onChange(of: selection) { _, position in
            guard let position, let centered = GunlukLoop.recentered(position, count: slides.count) else { return }
            var jump = Transaction()
            jump.disablesAnimations = true
            withTransaction(jump) { selection = centered }
        }
    }

    // MARK: - Sayfalar

    private var pager: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: MPSpacing.md) {
                ForEach(0..<GunlukLoop.length(count: slides.count), id: \.self) { position in
                    slideView(slides[position % slides.count])
                        .containerRelativeFrame(.horizontal)
                        .id(position)
                }
            }
            .scrollTargetLayout()
            // Kartın sert alt kenarı kesilmesin.
            .padding(.bottom, MP.E.widthLG + MPSpacing.xxs)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selection)
        .simultaneousGesture(DragGesture(minimumDistance: 8).onChanged { _ in userTookOver = true })
        // Kartlar aynı yükseklikte kalsın diye yazı büyümesi sınırlı.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func slideView(_ slide: ClassicHeaderSlide) -> some View {
        HStack(alignment: .center, spacing: MPSpacing.lg) {
            Button { onOpen(slide.tale) } label: {
                ClassicCoverTile(asset: slide.tale.cover, focus: slide.tale.coverFocus, seed: slide.tale.title,
                                 width: Self.coverWidth, height: Self.coverHeight)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                Button { onOpen(slide.tale) } label: {
                    VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                        Text(slide.eyebrow).mpText(.eyebrow).foregroundStyle(MPColor.actionPrimary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Text(slide.tale.title).mpText(.section).foregroundStyle(MPColor.textPrimary)
                            .lineLimit(3).minimumScaleFactor(0.7)
                            .multilineTextAlignment(.leading)
                        Text(slide.tale.fullMeta).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                            .lineLimit(2).minimumScaleFactor(0.7)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(slide.eyebrow): \(slide.tale.title). \(slide.tale.fullMeta)")
                .accessibilityHint("Masalın sayfasını açar")

                MPButton(title: slide.kind == .resume ? "Devam et" : "Oku",
                         systemImage: slide.kind == .resume ? "play.fill" : "book",
                         kind: .secondary, size: .small) { onRead(slide.tale) }
                    .accessibilityHint("\(slide.tale.title) masalını okuyucuda açar")
            }
        }
        .padding(MPSpacing.lg)
        .frame(height: Self.coverHeight + MP.E.widthLG + MPSpacing.lg * 2)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
    }

    // MARK: - Kendiliğinden geçiş

    private func advanceLater() async {
        guard !reduceMotion, !userTookOver, slides.count > 1 else { return }
        try? await Task.sleep(nanoseconds: Self.autoAdvance)
        guard !Task.isCancelled, !userTookOver else { return }
        let next = (selection ?? GunlukLoop.start(count: slides.count)) + 1
        withAnimation(MP.M.gated(MP.M.page)) { selection = next }
    }
}

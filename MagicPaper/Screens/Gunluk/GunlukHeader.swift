// GunlukHeader.swift
// Günlük'ün başlık vitrini: Ana sayfadaki sahne gibi ekranın tepesinden başlayan,
// kaydırılan boyalı kapaklar. Sıra `ClassicsCatalog.headerSlides`'ta.

import SwiftUI

/// Kaydırılan vitrin.
///
/// - Tepede "Masallar" ve arama düz krem zeminde, öbür sekmeler gibi; boyalı
///   sahne başlığın altından başlar (11 Kasım 2026: resmin tepesini kreme açan
///   beyaz geçiş kalktı, saat çubuğu ve başlık kâğıt üstünde okunur).
/// - Altta karartma, etiket, masalın adı, meta ve "Oku"; alt köşeler yuvarlak,
///   Ana sayfanın kartları gibi sert alt kenarlı.
/// - Kendiliğinden geçiş yavaş (7 sn) ve tek yönlü; kullanıcı kaydırınca durur,
///   Hareketi Azalt açıkken hiç başlamaz (sakin UX, tasarım yasası: hareket).
struct GunlukHeaderCarousel: View {
    let slides: [ClassicHeaderSlide]
    /// Saat çubuğunun yüksekliği: başlık onun altından başlar.
    var topInset: CGFloat = 0
    /// Saat çubuğunun altındaki görünen yükseklik: boyalı sahne olayı anlatacak
    /// kadar büyük (Batuhan, 14 Ekim: %45'e küçültülmüş hali görseli kesiyordu).
    var height: CGFloat = 520
    let onOpen: (ClassicTale) -> Void
    let onRead: (ClassicTale) -> Void
    let onSearch: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Döngüdeki konum (`GunlukLoop`): slayt `position % slides.count`.
    @State private var selection: Int?
    @State private var userTookOver = false


    /// En çok 400 pt (Faz 7; 14 Ekim'de 520): vitrin ilk ekranın tamamını
    /// kaplamasın, raf kapıları kıvrımın üstünde görünsün. SE'de ekranın %45'i.
    static func height(screen: CGFloat) -> CGFloat {
        min(400, (screen * 0.45).rounded())
    }

    private static let autoAdvance: UInt64 = 7_000_000_000

    private var current: Int {
        guard !slides.isEmpty else { return 0 }
        return (selection ?? 0) % slides.count
    }

    var body: some View {
        // Koyu alt kenar kreme erimez (gri bant olurdu): sahne alt köşeleri
        // yuvarlak, sert alt kenarlı bir sahne olarak biter. Sayfa noktaları
        // sahnenin içinde, resmin üstünde: vitrinden ayrı bir parça durmaz.
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            titleBar
            pager
                .overlay(alignment: .bottomTrailing) {
                    if slides.count > 1 {
                        MPPageDots(count: slides.count, current: current, onDark: true)
                            .padding(.trailing, MPSpacing.screenH)
                            .padding(.bottom, MPSpacing.xxl + MPSpacing.md)
                    }
                }
                .frame(height: artHeight)
                .gunlukStage()
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
            LazyHStack(spacing: 0) {
                ForEach(0..<GunlukLoop.length(count: slides.count), id: \.self) { position in
                    slideView(slides[position % slides.count])
                        .containerRelativeFrame(.horizontal)
                        .id(position)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $selection)
        .simultaneousGesture(DragGesture(minimumDistance: 8).onChanged { _ in userTookOver = true })
    }

    private func slideView(_ slide: ClassicHeaderSlide) -> some View {
        ZStack(alignment: .bottomLeading) {
            Button { onOpen(slide.tale) } label: {
                art(slide.tale)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(slide.eyebrow): \(slide.tale.title). \(slide.tale.fullMeta)")
            .accessibilityHint("Masalın sayfasını açar")

            // Karartma ve metin `MPArtHero`'dan; sahne arkadaki düğme, karartma
            // dokunuşu geçirir.
            MPArtHero(height: artHeight) {
                Color.clear
            } content: {
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text(slide.eyebrow).mpText(.eyebrow).foregroundStyle(MP.C.textOnArtMuted)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(slide.tale.title).mpText(.cover).foregroundStyle(MP.C.textOnArt)
                        .lineLimit(3).minimumScaleFactor(0.6)
                    Text(slide.tale.fullMeta).mpText(.supporting).foregroundStyle(MP.C.textOnArtMuted)
                        .lineLimit(2).minimumScaleFactor(0.7)
                    MPButton(title: slide.kind == .resume ? "Devam et" : "Masalı oku",
                             systemImage: slide.kind == .resume ? "play.fill" : "book",
                             kind: .secondary, size: .small) { onRead(slide.tale) }
                        .padding(.top, MPSpacing.sm)
                        .accessibilityHint("\(slide.tale.title) masalını okuyucuda açar")
                }
                .frame(maxHeight: artHeight, alignment: .bottom)
            }
            // Sahne sabit yükseklikte: en büyük yazı boyutlarında metin başlığın
            // üstüne binmesin diye büyüme sınırlı, sığmazsa küçülür (alt bar gibi).
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .frame(height: artHeight)
    }

    /// Başlık satırının ("Masallar" ve arama) kapladığı yer: sahne bu kadar
    /// kısalır, vitrinin toplam yüksekliği ve kıvrım değişmez.
    private static let titleBarClearance: CGFloat = MPSize.minTouchKid + MPSpacing.xxl

    private var artHeight: CGFloat { height - Self.titleBarClearance }

    /// Boyalı kapak, soluklaşmadan; altın karartması metinle birlikte
    /// `MPArtHero`'dan gelir.
    private func art(_ tale: ClassicTale) -> some View {
        ClassicCoverImage(asset: tale.cover, focus: tale.coverFocus, seed: tale.title, onStage: true)
            .frame(height: artHeight)
            .frame(maxWidth: .infinity)
            .clipped()
            .accessibilityHidden(true)
    }

    // MARK: - Başlık

    private var titleBar: some View {
        MPKidTabHeader(title: "Masallar") {
            MPCircleButton(systemImage: "magnifyingglass", accessibilityLabel: "Masal ara", action: onSearch)
        }
        // Başlık sahnenin üstünde sabit bir yer kaplar; satır büyümesin.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, topInset + MPSpacing.lg)
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

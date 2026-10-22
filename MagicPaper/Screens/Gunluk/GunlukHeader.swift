// GunlukHeader.swift
// Günlük'ün başlık vitrini: Ana sayfadaki sahne gibi ekranın tepesinden başlayan,
// kaydırılan boyalı kapaklar. Sıra `ClassicsCatalog.headerSlides`'ta.

import SwiftUI

/// Kaydırılan vitrin.
///
/// - Tepede "Günlük" ve arama; resmin üstü kreme açılır ki yazı ve saat çubuğu
///   okunsun (Ana sayfanın açık gökyüzü üstünde koyu başlık dili).
/// - Altta karartma, etiket, masalın adı, meta ve "Oku"; alt köşeler yuvarlak,
///   Ana sayfanın kartları gibi sert alt kenarlı.
/// - Kendiliğinden geçiş yavaş (7 sn) ve tek yönlü; kullanıcı kaydırınca durur,
///   Hareketi Azalt açıkken hiç başlamaz (sakin UX, tasarım yasası: hareket).
struct GunlukHeaderCarousel: View {
    let slides: [ClassicHeaderSlide]
    /// Saat çubuğunun yüksekliği: vitrin onun altına taşar, başlık altında kalır.
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


    /// Büyük telefonlarda 520 pt (Batuhan, 14 Ekim); küçük ekranda (iPhone SE)
    /// ekranın %60'ı, ki altındaki çipler ve ilk raf da görünsün.
    static func height(screen: CGFloat) -> CGFloat {
        min(520, (screen * 0.6).rounded())
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
        ZStack(alignment: .top) {
            pager
            titleBar
        }
        .overlay(alignment: .bottomTrailing) {
            if slides.count > 1 {
                MPPageDots(count: slides.count, current: current, onDark: true)
                    .padding(.trailing, MPSpacing.screenH)
                    .padding(.bottom, MPSpacing.xxl + MPSpacing.md)
            }
        }
        .frame(height: height + topInset)
        .gunlukStage()
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
            MPArtHero(height: height + topInset) {
                Color.clear
            } content: {
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text(slide.eyebrow).mpText(.eyebrow).foregroundStyle(MP.C.textOnArtMuted)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(slide.tale.title).mpText(.heroTitle).foregroundStyle(MP.C.textOnArt)
                        .lineLimit(3).minimumScaleFactor(0.6)
                    Text(slide.tale.fullMeta).mpText(.callout).foregroundStyle(MP.C.textOnArtMuted)
                        .lineLimit(2).minimumScaleFactor(0.7)
                    MPButton(title: slide.kind == .resume ? "Devam et" : "Masalı oku",
                             systemImage: slide.kind == .resume ? "play.fill" : "book",
                             kind: .secondary, size: .small) { onRead(slide.tale) }
                        .padding(.top, MPSpacing.sm)
                        .accessibilityHint("\(slide.tale.title) masalını okuyucuda açar")
                }
                .frame(maxHeight: height - Self.titleBarClearance, alignment: .bottom)
            }
            // Sahne sabit yükseklikte: en büyük yazı boyutlarında metin başlığın
            // üstüne binmesin diye büyüme sınırlı, sığmazsa küçülür (alt bar gibi).
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .frame(height: height + topInset)
    }

    /// Başlık satırının ("Günlük" ve arama) sahnede kapladığı yer.
    private static let titleBarClearance: CGFloat = MPSize.minTouchKid + MPSpacing.xxl

    /// Boyalı kapak: tepesi kreme açılır (başlık); altın karartması metinle
    /// birlikte `MPArtHero`'dan gelir.
    private func art(_ tale: ClassicTale) -> some View {
        ClassicCoverImage(asset: tale.cover, focus: tale.coverFocus, seed: tale.title, onStage: true)
            .frame(height: height + topInset)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                // Yalnızca saat çubuğu ve "Günlük" yazısının arkası açılır; resmin
                // geri kalanı olduğu gibi, soluklaşmadan görünür.
                LinearGradient(stops: [.init(color: MPColor.backgroundKid.opacity(0.8), location: 0),
                                       .init(color: MPColor.backgroundKid.opacity(0.55), location: 0.55),
                                       .init(color: MPColor.backgroundKid.opacity(0), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: topInset + MPSize.minTouchKid + MPSpacing.lg)
            }
            .clipped()
            .accessibilityHidden(true)
    }

    // MARK: - Başlık

    private var titleBar: some View {
        HStack(alignment: .center) {
            Text("Günlük").mpText(.pageTitle).foregroundStyle(MPColor.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.6)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: MPSpacing.sm)
            Button(action: onSearch) {
                MPIcon("magnifyingglass", size: MP.G.md, weight: .semibold)
                    .foregroundStyle(MPColor.textPrimary)
                    .frame(width: MPSize.circleButton, height: MPSize.circleButton)
                    .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge,
                                  radius: MPSize.circleButton / 2)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel("Masal ara")
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, topInset + MPSpacing.sm)
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

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
    /// Saat çubuğunun altındaki görünen yükseklik (`GunlukHeaderCarousel.height(screen:topInset:)`).
    var height: CGFloat = 330
    let onOpen: (ClassicTale) -> Void
    let onRead: (ClassicTale) -> Void
    let onSearch: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: String?
    @State private var userTookOver = false


    /// Vitrin saat çubuğu dahil ekranın %45'i (Ana sayfanın sahnesi ~%40): ilk
    /// bakışta vitrin, çipler ve ilk kartın üstü birlikte görünür. Küçük ve
    /// büyük ekranda 340–420 pt arasında kalır.
    static func height(screen: CGFloat, topInset: CGFloat) -> CGFloat {
        min(max(screen * 0.45, 340), 420) - topInset
    }
    private static let autoAdvance: UInt64 = 7_000_000_000

    private var current: Int {
        slides.firstIndex { $0.id == selection } ?? 0
    }

    var body: some View {
        VStack(spacing: MPSpacing.md) {
            // Koyu alt kenar kreme erimez (gri bant olurdu): sahne alt köşeleri
            // yuvarlak, sert alt kenarlı bir sahne olarak biter.
            ZStack(alignment: .top) {
                pager
                titleBar
            }
            .frame(height: height + topInset)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: MPRadius.hero, bottomTrailingRadius: MPRadius.hero,
                                              style: .continuous))
            .background(alignment: .bottom) {
                UnevenRoundedRectangle(bottomLeadingRadius: MPRadius.hero, bottomTrailingRadius: MPRadius.hero,
                                       style: .continuous)
                    .fill(MPColor.brandNight)
                    .frame(height: MPRadius.hero * 2)
                    .offset(y: MP.E.widthLG)
            }

            if slides.count > 1 {
                MPPageDots(count: slides.count, current: current)
            }
        }
        .task(id: selection) { await advanceLater() }
        .onAppear { if selection == nil { selection = slides.first?.id } }
    }

    // MARK: - Sayfalar

    private var pager: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(slides) { slide in
                    slideView(slide)
                        .containerRelativeFrame(.horizontal)
                        .id(slide.id)
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

            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text(slide.eyebrow).mpText(.eyebrow).foregroundStyle(MP.C.textOnArtMuted)
                Text(slide.tale.title).mpText(.title1).foregroundStyle(MP.C.textOnArt)
                    .fixedSize(horizontal: false, vertical: true)
                Text(slide.tale.fullMeta).mpText(.callout).foregroundStyle(MP.C.textOnArtMuted)
                MPButton(title: slide.kind == .resume ? "Devam et" : "Masalı oku",
                         systemImage: slide.kind == .resume ? "play.fill" : "book",
                         kind: .secondary, size: .small) { onRead(slide.tale) }
                    .padding(.top, MPSpacing.sm)
                    .accessibilityHint("\(slide.tale.title) masalını okuyucuda açar")
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xl)
        }
        .frame(height: height + topInset)
    }

    /// Boyalı kapak: tepesi kreme açılır (başlık), altı karartılır (metin),
    /// en alt kenarı sayfanın kremine erir (Ana sayfa sahnesi gibi).
    private func art(_ tale: ClassicTale) -> some View {
        ClassicCoverImage(asset: tale.cover, focus: tale.coverFocus, seed: tale.title)
            .frame(height: height + topInset)
            .frame(maxWidth: .infinity)
            .overlay {
                LinearGradient(stops: [.init(color: MP.Scrim.ink.opacity(0), location: 0.45),
                                       .init(color: MP.Scrim.solid, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .overlay(alignment: .top) {
                LinearGradient(colors: [MPColor.backgroundKid.opacity(0.92), MPColor.backgroundKid.opacity(0)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: topInset + 120)
            }
            .clipped()
            .accessibilityHidden(true)
    }

    // MARK: - Başlık

    private var titleBar: some View {
        HStack(alignment: .center) {
            Text("Günlük").mpText(.pageTitle).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: MPSpacing.sm)
            MPCircleButton(systemImage: "magnifyingglass", accessibilityLabel: "Masal ara",
                           bordered: false, fill: MPColor.backgroundSurface, action: onSearch)
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, topInset + MPSpacing.sm)
    }

    // MARK: - Kendiliğinden geçiş

    private func advanceLater() async {
        guard !reduceMotion, !userTookOver, slides.count > 1 else { return }
        try? await Task.sleep(nanoseconds: Self.autoAdvance)
        guard !Task.isCancelled, !userTookOver else { return }
        let next = slides[(current + 1) % slides.count].id
        withAnimation(MP.M.gated(MP.M.page)) { selection = next }
    }
}

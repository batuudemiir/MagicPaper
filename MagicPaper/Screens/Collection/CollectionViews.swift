import SwiftUI

/// Bir masalın çıkartması: yuvarlak kâğıt, kalın beyaz kenar, kapağın sanatı.
/// Hafif eğik durur; eğim masalın kimliğinden gelir, her açılışta aynı.
struct StickerView: View {
    let sticker: MPSticker
    var size: CGFloat = 104

    private var tilt: Double {
        let seed = sticker.id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return Double(seed % 13) - 6
    }

    var body: some View {
        MPBookCover(art: sticker.art, width: size)
            .frame(width: size, height: size, alignment: .top)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(MPColor.backgroundSurface, lineWidth: size * 0.07))
            .mpShadow(MP.Sh.card)
            .rotationEffect(.degrees(tilt))
            .accessibilityHidden(true)
    }
}

// MARK: - Odam → Çıkartma albümüm

/// Biten her masal buraya bir çıkartma bırakır (Faz 9). Eksik sayısı, "hepsini
/// topla" yok; son hücre kesikli: sıradaki masal.
struct StickerAlbumView: View {
    let profile: UserProfile

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var classics = ClassicProgressStore.shared
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var opened: MPSticker?

    private var stickers: [MPSticker] {
        MPStickerAlbum.stickers(for: profile, stories: storyManager.stories, classics: classics.entries)
    }

    var body: some View {
        let all = stickers
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                MPTopBar(title: "Çıkartma albümüm",
                         subtitle: all.isEmpty ? nil : "\(all.count) çıkartma",
                         onBack: { app.router.closeKidPage() }) { EmptyView() }

                if all.isEmpty {
                    MPStateView(mascot: .reading, title: "Albümün henüz boş",
                                message: "İlk masalı bitirince ilk çıkartman gelir.") {
                        MPButton(title: "Masal yaz", systemImage: "wand.and.sparkles") { app.startStoryCreation() }
                    }
                } else {
                    MascotSays(mascot: .happy, text: "Her bitirdiğin masal buraya bir çıkartma bırakır.", mascotWidth: 64)
                    ForEach(Array(MPStickerAlbum.byMonth(all).enumerated()), id: \.offset) { index, group in
                        VStack(alignment: .leading, spacing: MPSpacing.lg) {
                            MPSectionHeader(title: group.title)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md),
                                                     count: typeSize.isAccessibilitySize ? 2 : 3),
                                      spacing: MPSpacing.xl) {
                                ForEach(group.stickers) { sticker in
                                    Button { MPHaptics.tap(); opened = sticker } label: { cell(sticker) }
                                        .buttonStyle(MPPressStyle())
                                        .accessibilityLabel("\(sticker.title) çıkartması")
                                }
                                if index == 0 { nextSlot }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.lg)
            .padding(.bottom, GunlukLayout.bottomClearance)
        }
        .background(MPColor.backgroundSurface.ignoresSafeArea())
        .sheet(item: $opened) { sticker in
            StickerSheet(sticker: sticker, onClose: { opened = nil })
        }
    }

    private func cell(_ sticker: MPSticker) -> some View {
        VStack(spacing: MPSpacing.xs) {
            StickerView(sticker: sticker, size: 96)
            Text(sticker.title).mpText(.footnote).foregroundStyle(MPColor.textPrimary)
                .lineLimit(2).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero)
    }

    /// Sıradaki masalın yeri: sayı söylemez, yalnızca davet eder.
    private var nextSlot: some View {
        VStack(spacing: MPSpacing.xs) {
            Circle()
                .strokeBorder(MPColor.borderDashed, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                .frame(width: 96, height: 96)
            Text("Sıradaki masal").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

/// Çıkartmaya dokununca: büyük çıkartma, ad ve tarih.
private struct StickerSheet: View {
    let sticker: MPSticker
    let onClose: () -> Void

    var body: some View {
        MPSheet(title: sticker.title, onClose: onClose) {
            VStack(spacing: MPSpacing.lg) {
                StickerView(sticker: sticker, size: 180)
                Text(sticker.date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "tr_TR"))))
                    .mpText(.supporting).foregroundStyle(MPColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MPSpacing.lg)
        }
        .mpSheet(.half)
    }
}

// MARK: - Odam → Süsler

/// Yıldızla alınan süsler (Faz 9). Her şey fiyatıyla görünür; yetmeyen süsün de
/// önizlemesi serbest, yalnızca "kaç yıldız gerekiyor" yazar. Geri sayım,
/// "az kaldı", parayla yıldız yok. Alınan süs kaybolmaz.
struct DecorShopView: View {
    let profile: UserProfile

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var settings = MPSettingsStore.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @State private var wallet = MPStarWallet()
    @State private var selected: MPDecor = .defaultShelf

    private var earned: Int { MPStars.count(for: profile, stories: storyManager.stories) }
    private var balance: Int { wallet.balance(earned: earned) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                    MPTopBar(title: "Süsler", onBack: { app.router.closeKidPage() }) {
                        HStack(spacing: MPSpacing.xxs) {
                            MPStarMark(size: 18).accessibilityHidden(true)
                            Text("\(balance)").mpText(.cardTitle).monospacedDigit()
                        }
                        .foregroundStyle(MPColor.textPrimary)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(balance) yıldızın var")
                    }

                    VStack(alignment: .leading, spacing: MPSpacing.sm) {
                        Text("Kitaplığının rafı").mpText(.section).foregroundStyle(MPColor.textPrimary)
                        ShelfPreview(tone: selected.tone)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md), count: 3),
                              spacing: MPSpacing.md) {
                        ForEach(MPDecor.catalog) { item in
                            Button { MPHaptics.selection(); selected = item } label: { tile(item) }
                                .buttonStyle(MPPressStyle())
                                .accessibilityLabel(accessibility(item))
                                .accessibilityAddTraits(item == selected ? .isSelected : [])
                        }
                    }

                    Text("Yıldızlar yalnızca okuyarak kazanılır: her sabah 1, her masal 1. Aldığın süs hep senin.")
                        .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.top, MPSpacing.lg)
                .padding(.bottom, MPSpacing.xl)
            }
            footer
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.bottom, GunlukLayout.bottomClearance)
        }
        .background(MPColor.backgroundSurface.ignoresSafeArea())
        .onAppear {
            wallet = MPStarWalletStore().wallet(for: profile.id)
            selected = wallet.equippedItem(.shelf)
        }
    }

    private func tile(_ item: MPDecor) -> some View {
        let owned = wallet.owns(item)
        let isOn = wallet.equippedItem(.shelf) == item
        return VStack(spacing: MPSpacing.xs) {
            RoundedRectangle(cornerRadius: MPRadius.xs, style: .continuous)
                .fill(item.tone.soft)
                .frame(height: MP.S.x5)
                .mpKidSurface(item.tone.soft, edge: item.tone.edge, radius: MPRadius.xs)
            Text(item.title).mpText(.supporting).foregroundStyle(MPColor.textPrimary)
            Text(isOn ? "Kullanılıyor" : owned ? "Senin" : "★ \(item.price(easy: settings.easyPrices))")
                .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
        }
        .padding(MPSpacing.md)
        .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero)
        .background(item == selected ? MPColor.cardSoft : MPColor.backgroundSurface,
                    in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
            .strokeBorder(item == selected ? MPColor.actionPrimary : MPColor.borderKid, lineWidth: item == selected ? 2 : 1))
    }

    @ViewBuilder
    private var footer: some View {
        let owned = wallet.owns(selected)
        let price = selected.price(easy: settings.easyPrices)
        if wallet.equippedItem(.shelf) == selected {
            Text("Rafın bu renkte.").mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero)
        } else if owned {
            MPButton(title: "Kullan", size: .hero, fullWidth: true) { equip() }
        } else if balance >= price {
            MPButton(title: "★ \(price) · Al", size: .hero, fullWidth: true) { buy() }
        } else {
            Text("★ \(price) gerekiyor, \(balance) yıldızın var.")
                .mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero)
        }
    }

    private func buy() {
        guard case .bought = wallet.buy(selected, earned: earned, easyPrices: settings.easyPrices) else { return }
        wallet.equip(selected)
        MPStarWalletStore().save(wallet, for: profile.id)
        MPHaptics.success()
        MPSound.play(.earned)
        app.showToast("\(selected.title) raf senin", symbol: "star.fill")
    }

    private func equip() {
        wallet.equip(selected)
        MPStarWalletStore().save(wallet, for: profile.id)
        MPHaptics.tap()
    }

    private func accessibility(_ item: MPDecor) -> String {
        if wallet.equippedItem(.shelf) == item { return "\(item.title) raf, kullanılıyor" }
        if wallet.owns(item) { return "\(item.title) raf, senin" }
        return "\(item.title) raf, \(item.price(easy: settings.easyPrices)) yıldız"
    }
}

/// Süs önizlemesi: iki kapak ve altında raf.
private struct ShelfPreview: View {
    let tone: MPWorldTone

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: MPSpacing.md) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous)
                        .fill([MPWorldTone.lav, .sky, .mint][i].soft)
                        .frame(width: 64, height: 88)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, MPSpacing.sm)
            ShelfPlank(tone: tone)
        }
        .accessibilityHidden(true)
    }
}

import SwiftUI

/// Odam → Dolap (Faz 9): çocuk kahramanını giydirir. Üstte canlı önizleme, altında
/// sekmeler: Ben (tür, ten ya da kürk, saç, yüz), Kıyafet, Şapka, Gözlük. Her
/// seçenek kahramanın o parçayla küçük bir resmi: okuyamayan çocuk da seçer.
///
/// Kimlik (Ben) ebeveyn kapısıyla kaydedilir; kozmetik serbest, bir kısmı yıldızla.
/// Yetmeyen eşya önizlenir, yalnızca "kaç yıldız gerekiyor" yazar. Geri sayım,
/// "az kaldı", parayla yıldız yok; alınan eşya kaybolmaz.
struct HeroWardrobeView: View {
    let profile: UserProfile

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var settings = MPSettingsStore.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @Environment(\.dynamicTypeSize) private var typeSize

    enum Tab: String, CaseIterable, Identifiable {
        case me, top, hat, glasses
        var id: String { rawValue }
        var title: String {
            switch self {
            case .me: "Ben"
            case .top: "Kıyafet"
            case .hat: "Şapka"
            case .glasses: "Gözlük"
            }
        }
    }

    @State private var tab: Tab = .top
    @State private var look = HeroLook.standard
    @State private var saved = HeroLook.standard
    @State private var wallet = MPStarWallet()

    private var earned: Int { MPStars.count(for: profile, stories: storyManager.stories) }
    private var balance: Int { wallet.balance(earned: earned) }
    private var unpaid: (items: [HeroShop.Item], total: Int) {
        HeroShop.unpaid(in: look, wallet: wallet, easyPrices: settings.easyPrices)
    }

    var body: some View {
        VStack(spacing: 0) {
            MPTopBar(title: "Dolap", onBack: { app.router.closeKidPage() }) { starPill }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.top, MPSpacing.lg)

            HeroAvatarView(look: look, backdrop: MPWorldTone.lav.soft)
                .frame(height: typeSize.isAccessibilitySize ? 140 : 200)
                .padding(.vertical, MPSpacing.md)
                .animation(MP.M.gated(MP.M.base), value: look)

            MPSegmented(options: Tab.allCases.map { ($0, $0.title) }, selection: $tab)
                .padding(.horizontal, MPSpacing.screenH)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.xl) { content }
                    .padding(.horizontal, MPSpacing.screenH)
                    .padding(.vertical, MPSpacing.lg)
            }

            footer
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.bottom, GunlukLayout.bottomClearance)
        }
        .background(MPColor.backgroundSurface.ignoresSafeArea())
        .onAppear {
            let stored = HeroLookStore().look(for: profile.id) ?? .standard
            look = stored
            saved = stored
            wallet = MPStarWalletStore().wallet(for: profile.id)
        }
    }

    private var starPill: some View {
        HStack(spacing: MPSpacing.xxs) {
            MPStarMark(size: 18).accessibilityHidden(true)
            Text("\(balance)").mpText(.cardTitle).monospacedDigit()
        }
        .foregroundStyle(MPColor.textPrimary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(balance) yıldızın var")
    }

    // MARK: Sekmeler

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .me:
            group("Ben") {
                grid(HeroLook.Kind.allCases, title: \.title, isOn: { look.kind == $0 }) { look.kind = $0 } preview: { var l = look; l.kind = $0; return l }
            }
            if look.kind == .child {
                group("Ten") { swatches(MP.C.heroSkin, selected: look.skin) { look.skin = $0 } }
                group("Saç") {
                    grid(HeroLook.Hair.allCases, title: \.title, isOn: { look.hair == $0 }) { look.hair = $0 } preview: { var l = look; l.hair = $0; l.headwear = .none; return l }
                }
                group("Saç rengi") { swatches(MP.C.heroHair, selected: look.hairColor) { look.hairColor = $0 } }
            } else {
                group("Kürk") { swatches(MP.C.heroFur, selected: look.fur) { look.fur = $0 } }
            }
            group("Gözler") {
                grid(HeroLook.Eyes.allCases, title: \.title, isOn: { look.eyes == $0 }) { look.eyes = $0 } preview: { var l = look; l.eyes = $0; return l }
            }
            group("Ağız") {
                grid(HeroLook.Mouth.allCases, title: \.title, isOn: { look.mouth == $0 }) { look.mouth = $0 } preview: { var l = look; l.mouth = $0; return l }
            }
            if look.kind == .child {
                MPChip(title: look.freckles ? "Çiller var" : "Çil ekle", systemImage: "sparkles",
                       isSelected: look.freckles, height: MPSize.chipHeightKid) { look.freckles.toggle() }
            }
            Text("Kahramanını değiştirmek için bir büyük kaydeder.")
                .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
        case .top:
            group("Kıyafet") {
                grid(available(HeroLook.Top.allCases, HeroShop.price), title: \.title, isOn: { look.top == $0 },
                     price: { HeroShop.price($0) }, owned: { wallet.owns(itemID: "hero.top.\($0.rawValue)") }) { look.top = $0 } preview: { var l = look; l.top = $0; return l }
            }
            group("Renk") { swatches(MP.C.heroCloth, selected: look.topColor) { look.topColor = $0 } }
        case .hat:
            group("Şapka") {
                grid(available(HeroLook.Headwear.allCases, HeroShop.price), title: \.title, isOn: { look.headwear == $0 },
                     price: { HeroShop.price($0) }, owned: { wallet.owns(itemID: "hero.headwear.\($0.rawValue)") }) { look.headwear = $0 } preview: { var l = look; l.headwear = $0; return l }
            }
            group("Renk") { swatches(MP.C.heroCloth, selected: look.headwearColor) { look.headwearColor = $0 } }
        case .glasses:
            group("Gözlük") {
                grid(available(HeroLook.Glasses.allCases, HeroShop.price), title: \.title, isOn: { look.glasses == $0 },
                     price: { HeroShop.price($0) }, owned: { wallet.owns(itemID: "hero.glasses.\($0.rawValue)") }) { look.glasses = $0 } preview: { var l = look; l.glasses = $0; return l }
            }
        }
    }

    /// Ebeveyn yıldızla süsü kapattıysa yalnızca ücretsizler görünür.
    private func available<T>(_ all: [T], _ price: (T) -> Int) -> [T] {
        settings.collectionEnabled ? all : all.filter { price($0) == 0 }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text(title).mpText(.section).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func grid<T: Hashable>(_ options: [T], title: KeyPath<T, String>, isOn: @escaping (T) -> Bool,
                                   price: @escaping (T) -> Int = { _ in 0 }, owned: @escaping (T) -> Bool = { _ in true },
                                   choose: @escaping (T) -> Void, preview: @escaping (T) -> HeroLook) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.sm),
                                 count: typeSize.isAccessibilitySize ? 2 : 3), spacing: MPSpacing.sm) {
            ForEach(options, id: \.self) { option in
                let selected = isOn(option)
                let cost = price(option)
                let mine = cost == 0 || owned(option)
                Button { MPHaptics.selection(); choose(option) } label: {
                    VStack(spacing: MP.S.x1) {
                        HeroAvatarView(look: preview(option)).frame(height: 76)
                        Text(option[keyPath: title]).mpText(.footnote).foregroundStyle(MPColor.textPrimary)
                            .lineLimit(2).multilineTextAlignment(.center)
                        if !mine {
                            Text("★ \(MPDecor.easy(cost, settings.easyPrices))").mpText(.footnote)
                                .foregroundStyle(MPColor.textSecondary)
                        }
                    }
                    .padding(MPSpacing.sm)
                    .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero)
                    .background(selected ? MPColor.cardSoft : MPColor.backgroundSurface,
                                in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
                        .strokeBorder(selected ? MPColor.actionPrimary : MPColor.borderKid, lineWidth: selected ? 2 : 1))
                }
                .buttonStyle(MPPressStyle())
                .accessibilityLabel(option[keyPath: title] + (mine ? "" : ", \(MPDecor.easy(cost, settings.easyPrices)) yıldız"))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func swatches(_ colors: [Color], selected: Int, choose: @escaping (Int) -> Void) -> some View {
        MPFlowLayout(spacing: MPSpacing.sm) {
            ForEach(colors.indices, id: \.self) { i in
                Button { MPHaptics.selection(); choose(i) } label: {
                    Circle().fill(colors[i])
                        .frame(width: 40, height: 40)
                        .padding(MP.S.x1)
                        .overlay(Circle().strokeBorder(i == selected ? MPColor.actionPrimary : .clear, lineWidth: 3))
                        .frame(minWidth: MP.S.tapMin, minHeight: MP.S.tapMin)
                }
                .buttonStyle(MPPressStyle())
                .accessibilityLabel("Renk \(i + 1)")
                .accessibilityAddTraits(i == selected ? .isSelected : [])
            }
        }
    }

    // MARK: Alt

    @ViewBuilder
    private var footer: some View {
        let due = unpaid
        if look == saved {
            Text("Kahramanın hazır.").mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero)
        } else if due.total > 0 && balance < due.total {
            Text("★ \(due.total) gerekiyor, \(balance) yıldızın var.")
                .mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero)
        } else {
            MPButton(title: due.total > 0 ? "★ \(due.total) · Al ve giy" : "Kaydet", size: .hero, fullWidth: true, action: save)
        }
    }

    private func save() {
        let commit = {
            let due = unpaid
            if due.total > 0 {
                guard case .bought = wallet.buy(itemIDs: due.items.map(\.id), total: due.total, earned: earned) else { return }
                MPStarWalletStore().save(wallet, for: profile.id)
                MPSound.play(.earned)
            }
            HeroLookStore().save(look, for: profile.id)
            saved = look
            MPHaptics.success()
            app.showToast("Kahramanın hazır", symbol: "sparkles")
        }
        // Kimlik değiştiyse bir büyük onaylar; kozmetik doğrudan.
        if HeroShop.identityChanged(from: saved, to: look) {
            app.router.requestGate(then: commit)
        } else {
            commit()
        }
    }
}

/// Odam'ın kahraman kartı: kahraman büyük, dokununca Dolap.
struct HeroStageCard: View {
    let look: HeroLook?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.lg) {
                HeroAvatarView(look: look ?? .standard, backdrop: MPWorldTone.lav.soft)
                    .frame(width: 120, height: 132)
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text("Kahramanım").mpText(.section).foregroundStyle(MPColor.textPrimary)
                    Text(look == nil ? "Kahramanını giydirelim mi?" : "Dolabı aç, yeni bir şey dene.")
                        .mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: MPSpacing.xxs) {
                        MPIcon("sparkles", size: MP.G.sm, weight: .bold)
                        Text("Dolap").mpText(.button)
                    }
                    .foregroundStyle(MPColor.actionPrimary)
                    .padding(.top, MP.S.x1)
                }
                Spacer(minLength: 0)
            }
            .padding(MPSpacing.md)
            .frame(minHeight: MPSize.minTouchHero)
            .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Kahramanım, dolabı aç")
    }
}

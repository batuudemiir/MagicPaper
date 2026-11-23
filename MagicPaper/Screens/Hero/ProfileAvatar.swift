import SwiftUI

/// Profil avatarı (23 Kasım 2026, İrem): çocuk profil resmini Ragi'nin
/// pozlarından ya da masal arkadaşlarının yüzlerinden seçer. Yalnızca yüz,
/// beden yok; renkli zeminli kare karo. Görseller `Assets.xcassets/Avatars`
/// (Ragi'nin `Brand/mascot*` pozlarından ve karakter sayfalarından kırpıldı).
///
/// Tarçın: Batuhan'ın masal görsellerindeki tilki (`whole-book-art`).
/// Kestane: Batuhan'ın karakter denemesi (`2026-11-18-character-comparison`);
/// kendi notunda "nihai çizim değil".
struct ProfileAvatar: Identifiable, Hashable {
    let id: String
    let name: String
    let character: Character
    let tone: MPWorldTone

    var asset: String { "Avatars/\(id)" }

    enum Character: String, CaseIterable, Identifiable {
        case ragi, tarcin, kestane
        var id: String { rawValue }
        var title: String {
            switch self {
            case .ragi: "Ragi"
            case .tarcin: "Tarçın"
            case .kestane: "Kestane"
            }
        }
    }

    static let all: [ProfileAvatar] = [
        .init(id: "ragi-happy", name: "Neşeli Ragi", character: .ragi, tone: .yellow),
        .init(id: "ragi-calm", name: "Sakin Ragi", character: .ragi, tone: .lav),
        .init(id: "ragi-waving", name: "El sallayan Ragi", character: .ragi, tone: .mint),
        .init(id: "ragi-curious", name: "Meraklı Ragi", character: .ragi, tone: .sky),
        .init(id: "ragi-reading", name: "Okuyan Ragi", character: .ragi, tone: .pink),
        .init(id: "ragi-surprised", name: "Şaşıran Ragi", character: .ragi, tone: .peach),
        .init(id: "ragi-front", name: "Gülümseyen Ragi", character: .ragi, tone: .green),
        .init(id: "ragi-onbook", name: "Kitapçı Ragi", character: .ragi, tone: .yellow),
        .init(id: "ragi-pencil", name: "Yazan Ragi", character: .ragi, tone: .lav),
        .init(id: "ragi-thinking", name: "Düşünen Ragi", character: .ragi, tone: .mint),
        .init(id: "ragi-peek", name: "Saklanan Ragi", character: .ragi, tone: .sky),
        .init(id: "ragi-threequarter", name: "Yandan Ragi", character: .ragi, tone: .pink),
        .init(id: "ragi-walking", name: "Yürüyen Ragi", character: .ragi, tone: .peach),
        .init(id: "ragi-sleepy", name: "Uykulu Ragi", character: .ragi, tone: .green),
        .init(id: "ragi-sleeping", name: "Uyuyan Ragi", character: .ragi, tone: .lav),
        .init(id: "tarcin-standing", name: "Tarçın", character: .tarcin, tone: .mint),
        .init(id: "tarcin-sitting", name: "Bakan Tarçın", character: .tarcin, tone: .sky),
        .init(id: "tarcin-resting", name: "Mutlu Tarçın", character: .tarcin, tone: .lav),
        .init(id: "kestane-neutral", name: "Kestane", character: .kestane, tone: .yellow),
        .init(id: "kestane-looking", name: "Merak eden Kestane", character: .kestane, tone: .mint),
        .init(id: "kestane-waiting", name: "Bekleyen Kestane", character: .kestane, tone: .pink)
    ]

    static func named(_ id: String?) -> ProfileAvatar? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }

    static func of(_ character: Character) -> [ProfileAvatar] { all.filter { $0.character == character } }
}

/// Avatarın yüzü: renkli zeminde kırpılmış resim. Süs; etiketi çağırandan.
struct ProfileAvatarFace: View {
    let avatar: ProfileAvatar
    var circle: Bool = false

    var body: some View {
        Image(avatar.asset)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .background(avatar.tone.soft)
            .clipShape(circle ? AnyShape(Circle())
                              : AnyShape(RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous)))
            .accessibilityHidden(true)
    }
}

// MARK: - Profilini düzenle

/// Profildeki kimlik kartına dokununca zıplayarak açılan pencere (İrem'in
/// tasarım kararı, 23 Kasım 2026; oyunlardaki "Profili düzenle" dili). Üstte
/// seçili yüz ve ad, altında karakter sekmeleri ve yüz karoları, tek mor
/// "Kaydet". Karartmaya ya da X'e dokununca kapanır. Hareketi Azalt açıkken
/// zıplama yok, yalnızca solma.
struct ProfileAvatarPicker: View {
    let profile: UserProfile
    let onClose: () -> Void

    @EnvironmentObject private var app: MPAppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var shown = false
    @State private var character: ProfileAvatar.Character = .ragi
    @State private var selected: ProfileAvatar?
    @State private var saved: ProfileAvatar?
    /// Son seçilen karo kısa bir zıplama yapar.
    @State private var bumped: String?

    var body: some View {
        ZStack {
            MP.C.scrim
                .ignoresSafeArea()
                .opacity(shown ? 1 : 0)
                .onTapGesture(perform: close)
                .accessibilityHidden(true)

            panel
                .padding(.horizontal, MPSpacing.lg)
                .scaleEffect(shown || reduceMotion ? 1 : 0.6)
                .opacity(shown ? 1 : 0)
        }
        .onAppear {
            let look = HeroLookStore().look(for: profile.id)
            let current = ProfileAvatar.named(look?.avatar)
            selected = current
            saved = current
            character = current?.character ?? .ragi
            withAnimation(reduceMotion ? MP.M.easeOut : MP.M.spring) { shown = true }
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            HStack {
                Text("Profilini düzenle").mpText(.section).foregroundStyle(MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: MPSpacing.sm)
                MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat", action: close)
            }

            HStack(spacing: MPSpacing.lg) {
                Group {
                    if let selected {
                        ProfileAvatarFace(avatar: selected)
                    } else {
                        HeroAvatarView(look: HeroLookStore().look(for: profile.id) ?? .standard,
                                       backdrop: MPWorldTone.lav.soft)
                    }
                }
                .frame(width: MPSize.minTouchHero * 1.4, height: MPSize.minTouchHero * 1.4)
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text(profile.name).mpText(.page).foregroundStyle(MPColor.textPrimary)
                        .lineLimit(2).minimumScaleFactor(0.7)
                    Text(selected?.name ?? "Bir yüz seç").mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)

            characterTabs

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.sm),
                                         count: typeSize.isAccessibilitySize ? 2 : 3),
                          spacing: MPSpacing.sm) {
                    ForEach(ProfileAvatar.of(character)) { avatar in tile(avatar) }
                }
                .padding(MPSpacing.xxs)
            }
            .frame(maxHeight: typeSize.isAccessibilitySize ? 260 : 330)

            MPButton(title: "Kaydet", size: .hero, fullWidth: true, action: save)
                .disabled(selected == nil || selected == saved)
        }
        .padding(MPSpacing.lg)
        .frame(maxWidth: 460)
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPRadius.sheet)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var characterTabs: some View {
        HStack(spacing: MPSpacing.xs) {
            ForEach(ProfileAvatar.Character.allCases) { item in
                MPChip(title: item.title, isSelected: item == character, height: MPSize.chipHeightKid) {
                    MPHaptics.selection()
                    character = item
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func tile(_ avatar: ProfileAvatar) -> some View {
        let isOn = avatar == selected
        return Button {
            guard !isOn else { return }
            MPHaptics.selection()
            selected = avatar
            guard !reduceMotion else { return }
            withAnimation(MP.M.press) { bumped = avatar.id }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(140))
                withAnimation(MP.M.spring) { if bumped == avatar.id { bumped = nil } }
            }
        } label: {
            ProfileAvatarFace(avatar: avatar)
                .aspectRatio(1, contentMode: .fit)
                .overlay(RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous)
                    .strokeBorder(isOn ? MPColor.actionPrimary : MPColor.borderKid, lineWidth: isOn ? 3 : 1))
                .overlay(alignment: .bottomTrailing) {
                    if isOn {
                        MPIcon("checkmark", size: MP.G.sm, weight: .bold)
                            .foregroundStyle(MPColor.textOnAction)
                            .frame(width: MP.G.xl, height: MP.G.xl)
                            .background(MPColor.actionPrimary, in: Circle())
                            .padding(MPSpacing.xs)
                            .accessibilityHidden(true)
                    }
                }
                .scaleEffect(bumped == avatar.id ? 1.08 : 1)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(avatar.name)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func save() {
        guard let selected else { return }
        var look = HeroLookStore().look(for: profile.id) ?? .standard
        look.avatar = selected.id
        HeroLookStore().save(look, for: profile.id)
        saved = selected
        MPHaptics.success()
        app.showToast("Profilin yenilendi", symbol: "sparkles")
        close()
    }

    private func close() {
        withAnimation(MP.M.gated(MP.M.easeOut)) { shown = false }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 180))
            onClose()
        }
    }
}

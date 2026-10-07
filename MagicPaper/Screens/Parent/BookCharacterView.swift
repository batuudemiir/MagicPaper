import SwiftUI

// MARK: - Model

/// "Kitap karakteri" ekranının durumu ve eylemleri (B2).
///
/// İş mantığı görünümde değil burada: kayıtlı avatarı yüklemek, bir parçayı
/// seçmek, kaydetmek, kaldırmak. Kaydedilmeyen seçim hiçbir kitapta
/// kullanılmaz — görselli kitap ebeveynin açık bir "Kaydet"ini ister
/// (docs/B2_SCENE_LIBRARY_PLAN.md §8.1).
@MainActor
final class BookCharacterModel: ObservableObject {
    let profileID: UUID
    let kit: AvatarKit?
    private let store: AvatarStore

    /// Önizlemedeki seçim. Kayıt yoksa kitin başlangıç önizlemesi.
    @Published private(set) var spec: AvatarSpec
    /// Bu profilin kayıtlı bir kitap karakteri var mı.
    @Published private(set) var hasSaved = false
    @Published private(set) var isBusy = false

    init(profileID: UUID, kit: AvatarKit? = .bundled, store: AvatarStore = .shared) {
        self.profileID = profileID
        self.kit = kit
        self.store = store
        self.spec = kit?.previewDefault
            ?? AvatarSpec(skinTone: "", hairStyle: "", hairColor: "", outfit: "")
    }

    func load() async {
        guard let saved = await store.avatar(for: profileID) else { return }
        spec = kit?.resolved(saved) ?? saved
        hasSaved = true
    }

    func isSelected(_ group: AvatarKit.Group, _ id: String?) -> Bool {
        spec.part(in: group) == id
    }

    /// `id == nil` yalnızca aksesuar için anlamlı: "yok".
    func select(_ group: AvatarKit.Group, _ id: String?) {
        switch group {
        case .skinTone:  if let id { spec.skinTone = id }
        case .hairStyle: if let id { spec.hairStyle = id }
        case .hairColor: if let id { spec.hairColor = id }
        case .outfit:    if let id { spec.outfit = id }
        case .accessory: spec.accessory = id
        }
    }

    func save() async -> Bool {
        isBusy = true
        defer { isBusy = false }
        do {
            try await store.save(spec, for: profileID)
            hasSaved = true
            return true
        } catch {
            return false
        }
    }

    func remove() async {
        isBusy = true
        defer { isBusy = false }
        await store.delete(for: profileID)
        hasSaved = false
        spec = kit?.previewDefault ?? spec
    }

    /// VoiceOver için önizlemenin sözlü tarifi: seçili parçaların etiketleri.
    var spokenSummary: String {
        guard let kit else { return "Kitap karakteri" }
        let parts = AvatarKit.Group.allCases.compactMap { kit.option($0, id: spec.part(in: $0))?.label.lowercased() }
        return "Kitap karakteri: " + parts.joined(separator: ", ")
    }
}

// MARK: - Görünüm

/// Ebeveynin, çocuğun masallarda görünecek karakterini seçtiği ekran.
///
/// İlk, işlevsel sürüm. Görsel tasarımı Zehra'nın kararı (plan §9 #3).
/// Profil düzenleme sayfasından, ebeveyn tarafından açılır; çocuk profilinin
/// madalyonu değişmez — karakter yalnızca kitabın içinde görünür.
struct BookCharacterView: View {
    let profile: UserProfile
    @EnvironmentObject private var app: MPAppState
    @StateObject private var model: BookCharacterModel

    init(profile: UserProfile) {
        self.profile = profile
        _model = StateObject(wrappedValue: BookCharacterModel(profileID: profile.id))
    }

    var body: some View {
        MPSheet(title: "Kitap karakteri", onClose: close) {
            VStack(alignment: .leading, spacing: MP.S.x5) {
                Text("Görselli masallarda \(profile.name) bu karakterle görünür. Fotoğraf istemiyoruz; seçtiğin parçalar yalnızca bu cihazda saklanır.")
                    .font(MP.F.bodyMD())
                    .foregroundStyle(MP.C.textBody)
                    .fixedSize(horizontal: false, vertical: true)

                preview

                if let kit = model.kit {
                    group(.skinTone, title: "Ten", kit: kit)
                    group(.hairStyle, title: "Saç biçimi", kit: kit)
                    group(.hairColor, title: "Saç rengi", kit: kit)
                    group(.outfit, title: "Kıyafet", kit: kit)
                    group(.accessory, title: "Aksesuar", kit: kit, allowsNone: true)
                }

                if !model.hasSaved {
                    Text("Kaydedene kadar masallar bugünkü gibi resimsiz kalır.")
                        .font(MP.F.bodySM())
                        .foregroundStyle(MP.C.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } footer: {
            VStack(spacing: MP.S.x2) {
                LegacyMPButton(title: "Kaydet", fullWidth: true, isDisabled: model.isBusy || model.kit == nil) {
                    Task { await save() }
                }
                .accessibilityLabel("Kitap karakterini kaydet")
                if model.hasSaved {
                    LegacyMPButton(title: "Kitap karakterini kaldır", variant: .ghost, size: .sm, isDisabled: model.isBusy) {
                        Task { await model.remove() }
                    }
                }
            }
        }
        .task { await model.load() }
    }

    private var preview: some View {
        HStack(alignment: .bottom, spacing: MP.S.x4) {
            ForEach(["standing", "celebrating"], id: \.self) { pose in
                AvatarView(spec: model.spec, pose: pose, kit: model.kit)
                    .frame(height: 190)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MP.S.x4)
        .mpEdge(fill: MP.C.surfaceSunken, edge: MP.C.borderHairline, radius: MP.R.card)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.spokenSummary)
    }

    private func group(_ group: AvatarKit.Group, title: String, kit: AvatarKit, allowsNone: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: MP.S.x2) {
            LegacyMPSectionHeader(title: title, emphasis: .secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: MP.S.x2)],
                      alignment: .leading, spacing: MP.S.x2) {
                if allowsNone {
                    BookCharacterOption(label: "Yok", swatch: nil,
                                        isSelected: model.isSelected(group, nil),
                                        accessibilityGroup: title) { model.select(group, nil) }
                }
                ForEach(kit.selectableOptions(group)) { option in
                    BookCharacterOption(label: option.label,
                                        swatch: option.colorToken.flatMap { MP.C.avatarParts[$0] },
                                        isSelected: model.isSelected(group, option.id),
                                        accessibilityGroup: title) { model.select(group, option.id) }
                }
            }
        }
    }

    private func save() async {
        if await model.save() {
            app.showToast("Kitap karakteri kaydedildi", symbol: "sparkles")
            close()
        } else {
            app.showToast("Kaydedilemedi", symbol: "exclamationmark.triangle", tone: .danger)
        }
    }

    private func close() {
        app.sheet = .profileEdit(profile.id)
    }
}

/// Tek bir parça seçeneği: varsa renk örneği ve her zaman yazılı ad — bilgi
/// yalnızca renkle verilmez.
private struct BookCharacterOption: View {
    let label: String
    let swatch: Color?
    let isSelected: Bool
    let accessibilityGroup: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MP.S.x2) {
                if let swatch {
                    Circle().fill(swatch)
                        .frame(width: MP.S.x5, height: MP.S.x5)
                        .overlay(Circle().strokeBorder(MP.C.borderStrong, lineWidth: 1))
                        .accessibilityHidden(true)
                }
                Text(label)
                    .font(MP.F.labelMD())
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if isSelected {
                    MPIcon("checkmark", size: MP.G.sm, weight: .bold).accessibilityHidden(true)
                }
            }
            .foregroundStyle(isSelected ? MP.C.textOnBrand : MP.C.textBody)
            .padding(.horizontal, MP.S.x3)
            .frame(maxWidth: .infinity, minHeight: MP.S.tapMin)
            .mpEdge(fill: isSelected ? MP.C.brand : MP.C.surfaceCard,
                    edge: isSelected ? MP.C.brandEdge : MP.C.borderStrong,
                    radius: MP.R.md)
        }
        .buttonStyle(MPPressStyle(scales: false))
        .accessibilityLabel("\(accessibilityGroup): \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

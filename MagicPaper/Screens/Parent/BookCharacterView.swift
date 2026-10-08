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

/// 13 · Kahraman oluşturucu (`KahramanOlustur`): çocuğun görselli
/// masallarda görünecek karakteri. Canlı önizleme, ten, saç, kıyafet,
/// aksesuar. Fotoğraf asla istenmez. Benim köşem ve Masal ailem'den açılır
/// (görselli kitap bayrağı açıkken); çocuk profilinin madalyonu değişmez.
struct BookCharacterView: View {
    let profile: UserProfile
    @EnvironmentObject private var app: MPAppState
    @StateObject private var model: BookCharacterModel

    init(profile: UserProfile) {
        self.profile = profile
        _model = StateObject(wrappedValue: BookCharacterModel(profileID: profile.id))
    }

    var body: some View {
        VStack(spacing: 0) {
            MPTopBar(title: "Kahramanını tasarla", onBack: close) { EmptyView() }
                .padding(.horizontal, MPSpacing.screenH)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.xl) {
                    preview
                    if let kit = model.kit {
                        group(.skinTone, title: "Ten rengi", kit: kit)
                        group(.hairStyle, title: "Saç", kit: kit)
                        group(.hairColor, title: "Saç rengi", kit: kit)
                        group(.outfit, title: "Kıyafet", kit: kit)
                        group(.accessory, title: "Aksesuar", kit: kit, allowsNone: true)
                    }
                    if model.hasSaved {
                        MPButton(title: "Kahramanı kaldır", kind: .ghost, size: .small) {
                            Task { await model.remove() }
                        }
                        .disabled(model.isBusy)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.vertical, MPSpacing.lg)
            }

            VStack(spacing: MPSpacing.sm) {
                MPButton(title: "Kaydet", systemImage: "checkmark", fullWidth: true, isLoading: model.isBusy) {
                    Task { await save() }
                }
                .disabled(model.kit == nil)
                .accessibilityLabel("Kahramanı kaydet")
                Text("Kahraman masal kapaklarında ve resimlerde böyle görünür.")
                    .mpText(.caption).fontWeight(.regular)
                    .foregroundStyle(MPColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.vertical, MPSpacing.md)
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .task { await model.load() }
    }

    private var preview: some View {
        VStack(spacing: MPSpacing.sm) {
            AvatarView(spec: model.spec, pose: "standing", kit: model.kit)
                .frame(height: 150)
                .frame(width: 170, height: 170)
                .background(MPWorldTone.sky.soft, in: Circle())
                .clipShape(Circle())
                .mpShadow(.card)
            Text(profile.name).mpText(.title2).foregroundStyle(MPColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.spokenSummary)
    }

    @ViewBuilder
    private func group(_ group: AvatarKit.Group, title: String, kit: AvatarKit, allowsNone: Bool = false) -> some View {
        let options = kit.selectableOptions(group)
        let swatches = options.allSatisfy { $0.colorToken != nil }
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text(title).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            MPWrapRow(spacing: MPSpacing.sm) {
                if allowsNone {
                    MPChip(title: "Yok", isSelected: model.isSelected(group, nil)) { model.select(group, nil) }
                        .accessibilityLabel("\(title): Yok")
                }
                ForEach(options) { option in
                    let selected = model.isSelected(group, option.id)
                    if swatches, let token = option.colorToken, let color = MP.C.avatarParts[token] {
                        Button { MPHaptics.selection(); model.select(group, option.id) } label: {
                            Circle().fill(color)
                                .frame(width: 42, height: 42)
                                .overlay(Circle().strokeBorder(MPColor.borderKid, lineWidth: 1))
                                .padding(MPSpacing.xxs)
                                .overlay { if selected { Circle().strokeBorder(MPColor.actionPrimary, lineWidth: 3) } }
                                .frame(minWidth: MPSize.minTouchKid, minHeight: MPSize.minTouchKid)
                        }
                        .buttonStyle(MPPressStyle())
                        .accessibilityLabel("\(title): \(option.label)")
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    } else {
                        MPChip(title: option.label, isSelected: selected) {
                            MPHaptics.selection()
                            model.select(group, option.id)
                        }
                        .accessibilityLabel("\(title): \(option.label)")
                    }
                }
            }
        }
    }

    private func save() async {
        if await model.save() {
            app.showToast("Kahraman kaydedildi", symbol: "sparkles")
            close()
        } else {
            app.showToast("Kaydedilemedi", symbol: "exclamationmark.triangle", tone: .danger)
        }
    }

    private func close() {
        app.sheet = nil
    }
}

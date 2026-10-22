import SwiftUI
import StoryEngine

/// 20 · Yarat 2 (`SihirbazNasil`): Masalda kimler olsun?
///
/// 22 Ekim 2026: yol arkadaşları çip yerine adı ve tek satırlık huyuyla tam
/// genişlikte satırlar (`CreationChoiceRow`); önceki seçimler başlığın altında
/// tek satır ve "Değiştir". Masal ailem çip olarak kalır.
///
/// Teslimdeki ekranın uzunluk, ton ve serbest metin bölümleri yok: uzunluk
/// yaş bandından, ton moddan gelir, serbest metin yok (karar 3 ve 7 Ekim
/// 2026). Kalanlar: yol arkadaşı ve Masal ailem çipleri, "Masalı yaz".
///
/// Adaylar seçilen fikirden türer: masalın öncülünü bozacak bir yol arkadaşı
/// önerilmez. Bunu ekran bilmez, blueprint'ler bilir. Hiçbiri seçilmezse en
/// uygun arkadaşı MagicPaper seçer.
struct CompanionStep: View {

    let ideaID: String?
    /// The resolved intent. Candidates must be able to carry a story of this
    /// mode: a companion only the wrong mode's blueprints accept is not offered.
    var mode: StoryMode? = nil
    /// The child's age, so candidates come from the band the story is written for.
    var age: Int? = nil
    /// Üstteki özet kartı için.
    var childName: String = ""
    var childColor: Color? = nil
    /// Where the candidates come from. The flow passes its own so both steps
    /// ask the same source.
    var source: any StoryChoiceSource = StoryChoiceSources.current
    /// Masal ailem (FAZ 11): the child's own characters. The flow owns the
    /// choice so "Yeni karakter" can hand back the character it just made.
    var familyCharacters: [FamilyCharacter] = []
    /// Relations this mode can carry for this child, from the flow.
    var availableRelations: Set<FamilyRelationKind> = []
    @Binding var selectedFamilyID: UUID?
    /// Opens the new-character editor (parent mode only).
    var onAddFamily: (() -> Void)? = nil
    /// "Değiştir": birinci adıma döner.
    var onChangeMode: (() -> Void)? = nil
    /// Nil means "MagicPaper chooses".
    let onChoose: (String?) -> Void

    @State private var selectedCompanionID: String?

    private static let shown = 3

    /// Only a character this mode can carry shapes the companion list; one
    /// that cannot would leave no blueprint and an empty step.
    private var selectedFamily: FamilyCharacter? {
        familyCharacters.first { $0.id == selectedFamilyID && availableRelations.contains($0.relation.kind) }
    }

    private var candidates: [CompanionChoice] {
        Array(source.companionChoices(forIdeaID: ideaID, mode: mode, age: age, family: selectedFamily)
            .prefix(Self.shown))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    // "Macera" değil: Uyku öncesinde de bu soru soruluyor.
                    CreationTitle(title: "Masalda kimler olsun?")
                    if let mode { summary(mode) }
                }

                companionSection

                if onAddFamily != nil || !familyCharacters.isEmpty {
                    familySection
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.sm)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CreationFooter {
                MPButton(title: "Masalı yaz", systemImage: "wand.and.sparkles", fullWidth: true) {
                    onChoose(selectedCompanionID)
                }
            }
        }
        // A companion the new family choice no longer allows is dropped,
        // visibly, rather than kept and refused at "Masalı yaz".
        .onChange(of: selectedFamilyID) { _, _ in
            if let id = selectedCompanionID, !candidates.contains(where: { $0.id == id }) {
                selectedCompanionID = nil
            }
        }
    }

    /// Şimdiye kadarki seçimler tek cümlede, yanında "Değiştir".
    private func summary(_ mode: StoryMode) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MPSpacing.sm) {
            Text(childName.isEmpty ? mode.title : "\(childName) · \(mode.title)")
                .mpText(.body).foregroundStyle(MPColor.textSecondary)
            if let onChangeMode {
                Button("Değiştir", action: onChangeMode)
                    .mpText(.bodyStrong)
                    .foregroundStyle(MPColor.actionPrimary)
                    .frame(minHeight: MPSize.minTouchParent)
                    .accessibilityHint("Masal türünü değiştirir")
            }
        }
    }

    private var companionSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text(FamilyCharacterCopy.stepCompanionLabel).mpText(.headline).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            // Seçili satıra tekrar dokunmak seçimi kaldırır: arkadaş isteğe bağlı.
            VStack(spacing: MPSpacing.md) {
                ForEach(candidates) { companion in
                    let on = selectedCompanionID == companion.id
                    CreationChoiceRow(
                        title: companion.name,
                        subtitle: description(for: companion),
                        isSelected: on,
                        accessibilityLabel: "\(companion.name), \(description(for: companion))",
                        action: {
                            MPHaptics.selection()
                            selectedCompanionID = on ? nil : companion.id
                        },
                        leading: { MPIconTile(systemImage: symbol(for: companion), tone: .lav, size: MPSize.minTouchKid - MPSpacing.xxs) }
                    )
                }
            }
            if selectedCompanionID == nil {
                Text("Seçmezsen en uygun arkadaşı biz seçeriz.")
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
            }
        }
    }

    /// "Masal ailemden biri de gelsin mi?": optional, one at most.
    private var familySection: some View {
        let available = availableRelations
        let hasUnavailable = familyCharacters.contains { !available.contains($0.relation.kind) }
        return VStack(alignment: .leading, spacing: MPSpacing.md) {
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text("Masal ailem").mpText(.headline).foregroundStyle(MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(FamilyCharacterCopy.stepFamilyHint)
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            MPFlowLayout(spacing: MPSpacing.sm) {
                ForEach(familyCharacters) { character in
                    let isAvailable = available.contains(character.relation.kind)
                    MPChip(title: character.name,
                           systemImage: FamilyCharacterCopy.relationSymbol(character.relation.kind),
                           isSelected: selectedFamilyID == character.id) {
                        MPHaptics.selection()
                        selectedFamilyID = selectedFamilyID == character.id ? nil : character.id
                    }
                    .disabled(!isAvailable)
                    .opacity(isAvailable ? 1 : 0.45)
                    .frame(minHeight: MPSize.minTouchKid)
                    .accessibilityLabel("\(character.name), \(FamilyCharacterCopy.relation(character.relation.kind))")
                    .accessibilityHint(isAvailable ? "" : FamilyCharacterCopy.stepUnavailableAccessibility)
                }
                if let onAddFamily, familyCharacters.count < FamilyCharacter.maxPerChild {
                    MPChip(title: "Masal ailem", systemImage: "plus", style: .dashed) { onAddFamily() }
                        .frame(minHeight: MPSize.minTouchKid)
                        .accessibilityLabel(FamilyCharacterCopy.addButton)
                }
            }
            if hasUnavailable {
                Text(FamilyCharacterCopy.stepUnavailable)
                    .mpText(.caption).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// The companion's own line if it has one, otherwise what it is. Never the
    /// trait list — "reassuring" is a casting concept, not something to read.
    private func description(for companion: CompanionChoice) -> String {
        companion.personality.isEmpty
            ? companion.kind.capitalized(with: Locale(identifier: "tr_TR"))
            : companion.personality
    }

    /// Content declares no icon, so this maps from the animal.
    ///
    /// Every animal that has a symbol gets its own. The previous version sent
    /// hedgehog, rabbit, fox and bear all to `pawprint`, so four of the five
    /// companions in the library were drawn identically — on a screen whose
    /// entire job is choosing between three of them. A child picking a
    /// companion by its picture was choosing between three copies of the same
    /// picture.
    ///
    /// The paw stays as the honest fallback for an animal the symbol set has
    /// nothing for, and `CompanionSymbolTests` fails if two shipped companions
    /// ever land on it together — which is the point at which a fallback stops
    /// being a fallback and becomes the collision again.
    static func symbol(forType type: String) -> String {
        switch type.lowercased(with: Locale(identifier: "tr_TR")) {
        case "baykuş", "kuş":   return "bird"
        case "yunus", "balık":  return "fish"
        case "ejderha":         return "flame.fill"
        case "tavşan":          return "hare"
        case "tilki", "köpek":  return "dog"
        case "kedi":            return "cat"
        case "ayı":             return "teddybear"
        case "kaplumbağa":      return "tortoise"
        case "kertenkele":      return "lizard"
        case "robot":           return "cpu"
        case "kelebek":         return "ladybug"
        default:                return "pawprint"
        }
    }

    private func symbol(for companion: CompanionChoice) -> String {
        Self.symbol(forType: companion.kind)
    }
}

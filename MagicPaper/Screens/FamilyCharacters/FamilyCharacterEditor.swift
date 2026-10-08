import SwiftUI
import StoryEngine

/// Masal ailem karakterini ekleme ve düzenleme (FAZ 11).
///
/// İki yerden açılır: profil sayfasındaki Masal ailem listesinden ve
/// "Masalda kimler olsun?" adımındaki "Yeni karakter"den. Ad, ilişki türü,
/// hayvansa türü — başka alan yok, cinsiyet hiç yok. Ad kuralları
/// `FamilyNameValidator`'da; burada yalnızca gösterilir.
struct FamilyCharacterEditor: View {
    let childID: UUID
    let childName: String
    /// Nil: yeni karakter.
    var editing: FamilyCharacter? = nil
    var source: any StoryChoiceSource = StoryChoiceSources.current
    var store = FamilyCharacterStore()
    let onClose: () -> Void
    let onSaved: (FamilyCharacter) -> Void
    var onRemoved: (() -> Void)? = nil

    @State private var name = ""
    @State private var relation: FamilyRelationKind?
    @State private var animalKindID: String?
    /// Hata, ebeveyn bir kez kaydetmeyi denedikten sonra gösterilir; yazarken
    /// her harfte kırmızı uyarı görmek sakin değil.
    @State private var showsErrors = false
    @State private var confirmsRemoval = false
    @State private var saveFailed = false

    /// Read once when the editor opens. Reading them in `body` meant a file
    /// read and a catalog walk on every keystroke.
    @State private var kinds: [FamilyAnimalKindChoice] = []
    @State private var otherNames: [String] = []

    private var validation: Result<String, FamilyNameValidator.Rejection> {
        FamilyNameValidator.validate(name, childName: childName, existing: otherNames)
    }

    private var chosenRelation: FamilyRelation? {
        switch relation {
        case .sibling: return .sibling
        case .friend: return .friend
        case .imaginary: return .imaginary
        case .animal: return animalKindID.map { .animal(kindID: $0) }
        case nil: return nil
        }
    }

    private var canSave: Bool {
        if case .success = validation, chosenRelation != nil { return true }
        return false
    }

    private var nameError: String? {
        if saveFailed { return FamilyCharacterCopy.saveFailed }
        guard showsErrors, case .failure(let rejection) = validation else { return nil }
        return FamilyCharacterCopy.rejection(rejection)
    }

    var body: some View {
        VStack(spacing: 0) {
            MPTopBar(title: editing == nil ? FamilyCharacterCopy.newTitle : FamilyCharacterCopy.editTitle,
                     onBack: onClose) { EmptyView() }
                .padding(.horizontal, MPSpacing.screenH)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                    MPTextField(label: FamilyCharacterCopy.nameLabel,
                                placeholder: FamilyCharacterCopy.namePlaceholder,
                                text: $name,
                                helper: nameError ?? FamilyCharacterCopy.nameHint,
                                isError: nameError != nil)
                        .textInputAutocapitalization(.words)
                        .onChange(of: name) { _, value in
                            let limit = FamilyNameValidator.maxLength + 4
                            if value.count > limit { name = String(value.prefix(limit)) }
                        }

                    VStack(alignment: .leading, spacing: MPSpacing.md) {
                        Text(FamilyCharacterCopy.relationLabel).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                        MPWrapRow(spacing: MPSpacing.sm) {
                            ForEach(FamilyRelationKind.allCases, id: \.self) { kind in
                                MPChip(title: FamilyCharacterCopy.relation(kind),
                                       systemImage: FamilyCharacterCopy.relationSymbol(kind),
                                       isSelected: relation == kind) {
                                    MPHaptics.selection()
                                    relation = kind
                                }
                            }
                        }
                    }

                    if relation == .animal {
                        VStack(alignment: .leading, spacing: MPSpacing.md) {
                            Text(FamilyCharacterCopy.animalKindLabel).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                            MPWrapRow(spacing: MPSpacing.sm) {
                                ForEach(kinds) { kind in
                                    MPChip(title: kind.name.capitalized(with: Locale(identifier: "tr_TR")),
                                           systemImage: CompanionStep.symbol(forType: kind.name),
                                           isSelected: animalKindID == kind.id) {
                                        MPHaptics.selection()
                                        animalKindID = kind.id
                                    }
                                }
                            }
                        }
                        .transition(.opacity)
                    }

                    if editing != nil, onRemoved != nil {
                        MPButton(title: FamilyCharacterCopy.remove, systemImage: "minus.circle", kind: .ghost) {
                            confirmsRemoval = true
                        }
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.vertical, MPSpacing.lg)
                .animation(MP.M.gated(MP.M.easeOut), value: relation)
            }

            MPButton(title: FamilyCharacterCopy.save, fullWidth: true) { save() }
                // Devre dışı değil: eksik bir şey varsa basınca söyler. Ad
                // kuralları ancak böyle görünür olur.
                .opacity(canSave ? 1 : 0.6)
                .accessibilityHint(canSave ? "" : FamilyCharacterCopy.saveIncompleteHint)
                .padding(.horizontal, MPSpacing.xxxl)
                .padding(.vertical, MPSpacing.md)
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .confirmationDialog(
            FamilyCharacterCopy.removeConfirmTitle,
            isPresented: $confirmsRemoval,
            titleVisibility: .visible
        ) {
            Button(FamilyCharacterCopy.removeConfirmButton, role: .destructive, action: remove)
            Button(FamilyCharacterCopy.cancel, role: .cancel) {}
        } message: {
            Text(FamilyCharacterCopy.removeConfirmMessage(name: editing?.name ?? ""))
        }
        .onAppear(perform: load)
    }

    private func load() {
        kinds = source.familyAnimalKindChoices()
        otherNames = store.characters(for: childID).filter { $0.id != editing?.id }.map(\.name)
        guard let editing else { return }
        name = editing.name
        relation = editing.relation.kind
        animalKindID = editing.relation.animalKindID
    }

    private func save() {
        showsErrors = true
        saveFailed = false
        guard case .success(let normalised) = validation, let chosenRelation else { return }
        var character = editing ?? FamilyCharacter(childID: childID, name: normalised, relation: chosenRelation)
        character.name = normalised
        character.relation = chosenRelation
        do {
            try store.save(character)
            MPHaptics.success()
            onSaved(character)
        } catch {
            saveFailed = true
        }
    }

    private func remove() {
        guard let editing else { return }
        do {
            try store.delete(id: editing.id, childID: childID)
            // An open series written with this character goes on without it
            // (FAZ 13): unopened episodes are written again.
            SeriesManager.shared.familyCharacterRemoved(id: editing.id, childID: childID)
            onRemoved?()
        } catch {
            saveFailed = true
        }
    }
}

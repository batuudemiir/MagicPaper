import SwiftUI
import StoryEngine

/// Masal ailem: çocuğun tekrar eden karakterleri ve kaç masalda göründükleri (FAZ 11).
///
/// Profil sayfasından açılır. Benim köşem FAZ 17'de gelince oraya taşınır
/// (karar: 4 Ekim 2026). Düzenleyici aynı katmanda, listenin yerine açılır:
/// iç içe iki sayfa yerine tek bir sayfa.
struct FamilyCharactersView: View {
    let profile: UserProfile

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var storyManager = StoryGenerationManager.shared

    private enum Mode: Equatable {
        case list
        case adding
        case editing(FamilyCharacter)
    }

    @State private var mode: Mode = .list
    @State private var characters: [FamilyCharacter] = []

    private let store = FamilyCharacterStore()
    private var source: any StoryChoiceSource { StoryChoiceSources.current }

    var body: some View {
        Group {
            switch mode {
            case .list:
                list
            case .adding:
                editor(nil)
            case .editing(let character):
                editor(character)
            }
        }
        .onAppear(perform: reload)
    }

    private var list: some View {
        MPSheet(title: FamilyCharacterCopy.screenTitle, onClose: { app.sheet = nil }) {
            if characters.isEmpty {
                MPEmptyState(
                    title: FamilyCharacterCopy.emptyTitle,
                    description: FamilyCharacterCopy.emptyDescription
                )
            } else {
                VStack(spacing: MP.S.x2) {
                    let kinds = source.familyAnimalKindChoices()
                    ForEach(characters) { character in
                        let count = FamilyCharacterAppearances.count(of: character.id, in: storyManager.stories)
                        let relation = FamilyCharacterCopy.relationLine(character.relation, kinds: kinds)
                        LegacyMPListRow(
                            symbol: FamilyCharacterCopy.relationSymbol(character.relation.kind),
                            title: character.name,
                            description: "\(relation) · \(FamilyCharacterCopy.appearances(count))",
                            action: { mode = .editing(character) }
                        ) {
                            MPIcon("chevron.right", size: MP.G.sm, weight: .semibold)
                                .foregroundStyle(MP.C.textFaint)
                                .accessibilityHidden(true)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(FamilyCharacterCopy.rowAccessibility(
                            name: character.name, relation: relation, count: count))
                    }
                }
            }
        } footer: {
            VStack(spacing: MP.S.x2) {
                let full = characters.count >= FamilyCharacter.maxPerChild
                if full {
                    Text(FamilyCharacterCopy.limitReached)
                        .font(MP.F.bodySM())
                        .foregroundStyle(MP.C.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                LegacyMPButton(title: FamilyCharacterCopy.addButton, variant: .outline, icon: "plus",
                         fullWidth: true, isDisabled: full) {
                    mode = .adding
                }
            }
        }
    }

    private func editor(_ character: FamilyCharacter?) -> some View {
        FamilyCharacterEditor(
            childID: profile.id,
            childName: profile.name,
            editing: character,
            onClose: { mode = .list },
            onSaved: { _ in
                app.showToast(character == nil ? FamilyCharacterCopy.saved : FamilyCharacterCopy.updated)
                reload()
                mode = .list
            },
            onRemoved: {
                app.showToast(FamilyCharacterCopy.removed, symbol: "minus.circle")
                reload()
                mode = .list
            }
        )
    }

    private func reload() {
        characters = store.characters(for: profile.id)
    }
}

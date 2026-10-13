import SwiftUI
import StoryEngine

/// 14 · Masal ailem (`MasalAilem`): çocuğun tekrar eden karakterleri ve kaç
/// masalda göründükleri (FAZ 11). Benim köşem'den açılır. Kahraman kartı tam
/// genişlik, diğerleri iki sütun, "Yeni karakter" kesikli kart. Bir masal tek
/// bir Masal ailem karakteri taşıdığı için seçim tek (tasarımda çoklu);
/// "Bu karakterle masal yaz" Yarat'ı o karakter seçili açar. Düzenleyici aynı
/// katmanda, listenin yerine açılır.
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

    /// 14: bir masal tek bir Masal ailem karakteri taşır, seçim tek.
    @State private var selectedID: UUID?
    private static let tones: [MPWorldTone] = [.peach, .sky, .lav, .yellow, .mint, .pink, .green]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md), count: 2)

    private var list: some View {
        let kinds = source.familyAnimalKindChoices()
        let full = characters.count >= FamilyCharacter.maxPerChild
        return VStack(spacing: 0) {
            MPTopBar(title: FamilyCharacterCopy.screenTitle, subtitle: "Masallarında tekrar görünen karakterler",
                     onBack: { app.sheet = nil }) { EmptyView() }
                .padding(.horizontal, MPSpacing.screenH)

            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.md) {
                    heroCard
                    LazyVGrid(columns: columns, spacing: MPSpacing.md) {
                        ForEach(Array(characters.enumerated()), id: \.element.id) { index, character in
                            card(character, kinds: kinds, tone: Self.tones[index % Self.tones.count])
                        }
                        if !full {
                            Button { mode = .adding } label: {
                                VStack(spacing: MPSpacing.sm) {
                                    MPIcon("plus", size: 26, weight: .semibold)
                                    Text(FamilyCharacterCopy.addButton).mpText(.callout)
                                }
                                .foregroundStyle(MPColor.textSecondary)
                                .frame(maxWidth: .infinity, minHeight: 150)
                                .overlay(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
                                    .strokeBorder(MPColor.borderDashed, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
                            }
                            .buttonStyle(MPPressStyle())
                        }
                    }
                    if characters.isEmpty {
                        Text(FamilyCharacterCopy.emptyDescription)
                            .mpText(.body).foregroundStyle(MPColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, MPSpacing.sm)
                    }
                    if full {
                        Text(FamilyCharacterCopy.limitReached)
                            .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.bottom, MPSpacing.xl)
            }

            if let selected = characters.first(where: { $0.id == selectedID }) {
                VStack(spacing: MPSpacing.sm) {
                    HStack(spacing: MPSpacing.lg) {
                        Text("\(selected.name) seçili").mpText(.callout).foregroundStyle(MPColor.textSecondary)
                        Button("Düzenle") { mode = .editing(selected) }
                            .mpText(.callout).foregroundStyle(MPColor.actionPrimary)
                            .frame(minHeight: MPSize.minTouchParent)
                    }
                    MPButton(title: "Bu karakterle masal yaz", systemImage: "wand.and.sparkles", fullWidth: true) {
                        app.sheet = nil
                        app.startStoryCreation(family: selected.id)
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.vertical, MPSpacing.md)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .animation(MP.M.gated(MP.M.base), value: selectedID)
    }

    /// Çocuğun kendisi: her masalda kahraman. "Düzenle" kahraman
    /// oluşturucuya gider (görselli kitap açıkken).
    private var heroCard: some View {
        HStack(spacing: MPSpacing.lg) {
            MPInitialAvatar(name: profile.name, color: profile.mpColor, size: 64)
                .padding(MPSpacing.xxs)
                .background(MPColor.backgroundSurface, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text(profile.name).mpText(.headline).foregroundStyle(MPColor.textPrimary)
                Text("Kahraman · her masalda").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
            }
            Spacer(minLength: 0)
            if IllustratedBookAccess.isEnabled() {
                Button("Düzenle") { app.sheet = .bookCharacter(profile.id) }
                    .mpText(.callout).foregroundStyle(MPColor.actionPrimary)
                    .frame(minHeight: MPSize.minTouchParent)
            }
        }
        .padding(MPSpacing.lg)
        .background(MPWorldTone.green.soft, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func card(_ character: FamilyCharacter, kinds: [FamilyAnimalKindChoice], tone: MPWorldTone) -> some View {
        let count = FamilyCharacterAppearances.count(of: character.id, in: storyManager.stories)
        let relation = FamilyCharacterCopy.relationLine(character.relation, kinds: kinds)
        let isSelected = selectedID == character.id
        return Button {
            MPHaptics.selection()
            selectedID = isSelected ? nil : character.id
        } label: {
            VStack(spacing: MPSpacing.sm) {
                MPIcon(FamilyCharacterCopy.relationSymbol(character.relation.kind), size: 26, weight: .semibold)
                    .foregroundStyle(tone.deep)
                    .frame(width: 60, height: 60)
                    .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.tile, style: .continuous))
                Text(character.name).mpText(.headline).foregroundStyle(MPColor.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text("\(relation.lowercased(with: Locale(identifier: "tr_TR"))) · \(FamilyCharacterCopy.appearances(count))")
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(MPSpacing.lg)
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
                    .strokeBorder(isSelected ? MPColor.actionPrimary : .clear, lineWidth: 3)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    MPIcon("checkmark", size: 12, weight: .heavy)
                        .foregroundStyle(MPColor.textOnAction)
                        .frame(width: 24, height: 24)
                        .background(MPColor.actionPrimary, in: Circle())
                        .padding(MPSpacing.sm)
                }
            }
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(FamilyCharacterCopy.rowAccessibility(name: character.name, relation: relation, count: count))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: "Düzenle") { mode = .editing(character) }
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

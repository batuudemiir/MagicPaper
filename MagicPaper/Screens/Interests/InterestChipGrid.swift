import SwiftUI

/// "Neleri sever?" çipleri (FAZ 12). Profil oluşturma ve ebeveyn düzenleme
/// sayfası aynı ızgarayı kullanır.
///
/// Sınıra gelince seçilmemiş çipler devre dışı kalır; VoiceOver neden
/// olduğunu söyler. Seçim hiçbir zaman zorunlu değil.
struct InterestChipGrid: View {
    let choices: [InterestChoice]
    @Binding var selection: [String]

    var body: some View {
        MPWrapRow {
            ForEach(choices) { choice in
                let isSelected = selection.contains(choice.id)
                let canAdd = ChildInterests.canAdd(choice.id, to: selection)
                MPChip(
                    title: choice.name,
                    symbol: choice.symbol,
                    isSelected: isSelected,
                    isDisabled: !canAdd
                ) {
                    MPHaptics.selection()
                    toggle(choice.id)
                }
                .accessibilityLabel(choice.name)
                .accessibilityHint(canAdd ? "" : InterestCopy.limitHint)
            }
        }
    }

    private func toggle(_ id: String) {
        if let index = selection.firstIndex(of: id) {
            selection.remove(at: index)
        } else if ChildInterests.canAdd(id, to: selection) {
            selection.append(id)
        }
    }
}

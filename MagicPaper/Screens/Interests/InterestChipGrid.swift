import SwiftUI

/// 08 · Neleri sever: ilgi kartları, üç sütun. Seçili kart mor çerçeve ve
/// köşede tik taşır; bilgi yalnızca renkle verilmez. En fazla
/// `ChildInterests.maxSelection`; sınıra gelince seçilmemiş kartlar soluklaşır.
/// Profil oluşturma ve "Neleri sever?" düzenleyicisi aynı ızgarayı kullanır.
struct InterestChipGrid: View {
    let choices: [InterestChoice]
    @Binding var selection: [String]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md), count: 3)
    private let tones: [MPWorldTone] = [.peach, .sky, .green, .pink, .yellow, .mint, .lav, .gray]

    var body: some View {
        LazyVGrid(columns: columns, spacing: MPSpacing.md) {
            ForEach(Array(choices.enumerated()), id: \.element.id) { index, choice in
                tile(choice, tone: tones[index % tones.count])
            }
        }
    }

    private func tile(_ choice: InterestChoice, tone: MPWorldTone) -> some View {
        let isSelected = selection.contains(choice.id)
        let canAdd = ChildInterests.canAdd(choice.id, to: selection)
        return Button {
            MPHaptics.selection()
            toggle(choice.id)
        } label: {
            VStack(spacing: MPSpacing.sm) {
                MPIcon(choice.symbol ?? "sparkles", size: 26, weight: .semibold)
                    .foregroundStyle(tone.deep)
                Text(choice.name)
                    .mpText(.callout)
                    .foregroundStyle(MPColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .padding(.vertical, MPSpacing.sm)
            .background(tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.tile, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MPRadius.tile, style: .continuous)
                    .strokeBorder(isSelected ? MPColor.actionPrimary : .clear, lineWidth: 3)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    MPIcon("checkmark", size: 12, weight: .heavy)
                        .foregroundStyle(MPColor.textOnAction)
                        .frame(width: 22, height: 22)
                        .background(MPColor.actionPrimary, in: Circle())
                        .padding(MPSpacing.xs)
                }
            }
            .opacity(canAdd ? 1 : 0.45)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(choice.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(canAdd ? "" : InterestCopy.limitHint)
    }

    private func toggle(_ id: String) {
        if let index = selection.firstIndex(of: id) {
            selection.remove(at: index)
        } else if ChildInterests.canAdd(id, to: selection) {
            selection.append(id)
        }
    }
}

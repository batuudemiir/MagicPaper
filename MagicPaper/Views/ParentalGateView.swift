import SwiftUI

/// Ebeveyn kapısı — 03-SCREENS.md §11.
struct ParentalGateView: View {
    var onSuccess: () -> Void
    var onCancel: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var a = Int.random(in: 3...8)
    @State private var b = Int.random(in: 2...8)
    @State private var answer = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            MPIcon("shield", size: 34, weight: .semibold)
                .foregroundStyle(MP.C.brand)
                .frame(width: 72, height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(MP.C.brandSoft)
                )

            VStack(spacing: 6) {
                Text("Bu bölüm ebeveynler için")
                    .font(MP.F.displayMD())
                    .foregroundStyle(MP.C.textTitle)
                    .multilineTextAlignment(.center)
                Text("Devam etmek için işlemi çöz")
                    .font(MP.F.bodyMD())
                    .foregroundStyle(MP.C.textMuted)
            }

            Text("\(a) + \(b) = ?")
                .font(MP.F.displayHeavy(32))
                .foregroundStyle(MP.C.textTitle)

            MPInput(placeholder: "Cevap", text: $answer, error: error, keyboard: .numberPad)
                .frame(width: 160)
                .onChange(of: answer) { _, new in
                    let digits = new.filter(\.isNumber)
                    if digits != new { answer = digits }
                }

            LegacyMPButton(title: "Onayla", size: .lg, fullWidth: true,
                     isDisabled: answer.trimmingCharacters(in: .whitespaces).isEmpty) {
                check()
            }

            LegacyMPButton(title: "Geri dön", variant: .ghost, size: .sm) {
                if let onCancel { onCancel() } else { dismiss() }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .mpScreenBackground()
    }

    private func check() {
        if Int(answer) == a + b {
            error = nil
            onSuccess()
        } else {
            withAnimation(MP.M.gated(MP.M.easeOut)) {
                answer = ""
                error = "Tekrar dene"
                a = Int.random(in: 3...8)
                b = Int.random(in: 2...8)
            }
        }
    }
}

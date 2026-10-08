import SwiftUI

/// 28 · Ebeveyn kapısı (`EbeveynKapisi`).
///
/// Çarpma sorusu; üç yanlışta 30 saniye bekleme (`MPGateQuiz`). Ebeveyn
/// alanının kapısı olduğu için maskot yok. Masal aksiyonlarındaki kilitli
/// satırlar da (yazdır, paylaş, sil) bu ekrandan geçer.
struct ParentalGateView: View {
    var onSuccess: () -> Void
    var onCancel: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var quiz = MPGateQuiz()
    @State private var answer = ""
    @State private var error: String?
    @State private var now = Date()
    @FocusState private var focused: Bool

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri", action: cancel)
                Spacer()
            }
            .padding(.top, MPSpacing.sm)

            Spacer(minLength: MPSpacing.xl)

            VStack(spacing: MPSpacing.xl) {
                MPIcon("shield", size: 40, weight: .semibold)
                    .foregroundStyle(MPColor.actionPrimary)
                    .frame(width: 120, height: 108)
                    .background(MPWorldTone.sky.soft, in: Ellipse())
                    .accessibilityHidden(true)

                VStack(spacing: MPSpacing.md) {
                    Text("Bu bölüm büyükler için")
                        .mpText(.title2).foregroundStyle(MPColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Devam etmek için işlemi çöz")
                        .mpText(.body).foregroundStyle(MPColor.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Text(quiz.question)
                    .font(.mpNumeral)
                    .foregroundStyle(MPColor.textPrimary)
                    .accessibilityLabel("\(quiz.a) çarpı \(quiz.b) kaç eder?")

                VStack(spacing: MPSpacing.xs) {
                    TextField("Cevap", text: $answer)
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .multilineTextAlignment(.center)
                        .mpText(.title2)
                        .foregroundStyle(MPColor.textPrimary)
                        .frame(width: 160, height: 54)
                        .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.input))
                        .overlay(RoundedRectangle(cornerRadius: MPRadius.input)
                            .strokeBorder(error != nil ? MPColor.statusDanger : MPColor.borderKid, lineWidth: 2))
                        .disabled(locked)
                        .accessibilityLabel("Cevap")
                        .onChange(of: answer) { _, new in
                            let digits = String(new.filter(\.isNumber).prefix(3))
                            if digits != new { answer = digits }
                        }
                    if let error {
                        Text(error).mpText(.callout).foregroundStyle(MPColor.statusDanger)
                    }
                }

                VStack(spacing: MPSpacing.sm) {
                    MPButton(title: "Onayla", fullWidth: true, action: check)
                        .disabled(answer.isEmpty || locked)
                    MPButton(title: "Geri dön", kind: .ghost, action: cancel)
                }
                .padding(.horizontal, MPSpacing.xxxl)

                Text(locked
                     ? "Biraz bekleyelim: \(quiz.secondsLeft(at: now)) saniye."
                     : "Üç yanlış denemeden sonra 30 saniye beklenir.")
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: MPSpacing.xl)
        }
        .padding(.horizontal, MPSpacing.screenH)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .onReceive(tick) { now = $0 }
        .onAppear { focused = true }
    }

    private var locked: Bool { quiz.isLocked(at: now) }

    private func cancel() {
        if let onCancel { onCancel() } else { dismiss() }
    }

    private func check() {
        now = Date()
        switch quiz.answer(Int(answer), at: now) {
        case .correct:
            error = nil
            onSuccess()
        case .wrong, .locked:
            withAnimation(MP.M.gated(MP.M.easeOut)) {
                answer = ""
                error = "Tekrar dene"
            }
        }
    }
}

#Preview("28 · Ebeveyn kapısı") {
    ParentalGateView(onSuccess: {})
}

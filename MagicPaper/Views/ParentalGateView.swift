import SwiftUI

/// 28 · Ebeveyn kapısı (`EbeveynKapisi`).
///
/// İki biçim (karar: 14 Kasım 2026):
/// - `.hold`: "Büyükler için" odasına giriş. Bir büyük düğmeyi iki saniye
///   basılı tutar. Oda ayar ve özet içerir; dışarı çıkan ya da geri alınamayan
///   bir şey yapmaz, bu yüzden giriş hafif.
/// - `.quiz`: çarpma sorusu; üç yanlışta 30 saniye bekleme (`MPGateQuiz`).
///   Silme, paylaşma, dışa aktarma, giriş, profil ekleme ve satın alma.
///
/// Ebeveyn alanının kapısı olduğu için maskot yok.
struct ParentalGateView: View {
    enum Kind { case quiz, hold }

    var kind: Kind = .quiz
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
        // Sayı klavyesi açılınca ekranın yarısı gider. Tek çıkış ("Geri")
        // sabit tepede, güvenli alanın içinde; içerik kayar, klavye ve saat
        // çubuğu altına itilmez (23 Ekim 2026).
        VStack(spacing: 0) {
            HStack {
                MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri", action: cancel)
                Spacer()
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.sm)

            if kind == .hold {
                ParentalHoldGate(onSuccess: onSuccess)
            } else {
                quizBody
            }
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .onReceive(tick) { now = $0 }
        .onAppear { focused = kind == .quiz }
    }

    private var quizBody: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.lg) {
                    MPIcon("shield", size: 34, weight: .semibold)
                        .foregroundStyle(MPColor.actionPrimary)
                        .frame(width: 96, height: 84)
                        .background(MPWorldTone.lav.soft, in: Ellipse())
                        .accessibilityHidden(true)

                    VStack(spacing: MPSpacing.sm) {
                        Text("Bu bölüm büyükler için")
                            .mpText(.page).foregroundStyle(MPColor.textPrimary)
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
                            .mpText(.page)
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
                            Text(error).mpText(.supporting).foregroundStyle(MPColor.statusDanger)
                        }
                        // Kural ve bekleme sayacı alanın hemen altında: klavye açıkken görünür.
                        Text(locked
                             ? "Biraz bekleyelim: \(quiz.secondsLeft(at: now)) saniye."
                             : "Üç yanlış denemeden sonra 30 saniye beklenir.")
                            .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    MPButton(title: "Onayla", fullWidth: true, action: check)
                        .disabled(answer.isEmpty || locked)
                        .padding(.horizontal, MPSpacing.xxxl)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.vertical, MPSpacing.lg)
            }
            .scrollBounceBehavior(.basedOnSize)
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

// MARK: - Basılı tut

/// Odaya giriş: iki saniye basılı tutulan tek düğme. Halka zamanla dolar
/// (animasyon eğrisi değil, geçen süre); bırakılınca boşalır. VoiceOver'da
/// basılı tutmak zor olduğundan varsayılan eylem kapıyı açar: ekran okuyucuyu
/// kullanan büyüktür.
struct ParentalHoldGate: View {
    var onSuccess: () -> Void

    static let holdSeconds: Double = 2

    @State private var progress: Double = 0
    @State private var pressing = false
    @State private var done = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MPSpacing.xl) {
                VStack(spacing: MPSpacing.sm) {
                    Text("Bu bölüm büyükler için")
                        .mpText(.page).foregroundStyle(MPColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Açmak için düğmeyi iki saniye basılı tut.")
                        .mpText(.body).foregroundStyle(MPColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ZStack {
                    Circle()
                        .stroke(MPWorldTone.lav.soft, lineWidth: MPSpacing.sm)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(MPColor.actionPrimary,
                                style: StrokeStyle(lineWidth: MPSpacing.sm, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    MPIcon("hand.tap", size: MP.G.xl, weight: .semibold)
                        .foregroundStyle(MPColor.actionPrimary)
                }
                .frame(width: MPSize.minTouchHero * 2, height: MPSize.minTouchHero * 2)
                .contentShape(Circle())
                // Sistemin uzun basma hareketi kaydırma alanının içinde
                // tamamlanmıyordu (simülatörde görüldü, 15 Kasım 2026): basma
                // burada izlenir, süre dolunca kapı açılır.
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in if !pressing { pressing = true } }
                        .onEnded { _ in release() }
                )
                .task(id: pressing) { await fill() }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Büyükler için bölümünü aç")
                .accessibilityHint("İki saniye basılı tut")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { finish() }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.vertical, MPSpacing.xxxl)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    /// Basılıyken halkayı geçen süreyle doldurur; dolunca kapı açılır.
    private func fill() async {
        guard pressing else { return }
        let start = Date()
        while pressing && !done && !Task.isCancelled {
            progress = min(1, Date().timeIntervalSince(start) / Self.holdSeconds)
            if progress >= 1 { finish(); return }
            try? await Task.sleep(for: .milliseconds(30))
        }
    }

    /// Erken bırakıldı: halka boşalır.
    private func release() {
        pressing = false
        if !done { progress = 0 }
    }

    private func finish() {
        guard !done else { return }
        done = true
        progress = 1
        onSuccess()
    }
}

#Preview("28 · Ebeveyn kapısı") {
    ParentalGateView(onSuccess: {})
}

#Preview("28 · Odaya giriş") {
    ParentalGateView(kind: .hold, onSuccess: {})
}

import SwiftUI

/// Ebeveyn doğrulama ekranı - COPPA uyumluluğu için gerekli
/// Çocukların yanlışlıkla dış linklere veya ayarlara erişmesini engeller
struct ParentalGateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userAnswer: String = ""
    @State private var showError = false
    @State private var attempts = 0
    
    let onSuccess: () -> Void
    
    // Basit matematik soruları
    private let questions = [
        (question: "5 + 3 = ?", answer: "8"),
        (question: "10 - 4 = ?", answer: "6"),
        (question: "7 + 2 = ?", answer: "9"),
        (question: "12 - 5 = ?", answer: "7"),
        (question: "6 + 4 = ?", answer: "10"),
        (question: "15 - 8 = ?", answer: "7"),
        (question: "9 + 3 = ?", answer: "12"),
        (question: "11 - 6 = ?", answer: "5")
    ]
    
    @State private var currentQuestion: (question: String, answer: String)
    
    init(onSuccess: @escaping () -> Void) {
        self.onSuccess = onSuccess
        _currentQuestion = State(initialValue: questions.randomElement() ?? questions[0])
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.98, blue: 1.0),
                        Color(red: 0.95, green: 0.96, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // İkon
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                    }
                    
                    // Başlık
                    VStack(spacing: 12) {
                        Text(L.isEnglish ? "Parent Verification" : "Ebeveyn Doğrulama")
                            .font(.title.bold())
                            .foregroundColor(.primary)
                        
                        Text(L.isEnglish ? 
                             "This section is for adults only.\nPlease solve this simple math problem:" :
                             "Bu bölüm yalnızca yetişkinler içindir.\nLütfen bu basit matematik sorusunu çözün:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Soru kartı
                    VStack(spacing: 24) {
                        Text(currentQuestion.question)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                        
                        // Cevap girişi
                        TextField(L.isEnglish ? "Your answer" : "Cevabınız", text: $userAnswer)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal, 40)
                        
                        // Hata mesajı
                        if showError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(L.isEnglish ? "Incorrect answer. Please try again." : "Yanlış cevap. Lütfen tekrar deneyin.")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Doğrula butonu
                        Button(action: checkAnswer) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text(L.isEnglish ? "Verify" : "Doğrula")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange, Color.red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .padding(.horizontal, 40)
                        .disabled(userAnswer.isEmpty)
                        .opacity(userAnswer.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Bilgi notu
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text(L.isEnglish ? "Why do we ask this?" : "Neden bunu soruyoruz?")
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                        }
                        
                        Text(L.isEnglish ?
                             "To protect children, we verify that an adult is present before accessing certain features." :
                             "Çocukları korumak için, belirli özelliklere erişmeden önce bir yetişkinin olduğunu doğruluyoruz.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private func checkAnswer() {
        withAnimation {
            if userAnswer.trimmingCharacters(in: .whitespaces) == currentQuestion.answer {
                // Doğru cevap
                showError = false
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Başarılı, callback'i çağır ve kapat
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSuccess()
                    dismiss()
                }
            } else {
                // Yanlış cevap
                showError = true
                attempts += 1
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                
                // 3 yanlış denemeden sonra soruyu değiştir
                if attempts >= 3 {
                    currentQuestion = questions.randomElement() ?? questions[0]
                    attempts = 0
                }
                
                // Cevabı temizle
                userAnswer = ""
                
                // Hata mesajını 2 saniye sonra gizle
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showError = false
                    }
                }
            }
        }
    }
}

#Preview {
    ParentalGateView(onSuccess: {
        print("Ebeveyn doğrulaması başarılı")
    })
}

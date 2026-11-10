import SwiftUI
import StoryEngine

/// 02 · Karşılama (Faz 8, 11 Kasım 2026): tek ekran.
///
/// Üç parıltılı sayfa yerine tek, düz krem bir ekran: Ragi, markanın vaadi, güven
/// cümlesi, tek birincil düğme. Eski 2. sayfanın "uzay, korsanlar" vaadi motorda
/// olmadığı için kalktı. `MPGlowBackground` gradient olduğu için kullanılmaz.
///
/// "Önce masal" (`MPRemoteFlags.storyBeforeAccount`, hukuk onayına kadar kapalı):
/// açıkken çocuğun adı ve yaşı burada sorulur, ilk masal girişten önce yazılır.
/// Kapalıyken bugünkü sıra: karşılama → giriş → onay → profil → ilk masal.
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool

    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var name = ""
    @State private var band: AgeBand = AgeBandResolver.bands[1]
    @FocusState private var nameFocused: Bool

    private var storyFirst: Bool { MPRemoteFlags.value(.storyBeforeAccount, default: false) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MPSpacing.xl) {
                MascotImage(mascot: .onBook, width: typeSize.isAccessibilitySize ? 80 : 160)
                    .padding(.top, MPSpacing.xxl)
                    .accessibilityHidden(true)

                VStack(spacing: MPSpacing.md) {
                    Text("Her çocuğun kendi masal dünyası")
                        .mpText(.cover).foregroundStyle(MPColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(storyFirst ? "Adını söyle, ilk masalı birlikte yazalım. Kahramanı o olsun."
                                    : "Kahramanı çocuğun olan masallar. Her akşam yeniden yazılır, kitaplığında kalır.")
                        .mpText(.body).foregroundStyle(MPColor.textSecondary)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                if storyFirst { childFields }

                VStack(spacing: MPSpacing.sm) {
                    MPButton(title: storyFirst ? "Masalı yaz" : "Başlayalım",
                             systemImage: storyFirst ? "wand.and.sparkles" : nil,
                             size: .hero, fullWidth: true, action: start)
                        .disabled(storyFirst && trimmedName.isEmpty)
                    Text(OnboardingCopy.trust)
                        .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxl)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(MPColor.backgroundKid.ignoresSafeArea())
    }

    // MARK: - Önce masal: ad ve yaş

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var childFields: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            MPTextField(label: nil, placeholder: "Çocuğun adı", text: $name)
                .focused($nameFocused)
                .textContentType(.givenName)
                .submitLabel(.done)
                .accessibilityLabel("Çocuğun adı")
            MPFlowLayout(spacing: MPSpacing.sm) {
                ForEach(AgeBandResolver.bands, id: \.self) { option in
                    MPChip(title: "\(option.lowerBound)-\(option.upperBound) yaş",
                           isSelected: option == band, height: MPSize.chipHeightKid) {
                        MPHaptics.selection()
                        band = option
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Yaş")
        }
    }

    private func start() {
        MPHaptics.tap()
        if storyFirst {
            // İlk profil burada kurulur; ilk masal ContentView'da, karşılama adıyla açılır.
            let profile = profileManager.createProfile(name: trimmedName, age: band.upperBound, profileType: .child)
            profileManager.switchProfile(to: profile)
            UserDefaults.standard.set(profile.name, forKey: MPWelcome.pendingKey)
        }
        profileManager.completeOnboarding()
        isOnboardingComplete = true
    }
}

/// Karşılamanın güven cümlesi: yalnızca doğru olanlar (Faz 8).
enum OnboardingCopy {
    static let trust = "Reklam yok, satın alma çocuğa kapalı. Masallar cihazda yazılır."
}

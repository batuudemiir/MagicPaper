import SwiftUI

/// Profil oluşturma — 03-SCREENS.md §2.
/// MagicPaper çocuk fotoğrafı istemez ve saklamaz; kimlik bir harf madalyonudur.
struct ProfileCreationView: View {
    enum Mode { case first, addAnother }

    var mode: Mode = .first
    var onCreated: ((String) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profileManager = ProfileManager.shared

    @State private var name = ""
    @State private var colorIndex = 0
    @State private var ageRange: MPAgeRange = .r56
    @State private var interestChoices: [InterestChoice] = []
    @State private var interests: [String] = []

    /// `UserProfile.mpColor` ile aynı kümedir; indeks `UserDefaults`'ta
    /// saklandığı için iki taraf da `MP.C.avatarAccents` okumalı.
    private let palette: [Color] = MP.C.avatarAccents

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        VStack(spacing: 0) {
            MPNavBar(
                title: mode == .first ? "İlk profil" : "Yeni profil",
                onBack: mode == .first ? nil : { dismiss() }
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    MPAvatar(name: trimmedName.isEmpty ? "?" : trimmedName,
                             color: palette[colorIndex], size: 88, ring: true)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    MPInput(
                        label: "Çocuğunun adı ne?",
                        hint: "Masalda bu isim geçecek",
                        placeholder: "Örn. Elif",
                        text: $name,
                        symbol: "person.crop.circle",
                        maxLength: 20
                    )

                    colorPicker
                    agePicker
                    if ChildInterests.isShown(interestChoices) {
                        interestPicker
                    }
                    privacyNote
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.bottom, 24)
            }

            LegacyMPButton(
                title: mode == .first ? "Profili oluştur" : "Profili ekle",
                size: .lg,
                fullWidth: true,
                isDisabled: trimmedName.isEmpty
            ) {
                create()
            }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.bottom, 12)
        }
        .mpScreenBackground()
        .onAppear { interestChoices = StoryChoiceSources.current.interestChoices() }
    }

    /// "Neleri sever?" (FAZ 12). İsteğe bağlı: hiç seçmeden de profil oluşur.
    private var interestPicker: some View {
        VStack(alignment: .leading, spacing: MP.S.x3) {
            VStack(alignment: .leading, spacing: MP.S.x1) {
                Text(InterestCopy.question)
                    .font(MP.F.labelMD())
                    .foregroundStyle(MP.C.textTitle)
                Text(InterestCopy.questionHint)
                    .font(MP.F.caption(.regular))
                    .foregroundStyle(MP.C.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            InterestChipGrid(choices: interestChoices, selection: $interests)
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Avatar rengi")
                .font(MP.F.labelMD())
                .foregroundStyle(MP.C.textTitle)

            HStack(spacing: 10) {
                ForEach(palette.indices, id: \.self) { i in
                    Button {
                        withAnimation(MP.M.gated(MP.M.spring)) { colorIndex = i }
                    } label: {
                        Circle()
                            .fill(palette[i])
                            .frame(width: 40, height: 40)
                            .overlay {
                                if colorIndex == i {
                                    ZStack {
                                        Circle().strokeBorder(palette[i], lineWidth: 3).padding(-6)
                                        Circle().strokeBorder(MP.C.surfaceApp, lineWidth: 3).padding(-3)
                                    }
                                }
                            }
                            .background {
                                if colorIndex != i {
                                    Circle().fill(MP.C.edgeCircle).offset(y: 3)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Avatar rengi \(i + 1)")
                    .accessibilityAddTraits(colorIndex == i ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }

    private var agePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Yaş aralığı")
                .font(MP.F.labelMD())
                .foregroundStyle(MP.C.textTitle)

            MPWrapRow(spacing: 10) {
                ForEach(MPAgeRange.allCases) { range in
                    LegacyMPChip(title: range.title, isSelected: ageRange == range) {
                        withAnimation(MP.M.gated(MP.M.easeOut)) { ageRange = range }
                    }
                }
            }
        }
    }

    private var privacyNote: some View {
        Text("MagicPaper çocuk fotoğrafı istemez ve saklamaz — sadece bir isim ve avatar rengi.")
            .font(MP.F.caption(.regular))
            .lineSpacing(12 * 0.5)
            .foregroundStyle(MP.C.textFaint)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func create() {
        let finalName = trimmedName
        // Use the returned profile rather than `profiles.last`, which is only
        // the one just created for as long as creation happens to append.
        let created = profileManager.createProfile(
            name: finalName,
            age: ageRange.representativeAge,
            profileType: .child,
            interests: ChildInterests.merging(stored: [], edited: interests, choices: interestChoices)
        )
        UserProfile.storeColorIndex(colorIndex, for: created.id)
        if mode == .addAnother {
            profileManager.switchProfile(to: created)
        }

        if mode == .first {
            // Akış 1: örnek masallar yeni ada uyarlanır ve ana sayfada
            // "{Ad} için hazırız" toast'ı gösterilir.
            StoryGenerationManager.shared.adoptSampleStories(
                childName: finalName,
                childProfileID: created.id
            )
            UserDefaults.standard.set(finalName, forKey: MPWelcome.pendingKey)
        }

        onCreated?(finalName)
        if mode == .addAnother { dismiss() }
    }
}

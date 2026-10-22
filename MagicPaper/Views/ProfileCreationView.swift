import SwiftUI

/// 07 · Çocuk profili + 08 · Neleri sever (`ProfilOlusturma`, `NeleriSever`).
/// Tasarımın yaş aralıkları (5-7, 8-10, 11-12) yerine motorun bantları
/// (3-4 / 5-6 / 7-8 / 9-10); ilgi seçimi isteğe bağlı, en fazla üç (FAZ 12).
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

    /// 07 → 08. "Neleri sever" yalnızca katalog yeterince ilgi sunuyorsa
    /// (FAZ 12 eşiği) ikinci adım olur; yoksa 07'den profil oluşur.
    @State private var step = 1

    private var hasInterestStep: Bool { ChildInterests.isShown(interestChoices) }
    private var stepCount: Int { hasInterestStep ? 2 : 1 }
    private var title: String { mode == .first ? "Çocuk profili" : "Yeni profil" }

    var body: some View {
        VStack(spacing: 0) {
            MPTopBar(title: title, subtitle: stepCount > 1 ? "\(step) / \(stepCount)" : nil,
                     onBack: backAction) { EmptyView() }
                .padding(.horizontal, MPSpacing.screenH)

            ScrollView(showsIndicators: false) {
                Group {
                    if step == 1 { profileStep } else { interestStep }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.vertical, MPSpacing.lg)
            }

            VStack(spacing: MPSpacing.sm) {
                if step == 2 {
                    Text("\(interests.count) seçildi")
                        .mpText(.callout)
                        .foregroundStyle(MPColor.textSecondary)
                        .accessibilityAddTraits(.updatesFrequently)
                }
                MPButton(title: "Devam et", fullWidth: true) {
                    if step == 1 && hasInterestStep {
                        withAnimation(MP.M.gated(MP.M.base)) { step = 2 }
                    } else {
                        create()
                    }
                }
                .disabled(trimmedName.isEmpty)
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.vertical, MPSpacing.md)
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .onAppear { interestChoices = StoryChoiceSources.current.interestChoices() }
    }

    private var backAction: (() -> Void)? {
        if step == 2 { return { withAnimation(MP.M.gated(MP.M.base)) { step = 1 } } }
        return mode == .first ? nil : { dismiss() }
    }

    // MARK: 07 · Çocuk profili

    private var profileStep: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xxl) {
            avatar
                .frame(maxWidth: .infinity)

            MPTextField(label: "Çocuğunun adı ne?", placeholder: "Örn. Elif",
                        text: $name, helper: "Masallarda bu isim geçecek")
                .textInputAutocapitalization(.words)
                .onChange(of: name) { _, value in
                    if value.count > 20 { name = String(value.prefix(20)) }
                }

            colorPicker
            agePicker
        }
    }

    private var avatar: some View {
        let color = palette[colorIndex]
        return ZStack {
            Ellipse()
                .fill(color.opacity(0.18))
                .frame(width: 150, height: 134)
                .rotationEffect(.degrees(-18))
            MPInitialAvatar(name: trimmedName, color: color, size: 76)
                .mpShadow(.card)
        }
        .accessibilityHidden(true)
        .animation(MP.M.gated(MP.M.easeOut), value: colorIndex)
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text("Avatar rengi").mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
            HStack(spacing: MPSpacing.md) {
                ForEach(palette.indices, id: \.self) { i in
                    Button {
                        MPHaptics.selection()
                        colorIndex = i
                    } label: {
                        Circle()
                            .fill(palette[i])
                            .frame(width: 40, height: 40)
                            .padding(MPSpacing.xxs)
                            .overlay {
                                if colorIndex == i {
                                    Circle().strokeBorder(palette[i], lineWidth: 3)
                                }
                            }
                    }
                    .buttonStyle(MPPressStyle())
                    .accessibilityLabel("Avatar rengi \(i + 1)")
                    .accessibilityAddTraits(colorIndex == i ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }
        }
    }

    /// Masal yazılmış bantlar; liste katalogdan gelir, buradan değil.
    private var offeredRanges: [MPAgeRange] {
        MPAgeRange.authored(StoryChoiceSources.current.authoredBands())
    }

    /// Henüz masalı yazılmamış bantlar varsa ebeveyne söylenir.
    ///
    /// Sessizce dört chip'ten ikisini kaldırmak, ebeveyne 8 yaşındaki
    /// çocuğunun bu uygulamaya ait olmadığını düşündürür. Cümle eksiği değil
    /// sırayı anlatıyor: önce küçük yaşlar yazılıyor.
    private var ageNote: String? {
        offeredRanges.count < MPAgeRange.allCases.count
            ? "Şimdilik \(offeredRanges.first?.band.lowerBound ?? 3)-\(offeredRanges.last?.band.upperBound ?? 6) yaş için masal yazıyoruz, "
              + "daha büyük yaşların masalları hazırlanıyor."
            : nil
    }

    private var agePicker: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text("Yaş aralığı").mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
            MPWrapRow(spacing: MPSpacing.sm) {
                ForEach(offeredRanges) { range in
                    MPChip(title: range.title, isSelected: ageRange == range) {
                        MPHaptics.selection()
                        ageRange = range
                    }
                }
            }
            Text("Masalın dili ve uzunluğu yaşa göre ayarlanır.")
                .mpText(.caption).fontWeight(.regular)
                .foregroundStyle(MPColor.textSecondary)
            if let ageNote {
                Text(ageNote)
                    .mpText(.caption).fontWeight(.regular)
                    .foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // Varsayılan 5-6, ama sunulmayan bir bant seçili kalmasın: liste
        // içerikten geldiği için varsayılanın da listede olduğu garanti değil.
        .onAppear {
            if !offeredRanges.contains(ageRange) {
                ageRange = offeredRanges.first ?? .r56
            }
        }
    }

    // MARK: 08 · Neleri sever

    private var interestStep: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xl) {
            MascotSays(mascot: .curious,
                       text: "\(trimmedName) neleri sever? En fazla \(ChildInterests.maxSelection) tane seç.")
            InterestChipGrid(choices: interestChoices, selection: $interests)
        }
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

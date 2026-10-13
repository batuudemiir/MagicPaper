import SwiftUI

/// Günlük · Kategoriler (`GunlukKategoriler`): gece moru tam ekran örtü.
///
/// Üstte yaş bandı, ortada kategori listesi, altta kapat. Bir kategoriye
/// dokunmak örtüyü kapatır ve o rafı seçili yaşla açar.
struct GunlukCategoriesView: View {
    let onPick: (ClassicShelf?, MPAgeRange?) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var library = ClassicsLibrary.shared
    @State private var band: MPAgeRange?

    init(onPick: @escaping (ClassicShelf?, MPAgeRange?) -> Void) {
        self.onPick = onPick
        let age = ProfileManager.shared.currentProfile?.age
        _band = State(initialValue: age.map(MPAgeRange.from(age:)))
    }

    /// Boş raf listede durmaz ("Sesli" seslendirme gelene kadar).
    private var shelves: [ClassicShelf] {
        ClassicShelf.allCases.filter { !library.items(in: $0).isEmpty || $0 == .uyku }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            MPColor.backgroundPlum.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ageBands
                    VStack(spacing: 0) {
                        row(title: "Hepsi", shelf: nil)
                        ForEach(shelves) { shelf in row(title: shelf.title, shelf: shelf) }
                    }
                    .padding(.top, MPSpacing.xxxl + 2)
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.top, MPSpacing.xxxl)
                .padding(.bottom, MPSize.minTouchKid * 2 + MPSpacing.sm)
            }

            Button { dismiss() } label: {
                MPIcon("xmark", size: 22, weight: .bold)
                    .foregroundStyle(MPColor.textPrimary)
                    .frame(width: MPSize.minTouchKid, height: MPSize.minTouchKid)
                    .background(MPColor.backgroundSurface, in: Circle())
            }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel("Kapat")
            .padding(.bottom, MPSpacing.xxxl + MPSpacing.md)
        }
        .preferredColorScheme(.dark)
    }

    private var ageBands: some View {
        HStack(spacing: 2) {
            bandButton(nil, "Hepsi")
            ForEach(MPAgeRange.allCases) { range in bandButton(range, range.band.description) }
        }
        .padding(MPSpacing.xxs - 1)
        .background(MPColor.textOnAction.opacity(0.08), in: Capsule())
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func bandButton(_ value: MPAgeRange?, _ label: String) -> some View {
        let on = band == value
        return Button { withAnimation(MP.M.gated(MP.M.easeOut)) { band = value } } label: {
            Text(label).mpText(.footnote).fontWeight(.black)
                .foregroundStyle(on ? MPColor.textPrimary : MPColor.textOnAction.opacity(0.75))
                .lineLimit(1).minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(on ? MPColor.backgroundSurface : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(value.map { "\($0.title)" } ?? "Bütün yaşlar")
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func row(title: String, shelf: ClassicShelf?) -> some View {
        Button { onPick(shelf, band) } label: {
            Text(title)
                .mpText(.title3)
                .fontWeight(.bold)
                .foregroundStyle(MPColor.textOnAction.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: MPSize.minTouchKid)
        }
        .buttonStyle(MPPressStyle())
    }
}

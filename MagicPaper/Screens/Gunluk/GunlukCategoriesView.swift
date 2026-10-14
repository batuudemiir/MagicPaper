import SwiftUI

/// Günlük · Kategoriler (`GunlukKategoriler`): alt sayfa.
///
/// Ana sayfanın dili: krem zemin, yaş bandı segmenti, rafların listesi tek
/// beyaz kartta (pastel simge kutusu, ad, masal sayısı). Bir rafa dokunmak
/// sayfayı kapatır ve o rafı seçili yaşla açar.
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

    private func count(_ shelf: ClassicShelf?) -> Int {
        library.items(in: shelf, ageBand: band).count
            + (shelf == .uyku || shelf == nil ? library.originals(in: .uyku).count : 0)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                HStack {
                    Text("Kategoriler").mpText(.pageTitle).foregroundStyle(MPColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: MPSpacing.sm)
                    GunlukStageButton(systemImage: "xmark", label: "Kapat") { dismiss() }
                }
                .padding(.top, MPSpacing.xl)

                VStack(alignment: .leading, spacing: MPSpacing.sm) {
                    Text("Yaş").mpText(.eyebrow).foregroundStyle(MPColor.textSecondary)
                    MPSegmented(options: [(MPAgeRange?.none, "Hepsi")] + MPAgeRange.allCases.map { (Optional($0), $0.band.description) },
                                selection: $band, track: MPWorldTone.lav.soft)
                }

                GunlukSection(title: "Raflar") {
                    VStack(spacing: 0) {
                        row(title: "Hepsi", symbol: "book", tone: .gray, shelf: nil)
                        ForEach(shelves) { shelf in
                            MPRowDivider()
                            row(title: shelf.title, symbol: shelf.symbol, tone: shelf.tone, shelf: shelf)
                        }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
    }

    private func row(title: String, symbol: String, tone: MPWorldTone, shelf: ClassicShelf?) -> some View {
        let n = count(shelf)
        return Button { onPick(shelf, band) } label: {
            HStack(spacing: MPSpacing.md) {
                MPIcon(symbol, size: MP.G.md, weight: .semibold)
                    .foregroundStyle(tone.deep)
                    .frame(width: MPSize.circleButton, height: MPSize.circleButton)
                    .background(tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                    .accessibilityHidden(true)
                Text(title).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(n)").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                MPIcon("chevron.right", size: MP.G.sm, weight: .bold).foregroundStyle(MPColor.textChevron)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, MPSpacing.lg)
            .frame(minHeight: MPSize.minTouchKid)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel("\(title), \(n) masal")
    }
}

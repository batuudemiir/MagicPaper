import SwiftUI

/// Kitaplığın başındaki raf: çocuğun masalları sırtları görünen kitaplar gibi.
///
/// Soldan sağa eskiden yeniye dizilir, raf gerçek bir raf gibi dolar; açılışta
/// en yeni kitaba kaydırılır. Sırt rengi masalın dünyası, kalınlığı sayfa
/// sayısı, altında künyedeki sıra numarası (`StoryColophon`). Dokununca
/// kapak ızgarasıyla aynı yere gider (Masal aksiyonları). Kapak ızgarası
/// aşağıda tam olarak durduğu için raf ek bir yol değil, bir sahiplik hissi.
struct LibraryShelf: View {

    /// Çocuğun masalları; raf kendi sırasını kurar.
    let stories: [Story]
    let childName: String
    /// Künye sayısı bütün kitaplıktan sayılır (onay bekleyenler dahil).
    let library: [Story]
    let isFavorite: (Story) -> Bool
    let onOpen: (Story) -> Void

    private var shelved: [Story] {
        stories.sorted { $0.createdAt != $1.createdAt ? $0.createdAt < $1.createdAt
                                                        : $0.id.uuidString < $1.id.uuidString }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x3) {
            Text("\(SeriesCopy.genitive(childName)) rafı · \(stories.count) masal")
                .font(MP.F.labelSM())
                .foregroundStyle(MP.C.textMuted)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .bottom, spacing: MP.S.x1) {
                            ForEach(shelved) { story in
                                Button { onOpen(story) } label: {
                                    BookSpine(story: story,
                                              ordinal: StoryColophon.ordinal(of: story, among: library),
                                              isFavorite: isFavorite(story))
                                }
                                .buttonStyle(MPPressStyle())
                                .id(story.id)
                            }
                        }
                        .padding(.horizontal, MP.S.x3)
                    }
                    .onAppear {
                        guard let newest = shelved.last else { return }
                        // Açılışta animasyon yok: raf zaten dolu görünsün.
                        proxy.scrollTo(newest.id, anchor: .trailing)
                    }
                }

                // Raf tahtası.
                Rectangle()
                    .fill(MP.C.surfaceSunken)
                    .frame(height: MP.S.x2)
                    .mpEdge(fill: MP.C.surfaceSunken, edge: MP.C.edgeCard, radius: MP.R.xs)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// Bir kitabın sırtı: dünya tonunda, başlık yan yazılmış, altta sıra numarası.
private struct BookSpine: View {
    let story: Story
    let ordinal: Int
    let isFavorite: Bool

    /// Sırtın boyu; başlık bu boyun içine yan yatar.
    private static let height: CGFloat = MP.S.x10 * 3

    /// Kalınlık sayfa sayısından: ince, orta, kalın. En ince sırt da bir
    /// dokunma alanı kadar.
    private var width: CGFloat {
        switch story.pages.count {
        case ...5: MP.S.tapMin
        case 6...8: MP.S.tapMin + MP.S.x2
        default: MP.S.x10
        }
    }

    private var tone: MPWorldTone { story.mpWorld.tone }

    /// Başlığın yattığı uzunluk: üst bant ve alttaki işaret + sayı payı düşülür.
    private var titleLength: CGFloat { Self.height - MP.S.x4 - MP.S.x8 - MP.S.x2 }

    var body: some View {
        VStack(spacing: 0) {
            // Sırtın üstündeki bant, kitap sırtlarındaki baskı şeridi gibi.
            Rectangle().fill(tone.deep)
                .frame(height: MP.S.x1)
                .padding(.top, MP.S.x3)

            Text(story.title)
                .font(MP.F.labelSM())
                .foregroundStyle(MP.C.textTitle)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: titleLength, height: width)
                .rotationEffect(.degrees(-90))
                .frame(width: width, height: titleLength)

            Spacer(minLength: 0)

            if isFavorite {
                MPIcon("heart.fill", size: MP.G.xs, weight: .semibold)
                    .foregroundStyle(tone.deep)
            }
            Text("\(ordinal)")
                .font(MP.F.caption())
                .foregroundStyle(MP.C.textMuted)
                .padding(.bottom, MP.S.x2)
        }
        .frame(width: width, height: Self.height)
        .mpEdge(fill: tone.soft, edge: tone.deep, radius: MP.R.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ordinal <= 1 ? "\(story.title), ilk masal" : "\(story.title), \(ordinal). masal")
        .accessibilityValue(isFavorite ? "Favori" : "")
        .accessibilityHint("Masalın seçeneklerini açar")
    }
}

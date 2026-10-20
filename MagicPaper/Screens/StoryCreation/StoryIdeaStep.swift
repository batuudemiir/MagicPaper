import SwiftUI

/// Adım 2 (isteğe bağlı) — bu mod içinde neyin etrafında?
///
/// Mod birincil karardır; fikir kartı ikincil kişiselleştirme. Ebeveyn
/// "Bana bırak" diyerek geçebilir ve MagicPaper modun içinden seçer. Bu adımı
/// zorunlu yapmak uygulamayı bir hikâye yapılandırıcısına çevirirdi.
///
/// Kartlar anlatı sözleridir: her biri birkaç farklı hikâyeye dönüşebilir ve
/// hangisi olacağına motor karar verir. Burada hiçbir şey bir dünyayı, bir
/// blueprint'i ya da bir temayı adlandırmaz.
struct StoryIdeaStep: View {

    let mode: StoryMode
    /// Bu modun, bu çocuğun bandındaki fikirleri. Boşsa akış bu adımı atlar.
    let ideas: [StoryIdeaChoice]
    /// Nil "Bana bırak" demek — motor modun içinden seçer.
    let onChoose: (String?) -> Void

    /// §7: küratörlü, menü değil; sayıyı ekran belirler ki değiştirmek içerik
    /// yeniden yazmak anlamına gelmesin.
    private static let shown = 4

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: MP.S.x2) {
                    HStack(spacing: 6) {
                        MPIcon(mode.symbol, size: 16, weight: .semibold)
                        Text(mode.title)
                            .font(MP.F.labelSM())
                        MPIcon("checkmark", size: 14, weight: .bold)
                    }
                    .foregroundStyle(mode.accent)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(mode.title) seçildi")

                    Text("Bugün ne hakkında bir masal yazalım?")
                        .font(MP.F.displayLG())
                        .mpTightTracking(32)
                        .foregroundStyle(MP.C.textTitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, MP.S.x3)
                .padding(.bottom, MP.S.x5)

                VStack(spacing: MP.S.stackGap) {
                    ForEach(ideas.prefix(Self.shown)) { idea in
                        MPChoiceTile(
                            title: idea.title,
                            description: idea.detail,
                            symbol: idea.symbol,
                            accent: mode.accent,
                            layout: .column
                        ) {
                            onChoose(idea.id)
                        }
                        .accessibilityLabel("\(idea.title). \(idea.detail)")
                    }

                    MPChoiceTile(
                        title: "Bana bırak",
                        description: "Bu hikâyeyi biz seçelim.",
                        symbol: "wand.and.stars",
                        accent: MP.C.reward,
                        layout: .column
                    ) {
                        onChoose(nil)
                    }
                }
            }
            .mpGutter()
            .padding(.bottom, MP.S.x6)
        }
    }
}

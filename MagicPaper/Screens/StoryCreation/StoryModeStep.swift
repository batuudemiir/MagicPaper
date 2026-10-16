import SwiftUI

/// 19 · Yarat 1 (`SihirbazNerede`): bu akşam nasıl bir masal?
///
/// Teslimdeki dünya ızgarasının yerinde modlar duruyor (karar 7 Ekim 2026):
/// üç niyet ve "Bana sürpriz yap", pastel kartlarda. Kart seçilir, "Devam
/// et" ilerler. Sürpriz dördüncü bir mod değil: MagicPaper'ın üç moddan
/// birini seçmesi (`StoryModeResolver`), bu yüzden ayrı bir geri çağrı.
///
/// Kurulamayan bir mod gösterilmez: seçildiğinde hiçbir şey üretemeyecek
/// bir kart, verdiği sözü sessizce başka bir masala çevirir.
struct StoryModeStep: View {

    let modes: [StoryMode]
    /// Uyku saatinde öne çıkan mod: ilk sırada ve seçili gelir, diğerleri
    /// serbest (karar 15 Ekim 2026).
    var emphasized: StoryMode? = nil
    var childName: String = ""
    var childColor: Color? = nil
    /// Bir modun bu çocuğa sunulabilecek alt kategorileri (16 Ekim 2026).
    ///
    /// Kapanış olarak veriliyor çünkü liste moda göre değişiyor ve ekran onu
    /// yalnızca seçim yapıldığında soruyor. Boş dönmesi normaldir: alt
    /// kategori bir söz, ve motor yalnızca kurulabilen konuları döndürüyor.
    var topics: (StoryMode) -> [StoryTopicChoice] = { _ in [] }
    /// Seçilen mod ve — varsa — seçilen konunun kimliği.
    let onChoose: (StoryMode, String?) -> Void
    let onSurprise: () -> Void

    private enum Choice: Hashable { case mode(StoryMode), surprise }
    @State private var choice: Choice?
    /// Seçili modun konusu. Mod değişince düşer: "Meslekler" seçip moda geri
    /// dönüp uyku öncesini seçen biri, meslek masalı ısmarlamış olmamalı.
    @State private var topicID: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MPSpacing.lg) {
                VStack(spacing: MPSpacing.sm) {
                    Text("Masal nasıl olsun?")
                        .mpText(.title1).foregroundStyle(MPColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Birini seç, gerisini biz hazırlayalım.")
                        .mpText(.body).foregroundStyle(MPColor.textSecondary)
                        .multilineTextAlignment(.center)
                    if let emphasized {
                        Text("Bu akşam için \(emphasized.title) seçili. İstersen değiştir.")
                            .mpText(.footnote).foregroundStyle(MPColor.actionPrimary)
                            .multilineTextAlignment(.center)
                    }
                }
                if !childName.isEmpty {
                    HStack(spacing: MPSpacing.sm) {
                        MPAvatar(name: childName, color: childColor, size: 32)
                        Text("Kahraman: \(childName)").mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                    }
                    .padding(.leading, MPSpacing.xs).padding(.trailing, MPSpacing.lg)
                    .frame(minHeight: 44)
                    .background(MPColor.backgroundSurface, in: Capsule())
                    .mpShadow(.control)
                    .accessibilityElement(children: .combine)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: MPSpacing.md),
                                    GridItem(.flexible(), spacing: MPSpacing.md)],
                          spacing: MPSpacing.lg) {
                    ForEach(StoryCreationSteps.shownModes(modes, emphasized: emphasized), id: \.self) { mode in
                        WorldTile(title: mode.title, systemImage: mode.symbol, tone: mode.tone,
                                  isSelected: choice == .mode(mode)) {
                            MPHaptics.selection()
                            if choice != .mode(mode) { topicID = nil }
                            choice = .mode(mode)
                        }
                        .accessibilityLabel(mode == emphasized
                            ? "\(mode.title), bu akşam için önerilen. \(mode.promise)"
                            : "\(mode.title). \(mode.promise)")
                    }
                    // Tek bir mod kaldıysa sürprizin seçeceği bir şey yok (K6).
                    if StoryCreationSteps.showsSurprise(availableModes: modes) {
                        WorldTile(title: "Bana sürpriz yap", systemImage: "wand.and.sparkles", tone: .pink,
                                  isSelected: choice == .surprise) {
                            MPHaptics.selection()
                            // Sürprizin konusu sorulmaz: ebeveyn "sen seç"
                            // dedi, konuyu sormak o cümleyi yarıda kesmek olur.
                            topicID = nil
                            choice = .surprise
                        }
                        .accessibilityLabel("Bana sürpriz yap. Bugünün masalını biz seçelim.")
                    }
                }
                .padding(.top, MPSpacing.sm)

                if case .mode(let mode) = choice {
                    topicSection(for: mode)
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .animation(MP.M.gated(MP.M.easeOut), value: choice)
        .onAppear {
            if choice == nil, let emphasized { choice = .mode(emphasized) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MPButton(title: "Devam et", fullWidth: true) {
                switch choice {
                case .mode(let mode): onChoose(mode, topicID)
                case .surprise: onSurprise()
                case nil: break
                }
            }
            .disabled(choice == nil)
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.vertical, MPSpacing.md)
        }
    }

    /// Mod seçilince altında açılan konular.
    ///
    /// Ayrı bir ekran değil, aynı adımın devamı: mod masalın *ne işe
    /// yaradığını* söyler, konu *neyle ilgili olduğunu*, ve ikinci soru ancak
    /// birincisi cevaplandıktan sonra anlam kazanır. Ayrı ekran olsaydı
    /// ebeveyn iki kez "Devam et"e basardı; burada ikinci soru, birincinin
    /// cevabının altında beliriyor.
    ///
    /// Konu **isteğe bağlı**: seçilmeden devam edilebilir, ve seçili çipe
    /// tekrar dokunmak seçimi kaldırır. Bu yüzden ayrıca bir "Farketmez"
    /// kartı yok — seçmemek zaten farketmez demek.
    @ViewBuilder
    private func topicSection(for mode: StoryMode) -> some View {
        let choices = topics(mode)
        if !choices.isEmpty {
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                Text(prompt(for: mode))
                    .mpText(.headline).foregroundStyle(MPColor.textPrimary)
                Text("İstersen seç, istersen bize bırak.")
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                MPWrapRow(spacing: MPSpacing.sm) {
                    ForEach(choices) { topic in
                        MPChip(title: topic.name, systemImage: topic.symbol,
                               isSelected: topicID == topic.id) {
                            MPHaptics.selection()
                            topicID = (topicID == topic.id) ? nil : topic.id
                        }
                        .accessibilityLabel(topic.name)
                        .accessibilityAddTraits(topicID == topic.id ? [.isSelected] : [])
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, MPSpacing.sm)
            .transition(.opacity)
        }
    }

    /// Soru modun sorusunu sürdürüyor: "öğrenelim" dedikten sonra sorulacak
    /// şey "neyi", "maceraya çıkalım" dedikten sonra "nereye". Tek bir "Konu
    /// seç" başlığı ikisine de uymazdı.
    private func prompt(for mode: StoryMode) -> String {
        switch mode {
        case .learning:  return "Neyi öğrenelim?"
        case .adventure: return "Nereye gidelim?"
        case .bedtime:   return "Masal neyle ilgili olsun?"
        }
    }
}

// MARK: - Sunum

/// Modların ekrandaki karşılığı. Motor modun ne *olduğunu* bilir; nasıl
/// göründüğü uygulamanın işi.
extension StoryMode {
    /// Ekrandaki sıra (karar K5, 3 Ekim 2026). Motorun `allCases` sırası
    /// sürprizin eşitlik bozması için sabit kalır; kart, süzgeç ve ana sayfa
    /// sırası buradan okunur.
    static let displayOrder: [StoryMode] = [.bedtime, .learning, .adventure]

    var title: String {
        switch self {
        case .bedtime:   return "Uyku öncesi"
        case .learning:  return "Yeni şeyler öğrenelim"
        case .adventure: return "Maceraya çıkalım"
        }
    }

    var promise: String {
        switch self {
        case .learning:  return "Yeni bir şey keşfedelim."
        case .adventure: return "Birlikte bir maceraya çıkalım."
        case .bedtime:   return "Günü sakin bir hikâyeyle kapatalım."
        }
    }

    var symbol: String {
        switch self {
        case .learning:  return "sparkles"
        case .adventure: return "tent"
        case .bedtime:   return "moon"
        }
    }

    var accent: Color {
        switch self {
        case .learning:  return MP.C.brand
        case .adventure: return MP.C.play
        case .bedtime:   return MP.C.calm
        }
    }
}

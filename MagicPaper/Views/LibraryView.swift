import SwiftUI

/// Kütüphane — çocuğun okuduğu ve okuyacağı her şey.
///
/// Önceki hâli aramayı, üç filtre çipini ve bir kapsam düğmesini her zaman
/// gösteriyordu: içerik başlamadan önce ekranın üçte biri denetimdi. Sekiz
/// masallık bir rafta arama kutusu bir araç değil, bir engel — ve "Görselli"
/// filtresi görselli masal yokken yalnızca boş bir sonuç üretebiliyordu.
///
/// Kural: bir denetim, işe yarayabileceği kadar içerik varken görünür.
struct LibraryView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @StateObject private var favorites = MPFavorites.shared

    enum Filter: String, CaseIterable {
        case all = "Tümü", illustrated = "Görselli", favorite = "Favori"
    }

    @State private var query = ""
    @State private var filter: Filter = .all
    /// Kapsam: yalnızca aktif çocuk ↔ tüm çocuklar.
    @State private var allChildren = false

    /// Aramanın belirdiği eşik. Altında göz zaten hepsini görüyor.
    private static let searchAppearsAt = 8

    var body: some View {
        VStack(spacing: 0) {
            MPNavBar(title: "Kütüphane", subtitle: scopeLine) {
                // Kapsam ikonu tek başına ne yaptığını söylemiyordu. Artık
                // durumu alt başlık yazıyor, düğme yalnızca değiştiriyor.
                if profileManager.profiles.count > 1 {
                    MPIconButton(
                        symbol: allChildren ? "person.2.fill" : "person.crop.circle",
                        label: allChildren ? "Yalnızca \(activeName)" : "Tüm çocuklar"
                    ) {
                        withAnimation(MP.M.gated(MP.M.easeOut)) { allChildren.toggle() }
                    }
                }
            }

            if !controls.isEmpty || showsSearch { filters }

            if visibleStories.isEmpty {
                ScrollView(showsIndicators: false) {
                    emptyState.padding(.top, 20)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if !allChildren, let child = profileManager.currentProfile?.id {
                            SeriesCard(childID: child)
                        }
                        ForEach(visibleStories) { story in
                            MPStoryCard(
                                title: story.title,
                                meta: allChildren ? story.mpMetaWithChild : story.mpMeta,
                                symbol: story.mpSymbol,
                                accent: story.mpAccent,
                                coverTitle: story.mpCoverStyle == .magicPaperMosaic ? nil : story.title,
                                mosaicCover: story.mpCoverStyle == .magicPaperMosaic ? story.mpMosaicCover : nil,
                                status: status(of: story),
                                badge: story.isIllustrated ? "Görselli" : SeriesCopy.episodeBadge(story),
                                badgeTone: story.isIllustrated ? .reward : .neutral,
                                badgeSymbol: story.isIllustrated ? "crown.fill" : "bookmark",
                                progress: (story.mpProgress > 0 && story.mpProgress < 1) ? story.mpProgress : nil,
                                layout: .row
                            ) {
                                app.detailStory = story
                            }
                        }
                    }
                    .padding(.horizontal, MP.S.screenGutter)
                    .padding(.bottom, 24)
                }
            }
        }
        .mpScreenBackground()
    }

    /// Yarıda kalanın kendi göstergesi var (ilerleme çubuğu); burada yalnızca
    /// iki uç işaretleniyor.
    private func status(of story: Story) -> MPStoryCard.Status? {
        // `lastReadPage == nil` ile "ilerleme 0" aynı şey değil: ilki hiç
        // açılmamış, ikincisi açılmış ve ilk sayfasında duruyor. `mpProgress`
        // ikisini de 0 verdiği için onunla ayırt edilemez — ve ayrım tam olarak
        // bu rozetin söylediği şey.
        if story.lastReadPage == nil { return .unread }
        if story.isFinished { return .finished }
        return nil
    }

    private var activeName: String {
        profileManager.currentProfile?.name ?? "Arkadaşım"
    }

    /// Kapsam ve sayı, ikonun söyleyemediği şey.
    private var scopeLine: String {
        let n = scopedStories.count
        let who = allChildren ? "Tüm çocuklar" : activeName
        return n == 0 ? who : "\(who) · \(n) masal"
    }

    // MARK: - Denetimler

    private var showsSearch: Bool { scopedStories.count >= Self.searchAppearsAt }

    /// Yalnızca bir şey seçebilecek filtreler.
    ///
    /// Hiç görselli masal yokken "Görselli" çipi bir seçenek değil, boş bir
    /// sonuç vaadi. Seçili olan çip, sonucu boşalsa bile kalır — yoksa
    /// kullanıcının altından kaybolur.
    private var controls: [Filter] {
        Filter.allCases.filter { f in
            switch f {
            case .all: return false
            case .illustrated: return filter == f || scopedStories.contains { $0.isIllustrated }
            case .favorite: return filter == f || scopedStories.contains { favorites.contains($0.id) }
            }
        }
    }

    private var filters: some View {
        VStack(spacing: 10) {
            if showsSearch {
                MPInput(placeholder: "Masal ara", text: $query, symbol: "magnifyingglass")
            }
            if !controls.isEmpty {
                MPWrapRow(spacing: 10) {
                    LegacyMPChip(title: Filter.all.rawValue, isSelected: filter == .all) {
                        withAnimation(MP.M.gated(MP.M.easeOut)) { filter = .all }
                    }
                    ForEach(controls, id: \.self) { f in
                        LegacyMPChip(title: f.rawValue, isSelected: filter == f) {
                            withAnimation(MP.M.gated(MP.M.easeOut)) { filter = f }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.top, 4)
        .padding(.bottom, 14)
    }

    // MARK: - Boş durumlar

    /// Hiç masal olmamasıyla, arama sonucunun boş olması aynı şey değil: biri
    /// masal yaratmaya davet, diğeri aramayı geri almaya. Tek bir metin ikisine
    /// birden hitap ettiğinde ikisine de etmiyor.
    @ViewBuilder
    private var emptyState: some View {
        if scopedStories.isEmpty {
            MPEmptyState(
                title: allChildren ? "Henüz masal yok" : "\(activeName) için masal yok",
                description: "İlk masalı yaratınca burada belirecek.",
                illustration: "AppLogo",
                actionLabel: "Masal yarat",
                action: { app.startStoryCreation() }
            )
        } else if !query.trimmingCharacters(in: .whitespaces).isEmpty {
            MPEmptyState(
                title: "Eşleşen masal yok",
                description: "\"\(query)\" için bir şey bulamadık.",
                illustration: "AppLogo",
                actionLabel: "Aramayı temizle",
                action: { query = "" }
            )
        } else {
            MPEmptyState(
                title: filter == .favorite ? "Favori masal yok" : "Görselli masal yok",
                description: filter == .favorite
                    ? "Bir masalı kalple işaretleyince burada toplanır."
                    : "Görselli masallar resimleriyle birlikte burada durur.",
                illustration: "AppLogo",
                actionLabel: "Tümünü göster",
                action: { withAnimation(MP.M.gated(MP.M.easeOut)) { filter = .all } }
            )
        }
    }

    // MARK: - Liste

    /// Kütüphaneye giren masallar.
    ///
    /// Onay kapısı en başta uygulanıyor — kapsam ve filtrelerden önce. Kapı
    /// "hangi masallar var" sorusunun cevabını değiştirir; ondan sonra gelen
    /// her şey (çocuk kapsamı, arama, favori) o cevabın üzerinde çalışır.
    /// Sonda uygulansaydı boş durum metni bile yanlış sayardı.
    private var scopedStories: [Story] {
        let allowed = MPStoryGate.visible(
            storyManager.stories,
            approvalRequired: settings.approve,
            isApproved: { settings.isApproved($0) }
        )
        guard !allChildren, let active = profileManager.currentProfile else {
            return allowed
        }
        return allowed.filter { $0.belongs(to: active) }
    }

    private var visibleStories: [Story] {
        var list = scopedStories

        switch filter {
        case .all: break
        case .illustrated: list = list.filter { $0.isIllustrated }
        case .favorite: list = list.filter { favorites.contains($0.id) }
        }

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            // Türkçe locale ile küçük harfe çevrilir — i/ı ayrımı için zorunlu.
            let needle = MPText.foldedForSearch(trimmed)
            list = list.filter {
                MPText.foldedForSearch($0.title).contains(needle)
                || MPText.foldedForSearch($0.childName).contains(needle)
            }
        }
        return list
    }
}

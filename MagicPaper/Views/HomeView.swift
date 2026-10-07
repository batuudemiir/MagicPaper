import SwiftUI

/// Ana sayfa.
///
/// Bu ekran **tek bir soruya** cevap verir: *şimdi ne okuyoruz?*
///
/// Önceki hâli üç ayrı "masal yarat" girişi taşıyordu — hero kartı, alt bardaki
/// artı düğmesi ve "Masal dünyaları" şeridi. Hero ile artı düğmesi birebir aynı
/// eylemi yapıyordu; şerit ise farklı ve eski bir akışa gidiyordu. Üç giriş, iki
/// hedef, tek iş. Bir kullanıcı "hangisi doğru olan?" diye sormak zorunda
/// kalıyorsa cevap hiçbiri değildir.
///
/// Ayrıca ekran kendi içeriğine sahip değildi: son masallar Kütüphane'nin işi,
/// seri kartı Günlük'ün işi, dünyalar yaratmanın işi. Ana sayfa diğer üç
/// sekmenin menüsüydü ve çocuğun geri geldiği şey — kendi masalları — iki
/// tanıtım bloğunun altında, ekranın dışında kalıyordu.
///
/// Şimdi sıralama şu: önce çocuğun kaldığı yer, sonra kendi masalları, en
/// sonda alışkanlık. Yaratma eylemi tek bir yerde duruyor: alt bardaki artı.
/// Her yerden erişilir ve tektir.
struct HomeView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var streak = MPStreak.shared
    @State private var shelfFilter: MPShelfFilter = .all
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    tonight
                    if let child = profileManager.currentProfile?.id {
                        SeriesCard(childID: child)
                    }
                    modeCards
                    storiesSection
                    streakRow
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .mpScreenBackground()
    }

    // MARK: - Başlık satırı

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                app.sheet = .profilePicker
            } label: {
                HStack(spacing: 10) {
                    MPAvatar(name: activeName, color: profileManager.currentProfile?.mpColor, size: 44)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(greeting)
                            .font(MP.F.labelSM())
                            .foregroundStyle(MP.C.textMuted)
                        HStack(spacing: 4) {
                            Text(activeName)
                                .font(MP.F.displaySM())
                                .foregroundStyle(MP.C.textTitle)
                                .lineLimit(1)
                            MPIcon("chevron.down", size: 17, weight: .semibold)
                                .foregroundStyle(MP.C.textFaint)
                        }
                    }
                }
            }
            .buttonStyle(MPPressStyle(scales: false))

            Spacer(minLength: 0)

            // Mod anahtarı. Görselli masal hakkını gösteren yıldız hapı buradaydı
            // ve dokununca ödeme duvarını açıyordu — çocuk modunda, çocuğun
            // parmağının altında bir satın alma kapısı. Kalan hak artık
            // Ebeveyn tarafında, istatistiklerde ve abonelik kartında.
            MPModeSwitch(isParent: false) { parent in
                if parent { app.requestParentMode() }
            }
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.vertical, 4)
    }

    private var activeName: String {
        profileManager.currentProfile?.name ?? "Arkadaşım"
    }

    /// Saate göre selam.
    ///
    /// "Merhaba" günün her saati aynı şeyi söyler, yani hiçbir şey söylemez.
    /// Bu bir uyku masalı uygulaması: akşam açılması tesadüf değil, kullanımın
    /// kendisi. Selamın saati bilmesi hem sıcak hem doğru — akşam açan bir
    /// ebeveyne "günaydın" demek, ürünün ne için var olduğunu bilmemek olurdu.
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11:  return "Günaydın,"
        case 11..<17: return "İyi günler,"
        case 17..<22: return "İyi akşamlar,"
        default:      return "İyi geceler,"
        }
    }

    // MARK: - Bu akşam

    /// Bu çocuğun, çocuğun görmeye hakkı olan masalları.
    ///
    /// Onay kapısı burada da geçerli — ve burada geçerli OLMASAYDI kapı hiçbir
    /// işe yaramazdı: Kütüphane'den gizlenen bir masal "kaldığın yer" kartında
    /// ekranın en tepesinde durabilirdi.
    private var myStories: [Story] {
        MPStoryGate.visible(
            storyManager.stories,
            approvalRequired: settings.approve,
            isApproved: { settings.isApproved($0) }
        )
        .filter { $0.belongs(to: profileManager.currentProfile) }
    }

    /// Yarıda kalmış en son masal. Ekranın birincil yuvası bunun için ayrıldı:
    /// bir masalın ortasında bırakılmışsa, uygulamayı açmanın sebebi neredeyse
    /// her zaman odur.
    ///
    /// Seçim kuralı `MPContinueReading`'de — burada bir satır olarak durduğu
    /// sürece iki kez yanlış yazıldı, ve ikisinde de sessizce yanlış bir masal
    /// gösterdi. Kural artık tek bir yerde ve test edilebiliyor.
    private var unfinished: Story? {
        MPContinueReading.pick(from: myStories)
    }

    @ViewBuilder
    private var tonight: some View {
        if let story = unfinished {
            MPPressableCard(tone: .brand, padding: 22, action: { app.readerStory = story }) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("KALDIĞIN YER")
                        .font(MP.F.caption())
                        .tracking(1.1)
                        .foregroundStyle(Color.white.opacity(0.75))

                    Text(story.title)
                        .font(MP.F.displaySM())
                        .foregroundStyle(MP.C.textOnBrand)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        // İlerleme, sayfa numarası olarak değil çubuk olarak:
                        // okuma öncesi bir çocuk "3/8"i okuyamaz, dolan bir
                        // çubuğu okuyabilir.
                        Capsule().fill(Color.white.opacity(0.28))
                            .frame(height: 8)
                            .overlay(alignment: .leading) {
                                GeometryReader { geo in
                                    Capsule().fill(Color.white)
                                        .frame(width: max(8, geo.size.width * story.mpProgress))
                                }
                            }
                        Text("Devam et")
                            .font(MP.F.labelMD())
                            .foregroundStyle(MP.C.textOnBrand)
                        MPIcon("arrow.right", size: 18, weight: .semibold)
                            .foregroundStyle(MP.C.textOnBrand)
                    }
                }
            }
            .accessibilityLabel("\(story.title), kaldığın yerden devam et")
        } else if myStories.isEmpty {
            // YALNIZCA ilk açılışta.
            //
            // Devam edilecek bir şey yokken bu kartı her zaman göstermek, az
            // önce kaldırdığım kusuru geri getiriyordu: ekranın en büyük kartı
            // "masal yarat" diyor, otuz piksel altındaki hap da "masal yarat"
            // diyordu. Aynı eylem iki kez, biri diğerinden daha doğruymuş gibi.
            //
            // Rafında masalı olan bir çocuğun ana sayfası zaten dolu; yaratma
            // eylemi hapta duruyor ve her ekrandan erişilebilir. Hiç masalı
            // olmayan biri içinse hap fazla sessiz — ilk kez gelen birine ne
            // yapacağını söylemek gerekiyor, ve söyleyecek başka bir şey de yok.
            MPPressableCard(tone: .brand, padding: 22, action: { app.startStoryCreation() }) {
                HStack(spacing: 16) {
                    MPIcon("wand.and.stars", size: 28, weight: .semibold)
                        .foregroundStyle(MP.C.textOnBrand)
                        .frame(width: 54, height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.2))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("İlk masalını yaratalım")
                            .font(MP.F.displaySM())
                            .foregroundStyle(MP.C.textOnBrand)
                        Text("İki seçim yap, gerisini biz yazalım")
                            .font(MP.F.bodySM(.semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    MPIcon("arrow.right", size: 22, weight: .semibold)
                        .foregroundStyle(MP.C.textOnBrand)
                }
            }
        }
    }

    // MARK: - Mod kartları

    /// Dünya şeridinin yerinde (karar K8, 3 Ekim 2026): dünya seçimi kalktı,
    /// ebeveynin ilk kararı mod. Kart o kararı burada verdirir ve akışı
    /// doğrudan "Masalda kimler olsun?" adımından açar.
    ///
    /// Yalnızca bu çocuğun bandında kurulabilen modlar, ekran sırasıyla.
    /// Sürpriz burada yok: o, akışın birinci adımında.
    private var shownModes: [StoryMode] {
        let age = profileManager.currentProfile?.age ?? AgeBandResolver.mvp.upperBound
        return StoryCreationSteps.shownModes(StoryChoiceSources.current.availableModes(forAge: age))
    }

    @ViewBuilder
    private var modeCards: some View {
        if !shownModes.isEmpty {
            VStack(alignment: .leading, spacing: MP.S.x4) {
                LegacyMPSectionHeader(title: "Yeni bir masal",
                                subtitle: "Bu akşam nasıl bir masal olsun?")
                VStack(spacing: MP.S.stackGap) {
                    ForEach(shownModes, id: \.self) { mode in
                        MPChoiceTile(
                            title: mode.title,
                            description: mode.promise,
                            symbol: mode.symbol,
                            accent: mode.accent,
                            // Sütun: metin kartın tüm genişliğini alır. Satır
                            // düzeninde ikon ve seçim dairesi en büyük yazı
                            // boyutunda "öğrenelim"i kelime ortasından
                            // bölüyordu; kart bir seçim değil, bir eylem.
                            layout: .column
                        ) {
                            app.startStoryCreation(mode: mode)
                        }
                        .accessibilityLabel("\(mode.title). \(mode.promise)")
                        .accessibilityHint("Masalda kimlerin olacağını seçmeye geçer")
                    }
                }
            }
        }
    }

    // MARK: - Çocuğun kendi masalları

    /// Süzgeçten önceki raf.
    private var shelfBase: [Story] {
        // Kaldığı yer zaten yukarıda duruyor; rafta ikinci kez göstermek
        // ekranın en değerli iki yuvasını aynı masala harcamak olurdu.
        myStories.filter { $0.id != unfinished?.id }
    }

    private var shelfFilters: [MPShelfFilter] { MPShelfFilter.available(in: shelfBase) }

    /// Seçili süzgeç artık rafta yoksa (o moddaki tek masal silindiyse)
    /// "Hepsi"ye düşülür; boş bir raf göstermek yerine.
    private var activeFilter: MPShelfFilter {
        shelfFilters.contains(shelfFilter) ? shelfFilter : .all
    }

    private var shelf: [Story] {
        Array(shelfBase.filter(activeFilter.admits).prefix(6))
    }

    @ViewBuilder
    private var storiesSection: some View {
        if !shelf.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                LegacyMPSectionHeader(title: "\(activeName)'in masalları",
                                actionLabel: "Tümü",
                                action: { app.tab = .library })

                if !shelfFilters.isEmpty { filterRow }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(shelf) { story in
                            MPStoryCard(
                                title: story.title,
                                meta: story.mpMeta,
                                symbol: story.mpSymbol,
                                accent: story.mpAccent,
                                coverTitle: story.mpCoverStyle == .magicPaperMosaic ? nil : story.title,
                                mosaicCover: story.mpCoverStyle == .magicPaperMosaic ? story.mpMosaicCover : nil,
                                coverAsset: story.mpKitCoverAsset,
                                badge: story.isIllustrated ? "Görselli" : nil,
                                progress: nil,
                                layout: .shelf
                            ) {
                                app.detailStory = story
                            }
                            .accessibilityLabel("\(story.title). Masalın sayfasını aç")
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, MP.S.screenGutter)
                    .padding(.bottom, 6)
                }
                .scrollClipDisabled()
                .padding(.horizontal, -MP.S.screenGutter)
            }
        }
    }

    /// Mod hapları. Yalnızca rafta birden fazla mod varken görünür.
    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MP.S.x2) {
                ForEach(shelfFilters, id: \.self) { filter in
                    LegacyMPChip(title: filter.title, symbol: filter.symbol,
                           isSelected: filter == activeFilter) {
                        guard filter != activeFilter else { return }
                        MPHaptics.selection()
                        withAnimation(reduceMotion ? MP.M.easeOut : MP.M.base) {
                            shelfFilter = filter
                        }
                    }
                    .accessibilityAddTraits(filter == activeFilter ? .isSelected : [])
                }
            }
            .padding(.horizontal, MP.S.screenGutter)
        }
        .scrollClipDisabled()
        .padding(.horizontal, -MP.S.screenGutter)
    }

    // MARK: - Alışkanlık

    /// Seri, kart değil satır.
    ///
    /// Günlük kendi sekmesine geri döndü, dolayısıyla bugünün masalı orada
    /// duruyor ve burada tekrarlanmıyor. Geriye alışkanlığın tek satırlık
    /// özeti kalıyor: haftanın yedi noktası, ve dokununca Günlük sekmesi.
    /// Eskiden buradaki kart Günlük'ün birebir kopyasıydı ve üstünde o sekmeye
    /// giden ayrı bir düğme vardı — ana sayfanın bir bölümü, başka bir sekmenin
    /// reklamıydı.
    private var streakRow: some View {
        Button { app.tab = .daily } label: {
            HStack(spacing: 12) {
                MPIcon("book", size: 18, weight: .semibold)
                    .foregroundStyle(streak.readToday ? MP.C.play : MP.C.textFaint)
                // Sakin süreklilik dili (CLAUDE.md §7): bir seri değil,
                // birlikte geçen günler.
                Text(streak.currentStreak > 1
                     ? "\(streak.currentStreak) gün üst üste birlikte okudunuz"
                     : "Okuma yolculuğunuz devam ediyor")
                    .font(MP.F.labelMD())
                    .foregroundStyle(MP.C.textBody)

                Spacer(minLength: 0)

                // Haftanın yedi noktası. Sayı yerine nokta, çünkü bu satırın
                // işi bir değeri bildirmek değil, boşluğu göstermek.
                HStack(spacing: 5) {
                    ForEach(Array(streak.thisWeek.enumerated()), id: \.offset) { _, done in
                        Circle()
                            .fill(done ? MP.C.play : MP.C.borderStrong)
                            .frame(width: 8, height: 8)
                    }
                }
                MPIcon("chevron.right", size: 14, weight: .semibold)
                    .foregroundStyle(MP.C.textFaint)
            }
            .padding(.horizontal, MP.S.x4)
            .frame(minHeight: MP.S.tapMin)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: MP.R.md, style: .continuous)
                    .fill(MP.C.surfaceSunken)
            )
        }
        .buttonStyle(MPPressStyle(scales: false))
        .accessibilityLabel(streak.currentStreak > 1
            ? "\(streak.currentStreak) gün üst üste birlikte okudunuz. Günlük sekmesini aç"
            : "Okuma yolculuğunuz devam ediyor. Günlük sekmesini aç")
    }
}

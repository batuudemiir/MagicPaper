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
/// Şimdi sıralama şu: önce çocuğun kaldığı yer, sonra kendi masalları, sonra
/// alışkanlık, en sonda görselli masal yolu. Yaratma eylemi tek bir yerde
/// duruyor: alt bardaki artı. Her yerden erişilir ve tektir.
struct HomeView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var streak = MPStreak.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    tonight
                    storiesSection
                    streakRow
                    illustratedPath
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
                        Text("Merhaba,")
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

            // Sayı tek başına bir birim değil. "3" bir ebeveyne hiçbir şey
            // söylemiyordu; neyin üçü olduğu ancak ödeme duvarına girince
            // anlaşılıyordu — yani satın alma kararının isteneceği yerde.
            Button { app.openPaywall() } label: {
                HStack(spacing: 6) {
                    MPIcon("star.fill", size: 15, weight: .bold)
                    Text("\(starCount) görselli masal")
                        .font(MP.F.labelSM())
                        .lineLimit(1)
                }
                .foregroundStyle(MP.C.premiumInk)
                .padding(.horizontal, MP.S.x3)
                .frame(height: 34)
                .background(
                    Capsule(style: .continuous).fill(MP.C.rewardSoft)
                )
                .overlay(
                    Capsule(style: .continuous).stroke(MP.C.reward.opacity(0.45), lineWidth: 1.5)
                )
            }
            .buttonStyle(MPPressStyle(scales: false))
            .accessibilityLabel("\(starCount) görselli masal hakkın kaldı")
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.vertical, 4)
    }

    private var activeName: String {
        profileManager.currentProfile?.name ?? "Arkadaşım"
    }

    private var starCount: Int {
        subscriptionManager.isPremium
            ? subscriptionManager.remainingImageStories
            : subscriptionManager.freeTrialCount
    }

    // MARK: - Bu akşam

    private var myStories: [Story] {
        storyManager.stories.filter { $0.belongs(to: profileManager.currentProfile) }
    }

    /// Yarıda kalmış en son masal. Ekranın birincil yuvası bunun için ayrıldı:
    /// bir masalın ortasında bırakılmışsa, uygulamayı açmanın sebebi neredeyse
    /// her zaman odur.
    private var unfinished: Story? {
        myStories.first { $0.mpProgress > 0 && $0.mpProgress < 1 }
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
        } else {
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
                        Text(myStories.isEmpty ? "İlk masalını yaratalım" : "Yeni bir masal yarat")
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

    // MARK: - Çocuğun kendi masalları

    private var shelf: [Story] {
        // Kaldığı yer zaten yukarıda duruyor; rafta ikinci kez göstermek
        // ekranın en değerli iki yuvasını aynı masala harcamak olurdu.
        Array(myStories.filter { $0.id != unfinished?.id }.prefix(6))
    }

    @ViewBuilder
    private var storiesSection: some View {
        if !shelf.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                MPSectionHeader(title: "\(activeName)'in masalları",
                                actionLabel: "Tümü",
                                action: { app.tab = .library })

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(shelf) { story in
                            MPStoryCard(
                                title: story.title,
                                meta: story.mpMeta,
                                symbol: story.mpSymbol,
                                accent: story.mpAccent,
                                badge: story.isIllustrated ? "Görselli" : nil,
                                progress: nil,
                                layout: .shelf
                            ) {
                                app.sheet = .storyActions(story.id)
                            }
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

    // MARK: - Alışkanlık

    /// Seri, kart değil satır.
    ///
    /// Eskiden Günlük sekmesindeki kartın birebir kopyasıydı ve üstünde o
    /// sekmeye giden bir "Bak" düğmesi vardı — yani ana sayfanın bir bölümü,
    /// başka bir sekmeye gitmeyi öneren bir reklamdı. Bilgi burada kalır,
    /// gezinme alt bara aittir.
    private var streakRow: some View {
        HStack(spacing: 12) {
            MPIcon("flame.fill", size: 18, weight: .semibold)
                .foregroundStyle(streak.readToday ? MP.C.play : MP.C.textFaint)
            Text(streak.currentStreak > 0
                 ? "\(streak.currentStreak) günlük seri"
                 : "Bugün henüz masal okunmadı")
                .font(MP.F.labelMD())
                .foregroundStyle(MP.C.textBody)
            Spacer(minLength: 0)
            if streak.readToday {
                MPIcon("checkmark.circle.fill", size: 18, weight: .semibold)
                    .foregroundStyle(MP.C.success)
            }
        }
        .padding(.horizontal, MP.S.x4)
        .frame(minHeight: MP.S.tapMin)
        .background(
            RoundedRectangle(cornerRadius: MP.R.md, style: .continuous)
                .fill(MP.C.surfaceSunken)
        )
    }

    // MARK: - Görselli masal yolu

    /// Dünya şeridi burada, en altta ve adıyla duruyor.
    ///
    /// Eski yerinde — hero'nun hemen altında, "Bir dünya seç, gerisini biz
    /// yazalım" alt başlığıyla — hero'nun sözünü neredeyse birebir tekrar
    /// ediyor ama başka bir akışa gidiyordu. Üstelik "dünya", yeni mimarinin
    /// kaldırdığı bir kavram: iki seçimlik akış yeri kendisi seçer.
    ///
    /// Silinmedi çünkü görselli masal yolu hâlâ yalnız buradan geçiyor. Ama
    /// artık ne olduğunu söylüyor ve çocuğun kendi masallarının önüne
    /// geçmiyor.
    private var illustratedPath: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Görselli masal",
                            subtitle: "Resimli bir masal için bir dünya seç")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MP.World.ordered) { world in
                        MPChoiceTile(
                            title: world.name,
                            symbol: world.symbol,
                            accent: world.accent,
                            isLocked: world.isPremium && !subscriptionManager.isPremium,
                            layout: .column
                        ) {
                            if world.isPremium && !subscriptionManager.isPremium {
                                app.openPaywall()
                            } else {
                                app.startWizard(world: world)
                            }
                        }
                        .frame(width: 132)
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

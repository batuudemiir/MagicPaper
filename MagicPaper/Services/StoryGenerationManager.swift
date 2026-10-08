import Foundation
import OSLog
import SwiftUI
import Combine
import StoryEngine

/// `print` reaches the shared device console verbatim. `Logger` redacts
/// interpolated values as `<private>` outside a debugger by default.
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "StoryGenerationManager")

/// Orchestrates the entire story creation workflow
/// Handles background story generation with status updates
@MainActor
class StoryGenerationManager: ObservableObject {
    
    static let shared = StoryGenerationManager()
    
    // MARK: - Published Properties
    
    @Published var stories: [Story] = []
    @Published var isGenerating: Bool = false
    
    // MARK: - Private Properties
    
    private let fileManager = FileManagerService.shared
    
    private init() {
        // Before anything reads the library: the migration needs the legacy
        // store exactly as the last launch left it, and it is the only thing
        // allowed to touch the `stories` key besides `save`/`load` below.
        LibraryPersistence.bootstrap()
        loadStories()
        auditStoriesMissingImageURLs()
        createSampleStoriesIfNeeded()
    }
    
    // MARK: - Persistence
    
    private func saveStories() {
        do {
            let encoded = try JSONEncoder().encode(stories)
            let dataSize = encoded.count
            logger.debug("💾 Saving stories to UserDefaults: \(dataSize) bytes (\(dataSize / 1024) KB)")

            // Check if size is reasonable (< 1MB for UserDefaults)
            if dataSize > 1_000_000 {
                logger.warning("⚠️ WARNING: Stories data is large (\(dataSize / 1024 / 1024) MB). Consider cleanup.")
            }

            UserDefaults.standard.set(encoded, forKey: "stories")
            // Keep the verified copy on disk in step with the write that just
            // happened, deletions included. Does nothing until the migration
            // has verified; never the source of a failure here, because this
            // store is still the authoritative one.
            LibraryPersistence.reconcileAfterWrite(stories: stories)
        } catch {
            // Önceden `try?` idi: kodlama başarısız olduğunda hiçbir şey
            // yazılmıyor ve hiçbir şey söylenmiyordu. Kütüphane o andan sonra
            // sessizce kalıcılığını yitiriyor, uygulama kusursuz çalışmaya
            // devam ediyor ve kayıp ancak bir sonraki açılışta görülüyordu.
            assertionFailure("Masallar kaydedilemedi: \(error)")
            logger.error("🛑 Masallar KAYDEDİLEMEDİ, bu oturumdaki değişiklikler kaybolacak: \(String(describing: error))")
        }
    }
    
    private func loadStories() {
        guard let data = UserDefaults.standard.data(forKey: "stories") else { return }
        do {
            stories = try JSONDecoder().decode([Story].self, from: data)
            logger.debug("✅ Loaded \(self.stories.count) stories from UserDefaults")
        } catch {
            // Bu, uygulamadaki en pahalı sessiz arıza yoluydu.
            //
            // Çözümleme başarısız olunca `stories` boş kalıyor, hemen ardından
            // `createSampleStoriesIfNeeded()` örnekleri kuruyor ve ilk kayıtta
            // gerçek kütüphanenin üstüne yazıyordu. Tek bir bozuk kayıt —
            // tanınmayan bir enum değeri yeter — bir çocuğun bütün masallarını
            // götürüyor, yerine üç örnek koyuyor ve kimseye bir şey söylemiyor.
            //
            // Ham veri artık tarihli bir anahtara alınıyor. Hâlâ ekranda
            // görünmüyor, ama geri getirilebilir: kurtarılamayan bir kayıp ile
            // kurtarılabilir bir kayıp arasındaki fark, kullanıcının o çocuğun
            // ebeveyni olması.
            //
            // The backup itself had no second half. Each failure minted a new
            // dated key and nothing ever read one, pruned one, or told anyone
            // they existed — a store that only grows, inside the store whose
            // size is already the problem. It is capped now.
            let backupKey = "stories.undecodable.\(Int(Date().timeIntervalSince1970))"
            UserDefaults.standard.set(data, forKey: backupKey)
            Self.pruneUndecodableBackups(keeping: Self.undecodableBackupLimit)
            assertionFailure("Masallar çözümlenemedi: \(error)")
            logger.error("🛑 Masallar ÇÖZÜMLENEMEDİ. Ham veri '\(backupKey)' altına alındı: \(String(describing: error))")
        }
    }

    /// How many `stories.undecodable.*` blobs to keep.
    ///
    /// More than one because the same fault can strike twice before anyone
    /// looks, and the oldest copy is the one that predates the damage. Not
    /// unbounded, because these are whole libraries and they sit in
    /// `UserDefaults`.
    static let undecodableBackupLimit = 3

    static let undecodableBackupPrefix = "stories.undecodable."

    /// Keeps the newest `limit` recovery blobs and removes the rest.
    static func pruneUndecodableBackups(
        keeping limit: Int,
        in defaults: UserDefaults = .standard
    ) {
        let keys = defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(undecodableBackupPrefix) }
            // The suffix is a unix timestamp, so it sorts newest-first
            // numerically. String order would put "1000000000" after
            // "999999999" and drop the wrong one.
            .sorted { lhs, rhs in
                let l = Int(lhs.dropFirst(undecodableBackupPrefix.count)) ?? 0
                let r = Int(rhs.dropFirst(undecodableBackupPrefix.count)) ?? 0
                return l > r
            }
        for key in keys.dropFirst(max(0, limit)) {
            defaults.removeObject(forKey: key)
            logger.debug("🧹 Eski kurtarma yedeği kaldırıldı: \(key)")
        }
    }
    
    /// Reports stories written before `imageUrl` existed.
    ///
    /// This used to be the tail of `migrateOldStoriesIfNeeded()`. The head of
    /// that function deleted `UserDefaults["stories"]` outright whenever the
    /// blob passed four megabytes — no copy, no confirmation, on a launch —
    /// and set `stories = []` over a child's whole shelf. It has moved to
    /// `LibraryMigration`, which copies the blob to quarantine, reads the copy
    /// back, and then leaves the original alone. Nothing on the launch path
    /// removes user data any more.
    ///
    /// What remains here reads and reports. It never wrote anything.
    private func auditStoriesMissingImageURLs() {
        var needsSave = false
        for (_, story) in stories.enumerated() {
            for (pageIndex, page) in story.pages.enumerated() {
                // If page has no imageUrl but has imageFileName, try to load from file
                if page.imageUrl == nil && page.imageFileName != nil {
                    logger.warning("⚠️ Found page without imageUrl: Story \(story.id) Page \(pageIndex + 1)")
                    logger.debug("   This is an old story that needs migration")
                    needsSave = true
                }
            }
        }
        
        if needsSave {
            logger.warning("⚠️ Found \(self.stories.count) stories that may need imageUrl migration")
            logger.warning("⚠️ These stories will display placeholder images")
            logger.debug("💡 Solution: Delete old stories and create new ones, OR manually add imageUrls")
        }
    }
    
    // MARK: - Public Helpers
    
    func deleteStory(id: UUID) {
        // Delete images from file system
        fileManager.deleteStoryImages(storyId: id)
        // Kendi sesin (FAZ 18): masalla birlikte kayıtları da gider.
        VoiceRecordingStore.shared.deleteRecordings(for: id)
        
        // Remove from array
        stories.removeAll { $0.id == id }
        saveStories()
        
        logger.debug("✅ Story deleted: \(id)")
    }

    /// Deletes several stories with one save — used when a child's profile,
    /// and with it their shelf, is deleted.
    func deleteStories(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        for id in ids {
            fileManager.deleteStoryImages(storyId: id)
            VoiceRecordingStore.shared.deleteRecordings(for: id)
        }
        stories.removeAll { ids.contains($0.id) }
        saveStories()

        logger.debug("✅ \(ids.count) stories deleted")
    }
    
    // Kütüphaneye hikaye ekle (metin/günlük hikayeler için)
    func addStoryToLibrary(_ story: Story) {
        // Aynı ID'ye sahip hikaye varsa güncelle, yoksa ekle
        if let index = stories.firstIndex(where: { $0.id == story.id }) {
            stories[index] = story
        } else {
            stories.insert(story, at: 0)
        }
        saveStories()
        logger.debug("✅ Story added to library: \(story.id)")
    }
    
    /// İlk profil oluşturulduğunda örnek masallar yeni çocuğun adına uyarlanır
    /// (04-STATE-INTERACTIONS.md, akış 1) — aksi hâlde yeni kullanıcının ana
    /// sayfası boş görünür.
    func adoptSampleStories(childName: String, childProfileID: UUID? = nil) {
        guard !childName.isEmpty else { return }
        let samples = ["Zephyr", "Luna"]
        var changed = false
        for index in stories.indices where samples.contains(stories[index].childName) {
            let old = stories[index].childName
            stories[index].childName = childName
            stories[index].childProfileID = childProfileID
            stories[index].title = stories[index].title.replacingOccurrences(of: old, with: childName)
            for pageIndex in stories[index].pages.indices {
                stories[index].pages[pageIndex].text =
                    stories[index].pages[pageIndex].text.replacingOccurrences(of: old, with: childName)
            }
            changed = true
        }
        if changed {
            saveStories()
            logger.debug("✅ Örnek masallar profile uyarlandı")
        }
    }

    /// Okuma ilerlemesini yazar.
    ///
    /// **Anında diske indirilir.** Okuma ilerlemesi, kaybolması en olası
    /// veridir çünkü tam da uygulamanın kapanmasından hemen önce değişir:
    /// çocuk son sayfayı çevirir, ebeveyn uygulamadan çıkar. `UserDefaults`
    /// yazımı tembel; süreç o arada sonlandırılırsa değer hiç diske inmez ve
    /// "kaldığın yer" bir sonraki açılışta yok olur. Ana sayfanın birincil
    /// kartı buna bağlı olduğu için burada bekleyemeyiz.
    ///
    /// Maliyeti bilerek kabul ediliyor: `saveStories()` bütün kütüphaneyi
    /// yeniden kodluyor (~37 KB) ve bu her sayfa çevirmede oluyor. Doğru çözüm
    /// ilerlemeyi kendi küçük deposuna almak, ama o zaman aynı olgunun iki
    /// kaynağı olur — bu projede defalarca canımızı yakan şey. Tek kaynak
    /// kalsın, yazı da gerçekten insin.
    func updateLastReadPage(storyId: UUID, page: Int) {
        guard let index = stories.firstIndex(where: { $0.id == storyId }) else {
            // Sessizce dönüyordu. Okuyucuya kütüphanede olmayan bir masal
            // verildiğinde ilerleme hiçbir yere yazılmıyor, hiçbir şey de
            // söylenmiyordu — okuma çalışıyor, kayıt çalışmıyor, arada fark
            // yok gibi görünüyordu.
            assertionFailure("İlerleme yazılamadı: '\(storyId)' kütüphanede yok.")
            logger.error("🛑 İlerleme yazılamadı: '\(storyId)' kütüphanede yok.")
            return
        }

        guard stories[index].lastReadPage != page else { return }
        stories[index].lastReadPage = page
        stories[index].lastReadAt = Date()
        saveStories()
        // Tembel yazımı zorla indir. `synchronize()` kullanımdan kaldırıldı
        // sayılır ve çoğu yerde gereksizdir; burada gereklidir, çünkü bu değeri
        // yazan an ile sürecin öldüğü an arasında saniyeler olabiliyor.
        UserDefaults.standard.synchronize()

        logger.debug("📖 Updated reading progress for story \(storyId): page \(page)")
    }
    
    /// Masal açıldı — sayfa ilerlemese bile.
    ///
    /// `updateLastReadPage` yalnızca EN İLERİ sayfa değiştiğinde yazar, ki
    /// doğrusu budur: gereksiz yazma bütün `[Story]` dizisini yeniden JSON'a
    /// çevirmek demek. Ama o kural tek başına "en son hangi masalı okudu"
    /// sorusunu yanlış cevaplıyor: 3. sayfada bıraktığı masalı bu akşam açıp
    /// aynı sayfayı tekrar okuyan bir çocuk hiçbir iz bırakmıyor, ve ana sayfa
    /// başka bir masalı "kaldığın yer" diye gösteriyor.
    ///
    /// Açmak da okumaktır. Oturum başına bir yazma.
    func markOpened(storyId: UUID) {
        guard let index = stories.firstIndex(where: { $0.id == storyId }) else { return }
        stories[index].lastReadAt = Date()
        saveStories()
    }

    func getStory(id: UUID) -> Story? {
        return stories.first { $0.id == id }
    }
    
    // MARK: - Sample Stories
    
    private func createSampleStoriesIfNeeded() {
        // Sadece hiç hikaye yoksa örnek hikayeler oluştur
        guard stories.isEmpty else { return }
        
        logger.debug("📚 Creating sample stories...")
        
        let sampleStories = [
            createSampleStory(
                title: "Zephyr'in Sihirli Macerası",
                childName: "Zephyr",
                theme: .fantasy,
                pages: [
                    ("Sihirli Başlangıç", "Zephyr sabah güneşinin ışıklarıyla uyandı. Pencereden içeri süzülen altın renkli ışınlar, odanın her köşesini aydınlatıyordu. Kuşların cıvıltıları ve uzaktan gelen çiçek kokuları, güzel bir günün başlangıcını müjdeliyordu. Zephyr yataktan kalktı ve pencereye koştu. Dışarıda, arka bahçedeki eski meşe ağacının arkasında garip bir ışıltı gördü. 'Bu ne olabilir?' diye düşündü merakla. Kahvaltıda annesine bu konuda bir şey söylemek istedi ama kelimeler boğazında düğümlendi. Belki de önce kendisi keşfetmeliydi. Kahvaltısını hızla bitirip bahçeye koştu. Meşe ağacının arkasına vardığında, gözlerine inanamadı. Orada, ağacın gövdesinde parlayan, mor ve mavi ışıklarla çevrili sihirli bir kapı vardı."),
                    ("Sihirli Krallık", "Zephyr titreyen elleriyle kapının tokmağına dokundu. Kapı yavaşça açıldı ve içeriden tatlı bir melodi duyuldu. Cesaret toplayarak içeri adım attı. Gözlerini açtığında kendini bambaşka bir dünyada buldu. Etrafı konuşan hayvanlarla doluydu. Tavşanlar şapka takıyor, sincaplar dans ediyor, kuşlar şarkı söylüyordu. Uzakta, bulutların arasında yükselen ışıltılı bir kale görünüyordu. 'Hoş geldin Zephyr!' dedi yanından geçen kırmızı bir tilki. Zephyr şaşkınlıkla etrafına bakındı. 'Burası neresi?' diye sordu. 'Burası Sihirli Krallık,' dedi tilki gülümseyerek. 'Seni bekliyorduk. Krallığımızın sana ihtiyacı var.' Zephyr'in aklı karışmıştı ama aynı zamanda heyecan doluydu."),
                    ("Bilge Baykuş", "Yolda ilerlerken, Zephyr etrafındaki muhteşem manzarayı izliyordu. Ağaçlar gökkuşağı renklerindeydi, çiçekler müzik çalıyordu, nehir kristal gibi berraktı. Her şey o kadar güzeldi ki gözlerine inanamıyordu. Kaleye yaklaştıklarında, büyük bir baykuş onları karşıladı. 'Ben Bilge Baykuş,' dedi derin bir sesle. 'Krallığımız büyük bir tehlike altında. Kötü büyücü, krallığın gücünü veren Altın Taç'ı çaldı ve Karanlık Orman'da sakladı. Sadece saf kalpli bir çocuk onu bulabilir.' Zephyr derin bir nefes aldı. 'Ben bulabilirim,' dedi kararlılıkla. Baykuş gülümsedi. 'Biliyordum. İşte sana yardımcı olacak sihirli bir harita ve bir fener.'"),
                    ("Işıltı ile Tanışma", "Zephyr Karanlık Orman'a doğru yola çıktı. Orman gerçekten de karanlıktı ama feneri her şeyi aydınlatıyordu. Yolda ilerlerken, bir ağacın arkasından küçük bir peri çıktı. 'Merhaba! Ben Işıltı,' dedi neşeyle. 'Sana yardım edebilir miyim?' Zephyr gülümsedi. 'Altın Taç'ı arıyorum,' dedi. 'Ah, o çok tehlikeli bir yer!' dedi Işıltı. 'Ama ben sana yol gösterebilirim. Birlikte gidelim!' İkili birlikte yürümeye başladı. Işıltı, Zephyr'e ormanın sırlarını anlattı. Hangi mantarların yenilebileceğini, hangi yolların güvenli olduğunu öğretti. Zephyr yeni arkadaşına çok minnettar oldu. Birlikte her engeli aşabileceklerini biliyordu."),
                    ("Kristal Mağara", "Mağaraya girdiklerinde, her yer karanlıktı. Fener ışığı duvarlarda dans ediyordu. Birden, önlerinde büyük bir uçurum belirdi. 'Nasıl geçeceğiz?' diye sordu Zephyr endişeyle. Işıltı düşündü. 'Sihirli köprü büyüsü yapabilirim ama senin inancına ihtiyacım var. Gözlerini kapat ve geçebileceğimize inan.' Zephyr gözlerini kapattı ve derin bir nefes aldı. İnandı. Işıltı büyüyü yaptı ve aniden altın bir köprü belirdi. Birlikte köprüden geçtiler. Mağaranın derinliklerinde, bir kaide üzerinde parlayan Altın Taç duruyordu. Zephyr heyecanla koştu ama Işıltı onu durdurdu. 'Bekle! Etrafında koruma büyüsü var.' Zephyr yavaşça yaklaştı ve taca dokundu."),
                    ("Zafer Kutlaması", "Zephyr ve Işıltı tacı alıp kaleye geri döndüler. Tüm krallık onları bekliyordu. Kral, tahtından kalktı ve Zephyr'e doğru yürüdü. 'Krallığımızı kurtardın genç kahraman,' dedi gururla. 'Sana nasıl teşekkür etsek az.' Tüm hayvanlar alkışladı ve şarkılar söyledi. Kral, Zephyr'in başına küçük bir taç koydu. 'Bundan böyle sen bu krallığın onursal kahramanısın. İstediğin zaman buraya gelebilirsin.' Zephyr'in gözleri doldu. Hayatının en güzel gününü yaşıyordu. Işıltı ve diğer arkadaşlarıyla dans etti, şarkılar söyledi. Ama yavaş yavaş eve dönme zamanı geliyordu. Vedalaştı ve sihirli kapıdan geçti."),
                    ("Eve Dönüş", "O gece, Zephyr yatağına uzandı ve gününü düşündü. Ne kadar inanılmaz bir macera yaşamıştı! Sihirli bir krallık, konuşan hayvanlar, cesur bir görev... Hepsi gerçekti. Annesi gelip onu öptü. 'İyi geceler tatlım,' dedi. 'Güzel rüyalar gör.' Zephyr gülümsedi. 'Anneciğim, bugün harika bir macera yaşadım,' dedi. Annesi saçlarını okşadı. 'Eminim öyle olmuştur,' dedi sevgiyle. Zephyr gözlerini kapadı. Yarın yine Sihirli Krallık'a gidebileceğini biliyordu. Işıltı ve diğer arkadaşları onu bekliyordu. Belki de yeni bir macera yaşarlardı. Kim bilir, belki de ejderhalarla tanışırdı ya da uçan bir atla gökyüzünde gezinirdi. Mutlu bir gülümsemeyle uykuya daldı.")
                ]
            ),
            
            createSampleStory(
                title: "Luna'nın Uzay Yolculuğu",
                childName: "Luna",
                theme: .space,
                pages: [
                    ("Yıldızlara Bakış", "Luna her gece penceresinden yıldızları izlerdi. Gökyüzündeki sayısız ışık noktası onu büyülerdi. 'Acaba oralarda neler var?' diye düşünürdü. Bir gece, bahçede garip bir ışık gördü. Dışarı çıktığında, küçük ama parlak bir uzay gemisi buldu. Geminin kapısı açıktı ve içeriden davetkar bir ışık sızıyordu. Luna merakla içeri girdi. Kokpit koltuğuna oturduğunda, tüm düğmeler ve ekranlar canlandı. 'Hoş geldin Luna,' dedi geminin bilgisayarı. 'Uzay macerasına hazır mısın?' Luna heyecanla başını salladı. Kemer taktı ve büyük kırmızı butona bastı. Gemi yavaşça yerden kalktı ve gökyüzüne doğru hızla yükselmeye başladı."),
                    ("İlk Gezegen", "Luna ilk gezegenine indi. Her yer mor ve pembe renklerle doluydu. Ağaçlar kristalden, çiçekler ışık saçıyordu. Birden, üç gözlü yeşil bir yaratık belirdi. 'Merhaba! Ben Zyx,' dedi dostça. 'Hoş geldin gezegenmize!' Luna başta korkmuştu ama Zyx'in gülümsemesi onu rahatlattı. 'Ben Luna, Dünya'dan geliyorum,' dedi. Zyx heyecanlandı. 'Dünya! Orası hakkında çok şey duydum. Gel, sana gezegenmizi göstereyim!' İkili birlikte yürüdüler. Zyx, Luna'ya yüzen şehirlerini, müzik çalan çiçeklerini ve gökkuşağı renkli nehirlerini gösterdi. Luna her şeye hayran kalmıştı. Uzayın ne kadar muhteşem olduğunu şimdi anlıyordu."),
                    ("Asteroid Fırtınası", "Bir sonraki gezegene giderken, Luna büyük bir sorunla karşılaştı. Önünde dev bir asteroid fırtınası vardı. Kayalar her yöne savruluyordu. 'Ne yapacağım?' diye düşündü endişeyle. Geminin bilgisayarı devreye girdi. 'Sakin ol Luna. Sensörlerini kullan ve kayaların arasından geç.' Luna derin bir nefes aldı. Ellerini kumandaya koydu ve dikkatle ilerlemeye başladı. Sağa, sola, yukarı, aşağı... Her hareketi önemliydi. Bir kaya gemiye çarpmak üzereyken, Luna hızla manevra yaptı. Kalbi hızla çarpıyordu ama başarıyordu. Sonunda fırtınadan çıktı. 'Başardın Luna!' dedi bilgisayar. Luna gururla gülümsedi."),
                    ("Uzay İstasyonu", "Luna büyük bir uzay istasyonuna vardı. İçerisi farklı gezegenlerden gelen yaratıklarla doluydu. Herkes barış içinde yaşıyor, bilgi paylaşıyor ve birlikte çalışıyordu. Luna bir robot, bir peri ve bir bulut yaratığıyla tanıştı. Hepsi ona kendi dünyalarından bahsetti. Robot, teknoloji gezegeninden geliyordu. Peri, sihir diyarından. Bulut yaratığı ise gaz gezegeninden. 'Uzay çok büyük,' dedi robot. 'Ama hepimiz arkadaşız.' Luna mutluydu. Farklılıkların ne kadar güzel olduğunu öğrenmişti. Birlikte yemek yediler, oyunlar oynadılar ve hikayeler anlattılar. Luna Dünya'dan bahsetti ve herkes büyülenmiş dinledi."),
                    ("Kayıp Gezegen", "Uzay istasyonunda bir alarm çaldı. Bir gezegen yardım istiyordu. Güneşleri sönmek üzereydi ve her yer karanlığa gömülüyordu. 'Yardım etmeliyiz!' dedi Luna. Arkadaşları da katıldı. Hep birlikte o gezegene gittiler. Gezegen gerçekten de karanlıktı ve soğuktu. Halk üzgün ve korkmuştu. Luna düşündü. 'Belki güneşi yeniden ateşleyebiliriz!' Robot teknik bilgisini, peri sihirini, bulut yaratığı enerjisini kullandı. Luna da cesaretini ve umudunu ekledi. Hep birlikte güneşin etrafında bir enerji halkası oluşturdular. Yavaş yavaş güneş parlamaya başladı. Işık geri döndü! Gezegen halkı sevinçle bağırdı. Luna ve arkadaşları kahramandı."),
                    ("Yıldız Festivali", "Gezegeni kurtardıkları için büyük bir festival düzenlendi. Tüm uzaydan yaratıklar geldi. Müzik, dans, ışık gösterileri... Her şey muhteşemdi. Luna hiç bu kadar mutlu olmamıştı. Yeni arkadaşlarıyla dans etti, uzay yemekleri tattı ve yıldızların altında şarkılar söyledi. Kral, Luna'ya özel bir madalya verdi. 'Sen gerçek bir uzay kahramanısın,' dedi. 'Cesaretin ve kalbin sayesinde bir gezegeni kurtardın.' Luna'nın gözleri doldu. Bu macera ona çok şey öğretmişti. Cesaret, dostluk, yardımlaşma... Hepsi çok önemliydi. Gece sonunda, Luna gemisine bindi. Eve dönme zamanı gelmişti."),
                    ("Dünya'ya Dönüş", "Luna Dünya'ya dönerken, pencereden gezegenini izledi. Mavi ve yeşil, bulutlarla kaplı... Ne kadar güzeldi. Bahçeye yumuşak bir şekilde indi. Gemi ışıklarını söndürdü. 'Teşekkürler Luna,' dedi bilgisayar. 'Harika bir pilottun. İstediğin zaman geri gel.' Luna gemiye veda etti ve evine koştu. Yatağına uzandığında, tüm macera bir rüya gibi geldi. Ama cebindeki yıldız madalyası gerçekti. Annesi gelip onu öptü. 'İyi geceler Luna,' dedi. Luna gülümsedi. 'Anneciğim, bugün uzaya gittim,' dedi. Annesi saçlarını okşadı. 'Ne güzel bir hayal,' dedi. Luna gözlerini kapadı. Biliyordu ki bu sadece başlangıçtı. Uzay onu bekliyordu ve daha nice maceralar yaşayacaktı.")
                ]
            )
        ]
        
        stories = sampleStories
        saveStories()
        logger.debug("✅ Sample stories created: \(self.stories.count)")
    }
    
    private func createSampleStory(title: String, childName: String, theme: StoryTheme, pages: [(String, String)]) -> Story {
        let storyPages = pages.map { (pageTitle, pageText) in
            StoryPage(
                title: pageTitle,
                text: pageText,
                imagePrompt: pageText
            )
        }
        
        return Story(
            title: title,
            childName: childName,
            theme: theme,
            language: .turkish,
            status: .completed,
            pages: storyPages
        )
    }
    
}

extension StoryGenerationManager {
    @MainActor
    /// Builds a story from the two choices the new creation flow collects, and
    /// saves it.
    ///
    /// Replaces `createOfflineTextStory`, which took a genre string, a theme
    /// string and hard-coded ids — `setting_forest_001` and
    /// `companion_fox_001` — so every choice the user made was discarded (B3).
    /// Here the choices are stable ids, the seed is kept so the story can be
    /// rebuilt (B5), and a failure is thrown rather than printed (B2).
    ///
    /// Returns the saved story. The caller opens it; nothing here navigates.
    ///
    /// `mode` is already resolved — a surprise has been turned into one of the
    /// three modes by `OfflineStoryService.resolveMode` — and `strategy` records
    /// how. Both nil builds a story the way it was built before modes existed.
    @discardableResult
    func createStory(
        for profile: UserProfile,
        mode: StoryMode? = nil,
        strategy: StorySelectionStrategy? = nil,
        storyIdeaID: String?,
        companionID: String?,
        subOption: String? = nil,
        seed: String? = nil,
        family: FamilyCharacter? = nil
    ) async throws -> Story {
        isGenerating = true
        defer { isGenerating = false }

        let service = OfflineStoryService.shared
        let composed = try service.compose(
            childName: profile.name,
            ideaID: storyIdeaID,
            companionID: companionID,
            mode: mode,
            age: profile.age,
            seed: seed,
            subOption: subOption,
            family: family,
            interests: profile.interests,
            recent: recentOrigins(for: profile),
            usage: StoryUsageStore().usage(of: stories.filter { $0.belongs(to: profile) }, for: profile.id)
        )

        let mapped = OfflineStoryMapper.appStory(
            from: composed.story,
            childName: profile.name,
            childProfileID: profile.id,
            storyIdeaID: storyIdeaID,
            catalogVersion: composed.catalogVersion,
            mode: mode,
            selectionStrategy: strategy,
            ageBand: service.servedBand(forAge: profile.age),
            subOption: subOption,
            familyCharacter: family
        )
        // Görselli kitap (B2): kayıtlı bir kitap karakteri varsa ve bayrak
        // açıksa hazır sahneler eklenir; yoksa masal bugünkü gibi metin çıkar.
        let story = await IllustratedBookBinder.illustrateIfEnabled(
            mapped,
            composed: composed.story,
            profile: profile,
            mode: mode,
            ageBand: service.servedBand(forAge: profile.age),
            existing: stories
        )

        stories.insert(story, at: 0)
        saveStories()
        return story
    }

    /// The modes of this child's most recent stories, newest first.
    ///
    /// What "Bana sürpriz yap" looks at so it does not repeat itself. Only
    /// stories that recorded a mode count; older ones say nothing.
    func recentModes(for profile: UserProfile, limit: Int = StoryModeResolver.historyWindow) -> [StoryMode] {
        stories
            .filter { $0.belongs(to: profile) }
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap { $0.origin?.mode }
            .prefix(limit)
            .map { $0 }
    }

    /// What this child's most recent stories were made of, newest first
    /// (FAZ 12). The engine cools that content down, so the next story is
    /// less likely to repeat the last ones — for every child, interests or not.
    /// Stories without an origin (written before the offline engine) say
    /// nothing and are skipped.
    func recentOrigins(for profile: UserProfile, limit: Int = SelectionScoring.cooldownWindow) -> [StoryOrigin] {
        stories
            .filter { $0.belongs(to: profile) }
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap(\.origin)
            .prefix(limit)
            .map { $0 }
    }

}

// MARK: - Account sync (FAZ 16)

extension StoryGenerationManager {
    /// A story another device wrote. Added when missing, never rewritten: a
    /// story's text does not change once written, and the copy already here
    /// keeps whatever this device knows about it (its cover file, its place).
    func applySyncedStory(_ story: Story) {
        guard !stories.contains(where: { $0.id == story.id }) else { return }
        let index = stories.firstIndex(where: { $0.createdAt < story.createdAt }) ?? stories.endIndex
        stories.insert(story, at: index)
        saveStories()
    }

    /// Where another device left a story. The later reading wins; a reading
    /// position never moves back because an older one arrived late.
    func applySyncedProgress(storyID: UUID, progress: StoryProgress) {
        guard let index = stories.firstIndex(where: { $0.id == storyID }) else { return }
        let local = stories[index].lastReadAt ?? .distantPast
        guard (progress.lastReadAt ?? .distantPast) > local else { return }
        stories[index].lastReadPage = progress.lastReadPage
        stories[index].lastReadAt = progress.lastReadAt
        saveStories()
    }

    /// After `LocalDataEraser`: an empty shelf, on disk and on screen. The
    /// empty write also carries the erasure to the file copy
    /// (`LibraryPersistence.reconcileAfterWrite`).
    func resetAfterErase() {
        stories = []
        saveStories()
    }
}

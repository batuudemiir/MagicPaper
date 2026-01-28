import Foundation
import SwiftUI

/// Günlük hikayeleri yöneten servis
@MainActor
class DailyStoryManager: ObservableObject {
    
    static let shared = DailyStoryManager()
    
    @Published var dailyStories: [DailyStory] = []
    @Published var todaysStory: DailyStory?
    
    private let userDefaults = UserDefaults.standard
    private let storiesKey = "dailyStories"
    private let lastRotationKey = "lastStoryRotation"
    
    private init() {
        loadStories()
        if dailyStories.isEmpty {
            createDefaultStories()
        }
        rotateTodaysStory()
    }
    
    // MARK: - Public Methods
    
    func markAsRead(storyId: UUID) {
        if let index = dailyStories.firstIndex(where: { $0.id == storyId }) {
            dailyStories[index].isRead = true
            dailyStories[index].lastReadDate = Date()
            saveStories()
        }
    }
    
    func getStoriesByCategory(_ category: DailyStoryCategory) -> [DailyStory] {
        return dailyStories.filter { $0.category == category }
    }
    
    func getStoryOfTheDay() -> DailyStory? {
        return todaysStory
    }
    
    // MARK: - Private Methods
    
    private func rotateTodaysStory() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastRotation = userDefaults.object(forKey: lastRotationKey) as? Date {
            let lastRotationDay = calendar.startOfDay(for: lastRotation)
            if today == lastRotationDay {
                // Bugün zaten rotasyon yapılmış
                if let savedTodayId = userDefaults.string(forKey: "todaysStoryId"),
                   let savedId = UUID(uuidString: savedTodayId),
                   let story = dailyStories.first(where: { $0.id == savedId }) {
                    todaysStory = story
                    return
                }
            }
        }
        
        // Yeni günün hikayesini seç
        let unreadStories = dailyStories.filter { !$0.isRead }
        let storyPool = unreadStories.isEmpty ? dailyStories : unreadStories
        
        if let randomStory = storyPool.randomElement() {
            todaysStory = randomStory
            userDefaults.set(randomStory.id.uuidString, forKey: "todaysStoryId")
            userDefaults.set(Date(), forKey: lastRotationKey)
        }
    }
    
    private func saveStories() {
        if let encoded = try? JSONEncoder().encode(dailyStories) {
            userDefaults.set(encoded, forKey: storiesKey)
        }
    }
    
    private func loadStories() {
        if let data = userDefaults.data(forKey: storiesKey),
           let decoded = try? JSONDecoder().decode([DailyStory].self, from: data) {
            dailyStories = decoded
        }
    }
    
    // MARK: - Default Stories
    
    private func createDefaultStories() {
        dailyStories = [
            // UYKU ÖNCESİ HİKAYELER
            DailyStory(
                title: "Yıldız Tozu Battaniyesi",
                category: .bedtime,
                ageRange: "3-6",
                readingTime: 5,
                content: """
Küçük Ayşe her gece yatmadan önce gökyüzündeki yıldızları sayardı. Bir, iki, üç... Ama yıldızlar o kadar çoktu ki, sayamadan uykusu gelirdi.

Bir gece, pencereden içeri küçük bir yıldız süzüldü. Yıldız, Ayşe'nin yatağının üzerine kondu ve parıldamaya başladı.

"Merhaba Ayşe," dedi yıldız tatlı bir sesle. "Ben Işıltı. Seni çok uzun zamandır izliyorum. Her gece bizi saymaya çalışıyorsun."

Ayşe şaşkınlıkla yıldıza baktı. "Gerçekten konuşabiliyor musun?"

"Tabii ki!" dedi Işıltı. "Ve sana özel bir hediye getirdim." Işıltı ellerini salladı ve aniden odanın tavanı yıldızlarla doldu. Ama bunlar sıradan yıldızlar değildi - yumuşak, sıcak ve parlak bir battaniye gibiydiler.

"Bu yıldız tozu battaniyesi," dedi Işıltı. "Her gece seni sıcak tutacak ve güzel rüyalar görmeni sağlayacak."

Ayşe battaniyeye dokundu. Pamuk gibi yumuşaktı ve hafifçe ışıldıyordu. Üzerine örttüğünde, kendini bulutların üzerinde gibi hissetti.

"Teşekkür ederim Işıltı," dedi Ayşe uykulu bir sesle.

"İyi geceler Ayşe," dedi Işıltı. "Artık her gece seninle olacağım."

Ve o geceden sonra, Ayşe her gece yıldız tozu battaniyesinin altında huzurla uyudu.
""",
                moralLesson: "Güzel düşüncelerle uyumak, güzel rüyalar görmeyi sağlar.",
                emoji: "⭐️"
            ),
            
            DailyStory(
                title: "Uyku Perisi Lila",
                category: .bedtime,
                ageRange: "2-5",
                readingTime: 4,
                content: """
Lila küçük bir uyku perisiydi. Her gece, çocukların güzel rüyalar görmesi için çalışırdı. Elinde sihirli bir değneği vardı ve bu değnek rüya tozu saçardı.

Bir gece, küçük Mehmet'in odasına geldi. Mehmet yatağında dönüp duruyordu, uyuyamıyordu.

"Merhaba Mehmet," dedi Lila yumuşak bir sesle. "Neden uyuyamıyorsun?"

"Karanlıktan korkuyorum," dedi Mehmet.

Lila gülümsedi. "Karanlık aslında çok güzel. Bak, sana göstereyim." Değneğini salladı ve odanın tavanında küçük ışıklar belirdi. Yıldızlar, aylar, gezegenler...

"Gördün mü? Karanlık, yıldızların parlaması için gerekli. Karanlık olmasaydı, bu güzellikleri göremezdik."

Mehmet tavana baktı. Gerçekten de çok güzeldi.

"Şimdi gözlerini kapat," dedi Lila. "Sana güzel bir rüya göndereceğim."

Mehmet gözlerini kapattı. Lila değneğini salladı ve altın renkli bir toz Mehmet'in üzerine yağdı.

O gece Mehmet, uçan bir atla gökyüzünde gezdiği güzel bir rüya gördü. Ve artık karanlıktan korkmuyordu.
""",
                moralLesson: "Korkularımızla yüzleştiğimizde, onların aslında o kadar da korkutucu olmadığını görürüz.",
                emoji: "🧚"
            ),
            
            DailyStory(
                title: "Ay'ın Ninni Şarkısı",
                category: .bedtime,
                ageRange: "1-4",
                readingTime: 3,
                content: """
Gökyüzünde, parlak bir ay vardı. Her gece çıkar ve dünyayı aydınlatırdı. Ama Ay'ın özel bir görevi daha vardı: Çocuklara ninni söylemek.

Küçük Zeynep yatağında uzanmış, pencereden Ay'ı izliyordu.

"Merhaba Ay," dedi Zeynep. "Bana bir ninni söyler misin?"

Ay gülümsedi. "Tabii ki küçük Zeynep. Dinle..."

Ve Ay şarkı söylemeye başladı:

"Uyu uyu yavrum uyu,
Yıldızlar seni bekliyor.
Bulutlar yumuşak yastık,
Rüyalar seni çağırıyor.

Uyu uyu tatlı bebek,
Ay seni koruyor.
Sabah olunca güneş,
Seni uyandıracak."

Zeynep'in gözleri ağırlaştı. Ay'ın sesi o kadar tatlıydı ki...

"Teşekkür ederim Ay," dedi Zeynep uykulu bir sesle.

"İyi geceler Zeynep," dedi Ay. "Her gece seninle olacağım."

Ve Zeynep, Ay'ın ninnisiyle huzurla uykuya daldı.
""",
                moralLesson: "Doğa bize her zaman eşlik eder ve bizi korur.",
                emoji: "🌙"
            ),
            
            // SABAH HİKAYELERİ
            DailyStory(
                title: "Güneş'in İlk Işığı",
                category: .morning,
                ageRange: "3-7",
                readingTime: 4,
                content: """
Güneş her sabah erken kalkar ve dünyayı aydınlatmaya başlardı. Ama bu sabah farklıydı. Güneş çok yorgundu ve kalkmak istemiyordu.

"Ah, biraz daha uyusam," dedi Güneş esnerken.

Ama o zaman, küçük bir kuş geldi. "Güneş! Güneş! Kalkma zamanı! Çiçekler seni bekliyor, ağaçlar seni bekliyor, çocuklar seni bekliyor!"

Güneş gözlerini ovuşturdu. "Gerçekten mi? Beni mi bekliyorlar?"

"Tabii ki!" dedi kuş. "Sen olmadan dünya karanlık kalır. Kimse oynayamaz, çiçekler açamaz, kuşlar şarkı söyleyemez."

Güneş bunu duyunca hemen kalktı. "Haklısın! Benim görevim çok önemli!"

Ve Güneş gökyüzüne çıktı. Işıkları her yeri aydınlattı. Çiçekler açıldı, kuşlar şarkı söyledi, çocuklar oyunlara başladı.

Küçük Ali pencereden dışarı baktı. "Günaydın Güneş! Seni bekliyordum!"

Güneş gülümsedi. İşte bu yüzden her sabah erken kalkıyordu. Çünkü dünya ona ihtiyaç duyuyordu.
""",
                moralLesson: "Her birimizin önemli bir görevi var ve başkaları bize güveniyor.",
                emoji: "☀️"
            ),
            
            DailyStory(
                title: "Sabah Kahvaltısı Maceraları",
                category: .morning,
                ageRange: "4-8",
                readingTime: 5,
                content: """
Küçük Ece sabahları kahvaltı yapmayı pek sevmezdi. Ama bir sabah, masadaki yiyecekler konuşmaya başladı!

"Merhaba Ece!" dedi peynir. "Ben Kalsiyum Kaptan! Kemiklerini güçlü yapacağım!"

"Ben de Vitamin C Süper Kahramanıyım!" dedi portakal. "Seni hastalıklardan koruyacağım!"

Yumurta da atladı. "Ben Protein Prensi! Sana enerji vereceğim!"

Ece şaşkınlıkla baktı. "Siz konuşabiliyorsunuz?"

"Tabii ki!" dediler hep birlikte. "Ve bugün seninle bir maceraya çıkacağız!"

Ece kahvaltısını yaptı. Ve birden kendini çok enerjik hissetti. Koştu, zıpladı, oynadı. Hiç yorulmadı!

"Vay be!" dedi Ece. "Kahvaltı gerçekten sihirli!"

O günden sonra, Ece her sabah kahvaltısını severek yaptı. Çünkü biliyordu ki, kahvaltı ona süper güçler veriyordu!
""",
                moralLesson: "Sağlıklı beslenme bize enerji ve güç verir.",
                emoji: "🍳"
            ),
            
            // EĞİTİCİ HİKAYELER
            DailyStory(
                title: "Sayıların Dansı",
                category: .educational,
                ageRange: "4-7",
                readingTime: 5,
                content: """
Sayılar Ülkesi'nde, tüm sayılar bir arada yaşardı. Bir gün, Kral 10 bir parti düzenledi.

"Bugün dans edeceğiz!" dedi Kral 10. "Ama özel bir dans. Toplama dansı!"

Sayı 1 ve Sayı 2 el ele tutu. "Biz birleşince 3 oluyoruz!" dediler ve dans ettiler.

Sayı 3 ve Sayı 4 de katıldı. "Biz birleşince 7 oluyoruz!" dediler.

Küçük Deniz izliyordu. "Vay be! Sayılar dans ederken toplanıyor!"

Sonra Sayı 5 geldi. "Kim benimle dans etmek ister?"

"Ben!" dedi Sayı 5. "İkimiz birleşince 10 oluruz!"

Tüm sayılar dans etti. 2+3=5, 4+4=8, 6+3=9...

Deniz çok eğlendi. "Matematik aslında çok eğlenceli!" dedi.

Ve o günden sonra, Deniz sayıları düşündüğünde hep dans eden sayıları hayal etti.
""",
                moralLesson: "Öğrenmek eğlenceli olabilir, sadece doğru bakış açısına ihtiyacımız var.",
                emoji: "🔢"
            ),
            
            DailyStory(
                title: "Renklerin Sırrı",
                category: .educational,
                ageRange: "3-6",
                readingTime: 4,
                content: """
Renk Dünyası'nda üç özel renk vardı: Kırmızı, Sarı ve Mavi. Bunlar ana renklerdi.

Bir gün, küçük Yeşil üzgündü. "Ben neden ana renk değilim?" diye sordu.

Sarı gülümsedi. "Çünkü sen özelsin! Bak, sana bir sır göstereceğim."

Sarı ve Mavi el ele tutu. Ve birden... Yeşil ortaya çıktı!

"Vay be!" dedi Yeşil. "Ben sizin çocuğunuzum!"

"Evet!" dedi Mavi. "Ve daha fazlası var!"

Kırmızı ve Sarı birleşti - Turuncu doğdu!
Kırmızı ve Mavi birleşti - Mor doğdu!

Küçük Elif izliyordu. "Demek renkler birleşince yeni renkler oluşuyor!"

"Aynen öyle!" dediler renkler. "Birlikte daha güzeliz!"

Elif fırçasını aldı ve resim yapmaya başladı. Kırmızı, sarı, mavi... Ve onları karıştırarak muhteşem renkler yarattı.

"Sanat sihirli!" dedi Elif mutlulukla.
""",
                moralLesson: "Farklı şeyler bir araya geldiğinde güzel sonuçlar doğar.",
                emoji: "🎨"
            ),
            
            // DEĞERLER HİKAYELERİ
            DailyStory(
                title: "Paylaşmanın Mutluluğu",
                category: .values,
                ageRange: "3-7",
                readingTime: 5,
                content: """
Küçük Sincap Fındık, kışa hazırlanıyordu. Ağaçtan ağaca atlayarak fındık topluyordu. Çok çalışmıştı ve büyük bir fındık yığını biriktirmişti.

Bir gün, komşusu Tavşan Pamuk geldi. "Merhaba Fındık," dedi üzgün bir sesle. "Ben hastalandım ve kış için yiyecek toplayamadım."

Fındık düşündü. "Ama ben çok çalıştım bu fındıklar için..."

O gece, Fındık uyuyamadı. Pamuk'un üzgün yüzü aklına geliyordu.

Sabah olunca, Fındık karar verdi. Fındıklarının yarısını bir sepete koydu ve Pamuk'un evine götürdü.

"Bunlar senin için," dedi Fındık.

Pamuk'un gözleri doldu. "Çok teşekkür ederim! Sen gerçek bir arkadaşsın!"

Fındık eve dönerken çok mutluydu. Fındıkları azalmıştı ama kalbi doluydu.

O kış, Fındık ve Pamuk birlikte vakit geçirdi. Hikayeler anlattılar, oyunlar oynadılar. Fındık anladı ki, paylaşmak onu daha mutlu ediyordu.

Bahar geldiğinde, Pamuk Fındık'a yardım etti. Birlikte daha çok fındık topladılar. Çünkü gerçek arkadaşlar birbirlerine yardım ederler.
""",
                moralLesson: "Paylaşmak bizi daha mutlu eder ve dostlukları güçlendirir.",
                emoji: "💝"
            ),
            
            DailyStory(
                title: "Dürüstlük Ödülü",
                category: .values,
                ageRange: "5-9",
                readingTime: 6,
                content: """
Can okulda çok sevdiği bir oyuncak buldu. Parlak, kırmızı bir araba. "Vay be!" dedi. "Tam istediğim araba!"

Arabanın altında küçük bir isim vardı: "Ahmet"

Can düşündü. "Ahmet'in arabası bu. Ama o çok oyuncağı var, belki fark etmez..."

Arabayı cebine koydu. Ama eve giderken içi rahat değildi. Arabaya baktıkça üzülüyordu.

Annesi fark etti. "Can, bir sorun mu var?"

Can her şeyi anlattı. "Ahmet'in arabasını aldım ama şimdi pişmanım."

Annesi ona sarıldı. "Dürüst olduğun için gurur duyuyorum. Yarın ne yapmalısın sence?"

Ertesi gün, Can arabayı Ahmet'e verdi. "Özür dilerim, senin arabanı almıştım."

Ahmet gülümsedi. "Teşekkür ederim! Onu çok arıyordum. Sen çok dürüst birisin."

Öğretmen bunu duydu. "Can, dürüstlüğün için seni tebrik ediyorum. İşte sana özel bir ödül."

Öğretmen Can'a altın bir yıldız verdi. Can çok mutluydu. Arabadan çok daha değerliydi bu yıldız. Çünkü dürüstlüğünün ödülüydü.

O gece Can huzurla uyudu. Çünkü doğru olanı yapmıştı.
""",
                moralLesson: "Dürüstlük her zaman en iyi seçimdir ve bizi huzurlu yapar.",
                emoji: "⭐️"
            ),
            
            // MACERA HİKAYELERİ
            DailyStory(
                title: "Kayıp Hazine Haritası",
                category: .adventure,
                ageRange: "6-10",
                readingTime: 7,
                content: """
Dedem tavan arasını temizlerken eski bir sandık buldu. İçinde sararmış bir harita vardı.

"Bak Mert," dedi dedem. "Bu harita çocukluğumdan kalma. Bahçede bir hazine gösteriyor."

Gözlerim parladı. "Gerçek bir hazine mi?"

"Kim bilir," dedi dedem gülümseyerek. "Belki de buluruz."

Haritayı aldık ve bahçeye çıktık. Harita bizi büyük meşe ağacına götürdü. "10 adım kuzeye" diyordu.

Adımları saydık. Sonra "5 adım doğuya". Bir gül bahçesine geldik.

"Burası!" dedim heyecanla. Kürek getirdik ve kazmaya başladık.

Birden, küreğim bir şeye çarptı. Metal bir kutu! Açtığımızda içinde eski fotoğraflar, mektuplar ve küçük oyuncaklar vardı.

"Bu benim çocukluğumun hazinesi," dedi dedem gözleri dolarak. "Annem bana yazdığı mektuplar, ilk oyuncağım..."

O gün anladım ki, en değerli hazineler altın ve gümüş değil, anılar ve sevgidir.

Dedemle birlikte her fotoğrafa baktık, her mektubu okuduk. Ve yeni anılar biriktirdik.
""",
                moralLesson: "En değerli hazineler anılar ve sevdiklerimizle geçirdiğimiz zamandır.",
                emoji: "🗺️"
            ),
            
            // DOĞA HİKAYELERİ
            DailyStory(
                title: "Kelebeğin Dönüşümü",
                category: .nature,
                ageRange: "4-8",
                readingTime: 5,
                content: """
Küçük bir tırtıl vardı. Adı Çizgi'ydi. Çizgi her gün yaprakları yiyerek büyüyordu.

Bir gün, arkadaşı Kelebek Lale geldi. "Merhaba Çizgi! Benimle uçmak ister misin?"

Çizgi üzüldü. "Ben uçamam ki. Sadece sürünebiliyorum."

Lale gülümsedi. "Şimdi uçamazsın ama bekle, göreceksin."

Günler geçti. Çizgi kendini garip hissediyordu. Bir ağaca tırmandı ve ipek bir koza ördü.

"Ne oluyor bana?" diye düşündü. Ama çok yorgundu. Kozanın içinde uyudu.

Haftalarca uyudu. Rüyasında uçtuğunu gördü.

Bir sabah uyandı. Ama artık Çizgi değildi. Kozayı yırttı ve dışarı çıktı.

Sırtında muhteşem, renkli kanatlar vardı! Kanatlarını çırptı ve... uçtu!

"Ben uçuyorum!" diye bağırdı. "Ben bir kelebeğim!"

Lale geldi. "Gördün mü? Söylemiştim! Sen hep kelebek olacaktın, sadece zamanı gelmemişti."

Çizgi - artık adı Gökkuşağı'ydı - çiçekten çiçeğe uçtu. Anladı ki, bazen değişmek için sabırlı olmak gerekir.
""",
                moralLesson: "Büyümek ve değişmek zaman alır, ama sabırlı olursak muhteşem şeyler olabilir.",
                emoji: "🦋"
            ),
            
            DailyStory(
                title: "Ağacın Dört Mevsimi",
                category: .nature,
                ageRange: "5-9",
                readingTime: 6,
                content: """
Bahçede yaşlı bir çınar ağacı vardı. Adı Bilge'ydi. Yüzlerce yıldır oradaydı ve dört mevsimi defalarca görmüştü.

İlkbaharda, küçük Elif ağacın altına geldi. "Merhaba Ağaç Dede," dedi. "Neden yapraklarını kaybettin?"

Bilge gülümsedi. "Kışın dinlendim. Ama bak, şimdi yeni yapraklar çıkıyor. İlkbahar yenilenme zamanı."

Elif her gün gelip ağacı izledi. Yapraklar büyüdü, çiçekler açtı, kuşlar yuva yaptı.

Yaz geldi. Ağaç gür ve yeşildi. "Şimdi gölge verme zamanı," dedi Bilge. Elif sıcak günlerde ağacın altında kitap okudu.

Sonbahar geldi. Yapraklar sarı, kırmızı, turuncu oldu. "Neden yaprakların renk değiştiriyor?" diye sordu Elif.

"Çünkü değişim güzeldir," dedi Bilge. "Her mevsimin kendine göre güzelliği var."

Kış geldi. Yapraklar döküldü. Elif üzüldü. "Artık çıplaksın."

"Ama dinleniyorum," dedi Bilge. "Bahar gelince yine yeşereceğim. Hayat bir döngü. Her şeyin zamanı var."

Elif anladı. Değişim korkutucu değil, doğaldı. Ve her mevsim güzeldi.
""",
                moralLesson: "Hayatta her şeyin bir zamanı vardır ve değişim doğanın bir parçasıdır.",
                emoji: "🌳"
            )
        ]
        
        saveStories()
    }
}

# Offline okuyucu ritmi — onaylanan pilot

19 Kasım2026. Kullanıcı, API ile sayfa başına resim üretilemeyeceğini belirttikten sonra mevcut havuzla üç düzen önerisini onaylayıp çalışmayı başlatmamızı istedi. Bu spec, bu onayı uygulanabilir dar kapsama çevirir; özel Ela/harita sahne mockup’larının üretime alınması değildir.

## Amaç ve sınır

Mevcut çizimi doğru sayfasında korurken görselsiz anlatının ritmini iyileştirmek. API, yeni asset, metin yeniden yazımı, sayfa sayısı değişimi, yeniden görsel eşleme, Character Bible değişikliği yok. Normal metin görüntülemeye getirilen düzen dışında kapak/ithaf/kapanış, chrome, kaydırma, font/kâğıt tercihleri ve kelime yardımı korunur. Bu pilot okuma isteğini artırdığı kanıtlanmış bir müdahale olarak sunulmaz.

## Veri akışı

Aktif `ComposedPage.role` ve isteğe bağlı authored `refrain`, mapper’da `StoryPage.reading` alanına taşınır. Küçük `StoryPageReading` değeri schemaVersion1, raw role:String ve refrain:String? içerir. Yeni dosya senkronlu StoryEngineBridge altında; StoryPage alanı mevcut modelde optionaldır. Eski kayıtta yoksa nil, tanınmayan sürüm/rol varsa mevcut düzen; yanlış tipli metadata geçersiz role sahip etkisiz değer olarak okunabilir ve masalın tümünün okunmasını bozmaz. Range saklanmaz, okuyucu kaynak metinden üretir. SeriesEpisode mevcut [StoryPage] taşımasıyla aynı metadata’yı saklar; unlock veya eski masallar için geri doldurma yapılmaz.

`ReaderPage.reading` sadece sunum için bu değeri alır. Saf `ReaderReadingRhythm` geçerli rol ve kaynaktan görsel bloklar çıkarır; orijinal paragraphs/spokenText, PageWord ve artwork pinleri değişmez. İngilizce imagePrompt’tan rol tahmin edilmez. Paket içindeki diğer Domain/StoryPage layout alanları bu akışla karıştırılmaz.

## Sunum kuralları

- Bilinen rol ve normal boyut sınıflarında7–10 paragraf düzeni, aynı kaynak paragrafındaki cümleleri en fazla ikişerli gruplar. Hook/discovery’de ilk cümle tek başına; resolution/celebration/emotional_ending/bedtime_transition’da son cümle tek başına.
- 3–6 nefes düzeni mevcut tek cümle birimlerini korur. Sakin sonuçta son birime ek boşluk verilebilir.
- Yazarın refrain’i yalnız tam son cümle/birim sınırında ve sayfa sonuyla birebir eşleşirse bir kez ayrılır; cümle ortasından bölme, kelime arama ile tahmin veya yinelenen yeni metin yok. Refrain önceliği son cümle kuralıyla çift aralık üretmez.
- Bloklar sola hizalı, aynı MP.F.read, seçilmiş boyut/satır aralığı ve Türkçe ligatür korumasıyla çizilir. Ad ve ses sözcükleri mevcut attributed pipeline’dan geçer. Diyalog yalnız gerçek diyalog işareti varsa mevcut ince kenarla ayırt edilir. Balon, dekor, yeni font veya renkli paragraf eklenmez.
- Sakin son/refrain öncesinde ek MP.S.x6 aralığı, ancak ölçülen bütün anlatı kullanılabilir alana sığıyorsa uygulanır. Uzun metin kayar, opsiyonel ekstra boşluk kaldırılır; font küçülmez. View ölçümünde kendini besleyen state döngüsü kurulmaz.
- AX boyutlarında, kompakt yükseklikte, sahneli sayfada, bilinmeyen/eksik metadata’da eski düzen. Spot üstte kalır; düşen veya eksik resim için mevcut fallback korunur. Yeni renk/ölçü token’ı gerekmez.

## Ses ve erişilebilirlik

Her blok kaynak paragraf indeksini ve geçerli UTF16 aralığını taşır. Anlatım işareti bu aralıkla kesiştirilerek blok koordinatına çevrilir; önceden okunan blok sönük, gelecekteki blok normal, aktif blok yalnız doğru bölümde vurgulu olur. Emoji/Türkçe metinde geçersiz sınır üretilmez. VoiceOver’ın tek narrative metni orijinal spokenText kalır. Kelime linkleri aynı sözlük kimliğini/eylemini taşır; sayfa gezinme ve kaydedilmiş ilerleme değişmez.

## Doğrulama ve teslim

Testler üretim değişikliğinden önce yazılır; AGENTS.md gereği ara RED yürütmesi yapılmaz, plan bittiğinde tek nihai doğrulama penceresinde çalıştırılır. Testler: mapper metadata ve metin invariant’ı; eski/gelecek/hatalı JSON fallback; known-role grupları ve tam kaynak kapsaması; güvenli refrain sınırları; UTF16/emoji/ses remap; ReaderStory aktarımı; StoryPage ve SeriesEpisode roundtrip. Önceki reader/art/model testleri regresyon kapsamıdır.

Gerçek offline masalın aynı sayfaları sabit viewport renderlarında normal paragraf, nefes, görsel, sonuç, uzun metin, küçük ekran ve AX/gece olarak karşılaştırılır. PNG oluşumu tek başına görsel kabul sayılmaz; görüntüler gözle incelenir. Sabit viewport + no-op callback harness fiziksel cihaz veya uçtan uca etkileşim testi olarak sunulmaz. Uygulama build/test sonucu rapora, proje hafızasına ve changelog’a yazılır; yalnız bu işin dosyaları commit’lenir.

## Kapsam denetimi

Bu çalışma yalnız sunum metadata’sı ve metin bloklarıdır. Eski masalların yeni tasarıma otomatik dönüştürülmesi, sayfa sonlarında yeni merak cümleleri, görsel havuzunun genişletilmesi ve nitel çocuk pilotu bu commit’in kapsamı değildir. Ürün iddiası testlerin ötesine taşınmaz. Plan ve UI brifi bu spec’e bağlıdır.

# Karakter merkezli resimleme — araştırma ve öneri

18 Kasım 2026. Kullanıcının fikri: hikâye karakterlerini önceden çizip adlarının geçtiği sayfalarda göstermek. Bu belge fikri genişletir; uygulama kararı veya entegrasyon onayı değildir. Yeni görsel/kod hazırlanmadı.

## Öneri

Önceden onaylanmış karakter çizim kütüphanesi + varyant yazılırken tanımlanan görsel yönerge + cihazda deterministik seçim. Temel karar adın bulunması değil, karakterin sayfadaki rolü, sahnede bulunması, duygu ve eylemidir. İlk ürün basamağı karakter vinyetleri ve nesne ayrıntıları; tam sahne kompozisyonu daha sonra.

## Araştırma notları

1. Eng, Godwin & Fisher (2020), *Keep it simple: streamlining book illustrations improves attention and comprehension in beginning readers*. İlk/ikinci sınıf başlangıç okurlarında metinle ilgisiz ayrıntıları azaltılmış sayfalarda daha az dikkat kayması ve daha iyi anlama görüldü. Bu sonuç 3–4 yaş ebeveyn eşliğinde okuma veya MagicPaper modeli için doğrudan etki kanıtı değildir. Ürün çıkarımı: tek odak, ilgili çizim, her adı resimle doldurmama. https://www.nature.com/articles/s41539-020-00073-5
2. Greenhoot, Beyer & Curtis (2014), *More than pretty pictures?* 26 çocuk/ebeveyn çifti, çocuklar 3,5–4,5 yaş. Ebeveyn eşliğinde resimli koşulda toplam anlık hatırlama avantajı; bir hafta sonra anlamlı avantaj sürmedi. Örneklem küçük, etkiler otomatik veya kalıcı kabul edilemez. Ürün çıkarımı: ebeveynle konuşulabilecek anlamlı resimler, süslü yüzeyden daha iyi hipotezdir. https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2014.00738/full
3. Liu & Keller (AAAI 2023), *Detecting and Grounding Important Characters in Visual Stories*. VIST-Character, karakterlerin metin/görsel eşgönderimi ve önem derecesini ayrı modeller. Çocuk öğrenmesi veya bizim ürün için etki çalışması değildir. Mimari çıkarım: aynı ismin metinde geçmesi, görselde hangi varlığa karşılık geldiği ve anlatı odağı farklı kararlardır. https://arxiv.org/abs/2303.17647

Bu kaynaklar önerinin bazı ilkelerini destekler; önceden çizilmiş poz kataloğunun ürünümüzde çalıştığını kanıtlamaz. O varsayımı pilotla sınamalıyız. Çalışmalardan görsel kopyalanmadı.

## İncelenen yedi yaklaşım

| Yaklaşım | İşlev | Karar |
|---|---|---|
| Tek sabit karakter vinyeti | Kim olduğunu tanıtır | Karşılaştırma tabanı; bütün sayfalarda tekrarı durağanlaşabilir |
| Küçük ifade/poz seti | Duygu ve hareketi metne yaklaştırır | Önerilen çekirdek |
| İki karakterli düzen | Karşılaşma, birlikte bekleme | Yer/ölçek/yön için onaylı düzenlerle sınırlı |
| Nesnenin durum seti | Solan fide/iyileşmiş fide; dolu/boş sepet | Ancak gerçek metin durum değişimini anlatıyorsa |
| Seyrek mekân vinyeti | Ortamı kurar | Tanışma/açılış gibi seçili anlarda |
| Tam resimli dönüm noktası | Kitap başına seçili güçlü anlar | Maliyeti/özgüllüğü yüksek; ileriki aşama |
| Bilerek resimsiz sayfa | Okuma ritmi ve belirsizlikte sadakat | Her zaman geçerli seçenek |

Önerilen karışım: poz seti + nesne durumu + gerektiğinde ikili düzen. Tek odak, beyaz alan, mat guaj. Süs paneli, avatar rozeti, etiket çerçevesi ve her sayfada aynı çıkartma dili yok.

## Bir karakterin resim dosyası değil görsel kimliği olur

Her kanonik katalog karakteri: sabit siluet, yüz, renkler, boy oranı, referans çizim, onaylı ifade/pozlar ve sürüm. Kestane adı/ID'si aynı karakteri bulur; bütün kirpiler zorunlu aynı görünüme indirgenmez. Çocuk görünüşü adından/cinsiyet varsayımından türetilmez; mevcut ChildProfile/Character Bible ve kanonik görünüş kaydı kaynak kalır. Ragi'nin resmî kimliği ayrı; rolü yoksa masalın içine girmez. Masal ailem için bağımsız kimlik gerekir.

İlk üretimde nötr/meraklı/endişeli/dinlenen gibi küçük bir set düşünülebilir. Bunlar her karakter için dört farklı duygu çizme zorunluluğu değildir; gerçekten kullanılan metinlere göre seçilir. Sayfanın emotion alanı otomatik olarak bütün karakterlere uygulanmaz: Ela şaşırırken Kestane sakin olabilir. İnsan figürü için hazır sabit kız resmi bütün çocukların yerine kullanılamaz.

## Ad aramak yerine üretim anında görsel yönerge

Önerilen kavramsal alanlar (mevcut alanmış gibi sunulmamalı):

- Gösterilecek varlıkların ID'leri ve rollerine ait bağlama (`child`, `companion`, `family`, `discovery`).
- Anlatı odağı, sahnede bulunanlar ve yalnızca anılanlar ayrı.
- Karakter başına duygu ve poz; aktör → eylem → hedef.
- Nesnenin hali; gerekiyorsa günün zamanı/mekân.
- Yerleşim türü, ilk görünme/ifşa koşulu, izinli görsel kimliği/sürümü.

Varsayımsal örnekler:

| Metin | Karar |
|---|---|
| Kestane başını kaldırdı | Kestane'nin onaylı yukarı bakan pozu |
| Kestane orada değildi | Kestane'yi sahnede gösterme |
| O, yaprağın altından çıktı | Açıkça bağlanmış referent Kestane ise isim geçmese de göster |
| Ela ile Kestane yan yana bekledi | Tek sakin ikili düzen; uyumlu çocuk pozu yoksa sadece Kestane/nesne ya da metin |
| Kestane korkuyordu | Gülümseyen neşeli poz verme; uygun çizim yoksa nötr vinyet veya metin |

Türkçe ekler ve ortak adlar (`Kestane`, `Pamuk`, `Yıldız`) düz kelime aramasını kırılgan yapar. Motor varlığı zaten biliyorsa son metinden yeniden tahmin edilmemeli. Mevcut requiredSlots ve move alanları yardımcıdır; requiredSlots fiziksel bulunmayı, move ayrıntılı pozu ve sayfa emotion'ı bütün karakterlerin duygusunu tek başına garanti etmez.

## Mevcut sistemle ilişki

- Binder, ComposedStory/ComposedPage eldeyken karar verebilir; mevcut SceneSelector/StorySceneView deseninden yararlanılır, ikinci bağımsız sahne motoru kurulmaz.
- `OfflineStoryMapper.appPage` rol/beat/duygu/variant kimliklerini sayfaya taşımıyor; StoryOrigin varyantları masal düzeyinde düz liste olarak tutuyor. Önerilen sayfa yönergesinin kaybolmadan aktarımı ve kitapla kaydı tasarlanmalı.
- Kitap açıldığında görseller yeni baştan tahmin edilmez. Seçilen varlık/poz/sürüm ve çocuk görünüşü kitapla sabitlenir; yeni kitaplar güncel sanatı alabilir. Eksik/değişmiş varlık için kontrollü metin yedeği gerekir.
- Önceki pilotta 24 kitapta 48 görsel eşlemesi elde edildi. Karakter vinyetleri eyleme özel tam sahne zorunluluğunu azaltır; fakat ışık dili ve fide/kirpi hedefi gibi metin sorunlarını düzeltmez/gizlemez.

## İleriki pilot önerisi

En ucuz karşılaştırma: aynı temizlenmiş kısa metin yolu ve aynı yerleşim üzerinde (A) tek sabit Kestane vinyeti, (B) üç onaylı Kestane pozu/ifadesi, (C) aynı set + tek ilgili nesne ayrıntısı. Yeni karakterlere başlamadan önce bu üç yaklaşımı karşılaştır.

Hedefler: doğru karakter/duygu/eylem, erken görünmeme, isim değişiminde kimlik karışmaması, görsel tekrarının rahatsız edip etmemesi, metnin kesilmemesi. Önce editoryal inceleme, sonra küçük gönüllü ebeveyn–çocuk gözlemi; süre/kalıcılık/öğrenme etkisi vaat edilmez. Üç Kestane pozu + örneğin iki nesne hali, önerilen başlangıç kapsamıdır; katalog kapsaması tahmini değildir. Bu turda bunlar çizilmedi veya uygulanmadı.

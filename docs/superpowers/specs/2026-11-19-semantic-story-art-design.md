# Story Engine ile büyüyen görsel havuzu

19 Kasım 2026 · Tasarım önerisi ve ilk 12 konu görseli. Bu belge uygulama entegrasyonu onayı değildir. Kullanıcı mevcut motoru inceleme, planlama ve imagegen ile görsel hazırlamayı istedi. Üretim kodu bu turda değiştirilmez.

## Karar özeti

Hikâye metnini sonradan kelime arayarak süslemek yerine, motorun seçtiği içerik kimliklerini kullanarak **sayfa için kaydedilmiş bir görsel kararı** hazırlayalım. Çizimler önceden hazırlanır; cihazda görsel servisi çağrılmaz. Katalog büyüdükçe metin varyantları hangi görsel konuları hangi durumda gösterebildiklerini açıkça belirtir. Eşleşmeyen sayfa, mevcut kaliteli metin düzeninde kalır.

### Üç yaklaşım

| Yaklaşım | Kazanç | Sınır |
|---|---|---|
| Metinde kelime ara | İlk demo kolay | Türkçe ekler, olumsuzluk, hatırlama, benzetme, aynı adlı nesne ve spoiler hatası; üretim için önerilmez |
| Blueprint/sayfa/varyant izin listeleri | Küçük incelenmiş dilimde güvenli başlangıç; mevcut pilotla uyumlu | Yeni varyantlar geldikçe elle bakım; çok-beat sayfanın tümü ayrıca incelenmeli |
| Yazılmış görsel anlam bilgisi + sürümlü sanat kataloğu | Seri, yaş ve büyüyen havuz için ölçeklenir; denetlenebilir | İçerik şeması ve editoryal yayın kontrolleri gerekir |

Öneri: kısa vadede ikinci yaklaşımın dar dilimi; kalıcı yön üçüncü yaklaşım. Açıkça incelenmiş izin listesi olmadan benzer görsel seçilmez. Nötr nesne çizimi, onu görmeyen/yalnızca hatırlayan sayfada otomatik kullanılmaz.

## Mevcut mimari

`OfflineStoryService` seçilen bundled/downloaded `ContentCatalog` ile intent hazırlar. `OfflineStoryComposer` blueprint, setting, companion, discovery seçer; pagePlan’daki beat’ler için varyantları seçip Türkçe slotları işler. `ComposedPage` rol, beat, emotion ve **sayfaya ait seçilmiş variantIDs** taşır. İsim de varyant seçimini etkileyebilir; seed/sayfa tek başına anlam kimliği değildir.

`StoryGenerationManager`: compose → `OfflineStoryMapper.appStory` → `IllustratedBookBinder.illustrateIfEnabled` → kitaplığa kayıt. Binder hem seçilmiş engine sayfalarını hem app sayfalarını gördüğü için doğru bağlantı noktasıdır. Mapper sonrasında sayfa provenance bilgisi büyük ölçüde kaybolur; StoryOrigin’deki varyantlar kitap düzeyinde düz listedir.

Mevcut `SceneSelector` setting/role/mode için filtreler, beat/emotion için puan verir; discovery, seçilmiş varyant veya eylem hedefini bilmez. Bu seçicinin genel sahne puanını nesne eşleşmesi kanıtı saymayalım. B2 karakterli sahne yolu korunur; yeni nötr spot yolu ayrı, açık kapsamlı bir bağlama politikası olur. B2 Release kapısı bu çalışmayla açılmaz (Release false, DEBUG varsayılan true). Nötr spot bağlaması mevcut B2 bayrak/kit/library/avatar guard bloğunun tümünün dışında çalışmalıdır. Üründe spot desteği açılacaksa kendi kontrollü geçişi olur.

`StoryPage.art` bugün yalnızca role/altText/sourceID taşır; okuyucu scene → resim → metin önceliğiyle çiziyor, role=spot ve dolu açıklama küçük resim yerleşimi sağlıyor. Bu görsel çıktıyı göstermeye yeterli başlangıçtır; sürüm, semantik kanıt ve bundled asset konumu için yeterli değildir. ReaderImageLoader’ın asset katalog adını desteklediği varsayılmaz: entegrasyonda açık bundled-file çözümleyicisi eklenmeli veya onaylı dosya kitapla saklanmalıdır.

## Önerilen veri sınırları

**1. İçeriğin görsel anlamı — yazara ait.** Varyanta isteğe bağlı bildirim: subject slot/ID, presence (şimdi görülen / hatırlanan / hayal edilen / yok), action, actor, target, state (ör. torn, intact, wilted), setting/time ve çizilmemesi gereken öğeler. Eylem ile bir şey yapma niyeti ayrı. Her bildirim seçilmiş template+variant ve içerik sürümüyle izlenir. Nötr nesne için tam eylem sistemi gerekmez; görünür nesne ve durum yeterli minimumdur.

**2. Sanat kataloğu — illüstrasyon yayınına ait.** Stable assetID, revision, digest, styleRevision, yerel kaynak, görsel role (spot/scene), subjectID, durum/eylem desteği, karakter içerip içermediği, Türkçe alt açıklama ve onay durumu. `draft` varlık seçilemez. Aynı assetID’nin yeni çizimi ayrı revision olur. İlk setin manifest’i `review` durumundadır.

**3. Sayfa bağlayıcı — uygulama uyarlama katmanı.** Gerçek seçilmiş sayfadaki tüm ana/destek beat’leri ve eklenen recall/family/occasion cümleleri değerlendirilir. Uygun olmayan/eksik semantik bilgi → metin. Önce kesin uygunluk, sonra kompozisyon ve tekrar azaltma. Kapalı içerik listesi ilk sürümde desteklenir; otomatik metin anlamı çıkarımı yoktur.

**4. Kaydedilmiş sayfa kararı.** Sürüm, assetID+revision/digest, role, yazılmış Türkçe altText, subject/state, page-local variant provenance ve bindingPolicyVersion. Reader karar vermez, yalnız kaydı gösterir. Kaydedilmiş kitap yeni katalogla yeniden eşlenmez. Referanslanan resimler çevrimdışı kalır; dosya bulunamazsa metin okunabilir kalır.

`StoryPageArt` geri uyumlu isteğe bağlı alanlarla genişletilebilir; ayrı, ikinci rakip metadata sistemi açılmamalı. Mevcut kitapların otomatik geriye dönük resimlenmesi kapsam dışıdır. Eski kitapta yeterli sayfa provenance yoksa tahmin yapılmaz.

## Somut örnek

Bugün mevcut nesne `object_torn_map_001`. Seçilmiş sayfa varyantı, yırtık haritanın şimdi görüldüğünü ve hâlâ yarım olduğunu bildirirse `spot.torn-map / r1` seçilebilir. Başka cümle haritanın onarıldığını söylerse bu çizim uygun değildir. “Haritayı hatırladı”, “harita yoktu” veya yalnız bir benzetme aynı pozitif görünürlük değildir.

Kullanıcının deniz feneri örneği sonraki içerik için aynı mantıkla işler: önce `setting_lighthouse` veya ilgili object kimliği ve uygun varyantlar yazılır; sonra deniz feneri çizimi ve kayıtlı eşleşme eklenir. Bugünkü “eski fener” veya “kâğıt fener” deniz fenerine eşlenmez. Üçüncü sayfa diye sabit kural yok; nesne hangi gerçek sayfada görünüyorsa orada uygun olur.

## Seriler ve devamlılık

`SeriesPlan/SeriesAnchor` setting, companion, keepsake, katalog sürümü ve bölüm blueprint/discovery/seed bilgilerini tutar. Dört devam bölümü başta hazırlanır; ilkiyle toplam beş bölüm. Görsel kararları da aynı hazırlık sırasında bir kez bağlayıp saklayalım.

`SeriesEpisode` pages/origin taşır ama `StoryIllustration` taşımaz. Yalnız kitap seviyesine yeni alan eklemek, kilit açılışında görseli kaybettirir. Sayfa kararı pages ile korunmalı; ileride karakterli sahne eklendiğinde seri düzeyindeki style/character/keepsake snapshot’ı hem bölümlerde hem yeniden açılışta korunmalıdır.

İlk nötr nesne fazında çocuk kimliği yeniden çizilmez. Sonraki karakter fazında kanonik `BookCharacterSource`/Character Bible kullanılır; isimden yüz/ten/saç çıkarılmaz. Aynı hatıra nesnesi aynı seri içinde aynı revision kullanır. Karakter düzenleme serinin yayımlanmış bölümlerini sessizce değiştirmez.

Aile üyesi silinince açılmamış bölümler bugün güncel katalogla yeniden yazılabiliyor. O bölümlerin görsel kararları da yeni metne göre yeniden bağlanmalı; açılmış bölümler değişmez. Çıkarılmış katalog kimlikleri varsa mevcut serinin kapanış/fallback kuralları korunur.

## Havuz büyümesi ve paketler

Mevcut ContentPackage tüm kaynak havuzunu değiştirir; overlay değildir. Schema=2 tam eşitlikle kontrol edilir. Yeni şema eklenirse eski uygulamayla uyumluluk ve yayın politikası açıkça ele alınmalı; bilinmeyen yeni alanın eski decoder tarafından kabul edilmesini tam sözleşme desteği saymayalım.

İlk sürüm bundled çizimler ve dar izin listeleriyle çevrimdışı çalışır. İçerik büyürken yayın kontrolü bilinmeyen art ID’leri, yanlış nesne durumu, eksik revision ve çelişen varyantları raporlar. Kapsama setting × mode × yaş × standalone/continuation × variant üzerinden sayılır; ham blueprint uyumu gerçek kapsama diye sunulmaz.

Uzak içerik altyapısı metin kütüphane/beat belgelerini taşır; bugün görsel paket indirme sistemi yoktur. Gelecek faz: imzalı manifest, asset hash, boyut/saklama bütçesi, bağımlılıkların tümü doğrulanmadan etkinleşmeme, atomik geçiş ve rollback. Kaydedilmiş kitap/seri tarafından kullanılan revision çöp toplamada tutulur. Eksik görsel yeni masalı bozmaz. Uzak dağıtım bu turda açılmaz.

## Aşamalı uygulama ve kabul

1. **Bu teslim:** üç ayrı kaynak incelemesi, envanter, bu mimari taslak, 12 saydam konu çizimi, promptlar/provenans ve görsel kontrol. App/motor değişikliği ve test yok.
2. **Dar entegrasyon:** onaylı ilk nesneler + incelenmiş tam sayfa varyant allowlist’leri; optional snapshot sözleşmesi; yerel kaynak çözümleme; mevcut generation binder noktasında deterministic eşleme. Gerçek engine export’uyla kanıtlanmış örnek kitaplar. Her yeni görsel taslak/onaylı ayrımı.
3. **Seri desteği:** bind-once, unlock/restore/family-removal; aynı motifin revision devamlılığı. Beş bölümün hiçbiri açılırken yeni resim seçmez.
4. **İçerik semantiği:** varyant provenance ve optional görsel bildirimleri; tüm cümleleri dikkate alan doğrulama; editoryal içerik hatalarını ayrı düzeltme. Allowlist’ten bildirime kontrollü geçiş.
5. **Yeni havuz:** kanonik yol arkadaşları, durum/eylem varyantları, mekân setleri; sonra gerekirse uzak sanat paketleri.

İlk dilimden önce onaylanacak kararlar: sanat setinin görünüşü, allowlist→semantik bildirim yaklaşımı ve ilk entegrasyon kapsamı. Kod öncesi tasarım gözden geçirmesi: `brainstorming/SKILL.md` bu ayrımı gerektiriyor. Araştırma ve resim hazırlama kullanıcı tarafından bu turda açıkça istendiği için tamamlanır; üretim kodu somut tasarım incelemesinden sonra başlar.

## Test ve doğrulama planı

Uygulama fazında testler önce yazılır, AGENTS kuralıyla yalnız plan sonunda birlikte çalıştırılır:

- Eski/unknown/malformed art kaydı kitabı bozmaz; mevcut kütüphane formatı korunur.
- Aynı seçilmiş içerik ve policy ile aynı resim; isim veya seed değişip varyant değişince yeni anlam değerlendirilir.
- Bir sayfada destek beat’i nesneyi değiştiriyorsa yanlış resim seçilmez; yok/hatıra/hayal/olumsuz eylem ayrılır.
- Draft, yanlış subject/state ve eksik dosya text fallback; VoiceOver yalnız Türkçe onaylı açıklama.
- B2 sahne önceliği ve metin-only açılış sözleşmesi bozulmaz.
- Beş seri bölümü save/unlock/relaunch/restore boyunca aynı pinleri korur; aile silinince yalnız yeniden yazılan bölümler yeniden bağlanır.
- Eski katalog değişse bile kayıtlı kitap görseli korunur; yeni paket eksik/bozuk asset ile etkinleşmez.
- Beyaz ve tüm isteğe bağlı kâğıtlar, en büyük Dynamic Type, SE/Pro Max/iPad, kısa/uzun metin ve eksik resim doğrulanır.

Önceki okuyucu uygulamasında testler disk dolması ve yerel CodeSign hatasıyla çalışamamıştı; bu tasarım onu doğrulanmış varsaymaz. Bu tur build/simülatör çalıştırılmaz.

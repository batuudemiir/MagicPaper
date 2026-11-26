# Beş arkadaş P56: internal motor kaydı

25 Kasım 2026. Kullanıcının B kararı ve motor uyarlamasına devam talimatı kapsamında.

## Çalışma sınırı

P56 artık ayrı bir runtime formatı ve davranış yoluyla uygulanıyor: `offline-p56-v1`, `five-friends-56-runtime-v1`. Eski `ContentPackage`/`StoryBeat`/validator/production composer sözleşmeleri korunuyor. Üretim kataloğuna pilot JSON eklenmiyor; açık payload ve SHA verilmeden pilot yüklenmiyor. Yeni app internal servisinin singleton'ı, varsayılan paket araması veya kullanıcı ekranından giriş yolu yok.

Kaynak byte'ları, kişiselleştirme template'leri, parent authored kimlikleri/hash'leri, karakter profilleri, kurgu geçişleri, ortam ve sahne anlamı aynı payload içinde. Tam byte SHA-256'sı ayrı P56 kaynak referansında taşınıyor. K1'in legacy resolver'ı bu formatı biliyormuş gibi genişletilmedi. Internal arşiv digest adına atomik yazıyor, her okumada hash ve codec denetliyor; kayıp/bozuk kaynağın yerine güncel katalog konmuyor.

P56 çıktıları ayrı tiplerdir. Mevcut `Story`/`StoryOrigin`/seri kayıtlarına sahte legacy kimliğiyle yazılmazlar. Internal çıktı kaynağı ve kişiselleştirme girdileriyle tekrar denenebilir; gerçek çocuk verisi kanıt dosyalarına alınmaz.

## Repertuvar ve içerik

Beş canonical arkadaş, üç mod ve 5–6 yaş; 9 mekanizma/30 izinli eşleşme. Her arkadaşın her modda iki mekanizması var. Simit aynı şehir kedisi olarak ziyaretçi; ayının taşıma ve baykuşun uçma yeteneği eski katalogda değiştirilmedi. Çocuğun çözümünü bu yetenekler ele geçirmiyor.

Gündüz Fısıldayan Orman, uyku aynı dünyanın ayrı odası. U3'ün anı seçme/sınırlama/bırakma akışı gerçek bir bakım ihtiyacı veya tehdit gibi gösterilmiyor. Bedtime uyanık dinlenmeyi ve göz kapamayı gerçek uyku diye etiketlemiyor. Parent authored metin ve rendered metin farklı kimlik/hash alanlarıyla korunuyor; Türkçe ad çekimi mevcut renderer üzerinden yapılıyor.

Bağımsız okuma 30 kitabın 240 tam sayfasını kapsadı. Önceki sekiz düzeltmeye ek olarak iki bağlaç, ayının yatağa iki kez dönmesi ve L2 ayı p6 cümle bütçesi düzeltildi; değişen dört metin yeni sourceID aldı. Son cümle bölünmesi gerçek testte bulunan 16 kelimelik cümleyi 14 kelimelik sınırı değiştirmeden giderir. Metadata revizyonu aktör dizilerini, kitap özelindeki rahatlık materyallerini ve hatırlanan/offscene kökleri ayırıyor. [Editoryal inceleme](../five-friends-pilot/EDITORIAL_REVIEW.md) son editoryal/art/yayın onayı değildir. Bazı açıklayıcı olumsuz cümlelerin anlatı cilası ihtiyacı sürüyor.

## Ölçümün anlamı

N kolunda 15 hücre ×100 sabit ilk-deneme seed hedeflenir; zorlanmış 30 eşleşme bu paydadan ayrıdır. Başarısızlıklar gizlenmez, retry/reseed yapılmaz. Kitap ve mekanizma sayıları, ilk tekrar ve kaynak/metin tekrarları ayrı raporlanır. **İki kitap/hücre geniş kombinatoryal çeşitlilik değildir.** Teknik olarak temiz 1.500 yanıt, 1.500 farklı hikâye anlamına gelmez.

Art için onaylı P56 kuralı yok. Tam metin/kaynak/sayfa/önce-sonra/aktör/temporal bağlam handoff'u görsel ekibe kanıt sağlar; asset üretimi veya onayı değildir. Legacy görsel kuralları yeni semantik gruplara otomatik bağlanmaz. Görselsiz sonuçlar paydada tutulur; sanat için metin/seed seçilmez.

## Açık kapılar

- Üretim politikası kapalı; başarı halinde kendiliğinden açılmaz.
- Güvenlik etiketleri bağımsız gözden geçirilmemiş pilotta sağlanan güvenlik politikası sessizce yok sayılamaz; açık unsupported sonucu gerekir.
- Aile, konuk, recall, özel gün, seri, konu ve diğer yaş bağlamları bu teslimde desteklenmiş sayılmaz.
- L/F legacy karşılaştırma kolları N runtime doğrulamasından ayrıdır; çalıştırılmadıysa sonuç uydurulmaz.
- Metin çeşitleme/tekrar yeterliliği, son editoryal kabul, görsel kapsam kabulü ve açık ürün yayın kararı bekler. Meslek/deniz/uzay ayrı teslimlerdir.
- K1'de kaynağı kanıtlanamayan eski origin'lerin yeni devam/yeniden yazım sınırı bu teslimle çözülmüş sayılmaz. Kayıtlı metin ve hazırlanmış seri bölümleri korunur.

## Doğrulama

Seçili Release motor koşusu: **36 test / 0 hata**. İlk koşu L2/Böğürtlen p6 cümle sınırını yakaladı; metin yeni sourceID ile düzeltildi ve aynı testler tekrar geçti. 1.500 ilk-deneme N isteği: **1.500 başarı / 0 hata / 0 retry**, 15 hücre ×100; ayrı30zorlanmış eşleşme çıktı verdi. Tam motor paketi veya tüm app/UI paketi bu teslimde yeniden koşulmuş sayılmaz. Seçili gerçek iOS simülatör koşusu **21 test / 0 hata**, `TEST SUCCEEDED` (P56snapshot + frozenlegacy + tarihselseri/resolver + syncrefkoruma).

30sabitkitap vardır. Bütün hücrelerde ilk kitap tekrarı ikinci istekte gerçekleşti.12.000sayfada11.760tekrarlanan kaynak ve11.842tekrarlanan rendered sayfa görüldü; sayfa tekrarları global sayılır. Bu nedenle hücrede ilk metin tekrarı1görünebilir: başka karakter hücresindeki ortak proza önceden görülmüştür. Bu metrik hücre-içi ilk okuma sanılmamalıdır.

Art:1.500kitap0pin;0görselli kitap/0görselli sayfa. OnaylıP56kuralı yok;12.000sayfa için red gerekçesi `no-reviewed-p56-rule`. Bu, legacy binder ile uyumsuz tipleri zorlayıp elde edilmiş sonuç değil; pilotta asset atama yolu/approvedrule olmadığı doğrulanarak sayılmıştır.

252frozenlegacy dosya0değişim. Authoring bütünlük kontrolü30/240/1252,12revizyon ve tüm pointer/hash ilişkilerinde geçti. Bağımsız spec+kalite incelemesinin açık teknik engeli yok; testler koddan önce yazıldı, ara koşu yapılmadı.

Claude ile koordinasyon notu yerel Claude Code üzerinden iletildi, başarı yanıtı/session kaydı `CLAUDE_ACKNOWLEDGEMENT.json` içinde. Claude araçsız oturumda yalnız özeti okudu; bu, bağımsız kod incelemesi değildir.

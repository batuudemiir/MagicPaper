# Değişmeyen metinlerle geniş görsel havuzu

20 Kasım2026. Kullanıcı karma havuz önerisine “devam et” diyerek ilerlemeyi istedi. Bağlayıcı kısıtlar: metinler, olay örgüsü, mevcut seed/varyant seçimi ve hikâye çeşitliliği korunacak; görsel için yeni cümle veya seçim filtresi yok. Cihazda görsel API’si çağrılmayacak. Kapak dışında anlamlı görselli masal sayfaları hedefleniyor; küçüklerde daha fazla. İlk doğrulama eşiği her üretilebilir kitapta en az1 uygun sayfa;3–6 için3/7–10 için2 yalnız doğrulanması gereken yoğunluk hedefidir, teslim edilmiş garanti değildir.

## Birinci iş paketi: anlam envanteri ve doğrulama araçları

Katalog yükleyicinin gerçekten birleştirdiği authored kaynaklar; üst düzey normal, seri/özel gün ve beat varyantları, recall/refrain ekleri dahil çıkarılır. Her kayıt kaynak yolu+JSON pointer+ham kaynak digest’iyle kimliklenir. Bir araç kaynak sürüklenmesini, eksik/fazla annotation kaydını ve yanlış asset referansını denetleyebilir. Kelime/slot tespiti yalnız inceleme adayı üretir; kendiliğinden onaylı çizim kararı değildir.

Sidecar açıklama en az subject slot/ID, physical presence/remembered/destination/absent ayrımı, durum, gerekliyse canonical identity ve kaynak cümle sınırını taşır. Bilinmeyen/çelişkili durumlar unresolved olur. Tek başına setting slot’unun geçmesi mekânda bulunma kanıtı değildir; dünya, hava/ışık ve kişi ekleri resimde iddia edilen gerçeklerdir.

İlk çıktılar kaynak envanteri, elle incelenmiş örnekler, açıklar ve önerilen asset/state üretim listesi olacaktır. Bu paket app/engine metin veya davranışını değiştirmez. Tam kaynak kapsamı ile tam üretilebilir hikâye kapsamı ayrı raporlanır.

## Sonraki iş paketleri

1. Onaylı sidecar anlam bilgisini gerçek seçilmiş kaynaklardan ComposedPage’e taşıma. Recall/family/occasion eklerinin kaynak zinciri korunur; yalnız eski whole-page fingerprint kopyalanarak yeni ekler saklanmaz.
2. Bütün anlatı sayfalarını değerlendiren saf bağlama: önce anlam/durum uygunluğu, ardından farklı anlatı anı/tekrar azaltma. Eski katı kurallar ve kaydedilmiş pinler korunur. Görsel için yeniden compose veya seed değiştirme yapılmaz.
3. Kesin kapsam açıklarına göre önceden guaj çizimleri üretme: nesne, mekân, kanonik arkadaş/durum ve yalnız metnin kurduğu açık bağlam. Asset onayı/digest/image decode/altText/kimlik denetlenir; farklı kimlikler sırf benzer habitat nedeniyle birleştirilmez.
4. Garantiye sayılan resmin AX ve kısa yükseklikte okunabilir metinle birlikte kaydırılabilir biçimde gösterimi. Son dikey ortalama, font ve kâğıt tercihleri korunur.
5. Katalog kabulünde uygulamanın sanat sözleşmesiyle uyum; bilinmeyen kimlik için genel orman fallback’i yok. Yeni seri bölümleri hazırlanırken aynı sözleşme; unlock eski pinleri kopyalar. Kayıtlı kitaplar veya hazırlanmış eski bölümler yeniden yorumlanmaz.

## Kabul sınırı

Anlam envanterindeki slot sayımı veya rastgele seed başarı oranı evrensel garanti değildir. Gerçek selector/safety/habitat/trait/fallback/recall/occasion/seri kurallarıyla bütün ulaşılabilir anlam birleşimleri için en az sayfa sayısı kanıtlanmalıdır. Belirsiz durumlar hedefli composer denetimine gider. Açık kombinasyon kalırsa raporlanır; kullanıcıya vaat tamamlandı denmez.

Her adım ayrı incelenebilir teslimdir. Üretim koda geçmeden yeni unit testler yazılır; AGENTS gereği yalnız nihai doğrulama penceresinde çalıştırılır. Kapsam aracı yalnız mevcut kaynakları okur, hiçbir masalı yeniden yazmaz. Yeni logging özel çocuk/kitap içeriği taşımaz. Uygulama entegrasyonu sonrasında mapping/pin/series/metadata uyumu ve gerçek reader görüntüsü test edilir.

## Öz denetim

Metin koruma kısıtıyla çelişen ek anchor cümlesi yok. İlk sayfa istisnaları bütün kitap imkânsızlığı diye sunulmuyor. Üç/iki görsel sayısı onaylı sert kota diye kullanılmıyor. İlk paketteki otomatik aday çıkarımı editoryal onayla karıştırılmıyor. Mevcut kitaplara otomatik migration ve runtime imagegen kapsam dışı.

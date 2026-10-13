# Değişiklik günlüğü

MagicPaper Kids'te `main`'e giren değişiklikler, en yenisi üstte. Her madde ilgili
commit'le eşleşir; ayrıntı commit mesajında ve bağlantılı belgede.

## 13 Ekim 2026

### Ürün kararları

- **Çocuk alanı tasarımdaki gibi** (Batuhan): yıldız sistemi var, rozetler kilitli
  hâlleriyle görünür, Masal ailem'de bir masala en çok 2 karakter (motor işi bekliyor).
  Bu karar `CLAUDE.md` ilke 7'deki "puan/ödül ekonomisi yok" kuralının önüne geçer;
  ilke metni henüz güncellenmedi.
- **Yıldız bu turda yalnızca kazanılır ve gösterilir**: her sabah 1, sonuna kadar okunan
  her farklı masal 1. Harcama, üst sınır ve abonelik bağı sonraki planlarda.

### Ana sayfa: telefon testinden sonra

- **Sahne ekranın ~%40'ı**: görsel ekran genişliğine sığar (kule ve ay kırpılmaz), üstündeki
  boşluk görselin gökyüzü rengiyle dikişsiz devam eder; çipler ve bu akşamın kartı ilk
  ekranda görünür.
- **Yeni sahne görselleri**: Batuhan'ın ChatGPT ile ürettiği gündüz ve gece manzarası,
  maskotsuz (`Assets.xcassets/Scenes`).
- **Ragi ayrı katman** (`HomeSceneMascot`): markanın kendi görseli; gündüz kitap okur,
  gece uyur. Açılışta tepeye süzülür, yavaşça nefes alır, dokununca bir kez zıplar.
  Çiplerin üstünde durur, altında kalmaz. Reduce Motion'da yerinde durur.
- **Hareketsiz dokunuşlar giderildi**: başlıktaki avatar ve isim ile alt bardaki sekmeler
  artık yaylı basma alıyor (önceden `.plain`, hiç tepki yoktu); seçilen sekmenin ikonu
  yaylanarak büyür; sekmeler arasında yumuşak kayma ve solma (Reduce Motion'da yalnızca
  solma); avatara dokununca hafif titreşim.
- **Dokunuş hissi** (`MPPressStyle`, tüm uygulama): basınca öğe alt kenarına çöker,
  bırakınca yaylanarak geri gelir (önceden yalnızca küçülüyordu, `sinkFlat` hiç hareket
  etmiyordu). Ana sayfanın ana eylemlerinde tek hafif titreşim (`MPHaptics`).
  Hareketi Azalt açıkken bilerek sönme kullanılır.

### Ana sayfa yenilemesi (`anasayfa-yenileme`)

Tasarım notu: `docs/superpowers/specs/2026-10-13-ana-sayfa-yenileme-design.md`.

- **İllüstrasyonlu başlık sahnesi** (`HomeScene`): tam genişlikte masal manzarası
  (gökyüzü, bulutlar, dağlar, mor çatılı kule, değirmen, kulübe, kitap okuyan Ragi).
  Uyku saatinde aynı sahnenin gece hâline yavaşça geçer; alt kenarı krem zemine karışır.
  Görseller `Assets.xcassets/Scenes` içinde. **Taslak:** yapay zekâyla üretildi, kalıcı
  sürümü illüstratör çizecek. (`e9c5ef1`, `3494bcd`)
- **Bilgi çipleri** (`HomeStatChips`): "Yıldızların" ve "Okuma serisi" sahnenin alt
  kenarına biner. Yıldız başlıktan buraya taşındı. (`e9c5ef1`)
- **Mor hero kartı**: "Bu akşamın masalı" sayfanın tek dolgun mor yüzeyi; uyku saatinde
  gece laciverti. Dört durum (kaldığın yerden, okunmadı, okundu, uyku) metinleri aynı;
  durumu lavanta kapak simgesi söyler. Butonda gradient kalktı. (`7f144b6`, `e9c5ef1`)
- **Her bölüm tek kart** (`HomeSection`): başlık kartın üst satırında, içerik altında.
  Okuma şeridi ("Bu hafta"), "Bu akşam nasıl bir masal olsun?" ve mod düğmeleri, devam
  eden seri, günün masalı. Pastel tonlar yalnızca kart içindeki ikon karelerinde;
  kart içinde kart yok. (`5063111`, `5eb9b80`)
- **Düzenli boşluk ve kart dili**: hero dışındaki kartlar beyaz, lavanta kenarlı, aynı
  yarıçapta, altta sert kenar (`mpKidSurface`). Bölümler arası 24, kart içi 12. (`5063111`)
- **Ekranda tek Ragi**: maskot sahnede; hero kartı ve mod sorusu maskotsuz. (`e9c5ef1`)
- **Erişilebilirlik**: gün etiketleri, selam ve "Herkes için" 4.5:1 kontrastın üstüne
  çıktı; en büyük yazı boyutunda günün masalı başlığı bölünmüyor. (`5eb9b80`)
- **Yıldız sayacı** (`MPStars`): sabahlar profilin oluşturulma tarihinden, masallar
  hesapla eşitlenen rozet defterinden türetilir; yeni depo yok, uygulamayı açmak yıldız
  kazandırmaz. Testler: `StarCountTests`. (`474c99e`)
- **Köşem sekmesine geçiş**: ana sayfa Benim köşem'i `openKidCorner()` ile açar;
  `kosem-sekme`'nin geçici `showKidCorner` köprüsü silindi. (`46fde6d`)

### Masal ailem

- Ana sayfanın diliyle yeniden tasarım: lavanta bulut bandı, çocuğun mor kahraman kartı,
  karakterler tek beyaz bölüm kartında pastel karelerle; seçim mor halka ve tik ile.
  Kareler satırda eşit yükseklikte. Seçim şimdilik tek (motor masal başına bir aile
  karakteri taşıyor). (`ef6e31a`)

### Benim köşem (`kosem-sekme`)

- Alt bar: Ana sayfa · Kitaplık · Yarat · Köşem. Benim köşem avatardan açılan katman
  olmaktan çıkıp sekme oldu; kapat yerine ebeveyn kapısı kilidi. (`30ef55c`)
- 8 rozetin hepsi görünür, kazanılmamışlar kilitli, "n / 8" sayacı. (`30ef55c`)
- Yıldız kutucuğu: yıldız · gün seri · masal, altında "Her sabah 1 yıldız gelir. Her masal
  1 yıldız." (`04a9e28`)

### Okuyucu

- Sayfalardaki tüm süslemeler kaldırıldı. (`cf9e656`)

### FAZ 19 — iOS yüzeyleri

- Widget'lar, uyku modu Live Activity, Siri kısayolları. (`20b79f3`)

### Altyapı

- Web okuyucu ve `.firebaserc` Firestore projesi `magicpaper-393a7-f2d31`. (`9884c9f`, `c5fad00`)
- Xcode proje dosyası yeniden biçimlendirildi (davranış değişikliği yok). (`c5fad00`)

### Doğrulama

- Uygulama testleri 662/0 (1 atlanan), ana sayfa birleşmesinden sonra; son `main`
  birleşmesinden sonra ilgili testler 26/0.
- Simülatörde (iPhone 17 Pro Max, iPhone 18 Pro): ana sayfa gündüz ve uyku durumu,
  en büyük yazı boyutu; Masal ailem dolu ve seçili hâli.

### Açık kalanlar

- Başlık sahnesinin kalıcı illüstrasyonu (illüstratör).
- Masal ailem'de en çok 2 karakter: motor ve içerik işi.
- Gece modunda saat çubuğu yazısının okunurluğu.
- Karakter düzenleyici ("Yeni karakter") eski görünümde.
- iPhone SE ve sahneli ana sayfada en büyük yazı boyutu kontrolü; telefonda deneme.
- `CLAUDE.md` ilke 7 ve `MagicPaper_Faz_Plani_Ekim.md` yıldız ve rozet kararına göre
  güncellenmedi.

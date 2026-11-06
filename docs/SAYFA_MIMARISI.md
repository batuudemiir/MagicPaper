# Sayfa mimarisi: uygulamaya uzaktan bakış

7 Kasım 2026. Batuhan'ın isteği: gezinme çubuğu, sayfa yapısı ve mimari yeniden
düşünülsün, her sayfa tek başına ele alınsın; ebeveyn bölümü arka planda dursun,
görünür olmasın. Kaynak listesi: `UX_KAYNAK_ARASTIRMASI.md`.

## Tek cümlede mimari

**Uygulama çocuğundur; ebeveyn alanı ona bir kapıdan girilen, üstüne açılıp kapanan
bir odadır.** Çocuk ekranı ebeveyn açıkken kaybolmaz, altta bekler.

## Neden

| Kaynak | Ne diyor |
|---|---|
| [Khan Academy Kids](https://support.khanacademy.org/hc/articles/360040168512-Parent-Quick-Start-Guide) | Avatar → kullanıcı seçimi → en altta "For Parents" → kapı |
| [Lingokids](https://help.lingokids.com/hc/en-us/articles/115005129325-What-is-the-Parents-Area) | Çocuğun profili → Parents Area → kapı |
| [Epic](https://screenwiseapp.com/guides/epic-reading-app-parental-controls) (üçüncü taraf kaynak) | Ebeveyn profili ayrı, parola ile |
| [You.i: çocuk için TV uygulaması](https://medium.com/you-i-tv/designing-a-tv-app-for-kids-9bb446b362be) | Giriş noktası geri planda dursun ki çocuk oraya yönelmesin |
| [UX Collective](https://uxdesign.cc/dont-forget-the-parents-when-designing-for-young-children-1043d7afe408) | Çocuk ve yetişkin deneyimi karışık değil, ayrı tasarlanmalı |
| [App Store 1.3](https://developer.apple.com/app-store/review/guidelines/) | Dış bağlantı ve satın alma kapının arkasında |
| [HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars) | Çubuk en sık kullanılan bölümler içindir, görünür kalır |
| [HIG Settings](https://developer.apple.com/design/human-interface-guidelines/settings) | Ayarları azalt; işe özgü ayar işin yanında olsun |
| `design-handoff/docs/NAVIGATION.md` | Ebeveyn alanı kapıdan sonra çocuk kökünün üstüne açılır |

Çocuk uygulaması kaynakları yardım sayfaları ve incelemeler; akademik kanıt değil.
Hiçbir kaynak "her ekranda kilit" önermiyor. Bugünkü düzen (23 Ekim kararı) bu yüzden
değişiyor.

## Yapı

```
Çocuk kökü (hep canlı)
├─ Ana sayfa   → Seri
├─ Masallar    → Raf · Masal detayı · Seri · Arama │ sheet: Kategoriler
├─ Kitaplık    → Seri                              │ sheet: Masal eylemleri
├─ Köşem       → Masal ailem → Kahraman · Yeni kelimelerim
│                 └─ en altta sakin "Büyükler için" → Ebeveyn kapısı
└─ Masal yaz   (eylem) → tam ekran: Mod → Kimler → Hazırlanıyor → Okuyucu → Masal sonu

Ebeveyn odası (kapıdan sonra üste kayar, kendi alt çubuğu)
├─ Özet      → Masal kitabı → Paylaş · Abonelik bitti
├─ Güvenlik
└─ Ayarlar   → Aile · Kendi sesin · Paylaş · Gizlilik → Hesabı sil
               profil sheet'i → Profili düzenle · Masal ailem · Kahraman │ sheet: İlgi alanları
```

Tam ekran akışlar: ilk açılış, okuyucu, uyku modu, masal yazma, kapı, paywall.

## Gezinme çubuğu: ikinci bakış (öneri, uygulanmadı)

İlk turda "çubuk 5 öğe kalsın" denmişti, ama çubuk sorgulanmamıştı. Sorgulanınca iki sorun çıktı.

**1. Köşem sekme olmayı hak etmiyor.** HIG'e göre çubuk en sık kullanılan bölümler içindir.
Köşem seyrek açılır: rozet, profil, karakter. Khan Academy Kids ve Lingokids bu içeriğe avatardan
giriyor. Ana sayfada zaten bir avatar var ve Köşem'e gidiyor. NN/g, 9 yaş altı için gezinmeyi
azaltmayı öneriyor; uygulamanın en küçük bandı 3-4 yaş.

**2. "Masal yaz" yanlış araçla kurulu.** `.search` rolü aramaya ayrılmış (HIG Search fields); bir
düğme gibi kullanılması [geçici çözüm olarak anılıyor](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/).
iOS 27 SDK'sında `TabRole.prominent` var (Xcode 27 SwiftUI arayüzünde doğrulandı; davranışı denenmedi).

### Önerilen çubuk

```
[ Ana sayfa · Masallar · Kitaplık ]   ( Masal yaz )
Her sekmenin başlığında sağda avatar → Köşem (push) → en altta "Büyükler için"
```

| Karar noktası | Öneri | Neden | Bedel |
|---|---|---|---|
| Köşem | Sekmeden çıkar, her sekmede avatarla açılır | Khan/Lingokids düzeni; tesliminizin ilk çubuğu da üç öğeliydi; kilitten boşalan yer dolar | 13 Ekim kararını geri alır; rozet ve yıldız daha az görünür (ilke 7 ile uyumlu) |
| Masal yaz | iOS 27'de `.prominent` rolü, daha eskide bugünkü düzen | Rol kendi işine dönmeli | iOS sürümüne göre üç dal; önce denenmeli |
| Masal yaz bir yer mi eylem mi | Bugünlük eylem kalsın | Sayfa yapmak mod seçimini sekmeye taşımak demek, daha büyük iş | HIG sapması sürer |
| Çubuğu kaydırınca küçültme | Hayır | Küçük çocuk için sabit çubuk öngörülebilir | Yok |
| "Kaldığın yerden" alt aksesuarı (`tabViewBottomAccessory`) | Şimdilik hayır, sonra denenebilir | Müzik uygulamasındaki gibi her sekmede devam; ama yalnız iOS 26+ ve sakinliği bozabilir | Yok |

Alternatif, Köşem'i sekme olarak korumak: bugünkü düzen, iş yok, ama çubukta en seyrek açılan
sayfa yer tutar. Kaynak zayıflığı: Epic ve Apple Books'un güncel sekmeleri doğrulanamadı; rakipler
cihazda açılıp bakılmadı.

## Her sayfa tek başına: bulgular

Koddan ve simülatörden; hiçbiri uygulanmadı.

| Sayfa | Şimdi ne var | Bulgu | Öneri |
|---|---|---|---|
| Ana sayfa | Bu akşam, yeni masal, Masallar önizleme, seri, günün masalı | İki ayrı "bugün": önizlemede "Bugün" kurdelesi, altta "Günün masalı", ikisi farklı masal. "Yeni bir masal yaz" çubuktaki eylemi tekrarlıyor | Tek "bugün" kalsın. Mod listesi kalabilir: mod seçerek başlamak çubuktan farklı |
| Masallar | Vitrin, raflar, kaldığın yerden, seçki, Anadolu, Klasikler, uyku, Kahramanı sen ol | Uzun ama amacı tek. "Kaldığın yerden" vitrinde de bölüm olarak da var (filtreli) | Kaldı |
| Kitaplık | Ragi, arama, onay notu, süzgeç, kaldığın yerden, seri, kitaplarım | Ragi "Bugün hangi masalı okuyalım?" diyor: Ana sayfa ve Masallar'la aynı soru. Görevi "benim masallarım" | Söz değişsin. Az kitapta arama ve süzgeç gizlensin |
| Köşem | Kim okuyor, sayılar, Masal dünyam, rozetler, Büyükler için | Rozet ve profil yerinde | Avatarla açılan sayfa olsun |
| Masal ailem, Yeni kelimelerim, Seri | Push | Masal ailem'de geri düğmesi lavanta üstünde lavanta, görünmüyor | Düğme zemini düzelsin |
| Kahraman | Push | Aynı sayfanın üç adı: "Kahramanımı düzenle", "Kitap karakteri", "Kahraman" | Tek ad: "Kahraman" |
| Masal yazma | Çocuk, mod, kimler, hazırlanıyor, okuyucu | Sağlam | Kaldı |
| Okuyucu, masal sonu | Tam ekran | Yazı boyutu Okuma ayarlarında da var, Ayarlar'da da | Ayarlar'dan kalksın; sesli okuma düğmesi ayrı karar |
| Özet | Sayılar, grafik, onay, son masallar, abonelik | Amacı net | Kaldı |
| Güvenlik | Korku, konular, süre, uyku saati, onay | Amacı net; tek ekranda çok karar ama hepsi güvenlik | Kaldı |
| Ayarlar | Profiller, aile ve ses, bildirim, okuma, hesap, destek, sil | Masal kitabı "Hesap" altında ve Özet'te; Abonelik hem Özet'te hem Hesap'ta. Masal kitabı ayar değil, ürün | Masal kitabı Özet'te kalsın, Ayarlar'dan çıksın |
| Profil sheet'i | Düzenle, karakter, aile, ilgi, masallar, sil | Sağlam | "Kahraman" adı |
| Kök akış: ilk açılış | Karşılama, giriş, onay, profil, bildirim, ilk masal | Akış okunarak bakıldı, gezilmedi | Ayrı denetim |
| iPad | Yatay okuyucu | HIG kenar çubuğu öneriyor; bakılmadı | Ayrı denetim |

## Sayfa sayfa

"Uygulandı" ilk turda yapılanlar; "Karar" Batuhan'ın seçimini bekleyenler.

### Çocuk sekmeleri

| Sayfa | Tek işi | Bugünkü sorun | Durum |
|---|---|---|---|
| Ana sayfa | Bu akşam ne okuyoruz | Kilit gereksizdi. Yıldız ve seri iki kez görünüyordu: başlık satırı ve okuma kartı | Kilit ve okuma kartı kalktı (Batuhan onayı), başlık satırı kaldı |
| Masallar (eski adı Günlük) | Hazır masalları keşfet | Kilit gereksizdi. "Günlük" iki anlama geliyordu: her günün masalı mı, anı defteri mi | Kilit kalktı, ad "Masallar" oldu (Batuhan onayı), ikon açık kitap. Kodda `GunlukView` adı kaldı |
| Kitaplık | Benim masallarım | Kilit gereksiz. Raflar, arama ve süzgeç aynı anda | Kilit kalktı |
| Köşem | Ben: kim okuyor, rozetler, karakterler | Çocuk için doğru yer ama ebeveyne giden kapı yoktu | "Büyükler için" buraya geldi |
| Masal yaz | Yeni masal | Çubukta bir eylem (HIG'den bilinçli sapma, 22 Ekim) | Kaldı: ürünün ana eylemi |

### Çocuk alt sayfaları

| Sayfa | Açılış | Durum |
|---|---|---|
| Seri, Yeni kelimelerim, Masal ailem, Kahraman | Push, alt çubuk görünür | Yapıldı (`e2fe1bf`) |
| Klasik detay, raf, klasik seri, arama | Push | Zaten öyleydi |
| Kategoriler, Masal eylemleri | Sheet | Doğru: kısa iş |
| Hepsinin zemini | Krem, sekmeler beyaz | Beyaza geçti: sekmeden detaya renk değişmesin |

### Tam ekran akışlar

| Sayfa | Durum |
|---|---|
| Okuyucu, masal sonu, uyku modu | Doğru: sürükleyici, alt çubuk yok |
| Masal yazma | Doğru: çok adımlı |
| İlk açılış (karşılama, giriş, onay, profil, bildirim, ilk masal) | Doğru |
| Ebeveyn kapısı | Doğru: hem odanın kapısı hem bağlama bağlı kapılar (paylaşma, silme, düzenleme). App Store 1.3 bunları istiyor, kalıyorlar |
| Paywall | Doğru: yalnızca ebeveyn tarafından |

### Ebeveyn odası

| Sayfa | Tek işi | Sorun | Durum |
|---|---|---|---|
| Oda | Üste kayar, "Çocuk modu" ile iner | Çocuk ekranını yok edip yerine geçiyordu | Üste açılıyor, çocuk altta canlı |
| Özet | Bu hafta ne oldu | Yok | Kaldı |
| Güvenlik | İçerik sınırları | Yok | Kaldı |
| Ayarlar | Geri kalan her şey | 7 bölüm. HIG ayarları azaltmayı, işe özgü ayarı işin yanına koymayı öneriyor. "Okuma" okuyucuda da var | **Karar:** "Okuma" bölümü okuyucu ayarlarına taşınsın |
| Masal ailem (buradan) | Karakterler | Ebeveyn alanında Ragi | Ragi kalktı |
| Profili düzenle, Aile, Ses, Kitap, Paylaş, Gizlilik, Abonelik bitti | Push | Yapıldı | Kaldı |

## Bilerek yapılmayanlar

- Ebeveyn alt çubuğu kaldırılmadı: üç bölüm teslimde var, çalışıyor. Tek listeye indirmek
  HIG'in "uygulama içinde uygulama" uyarısına daha uygun olurdu ama büyük bir yeniden yazım
  ve bugünkü sorunu çözmüyor.
- Gizli hareket (uzun basma, köşeye üç kez dokunma) yok: ebeveyn bulamazsa destek sorunu olur,
  ebeveyn birincil müşteri (ilke 8). Kaynaklar da görünür ama sakin giriş kullanıyor.
- Kapı değişmedi. Bir caydırıcıdır, güvenlik sınırı değil.

## Bilinen risk

Ebeveyn girişi artık tek yerde. Ebeveynin onu bulup bulamadığı gerçek kullanıcıyla denenmedi.

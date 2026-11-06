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

## Sayfa sayfa

"Uygulandı" bu turda yapılanlar; "Karar" Batuhan'ın seçimini bekleyenler.

### Çocuk sekmeleri

| Sayfa | Tek işi | Bugünkü sorun | Durum |
|---|---|---|---|
| Ana sayfa | Bu akşam ne okuyoruz | Kilit gereksiz. Yıldız ve seri iki kez: başlık satırı ve okuma kartı, ikisi de Köşem'e gider | Kilit kalktı. **Karar:** biri kalksın (öneri: başlık satırı kalsın, kart gitsin) |
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

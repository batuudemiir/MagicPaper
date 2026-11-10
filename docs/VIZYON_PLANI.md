# MagicPaper vizyon planı: "Her çocuğun kendi masal dünyası" (Faz 7-14, 12-24 ay)

## Context

Startup planının kodu (Faz 0-6) bitti. Batuhan, uygulamayı profesyonel startup seviyesine taşıyacak, geniş ve vizyoner bir plan istedi: her sayfanın yeni düzeni ve çalışma mantığı, tasarım, sakin bir ekonomi. **Ödeme sistemleri bu planın dışında**; en sonda not olarak duruyor.

Yedi araştırma yapıldı (8-11 Kasım 2026):

1. **Açık kaynak kod:** Wikipedia, Kickstarter, Readium, isowords, Firefox (gerçek dosyalar; GPL ve AGPL'den yalnızca fikir).
2. **Çocuk ve aile uygulaması araştırması:** Radesky 2022 (JAMA), RITEC, AB DSA md. 28, COPPA 2025, Apple 1.3.
3. **MagicPaper denetimi:** 22 boşluk, bütün sayfaların envanteri.
4. **Ödül ve koleksiyon:** Deci 1999, Marinak ve Gambrell 2008, Khan Kids, Lingokids, Teach Your Monster, Epic, Duolingo ABC.
5. **Vizyon, pazar ve zanaat:** Yoto, Tonies, Lunii, Wonderbly, Pok Pok, Sago Mini, Nosy Crow; Sesame Workshop 2012, NN/g, ADA jürileri 2023-26; Takacs 2015, Strouse ve Troseth 2023, Chang 2015; Apple Foundation Models (iOS 26.1 Türkçe), TürkYayBir 2025.
6. **Motor ve içerik denetimi:** 17 blueprint, 843 satır çeşidi, 56 klasik; uyku modunda tek olay örgüsü, 7-10 yaş boş, %50-85 cümle tekrarı.
7. **Ekran düzeni:** kıyas ürünlerin sayfa kalıpları (Khan Kids, Pok Pok, Lingokids, Epic, Yoto, Duolingo, Headspace) ve MagicPaper'ın 13 sayfası için ekran görüntüsü üstünden yeni düzen tasarımı.

### Kuzey yıldızı

> **MagicPaper, bir ailenin akşam ritüelini taşıyan, çocuğun büyüdükçe büyüyen kendi masal dünyasıdır.** Yapay zekâ oyuncağı değil, bir çocuk yayınevi: yazılır, ciltlenir, ses alır, bazen basılır.

Kazananların ortak dersi: **ses + uyku + aile** sevgiyi yaratır; **tüketilen şey işin kendisidir** (Tonies'te figürler kutunun 2,8 katı gelir; Wonderbly'nin basılı kitabı); **"yapay zekâ olmayan" seçimler bir hendektir**. Kıyas ekranların ortak kalıbı: **tek baskın eylem** (Khan Kids'in oyna düğmesi, Duolingo'nun tek düğümü), **ertelenen ödül** (Lingokids, Headspace), **ebeveyn girişi en altta** (Khan Kids), **çocuk tarafında hiçbir sayaç baskısı yok** (Pok Pok).

### Vizyonun üç ayağı

| Ayak | Bugün | 12 ay | 24 ay |
|---|---|---|---|
| **Masal dünyası** | Ad, Masal ailem, seri | Yerler ve anılar hatırlanır, Odam, koleksiyon | Dünya haritası, yıllık, kardeşler aynı masalda |
| **Akşam ritüeli** | Okuyucu, gece teması | Ses öncelikli uyku kapısı, birlikte konuşma | Aile sesi, uzaktan kayıt, uyku arkı çeşitliliği |
| **Yayınevi** | PDF, 56 klasik | Basılı kitap pilotu, haftalık içerik | Hediye kutusu, diaspora, iki dilli okuyucu |

### Batuhan'ın kararları

- Ekonomi sakin harcama: yıldız kalıcı koleksiyona harcanır (8 Kasım).
- Kapsam bütün uygulama (8 Kasım).
- Aile özellikleri bu turda Release'te kapalı kalır (8 Kasım).
- Dolapta kozmetik serbest, kimlik parçaları (ten, saç) kapılı (11 Kasım).
- İlk açılış tek ekran olarak tasarlanır; giriş sırası hukuk onayıyla bayraktan değişir, o zamana kadar giriş masaldan önce (11 Kasım).

## Ortak düzen kuralları (Design law'a girer)

- **Ölçü:** 390 pt genişlik, kenar `screenGutter` 20, içerik 350. Alt çubuk 86 + ev göstergesi ≈ 120; **kıvrım ~700 pt**, görünür içerik ~580. SE'de ~540: kural "başlık + bir kahraman alan + ikinci bölümün ilk satırı" görünür.
- **Dokunma:** yeni token `MPSize.minTouchHero` = 64, ekranın tek birincil öğesi için (bugün `minTouchKid` 56). Çocuk akışında chip 44 (`chipHeightKid`; bugün 38). Geri kalanı ≥ 48. Alt kenarda aktif hedef yok.
- **Ritim:** sekme başlığı `MPKidTabHeader`, bölümler 32 pt boşlukla ayrılır, panel yok; kart yalnızca dokunulan öğede ve `mpEdge` ile. Ekran başına tek `primary`.
- **Okul öncesi (Sesame 2012, NN/g):** dokunma anında tepki; bekleme asla spinner değil, sahnelenmiş bekleme ve 2 sn'de atlama; sesli yönerge hep görselle, eylem cümlenin sonunda; çıkış ve ebeveyn için basılı tutma ya da çift dokunuş.
- **Delight bütçesi:** her hareket ya *üretken* (geri bildirim; `press`/`easeOut`, tek ses) ya *anlatımsal* (ritüel; `slow`/`spring`, Ragi beat'i, melodi, tek titreşim). Ekran başına en çok bir anlatımsal an, masal başına iki; kaydırırken hiçbir şey oynamaz.
- **Gradient:** `MPGlowBackground` (ilk açılış zemini) kalkar; düz krem.
- **Dil:** `docs/SES_VE_SOZ.md`'ye ad tablosu: seri masal, üst üste gün, Favorilerim, Kahraman, Odam, yıldız kumbarası, çıkartma, Dolap, uyku kapısı.

## Sayfa düzenleri (13 ekran)

Ölçüler 390 pt telefon için pt; "kıvrım" ~700.

### 1. Ana sayfa: "Bu akşam ne okuyoruz?"

```
İyi akşamlar,                     eyebrow
İrem                              MPKidTabHeader 34
★ 25 yıldız · 3 gün üst üste      HomeStatLine 24 → Odam
┌ sahne + Ragi            180 ┐
│ Kaldığın yerden              │   HomeHeroCard
│ İrem ve Uykucu Ay  Sayfa 3/5 │
│ [ Okumaya devam et ]      64 │   primary
└─────────────────────── 346 ──┘
Yeni bir masal yaz                HomeSection
☾ Uyku öncesi              › 64   MPListRow ×3     ── kıvrım
✦ Yeni şeyler öğrenelim    › 64
▲ Maceraya çıkalım         › 64
(Devam eden seri, varsa)   120    SeriesCard
Masallar            Tümü › 176    HomeGunlukPreview, 4 kapak
```

- Kart `TonightState`'e göre: `resume` "Okumaya devam et"; `unread` "Bu akşamın masalı / Masalı oku"; `readToday` "Bugün okudun. Yarın yeni bir masal seni bekliyor." + ikincil "Bir masal daha"; `bedtime` "Uyku masalına geç". **İlerleme çubuğu kalkar**, "Sayfa 3 / 5" yeter.
- Seri kartı modların altına iner (bugün üstte, modları kıvrımın altına itiyor). Önizleme 8 kapaktan 4'e.
- Bugünkü ekran görüntüsünde sahne 240 ve kart 400+ pt; modlar çubuğun altında kesiliyor. Yeni: sahne 180, üç mod kıvrımın üstünde.
- SE: sahne 140, önizleme kalkar. AX5: yatay satırlar dikey olur, satırlar iki satıra uzar.
- Ölü kod silinir: `HomeScene`, `HomeModeCard`.

### 2. Masallar: keşif, 8 bölüm → 5

```
▒ vitrin, kenardan kenara          400 ▒  GunlukHeaderCarousel
▒ Masallar                  (🔍)      ▒
▒ BU HAFTANIN SEÇKİSİ · Kırmızı Başlıklı Kız
▒ Grimm · 9 dk · 3-7 yaş  [ Masalı oku ] 52 (secondary)
Hangi raftan okuyalım?                   GunlukSection
▢ ▢ ▢ ▢ ▢  104×128                      GunlukShelfTile  ── kıvrım
Bu haftanın seçkisi        Tümü › 176    RankedPickCard ×3
Dünya klasikleri           Tümü › 176    ClassicShelfCard
░ Uyku vakti + "Kendi masalını yaz" ░   GunlukNightZone, Ragi walking
```

- Vitrin **400 pt'e sabitlenir** (bugün 6,9"de ≈ 520, bütün ilk ekran). Beş raf kapısı kıvrımın üstüne çıkar.
- Kalkar: "Kaldığın yerden" (yalnızca Kitaplık'ta), "Anadolu'dan" rafı (kapı var). "Kahramanı sen ol" → "Kendi masalını yaz".
- Vitrin düğmesi `secondary` kalır; ekranın tek `primary`'si yok, çünkü vitrin haftalık, raf kalıcı.
- SE: vitrin 300. AX5: vitrin metni büyür, düğme altına iner; raf başlıkları 2 satır.

### 3. Kitaplık: benim masallarım

```
Kitaplık                          34
🦝 reading "8 masalın, 3 klasik burada."  SpeechBubble 76
Kaldığın yerden                   HomeSection
┌ kapak 72×96 │ Rapunzel         ┐
│             │ Klasik · Sayfa 2/6 ▶ 112   ContinueCard, 64 hedef
(Serim, varsa)              120   SeriesCard
Kitaplarım          Son okunan ▾  MPSectionHeader + sırala
Tümü · Uyku · Öğrenelim · …  38   chip (≥ 6 kitap)   ── kıvrım
┌ kapak ┐ ┌ kapak ┐  165×232 + 44  MPBookCover, 2 sütun
```

- "Kaldığın yerden"in tek evi; en çok 3 satır, sonra "Tümü". İlerleme çubuğu yerine "Sayfa 2 / 6".
- Arama kutusu kalkar; `MPCircleButton("magnifyingglass")` Kitaplarım başlığına girer (≥ 6 kitapta).
- Lavanta kart içinde kart kalkar: Ragi düz `SpeechBubble`. Bugün "Kaldığın yerden" y≈560'ta, yeni y≈190.
- Boş: `MPStateView(.reading)` "Kitaplığın henüz boş / İlk masalın burada duracak." eylem "Masal yaz"; selam kalkar (tek Ragi).
- SE: 2 sütun 155×218. AX5: tek sütun, sırala simgeye iner.

### 4. Odam (eski Profil)

```
Odam                              34
Kim okuyor?  (İ) (A) (+)         100    MPAvatar 56
┌ kahraman sahnesi            240 ┐    HeroStage (AvatarView) → Dolap
│ 🦝 waving "Merhaba İrem!"       │    tek Ragi
└─────────────────────────────────┘
★ 25 yıldız · Her sabah 1, her masal 1.  64  kumbara satırı → Dolap  ── kıvrım
Odamda                            HomeSection
👕 Dolap            3 yeni şey › 64
🏷 Çıkartma albümüm   9 çıkartma › 64
♥ Masal ailem                   › 64
📖 Yeni kelimelerim             › 64
Rozetlerim                 3 / 8       MPBadgeCard 3 sütun
🔒 Büyükler için                  48   ghost (Khan Kids: en altta)
```

- Çocuğun kahramanı ilk ekranı doldurur; bugün sayfa metin ağırlıklı ve ateş simgeli üç sayaç var. Ateş (üst üste gün) buradan kalkar, Ana sayfa stat satırında kalır.
- Kahraman kaydı yoksa sahne kit varsayılanını gösterir, balon "Kahramanını giydirelim mi?".
- Masal bittiği gün sahne 2 sn `celebrating` pozunda.
- SE: sahne 200. AX5: balon sahnenin altına, rozet tek sütun.

### 5. Odam → Dolap (gardırop ve dükkân)

```
(‹) Dolap                   ★ 25 pill   MPTopBar
┌ avatar önizleme          220 ┐        AvatarView, canlı
Ben · Kıyafet · Şapka · Eşya   40      MPSegmented
┌  ┐ ┌  ┐ ┌ ★5 ┐  104×128  3 sütun     giyili / sahip / ★fiyat / yetmiyor  ── kıvrım
────────────────────────────────
[ Giy ]  /  [ ★ 5 · Al ]  /  [ Kaydet ]  64   CreationFooter, primary
```

- **Ben** sekmesi (ten, saç, saç rengi, gözlük; 23 kit parçası, hep ücretsiz) **kaydederken kapılı**. Kıyafet, şapka, eşya kozmetik; **kapısız** (para geçmiyor).
- "Yetmiyor" durumu: hücre yine dokunulur, önizleme serbest; alt yazı "★ 5 gerekiyor, 3 yıldızın var". "Az kaldı" ünlemi, geri sayım yok. Yıldız eksiye düşmez, hiçbir şey kaybolmaz.
- Satın alma tek düğmede: bas → "Alındı!" + `MPHaptics.success`; modal yok.
- Ragi yok (Odam az önce gösterdi).
- **Doğrulanmadı:** şapka ve eşya çizimi yok; kit yalnızca bere, çanta, gözlük taşıyor. Faz 9'un ilk adımı kit kalitesini gözle değerlendirmek.
- SE: önizleme 160. AX5: segment iki satır, grid 2 sütun.

### 6. Odam → Çıkartma albümü

```
(‹) Çıkartma albümüm         9 çıkartma
🦝 happy "Her bitirdiğin masal buraya bir çıkartma bırakır."  72
Kasım 2026                        MPSectionHeader
┌🌙┐ ┌🦊┐ ┌🚀┐  104×104 + başlık 36   StickerView (yeni)
┌  ┐ ┌  ┐ ┌ - ┐   son hücre kesikli "Sıradaki masal"   ── kıvrım
Ekim 2026 …
```

- Çıkartma: masalın kapak sanatı ya da mod simgesi yuvarlak kâğıtta; dokununca `mpSheet`: büyük çıkartma, masal adı, tarih, "Masalı aç". Künye satırı ("İrem'in 9. masalı") bu sheet'e taşınır.
- Eksik sayısı, "hepsini topla" yok.
- Boş: `MPStateView(.reading)` "Albümün henüz boş / İlk masalı bitirince ilk çıkartman gelir."

### 7. Masal yaz: mod adımı

```
(×)                               56
İrem için ▾ (2+ çocuk)            40    CreationChildPicker
Nasıl bir masal olsun?            34
Birini seç, gerisini biz hazırlayalım.
Bu akşam için önerimiz: Uyku öncesi.
┌ ☾ Uyku öncesi · Günü sakin bir hikâyeyle ┐ 80   CreationChoiceRow (bugün 56)
┌ ✦ Yeni şeyler öğrenelim                 ┐ 80
┌ ▲ Maceraya çıkalım                      ┐ 80
   ✨ Bana sürpriz yap               48    ghost   ── kıvrım
🦝 pencil "Sen seç, masalı birlikte yazalım!"  72
```

- 7 Kasım kararı korunur; satırlar 80 pt ve `mpEdge` ile (dokunulan kart). "Bana sürpriz yap" ghost kalır (strateji, mod değil).
- 3-4 yaş için seçenekler `MPSound` ile sesli okunabilir (Lunii deseni), Faz 13.

### 8. Masal yaz: "Masalda kimler olsun?"

```
(‹)
Masalda kimler olsun?             34
İrem · Uyku öncesi      Değiştir  48
Neyi öğrenelim? · İstersen seç, istersen bize bırak.
(chip)(chip)(chip)(chip)        2×44   MPChip 44 (yeni chipHeightKid)
Yol arkadaşı
┌ 🦊 Tilki Fındık · meraklı ┐   72    CreationChoiceRow ×3   ── kıvrım
Masal ailem  (Anne)(Dede)(+ Yeni)  44
────────────────────────────────
[ ✨ Masalı yaz ]                 64    CreationFooter, primary
```

- Yapı aynı; chip 38 → 44, satır 72, düğme 64. Ragi yok (kural istisnası). Seçim yoksa düğme yine açık: MagicPaper seçer.
- SE: konu chip'leri tek satır kaydırmalı. AX5: chip'ler tam genişlik, düğme iki satır olabilir (72).

### 9. Okuyucu: kontroller açık / gizli

```
açık                              gizli
(×)       (♥ | Aa) 42/54          (×)
illüstrasyon ≤ %45                illüstrasyon
masal metni MP.F.read             masal metni
┌ ‹   Sayfa 3 / 8   ▶   › ┐ 64    ── 2 pt ilerleme çizgisi (yeni)
```

- 21 Ekim cam kuralları korunur. Alt çubuk 64, geri ve ileri 64×64, ortada sesli okuma 64; çubuk ev göstergesinden `lg` yukarıda.
- **Gizliyken 2 pt ilerleme çizgisi** (bugün yok; `showsSecondary` kapalıyken hiçbir şey çizilmiyor): çocuk nerede olduğunu kaybetmez.
- "Kendim okuyorum / Ragi okusun" kapak sayfasında seçilir, ayarlarda değil (Nosy Crow deseni). Son sayfada ileri düğmesi bayrak (`isLastPage`, var).
- Uyku modu parlaklık ve gece kâğıdı ayar kapsülünde (ayrı ekran değil).

### 10. Masal sonu (gündüz)

```
○ kâğıt patlaması (bir kez)
🦝 happy, cheer                   180
"Harika bir masaldı!" → soru      SpeechBubble
Bravo, İrem!                      34
Ay'ın Bahçesi masalını bitirdin.  24
┌ çıkartma 120 ┐  ★ +1   📖 3 kelime   128   çıkartma merkezde
│ 🌙 Ay'ın Bahçesi │  → Odam'a uçar
(rozet satırı, yeniyse)           56
[ ✨ Bir masal daha ]             64    primary   ── kıvrım
      Bitir                       48    ghost
```

- Sıra: çıkartma (`spring` ile büyür) → bir vuruş → yıldız ve kelime yanına kayar → soru → çıkartma küçülüp sağ alt köşeye uçar; Odam sekmesinde bir kez sessiz nokta (yeni "taze çıkartma" bayrağı, `MPBadgeNews` gibi). Tek titreşim.
- Tekrar okumada çıkartma ve yıldız yok; kutu "Bu masalı yine okudun."
- Seri: "Devam ettir" `secondary`, birincilin üstünde. Gece sürümü aynı kalır; çıkartma sessizce verilir.
- Bugünkü ekran görüntüsünde 250 pt boşluk ve "+1 yıldız" kutusu merkezde; yeni düzen boşluğu çıkartmaya verir.
- SE: Ragi 140, çıkartma 96, kaydırmasız sığar.

### 11. Özet (ebeveyn)

```
Özet                   Çocuk modu  48    MPParentHeader
Bu hafta · 9-15 Kasım              20
(İrem)(Ali)                        44    çocuk seçici
⚠ 1 masal onay bekliyor [Onayla]   72    yalnızca onay açıkken
"Bu hafta 4 masal, 38 dakika, 3 akşam üst üste."   içgörü cümlesi (yeni)
┌ 4 masal ┐ ┌ 38 dk ┐ ┌ 3 gün ┐ ┌ 4 çıkartma ┐  88   MPStatTile   ── kıvrım
Günlük okuma (çubuk)              140
Son masallar               Tümü › MPListRow ×3
Abonelik  Hikaye Kahramanı · 2 Ara 56   en altta (Khan, Epic deseni)
```

- Yeni: içgörü cümlesi, dördüncü kutu "çıkartma" (ebeveyn çocuğun ne topladığını görür), hafta tek tanım, "Okuma serisi" → "Üst üste gün". Boş hafta: "Bu hafta henüz masal okunmadı."
- Ragi yok. Grafik tek.

### 12. Ayarlar (ebeveyn) ve çocuk profil sayfası

```
Ayarlar                          Profil (push)
Çocuk profilleri                 ‹ Geri   İrem
▭ İrem · 6 yaş            › 56   (avatar 72) İrem · 6 yaş
▭ Ali · 4 yaş             › 56   Profili düzenle          ›
+ Profil ekle               56   Kahraman (Dolap › Ben)   ›
Aile ve ses (Release'te gizli)   Masal ailem              ›
Bildirimler                      İlgi alanları            ›
▭ Masal saati hatırlatması ⏻     Masalları                ›
▭ Hatırlatma saati 20:30  ›      Yıldız ve çıkartmalar    ›   yeni: salt okunur defter
Hesap  ▭ Abonelik · ▭ Gizlilik   ─────────────────────────
Destek ▭ Bize yaz · ▭ Değerlendir   Profili sil (danger) 56
Tüm verileri sil (danger)
```

- Profil sayfası sheet'ten push'a (`MPParentHeader(onBack:)`); sheet → push → sheet zinciri ve ölü `ProfilePickerSheet` kalkar.
- "Okuma" bölümü kalkar: `readAloud` anahtarı (`SettingsView.swift:253`) okuyucu ayarlarına taşınmıştı, burada kalıntı.
- "Yıldız ve çıkartmalar": tarih · +1 · neden; tarih · −5 · "Mavi şapka". Açıklama: "Yıldızlar yalnızca okuyarak kazanılır, parayla alınamaz, kaybolmaz."
- Destek sheet'i: sürüm bilgisi, Mail yoksa kopyala, SSS.

### 13. İlk açılış: tek karşılama + ilk masal

```
🦝 onBook                         160
Her çocuğun kendi masal dünyası    34
Adını söyle, ilk masalı birlikte yazalım. Kahramanı o olsun.
┌ Çocuğun adı              ┐      52    MPTextField
(3-4)(5-6)(7-8)(9-10)              44    yaş bandı chip'leri
[ Masalı yaz ]                    64    primary   ── kıvrım
 Giriş yap (Apple · Google)        48    ghost
Reklam yok, satın alma çocuğa kapalı.  footnote + KVKK bağlantısı
```

- Sonra `StoryPreparationView` ("İrem'in ilk masalı yazılıyor") → okuyucu → masal sonu ilk çıkartma ve "İlk masal" rozeti → Ana sayfa. Hatırlatma sorusu ilk masal bittikten sonra, Ana sayfa üstünde sheet.
- **Sıra bayrakla:** `storyBeforeAccount` kapalıyken bugünkü sıra (giriş → onay → ad → masal); hukuk onayıyla açılır. Tasarım ve kod ikisini de taşır.
- Bugün: 3 parıltılı sayfa (gradient `MPGlowBackground`), giriş, onay, profil, bildirim, ilk masal. Yeni: tek ekran, düz krem zemin.
- SE: Ragi 110. AX5: Ragi 80, chip'ler 2×2.

## Fazlar

### Faz 7: Omurga (sayfa yapısı)

Yukarıdaki 13 düzenin uygulanması; ekonomi parçaları (Odam sahnesi, Dolap, albüm, çıkartma anı) Faz 9'a bırakılır, Odam bu fazda bugünkü veriyle yeni düzene geçer.

- Tek kapı: `MPRouter.requestGate(for:then:)`; bütün ayrı `fullScreenCover`'lar teke iner.
- Sözlük ve `docs/SAYFA_MIMARISI.md` sayfa başına "amaç, bölümler, birincil eylem, giriş ve çıkış, boş durum" tablosuyla yeniden yazılır.
- Yeni token'lar: `minTouchHero` 64, `chipHeightKid` 44.
- Olası hatalar: klasiğin masal sonu "Bravo, !" (`ClassicReading` `childName: ""`); "yeni kelime" sayısı bütün kelimeleri sayıyor.
- Dosyalar: `Views/HomeView.swift`, `DesignSystem/Pastel/MPHomeChrome.swift`, `Screens/Gunluk/GunlukView.swift`, `GunlukHeader.swift`, `Views/LibraryView.swift`, `Screens/KidCorner/KidCornerView.swift`, `Screens/StoryCreation/*`, `Screens/StoryReader/ReaderChrome.swift`, `StoryEndingLeaf.swift`, `Screens/Parent/*`, `Views/SettingsView.swift`, `Screens/MPSheets.swift`, `Screens/MPRouter.swift`, `ContentView.swift`, `DesignSystem/Pastel/MPLayout.swift`.

### Faz 8: İlk açılış, güven ve hız

- 13. düzen; `storyBeforeAccount` bayrağı (`MPRemoteFlags`, varsayılan kapalı).
- Bildirim izni ilk masaldan sonra; önce değeri anlatan kart (Firefox deseni).
- Kullanım paylaşımı varsayılan kapalı (`ParentConsentView.swift:11`).
- Güven bloğu kurulumda ve Ayarlar'da, yalnızca doğru olanlar; künye ve "yazıldı, ciltlendi" dili ebeveyne görünür.
- Yasal bağlantılar tek alan adı (`curl -I` ile seçilir; ikisi de yoksa Batuhan'a sorulur).
- Hız: `UILaunchScreen` krem; kitaplık arka planda çözülür ve yalnızca değişen masal yazılır (`StoryGenerationManager.swift` 27-39); kritik olmayan başlatmalar ilk kareden sonra.

### Faz 9: Odam ve sakin koleksiyon

Kurallar (CLAUDE.md ilke 7 ve `docs/RAGI.md` güncellenir): yıldız bugünkü gibi kazanılır, tekrar okuma vermez; hiçbir şey kaybolmaz; para yok; şans yok; masala yakın ödül (çıkartma otomatik); yem yok; sürpriz seyrek; ebeveyn Güvenlik'ten kapatır, Özet ve profil sayfasından görür.

- **4, 5, 6 ve 10. düzenler.** Yeni modeller: `StarLedger` (çocuk başına, büyüyen ve birleşebilen, `MPBadgeLedger` gibi), `StickerAlbum`, kozmetik kataloğu (`Content/` JSON, `avatar_kit.json`'a `price`), `AvatarSpec`'e sahip olunan parçalar, "taze çıkartma" bayrağı. `SyncCollection.collection`, Firestore kuralı ve testi.
- **Üç raf:** masal çıkartmaları (ücretsiz, otomatik); Kahramanımın dolabı (kozmetik yıldızla, kimlik kapılı; `IllustratedBookAccess`'ten ayrılıp Release'te açılır, bulut görsel kapalı); kitaplık süsleri (raf rengi, kapak şeridi, kâğıt dokuları).
- **Fiyat** (~2 yıldız/gün): aksesuar 6, süs 8, kıyafet 14, raf ya da kâğıt teması 20; 3-5 yaş "kolay fiyatlar" yarı. Açılış kataloğu ~30 eşya.
- **İlk adım:** kit kalitesi simülatörde gözle; yetersizse Dolap ertelenir, çıkartma ve süslerle gidilir. Ragi'nin kıyafetleri illüstratör işi.

### Faz 10: Masal dünyası hatırlar (içerik ve motor)

`faz-21-varyasyon` dalı (12 commit) birleştirilerek başlar.

- Uyku arkına çeşitlilik: tek olay örgüsü → 3 mekanizma; Book Intelligence'ın 5 uyku şekli ve `x_refrain_bedtime` nakarat deneyi canlıya.
- 7-8 bandı için standart ark (bugün boş).
- Yer ve anı hafızası: `StoryOrigin`'e etiketler; deterministik "hatırlıyor musun" cümlesi; Odam'da Masal haritası.
- Masal ailem orta beat'leri; kardeşler aynı masalda.
- Klasikler ve kapaklar uzak katalog paketine; haftalık içerik güncellemesiz.
- Apple Foundation Models yalnızca deneme: eşanlamlı ve cümle varyasyonu, doğrulayıcı kapıda; asla olay örgüsü.

### Faz 11: Akşam ritüeli (ses öncelikli)

- **Uyku kapısı:** tek dokunuşla ekran karartılır (Chang 2015: sıcak tema yetmez, parlaklık düşmeli), tek büyük kontrol, uyku sayacı, ses biterken söner; `SleepModeView` ve `MPSleepPlayback` üstüne; v2 açıkları kapanır; `sleepMode` bayrağı açılır.
- **Rutin kartı:** "Diş, pijama, masal, ışık"; masal sonu yankılar.
- **Birlikte konuşalım, okuyucuda:** Ragi'nin "Konuşalım" dokunuşu 2-3 sayfada, ebeveyn başlatır (Strouse ve Troseth 2023; PEER, CROWD). Güvenlik'ten kapatılır.
- **Aile sesi hazırlığı:** cihazda gerçek mikrofonla doğrulama; açma kararı Batuhan'da (App Check, hız sınırı, KVKK ses onayı, politika tutarsızlığı).
- **Ses:** gerçek kayıt öncelikli; premium `tr-TR` sesleri ve Personal Voice deney; ortam sesi katmanı (gerçek foley, "restoran testi").

### Faz 12: Yayınevi (fiziksel ve hediye)

- Yıllık ("Bu yıl İrem'in dünyasında") Faz 10 hafızasından.
- Basılı kitap pilotu: `MPStoryPDF` A5'e taşma payı, kesim, CMYK; tek Türkiye basım ortağıyla 10 kitap; "yakında" sekmesi gerçek olana kadar kalkar.
- Hediye kutusu tasarımı (ödeme turu bağlantılı).
- Haftalık içerik ritmi (Yoto Club deseni).

### Faz 13: Zanaat (hareket, ses, tipografi)

- Ragi kukla kuralları: küçük titreme serbest, hazırlık ve takip; `PhaseAnimator`, `KeyframeAnimator`.
- Kapaktan okuyucuya `matchedTransitionSource` + `.navigationTransition(.zoom)` (iOS 18+), öncesi `matchedGeometryEffect`.
- Kâğıt greni ve kenar gölgesi Metal `layerEffect` (Inferno, MIT).
- Ses: sabit perde-anlam haritası, hafif stereo pan, uyku modunda kısık; iki AHAP (sayfa, masal sonu).
- Tipografi: Nunito ve Baloo 2 kalır; fi/fl ligatürleri kapatılır (noktasız i); I, l, ı ve ğ, ş, ç diyakritik boşluğu okuyucu boyutlarında denetlenir.
- Okuma eşliği `TextRenderer` (iOS 18) ile glif düzeyinde; "kelimeye dokun, duy"; 3-4 yaş için seçenekler sesli okunur.

### Faz 14: Ebeveyn değeri, sakin geri dönüş, kalite altyapısı

- Akıllı hatırlatma (`MPReminder.swift`): okunan akşam gitmez, 7 gün tek tek planlanır, metin o akşamın masalını söyler, varsayılan kapalı.
- Değerlendirme isteği: ebeveyn alanında, üçüncü biten masaldan sonra Özet'te, 60 gün arayla, çökme sonrası değil (`MPReviewPolicy`).
- TipKit yalnızca ebeveyn alanında, en çok 3 ipucu.
- Durum görüntü testleri (Kickstarter `orthogonalCombos`): 13 düzen, normal ve AX3. App Store görselleri testten (isowords).
- Erişilebilirlik artıkları: dokunma hareketli öğeler `Button`; `dynamicTypeSize` tavanları; `MPStateView` ebeveynde değil (`ParentConsentView.swift:165`).

## Ufuk (24 ay, bu planda yalnızca temel)

Diaspora (Almanya, Hollanda; iki dilli okuyucu ikinci motor ister); uzaktan kayıt (anneanne, App Clip ya da web); SharePlay okuma; hazırlık masalları (ilk diş hekimi, ilk okul; tedavi iddiası olmadan).

## Yapılmayacaklar

Ödeme ve abonelik; aile özelliklerini açmak; streak baskısı, lig, XP; parayla yıldız; rastgele paket; sınırlı süreli eşya; Ragi'nin kıyafetleri; fotoğraf yükleme; disleksi fontu; sağlık iddiası; karanlık mod, iPad, String Catalog; masal sonunda yem, otomatik geçiş, çocuğa satış; Epic tarzı tanıtım karuseli Ana sayfada.

## Ödeme turu için hazır notlar (bu planda yapılmaz)

Paywall Release'te kapalı görselli masalı satıyor; hiçbir şey kilitli değil; yıllık ürün yok, fiyatlar elle; deneme hakkı kontrolsüz; 3.1.2 açıklaması ve "Aboneliği yönet" yok; paywall'da Ragi. Pazar: Türkiye abonelik fiyatı ABD'nin ~1/3'ü, Türk uygulamalarının gelirinin %89'u yurt dışından; tüketilen ürün (basılı kitap, yıllık, hediye) ve diaspora marjı taşır. Ayrıntı `docs/YAYIN.md`'ye.

## Kritik dosyalar

- **Sayfalar ve gezinme:** Faz 7 listesi.
- **Ekonomi:** `Screens/MPStars.swift`, `Screens/MPMilestones.swift`, `Screens/ArtKit/avatar_kit.json`, `AvatarKit.swift`, `AvatarFigure.swift`, `StoryEngineBridge/AvatarStore.swift`, `Screens/Parent/BookCharacterView.swift`, `StoryEngineBridge/Account/*`, `firebase/firestore.rules`.
- **Motor ve içerik:** `StoryEngine/Sources/StoryEngine/Offline/SelectionScoring.swift`, `Offline/Series/SeriesPlan.swift`, `Resources/blueprints/*`, `templates/bedtime/*`, `Content/Experiments/x_refrain_bedtime.json`, `Models/Story.swift`, `StoryEngineBridge/RemoteContent/*`, `Screens/Gunluk/Model/classics_catalog.json`.
- **Ritüel:** `Screens/SleepMode/*`, `Screens/MPSpeech.swift`, `StoryEngineBridge/Family/*`, `Screens/StoryReader/StoryPageView.swift`, `StoryTalkPrompts.swift`.
- **Yayınevi:** `Screens/MPStoryPDF.swift`, `Screens/Parent/BookExportView.swift`.
- **Zanaat:** `DesignSystem/Pastel/MPRagi.swift`, `MPSound.swift`, `MPHaptics.swift`, `MPTheme.swift`, `ReaderText.swift`, `ReaderWords.swift`, `DesignSystem/Pastel/MPOnboardingChrome.swift`.
- **Belgeler:** `docs/SAYFA_MIMARISI.md`, `docs/SES_VE_SOZ.md`, `docs/RAGI.md`, `docs/STARTUP_PLANI.md` (bu plan `docs/VIZYON_PLANI.md` olarak repoya girer), CLAUDE.md.
- **Yeniden kullanılacaklar:** `MPStateView`, `MascotSays`, `SpeechBubble`, `MPSectionHeader`, `HomeSection`, `MPListRow`, `ParentRowButton`, `MPButton`, `MPCircleButton`, `MPSegmented`, `MPChip`, `MPBookCover`, `MPBadgeCard`, `MPStatTile`, `CreationChoiceRow`, `CreationFooter`, `AvatarView`, `MPHaptics`, `MPSound`, `PaperStar`, `PaperBurst`, `MPRemoteFlags`, `MPFunnel`, `MPSpokenPosition`.

## Sıra ve bağımlılık

| Faz | Bağımlılık | Dış iş |
|---|---|---|
| 7 Omurga | yok | yok |
| 8 İlk açılış | 7 | alan adı, hukuk (bayrak) |
| 9 Odam | 7 | kit kalite kararı |
| 10 Dünya hatırlar | 7; `faz-21` birleşmesi | içerik yazımı |
| 11 Ritüel | 7, 10 | aile sesi kararı, KVKK |
| 12 Yayınevi | 10 | basım ortağı |
| 13 Zanaat | 7 | yok |
| 14 Değer ve kalite | 7-9 | yok |

Faz 7-9 ardışık; 10 ve 13 paralel yürüyebilir. Her faz `DEMO_CHANGELOG.md` kaydı ve commit ile biter.

## Doğrulama

Batuhan'ın kuralı: testler fazlar bitince bir kez.

- **Birim:** `StarLedger`, katalog, çıkartma üretimi, yeni kelime sayımı, hafıza etiketleri, uyku mekanizması sayısı (`VariationReport`: uyku tekrarı %85 → ≤ %60), hatırlatma planı, `MPReviewPolicy`, Özet içgörüsü, `storyBeforeAccount` bayrağının iki sırası.
- **UI:** masal sonu → çıkartma → Odam → Dolap → kahramanda görünür; tek kapı; koleksiyon kapalıyken dükkân yok; uyku kapısı; "Konuşalım".
- **Kurallar:** Firestore (koleksiyon eşitlemesi).
- **Görüntü:** 13 düzen, normal ve AX3; App Store görselleri.
- **Cihaz:** uyku kapısı kilitli ekranda, aile sesi gerçek mikrofon, VoiceOver, Reduce Motion.
- **Elle:** Design law grep'leri boş; açık + en büyük yazı, SE, Pro ve Pro Max; her düzende "başlık + kahraman alan + ikinci bölümün ilk satırı" kıvrımın üstünde; temiz kurulumda bildirim izni masaldan sonra; beyaz açılış parlaması yok.

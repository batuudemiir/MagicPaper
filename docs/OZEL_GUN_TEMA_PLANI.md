# Özel gün temaları: tasarım ve UX planı

Hazırlanma: 17 Kasım 2026. Durum: **öneri, karar bekliyor.** Uygulamada henüz hiçbir şey değişmedi.
Tarihler: `docs/research/OZEL_GUNLER_TAKVIMI_2026-2027.md`. Kişisel özel günler (doğum günü, okulun ilk günü, yeni kardeş, ilk düşen diş) zaten var: E6, `StoryEngineBridge/SpecialDays.swift`, main `7b6d5df`.

## 1. Tek cümle

**Özel günde uygulama bayram kıyafeti giyer, evini değiştirmez.** Çocuk aynı yerde aynı düğmeye basar; değişen Ragi'nin üstündeki kurdele, gökyüzündeki fener, Ragi'nin bir cümlesi ve rafta bekleyen bir masaldır. Bayram bitince kıyafet çıkar, masal kitaplıkta kalır.

## 2. Araştırmadan çıkanlar

| Bulgu | Kaynak | MagicPaper'a anlamı |
|---|---|---|
| Duolingo'nun maskotu Duo, Cadılar Bayramı ya da yılbaşında hayalete ya da Noel Baba'ya dönüşüp uygulama simgesinde görünüyor. Bu kıyafetleri şirket içindeki illüstratör ve animatörler çiziyor. | Design Compass (üçüncü taraf), Design Week 2020 | Maskot kıyafeti, sezonun en güçlü ve en ucuz işaretidir. Ama tek kaynak illüstratör: takvime göre önceden planlanmalı. |
| Bayram döneminde arayüzü ve deneyimi yeniden tasarlama, kullanıcı sonra düzeni yeniden öğrenmek zorunda kalır. | AppFollow | Düzen, gezinme ve düğmeler hiç değişmez. Yalnızca süs katmanı değişir. |
| Mağazadaki sezon görselleri ile uygulama içi deneyim tutarlı olmalı. | Moburst | Mağaza görselleri ve Instagram, uygulamadaki temayla aynı çizimi kullanmalı (bkz. 9. bölüm). |
| Apple'da alternatif uygulama simgesini kullanıcı, uygulamanın sunduğu seçeneklerden kendisi seçer (`setAlternateIconName`). İnceleme kuralı 4.6. Her simge koyu ve renklendirilmiş türev ister. | Apple belgeleri, geliştirici forumu | **Simge tarihe göre kendiliğinden değişemez.** Ancak ebeveynin seçtiği bir seçenek olabilir. Düşük öncelik. |
| Sezon temaları "uygulamayı yeniden açmak için yeni bir sebep" diye pazarlanıyor. | Audiorista, pazarlama blogları | **Bunu bilerek yapmıyoruz.** İlke 7: yeniden açtırmak için değil, aile ritüeli için. |

Çocuk uygulamalarına özgü, kaynaklı bir sezon teması rehberi bulamadım. Aşağıdaki çocukla ilgili kurallar araştırmaya değil, MagicPaper'ın kendi tasarım yasasına (CLAUDE.md, `RAGI.md`, `ROZET_PLANI.md`) dayanıyor.

## 3. Değişmeyenler (yasa)

Özel gün teması şunlara **dokunmaz**:

- Gezinme, alt çubuk (`KidTabBar`), sayfa düzeni, düğme stilleri, tipografi, eylem rengi `#6A47B8`
- Okuyucu kâğıdı ve masal metni (kontrast kuralı). Özel gün masalı da aynı kâğıtta okunur.
- Uyku modu ve gece masal sonu. Uyku saatinde süs söner (bkz. 5).
- Ebeveyn alanı. Tek istisna, bir ayar satırı (bkz. 7).
- Ödeme duvarı. Bayram indirimi, geri sayım, "yalnızca bugün" teklifi yok. Yıldız fiyatları da değişmez.

Yasak olanlar (CLAUDE.md ilke 7 ile rozet ve yıldız kuralları):

- Sadece o gün kazanılan rozet ya da çıkartma
- "Bayrama 3 gün kaldı" gibi geri sayım ya da "kaçırma" dili
- Bildirim. En fazla, ebeveynin açtığı genel bildirim içinde bir cümle olur, ayrı bildirim olmaz.
- Rastgele hediye ya da sürpriz paket
- Kardeşler arasında "kim bayram masalını okudu" karşılaştırması

## 4. Değişenler: yedi katman

Her tema bu katmanlardan **bazılarını** kullanır. Kademe A hepsini, kademe B yalnızca söz ve rafı kullanır (kademeler takvim belgesinde).

| # | Katman | Nerede | Ne değişir | Kim yapar | Bugünkü dayanak |
|---|---|---|---|---|---|
| K1 | **Söz** | Ana sayfa selamı (`MPKidTabHeader` eyebrow), Ragi balonu (`MascotSays`), gündüz masal sonu cümlesi | "Bayramın kutlu olsun, İrem!" Tek cümle, sen dili, çocuğun adıyla. | Yazar | Var |
| K2 | **Gökyüzü** | Ana sayfa gökyüzü bandı (`HomeSky`) | Bandın içine süs: 23 Nisan'da bayrak ve kurdele, bayramda fener zinciri, en uzun gecede ek yıldız ve kar, Hıdırellez'de dilek kurdeleleri. Kartlara ve içeriğe taşmaz. | İllüstratör | `HomeSky` var. Süs yuvası yok. |
| K3 | **Ragi aksesuarı** | Ana sayfa ve masal sonu Ragi'si | Pozun üstüne binen tek aksesuar: kurdele, küçük bayrak, atkı, fener, parti şapkası. Kukla kemiğine bağlanır, Ragi ile birlikte oynar. | İllüstratör | **`RAGI.md` "yeni kıyafet yok" diyor: karar gerekir (D1).** |
| K4 | **Raf** | Masallar vitrini, Ana sayfa "bu akşam" önerisi | O günün masalı vitrinin başında. Tarih geçince normal rafına döner. | Masal motoru ve içerik | Uzaktan akış ve E6 occasion yolu var |
| K5 | **Masal** | Motor (`occasion_library`) ya da Original | Çocuğun kahraman olduğu özel gün masalı. Metin cihazdaki motorla yazılır, LLM yok. | İçerik | E6 dört kişisel occasion ile var |
| K6 | **Çıkartma** | Masal sonu, Çıkartma albümü (`MPStickerAlbum`) | Özel gün masalı bitince albüme o günün çıkartması girer. Masal yıl boyu okunabildiği için çıkartma da yıl boyu kazanılabilir. | İllüstratör | Albüm var |
| K7 | **Kapak** | Kitaplık | Özel gün masalının kapağında temanın küçük işareti. Kalıcıdır, masalın parçası. | İllüstratör | Kapak sistemi var |

Bilerek dışarıda bırakılanlar:

- **Uygulama simgesi:** Apple kuralı gereği otomatik değişemez. İleride ebeveyn alanında "Uygulama simgesi" seçeneği olabilir (T5).
- **Ses:** sentez sesler Sol majör pentatonik. Bayramda masal sonu sesine aynı ölçekte tek nota eklenebilir; değeri düşük, sona kalır.
- **Konfeti, kar yağışı, ekran boyu efekt:** tasarım yasası (aşırı animasyon yok) ve Reduce Motion yükü yüzünden yok. Gökyüzündeki süs en fazla bulutlar kadar yavaş kıpırdar.

## 5. Zaman: bir temanın günleri

```
  hazırlık         ön gün                  gün(ler)                       ertesi             sonra
  ────────────────┬─────────────────────┬────────────────────────────────┬───────────────────┬──────────────
  içerik ve çizim  │ yalnızca K4 raf      │ K1 söz · K2 gökyüzü · K3 Ragi   │ gökyüzü sabahtan  │ masal kitaplıkta,
  (takvimdeki      │ (masal 1-3 gün önce  │ K5 masal · K6 çıkartma          │ söner, söz biter  │ çıkartma hâlâ
  tarih)           │ okunabilir)          │                                 │                   │ kazanılır
```

- **Geri sayım yok.** Ön gün yalnızca rafta bir masal demektir. "Yarın bayram" demek bile ancak masalın içinde, hikâyenin sesiyle olur.
- **Gündüz ve gece:** `MPBedtime.isBedtime` açıkken K1 söz yumuşar ("İyi bayramlar, iyi geceler"), K2'nin yalnızca gece hâli kalır (fener ışığı, yıldız), K3 aksesuarı uyuyan Ragi'de yalnızca tema bunu kaldırıyorsa durur. Ses ve zıplama zaten yok.
- **Çakışmalar** için tek kural: **sessiz gün > çocuğun kendi günü > A teması > B teması.** Örnekler: Kurban Bayramı'nın 4. günü 19 Mayıs; Ramazan Bayramı 8-12 Mart ara tatili içinde; 2 Nisan'da hem Çocuk Kitabı Günü hem Otizm Farkındalık Günü var.
- **Çocuğun kendi günü önce gelir.** 23 Nisan aynı zamanda İrem'in doğum günüyse ekran doğum gününü kutlar. 23 Nisan masalı rafta kalır.

### Sessiz günler

10 Kasım, 18 Mart ve 15 Temmuz'da süs katmanları kapanır. Çalışan bir tema varsa o gün durur. Çocuk alanına anma içeriği konmaz: 3-10 yaş için yas dili ebeveynin işidir. Masal sonundaki gündüz kutlaması (`cheer`) o gün de normal kalır, çünkü çocuğun masal bitirmesini kutlar, günü değil. Bu bir öneri; karar D5'te.

## 6. Çocuğun kendi özel günü

En güçlü "özel gün" takvimde yazmaz: **çocuğun doğum günü.** Ürün fikriyle birebir örtüşür: masal dünyası çocuğun, o gün de onun günü.

E6 bugün ebeveynin girdiği günü masal yazarken ("Masalda kimler olsun?" çipi) 14 gün önce ile 7 gün sonra arasında öneriyor. Plan bunu takvim temalarıyla aynı katmanlara bağlıyor:

| Gün | K1 söz | K2 gökyüzü | K3 Ragi | K4/K5 | K6 |
|---|---|---|---|---|---|
| Doğum günü (yalnızca o gün) | "İyi ki doğdun, İrem!" | Balon ve flama | Parti şapkası | Doğum günü masalı vitrinin başında (E6 var) | Doğum günü çıkartması |
| Okulun ilk günü | "Bugün büyük bir gün" | Yok | Sırt çantası, Ragi'nin zaten var | E6 masalı | Var |
| Yeni kardeş, ilk düşen diş | Ebeveynin girdiği güne göre tek cümle | Yok | Yok | E6 masalı | Var |

Kurallar:

- Yaş sayısı ekranda büyük yazılmaz. Masal içinde geçebilir.
- Profilde ve Masal ailem'de kardeşin doğum günü **ileride** olabilir. Şimdilik yalnızca çocuğun kendi E6 kayıtları (gelecek özellik erken yapılmaz).
- Rozet ailesinde zaten gizli "Masal yıldönümü" var. Doğum günü için tarihe kilitli bir rozet açılmaz.

## 7. Ebeveyn kontrolü

"Büyükler için → Ayarlar" içinde tek satır: **Özel günler**. Üç seçenek:

1. **Açık** (varsayılan): milli günler, bayramlar kültürel aile bayramı olarak, evrensel çocuk ve okuma günleri ve çocuğun kendi günleri.
2. **Dinî günleri de an:** kandiller, Kadir Gecesi ve Hicri yılbaşı da K1 ve K4 alır. K3 kıyafet yok.
3. **Kapalı:** hiçbir tema yok. Çocuğun kendi günleri E6'daki gibi yalnızca masal önerisi olarak kalır.

Ramazan ve Kurban Bayramı 1. seçenekte de var, ama kültürel dille: bayram sabahı, el öpme, şeker, ziyaret, sofra. İbadet anlatısı ve kurban imgesi yok. Ramazan ayı boyunca yalnızca B kademesi: iftar sofrası ya da davulcu masalı rafta. Oruç anlatılmaz.

## 8. Erişilebilirlik

- K2 ve K3 süs: `accessibilityHidden(true)`. VoiceOver yalnızca K1 cümlesini okur.
- Reduce Motion açıkken gökyüzü süsü durur, Ragi aksesuarı düz çizilir. Anlam kaybolmaz.
- Bilgi yalnızca renkle verilmez: bayram, bayrak renginden değil sözden anlaşılır.
- K1 cümlesi en büyük Dynamic Type boyutunda iki satırı geçmez. Bu yüzden en fazla 32 karakter.
- Kırmızı-beyaz bayrak süsü krem zemin üstünde dekordur, metin değildir. Kontrast kuralı metne uygulanır.

## 9. Teknik yön (öneri, karar değil)

1. **Saf çözücü:** `SeasonalThemeResolver`, girdileri tarih, saat dilimi, ebeveyn ayarı, uyku saati ve çocuğun E6 kayıtları; çıktısı `SeasonalLook?` (hangi katman, hangi varlık, hangi söz). UI'dan bağımsız, tamamen birim testli. Test edilecekler: çakışma sırası, sessiz gün, gece hâli, saat dilimi sınırı, "Kapalı" ayarı.
2. **Takvim verisi uygulamaya gömülmez.** Dinî tarihler her yıl kayar. Yıllık tema tablosu imzalı uzaktan akışın (`feed.json`, FAZ 15) yeni bir `seasons` bölümünde durur. Uygulamayla bir yedek dosya gelir. Böylece güncelleme yayınlamadan tarih düzeltilir ya da tema kapatılır.
3. **Görseller:** K3 aksesuarları ve K2 süsleri uygulamayla gelir (küçük PNG'ler, sürümle). Uzaktan yalnızca Original kapakları gibi masal görselleri iner. İlk yıl için bütün temaların varlıkları tek sürümde gelebilir. Akış yalnızca hangisinin ne zaman açılacağını söyler.
4. **Ragi aksesuarı** `MascotImage`'ın içinde ayrı bir katman. `RagiRig` baş kemiğine bağlı, poz başına bir bağlanma noktası. Ekranlar değişmez (`RAGI.md`: "Yeni çizim gelirse yalnızca varlıklar ve `RagiRig` tablosu değişir").
5. **Özel gün masalları** E6'nın `occasion_library`'sine takvim occasion'ları olarak girer (`occasion_23_nisan` gibi). Hikâye kayıtlarındaki `occasionID` alanı kalıcı etiket olur.
6. **Ölçüm** yalnızca okuma üzerinden: özel gün masalı bitirildi mi. Oturum süresi ya da "temayı gördü" ölçülmez (FAZ 14 gizlilik çizgisi).

## 10. Uygulama sırası

| Faz | Ne | İllüstratör gerekir mi | Hedef |
|---|---|---|---|
| **T0** | Kararlar (bölüm 11) | Hayır | Bu hafta |
| **T1** | Çözücü + K1 söz + K4 raf + ebeveyn ayarı + sessiz gün. Çizimsiz ilk tema: **21 Aralık en uzun gece** (söz + raf + motor masalı) ve **yeni yıl**. | Hayır | 18 Aralık |
| **T2** | K3 Ragi aksesuar katmanı + K2 gökyüzü süs yuvası. İllüstratöre ilk paket: Ramazan Bayramı (fener), 23 Nisan (kurdele ve bayrak), doğum günü (parti şapkası). | Evet | Çizim 20 Ocak'ta başlar, tema 6 Mart'ta açılır |
| **T3** | K6 çıkartma + K7 kapak işareti. Her A teması için bir çıkartma. | Evet | 23 Nisan'a kadar |
| **T4** | Çocuğun kendi günü ekranda: doğum günü K1, K2 ve K3 (E6'ya bağlanır) | Parti şapkası T2'de | Mart |
| **T5** | İsteğe bağlı: ebeveyn alanında uygulama simgesi seçeneği, mağaza ve Instagram görsellerinin temayla eşlenmesi | Evet | Yaz |

T1 çizim istemez. Bu yüzden takvimdeki "bu hafta başlamalı" sıkışıklığını çözer: aralık temaları çizimsiz çıkar, kıyafetli ilk tema Ramazan Bayramı olur.

## 11. Batuhan'ın vereceği kararlar

| # | Karar | Öneri |
|---|---|---|
| D1 | `RAGI.md` "yeni kıyafet yok" kuralı, temaya özel **tek aksesuar** için gevşesin mi? | Evet: tek aksesuar, kontursuz, aynı boya dili, bayram bitince çıkar. Ragi'nin kendi kıyafetleri (CLAUDE.md'de illüstratör işi) bundan ayrı kalır. |
| D2 | Dinî günler için üç seçenekli ebeveyn ayarı | Evet, varsayılan "Açık" (bayramlar kültürel, kandiller kapalı) |
| D3 | Yılbaşı nasıl anlatılsın? | "Yeni yıl" ve kış ışıkları; Noel Baba ve Noel ağacı yok |
| D4 | Kişisel gün takvim temasının önüne geçsin mi? | Evet |
| D5 | Sessiz günlerde çocuk alanı | Süs kapalı, anma içeriği yok, gerisi normal |
| D6 | A temalarının yıllık sayısı ve bütçe | 5-6 kıyafetli tema; gerisi B kademesi |
| D7 | Ödeme duvarında sezon teklifi | Hayır |

## Kaynaklar

- Design Compass, Duolingo marka sayfası: https://designcompass.org/en/wp-json/wp/v2/brands/44811
- Design Week, Duolingo şirket içi ekip (2020): https://www.designweek.co.uk/issues/12-18-october-2020/in-house-teams-duolingo
- AppFollow, tatil sezonunda kullanıcıyı tutmak: https://appfollow.io/blog/how-to-prepare-your-app-for-the-holiday-season
- Moburst, uygulamayı tatil sezonuna hazırlamak: https://www.moburst.com/blog/getting-your-app-ready-for-the-holiday-season/
- Audiorista, sezonluk içerik temaları: https://www.audiorista.com/best-practices/planning-seasonal-content-themes-for-your-app
- Apple, alternatif uygulama simgeleri: https://developer.apple.com/tutorials/data/documentation/xcode/configuring-your-app-to-use-alternate-app-icons.md
- Apple geliştirici forumu, 4.6 tartışması: https://developer.apple.com/forums/thread/723928
- Apple geliştirici forumu, alternatif simge reddi: https://developer.apple.com/forums/thread/751251

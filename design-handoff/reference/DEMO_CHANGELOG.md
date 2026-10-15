# MagicPaper demo ekranları · CLAUDE.md

Bu dosya, MagicPaper Kids demo canvas'ının hafızası. Kaynak koddaki CLAUDE.md gibi çalışır: canvas'ın ne olduğunu, nasıl kurulduğunu, hangi kurallara uyduğunu ve her güncellemede neyin değiştiğini tutar.

## Kural: bu dosya her değişiklikte güncellenir

- Canvas'ta herhangi bir ekran eklenir, silinir ya da değişirse, aynı yayında bu dosyanın **Değişiklik günlüğü** bölümüne yeni bir kayıt eklenir. İrem istemese, hatırlatmasa bile.
- 13 Ekim 2026'dan itibaren uygulama kodunda, içerikte ya da belgelerde tamamlanan her iş de buraya yazılır. Kim istemese, hatırlatmasa bile. Kural kaynak koddaki `CLAUDE.md`'de de var.
- Kayıt en üste eklenir (en yeni en üstte). Biçim: tarih, sürüm (canvas işinde canvas sürümü, uygulama işinde dal ve commit; commit yoksa "commit yok"), kısa başlık, madde madde ne değişti, test sonucu, hangi dosyalar etkilendi.
- Ekran listesi, kurallar ya da varlık listesi değiştiyse ilgili bölüm de aynı anda güncellenir.
- Bu dosyanın bir kopyası "Magic Paper" projesinde `claude/magicpaper-demo-CLAUDE.md` olarak durur. İkisi her zaman aynı içerikte tutulur.

## Nerede

- Canvas (Design artifact): https://claude.ai/code/artifact/656ec029-2855-47d2-a68e-4212ea0b21fe
- Mimari belge (Claude Docs): "MagicPaper ürün ve arayüz mimarisi" https://claude.ai/code/artifact/b23e4fe6-0af2-4a83-b946-97b2f4b763c4
- Tasarım sistemi artifact'ı (henüz eski hali, bilerek değiştirilmedi): https://claude.ai/artifact/RadDoF7u1Ndx1wfx3cv75U
- Her ekran `project/<Ad>.dc.html`, yerleşim `project/canvas.json`. Doğruluk kaynağı yayındaki bu dosyalardır. Üretim betikleri (gen_v5.py vb.) oturum sandbox'ında yaşadı, kalıcı değil.

## Bilgi mimarisi (kısa)

- **Çocuk alanı:** alt bar 3 sekme: Ana sayfa · + Yarat · Kitaplık. Üst barda avatar (Benim köşem), yıldız sayacı, kilit (Ebeveyn kapısı).
- **Yarat:** 2 adım. Dünya (kahraman bir çip), sonra Ayarla (uzunluk, ton, karakterler, "Masalda ne olsun?"). Ardından Masal yazılıyor, Okuyucu, Masal sonu.
- **Ebeveyn alanı:** kapının arkasında, gri zemin, kendi alt barı: Özet · Onaylar · Güvenlik · Ayarlar. Abonelik yalnızca buradan açılır.
- Çocuk alanında satın alma, dış bağlantı, reklam yok. Paylaş, yazdır ve sil işlemleri kapıdan geçer.

## Ekranlar (canvas satırları)

### Marka ve maskot
- `Marka.dc.html`: logo, uygulama simgesi, ton, palet, ifadeler ve pozların kullanım yeri

### Başlangıç: ilk masala kadar
- `Main.dc.html` Karşılama 1 · `Onboarding2.dc.html` Karşılama 2 · `Onboarding3.dc.html` Karşılama 3
- `Giris.dc.html` Giriş · `EbeveynOnayi.dc.html` Ebeveyn onayı (KVKK)
- `ProfilOlusturma.dc.html` Çocuk profili · `NeleriSever.dc.html` Neleri sever
- `BildirimIzni.dc.html` Bildirim izni · `IlkMasal.dc.html` İlk masal hazırlanıyor

### Çocuk alanı
- `AnaSayfa.dc.html` Ana sayfa (Tweaks: `durum` = Yarım masal / Bugün okunmadı / Bugün okundu / Uyku saati)
- `BenimKosem.dc.html` Benim köşem · `KahramanOlustur.dc.html` Kahraman oluşturucu · `MasalAilem.dc.html` Masal ailem
- `YeniKelimeler.dc.html` Yeni kelimelerim · `Kutuphane.dc.html` Kitaplık · `MasalAksiyon.dc.html` Masal aksiyonları · `SeriMasal.dc.html` Seri masal

### Masal oluşturma ve okuma
- `SihirbazNerede.dc.html` Yarat 1 · Dünya · `SihirbazNasil.dc.html` Yarat 2 · Ayarla · `Uretim.dc.html` Masal yazılıyor
- `OkuyucuGorselli.dc.html` Okuyucu · görselli · `Okuyucu.dc.html` Okuyucu · sadece metin (Tweaks: `tema` = Gündüz / Sepya / Gece)
- `OkumaAyarlari.dc.html` Okuma ayarları · `MasalSonu.dc.html` Masal sonu · `UykuModu.dc.html` Uyku modu · `iPadOkuyucu.dc.html` iPad yatay okuyucu (1180 genişlik)

### Ebeveyn alanı
- `EbeveynKapisi.dc.html` Ebeveyn kapısı (demo cevabı: 7 × 4 = 28)
- `EbeveynPaneli.dc.html` Özet · `OnayBekleyenler.dc.html` Onaylar · `IcerikGuvenligi.dc.html` Güvenlik · `Ayarlar.dc.html` Ayarlar
- `SesKaydi.dc.html` Kendi sesin · `AileUyeleri.dc.html` Aile · `KitapSiparisi.dc.html` Masal kitabı · `Paylas.dc.html` Aileyle paylaş
- `Paywall.dc.html` Abonelik · `AbonelikBitti.dc.html` Abonelik bitti · `HesapSil.dc.html` Hesabı sil

### iOS yüzeyleri
- `Widgetlar.dc.html` Ana ekran ve kilit ekranı widget'ları · `KilitEkrani.dc.html` Live Activity, bildirim, Siri

### Durum ekranları
- `BosKitaplik.dc.html` · `UretimHata.dc.html` · `InternetYok.dc.html` · `YildizBitti.dc.html`

## Görsel dil kuralları

- **Font:** Nunito (Google Fonts, 400 to 900), helmet içinde bağlı.
- **Zemin:** çocuk alanı krem #FFF8EE, ebeveyn alanı #F6F7F9.
- **Eylem rengi (marka moru):** buton degradesi #9C7BE3 → #5C3A8F, seçili ve bağlantı #6A47B8. Metin #2E1E3E, ikincil metin #6E6478.
- **Marka paleti:** #8F6BD6 lavanta, #5C3A8F mor, #3A2458 gece moru, #F6E8DC krem, #E6C7F2 leylak, #F2A3C3 pembe, #EE7C6B mercan, #F4B735 yıldız sarısı, #A97C52 çanta kahvesi, #2E1E3E mürekkep.
- **Dünya pastelleri** (kart zeminleri) ayrı kalır: lav, pink, yellow, green, sky, peach, mint, gray ve her birinin koyu tonu.
- **Biçim:** birincil buton tam yuvarlak, 52 px, ekranda tek bir tane. Kart köşesi 22 to 28. Dokunma alanı çocukta en az 56, ebeveynde en az 44.
- **Metin dili:** "sen" dili, cümle düzeni büyük harf, uzun tire yok, emoji yok. Hata mesajı suçlamaz.
- **Ekran içeriği:** sahte durum çubuğu yok, gerçek marka ya da karakter taklidi yok.
- **Gezinme:** tüm gezinme gerçek `<a href="X.dc.html">` ile yapılır, durum gerektiren yerler `onClick` + `state` kullanır.

## Maskot kuralları

- Bir ekranda en fazla bir maskot. Ebeveyn alanında maskot yok.
- İfadeye göre kullanım:

| İfade | Nerede |
|---|---|
| Mutlu | Masal sonu, rozet |
| Meraklı | Ana sayfa sorusu, Neleri sever |
| Sakin | Ebeveyn onayı |
| Uykulu | Bildirim izni, Yıldız bitti |
| Şaşkın | Üretim hatası |
| Düşünceli | İnternet yok |

- Poza göre kullanım:

| Poz | Nerede |
|---|---|
| Kitapta | Karşılama 1, Abonelik |
| El sallıyor | Masal sonu, Okundu kartı |
| Kalemli | Masal yazılıyor, İlk masal |
| Okuyor | Boş kitaplık |
| Uyuyor | Uyku modu, Uyku kartı |
| Yürüyor | Karşılama 3 |

- Konuşma balonu beyaz, sol altta kuyruk. Kısa ve sıcak cümle: "Bu gece hangi dünyaya gidelim?", "Harika bir masaldı!".
- Maskotun adı henüz belirlenmedi.
- Görseller marka kitinden kesilip arka planı temizlendi (demo kalitesi). Gerçek uygulama için tasarımcıdan şeffaf PNG @2x/@3x alınmalı.

## Varlıklar (canvas asset store)

| Ad | URL |
|---|---|
| Maskot · önden | /_blob/20fd09e28af4f7d1c9fa0bf1962cecb8 |
| Maskot · 3/4 | /_blob/77368590480cecbf85adffc935ed02d8 |
| Mutlu | /_blob/603fb0cc6cdc32ec223e3f82e5475585 |
| Meraklı | /_blob/95216b1e2dae917ee841f554c88c0723 |
| Sakin | /_blob/e0b0ea6ed8f550d07f4d1bf22b4b6599 |
| Uykulu | /_blob/f38d6a54d4cf7f6acb9a83bfbf106155 |
| Şaşkın | /_blob/c6b854332759cf22b3a2328305202d9e |
| Düşünceli | /_blob/8b36e8be5baf56364f765ab68bae67c5 |
| Okuyor | /_blob/3fdbbedb710ce9f3c605b9d688fd1075 |
| El sallıyor | /_blob/6941a09e7d0d2b40e317ec57ea08fba6 |
| Uyuyor | /_blob/f674579ca610d95160e0995bf20142a1 |
| Kalemli | /_blob/02c506d337bb3bd90280119e52d3babb |
| Kitapta | /_blob/5fd8df0aae96ad169a197f430c7c6ef9 |
| Yürüyor | /_blob/3a78bd9cfe8092ebbe1eb88b48a43e16 |
| Uygulama simgesi (açık) | /_blob/4ff1a8bafdf654c0fad79e509f4ac85e |
| Uygulama simgesi (koyu) | /_blob/78cdc95983715cf140cba7448275af88 |
| Gece sahnesi | /_blob/c3bbe01b25f733747afbbc430c899dea |
| Bakan yüz | /_blob/8dd22e3791b1002f4c3f41f444e66581 |
| Logo (açık) | /_blob/7d29c12f0b60eb0ae1b69d34231bc2dd |
| Logo (koyu) | /_blob/d8ec617fc9469df424632920cef35358 |
| Eski 3D çocuk görseli (artık kullanılmıyor) | /_blob/c23131b52bd9e1a56d2aa332269f235e |

## Açık konular

- Maskota isim verilecek.
- Tasarım sistemi artifact'ı yeni dile (mor palet, maskot, yeni bileşenler) henüz taşınmadı.
- PlanCard bileşeninde rozetin plan adını kaydırma hatası DS tarafında düzeltilecek.
- Basılı kitap fiyatı belirlenmedi (ekranda "fiyat ve teslimat bir sonraki adımda" yazıyor).

## Değişiklik günlüğü

### 2026-10-15 · main@cf1ae56 (uyku-v2 ileri sarıldı, origin'e gönderildi) · Uyku modu bayrak arkasında, akşam üç mod serbest
- Birleştirme: `uyku-v2` main'e ileri sarma ile alındı, ardından origin'e gönderildi (Batuhan'ın isteği; plan, iş ve günlük commit'leri dahil). Main'deki başka oturumun açık değişikliklerine (`MPTheme.swift`, `MPNavigationChrome.swift`) dokunulmadı.
- Uyku modu v1'de kapalı: yeni `MPFeatures.sleepMode = false`. Kod duruyor; Ana sayfa akşam kartı uyku modunu açmıyor, klasik masal detayındaki "Uyku modu" karesi gizli, masal sonu "İyi geceler" okuyucuyu kapatıp "İyi geceler" tostu gösteriyor, `magicpaper://sleep` bu akşamın masalına düşüyor, Siri "Uyku modu" kısayolu çıktı (intent `isDiscoverable` bayrağa bağlı).
- Akşam kartı: düğme "Uyku masalı oluştur", alt metin "Kısa, sakin bir masalla günü kapatalım." Düğme yeni `BedtimeStorySheet`'i açar: "Uyku masalı oluştur" (doğrudan Masalda kimler olsun?), yarım masal varsa "Kaldığın yerden devam et", "Başka bir masal seçeyim" (mod adımı). Pencere yalnızca dokununca açılır, kendiliğinden gelmez.
- Uyku saatinde Yarat artık üç modu da sunar: `allowedModes` filtresi kalktı, yerine `emphasizedMode` + `shownModes(_:emphasized:)`. Ana sayfada Uyku karosu "Bu akşam" etiketi ve mor çerçeveyle önde; Yarat 1'de Uyku öncesi önceden seçili ve üstte açıklama satırı. Sürpriz değişmedi.
- Ebeveyn Güvenlik: "… ve sonrasında uyku masalı öne çıkar".
- Bilerek değişmeyen: `SleepModeView`, `MPSleepPlayback`, Live Activity kodu; sürprizin mod ağırlığı; masal sonu düğme sırası.
- Test: tam takım 698 test, 2 hata. `AvatarViewTests.testAnUnknownPoseDrawsStanding` tekrar koşuda geçti (kararsız). `ReadingEventTests.testDeleteProfileReachesTheLiveStores` yeni simülatörde profil olmadığı için "son profil" kuralına takılıyor; bu değişiklikle ilgisiz, main'de denenmedi. `PastelHomeRulesTests` yeni kurallarla yeşil.
- Simülatör (iPhone 17 Pro, demo profil, saat 21.10): akşam kartı, "Bu akşam" etiketi, pencere, iki yol (Uyku masalı oluştur → Masalda kimler olsun?, Başka bir masal → mod adımı, Uyku öncesi seçili) açık temada ve en büyük Dynamic Type'ta görüldü; koyu temada pencere görüldü. iPhone SE, Pro Max, "Kaldığın yerden" satırı ve masal sonu "İyi geceler" simülatörde görülmedi.
- Dosyalar: `Screens/MPFeatures.swift` (yeni), `Screens/BedtimeStorySheet.swift` (yeni), `MPAppState`, `ContentView`, `HomeView`, `MPHomeChrome` (HomeModeTile `badge`), `StoryCreationSteps`, `StoryCreationFlow`, `StoryModeStep`, `StoryReaderView`, `ClassicDetailView`, `MPAppIntents`, `ParentSafetyView`, `MPSettingsStore`, `MPParentControls`, `PastelHomeRulesTests`, `docs/UYKU_MODU_V2_PLANI.md`.

### 2026-10-15 · main (belge) · Plan: uyku modu v2'ye, akşam üç mod serbest
- Yeni plan `docs/UYKU_MODU_V2_PLANI.md` (Batuhan'ın iki kararı): uyku modu (kararan ekran, süre, Live Activity, Siri "Uyku modu") lansmanda bayrak arkasında gizlenir, v2'de açılır; Ana sayfa akşam kartı "Uyku modunu aç" yerine "Uyku masalı oluştur" penceresi açar; uyku saatinde Yarat üç modu sunar, Uyku öncesi ilk sırada ve vurgulu.
- Bütün giriş noktaları dosya:satır ile listelendi (akşam kartı, masal sonu "İyi geceler", klasik detay karesi, Siri, `magicpaper://sleep`, Live Activity, ebeveyn Güvenlik kopyası).
- Açık kararlar: pencere yalnız dokununca mı (öneri) yoksa akşam bir kez kendiliğinden mi; sürpriz uyku saatinde Uyku öncesine ağırlık versin mi.
- Bilerek değişmeyen: uygulama kodu; "Uyku öncesi" masal modu v1'de kalır. Test çalıştırılmadı (yalnız belge).

### 2026-10-15 · book-intelligence@ecf41b5 · Haftalık araştırma turu: 9 yeni kitap
- Öğrenme döngüsü elle çalıştırıldı (yaklaşık 1 saat). 9 kitap tam analiz edildi (hedef 10; aceleye getirilmedi): 6 Book Dash, 3 Book Dash dışı (African Storybook 2, StoryWeaver 1; *Good Night, Monu* ilk uyku masalı). Hepsi CC BY 4.0. Korpus 16 tam analiz.
- Tekrar eden satır, sayfa sonu kancası, cümle uzunluğu ve resimde kalan bilgi LOW → MEDIUM. "12 sayfa" iddiası çürüdü (Book Dash dışı 3 kitaptan 1'i), yayınevi sorusuna çevrildi.
- Yeni öneri `p_bedtime_closes_circle` karar bekliyor (tavsiye research_more; story-engine bugünkü 3 uyku şablonunun da kurala uymadığını gösterdi, deney önerdi). Yöntem kuralı m006 eklendi.
- İlk kör yeniden okuma (Amahle): olay işlevi ve resimde kalan bilgi %58; 12 sayfa ile henüz "ölçülüyor".
- Bilerek değişmeyen: uygulama, StoryEngine, içerik; karar verilmedi. Book Dash'ten gelen 6 kitabın hepsi 3-4 bandında; 5-6 pilotu için korpus hâlâ karışık.
- Test: 131/131, `validate` 0 hata.
- Etkilenen: `Research/BookIntelligence/data/**` (9 eser, analiz, sayfa; iddialar; `p_bedtime_closes_circle`; `method/rules.json`), `docs/research/**` (derin incelemeler, haftalık sayfa 2026-10-15), `Research/BookIntelligence/bookintel/runs.py`, `.gitignore`. Bu kayıtla birlikte 14 Ekim araştırma kayıtlarındaki "commit yok" sürümleri gerçek commit'lerle düzeltildi.

### 2026-10-14 · book-intelligence@ecf41b5 · Haftalık kitap sayısı 10
- Haftalık öğrenme döngüsü artık haftada 10 kitaba kadar okuyor (önce 2). En az 3'ü Book Dash dışından olmalı. Kitaplar her biri 2 kitap alan, aynı anda en fazla 4 book-research alt ajanına dağıtılıyor; iddiaları, tartışmayı ve kuralları yalnızca yönetici oturum güncelliyor. Kural: sayıya ulaşmak için yargı atlanmaz.
- `runs.log` kilitli yazıyor: paralel ajanlar koşu kaydında birbirinin girişini silmiyor (8 süreçle 200 eşzamanlı yazma, 200'ü korundu). `data/runs/.lock` gitignore'da.
- Bilerek değişmeyen: kaynak kuralları, insan onayı, kitap başına analiz adımları.
- Test: 131/131.
- Etkilenen: `Research/BookIntelligence/bookintel/runs.py`, `Research/BookIntelligence/.gitignore`; repo dışında `scheduled-tasks/magicpaper-learning-loop/SKILL.md`.

### 2026-10-14 · main@a532209 · FAZ 20 Günlük: raf, arama ve Kategoriler kart dilinde; erişilebilirlik ve küçük ekran
- **Raf ve arama:**
  - Geri düğmesi ve arama alanı sert kenarlı, raf simgesi başlığın yanında.
  - Sonuçlar "N masal" kartında; arama alanında temizleme düğmesi var.
  - Sonuç yoksa düşünceli Ragi ile sakin bir mesaj çıkıyor.
  - Yaş süzgeci çipinde "✕" yazısı yerine simge.
- **Kategoriler:** koyu mor tam ekran örtü yerine krem bir alt sayfa. Yaş segmentle seçiliyor; raflar tek kartta (pastel simge kutusu, ad, masal sayısı).
- **Düzeltmeler:**
  - Kapağı bekleyen masal büyük sahnede koyu tonda çiziliyor; karartma artık çamurlu griye dönmüyor.
  - "Fabllar" simgesi traktör olarak çiziliyordu, düzeldi.
  - Okuyucu kapağı Günlük masallarında "İrem için" demiyor, yalnızca sayfa sayısı yazıyor (`StoryCover`: ad boşsa).
- **Erişilebilirlik ve küçük ekran:**
  - En büyük yazı boyutunda vitrin, detay ve seri sahne metni başlığa ve geri düğmesine binmiyor (büyüme `accessibility1` ile sınırlı, sığmazsa küçülüyor).
  - Vitrin küçük ekranda ekranın %60'ı, büyük telefonlarda 520 pt.
- **Bilerek değişmedi:** vitrin yüksekliği büyük telefonlarda aynı; 11 masal hâlâ kapak bekliyor.
- **Test ve doğrulama:**
  - Günlük ve okuyucu testleri 64/0. Tam takım bu turda çalıştırılmadı.
  - Simülatörde okuma akışı uçtan uca denendi: Rapunzel açıldı, 3. sayfada bırakıldı, "Kaldığın yerden"de göründü.
  - En büyük yazı boyutu ve iPhone SE ekran görüntüsüyle kontrol edildi.
  - SE'deki oran düzeltmesi ve koyu yedek sahne sonradan simülatörde ayrıca açılıp bakılmadı.
  - Telefona kurulamadı (iPhone 16 bağlı değildi).
- **Gönderim:** `main` origin'e gönderildi (`1a14de7..a532209`).
- **Kural:** kökteki `CLAUDE.md`, "Değişiklik günlüğü" bölümü sertleşti (Batuhan, 14 Ekim). Biten her iş, küçüğü de, yazılır. Dosyada başka oturumun değişikliği olsa da kayıt ertelenmez, yalnızca kendi kaydını commit'lersin.
- **Etkilenen:** `Screens/Gunluk/GunlukShelfView.swift`, `GunlukCategoriesView.swift`, `GunlukComponents.swift`, `GunlukHeader.swift`, `GunlukView.swift`, `ClassicDetailView.swift`, `ClassicSeriesView.swift`, `Screens/StoryReader/StoryCover.swift`, `Screens/MPAppState.swift`; repo dışında `CLAUDE.md`.

### 2026-10-14 · refrain-deneyi@104b3c3, kitap-rehberi@e6e6bc5, book-intelligence@227fcea · Onaylanan 3 araştırma önerisi uygulandı
- **Nakarat (p_repeated_line), `refrain-deneyi`:** motorda isteğe bağlı `RefrainSpec`: kısa, slotsuz bir satır belirtilen sayfaların sonuna eklenir, son sayfada bir kez değişir; `CatalogIntegrity` kuralları denetler. İki kardeş blueprint (uyku öncesi 5-6 ve 3-4) `Content/Experiments/x_refrain_bedtime.json` içinde, uygulamayla gelmez. Deneyler `x_refrain_bedtime_56/_34` tahminleriyle kayıtlı (taslak).
- **Sayfa sonu sorusu ve arkadaşın yansıtması, `kitap-rehberi`:** `docs/MagicPaper_Content_Library.md` §14'e yazım kuralı olarak girdi; mevcut satırlar değişmedi.
- **Araştırma, `book-intelligence`:** haftalık tur, 9 karar, UX hattı ve iş paketleri commit'lendi; 3 paket `done`.
- Bilerek değişmeyen: yayındaki katalog (hiçbir blueprint nakarat taşımaz), uygulama kodu, main. Hiçbir dal main'e birleştirilmedi, push yok.
- Yayın için açık (Batuhan): paket aracı `Content/Experiments`'i okumuyor; `ContentPackage.currentSchemaVersion` artırılmalı; sonra `experiment preflight` ve `mark live`.
- Test: motor paketi 788 test, 18 hata (main'de de aynı 18 test hatalı, önceden var), yeni `RefrainExperimentTests` 8/8; araştırma 119/119, `validate` 0 hata. Uygulama hedefi derlenmedi.
- Etkilenen: `StoryEngine/Sources/StoryEngine/Content/{CatalogBlueprint,CatalogIntegrity}.swift`, `Offline/OfflineStoryComposer.swift`, `StoryEngine/Tests/StoryEngineTests/RefrainExperimentTests.swift`, `Content/Experiments/*`, `docs/MagicPaper_Content_Library.md`, `Research/BookIntelligence/**`, `docs/research/**`.

### 2026-10-14 · book-intelligence@cfd900c · Araştırma ajanı kendini geliştiriyor
- Diğer ajanlar (story-engine, content-library, privacy-safety, reader, parent-ux, ui-agent, illustration-system) ve ürün sahibi araştırma ajanına soru sorabiliyor (`ba request ask`). Ajan bir sonraki koşuda önce bunları, iddia ve kitap göstererek cevaplıyor.
- Kör yeniden okuma: her koşuda tamamlanmış bir kitap, ilk analizine bakılmadan yeniden okunuyor; alan başına tutarlılık ölçülüyor. 20+ sayfada %60'ın altındaki bir alana dayanan iddialar LOW'u geçemiyor (`confidence.py`).
- Yöntem kuralları: kabul edilen her düzeltme bir kurala dönüşüyor, `validate` uyguluyor. İlk 5 kural gerçek düzeltmelerden geldi (0-3 yoğunluk ölçeği, yaş bandına göre sayfa sayısı, ilan edilmiş nakarat, uyku modu, metin-yalnız ürün).
- Haftalık sayfaya iki bölüm eklendi: "Ajanlardan gelen sorular" ve "Ajan kendini nasıl geliştirdi". Haftalık görev ve 8 ajan tanımı güncellendi (repo dışında).
- Bilerek değişmeyen: uygulama, StoryEngine, içerik; tek insan onayı (`exchange decide`). Kör okumayı CLI zorlayamıyor, talimatla sağlanıyor. Aynı worktree'deki haftalık koşunun commit edilmemiş işi olduğu gibi duruyor.
- Test: 131/131 (12 yeni), `validate` 0 hata.
- Etkilenen: `Research/BookIntelligence/bookintel/learning.py` (yeni), `bookintel/confidence.py`, `bookintel/schema.py`, `bookintel/cycle.py`, `book_agent.py`, `tests/test_learning.py` (yeni), `data/method/rules.json` (yeni), `docs/research/BOOK_RESEARCH_AGENT.md`; repo dışında `.claude/agents/*.md` ve `scheduled-tasks/magicpaper-learning-loop/SKILL.md`.

### 2026-10-14 · book-intelligence@227fcea · Araştırmadan UX'e ve onaydan işe bağlantı
- Öneriler artık tasarıma da gidebiliyor: 7 yeni hedef (okuyucu: sayfa çevirme, düzen, sesli okuma; ebeveyn akışı; çocuk alanı; görsel dil; resim brifi). Her hedefin sahibi tartışmaya katılır: reader, parent-ux, ui-agent, illustration-system; motor hedeflerinde story-engine. Güvenlik ajanı her öneride zorunlu.
- Onaylanan öneri kendiliğinden iş paketine dönüşür (`docs/research/handoffs/`, `HANDOFFS.md`): ne yapılacak, dokunacağı dosyalar, testler, güvenlik koşulları, "bitti" tanımı; durumu yalnızca sahibi ya da insan değiştirir (`ba exchange handoff`). Bugünkü 3 onay için paket açıldı: tekrar eden satır (story-engine + content-library), sayfa sonu sorusu ve arkadaşın duygusu (content-library).
- Haftalık sayfa ayrıca HTML yazılıyor (`docs/research/weekly/<tarih>.html`), karar listesi ve iş paketleriyle birlikte.
- Ajan tanımlarına (book-research, story-engine, content-library, reader, parent-ux, ui-agent, illustration-system) kısa tartışma ve iş paketi bölümü; haftalık görev UX sahiplerini paralel çağıracak şekilde güncellendi.
- Bilerek değişmeyen: uygulama ve motor kodu. İş paketlerini ajanlar kendiliğinden başlatmaz, ürün sahibi başlatır; ana koda yine onayla girer. UX önerileri deney olamaz.
- Test: araştırma testleri 119/119 (9 yeni), `ba validate` 0 hata.
- Etkilenen: `Research/BookIntelligence/bookintel/{exchange,cycle,htmlpage}.py`, `book_agent.py`, `vocab/research_vocab.json`, `tests/test_exchange.py`, `tests/test_loop.py`, `docs/research/{EXCHANGE_PROTOCOL,BOOK_RESEARCH_AGENT,RESEARCH_METHOD}.md`; repo dışında `.claude/agents/*.md` (7 dosya) ve zamanlanmış görev.

### 2026-10-14 · book-intelligence@227fcea · Haftalık araştırma turu ve 9 öneriye karar
- Haftalık döngü çalıştı (koşu `r_20261014_132709`): iki yeni Book Dash kitabı sayfa sayfa incelendi, *Best Friends* (arkadaşlık) ve kelimesiz *An Unexpected Adventure* (macera). İncelenmiş kitap sayısı 7 oldu.
- İki kitap 8 mevcut iddiaya destek ya da karşı örnek olarak eklendi. Güven düzeyi değişmedi, yeni iddia yok, bu yüzden ajan turu yapılmadı.
- Batuhan 9 öneriye tavsiye doğrultusunda karar verdi: tekrar eden satır deneyi, sayfa sonu merak sorusu ve arkadaşın duyguyu yansıtması onaylandı; 4 öneri bekletildi; korku sınırı ve "yetişkin çözer" önerileri reddedildi.
- Haftalık görev güncellendi: her hafta en az bir kitap Book Dash dışından gelecek (African Storybook ya da StoryWeaver, olmazsa Internet Archive).
- Bilerek değişmeyen: motor, içerik, uygulama kodu. Onaylanan deney henüz çocuklara ulaşmıyor; varyant yazılıp güvenlikten geçtikten sonra yayın için ayrıca onay gerekir.
- Test: `ba validate` 0 hata.
- Etkilenen: `Research/BookIntelligence/data/**` (2 eser, 8 iddia, 9 karar), `docs/research/**` (haftalık sayfa, rapor, deep-dive'lar, digest); repo dışında zamanlanmış görev `magicpaper-learning-loop`.

### 2026-10-14 · book-intelligence@3d55ee8 · Çocuk kitabı araştırma ajanı ve öğrenme döngüsü
- Yeni, uygulamadan ayrık araştırma aracı: `Research/BookIntelligence/` (Python stdlib CLI `book_agent.py`) ve `docs/research/`. Yasal kaynaklardan (Book Dash CC BY 4.0, Internet Archive ≤ 96 yıl, Gutenberg) kitap bulur, sayfa sayfa analiz eder, kanıt ve güven düzeyiyle iddia üretir.
- Fikir alışverişi (`exchange`): araştırma önerileri story-engine, content-library ve privacy-safety ajanlarıyla tartışılır; tek insan onayı çocuğa ulaşan her şeyde. 9 öneri karar bekliyor (`docs/research/EXCHANGE_DIGEST.md`).
- Döngü: deneyler (tahmin veriden önce kaydedilir), kullanım verisi içe aktarma (hücre başına ≥ 50 okuma, ≥ 7 gün), kalibrasyon, `cycle`; haftalık zamanlanmış görev `magicpaper-learning-loop` (pazartesi 10:10). 14 Ekim'de elle bir kez çalıştırıldı.
- `firebase/functions`: `aggregateOutcomes` zamanlanmış fonksiyonu ve `src/outcomes.js` eklendi; deploy edilmedi (Batuhan).
- Bilerek değişmeyen: StoryEngine, içerik, katalog, uygulama kodu. Kitap metinleri git'e girmez (`cache/`). Dal main'e birleştirilmedi; origin'de, PR açılmadı.
- Test: araştırma testleri 110/110, `outcomes` fonksiyon testleri 15/15.
- Etkilenen: `Research/BookIntelligence/**`, `docs/research/**`, `firebase/functions/src/outcomes.js`, `firebase/functions/index.js`, `firebase/functions/test/outcomes.test.mjs`; repo dışında `.claude/agents/book-research.md`.

### 2026-10-14 · main (c223ccd) · Liquid Glass alt çubuk main'e alındı
- `liquid-glass-tab-bar` dalı main'e ileri sarıldı (origin'e gönderilmedi, izin bekliyor): yüzen cam alt çubuk, yalnızca ikon, seçilince içi sekmenin rengiyle dolar, Yarat yalnızca artı, çubuk ana ekran göstergesinin hemen üstünde.
- Birleşmeden önce main'in son hâli (Ana sayfa, Günlük, günlük kayıtları) dala alındı; yalnızca bu dosyada çakışma vardı, iki tarafın kayıtları da korundu.
- Test: birleşik hâlde uygulama testleri 697, 0 hata, 1 atlandı.
- Etkilenen: bu dosya (önceki kayıtlarda listelenen dosyalar main'e girdi).

### 2026-10-14 · liquid-glass-tab-bar (6dd3573 üstüne) · Alt çubuk yalnızca ikon, seçilince içi boyanır
- Çubukta yazı yok, yalnızca ikon (Yarat dahil). Sekmelerin adı VoiceOver'da ve basılı tutunca büyük içerik görüntüleyicide okunuyor.
- Her sekmenin kendi rengi var: Ana sayfa mor (`brand`), Günlük sarı (`reward`), Kitaplık mercan (`play`), Köşem yeşil (`calm`). Seçilince ikonun içi o renkle dolar (SF Symbol `.fill`, çizgiden dolguya sembol geçişi) ve bir kez zıplar; Hareketi Azalt'ta yalnızca dolgu değişir. Seçim renkle birlikte dolu/boş şekil farkıyla da belli.
- Seçili sekme arkasındaki hap kaldırıldı. Yarat: marka renginde hap, içinde artı.
- Sekme ikonları Lucide yerine SF Symbol (Lucide'nin dolu hâli yok); `MPIcon`'a `symbolOnly` eklendi.
- Çubuk aşağı indi: ana ekran göstergesi olan cihazda alt kenarı ekranın altından 16 pt (`MP.S.x4`) yukarıda; göstergesiz cihazda 8 pt boşluk (`mpFloatingBar`).
- Kaldırıldı: resimli ikon denemesi (Batuhan: ek görsel kullanılmasın) ve `docs/TAB_ICON_PROMPTS.md`; "Alt çubukta tüm yazılar" geliştirici anahtarı.
- Bilerek değişmedi: cam yüzey, ebeveyn `TabView`'ı, üst başlıklar.
- Test: uygulama testleri 696, 0 hata, 1 atlandı (main birleşimiyle 3 yeni test). Tasarım yasası denetimleri yeni satırlarda boş. Simülatör (iPhone 17 Pro, iOS 27): dört sekme.
- Etkilenen: `MPNavigationChrome.swift`, `MPIcon.swift`, `MPGlass.swift`, `SettingsView.swift`, `docs/TAB_ICON_PROMPTS.md` (silindi).

### 2026-10-14 · liquid-glass-tab-bar (0e68d68 üstüne) · Alt çubukta yazı yalnızca seçili sekmede
- Çocuk alt çubuğunda yazı artık yalnızca seçili sekmede ve Yarat'ta görünüyor; diğer sekmeler yalnızca ikon ve ortada. Seçilince ikon yukarı kayar, yazı altından açılır; Hareketi Azalt'ta yalnızca belirir.
- Yatay hap (`[ikon Ana sayfa]`) denendi ama beş öğeyle iPhone SE'ye sığmıyor, sekme dokunma alanı 48 pt'nin altına düşüyor; bu yüzden dikey düzen.
- Karşılaştırma için geliştirici ayarına "Alt çubukta tüm yazılar" anahtarı eklendi (yalnızca DEBUG). Kapalı (varsayılan) yeni biçim.
- VoiceOver her sekmenin adını okumaya devam ediyor; basılı tutunca büyük içerik görüntüleyici çalışıyor.
- Resimli ikonlar için görsel promptları yazıldı: `docs/TAB_ICON_PROMPTS.md` (Ana sayfa, Günlük, Kitaplık; Köşem çocuğun avatarı). Görseller Batuhan'dan bekleniyor.
- Bilerek değişmedi: Yarat, cam yüzey, seçili sekme hapı.
- Test: uygulama testleri 693, 0 hata, 1 atlandı. Tasarım yasası denetimleri yeni satırlarda boş. Simülatör (iPhone 17 Pro, iOS 27): Kitaplık ve Ana sayfa, sekme geçişi.
- Etkilenen: `MPNavigationChrome.swift`, `SettingsView.swift`, `docs/TAB_ICON_PROMPTS.md` (yeni).

### 2026-10-14 · liquid-glass-tab-bar (3862324 üstüne) · Alt çubuk camı geliştirildi
- Çubuk iOS 26+ `safeAreaBar` ile yerleşiyor (`mpFloatingBar`): altından kayan içerik sistemin kaydırma kenarı efektiyle yumuşar. Öncesinde `safeAreaInset`.
- Cam dokunuşa tepki veriyor (`.interactive()`), kâğıt tonu %50'den %25'e indi: kapakların rengi camdan geçiyor, beyaz bir şerit gibi durmuyor.
- Pasif sekme rengi `textTertiary` → `textSecondary`: beyaz cam üstünde kontrast yaklaşık 2.5:1'den 5:1'e çıktı.
- `MPModeSwitch` kendi `GlassTrack`'i yerine ortak `mpGlassSurface`'i kullanıyor; böylece Saydamlığı Azalt yedeği ve ton ayarı iki kontrolde aynı.
- Bilerek değişmedi: Yarat hapı, seçili sekme göstergesi, üst başlıklar, ebeveyn `TabView`'ı.
- Test: uygulama testleri 693, 0 hata, 1 atlandı. Tasarım yasası denetimleri yeni satırlarda boş. Simülatör (iPhone 17 Pro, iOS 27): Ana sayfa ve Kitaplık. Yalnızca iOS 27 runtime kurulu; iOS 26 öncesi yedek yol hâlâ görülmedi.
- Etkilenen: `MPGlass.swift`, `MPTheme.swift`, `MPNavigationChrome.swift`, `ContentView.swift`, `MPModeSwitch.swift`.

### 2026-10-14 · liquid-glass-tab-bar (675bb72 üstüne) · Çocuk alt çubuğu Liquid Glass
- Çocuk modunun alt çubuğu (`KidTabBar`) içeriğin üstünde yüzen cam bir kapsül oldu: iOS 26+ sistem Liquid Glass'ı, öncesinde sistem materyali + kâğıt tonu, Saydamlığı Azalt açıkken opak kâğıt.
- "Yarat" çubuğun içine indi: yükseltilmiş 64 pt daire, gradient ve mor parlama kalktı; sekmelerle aynı satırda marka renginde dolu hap. Cam üstüne cam konmadı.
- Seçili sekmenin simgesinin arkasında `brandSoft` hap; sekmeler arasında kayar, Hareketi Azalt açıkken çapraz geçer. Dokunma alanı çocuk ölçüsüne (56 pt) çıktı.
- Yeni: `MP.Glass` token'ları (`MPTheme.swift`), `mpGlassSurface(in:)` (`MPGlass.swift`).
- Kararlar (13 Ekim, Batuhan): Yarat çubuğun içinde, yüzen kapsül, üst başlıklar sonraki tur, cam kuralı `CLAUDE.md` "Derinlik"e eklendi (yalnızca içerik üstünde yüzen gezinme kontrolleri). Araştırma ve plan: `docs/LIQUID_GLASS_TAB_BAR_PLAN.md`.
- Bilerek değişmedi: ebeveyn `TabView`'ı (sistem camını zaten alıyor), üst başlıklar, `MPModeSwitch`, kullanılmayan `MPTabBar`, `ContentView` yerleşimi.
- Test: uygulama testleri 692 geçti, 0 hata. Tasarım yasası denetimleri yeni kodda boş. Simülatör (iPhone 17 Pro, iOS 27): Ana sayfa ve Kitaplık, normal ve en büyük Dynamic Type; etiketler kesilmiyor. iOS 17.6 yedek yolu, koyu görünüm (uygulama yalnızca açık), küçük ekran ve VoiceOver simülatörde bakılmadı.
- Etkilenen: `MPNavigationChrome.swift`, `MPTheme.swift`, `MPGlass.swift` (yeni), `docs/LIQUID_GLASS_TAB_BAR_PLAN.md` (yeni), `docs/MagicPaper_Design_System.md`, `CLAUDE.md` (kökte, repo dışında).
### 2026-10-13/14 · main@675bb72 → main@75a578f · FAZ 20: Günlük (ücretsiz masallar)
- Alt bar beş öğe: Ana sayfa · Günlük · Yarat · Kitaplık · Köşem (İrem'in tasarımı; Köşem sekmesi korunarak Günlük eklendi).
- Ekranlar (`Screens/Gunluk/`): Günlük, Kategoriler, Kategori rafı ve arama, Klasik detay, Seri klasik.
- Başlık vitrini (`GunlukHeaderCarousel`): ekranın tepesinden başlayan boyalı kapak slaytları, sırası kaldığın yer → günün masalı (editör: Rapunzel) → uyku saatinde uyku masalı → seçki; 7 sn'de bir sakin geçiş, dokununca durur, Hareketi Azalt'ta yok; sonsuz döngü (`GunlukLoop`).
- Kart dili Ana sayfayla aynı: her raf tek beyaz kart (lavanta kenar, sert alt kenar, `GunlukSection`), gölge yok; detay ve seri aynı sahne (`gunlukStage`), düz mor ana düğme, "Bu masalla" kutuları Ana sayfa mod kutularıyla aynı.
- İçerik: 56 masal metni (16 tek, 5 seri: Keloğlan, Nasreddin Hoca, Dede Korkut, Karagöz, Kelile ve Dimne), 5'inde Klasik anlatım; güvenlik incelemesi bulguları işlendi. Kaynak `Content/Classics/`, katalog `Scripts/ClassicsCatalog/build_classics_catalog.py`.
- Kapaklar: 13 kamu malı renkli illüstrasyon (Gruelle, J. W. Smith, Anderson, Abbott, Rackham, Nicholson), kaynaklar `Content/Classics/COVER_SOURCES.md`; 11 masal kapağı bekliyor (pastel yedek kapak, üretim onaylanmadı).
- "Bu hafta en çok okunan" yerine editör listesi "Bu haftanın seçkisi" (gerçek okuma verisi yok).
- Bilerek değişmedi: Ana sayfadaki "Günün masalı" kartı (günlük akış masalı) bu turda klasiklere bağlanmadı; "Kahramanı ben" düğmesi motor desteğine kadar gizli; yıldız harcaması yok.
- Test: Günlük testleri 35/0 (`ClassicsCatalogTests`, `ClassicProgressTests`); tam takım son ölçüm 681/0 (vitrin değişikliklerinden önce); telefonda (iPhone 16) denendi.
- Etkilenen: `Screens/Gunluk/*`, `MPAppState.swift`, `MPNavigationChrome.swift`, `ContentView.swift`, `StoryReaderModel.swift`, `StoryReaderView.swift`, `MPStoryExtras.swift`, `MPTypography.swift`, `MPColor.swift`, `Assets.xcassets/Classics`, `Content/Classics/`.

### 2026-10-14 · main@b321c1e · Ana sayfa: aşağı çekerken yalnızca manzara yakınlaşır
- Sayfa en üstteyken aşağı çekince başlık, çipler ve kartlar yerinden oynamaz; içerik çekilen mesafe kadar geri tutulur, manzara köy hizasından yerinde yakınlaşır.
- Kaydırma ölçüsü içerikten değil ayrı görünmez bir işaretten okunur (önceki denemede içerik sabitlemesi ölçümü sıfırlıyordu).
- Görselin üst kenarı ile gökyüzü arasındaki ince dikiş çizgisi, daha uzun geçişle kalktı.
- Bilerek değişmedi: Ragi tepede yerinde durur, esneme zıplamaz (tasarım yasası, sürükleme).
- Test: derleme yeşil; simülatörde çekme anı ekran görüntüsüyle doğrulandı (öğeler sabit, manzara yakınlaşıyor).
- Etkilenen: `MagicPaper/Views/HomeView.swift`, `MagicPaper/DesignSystem/Pastel/MPHomeChrome.swift`.

### 2026-10-14 · main@3a6f75e · Ana sayfa: aşağı çekerken başlık sabit
- Sayfa en üstteyken aşağı çekince selam, avatar ve kilit yerinde kalır; yalnızca başlık sahnesi esner ve yakınlaşır (`HomeView`, başlığa `offset(y: -pull)`).
- Bilerek değişmedi: çipler ve kartlar içerikle birlikte hareket eder; esneme doğrudan dokunuşu izler, zıplama yok (tasarım yasası, sürükleme).
- Test: derleme yeşil. Simülatörde çekme anı bu turda yakalanamadı (simülatörü başka bir oturum devraldı).
- Etkilenen: `MagicPaper/Views/HomeView.swift`.

### 2026-10-13/14 · main@fd6d67a → main@17c68e5 · Ana sayfa: telefon testi düzeltmeleri
- Başlık sahnesi ekranın ~%40'ı; görsel ekran genişliğine sığar, gökyüzü üstte dikişsiz devam eder (`MPColor.sceneSkyDay/Night`).
- Sahne görselleri Batuhan'ın ChatGPT ile ürettiği maskotsuz gündüz/gece manzarası (`Assets.xcassets/Scenes`, taslak).
- Ragi ayrı katman (`HomeSceneMascot`): markanın görseli, gündüz okur gece uyur; süzülme, nefes, dokununca zıplama; Reduce Motion'da durur.
- `MPPressStyle` (tüm uygulama): basınca alt kenara çökme, bırakınca `MP.M.spring`; `sinkFlat` de hareket eder. Ana eylemlerde tek `MPHaptics.tap`.
- Avatar/isim ve alt bar sekmeleri `.plain` yerine `MPPressStyle`; seçili sekme ikonu yaylanır; sekmeler kayma + solma ile değişir (`ContentView`).
- Esneyen başlık: aşağı çekince beyaz boşluk yerine sahne alttan büyür (`HomeScene.pull`).
- Yeni token: `MP.M.idle` (Ragi'nin nefesi).
- Test: MagicPaperTests 662/0 (1 atlandı); simülatörde gündüz, gece ve çekme anı görüldü; telefona kuruldu.
- Etkilenen: `HomeView.swift`, `MPHomeChrome.swift`, `MPTheme.swift`, `MPColor.swift`, `MPNavigationChrome.swift`, `ContentView.swift`, `Assets.xcassets/Scenes`.

### 2026-10-13 · main@d1b2a28 · Ana sayfa ve Masal ailem yenilemesi
- Ana sayfa: illüstrasyonlu başlık sahnesi (`HomeScene`), yıldız ve okuma serisi çipleri (`HomeStatChips`), mor hero kartı, her bölüm tek kart (`HomeSection`), beyaz lavanta kenarlı kart dili (`mpKidSurface`), ekranda tek Ragi.
- Yıldız sayacı `MPStars`: her sabah 1 + biten her masal 1, rozet defterinden türetilir; harcama yok.
- Masal ailem aynı dille: mor kahraman kartı, pastel karakter kareleri, mor halka + tik ile seçim (seçim şimdilik tek).
- Ana sayfa Köşem sekmesine `openKidCorner()` ile gider; `kosem-sekme`'nin geçici `showKidCorner` köprüsü silindi.
- Bilerek değişmedi: hero kartı metinleri, karakter düzenleyici, motorun tek aile karakteri.
- Test: MagicPaperTests 662/0 (1 atlandı); en büyük yazı boyutu ve kontrast kontrolü.
- Etkilenen: `HomeView.swift`, `MPHomeChrome.swift` (yeni), `MPStars.swift` (yeni), `FamilyCharactersView.swift`, `SeriesCard.swift`, `MPAppState.swift`, tasarım notu `docs/superpowers/specs/2026-10-13-ana-sayfa-yenileme-design.md`.

### 2026-10-13 · main (ab6f02c üstüne) · Günlük kuralı uygulama işlerine genişletildi
- Bundan sonra tamamlanan her iş (uygulama, canvas, içerik, belge) bu günlüğe yazılır.
- Kural iki yerde: bu dosyanın "Kural" bölümü ve kaynak koddaki `CLAUDE.md` (yeni "Değişiklik günlüğü" bölümü, Definition of Done maddesi).
- Etkilenen: `CLAUDE.md` (repo dışında, kökte), `design-handoff/reference/DEMO_CHANGELOG.md`.

### 2026-10-13 · main (ab6f02c üstüne) · Okuyucu sayfalarındaki süslemeler kaldırıldı
- Masal sayfasından kâğıda serpiştirilen süs katmanı (dekorasyon motoru) çıkarıldı.
- Sayfa süsü seçenekleri çıkarıldı: süslü ilk harf (versal), paragraf sonu vinyeti, sayfa çerçevesi, kenar spot motifi.
- Süsleme sisteminin tüm kodu silindi; `docs/DECORATION_SYSTEM_HANDOFF.md` → `docs/retired/`. Geliştirici ayarlarındaki "Dekorasyon galerisi" ve "Dekorasyon demoları" satırları kaldırıldı.
- Bilerek değişmedi: kâğıt rengi, kâğıt dokusu ve cilt payı gölgesi (`ReaderPaper`), sahneler ve resimler, kapak, bitiş sayfası. `Storybook/` görselleri başka ekranlarda kullanıldığı için duruyor.
- Test: derleme yeşil, MagicPaperTests 657 test, 0 hata, 1 atlandı (önceki 660 testin 3'ü silinen süsleme seed testleriydi). Simülatörde görsel kontrol yapılmadı.
- Etkilenen: `StoryPageView.swift`, `StoryLeafView.swift`, `ContentView.swift`, `MPAppState.swift`, `SettingsView.swift`. Silinen: `StoryDecorationCatalog.swift`, `StoryDecorationCatalog+Generated.swift`, `StoryDecorationDemoView.swift`, `StoryDecorationEngine.swift`, `StoryDecorationGallery.swift`, `StoryDecorationTaxonomy.swift`, `StoryEnvironment.swift`, `StoryPageDecorationLayer.swift`, `ReaderPageOrnament.swift`, `MagicPaperTests/StoryDecorationSeedTests.swift`.

### 2026-10-03 · v21 · CLAUDE.md eklendi
- Canvas'a `project/CLAUDE.md` eklendi, kopyası projede `claude/magicpaper-demo-CLAUDE.md`.
- Bundan sonra her canvas değişikliği bu günlüğe aynı yayında yazılır.
- Ekranlarda değişiklik yok.

### 2026-10-03 · v20 · Marka kiti ve maskot
- Marka kitindeki rakun maskot, logo, uygulama simgeleri ve gece sahnesi canvas'a varlık olarak yüklendi (20 dosya).
- Arayüzün eylem rengi maviden marka moruna çevrildi, metin rengi marka mürekkebi (#2E1E3E) oldu.
- Eski 3D çocuk görseli tüm ekranlardan kaldırıldı.
- Maskot yerleşimi: Karşılama 1 (logo + kitapta), Karşılama 2 (gece sahnesi, koyu mor zemin), Karşılama 3 (yürüyor), Giriş (simge + logo), Ebeveyn onayı (sakin), Neleri sever (meraklı + balon), Bildirim izni (uykulu), Masal yazılıyor ve İlk masal (kalemli), Ana sayfa (meraklı balon "Bu gece hangi dünyaya gidelim?", okundu kartında el sallıyor, uyku kartında uyuyor), Masal sonu (el sallıyor + "Harika bir masaldı!"), Uyku modu (uyuyor), Abonelik (kitapta), durum ekranları (okuyor, şaşkın, düşünceli, uykulu).
- Widget, kilit ekranı ve bildirimlerde uygulama simgesi; küçük widget'ın zemini gece sahnesi.
- Yeni ekran: `Marka.dc.html` (marka ve maskot rehberi, canvas'ın en üst satırı).
- Etkilenen: Main, Onboarding2, Onboarding3, Giris, EbeveynOnayi, NeleriSever, BildirimIzni, IlkMasal, Uretim, AnaSayfa, MasalSonu, UykuModu, Paywall, BosKitaplik, UretimHata, InternetYok, YildizBitti, Widgetlar, KilitEkrani, Marka ve renk dönüşümüyle tüm ekranlar.

### 2026-10-03 · v19 · Altı yeni özellik
- Kahraman oluşturucu (`KahramanOlustur`): ten, 4 saç modeli, saç rengi, kıyafet, gözlük; canlı avatar.
- Görselli okuyucu (`OkuyucuGorselli`) ve iPad yatay okuyucu (`iPadOkuyucu`).
- Kendi sesin (`SesKaydi`): sayfa sayfa kayıt; Okuma ayarlarına "Kim okusun?" seçimi.
- Masal ailem (`MasalAilem`) ve seri masal (`SeriMasal`); Yarat 2'ye "Masalda kimler olsun?"; Ana sayfa ve Kitaplık'a seri kartı.
- iOS yüzeyleri: `Widgetlar`, `KilitEkrani` (Live Activity, bildirim, Siri).
- Ebeveyn: `KitapSiparisi`, `Paylas`, `AileUyeleri`, `AbonelikBitti`, `HesapSil`; Ayarlar'a "Aile ve ses" bölümü.
- Ebeveyn alt sayfalarında başlık sıkışmasın diye "Çocuk modu" düğmesi yalnızca kök sayfalarda kaldı.

### 2026-10-03 · v16 to v18 · Yeni bilgi mimarisi
- Mimari belgeye göre canvas yeniden kuruldu: 31 ekran, 5 satır.
- Çocuk alt barı 3 sekmeye indi; avatar, yıldız ve kilit üst bara taşındı.
- Sihirbaz 2 adıma indi. `SihirbazKim`, `Gunluk`, `ProfilSecimi` kaldırıldı.
- Yeni ekranlar: Giriş, Ebeveyn onayı, Neleri sever, Bildirim izni, İlk masal, Benim köşem, Yeni kelimelerim, Masal sonu, Uyku modu, Onaylar, Güvenlik, 4 durum ekranı.
- Ana sayfaya 4 durumlu "Bu akşamın masalı" kartı (Tweaks: `durum`).
- Ebeveyn alanı gri zemin ve kendi alt barıyla ayrıldı; Abonelik ebeveyn alanına taşındı.

### Eylül 2026 · Referans estetiğine geçiş
- Demo canvas, referans görselin diline taşındı: krem zemin, pastel kartlar, parlak yuvarlak butonlar, Nunito, 3D çocuk görseli.
- Tasarım sistemi artifact'ı bilerek değiştirilmedi.

### Eylül 2026 · İlk kurulum
- Tasarım sistemi bileşenleriyle 19 ekran kuruldu ve baştan sona tıklanabilir akış olarak birbirine bağlandı.

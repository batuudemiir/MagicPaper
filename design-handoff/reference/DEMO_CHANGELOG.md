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

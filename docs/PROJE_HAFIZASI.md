# Proje hafızası

Claude Code oturumlarının 17 Kasım 2026'ya kadar biriktirdiği notlar (karar, kaldığı yer, tuzak). Her bölüm yazıldığı günün durumunu anlatır: dosya, dal ya da commit adı geçiyorsa kullanmadan önce hâlâ var mı bak. Yeni kalıcı bilgi buraya ilgili bölümün altına ya da yeni bölüm olarak eklenir.

## İçindekiler

- [Semantik görsel havuzu](#semantik-gorsel-havuzu) — 19 Kasım: motor/seri/havuz incelemesi, 33 nesne envanteri, 12 guaj konu çizimi; ilk 10 konu/5–6 açılış entegrasyonu, 145 uygulama testi hatasız
- [Okuyucu guaj tasarımı](#okuyucu-guaj-tasarimi) — 19 Kasım: üst spot, Nunito600/800, iki sıralı chrome ve Aa ayarları onaylı referansa hizalandı
- [Offline guaj pilotu](#offline-guaj-pilotu) — 18 Kasım: 24 gerçek motor çıktısı, iki çizim/48 eşleme; altı ışık dili uyumsuzluğu ve bakım hedefi incelemesi; üretim entegrasyonu yok
- [Blueprint & v3 corpus realignment](#blueprint-corpus-realignment) — D3/D10 kapandı; K1 de kapandı: saklanan hikâyeler üretilmiş metni tutuyor, seed drift kullanıcıyı etkilemiyor.
- [MagicPaper Grup 1 + 1.5](#magicpaper-group1-integration) — build yeşil, 761/23 test; kalan hatalar tek içerik boşluğundan; Grup 2 önkoşulları ve dosya sahipliği kuralları.
- [Faz 0 kapandı](#phase0-closed-2026-09-30) — Entitlements target'ta, 248/0 + 647/18; paket testi scratch-path ile; açık gizlilik kalemleri
- [Görselli masal henüz canlı değil](#illustrated-stories-not-live) — Faz 9 ile Gemini metin yolu ve sihirbaz silindi; görsel kod CloudIllustrationAccess arkasında
- [B2 sahne kütüphanesi](#b2-scene-library-phase0) — Faz 1 tamam, Faz 2 onay bekliyor; b2/baseline geri alma dalı; iCloud dataless tuzağı
- [FAZ 10 planı](#faz10-plan) — plan repo dışında geçici; FAZ 10 ✅, main'de ve origin'de (677e73a); iCloud kopya ve Secrets.xcconfig tuzakları
- [Faz 9 kapandı](#faz9-closed-2026-10-03) — faz-9 dalı; bulut metin yolu silindi, görsel yol bayrakta; 350/0 + 647/18; disk dolu, yeni DerivedData açma
- [FAZ 11 Masal ailem](#faz11-masal-ailem) — main+origin 260763d; 675/18 + 404/0; temiz worktree doğrulama yöntemi
- [Shared checkout branch switch](#shared-checkout-branch-switch) — parallel sessions switch branches in the same checkout; check branch right before commit
- [FAZ 12 İlgi alanları](#faz12-ilgi-alanlari) — main+origin 8481008; 854/18 + 417/0; ekranlar eşik 4 ile gizli; Deniz ölü içerik
- [FAZ 13 Seri](#faz13-seri) — main+origin 8ab294c (takip dahil); kararlar ve kaldığı yer
- [FAZ 14 Kullanımdan öğrenme](#faz14-kullanim) — main+origin e418173; 741/18 + 472/0; FAZ 16 devri (bildirim, politika, storyID)
- [FAZ 15 Uzaktan içerik](#faz15-uzaktan-icerik) — main+origin c5a813c; 912/18 + 514/0; anahtar/deploy Batuhan'da
- [FAZ 16 Hesap ve senkron](#faz16-hesap-senkron) — main b92e701 (push yok); 545/0 + kurallar 18/18; Firebase kurulumu ve bundle ID uyuşmazlığı Batuhan'da
- [FAZ 17 MVP](#faz17-mvp) — main+origin edb2a30; 586/0, 937/18, kurallar 19/19; açık: VoiceOver (Batuhan); disk %99
- [FAZ 17 Pastel teslimi](#faz17-pastel) — İrem'in tasarımı faz-17-pastel'de (worktree MagicPaper-faz16); FAZ 17 arayüz blokları da burada
- [Book Intelligence ajanı](#book-intelligence-agent) — book-intelligence 5f30954 (21 Ekim, origin'de), 24 kitap; ilk UX önerisi karar bekliyor; main+origin 5263241 (merge 09c3dd2); aggregateOutcomes deploy edilmedi
- [FAZ 18 Aile](#faz18-aile) — main+origin 43f513a (13 Ekim push); 631/0, kurallar 51/51; Firebase adımları + plist proje kimliği uyuşmazlığı Batuhan'da
- [Çocuk alanı tasarım kararı](#cocuk-alani-tasarim-karari) — 13 Ekim: yıldız, kilitli rozet, çoklu aile seçimi tasarımdaki gibi; ilke 7'yi geçersiz kılar
- [FAZ 19 iOS yüzeyleri](#faz19-ios-yuzeyleri) — main+origin 7a9bca7; 652/0; Live Activity ay simgesi açık
- [Köşem sekmesi](#kosem-sekme) — tarihsel: 7 Kasım'dan beri adı Profil (bkz. gezinme-tek-duzen); main ab6f02c, 13 Ekim cf9e656 ile origin'e gitti, 660/0; yıldız + HomeView adımı anasayfa birleşmesini bekliyor
- [Değişiklik günlüğü kuralı](#degisiklik-gunlugu-kurali) — biten her iş (küçüğü de) DEMO_CHANGELOG.md'ye hemen; kirli dosyada bile ertelenmez, yalnız kendi hunk'ını commit'le
- [Ana sayfa yenileme](#anasayfa-yenileme) — main+origin 1a4870b (16 Ekim): ana sayfa + Benim köşem yeni dilde, Ragi ön planda; Batuhan tasarım kararları
- [Liquid Glass alt çubuk](#liquid-glass-tab-bar) — main 912f6cd (15 Ekim, push yok, derlenmedi); zıplama yok, yalnızca dolgu + renk
- [FAZ 20 Günlük](#faz20-gunluk) — main e87ee09 (15 Ekim, push yok), origin 19eead7+; 5 sekmeli bar, vitrin, 56 masal, 13 kamu malı kapak; 11 kapak bekliyor; Xcode grup ve simülatör tuzakları
- [Uyku modu v2](#uyku-modu-v2) — main+origin ba2ad8b; uyku modu bayrakta kapalı, akşam üç mod; pencere yalnız dokununca; -mpDemo ve gizli dosya kopyalama tuzağı
- [Ragi ön planda](#ragi-on-planda) — 16 Ekim: her çocuk ekranında Ragi görünür (Duo gibi); ekran başına tek, ebeveyn alanında yok
- [Masal atölyesi](#masal-atolyesi) — "Masal yazılıyor" defteri (599c7d6, origin) + 20 Ekim ithaf/künye/dil main+origin 549d851, raf geri alındı; akşam zarfı planı 909d162, inşa dal aksam-zarfi WIP 3bc022a (derlenmez); Models/ senkronlu değil
- [Kitaplık yenileme](#kitaplik-yenileme) — main+origin 0e28f5b (21 Ekim): mod rafları + klasikler, kapak Günlük ölçüsünde mozaik/boyalı (sırt reddedildi), StoryCoverDefault silindi; ana sayfa kasma düzeltmeleri de gitti
- [Uyku arkı](#uyku-arki) — main+origin b70dc4d (21 Ekim, merge ec732f5): bedtime kendi arkında, odalar, uyku devam bölümleri; 819/18; simülatörde görülmedi
- [FAZ 21 Varyasyon](#faz21-varyasyon) — 30 Ekim: konu olay örgüsünü de süzüyor (8d7d33c, push yok); doğrulayıcının anyOf kusuru yedi yanlış kırmızı üretiyormuş
- [Haftalık döngü: güncel kitaplar](#haftalik-dongu-guncel-kitaplar) — 29 Ekim: en yeni yayınlar önce (2020+), IA/Gutenberg yok; StoryWeaver 3 hikâye sınırı
- [Bütünlük denetimi](#butunluk-denetimi) — 22-23 Ekim: 1-6. adım bitti, main+origin 2a9196f, 782/0; MPModeSwitch silindi (4e6e9c8); açık: VoiceOver, buton gradient'i, token adları
- [Gezinme tek düzen](#gezinme-tek-duzen) — 7 Kasım: ebeveyn odası, push gezinme, sistem sheet'i main+origin c398a60, 795/0; iCloud " 2" dal kopyası fetch'i bozabilir; çubuk Ana sayfa · Masallar · Kitaplık · Profil + Masal yaz; xcodebuild -list takılıyor
- [Startup planı Faz 0-2](#startup-plani-faz0) — 7 Kasım: testler, Baloo 2, sekiz yazı rolü, düğmeler, MPRouter main'de (push yok); ebeveyn odası VoiceOver açık; sıradaki Faz 3
- [Faz 4 Ragi canlılık](#faz4-ragi-canlilik) — 7 Kasım: Ragi kod kuklası + sentez ses, masal sonu main'de (push yok); sesler dinlenmedi, yüksek çözünürlüklü çizim açık
- [Faz 5-6 ve yayın](#faz5-6-yayin) — 8 Kasım: masal sonu tam ekran, Faz 5, Faz 6 kodu main'de (push yok); huni bayrakla kapalı, yayın adımları Batuhan'da
- [Vizyon planı ve Faz 7](#vizyon-plani-faz7) — 11 Kasım: docs/VIZYON_PLANI.md (Faz 7-14); Faz 7 main fee1e7d, Profil → Odam, tek kapı; test ve simülatör yok
- [Test yalnız plan sonunda](#test-yalniz-plan-sonunda) — tüm testler ve simülatör yalnızca plan bitince bir kez; ara adımda kod okuyarak çöz
- [Token tasarrufu pilotu](#token-tasarrufu-pilotu) — 7 Kasım: CodeGraph A/B kazanç göstermedi, kurulmadı; maliyet bağlam tekrarında; context-mode ve Serena ölçülemedi; pilot ortamı temizlendi
- [MagicPaper Original](#magicpaper-original) — 12 Kasım: Masallar rafı + original-writer ajanı + pzt/per görev main 409c9d5 (push yok); dünya Bulut Durağı; 13 Kasım: uygulamayla gelir (uzaktan yok), ilk masal 5547c1c
- [Araştırma ↔ Original yazarı](#research-original-writer-loop) — 13 Kasım: craft notları + ORIGINALS_CRAFT.md + iki yönlü sorular; book-intelligence d8c35d7 + main ba49cec origin'de, 149 test
- [Ebeveyn sadeleşmesi](#ebeveyn-sadelesme) — 15 Kasım: masal onayı kalktı, oda tek sayfa, basılı tutma kapısı; main+origin 6f90dc1
- [Rozet planı](#rozet-plani) — 15 Kasım: 69 rozet + yıldız puanı + 12 Yıldız katı, R0-R6 bitti, main+origin 54e8241; armalar illüstratörde
- [İki kademe çocuk arayüzü](#iki-kademe-cocuk-arayuzu) — 15 Kasım: KidLevel Küçük/Büyük main+origin de277da; alt çubuk ve ses kararı açık; snapshot testi takılıyor, iCloud " 2" kopyası derlemeyi kırar

---

## blueprint-corpus-realignment

_D3/D10 kapandı — Schema 2 kanonik, 15 blueprint, pilotlar MERGE edildi (emekli değil)_

2026-09-18: Blueprint korpus hizalaması tamamlandı. Schema 2 tek kanonik format.
`pilot_library_v1.json` 6 → 15 blueprint. 12 v2 blueprint emekli (hepsi aynı yayın
kopyasıydı, `isBeatAuthored == false` olduğu için seçilemiyorlardı) —
`docs/retired/retired_blueprints_2026-09-18.json` içinde geri alınabilir.

**K1 KAPANDI (2026-09-18):** Saklanmış hikâyeler **üretilmiş metni** saklıyor
(`Story.pages[].text`), seed'den yeniden üretilmiyor. `StoryOrigin`'in kod tabanında
sıfır okuyucusu var ve `compose()` yalnızca yaratma yolundan çağrılıyor. Yani seed drift
mevcut kullanıcı kitaplarını etkilemiyor ve D4'ü bloke etmiyor.

Detay: `MagicPaper/docs/MagicPaper_Content_Library.md` ve [[magicpaper-group1-integration]]

---

## magicpaper-group1-integration

_MagicPaper çok-agent Grup 1 sonucu — neyin yeşil, neyin kırmızı olduğu ve Grup 2 önkoşulları_

2026-09-18: Grup 1 (7 agent paralel) + Grup 1.5 stabilizasyon kapısı tamamlandı. Grup 1'de 7 agent çalıştı (product-architect, story-engine, character-system,
content-library, illustration-system, design-system, privacy-safety). App build yeşil; paket testleri
761/38 → **761/23** (Grup 1.5). TestPlan 1 → 5 target.

**Why:** Grup 2 (story-engine, character-system, parent-ux, reader, library-memory,
monetization) bu önkoşullar kapanmadan başlamamalı.

**How to apply:**
- Testler: düz `swift test` codesign hatası veriyor. `xattr -cr Sources Tests .build` +
  `swift test --build-system native --scratch-path .build-agent-<ad>` kullan.
- Kalan 23 hatanın tek kök nedeni var: `sea+dolphin+shell` matris satırı hiçbir
  blueprint'e oturmuyor. Üretim hatası DEĞİL, içerik tasarım kararı bekliyor.
- Agent'lar aynı `.build`'i paylaşmamalı — `--scratch-path` ile ayır.
- `StoryGenerationManager.swift` (1540 satır) D1'de story-engine'in tek sahipliğinde,
  D4'te library-memory devralır. Asla eşzamanlı iki agent'a verilme.
- D1 tek adımda yapılamaz: `createCustomStory` kaldırılırsa illüstrasyonlu masal üretimi
  tamamen kaybolur, ikamesi yok.
- D2 GERİ ALINDI (2026-09-18): `MPStreak` RETAINED — okuma sürekliliği mekanizması,
  oyunlaştırma değil. Kaldırmayı önerme. `CLAUDE.md` İlke 7 ve `.claude/agents/parent-ux.md`
  buna göre güncellendi. Hedeflenen semantik `StoryReadingSessionCompleted`; bugünkü
  davranış hikâye AÇILDIĞINDA artırıyor. Detay: `docs/MagicPaper_Streak_System.md`.

Detay: `MagicPaper/docs/MagicPaper_MultiAgent_Status.md`

---

## phase0-closed-2026-09-30

_Faz 0 kapandı (2026-09-30); Entitlements target'ta; test ölçümleri; paket testini Desktop dışında scratch-path ile koş._

2026-09-30: Faz 0 kapandı.
- `Services/Entitlements/` (6 dosya) pbxproj'a elle eklendi (grup ID `E5A0…01`, Persistence kalıbı). Entitlement testleri `MagicPaperTests/`'e geri taşındı, `MagicPaperTests.pending/` silindi.
- `Screens/`, `MagicPaperTests/`, `DesignSystem/`, `Helpers/`, `StoryEngineBridge/` senkronize grup: pbxproj'da "0 referans" target dışı demek DEĞİL.
- Ölçüm: uygulama 218 test / 0 hata (seed çakışması kullanıcı onayıyla düzeltildi: `seed(from:)` artık 16 bayt üzerinde FNV-1a). Paket 647 / 23 (bilinen içerik boşluğu).
- Faz 3'ün 4 MB yedeksiz silme hatası zaten düzeltilmiş (`LibraryMigration.quarantineOversizedLegacyBlob`).
- Faz 1.4: çocuk adı/yaşı, prompt, fotoğraf/görsel URL'si basan print'ler kaldırıldı. Firebase `child_uploads/` fotoğrafı üretim bitince siliniyor (`deleteUploadedImage`; Storage kuralları silmeye izin vermeli — doğrulanmadı).
- deleteProfile artık masalları da siliyor (`Story.isSolelyOwned(by:among:)`; isim paylaşılan eski masallar korunur) ve MPSheets'te confirmationDialog var (kullanıcı onayıyla). Hikâyeler `childProfileID` ile profile bağlı.
- Faz 2: `OfflineStoryService.compose` isClean kapısı: yeni hikâyede 3 taze seed dener, rebuild seed'inde tek deneme; kusurluysa `Failure.defectiveDraft`. Bugünkü katalogda hiç tetiklenmiyor (emniyet ağı). Uygulama 226/0.
- Olası okuyucu hatası: X butonu simülatörde tepki vermedi (spawn_task ile ayrıldı).

**Why:** Desktop dosyalarındaki xattr'lar `swift test` kaynak paketi imzalamasını bozuyor.
**How to apply:** Paket testini `swift test --scratch-path <scratchpad>/se-build` ile koş; build için `generic/platform=iOS Simulator` yerine tek simülatör hedefi daha hızlı. Bkz. [[magicpaper-group1-integration]].
- Faz 4 ✅ (2026-09-30): UI dikişi `StoryEngineBridge/StoryChoiceSource.swift`; ölü kod proje kökündeki `Retired/`'a taşındı (derlenmez). Zamir maddesi kullanıcı kararıyla kapatıldı (Türkçe zamir cinsiyetsiz). Durum özeti `docs/MagicPaper_Faz_Plani.md` başında.
- Faz 1.5 ✅ (2026-10-01): Services+StoryEngineBridge print→ dosya başına `private let logger = Logger(...)`. Logger sayıları (Int) varsayılan PUBLIC yazar → çocuk yaşı için `privacy: .private` şart. Autoclosure yüzünden özelliklere `self.` gerekir. Uygulama 248/0.
- Faz 7.1 ✅ (2026-10-01): sea+dolphin+shell matristen emekliye ayrıldı (kullanıcı kararı), `retiredSeaRow` negatif örnek. Paket tabanı 647/18. Faz 5 sahibi: 'Tasarım sistemi altyapısı' oturumu. Paralel UI oturumları var — view/DesignSystem dosyalarına dokunma. Desktop iCloud senkronu dosya işlemlerini çok yavaşlatıyor.

---

## illustrated-stories-not-live

_Görselli masal henüz canlı değil; bugün tüm metin masalları blueprint motoruyla (varyasyonlar) yazılıyor; Gemini Flash görselli masal gelince kullanılacak._

2026-09-30 itibarıyla görselli masal akışı (StoryWizardView → createCustomStory → Gemini + Fal) henüz kullanıma açılmadı. Bugün çocuğa giden tüm metin, blueprint motoru ile varyasyonlardan üretiliyor (`OfflineStoryService.compose`), ve bu yolda `isClean` kapısı var.

**Why:** Kullanıcı Gemini metin doğrulamasını planlamamı durdurdu; o yol canlı olmadığı için şimdi yatırım erken (CLAUDE.md: gelecek özellikleri erken uygulama).
**How to apply:** Gemini/Fal yolundaki işleri (StoryValidator'ı Gemini çıktısına bağlamak vb.) "görselli masal açılmadan önce yapılacak" olarak işaretle, şimdi önceliklendirme. Mevcut riskleri blueprint yolunda ara. Bkz. [[phase0-closed-2026-09-30]].

---

## b2-scene-library-phase0

_B2 (avatar + hazır sahne kütüphanesi) — Faz 1 tamam 2026-10-01; Faz 2 kullanıcı onayı bekliyor; ortam tuzakları_

2026-10-01: B2 Faz 0 planı (v2, gözden geçirme işlendi) ve Faz 1 (veri modeli + SceneSelector + 54 test) tamam. Plan ve durum: `MagicPaper/docs/B2_SCENE_LIBRARY_PLAN.md` §11–§12. Her faz ayrı turda; Faz 2'ye kullanıcı "başla" demeden geçme.

**Why:** Görev metni fazları ayrı turlarda istiyor; kullanıcı bir kez "Faz 1'den önce dur" dedi.

**How to apply:**
- Git deposu `MagicPaper/.git` (dal `design-system/magicpaper-redesign`, paralel oturumların commit'lenmemiş işi var). Dal DEĞİŞTİRME; geri alma noktası `b2/baseline` (1c023a3, geçici index + commit-tree ile).
- Desktop iCloud dosyaları "dataless" yapıyor → git/grep/build takılır. Teşhis: `find . -flags +dataless`; çözüm: `brctl download MagicPaper`.
- xcodebuild'e `-project MagicPaper.xcodeproj` şart (klasörde `m.xcodeproj` da var). Uygulama tabanı 302/0 (+1 skip); paket 804/18 (10 test, bilinen).
- Masallar UserDefaults'ta tek `[Story]` blob: yeni kalıcı alanlar String/Int, çözücü atmaz.
- zsh: `--include='*.swift'` tırnakla; değişkenle dosya listesi için dizi kullan.
Bkz. [[illustrated-stories-not-live]], [[phase0-closed-2026-09-30]].

---

## faz10-plan

_FAZ 10 uygulama planı geçici olarak repo dışında; K1-K9 hepsi kapandı (3 Ekim)_

2026-10-03: FAZ 10 planı `MagicPaperAPP/FAZ10_UYGULAMA_PLANI.md` (repo dışı, geçici). FAZ 9 merge edilince `MagicPaper/docs/`'a taşınacak.
Kararlar: K1 İrem canvas rengi (#6A47B8 / #5C3A8F / #3A2458 + türetilen #7653C2/#F2EDFA/#DCD0F1, degrade yok, lavanta #8F6BD6 yalnızca odak halkası ve adım noktası);
K6 sürpriz kartı yalnızca bantta ≥2 mod varsa; K8 dünya şeridi → ana sayfada mod kartları (ikinci adıma açılır), eski sihirbaz FAZ 10 sonunda envanter onayıyla silinir.
3 Ekim'de K2-K5, K7, K9 da kapandı; özet planın §13'ünde. FAZ 12 notu: ParentChildrenView'daki "Favori dünyalar" boşluğuna İlgi alanları bölümü gelecek.

**Why:** FAZ 9 docs/ ve Views/ düzenliyordu, çakışmamak için.
**How to apply:** FAZ 10'a başlamadan planı oku, §13'teki kararlara uy; B/C/D paketleri FAZ 9 merge edilmeden başlamaz. İlgili: [[magicpaper-group1-integration]]

**Durum (2026-10-04):** FAZ 10 ✅. Yerel main'de birleşti (e298bb5 fix/reader-close, 677e73a faz-10); uygulama 379/0, paket 658/18. Kullanıcı push'ladı: origin/main = 677e73a. Kapanış notu, tasarım yasası borcu ve koyu tema sorusu `MagicPaper_Faz_Plani_Ekim.md`'de.

**Ortam tuzakları:**
- Desktop iCloud " 2"/" 3" çakışma kopyaları üretiyor (4 Ekim'de 584 tane, Çöp'e taşındı). Build öncesi: `git status --short --untracked-files=all | grep -E ' [23]\.'`.
- Eski main `Secrets.xcconfig` ve `GoogleService-Info.plist`'i takip ediyordu; main'e geçiş yerel kopyaları sildi. Beklenen yol `MagicPaper/MagicPaper/Secrets.xcconfig` (git dışı). Kendin oluşturma, kullanıcıya sor.
- ~/.Trash okunamaz (TCC).

---

## faz9-closed-2026-10-03

_Faz 9 (temizlik) faz-9 dalında kapandı; bulut metin yolu ve sihirbaz silindi, görsel yol CloudIllustrationAccess bayrağında; test tabanları 350/0 ve 647/18; disk doluluğu tuzağı._

2026-10-03: Faz 9 `faz-9` dalında (design-system/magicpaper-redesign'dan açıldı) kapandı, birleştirilmedi.
- Metin masal yalnızca `OfflineStoryService`. `AIService`, Gemini sağlayıcısı, `createCustomStory`, `TextStory*`, eski sihirbaz (`StoryWizardView`) silindi. Görsel kod `StoryEngineBridge/CloudIllustrationPipeline.swift` + `CloudIllustrationAccess` (Release sabit false) arkasında.
- Taban: uygulama 350 test / 0 hata (1 atlanan); paket 647 / 18.
- Açık: ekran görüntüsü matrisi yarım (okuyucu X butonu kapanmıyor, gezinmeyi kilitliyor; Mac'te iPhone SE simülatörü yok); `DesignSystem/MPBridge.swift:8` eski Gemini yorumu.
- Çalışma sırasında başka bir oturum aynı çalışma ağacında `StoryEngine/` altında growth→learning (Faz 10) değişikliği yaptı, sonra kayboldu.

**Why:** Mac diski ~%99 dolu; yeni `-derivedDataPath` ile tam build ENOSPC verip Bash aracını kilitledi. Kullanıcı temiz-kopya build'ini (gizli dosya kopyalama) reddetti.
**How to apply:** Varsayılan DerivedData ile koş, yeni DerivedData açma; gizli dosyaları scratch'e kopyalama. Paralel oturum değişikliklerini commit'lere katma. Bkz. [[phase0-closed-2026-09-30]], [[illustrated-stories-not-live]].

---

## faz11-masal-ailem

_FAZ 11 (Masal ailem) main'de ve origin'de (260763d); pilot satırlar onaylı; temiz worktree doğrulama yöntemi ve simülatör notları_

2026-10-04: FAZ 11 ✅ main'e birleşti ve push'landı: origin/main = `260763d` (Merge faz-11). Pilot satırlar 12 düzeltmeyle onaylandı (aile açılışı çocuğun adıyla başlar; doğrulayıcı kuralı). Kararlar onaylı: "Yeni karakter" yalnız ebeveyn modunda; çocuk başına 8, masal başına 1; rakam/emoji reddi.
- Pilot aile satırları (36) commit `19f63c5`'te ayrı; gözden geçirme dosyası `MagicPaperAPP/FAZ11_AILE_SATIRLARI.md` (repo dışı).
- Yeni taban: paket 675/18 (hata listesi 658/18 tabanıyla test başına aynı), uygulama 404/0 (1 atlanan). `AvatarViewTests.testAnUnknownPoseDrawsStanding` soğuk ilk koşuda bir kez düştü, tekrarda geçti (kararsız, B2).
- Kullanıcı kararları: aile karakteri açılış+kapanışta; giriş profil sayfası (Benim köşem FAZ 17); hayvan türü sabit liste; "Yeni karakter" yalnızca ebeveyn modunda (benim koruyucu kararım, onaya sunuldu).

**Why:** Sonraki fazlar (12, 13) bu dalın merge edilmesini bekleyebilir; FAZ 13 öncesi orta aile anları içerik önceliği.
**How to apply:** Birleştirmeden önce kullanıcıya sor. Simülatör çok gecikmeli: dokunuştan sonra 4-5 sn bekle, ekran görüntüsünde `device` parametresini mutlaka ver. Uygulama verisi simülatörler arası `simctl get_app_container ... data` + rsync ile kopyalanabildi. Paket testi scratch-path ile ([[phase0-closed-2026-09-30]]). Character-system ajanı oturum limitine takılıp hiçbir şey bırakmadan durdu; büyük işleri ajansız yapmak daha güvenilir çıktı. İlgili: [[faz10-plan]].

2026-10-04: `fix/conjunction-harmony` dalı faz-11'den açıldı (commit 9cd7f76): 9 v3 satırında slot sonrası da/de yeniden yazıldı, `check_conjunctions` kapısı tüm satırlarda; 675/18. **6 Ekim: main'e cherry-pick ile alındı (9b28d1e, push'landı), dal silindi; paket 855/18, uygulama 417/0, doğrulayıcı 12.** Çalışma ağacında başka bir oturumun commit'lenmemiş uygulama dosyaları var — bunlara dokunma, yalnız kendi dosyalarını stage et.

**Ortak çalışma ağacı tuzağı (2026-10-04):** Başka oturumlar aynı klasörde dal değiştirebiliyor (`fix/conjunction-harmony`, kapak işi). Kendi değişikliklerini dal değiştirmeden commit'lemek için: yama al → `git worktree add <scratchpad>/wt <dal>` → uygula, commit → ortak ağaçta yalnız kendi dosyalarını (yama birebir aynıysa) geri al.

**Temiz worktree doğrulama (kullanıcı istedi, 2026-10-04):** `git worktree add <scratchpad>/wt <dal>`; git dışı `Secrets.xcconfig` ve `GoogleService-Info.plist` için yalnız sembolik bağ (kopya değil), iş bitince bağları sil; `-derivedDataPath <scratchpad>/dd` + `-clonedSourcePackagesDirPath` mevcut DerivedData/SourcePackages (≈1 GB ek, disk %98 dolu). Birleştirme de `main` worktree'sinde yapıldı; ortak klasöre dokunulmadı.

---

## shared-checkout-branch-switch

_Parallel Claude sessions share the MagicPaper checkout and switch branches mid-task; verify branch right before committing_

2026-10-04: While fixing the cover title on `fix/cover-title-dynamic-type`, another session checked out `fix/conjunction-harmony` in the same working tree; my commit landed there and had to be moved with a temp index + `commit-tree`. Simulator content size / appearance were also changed by other sessions mid-test.

**Why:** Several sessions work in `/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper` at once (see [[faz9-closed-2026-10-03]]).
**How to apply:** Run `git branch --show-current` immediately before every commit; prefer a worktree for isolated fixes (disk permitting — ~0.4 GB free on 2026-10-04). Re-check `simctl ui <dev> content_size` before each screenshot.

---

## faz12-ilgi-alanlari

_FAZ 12 (ilgi alanı sözlüğü) main'de ve origin'de (8481008); etiketleme onaylı; ilgi ekranları eşik 4 nedeniyle bugün gizli_

2026-10-06: FAZ 12 ✅ main'e birleşti ve push'landı: origin/main = `8481008`. Worktree ve faz-12 dalı 6 Ekim'de silindi.
- Kararlar (4-6 Ekim): etiketleme onaylı (`blueprint_charge_tending_age3_001` etiketsiz); en fazla 3, zorunlu değil; sunulan kelime < 4 ise ilgi ekranları gizli (`ChildInterests.minimumOfferedToShow`), seçimler ve puanlama durur. Bugün 2 kelime → ekranlar gizli.
- "Profili düzenle" hatası plan belgesinde "Küçük işler" listesinde.
- Taban: paket 854/18 (bu sayımla FAZ 11 main 832/18; docs'taki eski "675" farklı sayım), uygulama 417/0, doğrulayıcı 12 bulgu (main ile aynı).
- Kararlar: görünürlük = her içerikli bantta ulaşan kelime (global); cooldown herkese; en fazla 3 seçim, zorunlu değil.
- Bulgu: Mercan Denizi/Köpük/Deniz Kabuğu hiçbir blueprint'e bağlanmıyor. Bugün yalnız Hayvanlar ve Doğa görünüyor, etkisiz.
- `MPIconMap`: leaf→tractor, pawprint→bone; simge seçerken bak.

**Why:** Sonraki fazlar (13, 14) bu tabanı kullanır; ilgi ekranları içerik 4. kelimeyi ulaştırınca kendiliğinden açılır.
**How to apply:** Yeni kelime için içerik her iki bantta (3-4, 5-6) masala ulaşmalı. Simülatör 17e'deki "Yeliz" profiline test sırasında "animals" kaydedildi. İlgili: [[faz11-masal-ailem]], [[shared-checkout-branch-switch]].

---

## faz13-seri

_FAZ 13 (Seri) sürüyor — worktree ../MagicPaper-faz13 (dal faz-13), C1-C3 yarıda; kararlar ve kaldığı yer_

2026-10-06: Ön koşul kapandı: fix/conjunction-harmony main'e cherry-pick (9b28d1e, push'landı), dal silindi, ortak klasör main'de. Taban: paket 855/18, uygulama 417/0, doğrulayıcı 12.

FAZ 13 worktree: `/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper-faz13`, dal `faz-13`, henüz commit YOK (hepsi çalışma ağacında).

Batuhan'ın kararları (6 Ekim): "Devam ettir"e basmak = beğeni (favori şart değil); açık seri varken sakin satır; 4 bölüm anında üretilir; Masal ailem silinirse açılmış bölümler kalır, açılmamışlar family=nil ile yeniden üretilir (katalog izin vermezse seri sakince kapanır); saat kuralı sade: şimdi = max(duvar saati, en yüksek görülen), readDay okuma anındaki saat diliminde, ileri alma açığı kabul; revisit beat + {{keepsake.name}} + SeriesAnchor onaylı; FAZ 11 #11 bölüm sonunda yok; sakin son yasak listesi: ?, yarın, acaba, birden, sonra ne olacak ("ama" serbest); 3-4'te seri yalnız Uyku öncesi kabul.

Yapılanlar (C1-C2 motor, derleniyor; SeriesPlannerTests 22/22 geçti): `continuation` blueprint'leri `ContentCatalog.series` katmanında (kind alanı yerine ayrı liste — eski kitaplar değişmesin diye, rapora yazılacak sapma); seri satırları `templates/series/beat_series_*.json` (`series: true`) → `series.templates`; `CatalogObject.keepsakeName`; `CalmEnding`; `SeriesPlan/SeriesPlanner` (`Offline/Series/`); bölümlerde karışık hash'li seçici (`DeterministicPicker.mixedIndex`) + önceki bölümlerin satırlarından kaçınma; doğrulayıcıya `check_series_lines`.

Durum (6 Ekim akşam): FAZ 13 ✅ main+origin. 064273e (Merge faz-13) + 8ab294c (Merge faz-13-takip). faz-13 dalı ve worktree'si silindi; faz-13-takip worktree'si (../MagicPaper-faz13-takip) duruyor. Taban: uygulama 450/0, paket 878/18 (liste aynı), doğrulayıcı 12.
Takip kararları: bitmiş serinin ilk masalı devam ettirilmez; görülen en geç an cihaz saatini en fazla 2 gün geçer (SeriesClock.maximumLead); "Devam ettir" yalnız isFinished masalda (masal sonu yaprağında atEnd). Saat yanlışken yapılan okuma yeniden tarihlenmez (geri alma kuralıyla çelişirdi) — açık not.
Açık: ekran metinleri İrem'de (SeriesCopy); plan/yazım ana iş parçacığında; mod başına continuation içerik hattında. Paralel oturum: ../MagicPaper-faz14 (faz-14) var, dokunma.

**Why:** Oturum yarıda durduruldu; devam edecek.
**How to apply:** Devam ederken önce worktree'de `git status` ile durumu doğrula; ortak klasörde dal değiştirme. İlgili: [[faz12-ilgi-alanlari]], [[shared-checkout-branch-switch]].

---

## faz14-kullanim

_FAZ 14 (Kullanımdan öğrenme) main'de ve origin'de (e418173); 741/18 + 472/0; ekran kontrolü eksik; FAZ 16 devri_

2026-10-06: FAZ 14 ✅ main'e birleşti ve push'landı: origin/main = `e418173`. Paket 741/18 (liste aynı), uygulama 472/0, doğrulayıcı 12. Kararlar: anlatı ailesi; "Okuma bilgisini paylaş" varsayılan açık.
Eksik: yeni anahtar satırının en büyük Dynamic Type + Pro Max ekran kontrolü yapılmadı.
FAZ 16 devri (reviewer HIGH): gönderimden önce ebeveyn bildirimi; PRIVACY_POLICY.md:269 + html'ler + App Store etiketleri; storyID takma ad (gönder / döndür / çıkar kararı).
Temizlik (6 Ekim): faz-14 worktree ve dalı silindi; .git içindeki 4 iCloud " 2" kopyası (index, main, origin/main, faz-13-takip) Çöp'e taşındı, fetch düzeldi. iCloud .git içinde de kopya üretiyor; fetch bozulursa: find .git -name "* [0-9]*" -not -path "*/objects/*".
Secrets bağı worktree'de `MagicPaper/Secrets.xcconfig` → ana checkout'taki `MagicPaper/MagicPaper/Secrets.xcconfig`.
**Why:** Sonraki fazlar (16) bu devirleri taşır. **How to apply:** FAZ 16'ya başlarken devir listesini oku. İlgili: [[faz13-seri]].
- 2026-10-16: açık kalem kapandı, main 7f695e7 (push yok): ilk üçte birde kapatılan masal yarıda bırakma sayılmıyor (`StoryUsageStore.leavingThreshold`). Uygulama 699/0.

---

## faz15-uzaktan-icerik

_FAZ 15 (Uzaktan içerik) main+origin c5a813c; 912/18 + 514/0 + yayın aracı 10/0; Batuhan'ın anahtar/deploy adımları bekliyor_

2026-10-06: FAZ 15 ✅ `faz-15` dalında, worktree `../MagicPaper-faz15`, son commit `8903ce9`. Kullanıcı onayıyla main'e birleşti ve push'landı: origin/main = `c5a813c` (Merge faz-15). faz-15 dalı ve worktree duruyor (silinebilir).
Taban: paket 912/18 (main 898/18, hata listesi aynı), uygulama 514/0, ContentPublisher 10/0, doğrulayıcı 12 (artık `Content/validator_baseline.txt`).
Kararlar: Ed25519 imza, Firebase Hosting (magicpaper-393a7.web.app/content/), paket = tam kaynak seti, günün masalı tarihli + belirleyici.
Bekleyen (Batuhan): `content-publisher keygen`, açık anahtarı Info.plist `MPContentSigningKey`'e, `firebase login`, ilk `publish --first --deploy`, feed.json commit. Anahtar boşken uzaktan içerik kapalı.
Tuzaklar: sandbox içinde `python -m http.server` dinleyemiyor (getfqdn takılıyor) → kendi ThreadingTCPServer betiği + sandbox dışı. BGTaskScheduler simülatörde yok. Bu worktree'nin DerivedData'sı `MagicPaper-annjcz...`; paketler `-clonedSourcePackagesDirPath ~/Library/Developer/Xcode/DerivedData/MagicPaper-cyfdck.../SourcePackages`.
Simülatör 17 Pro'nun kütüphanesinde test masalı "Batuhan ve Kestane" (catalogVersion 2.0.1) kaldı.

**Why:** Batuhan'ın yayın adımları sonraki oturumlara kaldı. **How to apply:** kapanış notu ve devir `docs/MagicPaper_Faz_Plani_Ekim.md` FAZ 15'te. FAZ 16'ya gizlilik metni devri var. İlgili: [[faz14-kullanim]].

---

## faz16-hesap-senkron

_FAZ 16 (Hesap, KVKK onayı, Firestore senkron) main'de b92e701, push edilmedi; 545/0 + kurallar 18/18; Firebase kurulumu Batuhan'da_

2026-10-06: FAZ 16 ✅ `faz-16` (91c99ec) main'e birleşti: main = `b92e701` (Merge faz-16). **origin'e push edilmedi** (kullanıcı yalnız birleştir+commit dedi; main origin'den 3+ commit önde). Worktree `../MagicPaper-faz16` duruyor.
Taban: uygulama 545/0 (1 atlanan), kural testi `firebase/` içinde `npm test` 18/18 (Java gerekir; JDK scratchpad'deydi, kalıcı değil).
Kararlar: giriş herkese zorunlu; storyID gönderilmez; onaydan önceki olaylar silinir. Belge: `docs/ACCOUNT_SYNC.md`.
Batuhan'da bekleyen: Firestore oluştur (bölge = KVKK m.9), kuralları deploy, Apple/Google sağlayıcı; **GoogleService-Info.plist BUNDLE_ID `com.magicpaper.kids` ama uygulama `com.batu.magicpaper.v1`** — Firebase iOS uygulaması yeniden kaydedilmeli; plist'te CLIENT_ID yok (Google düğmesi gizli).
Tuzaklar: disk %99 (DerivedData annjcz'in SourcePackages'ını sildim, scratch spm kullanıldı); ikinci simülatör süreç sınırı yüzünden açılmadı; emülatörde test için `-MPFirebaseEmulator 127.0.0.1 -MPEmulatorAccount <ad>`, emülatör `--project magicpaper-393a7`; simülatör keychain'i Firebase oturumunu yeniden kurulumda tutar (`simctl keychain reset`).
**Why:** FAZ 17 bunun üstüne kurulur; Firebase kurulumu olmadan hesap canlıda çalışmaz. **How to apply:** canlı denemeden önce Batuhan listesini sor. İlgili: [[faz14-kullanim]], [[faz15-uzaktan-icerik]].

---

## faz17-mvp

_FAZ 17 main+origin edb2a30 (b271a63); yalnız VoiceOver açık (Batuhan)_

2026-10-07: FAZ 17 planı onaylandı (plan: `~/.claude/plans/magicpaper-docs-magicpaper-faz-plani-eki-functional-sprout.md`, bloklar A-G).

**Paralel oturum:** `MagicPaper-faz16` worktree'si `faz-17-pastel` dalında İrem'in tasarım teslim paketini (`design-handoff/`, 45 ekran PNG, NAVIGATION.md, SCREENS.md) uyguluyor; Home/Settings/Library/Daily/StoryEnding/Parent* dosyalarında commit'lenmemiş değişiklik vardı. Kullanıcı kararı: önce motor (Blok B) ayrı worktree'de; arayüz blokları (A, C, D, E, F) pastel oturumu bitince onun dalı üstüne, teslim paketindeki ekranlara göre.

**Kararlar (Batuhan, 7 Ekim):** ebeveyn Özet · Güvenlik · Ayarlar; Onaylar Özet'in içinde kalır (tasarım paketi ayrı sekme diyor, reddedildi); Çocuklar bölümü Ayarlar'ın en üstüne; korku 2 kademe Sakin (varsayılan) / Biraz heyecan; rozetler `badges` koleksiyonuyla senkron; kelime/konu etiketlerini ajan taslaklar, Batuhan onaylar.

**Blok B bitti:** worktree `../MagicPaper-faz17`, dal `faz-17-motor`, commit `00786fe`. Paket 936/18 (liste taban 912/18 ile aynı), doğrulayıcı 12. `ContentSafety` (nil = süzgeç yok, tohuma girmez), `CatalogGlossaryEntry`, `ComposedPage.words`, `SeriesPlan.safety`. İçerik taslağı onaylandı (Korkmak konusu kalıyor) ve `bc260a9`'da işlendi: 5 konu, 13 etiket, 28 kelime, 76 kelime etiketi; paket 937/18, doğrulayıcı 12; varsayılan ayarda hiçbir mod gizlenmiyor.

**7 Ekim, sonraki karar (Batuhan):** arayüz blokları (A, C, D, E, F) `faz-17-pastel` oturumunda yapılıyor; `faz-17-motor` o dala birleştirildi. Ayrı bir oturum bu bloklara başlamamalı. Pastel dalının durumu: [[faz17-pastel]].

**Why:** arayüz işi paylaşılan dosyalarda çakışırdı. **How to apply:** UI bloklarına başlamadan `faz-17-pastel` durumunu kontrol et; Blok C motoru kullanır (`availableModes(..., safety:)`, intent `safety:`). İlgili: [[faz16-hesap-senkron]], [[shared-checkout-branch-switch]].

2026-10-08 durum: esas dal `faz-17-pastel` @ 8841e44 (tasarım oturumu "MagicPaper design system implementation"); benim ekran dışı mantığım ce58b84 oraya alındı; kapanış notu d4afb6f (`faz-17-kapanis`, tasarım oturumu alacak). FAZ 17 🔧: kapsam bitti; kabulün ekran kısmı açık (AX5 taşmaları, pastel bileşenlerinde tasarım yasası isabetleri, eyebrow Türkçe büyük harf hatası, VoiceOver cihazda yapılmadı). Uygulama 586/0, paket 937/18, kurallar 19/19. KVKK onay sürümü 2026-10-07 (yeniden onay; hukuki onay bekliyor).
Tuzaklar: worktree'de iCloud " 2" kopya dosyaları derlemeyi bozar; disk iki kez doldu — tek DerivedData, iş bitince sil; paket indirme (firebase/protobuf) saatler sürebilir, `-disableAutomaticPackageResolution` + kopyalanmış SourcePackages. Tasarım oturumuyla iş bölümü: ekranlar onda, ben ekran dosyalarına dokunmam.

2026-10-08 (03:45): tasarım oturumu AX5 + Türkçe büyük harf + tasarım yasası düzeltti (fe4a2ff, a35b314; 586/0). Kapanış notu güncel: 07579de (`faz-17-kapanis-2`, a35b314 üstünde). Tasarım yasası ✅; AX5 iki bölünme açık (rozet ızgarası, "Biraz heyecan"); VoiceOver Batuhan'ın iPhone 16'sında. "Denız" bug değil (veride U+0131).

2026-10-08: AX5 son iki bölünme 204dffa'te düzeldi; not b271a63'te AX5 ✅. FAZ 17'nin son commit'i b271a63 (faz-17-pastel); sonrası FAZ 18-19. Açık tek kalem: VoiceOver (Batuhan, iPhone 16). main'e birleştirme/push yok, Batuhan'ın kararı.

2026-10-08: FAZ 17 (b271a63) main'e birleşti ve push'landı: main = origin/main = edb2a30. Push, FAZ 16'nın bekleyen commit'lerini de (b92e701 vb.) origin'e götürdü. Birleştirmeden önce testler yeniden koşulamadı (disk %99, 197 MB); son ölçüm a35b314'te 586/0, 204dffa yalnız düzen. Açık: VoiceOver (Batuhan). Tasarım oturumu faz-17-pastel'de FAZ 18-19'a devam ediyor.

---

## faz17-pastel

_İrem'in Pastel Masal teslimi faz-17-pastel dalında (worktree MagicPaper-faz16); FAZ 17 arayüz blokları da burada; kararlar ve kaldığı yer_

2026-10-07: İrem'in Claude Design teslimi (`design-handoff/`, 45 ekran) `faz-17-pastel` dalında uygulanıyor. Worktree `MagicPaper-faz16` (birleşmiş FAZ 16 worktree'si, DerivedData'sı ısınmış diye yeniden kullanıldı). Plan: `~/.claude/plans/ux-tasar-mc-s-i-rem-claude-jolly-parrot.md`.

**Kararlar (Batuhan):** görünüm İrem'den, motor çevrimdışı (LLM/yıldız/onay kuyruğu/serbest metin yok); Yarat 1 = mod kartları, Yarat 2 = kimler; yalnızca Nunito; yalnızca açık tema; FAZ 18 ekranları `FamilyFeatureAccess` bayrağında; FAZ 17 arayüz blokları (güvenlik, kelime, rozet defteri+senkron, ses/uyku, durum) bu dalda, `faz-17-motor` buraya birleşti.

**Yapı:** Pastel bileşenler `DesignSystem/Pastel/`; eski çakışan tipler `Legacy*`; `MP.C/F/ReadTheme` köprüyle yeni asset renklerine yönlü. DEBUG başlatma kancası `-mpDemo YES -mpStartParent YES -mpParentTab settings -mpStartTab library` (giriş ekranını geçer).

**Tuzaklar:** 4+ açık simülatör kullanıcı süreç sınırını (1333) doldurup Bash'i kilitliyor; simülatör dokunuşları 4-5 sn gecikmeli.

**How to apply:** commit öncesi `git branch --show-current`; ilerleme commit mesajlarında. İlgili: [[faz17-mvp]], [[shared-checkout-branch-switch]].

2026-10-08: FAZ 18-19 başladı, faz-17-pastel @ dee81aa (main = edb2a30'un üstünde, push yok): 35 Masal kitabı (StoryBookPlan + 5 test) ve 27 iPad yatay açık kitap (StoryPageView.spread). 591/0. Açık kararlar Batuhan'da: 33 Kendi sesin (onay metni "ses kaydı yapılmaz" diyor → yeni sürüm + hukuk), 34/36 ve haftalık e-posta backend ister (Storage/Hosting/Functions), widget/Live Activity yeni hedef + App Group ister. Paket indirme tuzağı: protobuf/abseil alt modülleri scratchpad/mirrors'tan GIT_CONFIG insteadOf ile (scratchpad/devbuild.sh).

---

## book-intelligence-agent

_Children's Book Intelligence research tool (MVP built 2026-10-08) — where it lives, what was approved, what is not committed yet_

Children's Book Intelligence: committed 2026-10-13 as 3d55ee8 on branch `book-intelligence` in worktree `MagicPaperAPP/MagicPaper-research` (based on main 9884c9f; pushed to origin 2026-10-13 by the user, not merged; auto-mode blocks Claude from git push). Files were MOVED out of the main checkout; everything research-related lives in that worktree.
Paths: `Research/BookIntelligence/` (Python 3 stdlib CLI `book_agent.py`) + `docs/research/`
(architecture, BOOK_RESEARCH_AGENT.md, RESEARCH_METHOD.md); agent def `MagicPaperAPP/.claude/agents/book-research.md` (outside git).
User approved all proposal decisions D1-D10 as recommended (Python, Claude-session analyst, no texts in git, 5-6 pilot).

**Why:** research must feed the content line (Batuhan) through human review, never the engine directly.
**How to apply:**
- Gutendex is off-limits (robots.txt disallows /books/); use Gutenberg catalog feed + RDF + cache/epub text.
- 2026-10-08 sources added after terms review (docs/research/SOURCES.md): Internet Archive (≤ current year−96, no lending collections) and Book Dash (CC BY 4.0, page images + analyst transcription). African Storybook / StoryWeaver: manual only — their readers need app mechanics / terms say personal use; don't reverse-engineer. 84 tests.
- Python here is python.org 3.10 without CA bundle; the client falls back to /etc/ssl/cert.pem — never disable verification.
- Pilot done 2026-10-08 (run r_20261008_070359): 5 Book Dash books analysed page by page from images; 9 claims, all LOW/HYPOTHESIS. Report: docs/research/reports/. 4 IA classics ingested, not analysed.
- User decision 2026-10-08: contemporary books first; pre-1930 classics differ too much from today's — keep them only as a separate comparison population.
- IA trap: an IA 'scan' may be a user-made ebook (HTML5 Uploader, no scanningcenter) — treated as reconstructed unless `--confirm-scan`. IA data nodes are *.archive.org.
- Book Dash: last square image is a closing vignette → [skip]; one publisher/one country bias must be stated in every finding.
- Notable single-book signal from smoke test: Peter Rabbit ~980 words, longest sentence 41 vs MagicPaper 144-304 words / 14-word cap; and engine forbids fear (intensity 3) at 5-6 — a likely first research question. One book only.
Related: [[faz17-mvp]], [[shared-checkout-branch-switch]]
- 2026-10-08 learning loop: user wants research → agents debate → engine improves. Decision: ONE human gate (anything reaching children). Built `exchange` (docs/research/EXCHANGE_PROTOCOL.md); first round done with real story-engine/content-library/privacy-safety agents; 9 proposals ready for the user's decision in docs/research/EXCHANGE_DIGEST.md. Next loop parts: experiment arms (need FAZ 16 aggregate), usage→child_response evidence, heuristic calibration, weekly run. Lesson: research must state numbers on engine scales (emotion 0-3, per-band page counts).
- 2026-10-13 loop closed (committed in 3d55ee8): experiments (x_*, prediction before data, preflight needs owner approval), firebase/functions/src/outcomes.js + aggregateOutcomes in index.js (NOT deployed — Batuhan), `ba usage import` with privacy floor (≥50 readings, ≥7 days per cell), `ba cycle`, calibration. Scheduled task `magicpaper-learning-loop` Mondays 10:10. No engine code changed (arms = sibling blueprints in FAZ 15 packages).
- 2026-10-14 weekly run (r_20261014_132709): +Best Friends, +An Unexpected Adventure (wordless) → 7 analysed, all Book Dash; no confidence change. Owner said all 9 recommendations are sensible and asked for non-Book-Dash sources next time → scheduled task step 2 now requires ≥1 non-Book-Dash book/week (African Storybook/StoryWeaver manual route, else IA). Owner cannot read .md files: give reports as HTML opened in a browser (or plain text in chat). `exchange decide` was left for the owner to run (given as one command).
- 2026-10-14: user made the 9 decisions inside the weekly-run session (3 approved → work packages; that session also built UX targets + handoffs and started implementing packages on branches kitap-rehberi / refrain-deneyi). Self-improvement added (committed cfd900c on book-intelligence, after the run's own commit 227fcea; pushed to origin 2026-10-14 by the user): `bookintel/learning.py` — `request` (other agents ask book-research), `recheck` (blind re-read → per-field reliability; unreliable fields cap claims at LOW via `judgment_fields`), `method` (caught mistakes → rules enforced by validate; m001-m005 seeded). 131 tests. Weekly run session id local_8887dd2c… may still edit the same worktree — check `git status` before committing.
- 2026-10-14 later: UX targets + handoffs built and committed (book-intelligence@227fcea). The 3 approved packages are done on their own branches, none merged or pushed: `kitap-rehberi`@e6e6bc5 (worktree MagicPaper-rehber, Content Library §14) and `refrain-deneyi`@104b3c3 (worktree MagicPaper-refrain: RefrainSpec + 2 sibling blueprints in Content/Experiments, NOT loaded by the app). Engine baseline is 788 tests with 18 failures, the same 18 on main. Before refrain can be published: the publisher must read Content/Experiments, then a ContentPackage schema bump, preflight, mark live. TRAP: another session works in the MagicPaper-research worktree at the same time (learning.py, request/recheck/method). Never `git add` whole folders there; stage only your own hunks.
- 2026-10-14: weekly book target raised to 10 (owner), ≥3 non-Book Dash, split across book-research subagents (2 books each, ≤4 parallel); runs.log now flock-locked (uncommitted).
- 2026-10-15 run: 9 books (6 Book Dash, 3 ASB/StoryWeaver), corpus 16 complete; 4 claims LOW→MEDIUM; new p_bedtime_closes_circle awaits decision; committed ecf41b5 (book-intelligence, pushed by user 2026-10-15); changelog on main 2eb0230 (pushed by user).
- 2026-10-16: p_bedtime_closes_circle DECIDED 2026-10-15 = parked (read ≥4 new bedtime books, then return as an experiment variant of bp_charge_tending_001; privacy-safety's 5 conditions hold). decision.json + thread/claim edits + data/requests/ are UNCOMMITTED in MagicPaper-research (not by this session).
- 2026-10-16: refrain-deneyi main ile güncellendi (19d7f51, kayıt dd44465): motor 790/18 (aynı 10 test), publisher 15/0, uygulama 699/0. main'e alınmadı, Batuhan onayı bekliyor. Paket testleri için --scratch-path şart (iCloud codesign detritus).
- 2026-10-16: refrain-deneyi main'e ileri sarıldı (dd44465 + günlük kaydı), push yok. kitap-rehberi hâlâ dalda.
- 2026-10-16: kitap-rehberi main ile güncellendi + §14 gönderme düzeltmesi (7ae7b30), main'e ileri sarılabilir, onay bekliyor.
- 2026-10-16: kitap-rehberi main'e ileri sarıldı (7ae7b30 + günlük), push yok. Onaylanan 3 paketin ikisi main'de; book-intelligence dalı hâlâ ayrı.
- 2026-10-20: Monday run (19 Oct) hung on first command (stuck session local_0c038a39, stop denied by classifier); ran the loop manually in-session: 8 books (6 BD via 3 subagents, 2 StoryWeaver). StoryWeaver now demands sign-up after 3 books → browser route capped (no accounts). Recheck Catch That Cat: beat 58%, only_in_image 54% over 24 pages → unreliable. m007 added. Uncommitted in worktree; changelog entry written in main checkout (which was on branch fix/alt-secenek-testi), uncommitted. ingest file has no --text-origin flag (docs say it does) — set text_origin by editing edition JSON.
- 2026-10-20 committed: research 3ef564f on book-intelligence (pushed by user 2026-10-20); changelog 3eaf7fe on main via a temporary worktree because the shared checkout was on another session's branch (fix/alt-secenek-testi) — main pushed by user 2026-10-20 (549d851..3eaf7fe).
- 2026-10-21 gaps closed: settings.local.json allow rules (ba, unittest, git status/diff/log, node export script); Thursday task magicpaper-research-questions (answers requests, no new books). Two-way channel used: reader 2, parent-ux 2, story-engine 1 question, all answered. First UX proposal p_bedtime_quiet_last_page → adopt_guidance, awaits owner decision. aggregateOutcomes NOT in main (only on book-intelligence) → merge first; export script firebase/functions/scripts/export-outcomes.mjs + guide docs/research/COCUK_VERISI_ACILIS.md. Commits: research 5f30954 (pushed by user 2026-10-21), main changelog 4a47ed0 was dropped by another session's reset; reapplied as 42a66d8 (pushed by user 2026-10-21). No gh CLI on this Mac; another session prepared PR body (main a2806ae).
- 2026-10-21: owner approved p_bedtime_quiet_last_page → handoff to reader waiting; decision files uncommitted.
- 2026-10-21: book-intelligence (5f30954) Batuhan'ın isteğiyle main'e birleşti (09c3dd2, günlük 5263241), aynı gün origin'e push edildi. Çakışma yoktu. Firebase 16/16; Python test_exchange CLAUDE.md'yi dış MagicPaperAPP/ klasöründen bulduğu için repo dışı geçici worktree'de 1 hata veriyor (ortama bağlı, birleştirmeden değil). aggregateOutcomes deploy edilmedi.

---

## faz18-aile

_FAZ 18 (Aile özellikleri) main'de 43f513a (push yok); 631/0, kurallar 51/51, fonksiyonlar 9/9; Firebase adımları ve proje kimliği uyuşmazlığı Batuhan'da_

2026-10-08: FAZ 18 kodu tamam (🔧, yayın Firebase adımlarına bağlı). Worktree `../MagicPaper-faz18`, dal `faz-18` (faz-17-pastel b271a63'ten, sonra c53c0db birleştirildi). main'e birleştirilmedi, push yok. Belge: `docs/FAMILY_FEATURES.md`.

**Kararlar (Batuhan):** beşi birden; haftalık özet giriş hesabının e-postasına (Apple `.email` kapsamı); Resend; tasarım geçerli (sesli paylaşım, Basılı kitap "yakında"); faz-17-pastel'de paralel yazılan 33/35 (dee81aa, b455829) yerine faz-18 sürümleri. Ana klasörün DerivedData'sını silmeye izin verdi (disk).

**Mimari:** familyID = kurucunun uid'i, tek yönetici; members/memberships/invites; reader rolü pull-only; ayrı ses rızası voiceConsents/{uid}; Storage families/{fid}/voice; paylaşım shares/{token} açık belge; functions/ weeklySummary+unsubscribe+cleanupShares.

**Tuzaklar:** plist PROJECT_ID `magicpaper-393a7-f2d31` ama .firebaserc `magicpaper-393a7` (emülatörde veri f2d31 altında); FamilyFeatureAccess artık `bool(forKey:)` (launch arg `-mp_dev_family_x YES` çalışır); DEBUG `-mpParentRoute bookExport|familyMembers|voiceRecording|shareLink`; kural testleri `npm test` (JDK scratchpad'deydi, kalıcı değil); `firebase/node_modules` faz16 worktree'sine sembolik bağ; testler `-clonedSourcePackagesDirPath` ile faz16 SourcePackages'ı kullanır (yoksa protobuf alt modülü dakikalarca iner); iPhone 17 Pro Max açılmadı (süreç sınırı).

**Why:** başka oturum faz-17-pastel'e FAZ 18 işi yazdı; çakışma yeniden olabilir. **How to apply:** faz-17-pastel'e yeni FAZ 18 commit'i var mı kontrol et; birleştirmeden önce Batuhan'a sor. İlgili: [[faz17-pastel]], [[faz16-hesap-senkron]], [[shared-checkout-branch-switch]].

2026-10-13: main'e birleşti (43f513a, --no-ff, origin'e push edilmedi). Ana klasörde Batuhan'ın commit'lenmemiş `.firebaserc` değişikliği projeyi `magicpaper-393a7-f2d31` yapıyor; web okuyucunun PROJECT sabiti (`magicpaper-393a7`) buna göre düzeltilmeli.

---

## cocuk-alani-tasarim-karari

_13 Ekim 2026 kararı — çocuk alanı ekranları tasarımdaki gibi; yıldız sistemi, kilitli rozetler, Masal ailem çoklu seçim geri geliyor (CLAUDE.md ilke 7 ve 7 Ekim kararını geçersiz kılar)_

Batuhan, 13 Ekim 2026: "tasarımdaki gibi olacak, rozet sistemi var, yıldız sistemi de var." Bu hafta kendisi çocuk alanının 8 ekranında çalışıyor: Ana sayfa, Benim köşem, Kahraman oluşturucu, Masal ailem, Yeni kelimelerim, Kitaplık, Masal aksiyonları, Seri masal. Kaynak: `design-handoff/screens` 11–18 ve `docs/SCREENS.md`.

Bu kararla tasarım şu konularda 7 Ekim kararlarının önüne geçiyor:
- Yıldız sayacı: Ana sayfa başlığı ve Benim köşem, "Her sabah 1 yıldız gelir. Her masal 1 yıldız."
- Rozetler "3 / 6" sayacıyla, kilitli rozetler de görünüyor.
- Masal ailem'de çoklu seçim ("2 karakter seçili"). Motor bugün masal başına tek aile karakteri taşıyor; bu motor/içerik işi.

Netleşen kurallar (13 Ekim): Masal ailem en çok 2 karakter. Yıldız harcanıp harcanmayacağı, abonelik bağı ve üst sınır "sonraki planlarda". Bu hafta yıldız yalnızca kazanılır ve gösterilir (sabah +1, biten masal +1). Yıldız bitti (45) yok, Yarat kilitlenmez. Defter, ileride harcama eklenebilecek biçimde tutulur.

**Why:** Ürün sahibinin bilinçli tercihi. CLAUDE.md ilke 7 (puan/ödül ekonomisi yok) ve FAZ 17 "yıldız yok, kilitli rozet gösterilmez" kararı bununla çelişiyor; dokümanlar güncellenmezse reviewer/ajanlar bu işi geri alır.

**How to apply:** Bu ekranlarda tasarımı uygula; yıldız ekonomisinin kuralları (harcama, Yıldız bitti 45, plan ilişkisi) netleşmeden yıldız harcamasını kodlama. CLAUDE.md ilke 7 ve `MagicPaper_Faz_Plani_Ekim.md` güncellenmeli. faz-19 worktree'si HomeView/ContentView/MPAppState'e dokunuyor, bkz. [[shared-checkout-branch-switch]], [[faz17-mvp]].

---

## faz19-ios-yuzeyleri

_FAZ 19 (widget, uyku modu Live Activity, Siri) faz-19 dalında 20b79f3, worktree MagicPaper-faz19; 652/0; main'e birleşmedi_

2026-10-13: FAZ 19 kodu `faz-19` dalında 20b79f3 (worktree `../MagicPaper-faz19`, main 9884c9f'ten). Birleştirme/push yok. Kalan cihaz testlerini Batuhan yapacak.

**Kararlar:** Live Activity = Uyku modu (Batuhan). Haftalık widget hedefsiz ("3/4", "1 kaldı" yok). Kilit ekranı/Live Activity'de masal adı yok.

**Açık:** Live Activity'de ay simgesi (MPIcon "moon.fill" → SF Symbol) görünmüyor; App Group + `.widgets` bundle kaydı portalda; Siri Türkçe ifadeleri cihazda denenmedi; uzantı sürümü app Info.plist'teki sabit 1.0 (1).

**Tuzaklar:** proje dosyası elle düzenlendi (F19… kimlikleri); DesignSystem dosyaları uzantıya `PBXFileSystemSynchronizedBuildFileExceptionSet` ile giriyor. `xcodebuild -list` paket çözmeye kalkıp takılır; derleme için scratchpad'deki `xb.sh` kalıbı (`-clonedSourcePackagesDirPath` faz16 DerivedData'sı + `-disableAutomaticPackageResolution`). Simülatörde metin yapıştırma widget aramasına gitmiyor; listeyi kaydır. DerivedData `MagicPaper-faz19` ~disk.

İlgili: [[faz18-aile]], [[shared-checkout-branch-switch]].

2026-10-13: main'e birleşti (7a9bca7, --no-ff, push yok). Ana klasördeki Batuhan'ın commit'lenmemiş pbxproj değişikliği yalnızca Xcode sıralaması + 5 dosya adında tırnak kaldırmaydı; tırnak düzeltmesi commit'lenmemiş olarak yeniden uygulandı, yama yedeği scratchpad'de. Xcode açıkken Package.resolved bir an silindi, git'ten geri alındı.
2026-10-13: origin'e push edildi (edb2a30..7a9bca7, 14 commit; FAZ 18 ve 9884c9f de gitti).

---

## kosem-sekme

_Benim köşem alt bar sekmesi — kosem-sekme dalı 30ef55c (main'e birleşmedi); yıldız ve HomeView adımı anasayfa-yenileme birleşmesini bekliyor_

2026-10-13: `kosem-sekme` dalı (worktree `MagicPaper-kosem`, main 7a9bca7'den), commit `30ef55c`. Uygulama testleri 660/0 (1 atlanan).
Kararlar (Batuhan): bar Ana sayfa · Kitaplık · Yarat · Köşem; 8 onaylı rozet + kilitliler, "n / 8"; yıldız `MPStars` ile, anasayfa dalı birleşince.

Kalan iş:
- `anasayfa-yenileme` main'e birleşince: kosem-sekme'yi main'le güncelle; KidCornerView'e yıldız kutucuğu (`MPStars.count(for:stories:)`, ilk sırada) + "Her sabah 1 yıldız gelir. Her masal 1 yıldız."; HomeView avatar/şerit → `app.openKidCorner()`; `MPAppState.showKidCorner` köprüsünü sil.
- anasayfa oturumu `FamilyCharactersView`'i de düzenliyor; benim değişikliğim orada tek satır (`app.showKidCorner = false` silindi), birleşirken kontrol et.
- 13 Ekim: ab6f02c main'de ve origin'de (başka oturum cf9e656 ile push'ladı). Yıldız kutucuğu `04a9e28` (kosem-sekme, cf9e656 üstünde, 663/0); Batuhan origin/main'e push'ladı (cf9e656..04a9e28). MPStars/StarCountTests anasayfa dalından birebir. Kalan: HomeView → openKidCorner + showKidCorner köprüsünü silmek (anasayfa birleşince).

**How to apply:** worktree'de `Secrets.xcconfig` ×2 ve `GoogleService-Info.plist` sembolik bağ; iş bitince bağları ve scratchpad `dd` (~1.8 GB) sil. Disk 13 Ekim akşamı ~3.5 GB boştu. Simülatörü başka oturum kullanabiliyor; kendi cihazını (17 Pro Max F0081ED1) boot et. İlgili: [[cocuk-alani-tasarim-karari]], [[shared-checkout-branch-switch]].

---

## degisiklik-gunlugu-kurali

_Biten her iş, küçüğü de, DEMO_CHANGELOG.md Değişiklik günlüğüne hemen yazılır; başka oturumun değişikliği varken bile ertelenmez (13 ve 14 Ekim 2026)_

Tamamlanan her iş, ister uygulama kodu, ister canvas, içerik, belge, birleştirme ya da gönderim olsun, `MagicPaper/design-handoff/reference/DEMO_CHANGELOG.md` dosyasındaki **Değişiklik günlüğü** bölümüne en üste kayıt olarak eklenir. Kimse istemese de eklenir. Kural kökteki `CLAUDE.md`'de, "Değişiklik günlüğü" başlığı altında yazılı.

Kayıt biçimi:
- Başlık: `### YYYY-MM-DD · <dal@commit | canvas vNN> · <başlık>`.
- Maddeler: ne değişti, ne bilerek değişmedi, test sonucu, etkilenen dosyalar.

**Why:** Batuhan gelişimi bu dosyadan takip ediyor. 13 Ekim'de bunu kural yaptı, 14 Ekim'de "yapılan, biten tüm işler yazılacak" diye pekiştirdi. 14 Ekim'de FAZ 20 Günlük'ün kayıtları ertelendi, çünkü dosyada başka bir oturumun commit edilmemiş değişikliği vardı. Bu yüzden kural sertleşti.

**How to apply:**
- İşi bitti diye raporlamadan önce kaydı yaz.
- Dosya başka bir oturum yüzünden kirliyse ertelemeden çalış:
  1. Onların satırlarına dokunmadan kendi kaydını en üste ekle.
  2. Yalnızca kendi hunk'ını `git add -p` ile commit'le.
  3. Bu mümkün değilse kayıt metnini kullanıcıya ver ve bunu açıkça söyle.
- Test ya da cihaz doğrulaması yapılmadıysa kayıtta açıkça yaz.
- Eksik kalmış eski kayıtları fark edince geriye dönük ekle.
- Dosyanın claude.ai "Magic Paper" projesindeki kopyası (`claude/magicpaper-demo-CLAUDE.md`) buradan güncellenemiyor; senkronu Batuhan'a hatırlat.

İlgili: [[faz20-gunluk]].

---

## anasayfa-yenileme

_Ana sayfa yenilemesi main e4573b6 (15 Ekim, push yok); header altı Apple düzeni, vektör mod sahnecikleri, Günlük başlığı standart font kararı_

Dal `anasayfa-yenileme` (worktree `MagicPaper-anasayfa`), main+origin `d1b2a28` (13 Ekim 2026). Uygulama testleri 662/0 (birleşme öncesi), kosem-sekme birleşmesinden sonra ilgili testler 26/0.

Yapılan: ana sayfa (illüstrasyonlu başlık sahnesi `HomeScene`, yıldız/seri çipleri `HomeStatChips`, mor hero kartı, her bölüm tek kart `HomeSection`), `MPStars` (sabahlar + rozet defterindeki biten masallar, depo yok), Masal ailem aynı dille. Tasarım notu: `docs/superpowers/specs/2026-10-13-ana-sayfa-yenileme-design.md`.

Açık: `Assets.xcassets/Scenes` görselleri Figma AI ile üretilmiş **taslak**; kalıcı çizim illüstratörde. Masal ailem seçimi tek (motor tek aile karakteri taşıyor; karar "en çok 2" bekliyor). Gece saat çubuğu okunurluğu. Karakter düzenleyici eski görünümde. iPhone SE bakılmadı.

15 Ekim: main `e4573b6` (push yok), 698/0. Header (sahne + çipler + hero) Batuhan'ın onayıyla sabit; altı beyaz zeminde Apple düzeni: Yeni bir masal yaz (`HomeModeCard`, `Scenes/mode-*` SVG sahnecikler), Günlük rafı, Bu hafta (yıldız). Batuhan kararları: yıldız yolu header'a taşınmadı; "Günlük" başlığı el yazısı değil, öbür başlıklarla aynı (iki font kuralı istisnasız); yıldız imzası `MPStarMark`; yarıçap: yüzey card, çip input, iç kutu md; başlık-içerik 12, bölümler arası 32. Çok oturumlu birleştirmede sırayla birleştir, her seferinde main'i tekrar al.

16 Ekim: Benim köşem ana sayfa dilinde (beyaz, HomeSection, el sallayan Ragi + balon), denetim: Ekle kapıdan sonra profil eklemeye (`requestProfileAdd`/`gateDismissed`), Masal ailem ve kahraman düzenleme çocuk modunda kapılı (görmek serbest), ana sayfa çipleri Köşem'i açar. main+origin `1a4870b`. Tuzak: `git merge --ff-only ... | tail` zinciri hata vermez; push'u yalnızca ff başarılıysa yap. `git checkout -- dosya` başka commit'lenmemiş değişikliği de siler.

**Why/How to apply:** Başka oturumlar (kosem-sekme) aynı bundle ID'yle derlemelerini açık simülatörlere kuruyor; kendi derlemeni ayrı bir simülatöre kur ve ekran görüntüsünden önce yeniden kur. DerivedData'yı `cp -cR` ile klonlamak disk harcamadan ayrı önbellek verir. Bkz. [[cocuk-alani-tasarim-karari]], [[shared-checkout-branch-switch]].

---

## liquid-glass-tab-bar

_Çocuk alt çubuğu Liquid Glass — main+origin 1a14de7, 697/0_

Dal `liquid-glass-tab-bar`, worktree `MagicPaper-glass`, commit `3862324` (14 Ekim 2026), main `675bb72` (FAZ 20 dahil) üstüne. Uygulama testleri 692/0. DerivedData `MagicPaper-glass`, simülatör iPhone 17 Pro (CDD10510…).

Kararlar (13 Ekim, Batuhan): Yarat çubuğun içinde, yüzen kapsül, üst başlıklar sonraki tur, cam kuralı CLAUDE.md "Derinlik"te. Plandan sapma: Yarat düz marka renginde (cam üstüne cam yok).

Açık: iOS 17.6 yedek yolu, küçük ekran, VoiceOver simülatörde bakılmadı; `MPTabBar` ölü kod.

**Why:** Paylaşılan main checkout'u başka oturumlar kullanıyor; FAZ 20 başka oturumca main'e alındı.
**How to apply:** Birleştirmeden önce kullanıcıya sor; main'de yeni commit varsa önce dala birleştir. Bkz. [[shared-checkout-branch-switch]].

14 Ekim ikinci tur (122a1b8): safeAreaBar (`mpFloatingBar`), interactive cam, ton %25, pasif sekme textSecondary, MPModeSwitch ortak yüzeyde. Ardından main (1917fd6, Günlük) dala çakışmasız birleşti; Günlük kendi `GunlukLayout.bottomClearance` (142 pt) ile çubuğu aşıyor, sonunda ~50 pt boşluk kalıyor. Yalnızca iOS 27 runtime var, yedek yol görülemiyor.

14 Ekim üçüncü tur (ea34016) Batuhan kararları: çubukta hiç yazı yok (Yarat dahil), seçili hap yok; seçili ikon SF `.fill` + sekme rengi (brand/reward/play/calm) + tek bounce; ek görsel/resimli ikon istemiyor; çubuk aşağıda (göstergeden 16 pt). Lucide'nin dolu hâli olmadığı için sekme ikonları `MPIcon(symbolOnly:)`.

14 Ekim: main'e ileri sarıldı (6766c8b + günlük düzeltmesi 1a14de7), birleşik hâl 697/0. `git push origin main` otomatik mod sınıflandırıcısınca reddedildi; Batuhan kendisi gönderecek ya da izin verecek. `git fetch` 'did not send all necessary objects' hatası veriyor.

14 Ekim: Batuhan push'u kendisi yaptı, origin/main = 1a14de7.

15 Ekim (cf518bd + 912f6cd, main, push yok): Batuhan kararı — sekmede zıplama yok, yalnızca dolgu + renk. bounce/replace kaldırıldı, MPPressStyle(.highlight), MP.Glass.bar'dan .interactive() çıktı (MPModeSwitch de etkilenir). Derlenmedi, test edilmedi.

---

## faz20-gunluk

_FAZ 20 Günlük (ücretsiz klasikler) main+origin 19eead7; dal faz-20-gunluk, worktree MagicPaper-faz20; kararlar, açık işler ve tuzaklar_

FAZ 20 · Günlük (13-14 Ekim 2026), İrem'in canvas'ı https://claude.ai/artifact/LFvq9QMctoB2G7tGFcXRU6. main ve origin'de: son commit 19eead7 (changelog dahil). Dal `faz-20-gunluk`, worktree `MagicPaper-faz20`. Günlük testleri 35/0; tam takım son ölçüm 681/0.

**Kararlar (Batuhan):**
- Alt bar beş öğe: Ana sayfa · Günlük · Yarat · Kitaplık · Köşem.
- Günün masalı editörün seçtiği Rapunzel. `covers.json` içindeki `featured` alanından gelir; alan boşalırsa günlük sıraya döner.
- "En çok okunan" yerine "Bu haftanın seçkisi" denir, çünkü okuma verisi yok.
- Kapaklar kamu malı renkli plakalardan. Görsel üretimi (Figma AI, ücretli) onaylanmadı: 11 kapak `pendingCovers` listesinde, pastel yedek kapakla görünüyor.
- Vitrin 520 pt kalacak. Ekranın %45'ine indirilmiş hali beğenilmedi: "görseller olayı anlatmıyor".
- Vitrin sonsuz döngüde döner.

**Yapı:**
- Kaynak dosyalar `Content/Classics` altında: tales, series, covers.json, COVER_SOURCES.md.
- Kataloğu `Scripts/ClassicsCatalog/build_classics_catalog.py` kurar ve `MagicPaper/Screens/Gunluk/Model/classics_catalog.json` dosyasına yazar.
- Id'ler slug'dan uuid5 ile türetilir. Slug değişirse çocukların ilerlemesi sıfırlanır.

**Tuzaklar:**
- Xcode projesinde `Models/` ve `Services/` klasik gruplar: yeni dosya hedefe girmez. Yeni dosyalar `Screens/` altına konmalı, o klasör senkronize.
- Asset klasöründe `provides-namespace` true olursa adlar "Klasör/ad" olur.
- `NavigationStack`, kök görünümdeki alt bar `safeAreaInset`'ini almıyordu; iOS 26 Liquid Glass `safeAreaBar` ise alıyor. `GunlukLayout.bottomClearance` iOS 26'da `xxxl`, eskilerde bar + 56 (15 Ekim, 9edb7fb).
- Gizli gezinme çubuğu kenardan geri hareketini kapatır; `GunlukComponents.swift` içindeki `UINavigationController` uzantısı açıyor. Simülatörde kenar hareketi `swipe` x=2 ile tetikleniyor, `touch_path` x=8 ile tetiklenmiyor.
- 15 Ekim: denetim, vitrin altı yeni düzen (raf kapıları, simgeli bölümler) ve sayfa sonunda gece bölgesi (`GunlukNightZone`, manzara hep gece, renk `sceneSkyNight`). main e87ee09'da, origin'e gönderilmedi.
- Paylaşılan SourcePackages ile test çalıştırırken `-disableAutomaticPackageResolution` şart, yoksa swift-protobuf yeniden klonlanmaya çalışılıp hata veriyor.
- Ortak simülatörleri başka oturumlar ele geçiriyor. Bu iş için ayrı bir simülatör açıldı: "MP Günlük (Claude)" 4E56A91A-D35E-4C3A-B134-191517021B43.
- iCloud'un " 2" ekli kopyaları git'i bozuyor. `refs/remotes/origin/main 2` kopyası scratchpad'e taşındı. `.git/index 2` gibi kopyalar hâlâ duruyor.
- Telefon: iPhone 16, UDID 00008140-001E4C593CEB001C. Derleme `xcodebuild -allowProvisioningUpdates` ile, kurulum `devicectl` ile.

**Açık işler:**
- 11 kapak için kaynak bulunacak. Nasreddin Hoca ve Kelile ve Dimne için Osmanlı ve İran minyatürleri aday.
- Ana sayfadaki "Günün masalı" kartı henüz klasiklere bağlı değil.
- "Kahramanı ben" düğmesi motor desteği gelene kadar gizli.
- Liquid Glass alt bar dalı FAZ 20'nin 5 öğeli barı üstüne kurulacak. İlgili not: [[liquid-glass-tab-bar]].

İlgili: [[cocuk-alani-tasarim-karari]], [[anasayfa-yenileme]], [[kosem-sekme]], [[degisiklik-gunlugu-kurali]].

---

## uyku-modu-v2

_15 Ekim 2026 — uyku modu v2'ye ertelendi (MPFeatures.sleepMode=false), akşam üç mod serbest; main+origin ba2ad8b_

Karar (Batuhan, 15 Ekim 2026): uyku modu (kararan ekran, süre, Live Activity, Siri "Uyku modu") lansmanda yok, v2'de çıkar. Akşam yalnız uyku masalı değil; Uyku öncesi yalnızca öne çıkar. Akşam kartı "Uyku masalı oluştur" penceresini (`BedtimeStorySheet`) açar; pencere **yalnızca dokununca** açılır, kendiliğinden gelmez.

Durum: main+origin ba2ad8b (iş cf1ae56). Dal `uyku-v2`, worktree `MagicPaper-uyku`. Plan: `docs/UYKU_MODU_V2_PLANI.md` (v2 kalemleri orada).

Açık: iPhone SE / Pro Max, "Kaldığın yerden" satırı ve masal sonu "İyi geceler" simülatörde görülmedi. Sürprizin akşam Uyku öncesine ağırlık vermesi karar bekliyor.

**How to apply:** Worktree'de derlemek için gitignore'lu `MagicPaper/Secrets.xcconfig` ve `MagicPaper/GoogleService-Info.plist` ana checkout'tan kopyalanmalı. Simülatörde girişi atlamak için `xcrun simctl launch <cihaz> com.batu.magicpaper.v1 -mpDemo YES` (DEBUG). Kendi simülatörüm "MP Uyku (Claude)" 2089CDDC-E69C-4185-8D75-1C5174BE1C40. `ReadingEventTests.testDeleteProfileReachesTheLiveStores` profilsiz yeni simülatörde düşer. Bkz. [[shared-checkout-branch-switch]], [[degisiklik-gunlugu-kurali]].

---

## ragi-on-planda

_16 Ekim 2026 — Ragi her çocuk ekranında ön planda olmalı (Duolingo'daki Duo gibi); ekran başına tek Ragi, ebeveyn alanında yok_

Batuhan (16 Ekim 2026): "her ekranda Ragi'yi kullanmaya özen göster, Duolingo'daki Duo gibi Ragi ön planda olmalı."

**Why:** Marka kimliği maskotla taşınmalı; Ragi'nin geri planda kaldığı ya da hiç olmadığı çocuk ekranları markasız duruyor. 13 Ekim'deki "Ragi o kadar ön planda olmasın" yorumu ana sayfa varyasyonlarına özeldi; bu karar onun yerine geçer.

**How to apply:** Her çocuk ekranı yeniden tasarlanırken Ragi'ye görünür bir yer ver (karşılama, konuşma balonu, sahne). Yine geçerli olanlar: ekran başına en fazla bir Ragi, tek duygu, ebeveyn alanında Ragi yok (design-handoff/CLAUDE.md). İlgili: [[anasayfa-yenileme]], [[cocuk-alani-tasarim-karari]].

---

## masal-atolyesi

_Masal yazılıyor" ekranı masal defterine dönüştü; main+origin 05b8ce7 (kod 7bbb3ce); açık doğrulamalar var_

16 Ekim 2026: Nöropazarlama beyin fırtınasından ilk madde seçildi. Masal ~1,5 sn'de hazırlanıyor ve bu "ucuz" algısı yaratıyor. Çözüm: bekletmek değil, zanaati göstermek (labor illusion).

Plan: `MagicPaper/docs/MASAL_ATOLYESI_PLANI.md`, main b997fcb + changelog 9896d81.

Özet: `StoryPreparationView` bir masal defterine dönüşüyor. Adımlar: kadro → yaş → mod dokunuşu → gerçek ilk cümle mürekkeple → Ragi tekrar okuyor (isClean kapısı) → kapak + "Ela'nın 12. masalı". Süreler: ilk masal ~10 sn, 2.-3. masal ~8 sn, sonra ~5 sn; uykuda ×1,3; 2. masaldan sonra "Hemen aç". Mantık saf `StoryPreparationScript` + `PreparationFacts` içinde, `Story` modeli değişmiyor. Reduce Motion'da adımlar çapraz geçişle sürüyor (bugünkü "anında bitir" yasaya aykırı).

**Why:** Batuhan'ın limiti doldu (16 Ekim); "limitim yenilenince inşaya başlayacağız" dedi.

**How to apply:** Ekrana dokunan iş önce açık doğrulamaları (aşağıda) kapatmalı. Kalan beyin fırtınası maddeleri: ithaf sayfası + künye, "üretildi" → "yazıldı" dil temizliği, hazır bekleyen akşam zarfı, fiyat çapası + App Store anlatısı. Bkz. [[ragi-on-planda]], [[degisiklik-gunlugu-kurali]].

**16 Ekim, inşa edildi:** §9 kararlarının hepsi önerildiği gibi. Kod 7bbb3ce, günlük 05b8ce7, main+origin. Script testleri 15/0, tam takım 716/717 (AccountServiceTests.testAFailedSendKeepsTheEvents kararsız, tekrarda geçer). Defter çizgileri son anda kaldırıldı, sonrası derlenmedi. Açık: Reduce Motion, en büyük Dynamic Type, koyu tema, küçük ekran görülmedi.
Tuzaklar: `simctl io screenshot` panel bağlıyken eski kare dönebiliyor, simülatör aracının screenshot'ı doğru; geçişleri yakalamak için `simctl io recordVideo` + AVAssetImageGenerator betiği. Paketler için `-clonedSourcePackagesDirPath` ile `MagicPaper-drsefk...` SourcePackages + `-disableAutomaticPackageResolution` (cyfd klasöründe protobuf alt modülü eksik). Disk testler sırasında doldu.

**16 Ekim, ikinci tur (main+origin 599c7d6):** Batuhan süreleri uzattırdı: ilk ~15 sn, 2.-3. ~10 sn, sonra ~6 sn, uyku x1,2, mürekkep 2,8 sn. Defter her adımda dolar (başlık + No., kadro, yaş/mod notları, ilk cümle, "Ragi okudu" mührü), adım noktaları, Ragi nefesi. 17/0. 17 Pro'da ilk masal videoyla görüldü. Simülatörler silindi; kalan: iPhone 17 Pro CDD10510, Air C82DF855, 18 Pro Max 0C2B777B (başka oturumda olabilir).

**20 Ekim, "masal bir kitap" (main 6b2b1e6, push yok):** ithaf yaprağı (okuyucu + PDF), künye (son yaprak + PDF), kitaplık rafı (sırtlar), dil temizliği ("oluştur"→"yaz", "Hemen aç"→"Masalı aç"). Sıra numarası `StoryEngineBridge/StoryColophon.swift`'ten, createdAt ile. Dil kuralı + grep CLAUDE.md'de (repo dışı dosya). Tam takım 732/1 (StoryModeFlowTests alt kategori, başka iş). Tuzak: `Models/` senkronlu grup değil, yeni dosya oraya konursa derlenmez; senkronlu klasörler: DesignSystem, Screens, Helpers, StoryEngineBridge, Surfaces.
**20 Ekim gönderim:** main+origin 549d851 (ithaf, künye, dil; raf 18b6780 ile geri alındı, kitaplık UX'i başka oturumda).

**20 Ekim, akşam zarfı planı:** `MagicPaper/docs/AKSAM_ZARFI_PLANI.md`, main 909d162 (push yok, kod yok). Kararlar: akşam kartı zarfa döner, seri bölümü önce, açılmayan zarf sessizce kitaplığa. §9'da 5 onay bekliyor. Not: ana checkout başka oturumun dalında olabilir (fix/alt-secenek-testi); main'e scratchpad worktree ile commit'lendi.

**20 Ekim, akşam zarfı inşası başladı (kullanım limiti doldu):** dal `aksam-zarfi`, worktree `MagicPaper-zarf` (Secrets/GoogleService sembolik bağ), WIP 3bc022a DERLENMEZ: MPTonight.envelope(_, atBedtime:) + evening(of:) + EveningEnvelope saf kurallar + EveningEnvelopeTests. Kalan: WidgetCopy/HomeView/MPAppState switch'leri, Store + Writer (seri .ready önce, yoksa createStory mode .bedtime strategy nil seed), MPTonightSource/snapshot'a envelope, HomeHeroCard zarf durumu, EnvelopeOpeningView, MPStoryGate'e mühür süzgeci (LibraryView başka oturumda), MPReminder metni, test+simülatör+günlük.

---

## kitaplik-yenileme

_20-21 Ekim Kitaplık yenilemesi — main+origin 0e28f5b; kapak kararları, StoryCoverDefault silindi, ana sayfa kasma düzeltmeleri de aynı gönderimde_

Kitaplık Pastel dile geçti ve 21 Ekim'de main+origin'e gitti (0e28f5b); ana sayfa kasma düzeltmeleri (anasayfa-yenileme dalı: availableModes @State önbelleği, saat çubuğu şeridi kaldırıldı) aynı birleştirmeyle gitti.

Batuhan'ın kararları:
- Kitaplıkta Günlük'ten açılan klasikler de var; kategori ekseni mod rafları + Favoriler + Klasikler.
- Kapak: sırtlı/bantlı ortak çerçeve denendi ve REDDEDİLDİ. Klasik Günlük'teki boyalı kapağıyla, kendi masalı kâğıt mozaiğiyle; hepsi Günlük ölçüsünde (128×176), kartlar eş boy (başlığa 2 satır yer). `MPBookCover`/`MPBookCard`.
- "StoryCoverDefault" (her metin masalında aynı görsel) silindi; okuyucu da mozaik gösterir.
- Kaydırmada tek kare donma bile istemiyor; pahalı hesaplar görünüm gövdesinde olmaz.

Yapı: `Screens/Library/LibraryShelfModel.swift` (saf, testli), `LibraryComponents.swift`. DEBUG `-mpDemoLibrary YES` örnek kitaplık kurar.

**Why:** Batuhan tutarlılığı biçimden istiyor, resme dokunmadan; kapak fikirleri önce simülatör ekran görüntüsüyle onaylatılmalı.
**How to apply:** Kitaplık/kapak işinde bu kararları yeniden tartışma. Açık: telefonda Batuhan'ın gözünden geçmedi, iPhone SE ve VoiceOver bakılmadı; arkadaş adıyla arama yok. Alt seçenek testi (testASubOptionIsRemembered) main'den gelen hata, ayrı oturum düzeltiyor. Bkz. [[anasayfa-yenileme]], [[degisiklik-gunlugu-kurali]].

---

## uyku-arki

_Uyku arkı (21 Ekim 2026) — bedtime kendi arkında; dal uyku-arki 3dde158 (devam bölümleri dahil), main'e birleşti (ec732f5), origin b70dc4d_

21 Ekim 2026: Batuhan uyku öncesi modunun kendi yapısını onayladı ("oda ayarıyla başla"). Dal `uyku-arki`, worktree `MagicPaper-uyku-arki`. Commit'ler 39d3393 (kod) ve 86d1235 (günlük). Devam bölümleri 3dde158. Batuhan'ın onayıyla main'e birleşti (ec732f5) ve push edildi (b70dc4d); birleşik hâlde 819/18, yeni hata yok.

- Yapı: `NarrativeArc` (blueprint + şablon), mod aileyi ve arkı seçer, `isRestingPlace` odaları, `templates/bedtime/`, `familyMoments` listesine `establish_ordinary` eklendi. Ayrıntı: `docs/UYKU_ARKI.md`.
- Test tabanı: paket 819/18. Bu 18 hata main'de zaten düşen 10 testten geliyor. Python doğrulayıcının main'de 12 eski hatası var.
- 3dde158: uyku devam bölümleri yazıldı (bp_cont_bedtime_staying/settling, 5-6 + 3-4; satırlar templates/bedtime/beat_bedtime_series_*). Yeni nesne eklenmedi (standart tohumları kayardı); ince ses hatıra olduğundan seride 3 yeni nesne + 1 tekrar. Paket yine 819/18, py 12.
- Açık işler: simülatörde görsel kontrol, 7-10 bantları, odaya özel 4. yeni keşif nesnesi (tohum kaymasını göze alarak).

**Why:** Bir sonraki oturum birleştirmeyi ya da seri işini buradan sürdürecek.

**How to apply:** Birleştirmeden önce Batuhan'a sor. Worktree'de uygulamayı derlemek için `Secrets.xcconfig` dosyası `MagicPaper/Secrets.xcconfig` yoluna sembolik bağla bağlanmalı (kök dizine değil). İş bitince bağı sil. Bkz. [[faz11-masal-ailem]].

---

## faz21-varyasyon

_Varyasyon planı faz-21-varyasyon dalında, 29 Ekim'de origin'e gidildi (119b873); öğrenelimde üç konu canlı, örneklenen çeşitlilik sayıları eşik olmaktan çıkarıldı_

Story Engine varyasyon planı `faz-21-varyasyon` dalında (worktree
`MagicPaper-altkategori`), **23 Ekim 2026'da main'e birleştirildi** (ileri
sarma, `51053ab`); origin'e gönderilmedi. main `MagicPaper/` worktree'sinde
duruyor, bu dalda değil: ileri sarma `git -C ../MagicPaper merge --ff-only`
ile yapılıyor, uygulamanın birleştirme aracı bu worktree'yi kendisi açmadığı
için reddediyor.
Sıra: D1 taban → A → D1 karşılaştırma → C → B → D2.

Kapanan: **D1** (`VariationReport` + `Content/variation_baseline.json`, 50 sabit
seed), **A** (v2 kütüphanesindeki 44 ölü kayıt etiketlenip diriltildi, `0b7b006`),
**D1 karşılaştırma**, **C** (yaş bantları, `6ac94f2`).

**B** sürüyor: B-ön 1 (insan yol arkadaşı modeli) kapandı, `CompanionNature`
ekseni eklendi (`17d50a5`) — şema insanı zaten taşıyordu, eksik olan prozanın
"hayvan mı insan mı" diye soracağı yerdi. İlk konu canlı: **"Hazine avı"**
5-6'da, tek yeni blueprint yazılmadan dört mekanizmayla (`c101323`). Kabul
ölçütü artık motorda: `CatalogStoryTopic.minimumMechanisms = 3`, yani ince bir
konu teklif edilmiyor ("Denizin altı" bu yüzden kalktı, iki mekanizma).

**29 Ekim: "Meslekler ve günlük yaşam" canlandı** (`31f193e`), beş mekanizma
(signal, patientObservation, seekingKnowledge, revelation, perspectiveShift).
Öğrenelim böylece **mod başına üç konu** hedefine ulaştı (Hayvanlar, Meslekler,
Bilim ve uzay). Yine tek yeni blueprint yazılmadı; konuyu açan şey kütüphanenin
ilk üç insanı (fırıncı, postacı, öğretmen) ve Pazar Yeri mekânı oldu.
Mevcut 35 `meet_companion` satırı insana **kapatıldı** ve 16 yeni satır yazıldı:
eski kalıp ("bir X çıkageldi, 'ben buradayım' dedi") bir yetişkin için bir
çocuk kitabına girmemeli; yeni satırlarda çocuk ona gidiyor. Yeni dışlama
ekseni `ContentExclusions.nature`: dört macera blueprint'i insanı dışlıyor —
maceraya çıkmak bir eşiği geçmektir, o yolculuğun arkadaşı köyün fırıncısı
değil. Dal 29 Ekim'de **origin'e gönderildi** (`119b873`, yeni dal); main'e
birleştirilmedi, main `fb1bf12`.

**D2 kapandı** (`47ad4a3`): proza satırları soğuyor, tekrar oranı öğrenelim
5-6'da %25→%17, macerada %30→%19. `charge` ailesi öğrenelime eklendi (karar:
Batuhan): 3-4 ikinci moduna kavuştu, öğrenelim 5-6 on mekanizma oldu, üç
ulaşılamayan blueprint kurtuldu. Bedeli üç yerde çıktı: üç blueprint'in uyku
sesindeki başlıkları yeniden yazıldı, "bir aile iki moda giremez" değişmezi
"hiçbir blueprint iki moda girmiyor"a taşındı, ve öğrenelim 3-4'ün seri
içeriği olmadığı için seri taraması devam edilebilen kesitlere süzüldü.

**3-4'ün ikinci mekanizması yazıldı** (`lettingGo`, `93023fb`): 1 → 2
mekanizma, tekrar %83 → %81. Ve bir **sınır** çıktı: 3-4 korpusunun tüzüğü
engeli ve yanlış inancı yasakladığı için `solutionKnown` üreten yalnızca iki
beat kalıyor (`patient_wait`, `let_go`). Yani planın "bir konu her aktif
bantta en az üç mekanizma" ölçütü **3-4'te ulaşılamaz**; üçüncüsü ya tüzük
değişikliği ya da yeni bir çözüm beat'i ister, ikisi de ürün kararı. Konu
kapısı o bantta bu yüzden kapalı kalıyor.

Nakaratsız tekrar ölçüsü eklendi (`repeatedSentenceRateExcludingRefrains`),
kitap araştırma ajanının itirazı ölçülüp doğrulandıktan sonra: nakaratlı bir
blueprint'te masallar arası tekrarın 8'de 6'sı nakaratın kendisi. Eski ölçü
duruyor, taban kayıtları onunla alındı.

**Örneklenen çeşitlilik sayıları eşik olmaktan çıkarıldı (29 Ekim) — bu bir
ölçüm dersi, susturma değil.** Pazar Yeri eklenince eşik testi macera 5-6'da
örneklenen mekân sayısının 16'dan 9'a düştüğünü söyledi. Sebep: maceranın
`forbids.nature` yüzünden **hiç ulaşamadığı** o tek kaydın yalnızca katalogda
var olması, sabit seed listesinin hangi mekânlara denk geldiğini değiştiriyor.
Üç yapılandırmanın hepsinde **ulaşılabilir** mekân sayısı 16'da kaldı (50
seed'de de, 200 seed'de de). `settings`/`companions`/`casts` eşikten çıktı,
yerine `testReachableVarietyHasNotFallen` geldi (kaç mekânın gerçekten
*kurulabildiği*; macera ≥16, öğrenelim ≥21); tekrar oranı eşikte kaldı, payı
%0,1'den %3'e çıktı. Örneklenen sayılar `variation_baseline.json`'da duruyor.
Bedeli: A turundaki "mekân 2 → 15" gibi *örneklenen* iyileşme iddiaları aynı
gürültüye tabi. Mekanizma sayısı — asıl ölçüt — etkilenmiyor, o yapısal.

Açık: kalan konular, **3-4 bandı** (konusu bilerek kapalı ama macera için hâlâ
blueprint yok), **uyku modunun tek mekanizması** (%85 tekrar, ölçülen en kötü
bölüm — sıradaki en büyük kazanç), çekingen insan satırları (yazıldığında V-2
`perspectiveShift` meslekler için de açılır), bekleyen altı olgu (Ay, Güneş,
düşen cisim — keşifleri yazılmadı), "Yeni ülkeler ve şehirler" (UNESCO
provenansı, insan doğrulaması bekliyor).

**Üç karar 23 Ekim'de verildi** (Batuhan "vizyona göre sen ver" dedi):
olgular onaylandı ama "bir masalda en çok bir olgu, ve olgu masalın konusu
olamaz" kısıtıyla; insan tanışmasının güvenlik kuralı yapısal vekille
denetlenecek (insan yerleşim habitatı bildirmek zorunda, saklanılabilir ya da
tehlikeli mekâna bağlanamaz) artı editoryal kural beat dosyasına yazılacak;
3-4 bandı **bilerek konusuz** kalıyor (`docs/UC_DORT_BANDI_TAVANI.md`).
Ülkeler konusu UNESCO provenansı yüzünden ertelendi.

Eski not (artık geçersiz) — Batuhan'ın kararını bekleyen tek şey: insan yol arkadaşıyla tanışmanın çocuk
güvenliği kuralı (`docs/INSAN_YOL_ARKADASI_INCELEMESI.md` son bölüm) —
denetlenen kural mı, editoryal kural mı. Cevap gelmeden "Meslekler" açılmıyor.

A turunun ürün yüzeyine dokunan iki yan etkisi:

- **İlgi ekranları konusu kapandı, ve ilk teşhis yanlıştı.** Bir tur "eşik
  aşıldı, ekranlar açıldı, karar Batuhan'ın" diye kaydedildi. 22 Ekim'de
  ölçülünce 3-4 bandının bütün kapsamasının hiçbir moda bağlanamayan
  `blueprint_charge_tending_age3_001` üzerinden sayıldığı çıktı; o bantta bir
  çocuğun alabildiği tek şekil yalnızca `animals`'a ulaşıyor. `interestCoverage`
  artık yalnızca bir modun kabul ettiği blueprint'leri sayıyor, sunulan kelime
  bire düştü, ekranlar gizli. Eşik hiç meşru aşılmamış. Bkz.
  [[faz12-ilgi-alanlari]].
- **B2 sahne kapsaması düştü:** havuz 8 → 15 mekân, kütüphanede üç zemin
  (orman/çayır/bahçe) çizili. 40 macera seed'inin 16'sı sahne alıyor; kale, köy,
  mağara, kar vadisi, köprü, kumsal, dağ, nehir, resif çizimsiz. Regresyon
  değil, kapsama boşluğu; büyütmek B2 Faz 2'nin işi. Bkz.
  [[b2-scene-library-phase0]], [[illustrated-stories-not-live]].

Ölçümün verdiği asıl ders: havuz büyüdü, **mekanizma sayısı değişmedi** (8/4/1/1).
Çocuk aynı sekiz olay örgüsünü daha fazla yer ve arkadaşla yaşıyor; yeni olay
örgüsü B turunun işi.

Taban kaydını almak: `MP_RECORD_BASELINE=1 MP_REVISION=$(git rev-parse --short
HEAD) MP_NOTE="..." swift test --filter testRecordBaseline` (XCTest yalnızca
`test` ile başlayan metotları keşfediyor).

Kasıtlı kırmızı: `testNoBlueprintIsStrandedWithoutAMode` — 21 Ekim'de uyku arkı
eklenirken üç blueprint ulaşılamaz oldu (`admits()` aile VE ark bakıyor).
Düzeltmesi uyku arkı oturumunun, bkz. [[uyku-arki]].

**30 Ekim: konu artık OLAY ÖRGÜSÜNÜ de süzüyor** (`8d7d33c`, günlük `a466786`;
commit'lendi, **gönderilmedi**). Kusur ölçülmüştü: "Meslekler" seçilen 30 masalın
30'unda öğretmen vardı ve 30'u da başka bir şey hakkındaydı — konu kaydı
süzüyordu, şekli süzmüyordu. Çözüm konunun dördüncü yuvası `Slots.plot`, ve
`CatalogBlueprint.interests`'e bakıyor (o alan zaten "masalın kendisi neyle
ilgili" demek, yeni eksen icat edilmedi). Üç meslek blueprint'i üç ayrı
mekanizmayla 30/30 masal kuruyor.

Yeni eksenler: `requires.nature` (insan şartı), `CatalogCompanion.occupation`
(planın B-ön 1'inde ertelenen alan; tek işi prozanın zanaatı adıyla anabilmesi),
`CatalogVariant.occupationRequire` (esnemeyen süzgeç), `CatalogCompanion.factID`,
`CatalogFact.basis` (`sourced`/`editorial` — karma kaynak kararı). İnsan artık
yalnızca meslek masallarında (18 blueprint'e `forbids.nature`).

**Olgu nihayet çocuğa ulaşıyor.** `factID` 23 Ekim'de katalogda kurulmuştu ama
`ComposedStory`'nin olgu alanı yoktu ve uygulamada onu okuyan satır yoktu: onaylı
bilim olguları **hiç kimseye gösterilmiyordu**. Artık kapanış yaprağında
("Bunu biliyor muydun?", künyenin dilinde). İki taşıyıcı bir sıra gerektirdi:
olgu, blueprint'in `interests` ile bildirdiği kayıttan gelir.

**Beat'lerin kendi editoryal kuralları iki tasarımı iptal etti:** `reveal_truth`
çocuğun bir kişi tarafından düzeltilmesini yasaklıyor (o yüzden `revelation`
yerine `perspectiveShift`), `receive_appeal` satırları ("Benimle gelir misin?",
"Sensiz olmuyor") bir yetişkinin çocuğa söyleyeceği cümleler değil (o yüzden
V-2'nin meslek kardeşi 7. sayfada `restore` yerine `succeed`).

**Doğrulayıcıda iki gerçek kusur bulundu ve yedi "bilinen kırmızı" bunların
sonucuymuş:** `_satisfies` `anyOf` semantiğini TERS uyguluyordu (motor: her
grubun en az bir üyesi), `_pilot_library()` içeriğin yarısını okuyordu (v2
kütüphanesi hiç görünmüyordu). Bulma yolu: motorun 12/12 bağladığı bir
blueprint'e doğrulayıcı "hiç bağlanmıyor" dedi. Taban 14 → 10. Kelime bandı
ölçüsü bilerek eski havuzda — o ölçü katman başına olmalı (uyku satırı yalnızca
yatak odasına bağlanır) ve bu **açık bir iş**.

**İki test şansla geçiyordu, ölçümle düzeltildi:**
`ProseCooldownTests` uzun vadeli bir iddiayı 12 masalla ölçüyordu — macera her
sayıda çalışıyor, öğrenelim ancak **n=24'ten sonra** gürültüden ayrışıyor
(n=12'de %13→%16 ✗, n=24'te %32→%30 ✓); 30 ve 50'ye taşındı.
`UsageLearningTests` istatistik bir eğilimi tek rastgele arkadaşla ölçüyordu
(prob yunusu veriyordu, erişim 6/17, taban 4/100); mekanizma 10 arkadaşın
6'sında artırıyor ve erişimle güçleniyor, iddia artık toplamda ölçülüyor.

Test: motor 896/8 vaka (taban), uygulama 785/0, doğrulayıcı 10.
**Simülatörde görülmedi:** kapanış yaprağındaki olgu kartı ekranda hiç görülmedi.

---

## haftalik-dongu-guncel-kitaplar

_Haftalık kitap araştırma döngüsünde daha güncel kitaplar seçilir (Batuhan, 29 Ekim 2026); IA/Gutenberg eski kitapları artık alınmaz_

Haftalık öğrenme döngüsünde (magicpaper-learning-loop) daha güncel kitaplar ele alınır: her kaynakta en yeni yayınlar önce, tercihen 2020 ve sonrası; raporda her kitabın yayın yılı yazılır. Internet Archive (≤1930) ve Gutenberg kitapları haftalık artışa alınmaz.

**Why:** 28 Ekim döngüsünde Book Dash dışı kaynak bulunamayınca yedek olarak 1928 tarihli Millions of Cats okundu; Batuhan daha güncel kitap istedi.

**How to apply:** Book Dash dışı 3 kitap için StoryWeaver'da yüksek id'li (yeni) hikâyeler seç; StoryWeaver bir oturumda 3 hikâyeden sonra üyelik duvarı çıkarıyor (hesap açılmaz), African Storybook tarayıcıda reddedildi. Yol tıkanırsa IA yerine yeni Book Dash kitapları al ve bunu kayda geç. Zamanlanmış görevin metni de buna göre güncellendi (29 Ekim). İlgili: [[book-intelligence-agent]]

---

## butunluk-denetimi

_Bütünlük denetimi (22-23 Ekim 2026): 7 adımlık marka/erişilebilirlik/bulunabilirlik planı, 1-6 bitti, main+origin 2a9196f; açık kararlar ve ölçüm tuzakları_

Batuhan 22 Ekim 2026'da "tüm sayfalar bütün, erişilebilir, bulunabilir, marka her yerde" istedi. Plan ve bulgular `MagicPaper/docs/BUTUNLUK_DENETIMI.md`, ekran görüntüleri `docs/butunluk/`. main+origin 2a9196f (23 Ekim push, 782/0 test).

**Biten:** 1 dokunma alanı 48 + MPIcon VoiceOver'dan gizli; 2 tek `MPParentHeader` (kök/alt sayfa); 3 tek `MPSectionHeader` + boş durum `MPStateView`; 4 Günlük/klasik karartma `MPArtHero`'da (sabit yükseklik, `MP.Scrim.mid→solid`); 5 Legacy arayüz bileşenleri silindi, `MPRowButton` eklendi; 6 Ragi mod seçimi/Masal ailem/Kim okuyor?/Yeni kelimelerim'e, Günlük'e kilit, kapı ekranı düzeltildi, `MPStatusBarBackdrop` ortak. Design law'a Üst başlık, Bölüm başlığı ve boş durum, Ragi kuralları yazıldı (CLAUDE.md repo dışında, git'te yok).

**Karar 23 Ekim:** `MPModeSwitch` silindi (A); mod geçişi çocukta kilit, ebeveynde "Çocuk modu" (Design law). main 4e6e9c8, push yok.

**Açık:** 7. adım VoiceOver yürüyüşü; birincil buton gradient'i Design law'a aykırı (karar); token adları `MP.*` mi Pastel mi (karar); çocuk kök sekme başlıkları birleşmedi (`KidHeader` çağrılmıyor); Masal ailem geri düğmesi zeminde kayboluyor; Günlük tepesindeki krem açma karanlık slaytta yetmiyor; kapı en büyük yazıda klavyeyle "Onayla"ya kaydırmak gerekiyor.

**Why:** Denetim adlara/grep'e bakınca iki kez yanıldı: "Legacy" adlı veri taşıma (`MPStreak`) ve okuyucu geri dönüş anahtarı (`LegacyStoryReaderContainer`) arayüz değildi; `MPEmptyState` değil `MPStateView` canlıydı; "24 bölüm başlığı" çoğu kart başlığıydı.
**How to apply:** Bir bileşeni silmeden/taşımadan önce çağıranları ve ne iş yaptığını oku. Ana sayfa ve Kitaplık'a saat çubuğu şeridi koyma (16 Ekim kararı). Simülatörde açılıştan sonraki ilk dokunuş yutulabiliyor; dokun, görüntü al, kontrol et. Bkz. [[ragi-on-planda]], [[degisiklik-gunlugu-kurali]], [[shared-checkout-branch-switch]].

---

## gezinme-tek-duzen

_7 Kasım 2026: sayfa mimarisi uygulandı (ebeveyn odası, Büyükler için, push, sistem sheet'i, görsel sadeleşme); bekleyen kararlar ve derleme tuzakları_

Harita `MagicPaper/docs/SAYFA_MIMARISI.md`, kaynaklar `docs/UX_KAYNAK_ARASTIRMASI.md`. Hepsi main+origin c398a60 (7 Kasım). 795 test, 0 hata. iCloud `.git/refs/heads/` altına " 2" ekli dal kopyası bırakabiliyor, `git fetch`i bozuyor (`main 2` Batuhan'ın onayıyla silindi); `fetch` böyle kırılırsa uzak durumu `ls-remote` ile kontrol et. Kurallar Design law'da (Üst başlık, Sayfa açılışı, Ebeveyn odası, Bölüm başlığı).

"Günlük" sekmesi 7 Kasım'da "Masallar" oldu (Batuhan); kod adları `GunlukView`, `.gunluk` kaldı. Çubuk Ana sayfa · Masallar · Kitaplık · Profil + Masal yaz. Köşem bir tur avatara taşındı, Batuhan profil değiştirme pratik olsun diye sekmeyi geri istedi: adı Profil, "Kim okuyor?" en üstte. Köşem'i yeniden sekmeden çıkarmayı önerme. Masal yaz iOS 27'de `.prominent` (`.search` orada daireyi bozuyordu; Xcode 27 SDK ister, Xcode Cloud kontrol edilmedi).

Ana sayfadaki "Bu hafta" kartı da kalktı (Batuhan, 7 Kasım); çocuk tarafında hafta görünümü yok.

**Bekleyen kararlar:** çocuk dokunma alanı (teslim 56, Design law 48). Kalan iş: erişilebilirlik ve görüntü testleri, `HeaderWash` gradient'i, yeniden dokununca başa kaydırma yalnız Günlük'te, sheet'ler hâlâ krem.

**Why:** Batuhan "sekmeler değişik açılıyor" dedi ve ebeveyn bölümünün arka planda, görünmez olmasını istedi; `design-handoff/docs/` bunları zaten öyle tanımlıyordu, uygulama teslimden sapmıştı. 23 Ekim kilit ve 22 Ekim lavanta panel kararları 7 Kasım'da Batuhan onayıyla değişti. Temkinli adım adım durmamı istemedi ("neden yazmıyorsun").

**How to apply:**
- Onay gelince kodu yaz; doğrulama için beklerken durma.
- Ebeveyn odası bilerek `fullScreenCover` değil: kök sunumlar (paywall, sheet, masal yazma) odanın üstüne de açılmalı.
- `xcodebuild -list` kullanma, takılıyor (paket çözümü). Şema `MagicPaper`, `-disableAutomaticPackageResolution -skipPackageUpdates`, süre sınırı `perl -e 'alarm N; exec @ARGV'`. Soğuk derleme 9 dakikayı aşar. Görev "completed" dese de çıktıdaki çıkış kodunu oku; `xcodebuild test` testler bitince takılıp 142 ile sonlanabiliyor (Executed satırına bak). `pkill -f` zincirin kabuğunu da öldürür.
- Yalnızca iPhone 17 Pro (iOS 27) kurulu; SE, Pro Max ve iOS 26 öncesi denenemiyor. Koyu tema açık görünümle aynı. Simülatörde `text` yapıştırma izni sorar, klavye için `set_keyboard show` ve tuşlara dokun.
- `MP.E.width` 3 pt, `widthLG` 4 pt: ince çerçeve için kullanma.
- Bkz. [[butunluk-denetimi]], [[shared-checkout-branch-switch]].

---

## startup-plani-faz0

_7 Kasım startup planı (docs/STARTUP_PLANI.md) Faz 0 bitti; açık VoiceOver hatası, test komutu tuzakları, sıradaki Faz 1_

Faz 0 Korkuluk 7 Kasım 2026'da main'e commit'lendi (push yok). 802/0 + UI 9/0.

Açık: ebeveyn odasında çocuk öğeleri XCUITest ağacında duruyor. `accessibilityHidden`, `isModal`, `opacity` işe yaramadı; gerçek VoiceOver denenmedi (Batuhan cihazda). `testParentRoomHidesKidScreen` `XCTExpectFailure` ile tutuyor.

**Why:** Sıradaki oturum aynı üç denemeyi tekrarlamasın. Kontrast denetimden çıkarıldı çünkü piksel ölçümü kararsız; `textTertiary` 2,09-2,53:1 Faz 1'e kaldı.

**How to apply:** Görüntü testleri yalnız iPhone 17 Pro iOS 27'de geçerli, referanslar 1x. `xcodebuild test` kapanmaz (142), `Executed` satırını oku; `perl -e 'alarm N; exec @ARGV'` ile sar. pbxproj'a regex ile hedef eklerken tek satırlık kayıtlara dikkat: kopya kayıt üretti, kontrol `awk` ile uniq -d. Kararlar [[gezinme-tek-duzen]].

Faz 1 de bitti (7 Kasım, main, push yok): Baloo 2 özgün dosyası 1,60 em satır kutusu yüzünden doğrudan kullanılamaz, `Tools/make_baloo_latin.py` kopyası kullanılır. Faz 2 de bitti (7 Kasım, main, push yok): gezinme `app.router` (`MPRouter`), stil adları `cover/page/section/cardTitle/body/supporting/footnote/eyebrow/button`, `docs/ARCHITECTURE.md`. Faz 3'ün hukuk gerektirmeyen kısmı bitti (main, push yok). Kalan: önce-masal (hukuk), sonra Faz 4 (sanatçı) ve Faz 5. UI testleri `-mp_approveBeforeShow NO` ister, test sim'inde onay açık kalmış. Açık kararlar: Ragi kuralı gevşesin mi, paywall'dan Ragi kalksın mı.

---

## faz4-ragi-canlilik

_7 Kasım Faz 4: Ragi kod kuklası + sentez ses, masal sonu; main'de, push yok; sesler dinlenmedi, yüksek çözünürlüklü çizim açık_

Batuhan animatör beklemeden Ragi hareketini ve sesini bizim yapmamızı istedi (7 Kasım 2026). Rive yerine Metal kukla (`MPRagi.swift`, `RagiBones.metal`), sesler `Tools/make_ragi_sounds.py`. Kurallar: `docs/RAGI.md`.

**Why:** dış bütçe beklemeden Faz 4 ilerlesin. Figma Weave video modelleri hesabı bağlı olmadığı için kullanılamadı, ayrıca kredi harcar.

**How to apply:** Sesleri ben duyamam, Batuhan'ın kulağı karar verir. Pozlar `Tools/ragi/upscale_ragi.py` ile 4 kat büyütüldü (VideoToolbox, karakter aynı). Koddan vektör Ragi denendi, çıkartma gibi durdu, bırakıldı: yeniden deneme, yeni poz illüstratör işi. Önizleme: `-mpDemo YES -mpRagiStudio YES`, video `docs/media/ragi_onizleme.mp4` (commit dışı). `-mpDemo` altında Ragi kımıldamaz ki UI testleri takılmasın. Bağlantı: [[test-yalniz-plan-sonunda]], [[startup-plani-faz0]].

---

## faz5-6-yayin

_8 Kasım: masal sonu tam ekran, Faz 5 ve Faz 6 kodu main'de (push yok); huni gönderimi bayrakla kapalı, yayın adımları Batuhan'da_

8 Kasım 2026: masal sonu tam ekran kutlama (Batuhan: "başarmışlık hissi, dopamin"), Faz 5 (yaşa göre yazı boyutu, 3-6 kelime vurgusu, aile sesi), Faz 6 kodu (huni, uzaktan bayrak, marka web sayfaları, `docs/YAYIN.md`). Testler: 819/0, UI 17, kurallar 53/53.

**Why:** startup planı (Faz 0-6) kod tarafında bitti; kalanlar dış iş.

**How to apply:** Huni gönderimi `MPRemoteFlags.funnelUpload` ile kapalı: gizlilik politikası ve onay metni güncellenmeden açılmaz. Uyku modu v2'de, bayrakla açılır. Açık: "önce masal" (hukuk), TestFlight, Kids Category kararı, politika "ses kaydı toplanmaz" tutarsızlığı. Simülatörde soğuk açılış 15 sn'yi bulabiliyor: boş ekran görüntüsü hata sanılmasın. Bağlantı: [[faz4-ragi-canlilik]], [[test-yalniz-plan-sonunda]].

---

## vizyon-plani-faz7

_11 Kasım: vizyon planı (Faz 7-14) docs/VIZYON_PLANI.md; Faz 7 Omurga main fee1e7d (push yok, test çalıştırılmadı); Profil sekmesinin adı Odam_

Batuhan geniş, vizyoner bir plan istedi; yedi araştırmayla Faz 7-14 yazıldı: `docs/VIZYON_PLANI.md` (13 sayfanın tel çerçevesi dahil). Ödeme planın dışında. Kararlar: sakin koleksiyon ekonomisi (yıldız → kalıcı koleksiyon), bütün uygulama, aile özellikleri kapalı, Dolap'ta kozmetik serbest kimlik kapılı, ilk açılış tek ekran (giriş sırası `storyBeforeAccount` bayrağıyla, hukuk onayına kadar kapalı).

**Why:** startup planı (Faz 0-6) bitti; sıradaki tur sayfa düzeni, koleksiyon, motorun hafızası, akşam ritüeli, yayınevi.

**How to apply:** Faz 7 bitti (main fee1e7d, 11 Kasım): Profil → **Odam**, tek kapı `app.router.requestGate(then:)`, ebeveyn yığını `parentPath` çok seviyeli, profil sayfası `ProfileHubView`, token'lar `minTouchHero`/`chipHeightKid`/`choiceRowKid`. Testler fazlar bitince bir kez ([[test-yalniz-plan-sonunda]]); Faz 7 simülatörde görülmedi. Faz 8 bitti (main d1a898b): tek karşılama, `storyBeforeAccount` bayrağı (kapalı), hatırlatma ilk biten masaldan sonra (`ReminderSheet`), paylaşım varsayılan kapalı. Yasal alan adı `magicpaper.app` canlı, `magicpaperkids.com` web 404 (e-posta çalışıyor). Faz 9 ilk kısım main 327d508: çıkartma albümü, yıldız cüzdanı (cihazda, eşitleme yok), raf süsleri, ebeveyn kontrolü; CLAUDE.md ilke 7'de harcama kuralı. Kahraman: bugünkü kit kodla çizilmiş yer tutucu; Batuhan "çok basit, baştan tasarla" dedi. Açık kaynakta çocuk oranlı + katmanlı + boyalı set yok (DiceBear yetişkin baş; çocuk setleri CC0 düz vektör anarres/nonemo, kamu malı Delalain/Drayton kâğıt bebek). 12 Kasım Batuhan: "Duolingo tarzı avatar ve türleri" → kahraman kodla çizildi (`HeroLook`, `HeroAvatarView`, Dolap `HeroWardrobeView`), main 4fa6111: çocuk + kedi/ayı/tavşan/tilki/panda; kimlik ücretsiz ve kapılı, kozmetik yıldızla, başörtüsü ve gözlük hep ücretsiz. Kahraman ve cüzdan cihazda (eşitleme yok); eski `AvatarSpec` ile birleşme borç. Bağlantı: [[faz5-6-yayin]], [[faz4-ragi-canlilik]]. Faz 10 (12 Kasım, main, push yok): hatırlama cümlesi `StoryMemory` + Masal haritam 4d9a88a; uyku arkı 5-6'da 3, 3-4'te 2 mekanizma 6c17d86. 7-8 bandı d221261 (11 Kasım): 6 blueprint (her moda 2, 5-6 dizilerinin kopyası), 220 cümle `templates/v3-age7` + `bedtime/beat_bedtime_age7_*`; bant kısmen yazılırsa eksik mod 7-8'den kalkar (servedBand bant düzeyinde). Faz 11 main 012d1bb (11 Kasım): uyku modu bayrağı varsayılan açık (parlaklık, Ekranı karart, son sayfada söner, Siri kısayolu), akşam sırası `MPBedtimeRoutine`, okuyucuda Konuşalım (Ragi'siz, okuyucu istisnası); aile sesi ve ses katmanı yapılmadı. Faz 12 main cd490b3: baskıya hazır PDF (`MPPrintSpec`, RGB), yıllık (`MPYearbook`), "yakında" sekmesi kalktı, `docs/YAYINEVI.md`; basım ortağı ve pilot Batuhan'da. Faz 13 main 09f4dbe: fi/fl ligatürü 0,01 pt tracking ile kapalı, iki AHAP, ses perde haritası + pan, Ragi hazırlık/takip, kapak→okuyucu zoom (iOS 18), Metal kâğıt greni; TextRenderer okuma eşliği ve 3-4 sesli seçenekler yapılmadı. Faz 14 3ca7678. Plan sonu test koşusu a420d7a: uygulama 874/0, motor 8 eski kırmızı dc8306a ile kapandı (D3 pilot terfisine göre eskimiş testlerdi; motor 896/0). Düzen açıkları 9460f1b (Kitaplık sayfa satırı, okuyucu 64 pt + kapakta Kim okusun, taze çıkartma, Destek); SE/AX5 uyarlamaları açık. Faz 10 açık: Masal ailem orta beat'leri, klasikler uzak paket, Foundation Models denemesi; testler çalıştırılmadı.

---

## test-yalniz-plan-sonunda

_Tüm testler yalnızca plan bitince bir kez çalıştırılır; ara adımlarda test ve simülatör yok, token gidiyor_

Tüm test paketleri ve simülatör kontrolü her adımda değil, yalnızca plan bittiğinde bir kez çalıştırılır (Batuhan, 7 Kasım 2026).

**Why:** Ara koşular ve uzun çıktılar çok token harcıyor.

**How to apply:** Ara adımlarda sorunu kodu okuyarak çöz. Plan sonunda tek koşu yap, çıktıyı dar süz (`Executed` ve hata satırları). Günlükte hangi doğrulamanın yapılmadığını yine dürüstçe yaz.

---

## token-tasarrufu-pilotu

_7 Kasım 2026 token ölçümü ve CodeGraph A/B; Batuhan kurmama kararı verdi, maliyetin çoğu bağlam tekrarından geliyor_

Batuhan 7 Kasım 2026'da CodeGraph'ı kurmama kararı verdi. Tek A/B çiftinde CodeGraph'lı kol tahmini 1,16 $, CodeGraph'sız kol 1,05 $ tuttu; iki kolun dosya listeleri de eksiksizdi.

1 Ekim-7 Kasım 2026 ölçümü: 3,46 milyar token önbellekten okuma, 64,7 milyon önbelleğe yazma, 8,3 milyon çıktı. Araç çıktıları toplam 28,7 MB, `xcodebuild` payı 0,6 MB. RTK da aynı nedenle kurulmadı.

**Why:** Maliyetin çoğu araç çıktısından değil, bağlamın tekrar okunup yazılmasından geliyor; harita da aramanın yerini almak yerine üstüne eklendi.

**How to apply:** Token şikâyetinde önce `/clear` ile kısa oturum, işe göre model ve kullanılmayan bağlantıları kapatmayı öner. Kod haritası veya çıktı süzücü aracı ancak gerçek görevde yeni bir ölçüm kazanç gösterirse gündeme getir. Bu tek çift ölçümdür, kesin hüküm değildir.

`context-mode` ve Serena denemeleri otomatik güvenlik denetimine takıldı, ölçülmedi; yeniden denenecekse önce Batuhan izin vermeli. `context-mode` Node 24.15 ister. Pilot ortamı onayla kaldırıldı, sonuçlar main'deki `DEMO_CHANGELOG.md` kaydında (push yok).

---

## magicpaper-original

_MagicPaper Original markası (12 Kasım 2026): Masallar rafı, imzalı akışla gelen kendi masallarımız, original-writer ajanı ve pazartesi/perşembe zamanlanmış görev_

MagicPaper Original main'de (82b89f7..409c9d5, push yok). Spec `docs/superpowers/specs/2026-11-12-magicpaper-original-design.md`, plan `docs/superpowers/plans/2026-11-12-magicpaper-original.md`.

Batuhan kararları (12 Kasım): uzaktan, güncellemesiz; her masal insan onayından geçer; haftada 2 masal; kapağı Gemini DEĞİL Claude çizer: elle SVG → Tools/render_cover.py (qlmanage+sips), kılavuz Content/Originals/COVER_GUIDE.md (12 Kasım, Batuhan; Gemini aracı silindi); ortak dünya, ilk tur ajan üç dünya önerir.

Akış (13 Kasım: uzaktan sistem şimdilik YOK, masallar uygulamayla gelir): ajan `drafts/<slug>/` → `originals approve <slug>` → `python3 Scripts/ClassicsCatalog/build_classics_catalog.py` (classics_catalog.json + Assets.xcassets/Originals) → uygulama sürümü. Uzaktan kod kapalı; içerik adresi uyuşmazlığı (uygulama magicpaper-393a7.web.app, Firebase sitesi magicpaper-393a7-f2d31) çözülmedi. Ajan tanımı `MagicPaper/.claude/agents/original-writer.md`; zamanlanmış görev `magicpaper-original-writer` (0 9 * * 1,4, app kapalıyken açılışta çalışır).

**Why:** Kişiselleştirilmemiş, markalı içerik rafı; motoru değiştirmeden düzenli yeni masal.

**How to apply:**
- Dünya: Bulut Durağı (7971bc5). İlk masal "Saatin İçindeki Ninni" onaylandı, kapağı ChatGPT'den (Batuhan), uygulamada (5547c1c). Kapak (16 Kasım, e4a23f0): ajan review.md'ye ChatGPT promptu yazar, Batuhan üretir, `python3 Tools/place_cover.py <slug> <görsel>` yerleştirir; stil referansı published/saatin-icindeki-ninni/cover.jpg; SVG yolu yedek.
- SVG filtreleri qlmanage'de yalnız filterUnits="userSpaceOnUse" tam tuvalle çalışır; mix-blend-mode yok sayılır.
- Info.plist'te MPContentSigningKey DOLU (planda yanlışlıkla boş sanılmıştı).
- PublisherKit testleri `swift test --scratch-path <Masaüstü dışı>` ile; Masaüstü iCloud xattr codesign'ı bozar.
- Akış 2 MB sınırı Original metinleriyle dolabilir: ileride yükselt ya da sınırla.
- Simülatörde yerel akış denemesi: geçici repo + `content-publisher keygen/publish --repo --key`, `python3 -m http.server 8765`, `-mpDemo YES -mpStartTab gunluk -mp.debug.contentBaseURL ... -mp.debug.contentSigningKey ...`.

İlgili: [[faz15-uzaktan-icerik]], [[faz20-gunluk]], [[test-yalniz-plan-sonunda]], [[degisiklik-gunlugu-kurali]]

---

## research-original-writer-loop

_13 Kasım 2026: book-research ile original-writer birlikte çalışıyor; craft notları, ORIGINALS_CRAFT.md, iki yönlü sorular_

Karar (Batuhan, 13 Kasım 2026): book-research okuduğu kitaplardan neden-sonuç zinciri ve final derslerini çıkarır, MagicPaper Original yazarıyla (original-writer) paylaşır; ikisi birbirine soru sorar.

- Analizlerde `craft` bloğu (causal_chain + driver, ending, writer_note); `ba craft brief --write` → MagicPaper-research `docs/research/ORIGINALS_CRAFT.md`; `cycle` her hafta yeniler. 34 eski kitap `craft todo` ile haftada 3 tamamlanıyor.
- Sorular `ba request`: `--to original-writer`, yazar `--by original-writer --tale <slug>` ile cevaplar; yazar `ba`'yı mutlak yolla çağırır, araştırma klasörüne yalnız request ile yazar.
- 14 Kasım: book-intelligence d2b178c + d8c35d7 ve main ba49cec, ikisi de origin'de (149 test). Üç zamanlanmış görev güncellendi.
- İlk soru açık: Saatin İçindeki Ninni'de çözümü neden Minik buluyor.

**Why:** Batuhan Original masallarının kitaplardan öğrenerek yazılmasını istiyor.
**How to apply:** Haftalık döngüde craft bloğunu atlamamak; yazar cevaplarını çocuk kanıtı saymamak. Bkz. [[magicpaper-original]], [[book-intelligence-agent]].

---

## ebeveyn-sadelesme

_15 Kasım 2026: masal onayı kalktı, Büyükler için Profil üstünde, oda tek sayfa, giriş basılı tutma; main+origin 6f90dc1_

Batuhan (14 Kasım 2026) ebeveyn tarafının çocuğu beklettiğini ve ebeveyn alanının zor bulunduğunu söyledi. Plan onaylandı, main+origin 6f90dc1:
- Masal onayı tamamen kalktı. Ayar anahtarı açılışta silinir.
- Odaya giriş: 2 sn basılı tutma (`ParentalGateView(kind: .hold)`). Çarpma sorusu yalnızca dışarı çıkan ya da geri alınamayan işlerde ve Masal ailem ekle/düzenle'de.
- Kahraman ve kitap karakteri kapısız.
- Oda tek sayfa; Güvenlik ve Ayarlar itilen alt sayfa.

**Why:** Ebeveyn bulamıyordu; onay ve kapılar çocuğu bekletiyordu.

**How to apply:** Bu sadeleşmeyi geri alma. Onay kuyruğu ya da ebeveyn sekme çubuğu önerme. SwiftUI'da `onLongPressGesture` ScrollView içinde simülatörde tamamlanmadı; basılı tutmayı `DragGesture(minimumDistance: 0)` ve zamanlayıcıyla izle.

Açık kalanlar: koyu tema, en büyük yazı ve VoiceOver görülmedi; yazılan masalın onaysız açılışı simülatörde denenmedi. Bkz. [[gezinme-tek-duzen]].

---

## rozet-plani

_15-17 Kasım 2026 rozet planı R0-R6 bitti: main 54e8241 (origin'de); 951/953, rozet 90/90, kurallar 55/55; gündüz anı ve SE/ProMax/AX5/koyu görülmedi_

`MagicPaper/docs/ROZET_PLANI.md` (15 Kasım 2026, Batuhan): 69 rozet / 12 aile, 4 gizli, Masal anıları; gündüz masal sonunda tam ekran rozet+kat anı, gece sessiz satır. Yıldız = toplam puan (harcamayla düşmez, "cepteki yıldız" ayrı), profil 12 Yıldız katı alır. Sabah yıldızı artık yalnız masal bitirilen günde; eski sabahlar `morningRuleSince` ile korunur. Rozet yıldız vermez. Bütün kararlar verildi. R1 kodu main a037d2e (push yok, derlenmedi, test yok): `Screens/Badges/` (Services/ Xcode'da eşitlenen grup değil), MPMilestones silindi, `MPStars.score`. R2 main 63d6306: facts(for:) masaldan dolar, okuyucuda ses ve kelime kartı kancası. R3 main acf53c9: MPBadgeArt, BadgesView (MPKidRoute.badges), detay sheet, Profil altı arma + kat; kat sheet Rozetlerim'den açılır (kimlik kartı tek düğme). R4 main f508ef4: MPAwardMoment (gündüz, okuyucu içinde sahne), MPBadgeNews.announce (Profil noktası, ana sayfa eyebrow notu). R5 main c99436e: ProfileHubView puan+kat+rozet listesi, rules testi. Sıradaki R6: tek derleme, bütün testler (BadgePlanTests 28), kural testleri, simülatör.

**Why:** Batuhan Duolingo tarzı sürekli destek istedi; ilke 7'nin "points" yasağı yalnız yıldız için kaldırıldı (CLAUDE.md'ye işlendi). Kıyas, sıralama, ilerleme çubuğu, "kaldı" metni hâlâ yasak.

**How to apply:** R1'de `MPBadgeLedger` için `decodeIfPresent` göçü şart; testler yalnız plan sonunda (R6) — bkz. [[test-yalniz-plan-sonunda]], [[degisiklik-gunlugu-kurali]].


R6 (17 Kasım): main 54e8241. Düzeltildi: kelime kartı göçü, Sabah masalı 05-12, Ay arkadaşı simgesi moon, Profil kilitlileri ailelerden. Görülmedi: gündüz tam ekran an, koyu, AX5, SE, Pro Max, ebeveyn sayfası. Sonraki iş: illüstratör armaları (MPBadgeArt tek yer). Simülatör: iPhone Air C82DF855, -mpDemo YES -mpDemoLibrary YES -mpStartTab corner; açılış ~13 sn boş krem.

---

## iki-kademe-cocuk-arayuzu

_15 Kasım 2026: KidLevel (Küçük 3-6 / Büyük 7-10) main+origin de277da; açık kararlar ve iCloud kopya tuzağı_

Batuhan 14 Kasım 2026'da çocuk arayüzünün karışık olduğunu söyledi; araştırma ve iki taslaktan sonra "önerdiğin şekilde yap" dedi. İki kademe: `KidLevel` yaştan türer (7'den küçük Küçük), ebeveyn profil sayfasında "Kendi okuyor" anahtarı. Küçük'te Ana sayfa sade, masal yazma resimli karolar (`LittleSteps.swift`), "Kim gelsin?" adımı kalır, konuyu MagicPaper seçer. Masallar önizlemesi Ana sayfa'dan iki kademede de kalktı.

Durum: main'e birleşti (cf77ba5 + günlük 921d019), 16 Kasım'da origin'e gitti (de277da); dal ve worktree silindi. Birleşik halde 953/950; kalan 3 hata başka işlerin testleri (BadgePlanTests wordCard, LibraryCutoverTests JSON bayt karşılaştırması).

Açık (Batuhan'ın kararı): Küçük'te alt çubuk sekme sayısı, sesli etiket (`MPSound` uyku vaktinde çalmıyor), Kitaplık/Profil'in Küçük düzeni, CLAUDE.md karar satırı.

Tuzak: `DesignSystemSnapshotTests.testSnapshotButtons` koşuyu 10 dk takıp kesiyor; `-skip-testing` ile atla. Başka oturumun simülatörüne dokunmamak için ayrı cihaz (iPhone Air) + `-mpDemo YES` işe yarıyor. Bkz. [[test-yalniz-plan-sonunda]], [[shared-checkout-branch-switch]].

---

## story-mode-product-decisions

_Owner's 2026-09-23 product decisions on Story Mode, surprise, idea cards, age bands, badges, per-child streak_

Product owner decisions (2026-09-23), binding for Story Mode / creation-flow / streak work:

- **StoryMode has exactly 3 cases:** Gelişelim (growth: problem → discovery → attempt → small win), Maceraya Çıkalım (adventure: goal → journey → obstacle → resolution → return), Uyku Zamanı (bedtime: slow tempo → safety → repetition → peaceful end).
- **"Bana Sürpriz Yap" is NOT a StoryMode.** Model it as a selection strategy (`Direct` / `Surprise`) that resolves to one of the 3 modes, preferring variety against recent history (e.g. last 3 = Macera, Macera, Gelişelim → avoid Macera). Never add `StoryMode.surprise`.
- **Idea cards stay** but are an OPTIONAL second step after mode. Skipping ("Bana bırak") = engine picks. The parent must be able to go mode → story directly. Don't let the flow become a configurator.
- **One canonical AgeBand**, one resolver: `ChildProfile.age → AgeBandResolver → AgeBand → story constraints`. Bands 3–4, 5–6, 7–8, 9–10. MVP canonical band is 5–6. No raw-age decisions scattered through the engine.
- **Remove badges and trophy/goal UI** (Daily tab). Daily tab becomes memory + continuity + recent activity ("Bu ay birlikte 6 hikâye" is fine as memory, not reward).
- **MPStreak stays, scoped per child profile.** Family/account = ownership & shared settings; Child = story/reading experience (library, streak).

**Why:** product is a premium personal storybook, not a story configurator or gamified app; child identity is the core entity.
**How to apply:** follow these when designing mode/intent types, the creation UI, age handling, Daily tab and streak storage. Related: [[blueprint-corpus-realignment]], [[magicpaper-group1-integration]].


---

## offline-guaj-pilotu

_18 Kasım 2026 — Onaylı sosyal guaj yönünü offline kişiselleştirilmiş masallara uygulama pilotu._

Kaynak: `design-handoff/proposals/2026-11-18-offline-art-pilot/REPORT.md`. Gerçek paket yükleyicisi/composer ile explicit blueprint `bp_charge_tending_001`, 5–6 yaş, Eski Meyve Bahçesi + solan fide + Kestane sabitlendi. 12 tohum × iki kurmaca isim = 24 kitap/192 sayfa, 24/24 isClean; tekrarlanan export byte-identical. İki onay bekleyen guaj çizim (fide ve kirpi), incelenmiş varyant izin listeleriyle toplam 48 sayfaya eşlendi; 144 metin kaldı. App/motor kodu ve Release bayrağı değiştirilmedi.

**Tuzak:** isClean semantik doğrulama değil. 6/24 kitapta fideye ışık/parlaklık/görünüp kaybolma dili geliyor (`ex_s_light_02/04`); bütün 7. sayfa örneklerinde sonuç Kestane'ye dönüyor. Fidenin iyileştiğini çizmek metne sadık değil. Aynı tohumun Ela/Deniz çiftlerinin 12/12'sinde en az bir varyant kimliği değişti; görseli yalnızca seed/sayfa ya da ada göre bağlama.

**Sonraki adım:** Önce bu ailede eylemin ve bakımın hedefini, nesne-özellik eşleşmesini içerik incelemesiyle netleştir; sonra varyant düzeyinde görsel koşullar, en son tek kanonik çocuk ve iki pozla katmanlı guaj deneyi. Pilot bütün katalog kapsaması, otomatik anlam denetimi, çocuk kimliği/poz tutarlılığı veya uygulama entegrasyonu kanıtı değil. Çizimler yerleşik image_gen + onaylı referansla üretildi. İnceleme/audit ve JS sözdizimi kontrolü yapıldı; app test/simülatör ve tarayıcı görsel matrisi yapılmadı.


---

## okuyucu-guaj-tasarimi

**20 Kasım telefon düzeltmesi:** Kullanıcı metni dikey ortalı istedi. `StoryPageView.textScroll` minHeight frame `.top`→`.center`; satırlar soldan, uzun metin kendi yüksekliğiyle baştan kaydırılır. Cihaz derleme/imza/kurulum/açılış başarılı; görsel kabul kullanıcıda. Yeni kitapta görselsizlik tanısı: anonim canonical metadata5–6/`object_bell_001`, recalled ve `na_any_01`; havuzda çan asset’i yok, mevcut dar eşleme bu varyantı desteklemiyor. Loader hatası yok; kapsam genişletilmedi veya rastgele art bağlanmadı. Özel kitap metni kopyası/dosya listesi tanı sonrası silindi, repo yalnız anonim bulguyu taşır. Ayrıntı offline rhythm REPORT’ta.

**19–20 Kasım offline ritim pilotu:** Kullanıcı API ile sayfa resmi üretilemeyeceğini vurgulayıp mevcut havuzla çalışmayı onayladı. Yeni offline sayfalarda `ComposedPage.role/refrain` optional `StoryPageReading` v1 ile app/series kaydına taşınır; eski kayıtlar geri doldurulmaz. `ReaderReadingRhythm` özgün paragrafları ve UTF16 aralıklarını koruyan görsel bloklar çıkarır:7–10 en fazla2 cümle, açılış ilk/sakin sonuç son cümle ayrı;3–6 tek-cümle nefes korunur. Exact authored suffix yalnız sınır doğrulanırsa ayrılır, her kaynak paragraf tam byte/UTF16 kapsanmazsa legacy. `ReaderRhythmLayout` yalnız metnin tamamı sığdığında ek x6 boşluk ekler; AX/kompakt/sahne/bozuk veya bilinmeyen metadata eski düzen. API, yeni asset, engine metni/pagecount, binder/art pinleri değişmez; önceki kurmaca sahne mockup’ları uygulamaya eklenmedi. Plan/spec `2026-11-19-offline-reader-rhythm*`, UIbrief/nihai doğrulama `design-handoff/proposals/2026-11-19-offline-reader-rhythm/REPORT.md`. İlk test oturumu ve /tmp önbellekleri ortam değişiminde kayboldu.20 Kasım: bağımlılıksız gerçek kaynak harness’ında emoji sınır testi2assertion yakaladı; Character-boundary doğrulaması düzeltildi,12test/0hata. Kullanıcının telefon build isteğiyle iPhone16 Debug derleme/imza/kurulum/açılış başarılı. Uygulama XCTest/render matrisi çalıştırılmadı; telefondaki okuyucu kabulü ve aile gözlemi bekliyor. Ayrıntı REPORT’ta.

**19 Kasım okuma hevesi araştırması:** Kullanıcı mevcut sayfaların çocuğu okumaya davet etmesini istedi; bilimsel araştırma/fiziksel kitap/dijital örnekler incelendi. Kullanıcının tercihi iki bağlama ayrı öneri:3–6 birlikte,7–10 bağımsız okuma. Rapor: `docs/research/2026-11-19-okuma-hevesi-arastirmasi.md`. İlk öneri hikâye rolüne göre sayfa ritmi; alternatifler tam sahne dizisi ve sınırlı katılım. Bunlar henüz onaylı tasarım değil; app/motor/asset değişmedi. Aktif offline ComposedPage semantiği app mapper’da yerleşim sözleşmesi olarak saklanmıyor; başka Domain/StoryPage layout alanlarıyla karıştırma. Mevcut spot yalnız incelenmiş açılış kapsamıdır. Bulgular okuma hevesi/anlama/dokunma sayısını ayırmayı önerir; Türkiye/MagicPaper etkililik deneyi yapılmadı. Sonraki adım seçilen yaklaşımın görsel karşılaştırması ve tasarım onayıdır.

**19 Kasım referans hizalama onayı:** Kullanıcı spotun üstte büyük olmasını ve önceki okuma/font/ayar referansının tüm okuyucuya uygulanmasını istedi. Spot artık üst kontrol açıklığından sonra, metinden önce; %28 sayfa hedefi, kalan alanın %45 sınırı ve 320 pt genişlik tavanı var. AX’te ve çok dar yükseklikte isteğe bağlı çizim kalkar. Nunito600 gövde korunur, ad Nunito800 olur. Alt chrome sayfa/ses ve önceki/seek/sonraki olmak üzere iki sıra; seek ilk/son uçları0/1. Aa minimum hedefle büyür, AX3 tavanı kalktı; UIKit yapraklarına Dynamic Type/boyut sınıfı aktarılır. Ayarlarda doğrudan kâğıt üstünde örnek, kapatma, sade kolay okuma, seçili kâğıt işareti ve açık lila satır aralığı vardır; dört duraklı boyut sliderı ve tüm gelişmiş tercihler korunur. Ana ayarlar beyaz, örnek seçili kâğıttır. Motor/kimlik/eşleme değişmez. Kanıt ve doğrulama: `design-handoff/proposals/2026-11-19-reader-reference-alignment/REPORT.md`. Eski spot-after-text önerisini bu onay geçersiz kılar.

_18 Kasım 2026 — kullanıcı, kodlamadan önce GPT‑6.1 ile okuyucunun önceki beğenilen sahne/spot örneğine göre yeniden düşünülmesini istedi._

`gpt-6.1-sol` uzmanı mevcut okuyucuyu okuyup `design-handoff/proposals/2026-11-18-reader-concept/BRIEF.md` hazırladı. `REVIEW.md` önizleme kapsamı/sınırları; sohbet önizlemesi `reader-concept-61.html`. Öneri: üstte guaj sahne ve temiz metin; sonraki sayfada metin ardından küçük spot; kalıcı X, mevcut işlevleri koruyan sakin üst/alt chrome, Yazı→Kâğıt ayar sırası ve canlı yazı örneği. Beyaz Gündüz mevcut sıcak asset'in aynısı değil, önerilen değişikliktir. Spot yerleşimi mevcut hasIllustration akışında ayrı rol gerektirir.

**18 Kasım uygulama onayı:** kullanıcı önizlemeyi beğenip kodlamayı istedi. SwiftUI okuyucu sahne/spot/metin olarak ayrıldı; görselsiz sayfa üstten başlar, uzun metin kayar; eksik dosya metne döner. Gündüz beyaz; Yazı→Kâğıt sırası ve canlı örnek eklendi. `StoryPage.art` isteğe bağlı role/altText/sourceID taşır; eski kayıtlar korunur, bilinmeyen rol eski sahne düzenine döner. B2 sahnesi önceliklidir; hazırlanan masal metin olarak açılırken sanat bastırılır. Motor ve Assets değiştirilmedi. Doğrulama sonucu aşağıdaki uygulama kaydında tutulur. Kestane karşılaştırması taslağı (`2026-11-18-character-comparison`) korunuyor ama kullanıcı testi/onayı sayılmıyor. Okuyucu örneğinin metni ve kızı kurmaca yerleşim örneği, motorun gerçek kişiselleştirilmiş çıktısı değil. Sözdizimi/kaynak kontrolü yapıldı; app test/simülatör ve tarayıcı görsel matrisi yapılmadı.

**Okuyucu uygulama doğrulaması (18 Kasım):** Swift kaynakları derlendi/bağlandı; test yürütmesi önce disk dolmasıyla dSYM, ardından yerel CodeSign internal error nedeniyle başlayamadı. Başarılı test iddiası yok. Görsel simülatör matrisi açık; ayrıntı `docs/READER_LAYOUT_2026-11-18.md`.


## semantik-gorsel-havuzu

**21 Kasım — üçüncü nesne genişlemesi: 20 konu.** Kırmızı top, mavi/sarı saplı atlama ipi, renkli kuyruklu kâğıt uçurtma, tahta flüt, kişi/sahne yansıtmayan el aynası ve uzun kırmızı ipek kurdele onaylı referanslarla image_gen kullanılarak hazırlandı. Kurdele v1'deki dış boya izleri araçla temizlendi; v2 paketlendi. PNG kaynakları ve tam istemler kayıtlı; runtime mpart byte'ları aynı. Önceki 14 girdi ve 20 notice / dört paired destek / üç blueprint / 38 recall aynen korunuyor. Kapalı SHA→edition tablosu yeni 20 girdilik manifesti ve eski üç sürümün sayımlarını doğruluyor; authorization/ImageIO/binder değişmedi.

Seçili app doğrulaması **91 test: 90 geçti, 1 skip, 0 hata**. Altı yeni nesne için gerçek compose→map→aynı metin→kaydet/decode ve 20 reader decode geçti. Üç oyuncak 3–4 yaşta Köy Çayırı'nda, kurdele 5–6, flüt 7–8, ayna 9–10 örnekleriyle doğrulandı; gerçek seed/blueprint/source kimlikleri `real-composer-fixtures.json` içinde. Kurdele impliesNeed nedeniyle küçük yaş spor yoluna zorlanmadı. Motor/metin/seçim/UI değişikliği yok; önceki 44/0 motor sonucu yeniden koşulmuş sayılmıyor. Her masalda çizim garantisi, telefon kurulumu veya yeni UI/VoiceOver matrisi yok. Rapor ve çizimler: `design-handoff/proposals/2026-11-21-story-art-wave3/`.

**21 Kasım — ikinci nesne genişlemesi: 14 konu ve yeni yaş kaynakları.** Onaylı referanslarla yerleşik image_gen kullanılarak pirinç pusula (`object_compass_001`), eski madeni para (`object_coin_001`, draft `old_coin` değil) ve somut yıldız taşı hazırlandı. Saydam PNG'ler, aynı byte'larla `.mpart` olarak paketlendi. SHA pinli wave2 manifesti 14 konu, 20 notice, dört küçük yaş destek satırı ve mevcut 38 recall kaydı içeriyor; eski 11 çizim ve kayıtlı pinler korunuyor.

Tek parça kaynaklar 5–6 / 7–8 / 9–10 için. 3–4 desteği yalnız üç sports blueprint'inin ilk sayfasındaki notice→meet biçimi: gerçek companion present/greeting, tam kaynak/beat sırası ve recall yok. Her konu/her masal garantisi yok. Claude `365b66b` deltası, günlük hariç 32 dosyalık kaynak patch'iyle alındı (merge değil); kaynak metni/kimliği değişmedi. history20/partCount bu upstream tesliminden gelir.

Temiz doğrulama: motor **44/0**; uygulama **89 test: 88 geçti, 1 skip, 0 hata**. Gerçek 3–4 pusula / 7–8 para / 9–10 yıldız taşı fixture'ları ve 14 reader decode geçti. İlk koşuyu bozan 193 izlenmeyen `… 2.json` kaynak dosyası ve aynı byte'ları taşıyan 772 generated kopya silinmedi; `/private/tmp/magicpaper-json-copy-quarantine-20261121-wave2/` altında yol/SHA manifestleriyle korundu. Kaynak ve aktif bundle'lardan ayrılınca kod düzeltmesi gerekmeden testler geçti. Tam paket/BoundPool/UI/VoiceOver matrisi ve telefona kurulum yapılmadı. Seed içeren exactDuplicate ölçüm bulgusu ve önceki seri uygunluğu hatası açık. Rapor, görseller ve gerçek fixture JSON'u: `design-handoff/proposals/2026-11-21-story-art-wave2/`.

**21 Kasım — kaynak izli eşleme 11 nesneye genişledi:** Çan yanında önceki v1 çizimlerinden harita, tek eldiven, eski fener, altın anahtar, mavi kristal, renkli tüy, deniz kabuğu, büyüteç, sağlam ip ve kâğıt fener; aynı beş 5–6 notice kaynağı ve 38 hatırlama satırı için ayrı yayın incelemesi yapıldı. Yeni `reviewed-discovery-art-expansion-v2.json` SHA pinli; authorization asset+kanıt döndürür. v1 önce, reviewed yalnız kalan görselsiz uygun sayfalarda; eski çan proof/pinleri korunur. Boş yuva ve açık müzik kutusu dışarıda; motor/metin/seed/kimlik/reader düzeni değişmedi. Seçili Xcode 76 test: 75 geçti, 1 skip, 0 hata (yeni politika 11/11; art/provenance toplam 27/27). Gerçek on nesne fixture'ı ve 11 reader decode geçti. Önceki seri uygunluğu hatası tekrar sınanmadı/çözülmedi. Telefona kurulum ve yeni UI matrisi yok. Her masalda görsel veya diğer yaşlara kapsama garantisi yok. Rapor: `design-handoff/proposals/2026-11-21-reviewed-discovery-expansion/REPORT.md`.

**21 Kasım — ilk incelenmiş gümüş çan eşlemesi:** Claude `c742ea7` tesliminin günlük hariç 206 dosyası patch ile alındı (merge değil). Yeni kitaplarda sayfa provenance kalıcı; app tarafında 5 notice + 38 recall kaynak özeti tek tek izinli. Yalnız 5–6 yaş ve `object_bell_001`; gerçek composed kaynak sırası/tamlığı, kanonik nesne ve sayfa metni doğrulanır. Art politika 2, manifest/dosya SHA ve ImageIO kontrolü; mevcut v1 kuralları ve eski kitaplar korunur. `auto` havuzu reviewed yapılmadı; metin/seed/seçim değişmedi, her kitapta çizim garantisi yok. Motor 11/0; uygulama 96 test: 94 geçti, 1 skip, 1 seri uygunluğu hatası (`testAModeNoContinuationServesMayNot`, 9–10 learning available/unavailable). Yeni art/provenance 22/22 geçti; genel koşu kırmızı. Telefona kurulum ve yeni UI matrisi yapılmadı. Ayrıntı: `design-handoff/proposals/2026-11-20-reviewed-discovery-art/REPORT.md`. Derlemeyi bozan altı izlenmeyen ` 2.swift` kopyası silinmeden `/private/tmp/magicpaper-source-duplicate-quarantine-20261121/` altına taşındı. Originals/Classic/ReaderImageLoader başka oturumun alanıdır.

**20 Kasım Claude provenance teslimi:** origin/anlati-provenance c742ea7 sözleşmesi okundu. Kirli checkout’a merge yapılmadan Gitblob audit’i eklendi:2721beat,1622auto/1099etiketsiz/0reviewed,193autodosya;3304genişid/textkayıt. a7685ca→c742ea7 exactpointerID/metinhash0değişim/0ekleme/0silme.7tooltestigeçti. Yeni motor sözleşmesi visualKeyadı değil subject+resolvedsubjectID+presence+states;autoeksiksizdeğil,reviewedveartuyumlulukonayıayrı. Çıktı docs/research/2026-11-20-provenance-c742ea7-art-inventory.json/md. Provenance decodebozukparçalarıatladığından sonraki binder kalanparçalardan bütünsayfakanıtıvarsaymamalı. Runtimeartmanifest/binder/engine/telefondeğişmedi;garantiNOT_CERTIFIED.

**20 Kasım ilk yeni asset adayları:** Kullanıcı devam istedi; Claude’un engine/provenance/içerik alanları beklenirken3statikguajaday üretildi: küçük gümüş çan(object_bell_001), yarı aralık mavi perdeli bahçe penceresi(setting_blue_curtain_room_001), hilalli gece penceresi(setting_moon_window_room_001). `design-handoff/proposals/2026-11-20-story-art-expansion/` REPORT+candidates.json+PNG. Built-in image_gen ve onaylıreferans; herdosyaRGBA/alfa0–255/SHAkaydı. Ay penceresi ilk2taslağımanzara/hale nedeniyleelendi;sonv3temiz. Bunlar reviewcandidate, runtimeapproveddeğil;visualKeysnull Claudeşemasıbekleniyor. Engine/model/mapper/binder/içerik/appbuild değişmedi; eski çan kitabı otomatik resimlenmedi. Kullanım sayfa anlamı/durumuyla ayrıca doğrulanmalı.

**20 Kasım motor/sanat koordinasyonu ve audit aracı:** Kullanıcı Claude’un motor kaynak parçaları+StoryPage.provenance+mapper+visualKeys/state şeması/etiketleme işlerini üstlendiğini bildirdi. Bu alanlar Claude’un; ChatGPT yalnız Tools/story_art_coverage_audit.py+testleri, docs audit/artassetbridge, sonraki appbinder/reader tarafını sahiplenir. Engine/content üretim dosyaları bu tur değişmedi. HEADa7685ca’ya refresh238kaynak/3016authoredkayıt;973eklenmiş,0silinmiş.830önceki kaydın dosya bağlamı değişmiş,aynıpointertextdeğişmemiş;49anchorincelemesigeçersizleştirildi,2korundu,3014unresolved,0artbinding. Genişwalker3304id/textnesnesi ayrıscope.3016pointer/ID/text/fileSHA0hata;6tooltesti,12mevcutassetdigestkontrolügeçti. Şema beklenirken yeni visualKey adı uydurulmadı. `docs/research/2026-11-20-art-engine-app-handoff.md` işbölümü; auditjson/md ve assetbridge aynıklasörde. Universalgaranti yok; metin/seed/seçim/telefondakiapp değişmedi.

**20 Kasım genel kapsam hedefi:** Kullanıcı her yeni masalda görselli anlatı sayfaları, küçük yaşta daha fazla görsel istedi; **metin varyantlarını değiştirmeyi açıkça reddetti** ve garantinin yeniden değerlendirilmesini istedi. Yeni öneri: metin/seed/seçim dağılımını koruyan, bütün kitabı değerlendiren nesne+mekân+kanonik arkadaş/durum karma havuzu ve authored semantik açıklamalar. Yeni mekân cümlesi, otomatik yeniden seed/variant seçimi, sessiz havuz daraltma yok. Kapsama kanıtı henüz yok;3–6 için3,7–10 için2 yalnız önerilen hedef, onaylı/kanıtlı garanti değil. İlk sayfa istisnaları bütün kitabın görselleştirilemeyeceğini kanıtlamaz. Audit ham28mekân/33keşif/26arkadaş ve52blueprint (36normal+8seri+8özel gün) buldu; eski36sayımı tümkatalogsayısı olarak kullanılmamalı. Çıktılar `docs/research/2026-11-20-metni-korumali-gorsel-kapsam-onerisi.md`,87kayıtCSV ve source-snapshot. Bu tur üretim kodu/asset/build/test değişmedi; tasarım önerisi, uygulama onayı değil.

_19 Kasım 2026 — kullanıcı using-superpowers + imagegen ile geniş motor/seri/havuz incelemesi, planlama ve mevcut modele uygun çizimler istedi._

Üç salt-okunur ajan motor/binder, içerik envanteri ve seri/uzak havuzu ayrı inceledi. Statik ham toplam: 36 blueprint, 33 nesne, 26 companion, 28 setting (eski trait’siz kayıtların hepsi seçilebilir değil). Tasarım: `docs/superpowers/specs/2026-11-19-semantic-story-art-design.md`; set: `design-handoff/proposals/2026-11-19-story-art-library/`.

**Karar önerisi:** kelime arama yerine seçilmiş varyant/sayfa provenance + subject/presence/state semantiği; önce dar incelenmiş allowlist, sonra yazılmış görsel bildirimleri. Kaydedilmiş asset+revision+altText+policy kararı reader’da yeniden seçilmez. Nötr spot bağlaması B2 bayrak/kit/library/avatar guard’ının dışında olmalı; Release B2 kapısı açılmaz. ReaderImageLoader bundled art adı çözmez; yerel kaynak çözümlemesi ayrıca yapılmalı.

**Seri tuzağı:** dört devam bölümü başta compose edilir; SeriesEpisode pages/origin saklar ama StoryIllustration saklamaz. Page art yaşar; book-level continuity yeni sözleşmede açıkça saklanmalı. Unlock’ta tekrar seçme yok. Aile silinmesi açılmamış bölümleri güncel katalogla yeniden yazar; sanat da yalnız o bölümlerde yeniden bağlanmalı.

12 saydam konu çizimi yerleşik image_gen ile onaylı referans verilerek hazırlandı: yırtık harita, boş yuva, tek eldiven, altın anahtar, açık müzik kutusu, ışıklı kâğıt fener, deniz kabuğu, mavi kristal, eski el feneri, büyüteç, renkli tüy, sağlam ip. Haritada seçilen v5 üçgen yarım pafta; v2–v4 hale nedeniyle elendi. v1 tarihçe için korundu. Katalogda deniz feneri yok. Çocuk/Ragi veya kanonik hayvan kimliği çizilmedi. Bunlar review taslaklarıdır; blueprint/varyant ilişkileri henüz gerçek compose çıktısıyla doğrulanmış runtime eşleşmeleri değildir. App/motor/Assets değişmedi; build/test/simülatör çalıştırılmadı.

**İlk uygulama eşlemesi (19 Kasım):** kullanıcı tasarımı onayladı. `OfflineStoryMapper.appStory` bütün yeni tek masal/seri hazırlanışında `StorySpotBinder` çağırır. 17 blueprint × 10 konu × iki hook/notice_anomaly varyantı (na_neutral_01/02) için 340 katı kural; catalog 2.1.0 + ham source/subject fingerprint eşleşmesi gerekir. Ek beat/recall/refrain/aile/özel gün veya farklı sürüm metin kalır. Boş yuva ve açık müzik kutusu görselleri paketli ama kural yok. On gerçek composer örneği `docs/research/2026-11-19-story-spot-fixtures.json` içinde.

`StoryPageArt` optional sürüm/digest/provenance pinleri taşır; malformed new metadata varlığı decode/reencode sırasında korunur, eski resme downgrade yok. Bundle pin reader’da doğrudan çözülür; eski imageFileName verilmez. **Xcode tuzağı:** CopyPNGFile PNG baytlarını değiştirip hash bozdu. Sabit PNG payload `.mpart` olarak paketlenir; CryptoKit SHA-256 + ImageIO ile doğrulanır. Bugünkü kural değişse de kayıtlı exact filename/digest çözülür; sonraki sürümler eski pin dosyalarını korumalı.

Doğrulama: uygulama 145 test/0 hata/1 skip; render 1/0, sekiz sabit viewport görüntüsü; yeni motor izi 2/0. Tam paket Engine933/2skip/15 assertion (8 mevcut case) başarısız; değişiklik öncesi 068ca47 geçici kopyasında aynı 8 case/15 assertion üretildi (determinism/pinned-book, trait çeşitliliği, özel gün dili, mekân, cooldown ve yıldız-haritası çekimi). Diğer paket hedefleri17+89+51 hatasız. Tam cihaz/VoiceOver/ses/gestür elle matrisi yapılmadı. Plan, araştırma kayıtları ve renderlar `2026-11-19-story-spot-*` dosyalarında.


**21 Kasım — kitap boyunca görsel başlangıç ölçümü:** Kullanıcı yol haritasını uygulamayı istedi, Tarçın kimlik taslağını onayladı. `docs/STORY_ART_ROADMAP.md` aktif takip. Altı açık5–6macera blueprint×100sabitseed, doğrudan composer→appmapper→JSON:600/600temizbaşarılı,4.800sayfa,221kitap1pin/379kitap0pin; tüm pinler açılışta, orta/son0. `WholeBookArtCoverageTests`1testgeçti; mevcut UI/motor/seçim/metin değişmedi, tam paket/cihaz doğrulaması değil. HamJSON ve rapor `design-handoff/proposals/2026-11-21-whole-book-art/`. Otomatik kaynak etiketleri yalnız aday sayılır. Pilot üç nesnenin p2detayları ve kanonikTarçın pozları; kapanış/orta katkısı için tam sayfa kaynak onayı gerekli. Kimlik onayı runtimepozların tüm durumlara onayı değildir.

**22 Kasım — kitap boyunca pilot politika3:**6yeni görünüm/poz,21tam-sayfa kaynak kuralı; eski1/2pinleri korunur, yeni3kaydedilir/4reddedilir. AX ve kompakt spot sayfası çizim+metin tek scroll.101seçili test100geçti/1skip/0hata. Sabit600masal251pin(221önce),orta9/son2;356kitap görselsiz. Metin/eskiart karşılaştırması geçti. Telefon/VoiceOver/eklerin elle matrisi bekliyor. Kanıt `design-handoff/proposals/2026-11-21-whole-book-art/VALIDATION.md`.


---

## bes-arkadas-k01

**22 Kasım 2026 — B yaklaşımı kullanıcı tarafından onaylandı, kaynak koruma temeli uygulandı.** Beş ana arkadaş, gerektiğinde ayrı konuk/uzman; üç modda kişiliğe uygun repertuvar, bütün şablonlara zorlama yok. `ContentSourceReference` (tam payload SHA + `offline-legacy-v1`), kayıpsız `ContentSourceMetadata`, `CatalogSnapshotStore` ve tarihsel resolver eklendi. Origin/SeriesPlan kaynak kimliği taşıyor; devam/ailesiz yeniden yazım tarihsel kaynağı kullanıyor, unlock kayıtlı sayfayı kopyalıyor. Ref'siz geçmişe bugünkü 2.1.0 otomatik atanmaz: compatibility tablosu boş, yeniden yazımda missing/ambiguous açık sınırdır; saved text/precomposed episodes kalır.

Sabit ID binder yolu tüm havuzu gereksiz denetlemeyecek biçimde ortaklaştırıldı; habitat/safety/cast/konu ve ilk uygun duplicate/red sözleşmesi korunuyor. `StoryPage.==` ID-only olduğundan eski istemcinin source metadata'sını koruma kontrolü tam encoded sayfa değeriyle yapılır. Hesap silmede history + service source cache sıfırlanır.

P56, `Content/Pilots/five-friends-56-v1/` altında yalnız editoryal korpus: 9 kurgu,30 kitap,240sayfa,15hücre,1251kaynak; üretim bundle'ında değil.8sayfa inceleme düzeltmesi yeni `_v2` kimliği aldı, önceki metin/hash korundu. Runtime beat/state, kişiselleştirme,1500seed ve art kabulü yapılmadı. Meslek/deniz/uzay ayrı teslim; Ragi marka/Originals rolünde. Yeni beşli üretim politikası açılmadı, push/deploy yok.

Ayrıntı ve güncel test sonuçları: `docs/research/five-friends-k01-baseline/IMPLEMENTATION_REPORT.md` + `verification-summary.json`; okunabilir pilot: `docs/research/five-friends-pilot/OKUMA_DOSYASI.md`. Testte eski9–10learning devam yok varsayımı düzeltilip desteklenen9–10 ve desteksiz11–12 ayrı kontrol edildi. Mevcut252motor içerik dosyası hash0değişim. Başka oturumun seçim portresi/UI değişiklikleri bu teslimin sahipliğinde değil.


## bes-arkadas-p56-runtime

**25 Kasım 2026 — internal motor uygulanıp ölçüldü; üretim hâlâ kapalı.** Ayrı `offline-p56-v1` davranış/codec ve `P56ComposedStory`; legacy ContentPackage/StoryBeat/validator/katalog değişmez. Full payloadSHA, embedded authored source/book/causal evidence, açık ad-slot türevleri ve typed9kurgu faktları; U3 sahte need/anomaly kullanmaz, L3 bekleme gözlem değil destektir.15hücrede2mekanizma/30eşleşme; tek seededseçim/retry0. App P56InternalService yalnız explicit repo/payload/ref alır; singleton/UI/bundle kaydı yok. P56draft legacyStory/Series'e sahte ref ile yazılmaz. Kayıp/bozuk exactkaynağa currentfallback yok.

Authoring30kitap240sayfa bağımsız okundu.4yeni metin düzeltmesi (2bağlaç, U2ayıçiftdönüş, gerçektestteyakalanan L2ayı16kelime cümlesinin bölünmesi) önceki8ile12revizyon; eskiID/metin/SHA ledger'da.240metadatarevizyonu aktör dizileri/kitap özeliprops/A3offscene kökleri ayırır.1252source. Atomicartmapping/soneditorialapproval yok.

Sonuçlar `docs/research/five-friends-p56-runtime/verification-summary.json`, rapor `REPORT.md`. Seçili motor36test0hata; seçili iOS21test0hata;1500ilkdeneme1500başarı/0hata/0retry/30sabitkitap. İlk kitap tekrarı herhücrede2istek; sayfatekrarlarıglobaldir, hücrede1görünebilir. Bu genişkombinatoryalçeşitlilik değildir. Art1500kitap0pin; onaylıP56ruleyok;30tamkitap240sayfanın metin/kaynak/önce-sonra/eylem/temporalkanıtı art-handoff.json içinde. Görseliçinseeddeğişmez.

SağlananContentSafety bağımsızetiketlerhenüzyokken unsupported; aile/konuk/recall/özelgün/seri/konu/diğeryaşbağlamları sessizce atılmaz, nedenlerbiriktirilir. L/FveA0kolları çalıştırılmadı.252legacyresourcehash0değişim; K1'in ref'siztarihselkaynak sınırı sürer. Meslek/deniz/uzay ayrıteslimler. Claude'a kullanıcıisteğiyle araçsızClaudeCodeüzerinden koordinasyonnotu iletildi ve yanıt alındı; bu bağımsızkodreviewdeğil. Detay/session `CLAUDE_ACKNOWLEDGEMENT.json`. Üretimyayını/artkabulü/çeşitlilikkabulü yok; push/deployyok.


### 25 Kasım 2026 · P56 runtime v2 / ContentSafety (motor hattı)

C4 v1 entegrasyonda `d4cb8c1`; b099d9b dışarıda. Ayrı runtime-v2 90 kitap/720 sayfa, hücre başına 6 kitap içerir; v1 exact bayt ve tarihsel kimliği korunur. P56PinnedSource etkin packageVersion+SHA, ayrı v1SHA256 taşır. Metadata iki sürümü birbirine dönüştürmez. Kaynak bağlı sayfa/başlık güvenlik incelemesi, sağlanan ContentSafety politikasını tek seçimden önce süzer; nil avoided bütün konulardan kaçınır. Konu/aile/seri/recall henüz unsupported. Seçili Release 65 test/1 skip/0 hata; uygulama ve tam entegrasyon kapısı açık. Ölçümler ve kapsam sınırları `docs/research/five-friends-p56-runtime/v2/REPORT.md`; görsel teslim aynı klasörde art-handoff.json. Yeni teslim karşı inceleme bekler, üretim kapalıdır.

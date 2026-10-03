# MagicPaper — Faz Planı (Ekim 2026)

**3 Ekim 2026.** Ekip toplantısının kararlarından türetildi. `MagicPaper_Faz_Plani.md`'nin (Faz 0-8)
devamıdır: oradaki açık maddeler geçerliliğini korur, bu belge Faz 9'dan başlar.
Bu belge ile eski bir doküman çelişirse **bu belge geçerlidir** (`STORY_MODE.md` dahil).

Karar kaydı: proje dokümanlarında `claude/karar-kaydi.md`. İlerleme bu belgede, her fazın
başlığındaki durum işaretiyle tutulur: ⏳ başlamadı · 🔧 sürüyor · ✅ bitti.

---

## Değişmeyen kurallar

- `CLAUDE.md` mühendislik ilkeleri ve tasarım yasası geçerlidir. Faz bitirmek = Definition of Done.
- Her faz önce inceler, sonra değiştirir. Çalışan sistem yeniden yazılmaz; artımlı ilerlenir.
- Kaydedilmiş masallar her fazdan sonra açılmaya devam eder. Model değişen her yerde
  geriye dönük çözme testi yazılır.
- `StoryGenerationManager.swift` tek sahipli dosyadır; iki faz aynı anda dokunmaz.
- Paket testlerinde bilinen hata tabanı 18'dir (1 Ekim). Hiçbir faz bu sayıyı artıramaz.
- Çocuk adı, yaşı, masal metni, kullanıcının yazdığı karakter adları log'a yazılmaz.

## Kararların özeti (bu plan bunlara göre)

| Konu | Karar |
|---|---|
| Metin masal | Cihazda offline motor. LLM yok |
| Modlar | `bedtime` Uyku öncesi · `learning` Yeni şeyler öğrenelim · `adventure` Maceraya çıkalım · "Bana sürpriz yap" seçim stratejisi |
| Oluşturma | Mod → "Masalda kimler olsun?" (katalog yol arkadaşları + Masal ailem). Serbest metin yok. Uzunluk yaş bandından, ton moddan |
| Alt seçenekler | Her mod için gelecek; şimdi yok. `StoryIdeaStep` bayrakla kapalı, alt seçeneğin yeri |
| Yaş bantları | 3-4 / 5-6 / 7-8 / 9-10 |
| Seri | Beğenilen masal (sürprizle yazılmamış) devam ettirilir. 5 bölüm (ilk masal + 4). Günde bir bölüm açılır; okunmazsa bekler, birikmez. Çocuk başına tek açık seri. Her bölüm kapalı ve sakin biter |
| Masal ailem | Ad + ilişki türü (kardeş, arkadaş, hayvan, hayali varlık). Cinsiyet alanı yok |
| İlgi alanları | Motorun içerik etiketleriyle aynı sözlük |
| Kullanımdan öğrenme | MVP'de: anonim olaylar + seçim ağırlıklandırma + kategori bazlı talep. LLM eğitimi yok |
| Günün masalı + eğitici hikâyeler | Uygulama güncellenmeden sunucudan değişir |
| Giriş | Google + Apple, onboarding'de zorunlu. Hesap ebeveynin |
| Sunucu | Firebase (projede zaten var): Auth, Firestore, Storage, Hosting. **Firebase Analytics eklenmez** (Kids kategorisi) |
| MVP içi | Rozet (sakin kilometre taşı), yeni kelimeler, okuma serisi, sesli okuma, uyku modu, içerik güvenliği ayarları |
| Sonraki fazlar | Kendi sesin, aile üyeleri, aileyle paylaş, masal kitabı, haftalık e-posta, widget/Siri, iPad |
| Ertelenen | Yıldız ve Premium, görselli masal (prompt chaining aday), alt seçenekler, 11-12 yaş |
| Tasarım | Eylem rengi #6A47B8, Baloo 2 + Nunito, maskot rakun "Ragi". UI referansı: İrem'in demo canvas'ı ve "MagicPaper ürün ve arayüz mimarisi" belgesi |

---

## Sıra ve bağımlılık

```
FAZ 9  Temizlik ve taban
  └─ FAZ 10 Mod seti ve oluşturma akışı
       ├─ FAZ 11 Masal ailem
       ├─ FAZ 12 İlgi alanı sözlüğü
       │    └─ FAZ 14 Kullanımdan öğrenme (cihaz)
       └─ FAZ 13 Seri
FAZ 15 Uzaktan içerik (Faz 9'dan sonra, 10-14 ile paralel olabilir)
FAZ 16 Hesap ve senkron (Firebase)  ← Faz 11-13 modelleri sabitlendikten sonra
  ├─ FAZ 17 MVP deneyimi: rozet, kelime, güvenlik, uyku, bilgi mimarisi
  └─ FAZ 18 Aile özellikleri
       └─ FAZ 19 iOS yüzeyleri ve iPad
İÇERİK HATTI (sürekli, Batuhan) — her fazın içerik ihtiyacını besler
```

Önerilen ilk TestFlight kesiti: Faz 9-13 + 15 + 16 + 17. Faz 18-19 sonraki sürümler.

---

## FAZ 9 — Temizlik ve taban ⏳

**Amaç:** Erişmek istediğimiz dosyalar bulunabilir olsun, ölü kod ve eski rehberler çıksın,
plan tek kaynaktan okunsun.

1. **Envanter önce.** Silmeden önce her aday için: derleniyor mu (pbxproj / senkron klasör),
   referansı var mı, testi var mı. Envanteri bu belgenin sonuna "Faz 9 envanteri" olarak ekle.
2. **Kök dizin:** eski rehber `.md` dosyaları (RevenueCat, paywall, build fix, App Store adımları vb.),
   tek seferlik shell/python/ruby betikleri, `*.log`, `build_log.txt`, `xcodebuild.log`,
   `m.xcodeproj` (kullanılmadığı doğrulanırsa), `update_wizard.swift`, `translate_all.swift` gibi
   dosyalar. Hâlâ işe yarayan rehber varsa `docs/`'a taşınır, gerisi silinir. Yasal sayfalar
   (gizlilik, koşullar, erişilebilirlik) kalır.
3. **Üst klasör (`MagicPaperAPP/`):** `local_test.swift`, `run_test_now.swift`, `test_*.swift`,
   `update_engine.swift`, `fix_resolver.swift` vb. git dışı test dosyaları kaldırılır.
   `AuthKey_*.p8` repoya hiçbir zaman girmemeli; güvenli bir yere taşınması Batuhan'a raporlanır,
   ajan bu dosyaya dokunmaz.
4. **`Retired/`** ve `Views/MagicPaper 2026-01-30 18-01-07/` (dağıtım çıktısı) silinir.
5. **Metin için bulut yolu:** `GeminiStoryAIProvider`, `AIService` metin yolu, `createCustomStory`
   ve metin masalına ait eski üretim kodu kaldırılır. Metin masal yalnızca `OfflineStoryService`.
6. **Görsel bulut yolu (`FalImageProvider`, `FirebaseImageUploader`, `VisualSystem`):** silinmez,
   görselli masal kararına kadar bayrak arkasında izole kalır. Çocuk akışından erişilemez olduğu doğrulanır.
7. **Eski görünümler:** `Views/` altında yeni ekranlarla değiştirilmiş olanlar (`FirebaseTestView`,
   `SimpleSubscriptionView`, `ProfileSelectorView` vb.) tek tek doğrulanıp kaldırılır.
8. `GoogleService-Info.plist` git takibinden çıkarılır (`git rm --cached`), `.gitignore` korunur.
9. `docs/` düzeni: geçerliliğini yitiren raporlar `docs/retired/`'a; `docs/README.md` güncel belgelerin
   tek listesi olur.
10. Doküman güncellemesi: `STORY_MODE.md` (rozet satırı, mod adları, yaş bantları) bu planla uyumlu hâle gelir.

**Kabul:** app build yeşil; uygulama testleri ≥ 248 geçer; paket hata sayısı ≤ 18; kök dizinde
yalnızca proje dosyaları, yasal sayfalar, `README.md`, `docs/`, kaynak klasörleri; silinen her
dosya envanterde gerekçesiyle.

**Sahip:** builder (lead). Paylaşılan dosya yok; diğer fazlar başlamadan biter.

---

## FAZ 10 — Mod seti ve oluşturma akışı ⏳

**Amaç:** Yarat akışı bugünkü kararlara otursun.

1. `StoryMode`: `growth` → `learning` ("Yeni şeyler öğrenelim"). Kaydedilmiş masalların `origin`'indeki
   `growth` değeri `learning` olarak çözülür (geriye dönük çözme testi zorunlu). Katalogdaki
   `storyModes` profili güncellenir; `CatalogIntegrity` her modun her desteklenen bantta en az bir
   blueprint'e ulaştığını denetler (ulaşamıyorsa mod o bant için `availableModes`'tan düşer, hata vermez).
2. `StorySelectionStrategy.surprise` yalnızca tek seferlik masal üretir; `Story.origin` stratejiyi saklar
   (Faz 13 bunu okur).
3. `StoryIdeaStep` bir özellik bayrağının arkasına alınır, varsayılan kapalı. Niyet modelinde
   `subOption: String?` alanı açılır, şimdilik hep `nil`.
4. Uzunluk: sayfa sayısı `AgeBand`'den gelir (katalogda bant başına tanım). Ton: mod profilinden.
   Akışta uzunluk/ton seçimi yoksa eklenmez, varsa kaldırılır.
5. `AgeBandResolver`: 3-4 / 5-6 / 7-8 / 9-10. 11-12 yaşındaki profil için davranış: en yakın bant
   (9-10) sunulur; profilde yaş seçimi 3-10 ile sınırlanır. Sunulan bant ile içeriğin olduğu bant
   farklıysa `servedBand` mevcut mantığıyla çalışır.
6. Tasarım token'ı: `MP.C` eylem rengi #6A47B8 (`MP.Palette`'te tanımlanır). Tasarım yasası kontrolleri boş döner.

**Kabul:** üç mod + sürpriz her bantta ya masal üretiyor ya da modu göstermiyor; `StoryModeFlowTests`
güncel; eski masallar açılıyor; tasarım yasası grep kontrolleri temiz.

**Sahip:** content-library (motor/katalog) + design-system (ekran). `StoryCreationFlow` tek sahipli.

---

## FAZ 11 — Masal ailem ⏳

**Amaç:** Çocuğun tekrar eden karakterleri masallara girsin.

1. Model: `FamilyCharacter { id, childID, name, relation: sibling | friend | animal(kind) | imaginary, createdAt }`.
   Çocuk başına liste; profil silinince silinir (`deleteProfile` cascade'ine eklenir).
2. Ad doğrulama: boş, aşırı uzun, rakam/emoji ağırlıklı ad reddedilir; Türkçe ek çekimi `TurkishGrammar`
   ile yapılır, ünlü uyumu için testler (örn. Can'a, Pamuk'a, Elif'e, Nuri'ye).
3. Motor: `CastBinding` katalog yol arkadaşının yanında bir Masal ailem karakterini de bağlayabilir.
   Şablonlarda ilişki türüne göre varyant yuvaları (`{companion}` yanında `{family:sibling}` vb.).
   Uygun varyantı olmayan blueprint, o karakterle seçilmez (yapılandırılmış hata, rastgele düşüş yok).
4. `CompanionStep`: "Masalda kimler olsun?" — katalog yol arkadaşları + Masal ailem + "Yeni karakter".
5. Masal ailem ekranı (Benim köşem içinden), kaç masalda göründüğü sayacı.

**Kabul:** her ilişki türü için en az bir blueprint her desteklenen bantta karakteri doğal bağlıyor
(golden test); kullanıcı adı log'da yok; profil silme karakterleri siliyor.

**Sahip:** character-system (model) + content-library (motor).

---

## FAZ 12 — İlgi alanı sözlüğü ⏳

**Amaç:** "Neleri sever" seçimi motorun diliyle aynı olsun.

1. Tek sözlük: `InterestTag` (katalogda tanımlı, kodda kapalı küme değil). Onboarding'deki çipler,
   blueprint/ortam/yol arkadaşı/nesne etiketleri ve eğitici içerik konuları bu sözlükten gelir.
2. `CatalogIntegrity`: her `InterestTag` her desteklenen bantta en az bir içeriğe ulaşıyor mu — ulaşmayan
   etiket onboarding'de gösterilmez.
3. `BlueprintSelector` puanlaması: ilgi alanı eşleşmesi ağırlık ekler; yenilik/cooldown ile dengelenir
   (ilgi alanı her masalı aynı konuya kilitlemez).
4. Profil: ilgi alanları çocuk başına saklanır, ebeveyn alanından düzenlenir.

**Kabul:** aynı çocuk için 20 ardışık masalda ilgi alanı payı artıyor ama tek konuya çökmüyor
(belirleyici test, sabit tohum).

**Sahip:** content-library.

---

## FAZ 13 — Seri ⏳

**Amaç:** Beğenilen masal 5 bölümlük seriye dönüşsün.

1. Uygunluk: masal `selectionStrategy == .direct` ile yazılmış olmalı; çocuğun açık serisi olmamalı.
   Masal sonu ve masal aksiyonlarında "Devam ettir".
2. Planlama: "Devam ettir" anında kalan 4 bölüm tek bir `SeriesPlan` olarak üretilir ve saklanır.
   Girdi, ilk masalın bitiş `NarrativeState`'i + kadro + mod + bant. Bölümler arası tutarlılık
   (karakter, yer, nesne) plandan gelir.
3. Açılma: her bölüm, önceki bölüm okunduktan sonraki **takvim gününde** açılır (cihaz saati, yerel gün).
   Okunmayan gün bölüm bekler. Saat geri alınarak açma denemesi bir sonraki bölümü erken açmaz
   (açılma tarihi saklanır, geriye gidilmez).
4. İçerik: devam bölümleri için blueprint ailesi (`continuation`) ve sakin bölüm sonu kuralı
   (`ChildSafetyPolicy`/doğrulayıcı: bölüm sonunda gerilim yok, açık soru yok).
5. Kitaplık ve ana sayfada seri kartı; seri bitince "Seri tamamlandı" anı.

**Kabul:** belirleyicilik (aynı masal + tohum = aynı seri); bölüm kilidi tarih testleri; sürpriz
masalda "Devam ettir" yok; 5. bölümden sonra seri kapanıyor.

**Sahip:** content-library + library-memory. `StoryGenerationManager` bu fazda tek sahipli.

---

## FAZ 14 — Kullanımdan öğrenme (cihaz tarafı) ⏳

**Amaç:** Motor kullanım verisinden öğrensin; veri cihazdan anonim çıkacak şekilde tasarlansın.

1. Olay şeması (`ReadingEvent`): masal ID, mod, blueprint ID, içerik ID'leri, yol arkadaşı türü,
   bant, ulaşılan sayfa, bitti mi, tekrar okundu mu, gün (zaman damgası güne yuvarlanır).
   Ad, tam yaş, karakter adı, cihaz kimliği **yok**. Masal ailemden yalnızca ilişki türü.
2. Cihazda kayıt ve kuyruk; gönderim Faz 16'da (ebeveyn ayarında kapatma anahtarıyla).
3. Yerel öğrenme: çocuğun kendi geçmişi seçim puanına girer (tekrar okunan aile/yol arkadaşı +,
   yarıda bırakılan −). Mod başına başarı tanımı katalogda: Uyku öncesinde yarıda bırakma ceza değildir.
4. Toplu öğrenme (sunucu tarafı, Faz 16 sonrası): blueprint başına tamamlanma/tekrar tablosu ve
   seçimde Thompson sampling ağırlığı. Şimdi yalnızca arayüz ve katalogda ağırlık alanı.

**Kabul:** olay şeması testleri (kişisel alan yok); yerel ağırlıklandırma belirleyici; Uyku modu kuralı test edilmiş.

**Sahip:** library-memory.

---

## FAZ 15 — Uzaktan içerik ⏳

**Amaç:** Günün masalı, eğitici hikâyeler ve motor içerik paketleri App Store güncellemesi olmadan değişsin.

1. İçerik akışı: sürümlü JSON (`feed.json`: günün masalı, eğitici hikâyeler, yayın tarihi).
   Uygulama açılışta ve arka planda çeker, cihazda saklar; internet yoksa son akış okunur.
   `DailyStoryManager`'daki yerel varsayılanlar yalnızca ilk açılış yedeği olur.
2. Katalog paketleri: `ContentCatalogLoader.load(data:)` ile uzaktan paket; etkinleştirmeden önce
   `CatalogIntegrity` + şema sürümü kontrolü; başarısızsa paketle gelen katalog kalır.
   Paketler imzalı/özetli (bütünlük), yalnızca veri — kod değil.
3. Barındırma: Firebase Storage/Hosting (Faz 16 ile aynı proje). Faz 16'dan önce statik dosya olarak da çalışır.
4. Yayın aracı: Batuhan'ın yeni hikâyeyi/paketi doğrulayıp yükleyeceği küçük bir betik
   (`Scripts/ContentPublisher`): doğrula → sürüm artır → yükle.

**Kabul:** akış değişince uygulama yeniden başlatmadan (arka plan yenilemesiyle) yeni günün masalını
gösteriyor; bozuk paket etkinleşmiyor; çevrimdışı açılış çalışıyor.

**Sahip:** builder.

---

## FAZ 16 — Hesap ve senkron (Firebase) ⏳

**Amaç:** Ebeveyn hesabı, KVKK onayı, cihazlar arası kütüphane.

1. Firebase Auth: Sign in with Apple + Google. Onboarding: Karşılama → Giriş → Ebeveyn onayı → Profil →
   Neleri sever → İlk masal. Çocuk giriş yapmaz.
2. Ebeveyn onayı: KVKK açık rıza kaydı (sürüm + tarih) Firestore'da. Metin ses kaydı özelliğine göre güncellenir.
3. Senkron: çocuk profilleri, avatar spec'i, Masal ailem, kütüphane (masal metni + origin), seri planları,
   okuma ilerlemesi. Çevrimdışı önce yerel; çakışmada son yazılan kazanır, masal metni değişmez.
4. Hesap silme: sunucu + yerel tüm veri, uygulama içinden (Apple zorunluluğu).
5. Faz 14 olay kuyruğunun gönderimi (anonim koleksiyon, kullanıcı kimliğiyle bağlanmaz).
6. Firebase Analytics, Crashlytics'in kişisel veri toplayan ayarları **eklenmez**. Güvenlik kuralları:
   her belge yalnızca sahibi ebeveyne açık; kurallar test edilir.
7. Hukuki not (ajan uygulamaz, rapor eder): Firestore bölgesi yurt dışındaysa KVKK m.9 standart
   sözleşme + Kurul bildirimi gerekir.

**Kabul:** iki cihazda aynı hesapla kütüphane eşleşiyor; çevrimdışı masal yazma ve okuma çalışıyor;
hesap silme sonrası sunucuda veri yok; güvenlik kuralları testi geçiyor.

**Sahip:** builder + library-memory.

---

## FAZ 17 — MVP deneyimi ⏳

**Amaç:** İrem'in demosundaki çekirdek deneyim.

1. Bilgi mimarisi: çocuk alanı 3 sekme (Ana sayfa · Yarat · Kitaplık); Günlük ana sayfaya katılır;
   üst bar: avatar (Benim köşem), kilit (ebeveyn kapısı). Ebeveyn alanı: Özet · Güvenlik · Ayarlar
   (Onaylar sekmesi yok). Ana sayfa hero kartı durumları (yarım masal / bugün okunmadı / okundu / uyku saati).
2. Rozetler: `CLAUDE.md` ilke 7'deki sakin kilometre taşı kurallarıyla; masal sonunda ve Benim köşem'de.
3. Yeni kelimeler: şablonlarda kelime + anlam etiketi; okuyucuda vurgulama; "Yeni kelimelerim" ekranı (`MPVocabulary`).
4. İçerik güvenliği ayarları: korku seviyesi, kaçınılacak konular — içerik etiketleriyle motorda eleme.
   "Ölüm ve kayıp" seçenek değildir (hiçbir içerikte yok). Varsayılan en korumacı.
5. Sesli okuma (`MPSpeech`, Türkçe ses), uyku modu (kararan ekran, süre sonunda kapanma), okuma ayarları.
6. Durum ekranları: boş kitaplık, üretim başarısız, internet yok (yalnızca senkron/giriş için).

**Kabul:** CLAUDE.md doğrulama komutları temiz; VoiceOver ile ilk masal baştan sona okunuyor;
en büyük Dynamic Type'ta taşma yok.

**Sahip:** design-system (UI) — İrem'in oturumları. Motor tarafı (kelime/güvenlik etiketleri) content-library.

---

## FAZ 18 — Aile özellikleri ⏳

1. Kendi sesin: sayfa sayfa kayıt, Firebase Storage'da yalnızca aile hesabına açık; okuyucuda
   "Kim okusun?" seçimi; silme.
2. Aile üyeleri: davet, roller (yönetici, ebeveyn, sadece okuma).
3. Aileyle paylaş: süreli, salt okuma bağlantısı (Firebase Hosting'de web okuyucu); bağlantıda yalnızca
   çocuğun adı ve masal metni.
4. Masal kitabı: PDF (`MPStoryPDF`); basılı kitap iş modeli kararına kadar yalnızca PDF.
5. Haftalık özet e-postası (Cloud Functions + e-posta sağlayıcısı).

**Sahip:** builder + library-memory + design-system.

---

## FAZ 19 — iOS yüzeyleri ve iPad ⏳

Widget'lar (bu akşamın masalı, seri), Live Activity, App Intents/Siri ("bu akşamın masalını oku"),
iPad yatay okuyucu.

**Sahip:** design-system + builder.

---

## İÇERİK HATTI (sürekli) — Batuhan

Kod fazlarının içerik ihtiyacı. Yazım geliştirme zamanında; yapay zekâ yalnızca taslak için,
her parça doğrulayıcıdan (`validate_beat_corpus.py`, `CatalogIntegrity`) geçer.

| İhtiyaç | Faz |
|---|---|
| `learning` modu blueprint'leri ve konuları | 10 |
| 7-8 ve 9-10 bantları için blueprint ve şablonlar (bugün yalnızca 3-4, 5-6 var) | 10 |
| İlişki türü varyantları (kardeş, arkadaş, hayvan, hayali varlık) | 11 |
| İlgi alanı etiketleri | 12 |
| `continuation` blueprint ailesi | 13 |
| Kelime + anlam etiketleri, güvenlik etiketleri | 17 |
| Günün masalı ve eğitici hikâyeler (akış) | 15 |

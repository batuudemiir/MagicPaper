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

## FAZ 9 — Temizlik ve taban ✅

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

### Kapanış notu (3 Ekim 2026, dal `faz-9`)

| Kabul kriteri | Nasıl karşılandı |
|---|---|
| App build yeşil | `xcodebuild test` (iPhone 17 Pro simülatörü) `TEST SUCCEEDED` |
| Uygulama testleri ≥ 248 | Taban 341 / 0 hata (1 atlanan) → **350 / 0 hata** (1 atlanan). Yeni: `CloudIllustrationAccessTests` (5), `LegacyCloudStoryDecodingTests` (4) |
| Paket hata sayısı ≤ 18 | Taban 647 / 18 → **647 / 18** (temiz HEAD kopyasında ölçüldü); VisualSystem 89 / 0 |
| Kök dizinde yalnızca proje dosyaları, yasal sayfalar, README, docs, kaynak klasörleri | Kök: `.github`, `AssetCatalog`, `Assets`, `ExportOptions.plist` (CI), `MagicPaper/`, `MagicPaper.xcodeproj`, `MagicPaperTests/`, `Scripts/`, `StoryEngine/`, `TestPlan.xctestplan`, `Tools/`, `ci_scripts/`, `docs/`, `marketing/`, `promo/`, `README.md`, `Secrets.xcconfig.template` (+ git dışı `Secrets.xcconfig`), yasal sayfalar (`PRIVACY_POLICY.md`, `TERMS_OF_SERVICE.md`, `privacy.html`, `privacy_policy.html`, `terms_of_service.html`, `accessibility.html`) |
| Silinen her dosya envanterde gerekçesiyle | Aşağıdaki "Faz 9 envanteri" |
| Kaydedilmiş masallar açılıyor | Geriye dönük çözme testleri (eski bulut masalı: `completed`/`generatingImages`, `imageUrl`, `coverImageUrl`, `origin` yok → `LibraryMigration`, `LibraryFileStore`, okuyucu eşlemesi); simülatörde mevcut kütüphane, masal detayı ve okuyucu açıldı |
| Metin masal yalnızca `OfflineStoryService` | `AIService`, `GeminiStoryAIProvider`, `createCustomStory`, `createCategoryBasedStory`, `TextStory*` silindi; `grep "AIService\b\|GeminiStoryAIProvider\|createCustomStory\|GEMINI"` uygulama ve `ci_scripts`'te boş |
| Görsel bulut yolu bayrak arkasında, çocuk akışından erişilemez | `CloudIllustrationAccess` (Release'te sabit `false`, DEBUG'da varsayılan kapalı, UI anahtarı yok); görsel yardımcıları `CloudIllustrationPipeline`'a taşındı; `StoryEngineContainer` bayrak kapalıyken kurulmuyor. `Screens/`, `Views/`, `ContentView`, `StoryGenerationManager`'dan bu tiplere referans yok |

Sırayla ilgili not: sihirbaz `createCustomStory`'nin tek çağıranı olduğu için "sihirbazı kaldır" commit'i
"bulut metin yolunu kaldır"dan önce geldi; her commit derleniyor.

Değişen ekranlarda yeni tasarım yasası ihlali yok (`HomeView`'deki 4 çıplak `.padding` eski).

**Borç (4 Ekim 2026 kararları):**
- **Ekran görüntüsü kontrolü (borç):** tasarım yasasının matrisi yarım kaldı. Açık tema, normal boyut, iPhone 17 Pro'da
  Ana Sayfa + masal detayı + okuyucu bakıldı; koyu tema, en büyük Dynamic Type, Pro Max ve Ebeveyn > Çocuklar
  alınamadı, çünkü okuyucunun X butonu kapanmıyor ve gezinmeyi kilitliyor. Ayrı iş: `fix/reader-close` dalı;
  düzeltildikten sonra eksik kontroller orada tamamlanır. Bu Mac'te iPhone SE simülatörü yok.
- **Premium kararıyla ele alınacak ölü kod:** sihirbaz kalkınca yıldız harcayan yol kalmadı.
  `SubscriptionManager.remainingImageStories`, `freeTrialCount`, `canCreateFreeTextStory` ve `useStory(type:)`
  bugün ölü ya da öksüz. Premium kararına kadar dokunulmaz. `SimpleSubscriptionView.swift` da derleniyor ama
  hiçbir kullanıcı yolundan açılmıyor; paywall işiyle birlikte ele alınır.
- `DesignSystem/MPBridge.swift:8` yorumu hâlâ "Gemini/Fal.ai hattı" diyor → FAZ 10 design-system işine eklendi.

### Faz 9 envanteri

Kök dizin (git'ten silindi): 37 eski rehber `.md` (`ADD_REVENUECAT_TO_TARGET`, `APP_STORE_CONNECT_*` ×4,
`APP_STORE_FINAL_SUBMISSION`, `APP_STORE_SUBMISSION_FIX`, `BUILD_FIX_SUMMARY`, `DEBUG_BUILD_REQUIRED`,
`FIX_REVENUECAT_MODULE_ERROR`, `HEMEN_YAPILACAKLAR`, `LOCALIZATION_GUIDE`, `MANUAL_UPLOAD_GUIDE`, `PAYWALL_*` ×5,
`QUICK_START`, `REVENUECAT_*` ×12, `SECURITY_WARNING`, `SONRAKI_ADIMLAR`, `SUBSCRIPTION_COMPLIANCE_CHECKLIST`,
`ACCESSIBILITY_GUIDE`, `READING_CUSTOMIZATION_GUIDE`) — tek seferlik düzeltme notları ve Gemini dönemi rehberleri,
kod/doc referansı yok. `SKILL.md` (başka projeden skill kopyası), `.claude.md` (eski Gemini prompt'u), `.vscode/settings.json`.
24 tek seferlik betik (`*.sh` ×17, `add_*_to_xcode.rb` ×2, `generate_v2.py`, `localize_app.py`, `update_wizard.swift`,
`translate_all.swift` (boş), `turkish_strings.txt`) — build fazında/CI'da çağrılmıyor.
`Retired/` (5 swift, derlenmiyordu), `MagicPaper/Views/MagicPaper 2026-01-30 18-01-07/` (dağıtım çıktısı),
`MagicPaper/patch.swift`, `MagicPaper/Services/LocalizationManager_Extended.swift` (target üyesi değildi), boş `MagicPaper/MagicPaper/`.

Git dışı (çöp kutusuna taşındı, `~/.Trash/MagicPaper-Faz9-20261003/`): `build_log.txt`, `build_stateobj_fix.log`,
`xcodebuild.log`, `m.xcodeproj/` (boş kabuk), boş `Development/`, dağıtım çıktısındaki `MagicPaper.ipa`; üst klasörden
`fix_resolver.swift`, `full_local_test.swift`, `local_test.swift`, `run_test_now.swift`, `test_run.swift`,
`test_runner.swift`, `test_story_init.swift`, `update_engine.swift`.

Kod: `Services/AIService.swift`, `StoryEngineBridge/GeminiStoryAIProvider.swift`, `Services/TextStoryManager.swift`,
`Models/TextStory.swift`, `Models/TextOnlyStory.swift` (bulut metin yolu / hiç çağrılmıyor);
`Screens/StoryWizardView.swift`, `Screens/StoryGeneratingView.swift`, `MPAppState` sihirbaz alanları (karar: sihirbaz kalkar;
içindeki `MPWrapRow`/`MPFlowLayout` `Screens/MPWrapRow.swift`'e taşındı); `Views/FirebaseTestView.swift`,
`Views/LocalImageView.swift`, `Helpers/ImagePicker.swift` (hiçbir yerden açılmıyordu); `APIKeys.gemini`,
`GEMINI_API_KEY`/`GEMINI_BUNDLE_ID` (Info.plist, şablonlar, CI); kamera ve fotoğraf kütüphanesi okuma izin metinleri.
`MagicPaper/GoogleService-Info.plist` git takibinden çıkarıldı (yerel dosya duruyor).

Kalanlar (madde 7 ile çelişki, karar: kalır): `ProfileSelectorView` (kök akış) ve `SimpleSubscriptionView`
(PaywallView yedeği) canlı. `Views/` altındaki diğer 7 ekran yeni tasarıma yerinde taşınmış, canlı.

docs: Eylül raporları ve yerini alan planlar `docs/retired/`'a taşındı (21 belge); `MagicPaper_Wave0_Stabilization`
ve `MagicPaper_MultiAgent_Status` kodda/etkin belgelerde kaynak gösterildiği için yerinde kaldı. `docs/README.md` tek liste.

---

## FAZ 10 — Mod seti ve oluşturma akışı ✅

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
7. Faz 9'dan devir (design-system): `DesignSystem/MPBridge.swift:8` yorumu kaldırılan "Gemini/Fal.ai hattı"ndan söz ediyor; güncellenir.

**Kabul:** üç mod + sürpriz her bantta ya masal üretiyor ya da modu göstermiyor; `StoryModeFlowTests`
güncel; eski masallar açılıyor; tasarım yasası grep kontrolleri temiz.

**Sahip:** content-library (motor/katalog) + design-system (ekran). `StoryCreationFlow` tek sahipli.

**Uygulama planı ve kararlar (K1-K9):** `FAZ10_UYGULAMA_PLANI.md`. Dal: `faz-10`.

### Kapanış notu (4 Ekim 2026)

**Doğrulama:**
- Paket testleri 658, hata 18. Hata listesi tabanla birebir aynı.
- App build yeşil.
- Uygulama testleri 379/0 (1 atlanan; taban 359).
- Reviewer: CRITICAL ve HIGH yok. İki MEDIUM düzeltildi: kurulamayan preset mod; preset ile fikir adımının atlanması testle sabitlendi.

**Kabul kriterleri:**
- Üç mod ve sürpriz her bantta ya masal üretiyor ya da modu göstermiyor (`testEveryBandEitherBuildsOrHidesEachMode`).
- `StoryModeFlowTests` güncel.
- Eski `"growth"` masalları "Yeni şeyler öğrenelim" olarak açılıyor (`testAStorySavedAsGrowthOpensAsLearning`).
- Tasarım yasası: FAZ 10 yeni ihlal eklemedi; beş denetimin toplamı main ile aynı. Değişen dosyalardaki eski isabetler aşağıda borç olarak kayıtlı.

**Ekran kontrolü** (iPhone 17 Pro, açık tema, en büyük Dynamic Type; mod adımı, "Masalda kimler olsun?", ana sayfa mod kartları, Ebeveyn > Çocuklar). İki kesilme bulundu ve düzeltildi:
- Ana sayfa mod kartında "öğrenelim" kelime ortasından bölünüyordu. Kart satırdan sütun düzenine geçti; yanıltıcı seçim dairesi de kalktı.
- Ebeveyn başlığı "Çocuk…" diye kesiliyordu. `MPParentHeader`, erişilebilirlik boyutlarında mod anahtarını başlığın üstüne alıyor. Üç ebeveyn ekranında ortak, değişiklik küçük.

**Kapsam dışı bırakılanlar:**
- iPhone SE ve Pro Max ekran görüntüleri alınmadı (Batuhan'ın kararı: 17 Pro yeterli).
- Ana sayfa başlığındaki "Batu…" ve sekme çubuğundaki "Ana…" kesilmeleri FAZ 10'dan önce de vardı; dokunulmadı.

**Devir:**
- İçerik hattı: 3-4 bandı için öğrenelim ve macera blueprint'leri, uyku arkı, 7-8 ve 9-10 içeriği.
- FAZ 12: Ebeveyn > Çocuklar'da "Favori dünyalar"ın boşalttığı yere İlgi alanları düzenleme bölümü gelecek.
- FAZ 13: seri yalnızca `origin.selectionStrategy == "direct"` olan masaldan açılır.

#### Tasarım yasası borcu

FAZ 10'un dokunduğu ama düzeltmediği, FAZ 10'dan önce var olan isabetler. Hepsi çıplak sayılı `.padding(...)`;
`MP.S` ölçeğinde karşılığı olmayan değerler (18, 30, 11, 13 vb.), düzeltmek görünümü değiştirir.

| Dosya | İsabet |
|---|---|
| `DesignSystem/MPControls.swift` | 7 |
| `DesignSystem/MPNavigation.swift` | 8 |
| `Views/HomeView.swift` | 4 |
| `Views/SettingsView.swift` | 6 |

Ayrı tur: "Tasarım yasası borç turu" (bu belgenin sonu).

---

## FAZ 11 — Masal ailem ✅

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

**Uygulama planı:** dal `faz-11`. Kararlar (4 Ekim 2026):
- Pilot satırları ajan taslak olarak yazar; birleştirmeden önce okunur (`MagicPaperAPP/FAZ11_AILE_SATIRLARI.md`, repo dışı).
- Karakter masalın açılışında (`notice_anomaly`) ve kapanışında (`warm_close`) yer alır.
- Giriş profil sayfasından.
- Hayvan türü sabit listeden.

### Kapanış notu (4 Ekim 2026)

**Doğrulama:**
- Paket testleri 674, hata 18. Hata listesi test başına tabanla birebir aynı (taban 658/18).
- `validate_beat_corpus.py`: bulgular tabanla birebir aynı (12, hepsi FAZ 11 öncesi). Yeni aile kapısı temiz.
- App build yeşil.
- Uygulama testleri 404/0 (1 atlanan; taban 379).
- Reviewer: CRITICAL yok. İki HIGH düzeltildi:
  - Çocuk moduna geçince Masal ailem sayfası açık kalıyordu.
  - Mod değişince uygun olmayan seçim yol arkadaşı listesini boşaltıyordu.
- Tasarım yasası: beş denetim yeni ve değişen dosyalarda yeni isabet vermedi. Repo geneli tabanla aynı (padding 81, shadow 7, hex 59).

**Kabul kriterleri:**
- **Her ilişki türü için en az bir blueprint her desteklenen bantta karakteri doğal bağlıyor (golden test):**
  - `FamilyCastTests.testEveryRelationIsCarriedInEveryBand`: 4 bant × 4 ilişki türü, `servedBand` üzerinden. Ad ilk ve son sayfada geçiyor, eksik yuva ya da tanınmayan ek yok.
  - `testEveryShippedBlueprintCarriesEveryRelation`: 15 blueprint'in hepsi 4 türü de taşıyor.
  - `FamilyStoryFixtureTests`: bant × ilişki türü başına tam metin sabitlendi.
- **Kullanıcı adı log'da yok:**
  - `FamilyCharacter` ve `FamilyCast`'in `description`, `debugDescription` ve `Mirror` çıktısı adı içermiyor.
  - Yeni hata (`noVariantForFamily`), seçici gerekçeleri ve köprü hataları yalnızca ilişki türünü söylüyor.
  - Depo log'u yalnızca sayı içeriyor.
  - Testler: `FamilyCharacterPrivacyTests`, `testTheFamilyErrorNamesTheRelationNotTheName`, `testARelationWithNoLineIsReportedNotSubstituted`. Değişen dosyalarda log grep'i temiz.
- **Profil silme karakterleri siliyor:** `FamilyCharacterDeletionTests`, gerçek `deleteProfile` üzerinden; kardeşin karakterleri duruyor. "Tüm verileri sil" de siliyor.
- **Kaydedilmiş masallar açılıyor:** `StoryOrigin`'e iki isteğe bağlı alan eklendi; FAZ 10 kökeni `nil` ile çözülüyor (`testAnOriginWrittenBeforeFaz11StillOpens`). Ailesiz masalın tohumu, fingerprint'i ve havuzu değişmedi (`OfflineDeterminismTests` sabit değerleri aynı, `testAStoryWithoutAFamilyCharacterNeverUsesAFamilyLine`).

**Plandan sapmalar (onaylı plan):**
- **`CastBinding` yerine canlı yol kullanıldı:** `OfflineStoryIntent.family` → composer. `CastBinding` ölü yolda.
- **Yuva biçimi:** `{family:sibling}` değil; `{{family.name}}` yuvası ve varyantta `familyRelations` alanı. Doğrulayıcının `[a-z.]+` deseni yüzünden iyelik yuvası `family.possessive` adını aldı.
- **"Benim köşem" yok:** Masal ailem profil sayfasından açılıyor; FAZ 17'de taşınır.
- **Ad kuralı plandan katı:** tek bir rakam ya da emoji de reddediliyor.
- **Dosya yeri:** yeni uygulama dosyaları senkron `StoryEngineBridge/` klasöründe; pbxproj'a dokunulmadı.

**Yolda bulunan ve düzeltilenler:**
- Yol arkadaşı ile aile karakteri aynı adı taşıyabiliyordu ("Pamuk" tavşan + "Pamuk" kedi). Artık bağlanmıyor.
- `TurkishGrammar` iki noktada düzeltildi; bu, ailesiz masalları da etkiler, kayıtlı metinler değişmez:
  - `â/î/û` ünlü sayılıyor.
  - İnce *l* ile biten adlar (Kemal, Hilal…) artık "Kemal'e" çekiliyor.
- `MPChip` sabit 42 pt yüksekliği en büyük yazı boyutunda etiketi kesiyordu. Artık en az 42 pt; normal boyutta görünüm aynı.

**Ekran kontrolü** (iPhone 17e + 17 Pro Max, açık tema, en büyük Dynamic Type):
- Bakılan ekranlar: profil sayfası, Masal ailem (boş ve dolu), düzenleyici (hata mesajıyla), "Masalda kimler olsun?" (çip seçili ve seçili değil).
- Uçtan uca: karakter eklendi, masal yazıldı, ilk sayfada "kardeşi Ela" geçti, kayıtlı masalın kökeninde ilişki türü ve kimlik var.
- İkinci tur:
  - Evcil hayvan ve hayvan türü çipleri.
  - Uzun ad ("Karamelli Pofuduk").
  - Gerçek masalda hayvan çekimi: "köpeği Karamelli Pofuduk'a günaydın dedi".
  - Sayaç "1 masalda".
  - Pro Max'te düzenleme ve çıkarma; karakter silinince masal kitaplıkta kaldı.
- İkinci turda bulunan ve düzeltilen:
  - En büyük boyutta uzun ad çipi ekrandan taşıyordu. `MPFlowLayout` artık satırdan geniş öğeye satır genişliğini öneriyor; `MPChip` yalnızca erişilebilirlik boyutlarında alt satıra geçiyor. Normal boyutta görünüm aynı.
  - Düzenleyici her tuş vuruşunda diskten okuyordu; artık açılışta bir kez okuyor.
  - Kaydet düğmesi soluk ama basılabilir; VoiceOver'a ne eksik olduğunu söyleyen bir ipucu eklendi.
- Bakılmayan: devre dışı çip durumu. Bugünkü içerikte her ilişki türü her modda uygun, bu yüzden oluşmuyor; mantığı `CompanionStep`/`StoryCreationFlow`'da, reviewer bulgusuyla düzeltildi.

**Kararlar (4 Ekim 2026):**
- Pilot satırlar 12 düzeltmeyle onaylandı (`FAZ11_AILE_SATIRLARI.md`). Aile açılış satırı çocuğun adıyla başlar; kural doğrulayıcıda ve `testEveryFamilyOpeningNamesTheChildInItsFirstSentence`'ta.
- "Yeni karakter" çocuk modunda gizli: başka birinin adını kaydetmek ebeveyn eylemi.
- Çocuk başına en fazla 8 karakter, masal başına 1. Adda tek rakam ya da emoji de reddedilir.

**Son doğrulama (birleştirme öncesi, temiz git worktree'de):**
- Paket 675/18, hata listesi tabanla test başına aynı.
- Uygulama testleri için aşağıdaki birleştirme commit'ine bakın.

#### Tasarım borcu (FAZ 11 ekran kontrolünden)

| Yer | Sorun |
|---|---|
| iOS onay penceresi (`confirmationDialog`: Masal ailem'den çıkar, profil sil) | En büyük yazı boyutunda dar bir balon olarak çiziliyor, kelimeleri bölüyor ("Karakt / eri"). Sistem bileşeni; çözüm kendi onay sayfamız (`MPSheet`) olabilir |
| `MPInput` | Tek satırlık alan, odak dışındayken uzun adı "…" ile kısaltıyor (Masal ailem adı, çocuk adı). Çok satırlı alan (`axis: .vertical`) ya da odak dışında sarılan metin |


**FAZ 11 dışı, ekran kontrolünde görülenler:**
- Masal kapağında başlık satırları en büyük boyutta üst üste biniyor.
- Ebeveyn > Çocuklar başlığı "profiller / i" diye kelime ortasından bölünüyor.
- `MPSheet` başlığı klavye açıkken tek satıra kesiliyor.
- Korpusta `{{child.name}} de/da …` biçiminde, adın ünlü uyumuna uymayan eski satırlar var ("Can de anladı").

**İçerik hattına devir:**
- (a) **İlişki türü varyantı eksik blueprint listesi:** bugün boş. `familyCoverage` raporuna göre 15 blueprint'in hepsi 4 ilişki türünü de taşıyor, çünkü aile anları her blueprint'in ortak açılış ve kapanışı. Yeni bir blueprint ya da yeni bir aile anı eklendiğinde `testEveryShippedBlueprintCarriesEveryRelation` eksikleri adıyla listeler. Pilot hücreler ince: hücre başına 2 satır (5-6 kapanışında 3).
- (b) **Masalın ortasındaki aile anları — FAZ 13'ten önce öncelikli.** Bugün karakter yalnızca ilk ve son sayfada. Seri bölümlerinde karakterin ortada hiç görünmemesi belirginleşecek.

---

## FAZ 12 — İlgi alanı sözlüğü ✅

> FAZ 10'dan not: Ebeveyn > Çocuklar'daki "Favori dünyalar" bölümü kaldırıldı. Çocuğun "İlgi alanları" düzenleme bölümü o konuma, profil listesinin altına gelir.

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

### Kapanış notu (4 Ekim 2026, dal `faz-12`)

**Doğrulama** (kendi worktree'sinde):
- Paket testleri 854, hata 18 (bu sayım biçimiyle main 832/18; 22 yeni test). Hata listesi test başına main ile aynı.
- `validate_beat_corpus.py`: 12 bulgu, main ile birebir aynı. Yeni sözlük kapısı temiz.
- App build yeşil. Uygulama testleri 417/0 (1 atlanan; taban 404).
- Reviewer: CRITICAL ve HIGH yok. Bir LOW düzeltildi (düzenleme sayfası yeniden görününce seçimi sıfırlıyordu). Bir MEDIUM belgelendi, aşağıda açık kalanlarda.
- Tasarım yasası: yeni ve değişen dosyalarda yeni isabet yok. `ProfileCreationView`'daki 4 çıplak padding main'de de var (eski borç).

**Kabul:** `InterestScoringTests.testAnInterestRaisesItsShareWithoutCollapsingOntoIt`. Üç sabit tohum setinde, 20 ardışık masalda, her masalın içeriği bir sonrakinin geçmişine girerek:
- ilgi alanı payı ilgi alanısız tabandan yüksek (0,35→0,40 · 0,35→0,50 · 0,25→0,55);
- pay en fazla %60;
- en az 3 farklı ortam ve 2 farklı aile;
- aynı ortam üst üste en fazla 3 kez, konu üst üste en fazla 4 masal.

Etiketleme teste ait, çünkü bugünkü görünür kelimeler her masalla eşleşiyor (aşağıda).

**Ne yapıldı:**
- **Sözlük katalogda:** `interests` (12 kelime, İrem'in demosu); kayıtlarda ayrı bir `interests` alanı (`tags` kapak dünyasını seçtiği için ona dokunulmadı).
- **Görünürlük:** `availableInterests`, binder'a sorarak yalnızca içeriği olan her bantta masala ulaşan kelimeyi sunar. Ulaşmayan kelime `interest_unreachable_in_band` uyarısıyla içerik hattına düşer.
- **Puanlama (`SelectionScoring`):** ilgi eşleşmesi ×3; son 4 masalın içeriği doğrusal soğur. Ağırlıklar eşitse eski tohumlu döndürme çalışır, `OfflineDeterminismTests` değişmedi.
- **Profil:** `UserProfile.interests`, elle yazılmış çözücüyle; FAZ 12 öncesi profil listesi açılıyor (test + cihazda eski profil açıldı).
- **Ekranlar:** isteğe bağlı "Neleri sever?" (profil oluşturma); Ebeveyn > Çocuklar'da "Favori dünyalar"ın yerinde İlgi alanları ve düzenleme sayfası. Metinler `InterestCopy`'de.

**Plandan sapmalar ve bulgular:**
- **Cooldown yoktu; FAZ 12 kurdu.** `SelectionWeights` tanımlıydı ama okunmuyordu, `read_history` yazılıyor ama okunmuyordu. Karar: cooldown herkese. Geçmiş artık kayıtlı masalların kökeninden okunuyor.
- **Bugün yalnızca 2 kelime görünüyor** (Hayvanlar, Doğa). İkisinin de gözle görülür etkisi yok: her yol arkadaşı hayvan, ulaşılan her ortam doğa. Etki içerik ayrıştıkça başlar.
- **Deniz hiçbir banda ulaşmıyor:** Mercan Denizi, Köpük ve Deniz Kabuğu hiçbir blueprint'e bağlanamıyor (ölü içerik, FAZ 12 öncesinden).
- **Ağırlıklı sıralamada FNV hash'in üst bitleri karışmıyordu;** SplitMix64 sonlandırıcısı eklendi.
- **Simgeler:** `MPIconMap`, `leaf`'i traktör, `pawprint`'i kemik çiziyor; sözlükte `tree` ve `hare` kullanıldı.

**Kararlar (4 Ekim 2026, kapanış sonrası):**
- Etiketleme taslağı onaylandı; `blueprint_charge_tending_age3_001` etiketsiz.
- Seçim zorunlu değil, en fazla 3.
- **Görünürlük eşiği:** sunulan ilgi alanı sayısı 4'ün altındaysa "Neleri sever?" ve Ebeveyn > Çocuklar'daki
  İlgi alanları bölümü gizlenir. Sabit: `ChildInterests.minimumOfferedToShow`, test:
  `testTheScreensNeedAtLeastFourOfferedWords`. Kaydedilmiş seçimler silinmez, puanlama çalışmaya devam eder
  (`testTodaysCatalogHidesTheScreensButKeepsWeighing`). **Bugün 2 kelime sunulduğu için iki ekran da gizli;**
  içerik dördüncü kelimeyi ulaştırınca kendiliğinden görünür.

**Ekran kontrolü** (eşik kararından önce; iPhone 17e + 17 Pro Max, açık tema, en büyük Dynamic Type):
- Bakılan ekranlar: Ebeveyn > Çocuklar İlgi alanları (boş ve dolu), düzenleme sayfası, profil oluşturma "Neleri sever?". Kesilme ve taşma yok.
- Uçtan uca: seçildi, kaydedildi, satır "Hayvanlar" oldu.
- Görülemeyen: 3 sınırı. Bugün yalnızca 2 çip var, sınır testle sabit.

**Açık kalanlar:**
- **Etiketleme taslağı onay bekliyor:** `MagicPaperAPP/FAZ12_ILGI_ETIKETLERI.md`, ayrı commit "içerik etiketleme taslağı". `blueprint_charge_tending_age3_001` için Hayvanlar etiketi kararı da orada.
- **Tohumla yeniden kurma:** ilgi alanı ve geçmiş kökende saklanmıyor, bu yüzden aynı tohum yalnızca aynı ilgi alanı ve geçmişle aynı kitabı kurar. Bugün yeniden kuran çağıran yok. FAZ 13 seri planı yeniden kuracaksa karar orada.
- **`hostsInterest` maliyeti:** her masalda blueprint × etiketli kayıt kadar bağlama denemesi yapıyor (bugün ≤ ~285). Katalog büyüyünce önbellek gerekir.
- **Ekran metinleri** İrem'in gözden geçirmesini bekliyor (`InterestCopy`).
- **"Profili düzenle" satırı:** "Küçük işler" listesine hata olarak eklendi.

**İçerik hattına devir:**
- Mercan Denizi / Köpük / Deniz Kabuğu'nu taşıyabilecek bir blueprint.
- 9 kelime için içerik (Uzay, Dinozorlar, Prensesler, Arabalar, Müzik, Sihir, Robotlar, Spor, Korsanlar), her biri 3-4 ve 5-6'da bir masala ulaşmalı.

---

## FAZ 13 — Seri ✅

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

### Kapanış notu (6 Ekim 2026, dal `faz-13`)

**Ön koşul:** `fix/conjunction-harmony` main'e cherry-pick ile alındı (`9b28d1e`, iki çakışma iki taraf korunarak çözüldü), dal silindi.

**Doğrulama** (kendi worktree'sinde):
- Paket testleri 878, hata 18. Hata listesi test başına main ile aynı (taban 855/18; 23 yeni test).
- `validate_beat_corpus.py`: 12 bulgu, main ile aynı. Yeni seri kapısı (`check_series_lines`, 171 satır) temiz.
- App build yeşil. Uygulama testleri 446/0 (1 atlanan; taban 417, 29 yeni test).
- Reviewer: CRITICAL ve HIGH yok. Üç MEDIUM düzeltildi:
  - erken kapanan seri, açılmış bölümü okununca "tamamlandı"ya dönebiliyordu;
  - okunamayan seri dosyası bir sonraki yazımda eziliyordu, artık kenara alınıyor (profil silme onu da siliyor);
  - ekranlar her çizimde dosyayı okuyup çözüyordu, artık değişiklik tarihine bağlı önbellek var.
  Ayrıca: yazma hataları log'lanıyor, "Tüm verileri sil" seri saatini de siliyor, seri kartı silinmiş bölümü açmadan önce geri koyuyor. Açık bırakılan MEDIUM'lar aşağıda.
- Tasarım yasası: değişen dosyalarda yeni isabet yok; `HomeView` 4, `LibraryView` 4, `SettingsView` 6 isabet main ile aynı (eski borç).

**Kabul kriterleri:**
- **Belirleyicilik** (aynı masal + tohum = aynı seri): `SeriesPlannerTests.testTheSameStoryAndSeedPlanTheSameSeries`, `testAPlanRoundTripsAndComposesTheSameText`.
- **Bölüm kilidi tarih testleri:** `SeriesClockTests` (aynı gün, ertesi gün, 23:50→00:00, saat geri, saat ileri = kabul edilen açık, saat dilimi değişimi) ve `SeriesManagerTests.testEpisodesOpenOneADayAndWaitWhenUnread` (okunmayan gün bekler, birikmez).
- **Sürpriz masalda "Devam ettir" yok:** `testASurpriseStoryMayNot`, `testTheLastPageShowsWhatTheStoryAllows`.
- **5. bölümden sonra seri kapanıyor:** `testTheFifthEpisodeCompletesTheSeries` (sonrasında yeni seri açılabiliyor).
- **Tek açık seri:** `testOneOpenSeriesPerChild`. **Profil silme seriyi siliyor:** `testDeletingAProfileDeletesItsSeries` (gerçek `deleteProfile`). **FAZ 13 öncesi masallar açılıyor:** `testAStoryWrittenBeforeFaz13StillOpens`; kayıtlı masallar değişmedi (`OfflineDeterminismTests` aynı).
- **Sakin son:** `CalmEnding` (motor süzgeci + yazılmış sayfa denetimi + doğrulayıcı), `testEveryEpisodeEndsCalmly`, `testNoEpisodeEverClosesOnTomorrow`.
- **Masal ailem silinince:** `testDeletingTheCharacterRewritesOnlyUnopenedEpisodes`.

**Kararlar (6 Ekim 2026):** "Devam ettir"e basmak = beğeni; açık seri varken sakin satır; dört bölüm anında yazılır; Masal ailem silinirse açılmış bölümler kalır, açılmamışlar karaktersiz yeniden yazılır (olmazsa seri sakince kapanır); saat kuralı sade (şimdi = max(cihaz saati, görülen en geç an), ileri alma kabul); `revisit` beat'i, `{{keepsake.name}}`, `SeriesAnchor`; FAZ 11 #11 bölüm sonlarında yok; sakin son yasak listesi; 3-4'te yalnız Uyku öncesi; içerik taslağı onaylandı (`MagicPaperAPP/FAZ13_SERI_TASLAK.md`).

**Plandan sapmalar:**
- Continuation blueprint'leri `kind` alanı yerine ayrı bir katalog katmanında (`series`): eski kod yollarına dokunmadan, kayıtlı masallar değişmeden.
- Bölümler için karışık hash'li seçici (`DeterministicPicker.mixedIndex`): eski seçici iki bölüme dörtte bir olasılıkla sayfa sayfa aynı satırları veriyordu. Tek seferlik masalın seçicisi aynı.
- Bölüm, önceki bölümlerin satırlarından kaçınır; bu yüzden "tek bölümü yeniden yaz" yerine "seriyi baştan yaz" (`SeriesPlanner.compose(plan:)`).
- `MPStoryCard`'a rozet simgesi/tonu parametresi (paylaşılan dosya, küçük ek): bölüm rozeti taç yerine yer imi.
- Masal sonu sütunu en büyük yazı boyutunda sığmazsa kayıyor (ay simgesi kapatma düğmesine çarpıyordu).

**Ekran kontrolü** (iPhone 17e + 17 Pro Max, açık tema, en büyük Dynamic Type; görüntüler `MagicPaperAPP/FAZ13_ekran/`, repo dışı):
- 17e: masal sonu (Devam ettir, başlatıldı, bölüm, Seri tamamlandı; normal ve en büyük boyut), ana sayfa seri kartı (bekliyor, hazır), kitaplık kartı ve bölüm rozeti, masal aksiyonlarında sakin satır.
- Pro Max: masal sonu (Devam ettir, başlatıldı), ana sayfa kartı (bekliyor, hazır), kitaplık rozeti. "Seri tamamlandı" Pro Max'te bakılmadı (17e'de iki boyutta bakıldı).
- Uçtan uca: 17e'de bir seri beş bölüm boyunca okundu (DEBUG saat ileri alma ile).

**Açık kalanlar:**
- **Ekran metinleri** İrem'in gözden geçirmesini bekliyor (`SeriesCopy`).
- **Keşif tekrarı:** 8 nesneyle bazı yerlerde bir keşif iki kez geliyor (üst üste değil). İçerik hattı.
- **5-6'da ton farkı yok:** iki continuation üç modda da; mod başına continuation içerik hattının işi.
- **Masalın ortasındaki aile anları** hâlâ yok (FAZ 11 devri); seride karakter açılış ve kapanışta.

- **Reviewer'dan açık kalan (ileri iş):**
  - *Plan ve dört bölümün yazımı ana iş parçacığında:* bugün 8 nesneyle hızlı, katalog büyüyünce arama büyür. Öneri: bölüm başına uygun keşifleri önceden hesaplamak ve başlatmayı arka plana almak.
  - *"Yarın yeni bölüm kitaplığında olacak":* bölüm uygulama açılınca açılıyor; metin İrem'in gözden geçirmesinde.
  - *Saat yanlışken yapılan okuma:* yanlış (ileri) gününü taşır, sonraki bölüm o gün gelene dek bekler. Yeniden tarihlemek, saati iki günden fazla geri alıp getirenin bölümü erken açmasına izin verirdi (karar: geri alma hiçbir şeyi erken açmaz); cihaz bu ikisini ayıramaz.

**Takip kararları (6 Ekim 2026, dal `faz-13-takip`):**
1. Bitmiş serinin ilk masalı yeniden devam ettirilmez; masal ve bölümler yeniden okunur (`testAFinishedSeriesFirstStoryIsNotContinuedAgain`).
2. Görülen en geç an cihaz saatini en fazla 2 gün geçebilir (`SeriesClock.maximumLead`; `testTheLatestTimeSeenLeadsByAtMostTwoDays`, `testAClockAYearAheadAndBackDoesNotHoldTheSeries`).
3. "Devam ettir" yalnız sonuna kadar okunmuş masalda (`testAStoryNotReadToTheEndOffersNothingInItsActions`).
Uygulama testleri 450/0 (1 atlanan), paket 878/18 (liste aynı), doğrulayıcı 12.

**İçerik hattına devir:** öğrenelim ve macera için ayrı continuation'lar; 3-4'te öğrenelim/macera ilk masalı gelince continuation'ları; yeni nesneler (`keepsakeName` ile).

---

## FAZ 14 — Kullanımdan öğrenme (cihaz tarafı) ✅

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

### Kapanış notu (6 Ekim 2026, dal `faz-14`)

**Kararlar (Batuhan, 6 Ekim):** taban FAZ 13 birleştikten sonraki main; "tekrar okunan aile" = anlatı ailesi
(`NarrativeFamily`); "Okuma bilgisini paylaş" anahtarı varsayılan **açık**.

**Doğrulama** (kendi worktree'sinde):
- Paket testleri 741, hata 18; hata listesi test başına tabanla aynı.
- `validate_beat_corpus.py`: 12 bulgu, tabanla aynı.
- App build yeşil. Uygulama testleri 472/0 (1 atlanan; taban 446).
- Reviewer: CRITICAL yok. İki HIGH onay ve bilgilendirme üzerine (aşağıda FAZ 16 devri). Kodda düzeltilenler: süre bitince
  kapanan masal yarıda bırakılmış sayılmıyor; profil silme kenara alınmış kuyruk dosyasını da siliyor; anahtar metni
  kapatınca bekleyenlerin silindiğini söylüyor.
- Tasarım yasası: yeni ve değişen dosyalarda yeni isabet yok.
- Simülatörde (17 Pro): masal okunup kapatılınca kuyrukta tek olay (bitti, sayfa 7/8, "kirpi", gün), içinde çocuğun adı
  yok; yerel kayıt yazıldı.

**Kabul:**
- *Olay şeması testleri (kişisel alan yok):* `ReadingEventTests.testTheEventCarriesOnlyTheseKeys` (anahtar beyaz listesi),
  `testNothingPersonalIsInTheEvent` (ad, profil kimliği, Masal ailem kimliği, başlık yok; description/Mirror/dump),
  `testTheTimeIsADay`, `testTheOutboundPayloadHasNoProfileID`.
- *Yerel ağırlıklandırma belirleyici:* `UsageLearningTests.testTheOrderOfStoriesDoesNotMatter`, `testPinnedMultipliers`,
  `testANeutralProfileKeepsThePinnedBook` (okuma yokken sabit kitap aynı).
- *Uyku modu kuralı:* `testAbandoningABedtimeStoryIsNotAPenalty` (katalogda `success.abandonIsPenalty: false`).

**Ne yapıldı:**
- Motor: `UsageLearner` → `UsageProfile` (anlatı ailesi ve yol arkadaşı çarpanı; tekrar okuma +1, bir kez bitirme +¼,
  yarıda bırakma −1; `1 + toplam / (masal + 2)`, 0,6…1,8). Okuma yoksa çarpan tam 1, tohumlu döndürme değişmez.
  `storyModes[].success`, `CatalogBlueprint.aggregateWeight` (varsayılan 1), `BlueprintOutcome` satırı.
- Uygulama: `ReadingEvent`, `ReadingEventQueue` (500 tavan), `StoryUsageStore` (son 30 masal motora gider),
  `ReadingSessionRecorder` (okuyucu oturumu başına bir kayıt; "Tekrar oku" ile ikinci bitiş), Gizlilik ve veri'de anahtar.
  Profil silme ve "Tüm verileri sil" ikisini de siler. `read_history_<UUID>` artık yazılmıyor.

**Plandan sapmalar:**
- Thompson sampling için ayrı bir protokol açılmadı: arayüz `BlueprintOutcome` satırı + katalogdaki `aggregateWeight`.
  Sunucu ağırlığı katalog paketiyle (FAZ 15) gönderir; motor yalnızca okur.
- Gizlilik ve veri'deki üst bilgi kartının metnine dokunulmadı; açıklama yeni anahtarın satırında.
- Arka planda öldürülen uygulamanın açık oturumu kaydedilmez (bir veri noktası kaybı, yanlış veri değil).

**FAZ 16'ya devir (reviewer HIGH, ajan uygulamaz):**
- Anahtar varsayılan açık ve mevcut kurulumlarda da olay birikiyor. Gönderimden önce ebeveyn kapısının arkasında açık bir
  bildirim gösterilmeli; bildirimden önce biriken olaylar ya gönderilmemeli ya da bildirimde söylenmeli.
- `PRIVACY_POLICY.md:269` ("Anonim kullanım istatistikleri toplanır"), `privacy.html`, `privacy_policy.html` ve App Store
  gizlilik etiketleri okuma olaylarını anlatacak biçimde güncellenmeli.
- `storyID` olayları aynı cihazda birbirine bağlar (takma ad, anonim değil). Olduğu gibi göndermek, parti başına döndürmek
  ya da çıkarmak FAZ 16 kararı.

**Açık kalanlar:**
- Tek sayfa çevirip kapatmak da (öğrenelim/macera modunda) yarıda bırakma sayılıyor. Bir eşik (örn. masalın üçte biri)
  istenirse küçük bir değişiklik.
- Modu olmayan eski masallar varsayılan kurala (yarıda bırakma ceza) düşüyor.
- `pageReached` oturumun açıldığı sayfadan başlar; kaldığı yerden açılan oturum o sayfaya "ulaşmış" sayılır.
- Ayar metni İrem'in gözden geçirmesini bekliyor.

---

## FAZ 15 — Uzaktan içerik ✅

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

### Kapanış notu (6 Ekim 2026, dal `faz-15`)

**Kararlar (Batuhan, 6 Ekim):** bütünlük Ed25519 imza (akış imzalı, paket özeti akışta); barındırma Firebase
Hosting (`magicpaper-393a7.web.app/content/`); paket = tam kaynak seti (kütüphaneler + tüm beat dosyaları,
yama değil); günün masalı hazır metin, tarihli, belirleyici seçim. Süreç ve yayın: `docs/REMOTE_CONTENT.md`.

**Doğrulama** (kendi worktree'sinde):
- Paket testleri 912, hata 18; hata listesi main'in 898/18'iyle test başına aynı.
- Uygulama testleri 514/0 (1 atlanan; taban 472). Yayın aracı testleri 10/0.
- `validate_beat_corpus.py`: 12 bulgu, tabanla aynı (taban artık `Content/validator_baseline.txt`'de; araç bunu aşan yayını durdurur).
- Tasarım yasası: yeni ve değişen dosyalarda yeni isabet yok. Ekran değişmedi (Günlük aynı görünüm, yalnız veri kaynağı).
- Reviewer: CRITICAL yok. HIGH (arka plan görevinin süresi dolunca bitirilmemesi) düzeltildi. MEDIUM'lardan düzeltilenler:
  özet uyuşmazlığı kalıcı kara listeye girmiyor (önbellek olabilir), ret listesi uygulama sürümüne bağlı, indirme sınırı
  akarken uygulanıyor, ilk yayın `--first` ister. LOW: paket yolu izin listesi (`catalog/x.y.z.json`), bozuk yazılmış
  `publishDate` masalı atlanıyor.
- Simülatörde (17 Pro, yerel sunucu + test anahtarı): akış 1'de günün masalı "Dürüstlük Ödülü"; bugün tarihli masalla
  akış 2 yayımlanıp uygulama arka plana alınıp öne getirildi → aynı süreçte (PID değişmeden) "Ragi ve Ay Işığı Feneri".
  Paket 2.0.1 bekletildi, yeniden açılışta etkinleşti, onunla yazılan masal `catalogVersion 2.0.1` kaydetti. Özeti bozuk
  2.0.2 reddedildi ("digest"), açılışta paketle gelen katalog döndü. Sunucu kapalıyken açılış son akışı gösterdi.

**Kabul:**
- *Akış değişince yeniden başlatmadan yeni günün masalı:* `DailyStoryManagerTests.testANewFeedChangesTodaysStoryWithoutARestart`
  + simülatör (öne gelme yolu). Arka plan yenilemesi (`BGAppRefreshTask`) kayıtlı ama simülatörde çalışmıyor; cihazda denenmedi.
- *Bozuk paket etkinleşmiyor:* `testAPackageThatIsNotThePublishedOneIsNotStaged`, `testABrokenPackageIsNotStaged`,
  `testAnActivePackageTheFeedDoesNotNameIsDropped`, paket tarafında `ContentPackageTests` (şema, sürüm, yeni hata, eksik beat).
- *Çevrimdışı açılış:* `testOfflineTheLastFeedIsRead` + simülatör.

**Ne yapıldı:**
- Motor: `ContentCatalogLoader.load()` birleştirme hattı değiştirilmeden `assemble(...)`'a çıkarıldı; `ContentPackage`,
  `load(package:)`, `RemoteCatalogPolicy`, `BeatCorpusLoader.load(files:)`, `CatalogLoadReport.Source.remotePackage`.
- Uygulama (`StoryEngineBridge/RemoteContent/`): `ContentFeed` (+imza), `RemoteContentStore` (Application Support,
  yedekten hariç, ilk kilit açılışından sonra okunur — arka plan yenilemesi için; çocuk verisi yok), `RemoteContentService`,
  `CatalogSourceResolver` (`OfflineStoryService.catalog()` bunu kullanır), `TodaysStoryPicker`. `DailyStoryManager`
  akıştan okur; 12 hazır masal sabit kimlikle `Content/DailyFeed/stories/`'a ve uygulama yedeğine taşındı (Swift'teki
  ~400 satır kaldırıldı); okundu bilgisi başlıkla bir kez taşınır. "Tüm verileri sil" günlük masal okuma durumunu da siler
  (önceden eksikti). `Info.plist`: arka plan görevi, `fetch`, `MPContentBaseURL`, `MPContentSigningKey` (boş).
- `Scripts/ContentPublisher`: `keygen`, `public-key`, `build-package`, `publish`, `fallback`, `verify`. `hosting/firebase.json`.

**Plandan sapmalar:**
- Günün masalı artık rastgele değil (karar); aynı gün, yaş ve okuma geçmişi her cihazda aynı masalı verir.
- Paket ancak uygulamanın katalog sürümünden yeniyse kullanılır; sürümün tek kaynağı `shared_content_library_v2.json`.
- Akış bir paket adlandırıp o paket indirilemezse/reddedilirse eski paket de bırakılır (akış neyi adlandırıyorsa o).
  Güvenli tarafta kalan bir davranış: o arada paketle gelen katalog çalışır.

**Batuhan'ın yapacakları (ajan yapmadı):** `content-publisher keygen`, açık anahtarı `MPContentSigningKey`'e koymak,
gizli anahtarı yedeklemek, `firebase login` + ilk `publish --first --deploy`, yayımlanan `feed.json`'u commit'lemek.
Anahtar boş kaldıkça uygulama uzaktan içerik almaz, yerel yedekle çalışır.

**FAZ 16'ya devir:**
- Gizlilik metni: uygulama Firebase Hosting'den içerik çeker (IP adresi Google'a görünür; istekte kimlik yok).
  `PRIVACY_POLICY.md`, html'ler ve App Store etiketi buna göre.

**Açık kalanlar:**
- Paket, ilk masal oluşturmada ana iş parçacığında yükleniyor (paketle gelen katalogdan sonra bir yükleme daha, ~0,2 sn);
  büyük paketlerde açılışta takılma olursa arka plana alınmalı.
- Yeni kurulumda geri sarma tabanı yok (saklanan akış yokken imzalı eski bir akış kabul edilir; TLS + imza gerektirir).
- Tek imza anahtarı; anahtar değişimi uygulama güncellemesi ister (birden çok açık anahtar ileride).
- `feed.json` ve `.sig` CDN'de ayrı önbelleklenir: 5 dk'lık pencerede imza uyuşmazlığı olursa akış reddedilir, sonraki çekişte düzelir.
- Arka plan yenilemesi gerçek cihazda denenmedi.

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
| `learning` modu blueprint'leri ve konuları; 3-4 bandı için en az bir `appeal` blueprint'i (bugün 3-4'te öğrenelim kurulamıyor) | 10 |
| 3-4 bandı için en az bir `threshold` ya da `absence` blueprint'i (bugün 3-4'te macera kurulamıyor) | 10 |
| Gerçek bir uyku arkı (bugün Uyku öncesi geçici olarak `charge` ailesine bağlı) | 10 |
| 7-8 ve 9-10 bantları için blueprint ve şablonlar (bugün yalnızca 3-4, 5-6 var) | 10 |
| İlişki türü varyantları (kardeş, arkadaş, hayvan, hayali varlık): pilot set FAZ 11'de (açılış + kapanış, hücre başına 2), gözden geçirme bekliyor | 11 |
| İlişki türü varyantı eksik blueprint'ler: bugün yok; yeni blueprint ya da aile anı eklenince `testEveryShippedBlueprintCarriesEveryRelation` listeler | 11 |
| **Masalın ortasındaki aile anları (FAZ 13'ten önce, öncelikli)** | 11 → 13 |
| `{{child.name}} de/da` gibi adla ünlü uyumuna uymayan eski satırlar | 11 (bulgu) |
| İlgi alanı etiketleri: taslak onayı; Deniz içeriğini taşıyan blueprint; 9 kelime için 3-4 ve 5-6 içeriği | 12 |
| `continuation` blueprint ailesi: pilot onaylı (bantta 2); mod başına continuation, 3-4 öğrenelim/macera, daha çok nesne | 13 |
| Kelime + anlam etiketleri, güvenlik etiketleri | 17 |
| Günün masalı ve eğitici hikâyeler (akış): `Content/DailyFeed/stories/`, yayın `docs/REMOTE_CONTENT.md`; bugün 12 eski masal var | 15 |

---

## Tasarım yasası borç turu ⏳ — design-system (İrem)

Ayrı bir turda, dosya sahibiyle. `CLAUDE.md` tasarım yasası kontrollerinin değiştirilen dosyalarda boş dönmesi
için eski isabetler temizlenir. İlk liste FAZ 10 kapanışından:

1. `DesignSystem/MPControls.swift` — 7 çıplak padding
2. `DesignSystem/MPNavigation.swift` — 8 çıplak padding
3. `Views/HomeView.swift` — 4 çıplak padding
4. `Views/SettingsView.swift` — 6 çıplak padding
5. iOS onay penceresi en büyük yazı boyutunda kelime bölüyor (FAZ 11)
6. `MPInput` odak dışında uzun değeri kısaltıyor (FAZ 11)

Her değer ya `MP.S`'teki en yakın token'a oturur ya da gerekçesiyle yeni bir token açılır. Görsel fark
ekran görüntüsüyle onaylanır. Repo geneli taban (4 Ekim 2026): padding 81, shadow 7, izinli iki dosya (`MPTheme.swift`, `MagicPaperCoverPalette.swift`) dışında `Color(hex:)` 59.

## Küçük işler

| İş | Tür | Nereden |
|---|---|---|
| Ebeveyn > Çocuklar > profil sayfasındaki "Profili düzenle" satırı profili düzenlemiyor, yeni profil ekleme ekranını açıyor (`Screens/MPSheets.swift`, `ProfileEditSheet`: `app.showProfileAdd = true`). Ad ve yaş düzenleme akışı yok; `ProfileManager.updateProfile` hiçbir ekrandan çağrılmıyor | Hata | FAZ 12 incelemesi |

## Açık sorular

- **Koyu tema** (karar: İrem): Uygulama koyu temayı destekleyecek mi, yoksa bilinçli olarak her zaman açık kâğıt mı?
  Bugün sistem koyu temadayken de uygulama açık kâğıtla açılıyor. FAZ 10'da tespit edildi, FAZ 10'un konusu değil.

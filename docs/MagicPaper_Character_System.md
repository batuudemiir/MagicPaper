# MagicPaper — Karakter Sistemi

> **Faz 9 durumu (3 Ekim 2026):** Bulut metin yolu kaldırıldı — `AIService`, `GeminiStoryAIProvider`,
> `createCustomStory` / `createCategoryBasedStory`, `TextStoryManager`, `TextStory`, `TextOnlyStory`, eski 4 adımlı
> sihirbaz (`StoryWizardView`, `StoryGeneratingView`, `MPAppState.startWizard`), `FirebaseTestView`, `LocalImageView`,
> `ImagePicker`, `Retired/`. Metin masal yalnızca `OfflineStoryService`. Görsel bulut kodu (`FalImageProvider`,
> `FalAIImageGenerator`, `FirebaseImageUploader`, `VisualSystem`) silinmedi: `StoryEngineBridge/CloudIllustrationPipeline.swift`
> içinde, `CloudIllustrationAccess` bayrağının arkasında (Release'te hep kapalı) ve çocuk akışından erişilemez.
> Bu belgede bu dosyalara verilen satır referansları tarihseldir. Ayrıntı: `MagicPaper_Faz_Plani_Ekim.md` → FAZ 9.

**Tarih:** 2026-09-18
**Agent:** character-system
**Kapsam:** `StoryEngine/Sources/CharacterEngine/**`, `StoryEngine/Tests/CharacterEngineTests/**`
**Salt okunan:** `Services/ProfileManager.swift`, `Services/StoryGenerationManager.swift`,
`StoryEngineBridge/**`, `Screens/StoryCreation/**`, `Views/ProfileCreationView.swift`

Bu tur: haritalama + eksik testlerin kapatılması + bir küçük uyumluluk düzeltmesi.
Karakter modeli **yeniden tasarlanmadı**.

---

## 0. Tek cümlelik özet

Character Engine eksiksiz, test edilmiş ve doğru tasarlanmış durumda —
ve **üretimde hiçbir kod yolu ona dokunmuyor**. Çocuğun kimliği bugün
`String` bir isimden ibaret.

---

## 1. İsim eşlemesi (agent metinleri ↔ kod)

| Rol tanımının aradığı | Koddaki gerçek karşılık |
|---|---|
| `ChildProfile` | `UserProfile` — `MagicPaper/Services/ProfileManager.swift:26` |
| `CharacterBible` | `CharacterProfile` + `CharacterVersion` + `CharacterIdentity` + `CharacterDescriptor` + `CharacterAssetSet` + `Resources/lexicons.json` |
| "photo processing" | **yok** (V1'de vision adımı yok; `CharacterExtractionPort` boş duruyor) |
| "character UI" | **yok** |

İstenen "Character Bible" zaten var ve istenenden fazlasını karşılıyor:
karakter kimliği, yaş, saç/göz/ten/beden tanımlayıcıları, kıyafet, ayırt edici
özellik, illüstrasyon stili, referans görsel, `doNotDepict` güvenlik listesi,
ve bunların **sürümlenmiş** hâli.

---

## 2. UserProfile ile CharacterProfile arasındaki boşluk

### 2.1 Alan karşılaştırması

| `UserProfile` (app) | `CharacterProfile` / `CharacterIdentity` (engine) | Durum |
|---|---|---|
| `id: UUID` | `CharacterID`, `ownerProfileID` | ✅ köprülenebilir |
| `name: String` | `displayName` | ✅ |
| `age: Int` | `identity.ageYears` | ✅ |
| `profileType` (child/parent) | — | engine'in umurunda değil |
| `imageFileName: String?` | `assetSet.masterReference.locator` | ⚠️ köprü var, kullanılmıyor |
| `createdAt` | `createdAt` | ✅ |
| **yok** | `pronouns` | ❌ app hiç toplamıyor |
| **yok** | `descriptors[]` (saç, göz, ten, beden, boy, ayırt edici özellik, kıyafet, aksesuar) | ❌ app hiç toplamıyor |
| **yok** | `identitySeed` | ❌ köprüde türetiliyor, saklanmıyor |
| **yok** | `doNotDepict[]` | ❌ app hiç toplamıyor |
| **yok** | `styleProfile` (illustrationStyleID, palettePresetID) | ❌ köprüde sabit değer |
| **yok** | `versions[]`, `activeVersionID` | ❌ |

Boşluk **veri modelinde değil, veri toplamada ve bağlantıda**.

### 2.2 Köprü ölü — TEYİT EDİLDİ

`MagicPaper/StoryEngineBridge/ProfileCharacterSource.swift` tüm projede
yalnızca **tek bir yerden** referans alınıyor:
`StoryEngineBridge/StoryEngineContainer.swift:26,61,113,123`.

`StoryEngineContainer` ise kendi dosyası dışında **hiçbir yerden** referans
alınmıyor:

```
$ grep -rl "ProfileCharacterSource\|StoryEngineContainer" --include="*.swift" .
MagicPaper/MagicPaper/StoryEngineBridge/StoryEngineContainer.swift
MagicPaper/MagicPaper/StoryEngineBridge/ProfileCharacterSource.swift
```

**Sonuç:** `ProfileCharacterSource` ölü. Onunla birlikte `FileCharacterStore`,
`FileStoryRepository`, `FileJobStore`, `StoryOrchestrator`, `CharacterBinder`,
`CharacterResolver` ve `StoryDataLifecycle.deleteCharacterReporting` de üretimde
erişilemez durumda. Hepsi derleniyor ve test ediliyor; hiçbiri çalışmıyor.

Bu ölü kod **silinmemeli**. D4 kararıyla ihtiyaç duyulacak parçaların tamamı
burada, çalışır ve test edilmiş hâlde duruyor.

---

## 3. "Parent bir kez girer, sonraki hikâyeler yeniden sormaz"

### 3.1 İz sürümü — canlı akış

```
ProfileCreationView.create()                 (Views/ProfileCreationView.swift:135)
  → ProfileManager.createProfile(name:age:profileType:image:)
      image parametresi VERİLMİYOR → nil
  → UserDefaults["user_profiles"] ← [UserProfile] JSON

StoryCreationFlow                            (Screens/StoryCreation/StoryCreationFlow.swift)
  profile = ProfileManager.shared.currentProfile     (:44)
  idea adımı  → yalnızca profile.age kullanılıyor    (:110)
  companion adımı
  → StoryGenerationManager.createStory(for:storyIdeaID:companionID:)   (:148)

StoryGenerationManager.createStory            (Services/StoryGenerationManager.swift:1450)
  → OfflineStoryService.shared.compose(childName: profile.name, ...)
                                              ^^^^^^^^^^^^^^^^^^^^^^^
  → OfflineStoryMapper.appStory(childName:childProfileID:)
  → recordBlueprintRead(_:for:)  → UserDefaults["read_history_<uuid>"]
```

### 3.2 Cevap

**Kısmen — ve yanıltıcı biçimde "evet" görünüyor.**

- ✅ Ebeveyne çocuk **bir kez** soruluyor. `StoryCreationFlow` çocuğu tekrar
  sormuyor; `currentProfile`'dan alıyor. İlke 8'e uyuyor.
- ✅ İsim ve yaş kalıcı; ikinci hikâyede tekrar istenmiyor.
- ❌ Ama **tekrar sorulmayan tek şey isim ve yaş, çünkü toplanan tek şey o.**
  Görünüş, zamir, stil, güvenlik dışlamaları hiç sorulmuyor — dolayısıyla
  "tekrar sormama" başarısı değil, veri yokluğu.
- ❌ `OfflineStoryIntent` yalnızca `childName: String` taşıyor. `profile.age`
  bile hikâye üretimine girmiyor; sadece hangi fikir kartlarının gösterileceğini
  seçiyor. Yaş bandı seçiliyor, hikâyeye geçmiyor.
- ❌ Canlı akışta `CharacterProfile` **hiç yaratılmıyor**. `CharacterID`,
  `CharacterVersion`, `identitySeed`, `descriptors` üretimde hiç var olmuyor.

### 3.3 İllüstrasyonlu yol (StoryWizardView → createCustomStory)

`Screens/StoryWizardView.swift:326` → `createCustomStory(...)`
`Services/StoryGenerationManager.swift:42`

Burada çocuk yeniden **seçiliyor** ama yeniden **sorulmuyor**:
`childID` açılışta `currentProfile`'dan ön-dolduruluyor
(`StoryWizardView.swift:106`) ve picker yalnızca birden fazla çocuk varsa
anlamlı. İlke 8 ihlali değil.

Ama bu yol da Character Engine'i kullanmıyor: referans görsel olarak
`MPAvatarRenderer.image(letter:color:)` ile **sentetik bir harf avatarı**
üretiliyor (`StoryWizardView.swift:333`) ve fal.ai'ye o gönderiliyor.

---

## 4. Kimlik kararlılığı

### 4.1 Kararlı olanlar

| Değer | Nasıl türetiliyor | Kararlı mı |
|---|---|---|
| `CharacterID` | `CharacterID(profile.id)` — app profil UUID'si | ✅ Aynı çocuk → aynı id, her cihazda, her yeniden kurulumda |
| `identitySeed` | `ProfileCharacterSource.seed(from: profile.id)` — UUID'nin ilk 8 baytı | ✅ Deterministik, saf fonksiyon |
| `ownerProfileID` | `profile.id` | ✅ |

`ProfileCharacterSource.seed` doğru yazılmış: rastgelelik yok, tarih yok,
yalnızca UUID'den türetiliyor. **Bu tasarım kararı korunmalı.**

### 4.2 Kararlı OLMAYANLAR — ve neden önemli

| Değer | Davranış |
|---|---|
| `CharacterVersionID` | Her `CharacterVersion()` çağrısında **taze UUID** |
| `CharacterAsset.id` | Her `CharacterAsset()` çağrısında **taze UUID** |

Yeni test bunu açıkça sabitliyor
(`CharacterIdentityStabilityTests.testVersionIdentifiersAreNotDerivedFromContent`):
birebir aynı girdiden üretilen iki `CharacterVersion` **eşit bile değil**.

Bu bir hata değil, kasıtlı: sürüm kimliği içeriğin fonksiyonu olsaydı,
aynı görünüme dönen bir çocuk eski sürüme çarpar ve tarih çökerdi.
Ama **migration için ölümcül bir tuzak**: bkz. §6.3.

### 4.3 CharacterVersionResolver ne zaman yeni sürüm üretiyor

`CharacterVersionResolver` **hiçbir zaman sürüm üretmiyor** — yalnızca seçiyor:

1. `versionID` pinlenmişse → tam o sürüm, yoksa `versionNotFound` hatası.
   Sessizce başka bir çocuğa düşmüyor. Doğru davranış.
2. Pin yoksa ve `activeVersion` kullanılabilirse (`assetSet.isUsable`) → o.
3. Aksi hâlde → en yüksek numaralı kullanılabilir sürüm.
4. Hiçbiri yoksa → `noUsableVersion`.

Sürüm **üretimi** tek bir yerde: `ProfileCharacterSource.updating(...)`
→ `CharacterProfile.appending(_:)`. Tetikleyicisi
`StoryEngineContainer.ensureCharacter(...)`:

```swift
guard referenceLocator != nil || !descriptors.isEmpty else { return existing.id }
```

Yani yeni sürüm yalnızca yeni bir referans görsel veya yeni tanımlayıcı
geldiğinde açılıyor. İsim veya yaş değişikliği sürüm açmıyor —
**`updateProfile` ile yaşı değiştirilen çocuğun `identity.ageYears`'ı
güncellenmiyor.** (Bugün etkisi yok, çünkü köprü ölü. İkinci dalgada
`ProfileManager` ↔ `CharacterEngine` bağlanınca bu bir bug olacak.)

### 4.4 Sürüm artışı görsel kimliği bozar mı?

**Hayır — üç koruma var:**

1. `appending` eski sürümleri hiç yeniden yazmıyor; ekliyor.
2. `updating(...)` `identitySeed`'i ileri taşıyor
   (`ProfileCharacterSource.swift:90,100`), stil profilini aynen kopyalıyor,
   `referenceLocator` nil ise eski master referansı koruyor.
3. Hikâye `versionID`'yi pinliyor (`CastBinding.Member.versionID`), pin
   `CharacterVersionResolver` tarafından harfiyen uygulanıyor.

Yeni testler bu üçünü de sabitliyor.

**Tek gerçek risk:** `updating(...)` `descriptors` parametresini **tamamen
değiştiriyor**, birleştirmiyor. Boş dizi geçilirse çocuğun tüm görünüş
tanımı silinmiş bir sürüm açılır. `ensureCharacter` bunu bir koruma ile
engelliyor (`descriptors.isEmpty ? existing... : descriptors`), ama koruma
çağıranın tarafında, modelin tarafında değil. İkinci dalgada
`ProfileCharacterSource` yeniden canlandırılırken bu korunmalı.

---

## 5. Gizlilik — karakter tarafı tespiti

> Ayrıntılı analiz `docs/MagicPaper_Privacy_Architecture.md`'de (privacy-safety
> agent). Burada yalnızca karakter/profil ekseni ve **bir düzeltme** var.

### 5.1 Çocuk fotoğrafı bugün nerede

**Üretim akışında hiç toplanmıyor.**

- `ProfileCreationView` fotoğraf kontrolü içermiyor ve ekranda şunu yazıyor:
  "MagicPaper çocuk fotoğrafı istemez ve saklamaz — sadece bir isim ve avatar
  rengi." (`Views/ProfileCreationView.swift:127`)
- `createProfile(...)` çağrısı `image:` argümanını geçmiyor
  (`ProfileCreationView.swift:138`) → `nil`.
- `ImagePicker` yalnızca `FalAITestView` ve `FirebaseTestView` tarafından
  kullanılıyor; **ikisi de hiçbir yerden referans alınmıyor** (yalnızca
  `#Preview`). Erişilemez.

### 5.2 Düzeltme — privacy dokümanına not

`MagicPaper_Privacy_Architecture.md` §2.4 "Ham fotoğraf. İki ayrı servise"
diyor. **Bugünkü erişilebilir kod yollarında bu doğru değil.**

`createCustomStory`'nin tek çağıranı `StoryWizardView:344` ve gönderdiği
`image:` şu:

```swift
let reference = MPAvatarRenderer.image(
    letter: String(profile.name.prefix(1)).uppercased(with: Locale(identifier: "tr_TR")),
    color: UIColor(profile.mpColor)
)
```

Yani Firebase `child_uploads/<UUID>.jpg` yoluna giden şey **512×512 bir harf
avatarı**, çocuğun yüzü değil. `createCategoryBasedStory`'nin ise **hiç çağıranı
yok**.

Bu, bulguyu hafifletmiyor ama sıralamasını değiştiriyor:
- Boru hattı (`saveProfileImage`, `FirebaseImageUploader`, silme yolunun
  yokluğu) **canlı kullanıcı verisi olmadan** temizlenebilir. Bu bir fırsat
  penceresi, acil bir sızıntı değil.
- `child_uploads/` yol adı yanıltıcı; içindekiler çocuk fotoğrafı değil.
  Yine de bucket adı keşif bilgisi ve URL'in log'a basılması gereksiz.

### 5.3 ProfileManager'daki 20 `print()` — sınıflandırma

**SALT TESPİT. Temizlik privacy-safety agent'ında.**

| Satırlar | İçerik | Çocuk verisi? |
|---|---|---|
| 238, 270 | `"...: \(fileName)"` → `profile_<UUID>.jpg` | ⚠️ **Evet** — profil UUID'si. Takma-adlı tanımlayıcı; cihaz log'unda kalıcı ve `read_history_<UUID>`, `mp_avatarColor_<UUID>` anahtarlarıyla birleştirilebilir. |
| 135, 206 | `profileType.displayName` → "Çocuk" / "Ebeveyn" | ⚠️ Zayıf — evde çocuk profili olduğunu söylüyor, kimliğini değil. |
| 73, 97 | `profiles.count` | ⚠️ Zayıf — kaç çocuk olduğu. |
| 100, 240, 272 | `\(error)` | ⚠️ Dolaylı — `NSError.userInfo` dosya yolunu taşıyabilir, yol UUID içerir. |
| 59, 80, 83, 87, 106, 161, 175, 198, 214, 298, 315 | Sabit metin | ✅ Temiz |

**Hiçbir `print()` çocuğun adını veya yaşını basmıyor.** ProfileManager bu
açıdan temiz.

**Buna karşılık — kilitli dosyada, raporlanıyor:**

```
Services/StoryGenerationManager.swift:347   print("🎬 Child: \(childName), Age: \(age)")
Services/StoryGenerationManager.swift:444   print("🎬 Child: \(childName), Age: \(age)")
```

Bu **çocuğun adını ve yaşını** doğrudan konsola basıyor. `:347` canlı
illüstrasyonlu yolda (`createCustomStory`). İlke 10'un doğrudan ihlali ve
ProfileManager'ın 20 satırının tamamından daha ağır.

### 5.4 Saklama süresi

| Veri | Yer | Süre | Silen kod |
|---|---|---|---|
| `UserProfile` (ad, yaş) | `UserDefaults["user_profiles"]` | Süresiz | `deleteProfile` |
| `profile_<UUID>.jpg` | `Documents/` | Süresiz | `deleteProfileImage` ✅ |
| `read_history_<UUID>` | `UserDefaults` | Son 40 kayıt | `deleteProfile` ✅ |
| `mp_avatarColor_<UUID>` | `UserDefaults` | Süresiz | `deleteProfile` ✅ |
| `CharacterProfile` | `Documents/StoryEngine/Characters/` | — | **Hiç yazılmıyor** (köprü ölü) |
| `child_uploads/<UUID>.jpg` | Firebase Storage | **Süresiz, silen kod yok** | ❌ |

Engine tarafında doğru silme zaten yazılmış:
`StoryDataLifecycle.deleteCharacterReporting` sürümlerdeki **tüm** varlık
konumlarını (master, fullBody, face, expression) toplayıp siliyor ve
silinemeyeni sessizce yutmak yerine `externalAssetLocators` /
`failedAssetLocators` olarak raporluyor. Üretimde erişilemez.

---

## 6. D4 — persistence kararının karakter tarafı

### 6.1 `CharacterStore` protokolü FileStores ile karşılanıyor mu?

**Evet, bugün, değişiklik gerekmeden.**
`MagicPaper/StoryEngineBridge/FileStores.swift:125` `FileCharacterStore`
protokolü tam olarak uyguluyor: kayıt başına bir JSON,
`Documents/StoryEngine/Characters/<CharacterID>.json`, atomik yazma.

Protokolde **değişiklik gerekmiyor.** `CharacterStore` zaten doğru soyutlama
düzeyinde: `profile(id:)`, `save(_:)`, `allProfiles(ownedBy:)`, `delete(id:)`.

### 6.2 Ama `FileCharacterStore`'da üç sessizlik var — app katmanı, RAPOR

`FileStores.swift` benim yazma alanımda değil. Üçü de karakter kimliği için
kritik:

1. **`FileBackedStore.save` sessizce başarılı olabiliyor** (`:58`):
   ```swift
   guard let url = directory?.appendingPathComponent(...) else { return }
   ```
   Documents erişilemezse kaydetme *başarılı görünür*. Hikâye için kötü,
   karakter kimliği için felaket.

2. **`FileBackedStore.load` çözümlenemeyen dosyayı `nil` yapıyor** (`:54`):
   `try? decoder.decode(...)`. Çağıran taraf bunu "bu çocuğun karakteri yok"
   diye okur ve **yeni bir `CharacterVersionID` basar**. Çocuk yeni
   hikâyelerde kendine benzemez olur, eski kitaplar eski sürüme pinli kalır.

3. **`loadAll()` bozuk dosyayı atlıyor** (`:76`): hikâye için doğru ödünleşme
   (bir bozuk kitap kütüphaneyi gizlememeli), **karakter için değil**.

**Öneri (karar lead agent'ın):** karakter deposu için `load` ve `save`
hata fırlatmalı; `CharacterStore` protokolü `async throws` olduğu için imza
zaten uygun.

### 6.3 Migration planı — UserProfile → FileStores

**Kesin kural — bunu başa yazıyorum:**

> Migration `CharacterVersion` veya `CharacterAsset` **yeniden inşa etmemeli**.
> Kopyalamalı. Yeniden inşa edilen sürüm taze bir `CharacterVersionID` alır ve
> o sürüme pinli her kitap `versionNotFound` ile çözülemez hâle gelir.
> `CharacterIdentityStabilityTests.testVersionIdentifiersAreNotDerivedFromContent`
> bunu testle sabitliyor.

Bugün pinli kitap yok (köprü ölü), yani **risk bugün sıfır ve yarın yüksek**.
Migration'ı köprü canlanmadan *önce* yapmak, sonra yapmaktan çok daha ucuz.

#### Sıra

**Adım 0 — hazırlık (bu tur yapıldı)**
CharacterEngine artık eksik alanlara toleranslı çözümlüyor (§7.2). Bir sonraki
şema eklemesi mevcut kayıtları okunamaz hâle getirmeyecek.

**Adım 1 — çift yazma, tek okuma**
`ProfileFileStore` (yeni, `Documents/StoryEngine/Profiles/<UUID>.json`) eklenir.
`ProfileManager` hem UserDefaults'a hem dosyaya yazar; **okumayı hâlâ
UserDefaults'tan** yapar. Geri alınabilir: dosyaları silmek yeter.

**Adım 2 — migration + doğrulama**
Açılışta bir kez: UserDefaults'ta olup dosyada olmayan her profil dosyaya
yazılır. Ardından **sayı ve alan karşılaştırması** yapılır. Eşleşmezse
migration `mp_profile_migration_state = failed` yazıp UserDefaults'ta kalır.
`UserDefaults["user_profiles"]` **silinmez.**

**Adım 3 — okumayı çevir**
`loadProfiles()` dosyalardan okur. UserDefaults kopyası **en az iki sürüm
boyunca yazılmaya devam eder** — geri dönüş yolu budur.

**Adım 4 — karakter üretimi**
Ancak profiller dosyada güvenli oturduktan sonra: her `UserProfile` için
`ProfileCharacterSource.makeProfile(...)` ile **bir kez** `CharacterProfile`
üretilir ve `FileCharacterStore`'a yazılır.
`CharacterID(profile.id)` ve `seed(from: profile.id)` deterministik olduğu
için bu işlem **idempotent**: iki kez çalışırsa aynı id ve aynı seed çıkar.
Yalnızca `CharacterVersionID` ve `CharacterAsset.id` farklı olur — bu yüzden
**var olan bir karakter dosyası asla üzerine yazılmamalı**:

```
if try await store.profile(id: CharacterID(profile.id)) != nil { skip }
```

**Adım 5 — UserDefaults temizliği**
Yalnızca §Adım 3'ten iki sürüm sonra, ve yalnızca migration `succeeded`
işaretliyse.

#### Geri alınabilirlik

| Adım | Geri alınabilir mi | Nasıl |
|---|---|---|
| 1 | ✅ Tam | Dosyaları sil |
| 2 | ✅ Tam | UserDefaults dokunulmamış |
| 3 | ✅ Tam | Okuma kaynağını geri çevir; UserDefaults hâlâ güncel |
| 4 | ⚠️ Kısmi | Karakter dosyaları silinebilir ama `CharacterVersionID`'ler yeniden üretilince değişir |
| 5 | ❌ Yok | Bu yüzden en sona ve gecikmeli |

#### Fotoğraflar

`profile_<UUID>.jpg` **taşınmamalı**. Dosya adı profil UUID'sinden
türetiliyor ve `imageFileName` alanı onu adıyla tutuyor; taşımak hiçbir şey
kazandırmaz, `getProfileImage` yolunu kırma riski taşır. `Documents/` kökünde
kalsın.

---

## 7. Bu turda yapılan değişiklikler

### 7.1 Yeni testler

| Dosya | Test sayısı | Kapsam |
|---|---|---|
| `Tests/CharacterEngineTests/CharacterStoreTests.swift` | 10 | yaratma, saklama, yeniden yükleme, güncelleme, silme, iki kez silme, sahiplik kapsamı, sıralama |
| `Tests/CharacterEngineTests/CharacterIdentityStabilityTests.swift` | 7 | kimlik kararlılığı, pin dokunulmazlığı, seed taşınması, sürüm id'lerinin içerikten türetilmediği |
| `Tests/CharacterEngineTests/CharacterCompatibilityTests.swift` | 7 | eksik opsiyonel alanlar, eski kayıt okunabilirliği |

Rol tanımının test listesindeki **yedi maddenin tamamı** artık kapsanıyor.
Önceki durum: yaratma ✅, kalıcılık ❌, yeniden yükleme ❌, güncelleme kısmen,
silme ❌, eksik opsiyonel alanlar ❌, kimlik kararlılığı ❌.

### 7.2 Kaynak değişikliği — toleranslı çözümleme

Dört tipe özel `init(from:)` eklendi. Sebep §6.2/2: çözümlenemeyen bir karakter
dosyası sessizce `nil` olur ve çocuğun kimliği yeniden basılır.

| Dosya | Alan | Eksikse |
|---|---|---|
| `Domain/CharacterIdentity.swift` | `descriptors`, `doNotDepict` | `[]` |
| `Domain/CharacterAssetSet.swift` | `expressionReferences` | `[:]` |
| `Domain/CharacterStyleProfile.swift` | `renderingNotes`, `negativeTraits` | `[]` |
| `Domain/CharacterProfile.swift` | `schemaVersion` | `1` |

`identitySeed` **kasten dışarıda**: onun dürüst bir varsayılanı yok.
Eksikse çözümleme hata veriyor, ve bunu bir test sabitliyor.

Kodlama (`encode`) tarafı değişmedi; tüm alanlar yazılmaya devam ediyor.
Mevcut round-trip testleri etkilenmedi.

---

## 8. Sıradaki iş (bu turda YAPILMADI)

1. **`ProfileManager` ↔ `CharacterEngine` bağlantısı** — parent-ux ikinci
   dalgada `ProfileManager`'ı sahiplenecek. `createProfile` / `updateProfile` /
   `deleteProfile` karşılık gelen `CharacterProfile` işlemlerini tetiklemeli.
   `updateProfile(age:)` bugün `identity.ageYears`'ı güncellemiyor (§4.3).
2. **`OfflineStoryIntent`'e yaş ve zamir** — story-engine agent'ının alanı.
   Bugün yaş hikâyeye hiç girmiyor.
3. **Tanımlayıcı toplama UI'ı** — "saçı nasıl?" gibi 3-4 soru. İlke 7 gereği
   sakin ve atlanabilir olmalı; `DescriptorLexicon` zaten kelime dağarcığını
   tutuyor.
4. **`FileCharacterStore` sessizlikleri** (§6.2) — app katmanı.

---

## 9. D1 / D2 bağımlılığı

- **D1** (`createCustomStory` emekliye ayrılıyor): karakter tarafında
  bağımlılık **yok**. O yol Character Engine'i hiç kullanmıyor; sentetik
  avatar üretiyor. Emekliye ayrılması karakter sistemini etkilemez —
  aksine `StoryGenerationManager.swift:347`'deki ad+yaş `print()`'ini de
  götürür.
- **D2** (`MPStreak` kaldırılıyor): karakter tarafında bağımlılık **yok**.
- `createCategoryBasedStory` (`:111`) zaten **çağıransız**. D1 kapsamına
  alınabilir.

---

# Dalga 2A — köprü sağlamlaştırma

**Tarih:** 2026-09-22
**Agent:** character-system
**Kapsam:** `StoryEngine/Sources/CharacterEngine/**`, `StoryEngine/Tests/CharacterEngineTests/**`,
`Services/ProfileManager.swift`, `StoryEngineBridge/ProfileCharacterSource.swift`,
`MagicPaperTests/ProfileCharacterSourceTests.swift`
**Salt okunan:** `StoryEngineBridge/StoryEngineContainer.swift`, `FileStores.swift`

Köprü hâlâ **canlı değil** — `StoryEngineContainer`'ın tüketicisi 2B'de bağlanacak.
Bu tur köprüyü *doğru* yaptı, *açmadı*.

---

## 10. `updateProfile(age:)` — kapatıldı

### 10.1 Hata neredeydi

`ProfileManager.updateProfile` `UserProfile.age`'i yazıyor ve duruyordu.
`ProfileCharacterSource.updating(...)` ise `current.identity.ageYears`'ı
**koşulsuz ileri taşıyordu** — yaşı değiştirmenin bir yolu yoktu. Yani:

- ebeveynin gördüğü yaş: `UserProfile.age`
- her illüstrasyon isteğinin koşullandığı yaş: `CharacterIdentity.ageYears`

İkisi ayrışıyordu. Altı yaşına giren çocuk, uygulamadaki ömrü boyunca beş
yaşında çizilmeye devam ederdi. Bu İlke 5'in tersten ihlali: "her sayfada
yeniden tanımlama" değil, **hiç güncellememe**.

Aynı boşluk **ad** için de vardı: `displayName` `CharacterProfile` üzerinde
`let` ve `appending(_:)` onu aynen kopyalıyor. Yeniden adlandırmanın da yolu
yoktu.

### 10.2 Karar — yaş sürüm açar, ad açmaz

| Değişiklik | Davranış | Gerekçe |
|---|---|---|
| **Yaş** | Yeni `CharacterVersion` eklenir | Yaş bir **görünüş olgusu**. Çocuk beş yaşındayken çizilen kitap beş yaşındaki çocuğu göstermeye devam etmeli. Sürüm eklemek pinlenmiş kitapları korur. |
| **Ad** | `CharacterProfile.renamed(to:)`, sürüm açılmaz | Ad görünüş olgusu **değil**; hiçbir illüstrasyon iki sürümü birbirinden ayırt edemez. Sürüm açmak geçmişi ayırt edilemez kayıtlarla kirletir. Saklanan hikâyeler üretilmiş metni tuttuğu için (K1) eski kitaplar eski adı korur. |

### 10.3 Kural çağırandan modele taşındı

Grup 1 raporu §4.4'teki "tek gerçek risk" buydu: `updating(...)` `descriptors`
parametresini **tamamen değiştiriyordu**, ve boş dizi geçilmesine karşı tek
koruma `StoryEngineContainer.ensureCharacter`'ın içindeydi — yani *çağıranın*
tarafında. Yeni bir çağıran o korumayı yeniden keşfetmek zorundaydı.

Artık `CharacterVersion.next(...)` var ve sözleşmesi şu:

- **Atlanan parametre = değişmedi.** `descriptors: nil` mevcut tanımlayıcıları
  korur. Silmek için `descriptors: []` **açıkça** yazılmalı — bu diff'te bir
  karar gibi okunur, bir unutkanlık gibi değil.
- **`identitySeed` parametre değil.** İleri taşınması opsiyonel değil, mümkün
  değil. Seed'i değiştirmenin tek yolu sıfırdan `CharacterVersion` kurmaktır.
- **`masterReference: nil` mevcut referansı korur**, silmez. `isUsable` tam
  olarak o alana bakıyor; atlama yoluyla düşürmek çocuğu kendi kitabından
  çıkarırdı.

`ProfileCharacterSource.updating(...)` bunun üzerine yeniden yazıldı ve
`syncing(_:with:)` eklendi — ad + yaşı tek çağrıda uzlaştırır, **idempotenttir**
(değişmemiş bir profil sürüm açmaz), dolayısıyla her profil kaydında güvenle
çağrılabilir.

**Bağlama noktası:** `ProfileManager.updateProfile` bu turda `syncing`'i
**çağırmıyor**. Çağırabilmesi için bir `CharacterStore` örneğine ihtiyacı var;
tek uygulama `FileCharacterStore` ve onun yaşam döngüsü D4'te. Bugün ortada
bayatlayacak `CharacterProfile` yok, dolayısıyla açık bir hata da yok.
Doküman yorumu `updateProfile`'ın üzerinde duruyor.

---

## 11. `CharacterVersionID` — karar: **taze UUID kalıyor**

Görev sorusu: "deterministik bir versiyon kimliği üretimi mümkün mü, yoksa
kopyalama tek yol mu?"

### 11.1 Mümkün — ama yanlış

`CharacterVersionID`'yi `(CharacterID, versionNumber)`'dan türetmek teknik
olarak mümkün (UUIDv5 tarzı). Reddedildi, üç sebeple:

1. **Göçe hiçbir faydası yok.** Deterministik türetme yalnızca *değişiklikten
   sonra* yazılan kayıtlar için çalışır. Var olan bir kayıttaki taze UUID'yi
   geri hesaplamak imkânsız — o kayıt için tek doğru davranış zaten kopyalamak.
2. **Yeni ve daha kötü bir çarpışma açar.** İki ayrı kod yolu aynı karakter için
   "sürüm 2" üretirse **aynı id'yi farklı içerikle** alır. Pinlenmiş bir kitap
   sessizce başka bir görünüme çözülür. Taze UUID bu çarpışmayı imkânsız kılar.
3. **Bugün göçecek karakter yok.** Köprü ölü; `Documents/StoryEngine/Characters/`
   boş. D4 `UserProfile` göçüdür; karakterler §6.3 Adım 4'te **üretilir**,
   göç etmez, ve o üretim `CharacterID(profile.id)` + `seed(from:)` deterministik
   olduğu için zaten idempotenttir.

**Sonuç: kopyalama tek yol.** Mevcut davranış bozulmadı;
`testVersionIdentifiersAreNotDerivedFromContent` yerinde duruyor.

### 11.2 Ama kural artık *doğrulanabilir*

Kuralı dokümanda bırakmak yetmiyordu. `CharacterVersion` id'sini de kapsayacak
şekilde `Equatable`, yani yeniden inşa edilmiş bir sürüm orijinaline eşit değil —
**ama meşru bir düzenleme de değil.** İkisini ayırt edecek bir şey yoktu.

Eklendi (`Domain/CharacterCopyVerification.swift`, ikisi de additive):

| API | Ne yapar |
|---|---|
| `CharacterVersion.contentFingerprint` | Kimlikleri ve tarihleri **dışarıda bırakan**, `StableHash` tabanlı deterministik içerik özeti. Tanımlayıcı sırasından bağımsız. |
| `CharacterProfile.copyDefects(from:)` | Bir profilin başka bir profilin *taşınmış* hâli mi yoksa *yeniden yapılmış* hâli mi olduğunu söyler. Tüm kusurları döndürür, ilkini değil. |
| `CharacterProfile.preservesVersionIdentity(of:)` | Yalnızca dallanan çağıran için kısayol. |

`CharacterCopyDefect` beş vakayı **ayrı ayrı** raporluyor, çünkü düzeltmeleri
farklı: `rebuiltVersion` (aynı içerik, yeni id — asıl tuzak), `missingVersion`,
`rewrittenVersion` (aynı id, değişmiş içerik — append-only ihlali),
`characterIDChanged`, `danglingActiveVersion`.

**library-memory için:** D4 göçü yazdıktan sonra, `succeeded` işaretlemeden
önce şunu doğrulayabilir:

```swift
let defects = migrated.copyDefects(from: original)
guard defects.isEmpty else { /* göçü failed işaretle, kaynağı silme */ }
```

Sürüm eklemek kusur **değildir** — göç sırasında çocuğu ileri taşıyan bir adım
(ad, yaş) eski sürümlere dokunmadığı sürece sadık sayılır.

---

## 12. Profil göçü karakter kimliğini nasıl koruyacak

§6.3'teki beş adımlı sıra geçerliliğini koruyor. Bu tur netleşen üç şey:

### 12.1 `user_profiles` göçü karakter kimliğini **doğrudan** etkilemez

`CharacterID` ve `identitySeed`'in tek girdisi `UserProfile.id`. Göç yalnızca
`[UserProfile]` blob'unu `UserDefaults`'tan dosyalara taşıyor; `id` alanına
dokunmadığı sürece karakter kimliği tanım gereği korunur.

**Bu yüzden göçün tek karakter-kritik değişmezi şudur:**

> Göç `UserProfile.id`'yi **asla yeniden üretmemeli**. `UserProfile.init`
> varsayılan olarak taze bir UUID basar (`ProfileManager.swift:35`). Göç yolunda
> `UserProfile(...)` çağırmak — alanları tek tek kopyalamak — çocuğun profilini
> yeni bir kimliğe taşır ve onunla birlikte `CharacterID`'yi, `identitySeed`'i,
> `read_history_<UUID>`'yi ve `profile_<UUID>.jpg`'yi koparır. Göç **decode
> edilen değeri olduğu gibi yazmalı**, yeniden kurmamalı.

Bu, karakter tarafındaki "kopyala, yeniden inşa etme" kuralının profil
tarafındaki tam karşılığı ve aynı sebepten doğuyor: kimlik alanı varsayılanı
taze UUID olan bir initializer.

### 12.2 Doğrulama adımı neye bakmalı

§6.3 Adım 2 "sayı ve alan karşılaştırması" diyordu. Karakter açısından
yeterli kesinlik:

| Kontrol | Neden |
|---|---|
| Kaynak ve hedefteki `id` **kümeleri** birebir aynı | Kimlik kopması bu turda yakalanır |
| Profil **sayıları** eşit | Sessiz kayıp |
| `name`, `age`, `imageFileName`, `createdAt` her `id` için eşit | Alan kaybı |

`id` kümesi eşleşmiyorsa göç `failed` işaretlenmeli ve `UserDefaults["user_profiles"]`
**kesinlikle silinmemeli**.

### 12.3 Karakter üretimi (Adım 4) sırası

Karakterler ancak profiller dosyada güvenle oturduktan sonra üretilmeli, ve
üretim şu iki kurala uymalı:

1. **Var olan karakter dosyasının üzerine asla yazma.**
   `if try await store.profile(id: CharacterID(profile.id)) != nil { skip }` —
   çünkü `CharacterID` ve `seed` idempotent olsa da `CharacterVersionID` ve
   `CharacterAsset.id` değil; üzerine yazmak pinleri koparır.
2. **Yaşı profilden al, sonra bir daha `makeProfile` çağırma.** Var olan bir
   karakteri profille uzlaştırmanın yolu `ProfileCharacterSource.syncing(_:with:)`
   (§10.3); `makeProfile` yalnızca hiç karakteri olmayan çocuk için.

`FileCharacterStore`'un §6.2'deki üç sessizliği **hâlâ açık** ve hâlâ app
katmanında. Özellikle 2 numaralı sessizlik (çözümlenemeyen dosya → `nil`)
Adım 4'ün "var mı?" kontrolünü yanlış cevaplatıp üzerine yazdırabilir.
Bu, D4'ün kapatması gereken karakter-kritik tek `FileStores` maddesidir.

---

## 13. Gizlilik — `ProfileManager` `print()` temizliği

§5.3'te sınıflandırılan 20 `print()` **kaldırıldı**; yerine tek bir
`os.Logger` (`subsystem: bundle id`, `category: "profiles"`) geçti.

| Eski satır | Yeni davranış |
|---|---|
| `:238`, `:270` — `profile_<UUID>.jpg` dosya adı | Dosya adı interpolasyonu **tamamen kaldırıldı** |
| `:100`, `:240`, `:272` — `\(error)` | `NSError.domain` + `code`; `userInfo` (dolayısıyla `NSFilePath`) basılmıyor |
| `:135`, `:206` — `profileType.displayName` | Interpolasyon kaldırıldı |
| `:73`, `:97` — `profiles.count` | `privacy: .private` |
| Sabit metinler | `Logger.debug` |

İki ek not:

- `saveProfiles`'taki `assertionFailure("...\(error)")` de düzeltildi:
  `EncodingError.invalidValue` **değeri taşır**, ki burada o değer çocuğun adı olur.
- `print` cihazda paylaşılan konsola yazar — uygulama kapandıktan sonra da
  okunabilir ve tanı paketlerine girer. `Logger` en azından `.private`
  interpolasyonu redakte eder. Gerekçe P2 sınıfı için yeterli; hiçbir satır
  artık ad, yaş veya dosya adı basmıyor.

`StoryGenerationManager.swift:347/:444`'teki ad+yaş basan iki satır **hâlâ
duruyor** — o dosya library-memory'nin (D4). §5.3'teki tespit geçerli.

---

## 14. Bu turda yapılan değişiklikler

### 14.1 Kaynak

| Dosya | Değişiklik |
|---|---|
| `Domain/CharacterVersionSuccession.swift` | **YENİ** — `CharacterAssetSet.adoptingMasterReference(_:)`, `CharacterVersion.next(...)`, `CharacterProfile.renamed(to:)` |
| `Domain/CharacterCopyVerification.swift` | **YENİ** — `contentFingerprint`, `CharacterCopyDefect`, `copyDefects(from:)`, `preservesVersionIdentity(of:)` |
| `StoryEngineBridge/ProfileCharacterSource.swift` | `updating(...)` yeniden yazıldı (tüm parametreler opsiyonel, `nil` = değişmedi); `syncing(_:with:)` eklendi |
| `Services/ProfileManager.swift` | 20 `print()` → `os.Logger`; `updateProfile` üzerine bağlama notu |

Mevcut hiçbir tip, alan veya kodlama biçimi değişmedi. Eklemeler additive;
`CharacterProfile` JSON şeması **aynı** (`schemaVersion` hâlâ 1).

### 14.2 Testler

| Dosya | Test sayısı | Kapsam |
|---|---|---|
| `Tests/CharacterEngineTests/CharacterVersionSuccessionTests.swift` | 11 | yaş değişimi, eski sürümün korunması, atlamanın silme olmaması, seed'in her düzenlemede hayatta kalması, yeniden adlandırma |
| `Tests/CharacterEngineTests/CharacterCopyVerificationTests.swift` | 12 | parmak izi kararlılığı/sıra bağımsızlığı, kopya doğrulama, beş kusur vakası |
| `MagicPaperTests/ProfileCharacterSourceTests.swift` | 19 | determinizm, profil→karakter eşlemesi, eksik opsiyonel alanlar, yaş/ad senkronu, idempotans, depo gidiş-dönüşü, silme |

## 15. Masal ailem (FAZ 11, 4 Ekim 2026)

Çocuğun tekrar eden karakterleri:
- **Model:** `FamilyCharacter { id, childID, name, relation, createdAt, schemaVersion }`. `relation`: kardeş, arkadaş, hayvan(tür) ya da hayali arkadaş. Cinsiyet yok.
- **Depo:** `Documents/StoryEngine/FamilyCharacters/<çocukUUID>.json`, çocuk başına tek dosya, kayıplı okuma, en fazla 8 karakter.
- **Bilinçli ayrım:** `CharacterProfile` (Character Bible) kullanılmadı. Masal ailem karakterinin görsel kimliği yok, yalnızca metinde adı ve ilişkisi var. Görselli masal açıldığında bir Masal ailem karakterine görsel kimlik verilecekse `CharacterProfile`'a bağlanması o fazın kararıdır.
- **Silme:** `ProfileManager.deleteProfile` ve "Tüm verileri sil" bu klasörü de siler.
- **Masala kopyalanan:** adın o günkü hâli metne girer. Kökende yalnızca kimlik ve ilişki türü tutulur. Karakter silinse ya da adı değişse de kayıtlı masal değişmez.
- **Senkron (FAZ 16):** kimlik ve `createdAt` sabit. Kayıplı okuma, daha yeni bir sürümün yazdığı kaydı atlar; eski sürümde düzenleme yapılırsa o kayıt kaybolur.

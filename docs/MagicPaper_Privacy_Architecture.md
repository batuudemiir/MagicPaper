# MagicPaper — Gizlilik Mimarisi

> **Faz 9 durumu (3 Ekim 2026):** Bulut metin yolu kaldırıldı — `AIService`, `GeminiStoryAIProvider`,
> `createCustomStory` / `createCategoryBasedStory`, `TextStoryManager`, `TextStory`, `TextOnlyStory`, eski 4 adımlı
> sihirbaz (`StoryWizardView`, `StoryGeneratingView`, `MPAppState.startWizard`), `FirebaseTestView`, `LocalImageView`,
> `ImagePicker`, `Retired/`. Metin masal yalnızca `OfflineStoryService`. Görsel bulut kodu (`FalImageProvider`,
> `FalAIImageGenerator`, `FirebaseImageUploader`, `VisualSystem`) silinmedi: `StoryEngineBridge/CloudIllustrationPipeline.swift`
> içinde, `CloudIllustrationAccess` bayrağının arkasında (Release'te hep kapalı) ve çocuk akışından erişilemez.
> Bu belgede bu dosyalara verilen satır referansları tarihseldir. Ayrıntı: `MagicPaper_Faz_Plani_Ekim.md` → FAZ 9.

**Tarih:** 2026-09-18
**Rol:** privacy-safety agent
**Kapsam:** Salt inceleme. Bu turda hiçbir `.swift` dosyası değiştirilmedi.
**Ölçüm tabanı:** `MagicPaper/MagicPaper/**` (uygulama hedefi) + `StoryEngine/Sources/**`
(paket kaynakları). Testler hariç.

> Bu teknik bir dokümandır. Hukuki uyum iddiası içermez. "Şu mevzuata uygundur"
> cümlesi burada hiçbir yerde geçmez ve geçmemelidir.

---

## 0. Doğrulanan ölçümler

| İddia | Ölçüm | Durum |
|---|---|---|
| `print()` toplam 441 | 430 (uygulama hedefi) + 11 (StoryEngine/Sources) = **441** | ✅ Doğru |
| `os.Logger` / `os_log` = 0 | `import os`, `Logger(`, `os_log` → **0 eşleşme** | ✅ Doğru |
| StoryGenerationManager 154 | 154 | ✅ |
| FalAIImageGenerator 64 | 64 | ✅ |
| RevenueCatManager 35 | 35 | ✅ |
| TextStoryManager 33 | 33 | ✅ |
| AIService 31 | 31 | ✅ |
| ProfileManager 20 | 20 | ✅ |

Testlerdeki 25 `print()` bu sayıya dahil değil (441 + 25 = 466).

`MagicPaperApp.swift`'te de 20 `print()` var; listede yoktu, eklenmeli.

### `print()` release build'de susmaz

Swift'in `print()` fonksiyonu derleme yapılandırmasına duyarlı değildir. `-Onone`
ile `-O` arasında fark yoktur; `#if DEBUG` sarmalayıcısı olmadan Release/App Store
build'inde de stdout'a yazar. Cihazda stdout sistem log'una düşer: Console.app,
bağlı bir Mac, ve **sysdiagnose** çıktısı bunu görür. Kullanıcı bir hata raporu
gönderdiğinde bu satırlar rapora dahil olur.

Depoda 5 adet `#if DEBUG` var ve hiçbiri log sarmalayıcısı değil
(`MagicPaperApp.swift:46` RevenueCat key tipi kontrolü, `MPPreviews.swift:1`,
`SettingsView.swift:34/286`, `SubscriptionManager.swift:283`).

**Sonuç:** Aşağıdaki P0 ve P1 satırları üretim cihazlarında gerçekten yazılıyor.

---

## 1. `print()` sınıflandırması — 2. dalganın iş emri

441 çağrının 205'i sabit metin (string interpolation içermiyor), 236'sı değişken
basıyor. Sınıflandırma interpolasyon içeriğine göre yapıldı.

| Sınıf | Adet | Tanım |
|---|---|---|
| **P0 — Kimlik bilgisi** | 3 | API anahtarı basıyor |
| **P1 — Çocuk verisi** | 33 | Çocuk adı, fotoğraf URL'i, hikâye prompt'u, ham API gövdesi |
| **P2 — Türetilmiş / bağlayıcı** | 44 | Yaş, cinsiyet, tema, hikâye başlığı, profil dosya adı |
| **P3 — Operasyonel** | 156 | Sayaç, durum kodu, hata tipi, süre |
| **SAFE — Sabit metin** | 205 | Değişken içermiyor |

Toplam: 3 + 33 + 44 + 156 + 205 = 441.

---

### P0 — API anahtarı basan satırlar (3) · DERHAL

Bunlar çocuk verisi değil ama **daha ağır**: sızan anahtar, sızan anahtarla
üretilebilecek her şeyin faturasını ve erişimini açar.

| Dosya:satır | Ne basıyor |
|---|---|
| `MagicPaper/Services/AIService.swift:319` | `print("🌐 API Endpoint: \(endpoint)")` — `endpoint` = `...:generateContent?key=<GEMINI_API_KEY>`. **Gemini anahtarının tamamı düz metin log'a yazılıyor.** |
| `MagicPaper/MagicPaperApp.swift:76` | `print("⚠️ Bulunan key: \(...REVENUECAT_API_KEY...)")` — RevenueCat anahtarının **tamamı**, kırpma yok |
| `MagicPaper/MagicPaperApp.swift:71` | `print("✅ RevenueCat yapılandırıldı: \(apiKey.prefix(10))...")` — ilk 10 karakter; tip sızdırır, anahtarı sızdırmaz. Düşük ama gereksiz. |

Ayrıca `MagicPaperApp.swift:75` kaynak kodda **canlı test anahtarını literal olarak**
taşıyor (`test_… (redacted)`) — bkz. Bölüm 5.

---

### P1 — Çocuk verisi basan satırlar (33) · 2. dalga öncelik 1

#### 1a. Çocuğun adı (7)

| Dosya:satır |
|---|
| `MagicPaper/Services/StoryGenerationManager.swift:235` — `🎨 Child name: \(childName)` |
| `MagicPaper/Services/StoryGenerationManager.swift:347` — `🎬 Child: \(childName), Age: \(age)` |
| `MagicPaper/Services/StoryGenerationManager.swift:445` — `🎬 Child: \(childName), Age: \(age)` |
| `MagicPaper/Services/StoryGenerationManager.swift:1019` — `Örnek masallar \(childName) adına uyarlandı` |
| `MagicPaper/Services/AIService.swift:1232` — `👤 Çocuk: \(childName)` |
| `MagicPaper/Services/TextStoryManager.swift:152` — `- Çocuk: \(story.childName)` |
| `MagicPaper/MagicPaperApp.swift:137` — `📱 Aktif profil: \(profileManager.currentProfile?.name ?? "yok")` |

Ad + yaş aynı satırda (347, 445) — tek log satırından çocuğun kimliği çıkar.

#### 1b. Çocuk fotoğrafının URL'i (14)

Bu URL'ler Firebase Storage download URL'leridir ve **token taşır**: URL'i bilen
herkes fotoğrafı indirebilir. Log'a yazmak fotoğrafı log'a yazmaya yakındır.

| Dosya:satır |
|---|
| `MagicPaper/Services/FirebaseImageUploader.swift:56` — `🔗 Download URL: \(urlString)` — **tam URL** |
| `MagicPaper/Services/FirebaseImageUploader.swift:42` — `📤 Uploading to: child_uploads/\(filename)` |
| `MagicPaper/Services/StoryGenerationManager.swift:360` — `✅ URL: \(downloadURL)` — **tam URL** |
| `MagicPaper/Services/StoryGenerationManager.swift:458` — `✅ URL: \(downloadURL)` — **tam URL** |
| `MagicPaper/Services/StoryGenerationManager.swift:234` — `🎨 Reference photo: \(referencePhotoUrl.prefix(60))...` |
| `MagicPaper/Services/StoryGenerationManager.swift:172` — `❌ Invalid URL: \(urlString)` |
| `MagicPaper/Services/StoryGenerationManager.swift:178` — `⬇️ Downloading image from: \(urlString.prefix(60))...` |
| `MagicPaper/Services/FalAIImageGenerator.swift:80` — `📸 URL: \(refUrl.prefix(60))...` |
| `MagicPaper/Services/FalAIImageGenerator.swift:256/264/271/281/291` — `✅ URL: \(imageUrl)` — üretilen görselin **tam** fal.ai URL'i (5 satır) |
| `MagicPaper/Services/FalImageGenerator.swift:32` — `🔗 Fotoğraf URL: \(childPhotoURL)` — *ölü kod, bkz. Bölüm 4* |

> `.prefix(60)` bir koruma değil. Firebase URL'inin ilk 60 karakteri
> `https://firebasestorage.googleapis.com/v0/b/<bucket>/o/child_upl...` — bucket
> adını açığa çıkarır, token'ı gizler. Token'ı gizlediği için indirilemez; ama
> bucket + `child_uploads/` yol şeması birlikte keşif bilgisidir.

#### 1c. Hikâye / görsel prompt'u (4)

Prompt, çocuğun adını ve sahne tarifini içerir.

| Dosya:satır |
|---|
| `MagicPaper/Services/StoryGenerationManager.swift:272` — `📝 Scene prompt: \(promptToUse.prefix(150))...` |
| `MagicPaper/Services/FalAIImageGenerator.swift:62` — `📝 Prompt: \(fullPrompt.prefix(100))...` |
| `MagicPaper/Services/FalImageGenerator.swift:31` — `📝 Prompt: \(prompt)` — **kırpma yok** (*ölü kod*) |
| `MagicPaper/Services/StoryGenerationManager.swift:960` — `Story '\(story.title)' Page N` |

#### 1d. Ham API yanıt gövdesi (5)

Hata gövdeleri gönderilen prompt'u yankılar; yankılanan prompt çocuğun adını taşır.

| Dosya:satır |
|---|
| `MagicPaper/Services/AIService.swift:375` — `❌ API Hatası: \(errorText)` (Gemini gövdesi) |
| `MagicPaper/Services/FalAIImageGenerator.swift:112` — `❌ Response: \(errorText)` |
| `MagicPaper/Services/FalAIImageGenerator.swift:140` — `❌ Full response: \(json)` |
| `MagicPaper/Services/FalAIImageGenerator.swift:298` — `❌ Full JSON: \(json)` |
| `MagicPaper/Services/FalImageGenerator.swift:95` — `JSON Parse Hatası (Submit): \(String(data:...))` (*ölü kod*) |

#### 1e. Test ekranları (3)

`FalAITestView` ve `FirebaseTestView` ürün akışında değil ama build'e dahil.

`MagicPaper/Views/FalAITestView.swift:209`, `:224`, `MagicPaper/Views/FirebaseTestView.swift:147`

---

### P2 — Türetilmiş / bağlayıcı veri (44) · 2. dalga öncelik 2

Tek başına kimlik değil; P1 ile birleşince kimliği zenginleştirir.

**Yaş / cinsiyet (6):** `AIService.swift:134`, `:864`, `:1233`,
`StoryGenerationManager.swift:347`, `:445`, `StoryEngineBridge/OfflineStoryService.swift:85`,
`Services/DailyStoryManager.swift:85`

**Hikâye başlığı (10):** `AIService.swift:133`, `:862`, `:1369`,
`StoryGenerationManager.swift:257`, `:552`, `:707`, `:996`,
`TextStoryManager.swift:151`, `:171`, `:184`, `:251`, `:308`

**Tema / dil (7):** `StoryGenerationManager.swift:236`, `:348`, `:490`,
`AIService.swift:1234`, `:1235`, `TextStoryManager.swift:153`, `:154`, `:160`

**Profil'e bağlı dosya adı (11):** `ProfileManager.swift:238`, `:270`
(`profile_<UUID>.jpg`), `StoryGenerationManager.swift:201`, `:296`,
`FileManagerService.swift:53`, `Views/LocalImageView.swift:41`, `:42`, `:43`,
`:48`, `:51`, `:58`, `:61` (`:42`/`:43` **tam Documents yolunu** basıyor)

**Profil tipi / sayaç (4):** `ProfileManager.swift:135`, `:206`,
`MagicPaperApp.swift:135`, `:136`

**Cihaz dili (4):** `LocalizationManager.swift:37`, `:41`, `:47`, `:48`

---

### P3 — Operasyonel (156) ve SAFE (205)

Sayaç (`\(pages.count)`), durum kodu, `error.localizedDescription`, süre, byte
boyutu. Bunlar gizlilik riski taşımıyor; taşıdıkları sorun gürültü. 360 satırlık
gürültü, P0/P1 satırlarının gözden kaçmasının sebebi.

**Öneri (2. dalga):** tek bir `MPLog` cephesi + `os.Logger`. `os.Logger`'ın
`privacy:` niteleyicisi tam olarak bu iş için var — `\(childName, privacy: .private)`
cihazda maskelenir, sysdiagnose'a düşmez. Bu değişiklik P1'i kod silmeden çözer.

---

## 2. Çocuk fotoğrafının yaşam döngüsü

### 2.1 Giriş — fotoğraf nereden geliyor

`PermissionManager` (`Services/PermissionManager.swift`) fotoğraf izniyle **hiç
ilgilenmiyor**. İçinde yalnızca bildirim izni var; ATT (tracking) kodu Kids
Category gerekçesiyle yorum satırına alınmış. Bu doğru bir karar.

Fotoğraf seçimi `Helpers/ImagePicker.swift` üzerinden:
`UIImagePickerController`, `sourceType = .photoLibrary`.

**Bulgu:** `ImagePicker` yalnızca iki yerde kullanılıyor ve **ikisi de test ekranı**:
`Views/FalAITestView.swift:181` ve `Views/FirebaseTestView.swift:40`.

`ProfileCreationView.swift:138` `profileManager.createProfile(...)` çağırıyor;
`createProfile` bir `UIImage?` parametresi alıyor ama bu ekranda fotoğraf seçtiren
bir kontrol yok. Yani **ürün akışında bugün çocuk fotoğrafı toplanmıyor**; toplama
mekanizması kurulu, giriş kapısı bağlı değil.

Bu, temizlik için bir fırsat penceresi: fotoğraf boru hattı canlı kullanıcı verisi
taşımadan düzeltilebilir.

### 2.2 Yerel yazım

`ProfileManager.saveProfileImage` (`Services/ProfileManager.swift:223-242`):

```
Documents/profile_<profileUUID>.jpg    JPEG, compressionQuality 0.8
```

`UserProfile.imageFileName` alanına dosya adı yazılır, profil
`UserDefaults["user_profiles"]` içindeki JSON dizisine kaydedilir.

**Dosya koruma seviyesi belirtilmemiş.** Tüm depoda `FileProtection`,
`NSFileProtectionKey`, `.completeFileProtection` → **0 eşleşme**. Üç yazım noktası
da niteliksiz `write(to:)` kullanıyor:

- `Services/ProfileManager.swift:230` (çocuk fotoğrafı)
- `Services/FileManagerService.swift:52` (hikâye görselleri)
- `StoryEngineBridge/FileStores.swift:59` (engine JSON kayıtları)

iOS varsayılanı `NSFileProtectionCompleteUntilFirstUserAuthentication`. Pratik
anlamı: **cihaz açıldıktan ve bir kez kilit açıldıktan sonra, cihaz tekrar
kilitlense bile bu dosyalar okunabilir.** Çocuk fotoğrafı ve hikâye metinleri için
`.completeUnlessOpen` veya `.complete` düşünülmeli. Bu, D4 ile domain verisi
UserDefaults'tan dosyalara taşınınca **daha da önem kazanıyor**: UserDefaults'un
`.plist`'i de aynı sınıfta, ama veri hacmi ve hassasiyeti artıyor.

### 2.3 Buluta yükleme

`Services/FirebaseImageUploader.swift` → `uploadImageToFirebase(image:)`

```
UIImage → jpegData(0.5) → Firebase Storage: child_uploads/<UUID>.jpg
       → downloadURL (token'lı, kimlik doğrulaması gerektirmeyen public URL)
```

Çağrı yerleri: `StoryGenerationManager.swift:358`, `:456` (üretim akışı),
`FalAITestView.swift:202`, `FirebaseTestView.swift:141` (test).

Dönen URL `updateStoryCoverUrl` ile `Story.coverImageUrl` alanına yazılır ve
`UserDefaults["stories"]` içinde **kalıcı olarak saklanır**.

### 2.4 Dış servise ne gidiyor — ham fotoğraf mı, türetilmiş tanımlayıcı mı?

**Ham fotoğraf. İki ayrı servise, iki ayrı biçimde.**

| Hedef | Ne gidiyor | Kod |
|---|---|---|
| **Firebase Storage** | Ham JPEG baytları (q=0.5) | `FirebaseImageUploader.swift:49` |
| **Gemini** (`generativelanguage.googleapis.com`) | Ham JPEG'in **base64'ü**, `inline_data` olarak, prompt ile aynı istekte | `AIService.swift:344-357`; besleyen: `StoryGenerationManager.swift:378`, `:476` |
| **fal.ai** (`fal.run/fal-ai/gemini-25-flash-image/edit`) | Firebase public URL'i, `image_urls` alanında **3 kez** | `FalAIImageGenerator.swift:76-78` |

Yani tek bir hikâye üretimi sırasında çocuğun fotoğrafı:
1. Firebase'e ham yüklenir ve **kalıcı kalır**,
2. Google'a base64 olarak gönderilir,
3. fal.ai'ye indirilebilir URL olarak verilir — fal.ai fotoğrafı Firebase'den kendisi çeker.

Türetilmiş bir tanımlayıcı (embedding, karakter tarifi, yüz hash'i) **hiçbir yerde
kullanılmıyor**. `CharacterEngine` bu soyutlamaya sahip ama ürün akışında
çağrılmıyor (bkz. Bölüm 4).

### 2.5 Ne kadar tutuluyor — silme yolu var mı

| Konum | Silme yolu | Durum |
|---|---|---|
| `Documents/profile_<UUID>.jpg` | `ProfileManager.deleteProfileImage` (`:262`), `deleteProfile` içinden çağrılıyor | ✅ Çalışıyor |
| `Documents/Stories/*` | `FileManagerService.deleteStoryImages(storyId:)`, `StoryGenerationManager.deleteStory(id:)` içinden | ✅ Hikâye bazında çalışıyor |
| **Firebase `child_uploads/<UUID>.jpg`** | **Yok** | ❌ **Kod tabanında tek bir Firebase Storage silme çağrısı yok** |
| Gemini'ye gönderilen kopya | Uygulama kontrolünde değil | ⚠️ Sağlayıcı saklama politikasına tabi |
| fal.ai'nin çektiği kopya | Uygulama kontrolünde değil | ⚠️ Aynı |

**En ağır bulgu:** Çocuğun ham fotoğrafı Firebase Storage'da **süresiz** duruyor.
Kullanıcı hikâyeyi silse, profili silse, uygulamayı kaldırsa bile orada kalır.
`PRIVACY_POLICY.md` "Bulut depolamadaki geçici veriler 30 gün sonra otomatik
silinir" diyor — bunu yapan **hiçbir kod yok**; varsa Firebase konsolunda
tanımlanmış bir lifecycle kuralıdır ve depodan doğrulanamaz (bkz. Açık Sorular).

---

## 3. Dış servis veri akışı

### 3.1 fal.ai — `Services/FalAIImageGenerator.swift` (canlı)

**Endpoint:** `https://fal.run/fal-ai/gemini-25-flash-image/edit`
**Gönderilen:** `prompt` (sahne tarifi + stil), `negative_prompt`, `seed`,
`image_urls: [refUrl, refUrl, refUrl]` — refUrl = çocuğun Firebase fotoğrafı.
**Çocuk verisi içeriyor mu:** Evet — fotoğraf URL'i ve prompt içindeki sahne tarifi.
**Gerekli minimum mu:** Hayır.
- Aynı URL 3 kez gönderiliyor ("daha güçlü kimlik" gerekçesiyle). Bu, sağlayıcı
  tarafında aynı fotoğrafın 3 kopyasının işlenmesi demek.
- `prompt` çocuğun adını **taşımıyor** (iyi) — `FalAIImageGenerator.swift:57-60`'daki
  şablon "show the child \(prompt)" diyor, ad geçmiyor. Bu doğru tasarım.
- Fotoğraf yerine karakter tarifi/embedding gönderme seçeneği değerlendirilmeli.

fal.ai'ye 10 dosyada referans var ama **canlı olan tek sınıf bu**.
`FalImageService.swift` (queue.fal.run/flux/schnell), `FalImageGenerator.swift`
(queue.fal.run/flux/dev) ve `StoryEngineBridge/FalImageProvider.swift` hiçbir
üretim yolundan çağrılmıyor.

> Not: `enable_safety_checker: true` yalnızca **ölü** `FalImageGenerator.swift:76`
> içinde var. Canlı `FalAIImageGenerator` bu parametreyi hiç göndermiyor.

### 3.2 Gemini — `Services/AIService.swift` (canlı)

**Endpoint:** `.../v1/models/<model>:generateContent?key=<API_KEY>`
**Gönderilen:** Prompt (çocuğun adı, yaşı, cinsiyeti, tema, dil) + varsa fotoğrafın
base64'ü, `X-Ios-Bundle-Identifier` başlığı.
**Çocuk verisi içeriyor mu:** Evet — ad, yaş, cinsiyet, fotoğraf.
**Gerekli minimum mu:** Kısmen.
- Ad ve yaş hikâyenin kişiselleştirilmesi için gerçekten gerekli.
- **Fotoğraf metin üretimi için gerekli değil.** `callGeminiAPI` metin döndürüyor;
  fotoğraf yalnızca "çocuğu tanısın" sezgisiyle ekleniyor. `TextStoryManager.swift:238`
  zaten `photoData: nil` geçiyor ve çalışıyor — yani metin üretimi fotoğrafsız mümkün.
  Bu, kaldırılabilecek en net veri fazlalığı.

**İki ek bulgu:**
1. **API anahtarı query string'de.** `AIService.swift:314`. URL'ler ara
   sunuculara, hata raporlarına ve (bu kod tabanında) log'a düşer. Gemini
   `x-goog-api-key` başlığını destekliyor; başlığa taşınmalı.
2. **`safetySettings` gönderilmiyor.** `requestBody` yalnızca `generationConfig` ve
   `contents` içeriyor (`AIService.swift:333-367`). Çocuklara yönelik bir üründe
   model tarafı güvenlik eşikleri varsayılana bırakılmış.

### 3.3 Firebase — `Services/FirebaseImageUploader.swift` (canlı)

**Kullanılan servis:** Yalnızca Storage. `FirebaseApp.configure()` +
`FirebaseStorage`. **Analytics ve Crashlytics yok** — bu iyi: `print()` satırları
uzak bir toplayıcıya gitmiyor, cihazda kalıyor.
**Gönderilen:** Ham çocuk fotoğrafı JPEG'i.
**Kimlik doğrulama:** **Yok.** `FirebaseAuth` import edilmiyor, `Auth.auth()` çağrısı
yok. Yükleme anonim.
**Gerekli minimum mu:** Hayır. Firebase burada yalnızca **fal.ai'nin erişebileceği
bir public URL üretmek için** var. Fotoğrafı fal.ai'ye doğrudan (base64/multipart)
göndermek bu aracı katmanı ve kalıcı bulut kopyasını tümden kaldırır.

**Risk:** Auth olmadan yükleme çalışıyorsa Storage kurallarının yazmaya açık olması
gerekir. Depoda `storage.rules` **yok**; kurallar konsolda. Doğrulanamıyor.

### 3.4 RevenueCat — `Services/RevenueCatManager.swift` (canlı)

**Gönderilen:** Yalnızca satın alma/abonelik olayları.
**Çocuk verisi içeriyor mu:** **Hayır.** `Purchases.logIn`, `setAttributes`,
`setEmail`, `setDisplayName` → **hiçbiri çağrılmıyor**. Anonim app user ID kullanılıyor.
**Gerekli minimum mu:** Evet. Bu entegrasyon gizlilik açısından temiz.

35 `print()` çağrısı var ama hiçbiri çocuk verisi basmıyor; paket kimliği ve fiyat
basıyor. P3.

---

## 4. Güvenlik yüzeyi

### 4.1 `Secrets.xcconfig` tutarlı mı — hayır

**İki ayrı `Secrets.xcconfig` var:**

| Yol | İçerik | Durum |
|---|---|---|
| `MagicPaper/MagicPaper/Secrets.xcconfig` | `GEMINI_API_KEY`, `REVENUECAT_API_KEY`, `FAL_API_KEY` | ✅ Projenin kullandığı (`project.pbxproj:500/566/625/663` → `baseConfigurationReference`, `MagicPaper` grubu altında) |
| `MagicPaper/Secrets.xcconfig` | `GEMINI_API_KEY`, `REVENUECAT_API_KEY` — **`FAL_API_KEY` yok** | ⚠️ Bayat kopya. Yeni bir geliştirici bunu doldurursa fal.ai sessizce 401 alır. |

Okuma yolu tutarlı ve doğru kurulmuş: `Helpers/APIKeys.swift` tek giriş noktası
(env → Info.plist), `$(KEY)` yer tutucusunu `nil`'e çeviriyor. Dört fal.ai sınıfı da
`APIKeys.fal` üzerinden okuyor. Bu iyi bir temizlik; yalnızca RevenueCat
`MagicPaperApp.swift:43`'te `APIKeys`'i atlayıp doğrudan `Bundle.main`'e gidiyor.

**Mimari sınır:** `Info.plist`'e gömülen anahtar IPA'dan çıkarılabilir. `GEMINI_API_KEY`
ve `FAL_API_KEY` **istemcide bulunduğu sürece herkese açıktır** — bu, xcconfig'in
çözemeyeceği bir sorundur. Uzun vadede bu iki çağrının sunucu tarafına taşınması
gerekir. RevenueCat public key'i (`appl_`/`test_`) için bu geçerli değil, o zaten
istemci anahtarıdır.

### 4.2 Kaynak kodda sızmış anahtar — evet

**`.swift` dosyalarında düz anahtar yok.** (Geçmişte üç dosyada varmış;
`APIKeys.swift` yorumu bunu kaydediyor ve `MagicPaper/Secrets.xcconfig` "paylaşılmış
kabul edin ve fal.ai panelinden iptal edin" diyor.)

**Ama markdown dosyalarında var — ve bunlar `.gitignore` kapsamında değil:**

| Dosya:satır | Ne |
|---|---|
| `MagicPaper/REVENUECAT_API_KEY_FIX.md:15`, `:33`, `:47` | **RevenueCat secret key (`sk_…`)** — tam değer, üç kez |
| `MagicPaper/REVENUECAT_SETUP_COMPLETE.md:24` | `appl_…` public key, tam değer |
| `REVENUECAT_TEST_GUIDE.md:7`, `REVENUECAT_PRODUCTION_KEY_NASIL_ALINIR.md:7`/`:195`, `REVENUECAT_PRODUCTION_KEY_ZORUNLU.md:79`, `DEBUG_BUILD_REQUIRED.md:98`/`:144`, `REVENUECAT_API_KEY_FIX.md:24`/`:39`/`:50`/`:136` | `test_… (redacted)`, tam değer, 10 yerde |
| `MagicPaper/MagicPaperApp.swift:75` | Aynı test key'i **kaynak kodda literal** (bir `print` metni içinde) |

`MagicPaper/.gitignore` yalnızca `Secrets.xcconfig`, `Info.plist`,
`GoogleService-Info.plist` dosyalarını dışlıyor. Markdown'lar **takip ediliyor** ve
`sk_` değeri git geçmişinde `4101e29` numaralı commit'te mevcut. Yani anahtar
yalnızca çalışma kopyasında değil, **geçmişte** de duruyor.

### 4.3 `SECURITY_WARNING.md` hâlâ geçerli mi — EVET

`SECURITY_WARNING.md` "Secret key derhal iptal edilmeli" diyor ve bir kontrol listesi
veriyor. Kontrol listesindeki maddelerin durumu:

- [x] `Secrets.xcconfig` public key kullanıyor (`test_` — doğru tip)
- [x] `.gitignore`'da `Secrets.xcconfig` var
- [ ] **Secret key iptal edildi mi — doğrulanamıyor**, ve `sk_` değeri hâlâ depoda
- [ ] Depodaki markdown'lardan anahtarlar temizlenmedi

**Doküman geçerliliğini korumakla kalmıyor, kapsamı da eksik:** yalnızca
`Secrets.xcconfig`'e odaklanıyor, esas sızıntının kendi komşusundaki markdown
dosyalarında olduğunu görmüyor.

---

## 5. Safety pipeline gerçeği

Rol tanımındaki zincir:

```
Input → Generation → Safety Validation → Age Validation → Quality Validation
      → Illustration → Illustration Validation → Child-facing Content
```

### 5.1 Zincir kodda tam olarak var

`StoryEngine/Sources/StoryEngine/Services/Validators/`:

| Bileşen | Zincirdeki yeri | Kayıtlı mı |
|---|---|---|
| `StructuralValidator` | Quality | ✅ `StoryValidator.swift:53` |
| `RepetitionValidator` | Quality | ✅ `:54` |
| `CharacterConsistencyValidator` | Safety (kimlik uydurmama) | ✅ `:55` |
| `AgeAppropriatenessValidator` | Age | ✅ `:56` |
| `VisualSafetyValidator` | Safety (görsel prompt) | ✅ `:57` |
| `GeneratedImageValidator` | Illustration Validation | ✅ `:58` |
| `NarrativeConsistencyValidator` | Semantic quality | ✅ `:61` |
| `SceneTextAlignmentValidator` | Semantic quality | ✅ `:62` |

`StoryValidator.validate` tasarımı sağlam: şablonun `enabledValidators` kümesine
bakıyor, çalışamayan bir doğrulayıcıyı `.skipped(reason:)` olarak **ayırt edilebilir**
biçimde işaretliyor, yalnızca `.error` yayını engelliyor.
`StoryOrchestrator.swift:478`/`:487` doğrulamayı, `:468` görsel doğrulamayı çağırıyor.

### 5.2 Ama zincirin tamamı **ölü**

Kopuk halka tek ve net:

```
StoryValidator
  ← StoryOrchestrator (StoryOrchestrator.swift:315)
    ← StoryEngineContainer (StoryEngineBridge/StoryEngineContainer.swift:65)
      ← ??? HİÇBİR YERDEN ÇAĞRILMIYOR
```

`StoryEngineContainer` adı geçen tek dosya kendi dosyası. Uygulama hedefinde bu
sınıfı inşa eden veya `make(...)` çağıran hiçbir satır yok. Dolayısıyla
`orchestrator` da yok; `orchestrator.` ifadesinin uygulamadaki tek geçtiği yer
`StoryEngineContainer.swift:94` (`lifecycle` getter'ı), o da çağrılmıyor.

### 5.3 Canlı üretim yollarında ne var

| Yol | Doğrulama |
|---|---|
| `createStory` → `OfflineStoryService.compose()` (V2, yeni akış) | **Hiçbiri.** `OfflineStoryComposer.swift` ve `OfflineStoryService.swift` içinde `Validator`/`validate`/`safety` → 0 eşleşme. Deterministik şablonlardan üretildiği için içerik önceden insan tarafından yazılmış; risk düşük ama kontrol yok. |
| `createCustomStory` → Gemini + fal.ai (Legacy V1) | **Hiçbiri.** Gemini yanıtı JSON'a çözülüp doğrudan `Story`'ye yazılıyor. `safetySettings` da gönderilmiyor. |
| `createCategoryBasedStory` → Gemini (Günlük masallar) | **Hiçbiri.** |
| `FalAIImageGenerator` (canlı görsel) | `negative_prompt` var (metin/watermark engelleme — estetik, güvenlik değil). `enable_safety_checker` **gönderilmiyor**. |

**Uygulama hedefinin tamamında** (`Services/` + `StoryEngineBridge/`) güvenlik
doğrulamasına işaret eden yalnızca iki eşleşme var ve ikisi de aldatıcı:
`AIService.swift:891` bir prompt metni içindeki "safety" kelimesi,
`FalImageGenerator.swift:76` ölü koddaki `enable_safety_checker`.

### 5.4 Kopuk halkaların özeti

1. **`StoryEngineContainer` inşa edilmiyor** → 8 doğrulayıcının tamamı erişilemez.
2. **`imageValidationProvider` varsayılan `nil`** → `ImageValidationService` sağlayıcısız;
   şablonlar `.advisory` olduğu için bu engellemiyor, raporluyor. Container zaten ölü
   olduğundan bu ikincil.
3. **Semantik doğrulayıcılar `aiService` gerektiriyor**; yoksa `.skipped`. Tasarım doğru,
   ama yine erişilemez.
4. **Canlı Gemini çağrısında `safetySettings` yok** → model tarafı eşikler varsayılan.
5. **Canlı fal.ai çağrısında `enable_safety_checker` yok.**

Yani bugün çocuğa ulaşan içeriğin önünde **uygulama seviyesinde tek bir güvenlik
kontrolü yok**. Tek koruma, sağlayıcıların kendi varsayılan filtreleri.

---

## 6. Silme

### 6.1 `FileAssetDeleter` — tanımlı, çağrılmıyor

`StoryEngineBridge/FileAssetDeleter.swift`. Tasarımı iyi: uzak bir locator'ı
`RemoteAssetDeleting` olmadan **sessizce silinmiş saymıyor**, `remoteAssetHasNoDeleter`
fırlatıyor. Kendi yorumu bunu açıkça söylüyor.

Ama tek inşa yeri `StoryEngineContainer.swift:79` ve o container hiç inşa edilmiyor.
**Ölü.** Ayrıca `RemoteAssetDeleting`'in **hiçbir uygulaması yok** — yani container
canlansa bile Firebase'deki fotoğraf silinemez, yalnızca "silinemedi" diye raporlanır.

### 6.2 `StoryDataLifecycle` — tanımlı, yalnızca testlerden çağrılıyor

`StoryEngine/Sources/StoryEngine/Services/StoryDataLifecycle.swift`.
`DeletionReport` ayrımı doğru kurulmuş: silinen kayıt / silinen dosya / **başkasına
ait dosya** / **silinemeyen dosya**. Karakter silerken ailenin kendi fotoğrafını
`externalAssetLocators`'a koyup dokunmuyor — düşünülmüş bir davranış.

Uygulamadaki tek referans `StoryEngineContainer.swift:93`. Gerçek çağrı yalnızca
`StoryEngine/Tests/StoryEngineTests/DataLifecycleTests.swift`. **Üretimde ölü.**

### 6.3 Bugün gerçekten çalışan silme

| İşlem | Kod | Ne siliyor | Ne silmiyor |
|---|---|---|---|
| Hikâye sil | `StoryGenerationManager.deleteStory(id:)` (`:976`) | `Documents/Stories/` içinde adı storyId içeren dosyalar; `stories` dizisinden kayıt | ❌ Firebase `child_uploads/` kopyası (`coverImageUrl`'in işaret ettiği) |
| Metin hikâye sil | `TextStoryManager.deleteStory(_:)` (`:305`) | `textStories` dizisinden kayıt | — (görsel yok) |
| Profil sil | `ProfileManager.deleteProfile(_:)` (`:173`) | `profile_<UUID>.jpg`; `mp_avatarColor_<UUID>`; `read_history_<UUID>` | ❌ **O profile ait hikâyeler** ❌ Firebase kopyaları ❌ `mp_readDays` / `mp_readSeconds` |

**Profil silme, o çocuğun hikâyelerini silmiyor.** `Story` modelinde `childProfileID`
alanı **var** (`Models/Story.swift`) — yani kaskad silme teknik olarak mümkün, sadece
yazılmamış. Silinen çocuğun adı, hikâye metinleri ve yerel illüstrasyonları
`UserDefaults["stories"]` ve `Documents/Stories/` içinde kalmaya devam ediyor.

### 6.4 Sessiz birikim: `stories.undecodable.<timestamp>`

`StoryGenerationManager.swift:926`. Hikâye JSON'u çözülemezse ham veri tarihli bir
UserDefaults anahtarına yedekleniyor. Veri kaybını önleme gerekçesi doğru ve iyi
düşünülmüş. Ama:

- Bu anahtarları **temizleyen hiçbir kod yok**.
- İçerik **çocuğun tam hikâye korpusu**: ad, yaş, başlıklar, tüm sayfa metinleri, URL'ler.
- Kullanıcı hikâyeleri sildikten sonra bile yedek kalır.
- Her başarısız çözümlemede **yeni** bir anahtar oluşur; birikir.

Bir saklama politikası gerekiyor: en fazla 1 yedek, en fazla N gün.

### 6.5 `MPStreak` persistence (D2 kapsamı)

`Screens/MPStreak.swift`. İki UserDefaults anahtarı:

| Anahtar | İçerik | Hassasiyet |
|---|---|---|
| `mp_readDays` | `["2026-09-18", …]` — okuma yapılan günler, `Set<String>` | Düşük-orta: çocuğun günlük aktivite takvimi, profile bağlı değil |
| `mp_readSeconds` | `["2026-09-18": 1830.0, …]` — gün başına okuma saniyesi | Aynı |

Profile bağlı değil (cihaz geneli), doğrudan tanımlayıcı içermiyor. Yine de bir
çocuğun günlük rutininin uzun vadeli kaydı ve CLAUDE.md İlke 7 zaten streak'i
istemiyor. D2 kaldırmayı zaten karara bağlamış.

**D2 için gereken temizlik:** kodu silmek yeterli değil. Mevcut kullanıcıların
cihazında bu iki anahtar kalır. Kaldırma sürümünde tek seferlik bir
`removeObject(forKey:)` çalıştırılmalı. Ayrıca `ParentPanelView.swift:125`
"bu hafta okuma" değerini `MPStreak.addReadingTime`'dan besliyor — bu ekran
kaldırılırken ne göstereceğine karar verilmeli.

---

## 7. D4 — UserDefaults → FileStores göçünün gizlilik riski

### 7.1 Çift kopya penceresi

D4 sonrası `user_profiles`, `stories`, `textStories`, `dailyStories`,
`mp_favoriteStoryIDs` gibi anahtarlar `FileStores`'a taşınacak. Göç sırasında
kaçınılmaz bir pencere doğar: veri hem eski `.plist`'te hem yeni JSON dosyalarında.

Gerilim şu iki ilke arasında:
- **Koordinatör kararı:** "eski veri öylece silinmeyecek" — veri kaybı riskine karşı.
- **CLAUDE.md İlke 10:** "gereksiz veri tutma" — çocuk verisinin ikinci bir kopyası
  gereksizdir.

Bunlar çelişmiyor; **sıralanıyorlar**. Eski kopya, yeni kopyanın doğruluğu
kanıtlanana kadar gereklidir; kanıtlandıktan sonra gereksizdir. Sorun "silinsin mi"
değil, "ne zaman".

### 7.2 Önerilen sıra

```
1. YAZ        UserDefaults'tan oku → FileStores'a yaz (atomic)
2. DOĞRULA    Geri oku; kayıt sayısı ve her kaydın id'si eşleşiyor mu?
              Eşleşmiyorsa: göç başarısız, eski veri DURUR, tekrar denenir.
3. İŞARETLE   schemaVersion = 2  (küçük bir tercih; UserDefaults'ta kalabilir)
4. GECİKTİR   Eski anahtarlar bir sürüm boyunca durur — geri alma güvencesi
5. SİL        Bir sonraki sürümün ilk açılışında, schemaVersion == 2 ise
              eski anahtarlar removeObject ile silinir
```

Kritik nokta: **5. adım yazılmadan 1. adım gönderilmemeli.** Aksi halde "geçici"
kopya kalıcı olur — `stories.undecodable.*` anahtarlarının bugün olduğu gibi
(Bölüm 6.4). Bu kod tabanının kanıtlanmış hatası tam olarak budur.

İkinci kritik nokta: 2. adım **gerçek bir doğrulama** olmalı, `try?` değil.
`ProfileManager.saveProfiles` yorumu (`:92-93`) bu dersin bir kez öğrenildiğini
gösteriyor; göçte tekrar unutulmamalı.

### 7.3 FileStores'un dosya koruması

Bölüm 2.2'de tespit edildi: `FileStores.swift:59` niteliksiz `write(to:.atomic)`
kullanıyor, koruma sınıfı belirtmiyor. Göçten sonra `Documents/StoryEngine/` altında
şunlar bulunacak:

```
Stories/<uuid>.json      hikâye metni + çocuk adı + prompt anlık görüntüleri
Characters/<uuid>.json   çocuğun görsel kimlik tarifi
Jobs/<uuid>.json         üretim durumu
Requests/<uuid>.json     ad, yaş, tema — üretim girdisi
```

Bunlar bugünkü UserDefaults blob'undan daha ayrıntılı. Göç, dosya koruma seviyesini
**açıkça** belirlemek için doğru an:

- `FileBackedStore.save` → `write(to:options: [.atomic, .completeFileProtectionUnlessOpen])`
- `ProfileManager.saveProfileImage` ve `FileManagerService.saveImage` → aynı

`.complete` yerine `.completeUnlessOpen` öneriliyor çünkü arka planda devam eden bir
üretim işi cihaz kilitlendiğinde dosya yazmaya devam edebilmeli.

### 7.4 D4 sonrası silme yolu nasıl olmalı

Bugün yok olan kaskad, D4 ile yazılmak zorunda. `deleteProfile(_:)` şunları yapmalı:

```
deleteProfile(profile)
 ├─ Documents/profile_<id>.jpg                         (bugün var)
 ├─ mp_avatarColor_<id>, read_history_<id>             (bugün var)
 ├─ FileStores: Stories  → childProfileID == id        (YOK — yazılmalı)
 ├─ FileStores: Characters → ownerProfileID == id      (YOK — yazılmalı)
 ├─ FileStores: Jobs/Requests → profile'a bağlı olanlar (YOK)
 ├─ Documents/Stories/ → o hikâyelerin görselleri      (YOK)
 └─ Firebase child_uploads/ → o profilin yüklemeleri   (YOK ve bugün İMKÂNSIZ)
```

Son satır bugün imkânsız çünkü:
1. `RemoteAssetDeleting`'in uygulaması yok,
2. Firebase Auth olmadığından yüklemeler hiçbir profile **bağlı değil** —
   `child_uploads/<rastgele UUID>.jpg`. Hangi dosyanın hangi çocuğa ait olduğunu
   uygulama yalnızca `Story.coverImageUrl` üzerinden bilir. O kayıt silinirse
   **bağ kopar ve dosya yetim kalır, sonsuza kadar.**

Doğru düzeltme sırası:
1. **Önce** `RemoteAssetDeleting`'i Firebase Storage için uygula,
2. **sonra** `StoryDataLifecycle`'ı gerçekten bağla (container'ı inşa et),
3. **sonra** `deleteProfile` kaskadını yaz.

Ya da — daha ucuz ve daha temiz — **Firebase'i boru hattından tamamen çıkar**.
Fotoğrafı fal.ai'ye doğrudan gönder; silinecek uzak kopya kalmaz. Bölüm 3.3'teki
gerekçeye göre Firebase'in tek işlevi zaten bir public URL üretmek.

---

## 8. Riskler

| # | Risk | Şiddet | Kanıt |
|---|---|---|---|
| R1 | Gemini API anahtarı düz metin log'a yazılıyor (URL query string'i basılıyor) | **Kritik** | `AIService.swift:314` + `:319` |
| R2 | RevenueCat secret key (`sk_…`) depoda ve git geçmişinde | **Kritik** | `REVENUECAT_API_KEY_FIX.md:15/33/47`, commit `4101e29` |
| R3 | Ham çocuk fotoğrafı Firebase'de süresiz; silme kodu yok | **Kritik** | `FirebaseImageUploader.swift:49`, kod tabanında 0 silme çağrısı |
| R4 | Çocuğa giden içeriğin önünde uygulama seviyesinde güvenlik doğrulaması yok | **Kritik** | `StoryEngineContainer` hiç inşa edilmiyor; 8 doğrulayıcı erişilemez |
| R5 | Çocuğun adı, fotoğraf URL'i ve prompt'u Release build'de log'a yazılıyor | **Yüksek** | P1 listesi, 33 satır |
| R6 | Profil silindiğinde o çocuğun hikâyeleri silinmiyor | **Yüksek** | `ProfileManager.swift:173-200` |
| R7 | Firebase Storage kimlik doğrulaması yok; kurallar depoda doğrulanamıyor | **Yüksek** | `FirebaseAuth` import edilmiyor, `storage.rules` yok |
| R8 | Fotoğraf metin üretimi için Gemini'ye gönderiliyor — gereksiz | **Yüksek** | `AIService.swift:344`; `TextStoryManager.swift:238` fotoğrafsız çalışıyor |
| R9 | Dosya koruma sınıfı hiçbir yerde belirtilmemiş; kilitli cihazda okunabilir | **Orta** | 3 yazım noktası, `FileProtection` 0 eşleşme |
| R10 | `stories.undecodable.*` yedekleri sınırsız birikiyor, temizlenmiyor | **Orta** | `StoryGenerationManager.swift:926` |
| R11 | Gemini çağrısında `safetySettings`, fal.ai çağrısında `enable_safety_checker` yok | **Orta** | `AIService.swift:333-367`, `FalAIImageGenerator.swift:64-78` |
| R12 | İki `Secrets.xcconfig`; bayat olanda `FAL_API_KEY` eksik | **Düşük** | `MagicPaper/Secrets.xcconfig` |
| R13 | Test ekranları (`FalAITestView`, `FirebaseTestView`) üretim build'inde; fotoğraf yükleyip URL basıyorlar | **Düşük** | `#if DEBUG` sarmalayıcısı yok |

---

## 9. Açık sorular

1. **Firebase Storage kuralları nedir?** Depoda `storage.rules` yok. Auth olmadan
   yazma çalıştığına göre kural permissif. `child_uploads/` dizini listelenebiliyor mu?
   Bu, "tek bir URL sızdı" ile "tüm yüklemeler okunabilir" arasındaki farktır.
2. **`PRIVACY_POLICY.md`'deki 30 günlük otomatik silme nerede tanımlı?** Kodda yok.
   Firebase konsolunda bir lifecycle kuralı var mı? Yoksa politika metni kodun
   yaptığını anlatmıyor demektir.
3. **`sk_yAcez…` secret key iptal edildi mi?** `SECURITY_WARNING.md` iptal edilmesini
   söylüyor; iptal edildiğine dair kanıt yok. Edilmediyse acil.
4. **Gemini ve fal.ai'nin veri saklama ayarları ne?** İki sağlayıcı da gönderilen
   görselleri ve prompt'ları tutuyor olabilir. Kurumsal/no-retention seçenekleri
   etkin mi?
5. **Firebase gerçekten gerekli mi?** Tek işlevi fal.ai'ye public URL vermek. Fotoğrafı
   fal.ai'ye doğrudan göndermek en büyük üç riskten ikisini (R3, R7) tek hamlede
   ortadan kaldırır. Bu bir mimari karar, bu agent'ın yetkisinde değil.
6. **Fotoğraf boru hattı yeniden açılacak mı?** Bugün `ProfileCreationView` fotoğraf
   toplamıyor. Açılmadan önce mi düzeltilecek, yoksa boru hattı emekliye mi ayrılacak?
7. **`StoryEngineContainer` bağlanacak mı, yoksa doğrulayıcılar canlı yollara mı
   taşınacak?** Güvenlik zincirinin ölü olması bir "sonra bağlarız" sorunu değil;
   canlı üç üretim yolunun hiçbirinde doğrulama yok. Hangi yolun kalacağına dair
   karar (D1 legacy'yi emekliye ayırıyor) bu soruyu doğrudan etkiliyor.
8. **Çocuk fotoğrafı yerine türetilmiş bir tanımlayıcı kullanılabilir mi?**
   `CharacterEngine` bu soyutlamaya sahip. Kimlik tutarlılığı ham fotoğraf yerine
   karakter tarifiyle sağlanabilirse, ham fotoğrafın dış servise hiç çıkması
   gerekmez. Bu, İlke 10'un en güçlü uygulaması olurdu.

## 10. Masal ailem adları (FAZ 11, 4 Ekim 2026)

Ebeveynin yazdığı karakter adları (kardeş, arkadaş, evcil hayvan, hayali arkadaş) çocuk verisi gibi ele alınır:
- **Saklama:** yalnızca cihazda (`Documents/StoryEngine/FamilyCharacters/`, `.completeUnlessOpen`). Cihaz ve iCloud yedeğine girer; öteki depolarla aynı.
- **Log ve tanı:** ad hiçbir log'a, hata metnine ya da `description`'a girmez. `FamilyCharacter` ve `FamilyCast` ilişki türünü yazar; seçici ve köprü gerekçeleri yalnızca ilişki türünü söyler. Testler: `FamilyCharacterPrivacyTests`, `FamilyCastTests`.
- **Kayıt:** masal kökeni (`StoryOrigin`) ad değil kimlik ve ilişki türü tutar. Ad yalnızca masal metninde.
- **FAZ 14:** olay şemasına yalnızca ilişki türü girer.
- **Silme:** profil silme ve "Tüm verileri sil".
- **Serbest metin girişi:** yalnızca ebeveyn modunda. Çocuk modunda "Masalda kimler olsun?" yalnızca mevcut karakterleri gösterir.

## 11. İlgi alanları (FAZ 12, 4 Ekim 2026)

Çocuğun ilgi alanları ("Hayvanlar", "Doğa") aile içeriği gibi ele alınır:
- **Saklama:** `UserProfile.interests`, yalnızca cihazda, profil listesiyle aynı yerde (`UserDefaults["user_profiles"]`). Değer katalog kimliği (`animals`), serbest metin değil.
- **Log ve tanı:** ilgi alanı hiçbir log'a girmez; `ProfileManager` yalnızca sayıyı `.private` yazar. `UserProfile`'ın `description`, `debugDescription` ve `Mirror`'ı ne adı ne ilgi alanlarını içerir (`InterestProfileTests.testAProfileNeverPrintsItsNameOrInterests`).
- **Motor:** yalnızca katalog kimlikleri gider; masal kökenine ilgi alanı yazılmaz.
- **Silme:** profil kaydının parçası; profil silme ve "Tüm verileri sil" ile gider.
- **FAZ 14 / 16:** olay şemasına ve senkrona girip girmeyeceği o fazlarda karara bağlanır; girerse ad ve çocuk kimliğiyle birlikte değil.
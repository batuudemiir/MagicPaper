# B2 — Avatar + hazır sahne kütüphanesi: Faz 0 planı

**Tarih:** 2026-10-01 · **Durum:** Faz 0, **v2** (gözden geçirme işlendi). **Üretim kodu yazılmadı.**
**Görev metni:** `../../B2_SAHNE_KUTUPHANESI_PROMPT.md`
**Onay:** §9'daki varsayılanlar onaylandı (2026-10-01). Gözden geçirme sonucu §11'de. Faz 1, kullanıcı "başla" diyene kadar bekliyor.

> **Ürünün tanımı (v2):** Asıl ürün sahne kütüphanesi değil. Asıl ürün **sahne + avatar + eylem + deterministik birleştirici** (compositor). Sahne kütüphanesi bunun bir parçası. Bir masalın görseli şu zincirden çıkar:
> masal → beat → sahne → avatar pozu → katmanlı birleştirme.
> Zincirin her halkası veride tanımlıdır, kodda değil.

Her bölümde üç ayrı başlık var. **Olgu**, kodda ya da ölçümde görülen şeydir. **Yorum**, olgudan çıkardığım sonuçtur. **Öneri** ise uygulanmasını önerdiğim şeydir.

---

## 0. Özet

- MVP (Macera, 5-6 yaş, 8 sayfa) **3 ortam, 4 blueprint ve 4 yol arkadaşı** kullanıyor. Bu, 2040 masal üretilerek ölçüldü (§1).
- Önerilen görselli sayfa kuralıyla rol düzeyinde **12 sahne** gerekiyor. Beat düzeyinde özelleşmiş tam set **16** sahne (§1.3).
- Mimari, `StoryArtKit` desenini genişletiyor; paralel bir sistem kurmuyor:
  - JSON manifest + `Assets.xcassets` ad alanı + yer tutucuya düşme
  - Saf `SceneSelector`
  - Masalla birlikte donan avatar anlık görüntüsü
  - Okuyucuda canlı birleştirme
- **Engine paketine dokunulmuyor.** `visual_catalog.json`, golden fixture'lar, `FalImageProvider`, legacy `createCustomStory`, paywall ve RevenueCat de değişmiyor.
- Görev metniyle **4 çelişki** ve **2 ön koşul** bulundu (§8). Sahne kütüphanesinin içerik güvenliği onayı hâlâ **sahipsiz** (§9).

---

## 1. Kapsama matrisi (ölçülmüş)

### 1.1 Nasıl ölçüldü

**Olgu.**
- Paketin scratchpad kopyasına geçici bir test eklendi. Repo'ya yazılmadı.
- Test, üretim yükleyicisiyle (`ContentCatalogLoader().load()`) üç modun her birini tarıyor. Her modda sırayla şunları geziyor:
  - her fikir kartı (+ "sürpriz")
  - her yol arkadaşı adayı (+ "sürpriz")
  - 60 seed
- Hepsi `AgeBand 5-6` ile `OfflineStoryComposer().compose` üzerinden koştu.
- Sonuç: **2040 masal, 0 hata.** Kayıt: setting, tag, companion, blueprint, sayfa, rol, beat'ler, emotion.

### 1.2 MVP — Macera modu, 5-6 yaş

**Olgu.**

Ortamlar ve blueprint'ler:

| Ortam | Tag | Blueprint'ler | Yol arkadaşları |
|---|---|---|---|
| `setting_whispering_forest_001` | forest, nature | threshold_crossing_001, absence_looking_001, absence_retracing_002 | fox, hedgehog, rabbit |
| `setting_festival_meadow_001` | meadow, nature | threshold_crossing_001, threshold_joining_002 | fox, hedgehog, owl, rabbit |
| `setting_night_garden_001` | garden, nature | threshold_crossing_001 | fox, hedgehog, rabbit |

Dağılım ve sayfa düzeni:
- 780 macera masalının dağılımı: meadow 390, forest 315, garden 75.
- 10 ortam × yol arkadaşı çifti var.
- Her blueprint 8 sayfa. Yol arkadaşı **her zaman 3. sayfada** tanışılıyor.

Rol × beat × emotion (macera, tüm ortamlar):

| Sayfa | Rol | Beat / emotion |
|---|---|---|
| 1 | hook | notice_anomaly / curiosity · ease |
| 2 | discovery | approach / wonder · examine / unease · wonder |
| 3 | companion | meet_companion (+companion_offers / receive_appeal) / hesitation · concern |
| 4 | problem | hesitate / unease · determination · commit+obstacle_raises / determination |
| 5 | attempt | small_step · prepare · first_attempt / determination · doubt |
| 6 | challenge | find_own_courage · ask_for_help / effort · persist / patience · retrace / insight |
| 7 | resolution | succeed · restore / relief |
| 8 | emotional_ending | warm_close / self_recognize (+carry_forward) / pride · tenderness · satisfaction |

Ortam başına görselli rollerdeki beat'ler:

| Ortam | hook | discovery | problem | challenge | resolution | ending |
|---|---|---|---|---|---|---|
| forest | notice_anomaly | approach, examine | hesitate, commit | find_own_courage, persist, retrace | succeed, restore | 3 varyant |
| meadow | notice_anomaly | approach, examine | hesitate | find_own_courage, ask_for_help | succeed | 2 varyant |
| garden | notice_anomaly | approach | hesitate | find_own_courage | succeed | 1 varyant |

Kombinasyon sayıları (macera): setting×role 24 · setting×role×beat 39 · setting×role×beat×emotion 41.

**Diğer modlar (bilgi; MVP dışı):**
- **Gelişelim:** 5 ortam (+ cloud_mountain, old_orchard), 8 blueprint. setting×role 40, setting×role×beat×emotion 148.
- **Uyku:** 3 ortam, 2 blueprint (charge ailesi, geçici). setting×role 24.

### 1.3 Kaç sahne gerekiyor

Aşağıdaki tablo hesaptır, tahmin değil. Sayılar kodla doğrulandı.

| Görselli sayfa kuralı | Ortam × rol (asgari) | Ortam × rol × ana beat (tam) |
|---|---|---|
| **A: 1, 2, 4, 7** (hook, discovery, problem, resolution) | **12** | **16** |
| B: 1, 2, 6, 8 (hook, discovery, challenge, ending) | 12 | 19 |
| C: 1, 2, 6, 7 | 12 | 18 |

**Yorum.**
- Asgari set 12 sahnedir. Rol düzeyinde her eşleşme bir sahne bulur, kapsama boşluğu sıfır olur.
- Beat'e özel sahneler (ör. forest·discovery için `approach` ve `examine` ayrı) kaliteyi artırır ama zorunlu değil. Skorlama bunu zaten ödüllendiriyor (§3.2).
- `emotion` eşleşmesi MVP'de ayırt edici değil: 41 kombinasyonun 39'u beat ile zaten belirleniyor. Emotion alanı şemada opsiyonel kalır.

**Öneri.**
- Faz 6 için yer tutucu set: **12 sahne** (3 ortam × 4 rol).
- Gerçek illüstrasyon teslimi için hedef: 16 sahne.

### 1.4 Matristen çıkan iki tasarım olgusu

1. **1. ve 2. sayfada yol arkadaşı yok.** Tanışma 3. sayfada. Hook ve discovery sahnelerinde companion anchor **tanımlanmamalı**; tanımlanırsa yol arkadaşı tanışmadan önce resimde belirir.
   - Kural: `companionAnchor` yalnızca `pageNumber > companionPage` olan sayfalarda kullanılır. `companionPage`, compose çıktısındaki `role == .companion` sayfasıdır.
2. **Tag yeterince ayırt edici değil.**
   - `night_garden` ve `old_orchard` ikisi de `garden, nature` taşıyor. Ortamlarda `timeOfDay` alanı yok.
   - Yalnızca tag ile eşleşen gündüz bir bahçe sahnesi "Gece Bahçesi"ne düşer.
   - Öneri: sahne şemasında `settingTags` zorunlu kalsın. Yanına opsiyonel ve daha yüksek puanlı bir `settingIDs` eklensin. MVP sahneleri `settingIDs` ile yazılsın.
   - Ortamlara `timeOfDay` eklemek content-library'nin kararı (§9).

---

## 2. Görselli sayfa kuralı

**Olgu.**
- 8 sayfalık her macera blueprint'i `PageRole.mvpArc` sırasını izliyor.
- 3-4 yaş bandında bugün 6 sayfalık tek blueprint var (uyku modu). Macera modunda 3-4 içeriği yok.

**Öneri: kural A — 1, 2, 4, 7.**
- Sayfaların ritmi şöyle olur: görsel · görsel · metin · görsel · metin · metin · görsel · metin. Arka arkaya en fazla iki metin sayfası gelir.
- Kural B (1, 2, 6, 8) ve C (1, 2, 6, 7) üç metin sayfasını arka arkaya dizer.
- 4. sayfa (problem/hesitate: eşikte duran çocuk) ve 7. sayfa (resolution/succeed) güçlü kompozisyonlardır.

Kural veride durur, kodda değil (`scene_library.json`):

```json
"illustratedPages": {
  "5-6":  [["hook"], ["discovery"], ["problem", "challenge"], ["resolution", "emotional_ending"]],
  "3-4":  [["hook"], ["problem", "challenge"], ["resolution", "emotional_ending"]],
  "default": [["hook"], ["discovery"], ["problem", "challenge"], ["resolution", "emotional_ending"]]
}
```

Nasıl okunur:
- Her iç dizi bir **görsel yuvasıdır**.
- Yuva, masalda bulunan **ilk** role verilir.
- Böylece aynı kural farklı uzunluktaki arklarda da çalışır.

Hangi sayfaların görsel alacağı ve yaş bandına göre değişimi İrem ve Batuhan'ın kararı (§9). Kod bu kararı beklemeden çalışır.

---

## 3. Mimari

### 3.1 Manifest kararı: iki ayrı manifest, ArtKit'in yanında

**Olgu.**
- `art_kits.json` mod ve dünyaya bağlı **set**ler tutuyor; slotları `hero`, `cover`, `spot`.
- `StoryArtKitTests` şu değişmezleri koruyor:
  - her slot varlığı `ArtKit/` ad alanında;
  - `kit(modeID:worldID:)` mod önce, dünya sonra.
- `Screens/` senkronize klasör, yani içine konan JSON ve Swift dosyaları pbxproj düzenlemesi olmadan target'a girer.
- `Services/` ve `Models/` senkronize **değil**. Faz 0'da Entitlements bu yüzden elle eklenmişti.

**Yorum.** Sahne, sayfa düzeyinde seçilen, anchor taşıyan ve skorlanan bir kayıttır. Bunu kit'e `scenes` alanı olarak eklemek kit'in "bir aileye bir set" anlamını bozar ve testlerin ad alanı değişmezini kırar.

**Öneri.**
- `Screens/ArtKit/scene_library.json` ve `Screens/ArtKit/avatar_kit.json` ayrı manifestler olsun.
- Yükleyiciler `StoryArtKitCatalog.bundled` desenini izlesin: okunamazsa boş katalog döner, sessizce başka bir sete düşmez.
- Varlık ad alanları: `Assets.xcassets/Scenes/` ve `Assets.xcassets/Avatar/`.
  - `Storybook/` ve `ArtKit/` ad alanlarına dokunulmaz.
  - `sync_decorations.py` `Storybook/`'u baştan silip yeniden kuruyor (`rmtree`). Yeni araç kendi ad alanının dışına yazmamalı.

### 3.2 SceneSelector: app katmanında, ama yalnızca Foundation

**Olgu.**
- `StoryEngine` paketi vendor-free bir metin motoru.
- `ComposedStory`'nin belgesi "text only. No images, no persistence" diyor.
- Paket story-engine'in sahipliğinde. Değişen her şey 647/18 tabanına dokunur.
- `OfflineStoryMapper.appPage` bugün `role`, `beats` ve `emotion`'ı **düşürüyor**; `StoryPage`'e yalnızca `visualScene` geçiyor.

**Yorum.** Seçicinin girdilerinin yarısı app'e ait: varlık manifesti, okuma geçmişi, avatar. Pakete koymak sahiplik sınırını zorlar.

**Öneri.**
- `Screens/ArtKit/SceneBook/SceneSelector.swift` yalnızca Foundation import eder. SwiftUI, UIKit ve StoryEngine tipleri kullanılmaz.
- Girdiler düz değerlerdir: `[SelectorPage(number, role: String, beats: [String], emotion: String?)]`, `settingID`, `settingTags`, `mode`, `ageBand`, `seed`, `recentSceneIDs`. Bu sayede tip ileride kod değişmeden pakete taşınabilir.
- Motor tiplerinden düz değerlere çeviri tek bir bridge dosyasında yapılır: `StoryEngineBridge/IllustratedBookBinder.swift`.

Seçim algoritması (görev §3.2, eklerle):
1. Sayfa bir görsel yuvası alıyor mu? §2'deki kurala bakılır.
2. Aday süzme: `status == approved`, rol uyuyor, mod uyuyor, `settingIDs` ya da `settingTags` kesişiyor.
3. Skor, sırayla:
   - `settingIDs` eşleşmesi
   - beat eşleşmesi
   - sahnenin `allowedPoses` listesinde beat'in pozu var mı (v2)
   - emotion eşleşmesi
   - yalnızca rol
   - ardından `weight`
4. Cooldown: çocuğun son N masalında kullanılmış sahneye puan cezası verilir; sahne yasaklanmaz.
5. Aynı masalda aynı sahne iki kez çıkmaz.
6. Eşitlikte sıra seed'den türetilir: `StableHash(seed + pageNumber)` → SplitMix64. Dekorasyon motorundaki desen budur.
7. Aday yoksa `CoverageGap(page, role, settingID, settingTags)` döner ve sayfa metin sayfası kalır.
8. Poz §3.2.1'deki sözleşmeyle seçilir.

### 3.2.1 Eylem sözleşmesi: beat → poz (v2)

**Yorum.** Bu sözleşme sistemin kalbi. Bir sayfanın görsel anlatımını, çocuğun o sayfada **ne yaptığı** belirler. Bu yüzden kural bir yorum satırında ya da Swift `switch`'inde durmamalı, veride durmalı.

**Öneri.** `scene_library.json` içinde bir `direction` bloğu:

```json
"direction": {
  "beatPoses": {
    "notice_anomaly": "lookingUp",
    "approach": "walking",
    "examine": "reaching",
    "hesitate": "standing",
    "commit": "pointing",
    "small_step": "walking",
    "find_own_courage": "walking",
    "persist": "walking",
    "retrace": "pointing",
    "ask_for_help": "pointing",
    "succeed": "celebrating",
    "restore": "reaching",
    "warm_close": "sitting",
    "self_recognize": "celebrating"
  },
  "rolePoses": {
    "hook": "lookingUp", "discovery": "walking", "problem": "standing",
    "challenge": "walking", "resolution": "celebrating", "emotional_ending": "sitting"
  },
  "fallbackPose": "standing"
}
```

**Poz çözümü (deterministik):**
1. `beatPoses[sayfanın ana beat'i]` alınır.
2. Bu poz sahnenin `allowedPoses` listesinde yoksa `rolePoses[rol]` denenir.
3. O da listede yoksa sahnenin `defaultPose`'u kullanılır.
4. Hiçbir zaman rastgele seçim yapılmaz.

`allowedPoses` gerekli, çünkü sahne belirli bir kompozisyonla çizilir. Örneğin oturma pozu, sahnede oturulacak bir kütük olmasını ister.

**Testler:**
- Haritadaki her poz `avatar_kit.json`'da tanımlı.
- MVP'de görselli sayfaya düşen her ana beat'in `beatPoses`'ta açık bir karşılığı var. Bu beat'ler notice_anomaly, approach, examine, hesitate, commit, succeed ve restore; liste test içinde compose çıktısından yeniden üretilir. Yalnızca `rolePoses`'a düşen beat varsa test bunu boşluk olarak raporlar.
- Her sahnenin `defaultPose`'u kendi `allowedPoses` listesinde.

Böylece bir poz eklemek, ya da bir beat'in pozunu değiştirmek, yalnızca veri değişikliğidir.

**Sonuç (problem ve resolution aynı poza düşmesin):** 4. sayfa (hesitate) `standing`, 7. sayfa (succeed) `celebrating` alır. Planın ilk sürümünde ikisi de durağan pozlara düşüyordu.

### 3.2.2 Sahne katmanları (v2)

**Olgu.** İlk plan bir sahneyi `background` + `foreground` olarak tanımlıyordu.

**Öneri.** Şema, sıralı ve rolü belli bir katman listesi taşır. V1 yer tutucuları yalnızca arka plan ve ön plan kullanır; diğer katmanlar şemada opsiyoneldir.

```json
"layers": [
  { "role": "background", "asset": "Scenes/scene_forest_hook_01_v1_bg" },
  { "role": "midground",  "asset": "…", "optional": true },
  { "role": "props",      "asset": "…", "optional": true },
  { "role": "avatar" },
  { "role": "companion" },
  { "role": "foreground", "asset": "…", "optional": true },
  { "role": "lighting",   "asset": "…", "optional": true, "blend": "multiply" }
]
```

Kurallar:
- Avatar ve yol arkadaşının derinliği **listedeki sıradan** gelir. Bir dal çocuğun önüne mi arkasına mı düşecek, sahneyi çizen kişi karar verir; kod sabitlemez.
- `lighting` boyanmış bir sanat katmanıdır, kodla üretilen bir gradient değildir. Design law gradient'e malzeme taklidinde izin veriyor.
- `quietBand` (opsiyonel): ArtKit'teki `textSafe` ile aynı biçim. Bugün okuyucuda sahnenin üstüne metin binmiyor; bu alan tam sayfa düzen gelirse diye şemada durur.

**Asset ekonomisi.** Tek bir orman arka planı; ayakta, yürüyen ya da uzanan bir çocukla ve tilki ya da tavşanla birleşebilir. Varlık sayısı sahne × poz × yol arkadaşı çarpımına çıkmaz; ilk plan da buna dayanıyordu. `props` katmanının beat'e göre değiştirilmesi (aynı arka plan + farklı nesne) bir V2 olasılığı olarak şemada açık bırakılır. V1'de kullanılmaz, çünkü her varyant ayrı bir içerik onayı demek.

**Okuma geçmişi için yeni anahtar yok.**
- Olgu: `read_history_<UUID>` yalnızca blueprint ID'lerini tutuyor.
- Öneri: son N sahne, çocuğun kayıtlı masallarındaki plate'lerden türetilir. Bu, `recentModes(for:)` ile aynı desen.
- Böylece yeni bir UserDefaults anahtarı açılmaz ve profil silinince geçmiş de masallarla birlikte gider.

### 3.3 Katman ve sahiplik haritası

**Yeni dosyalar.** Hepsi senkronize klasörlerde; pbxproj düzenlemesi gerekmez.

| Dosya | Faz | Sahip ajan | Not |
|---|---|---|---|
| `Screens/ArtKit/SceneBook/AvatarSpec.swift` | 1 | character-system | Codable, versiyonlu, `descriptors()` |
| `Screens/ArtKit/SceneBook/AvatarKit.swift` + `Screens/ArtKit/avatar_kit.json` | 1 | illustration-system (descriptor eşlemesi: character-system) | |
| `Screens/ArtKit/SceneBook/SceneLibrary.swift` + `Screens/ArtKit/scene_library.json` | 1 | illustration-system | |
| `Screens/ArtKit/SceneBook/SceneSelector.swift` | 1 | illustration-system | saf |
| `Screens/ArtKit/SceneBook/StoryIllustration.swift` | 1 | library-memory (şema) | anlık görüntü tipleri, §4 |
| `StoryEngineBridge/IllustratedBookBinder.swift` | 1 / 4 | illustration-system, story-engine gözden geçirir | ComposedStory + avatar → plate'ler |
| `StoryEngineBridge/AvatarStore.swift` | 4 | character-system | `FileBackedStore<AvatarSpec>("Avatars")` |
| `Screens/ArtKit/SceneBook/AvatarView.swift` | 2 | illustration-system; design-system gözden geçirir | yer tutucu vektör + varlık katmanları |
| `Screens/ArtKit/SceneBook/StorySceneView.swift` | 3 | illustration-system; reader gözden geçirir | okuyucu, PDF ve galerinin tek kaynağı |
| `Screens/Parent/BookCharacterView.swift` | 4 | parent-ux | işlevsel ilk sürüm; görsel tasarım Zehra'da |
| `Screens/ArtKit/SceneBook/SceneLibraryGallery.swift` | 5 | illustration-system | `#if DEBUG` |
| `Tools/sync_scenes.py`, `docs/art/SCENE_LIBRARY_BRIEF.md` | 5 | illustration-system | |
| `MagicPaperTests/SceneSelectorTests.swift`, `AvatarKitTests.swift`, `StoryIllustrationPersistenceTests.swift` | 1+ | — | |

**Dokunulacak paylaşılan dosyalar.** Her değişiklik asgari tutulur ve sahibine bildirilir.

| Dosya | Sahip | Değişiklik | Neden |
|---|---|---|---|
| `Models/Story.swift` | library-memory (D4) / story-engine | `Story.illustration: StoryIllustration?`, `StoryPage.scene: ScenePlate?` | anlık görüntü masalla birlikte saklanmalı (kural 7) |
| `Services/StoryGenerationManager.swift` → `createStory` | story-engine (D1) → library-memory (D4) | compose'dan sonra binder'a tek çağrı, yaklaşık 4 satır | Faz 4. `createCustomStory`'ye dokunulmaz. **Aynı anda başka ajan bu dosyada olmamalı.** |
| `Screens/StoryReader/ReaderStory.swift` | reader | `ReaderPage.scene`, `hasIllustration`, plate'li sayfada `imageLabel = altTextTR` | |
| `Screens/StoryReader/StoryPageView.swift` | reader | plate varsa `PageIllustration` yerine `StorySceneView` | |
| `Screens/StoryReader/StoryLeafView.swift` | reader | `imageRef != nil` yerine `hasIllustration`; dekorasyon yoğunluğu | §5 |
| `Screens/MPStoryPDF.swift` | reader / library | sahne çizimi; `makePDF` `async` olur | §5.3 |
| `Screens/MPSheets.swift`, `Screens/Parent/ParentOverviewView.swift` | parent-ux | `makePDF` çağrısına `await` eklenir (birer token) | §5.3 |
| `Views/SettingsView.swift` (`developerSection`) | parent-ux | DEBUG satırları: bayrak, örnek avatar, örnek masal, sahne galerisi | Faz 6 |
| `Screens/MPAppState.swift`, `ContentView.swift` | parent-ux | `showSceneGallery`, `.bookCharacter(UUID)` sheet | |
| `Screens/MPSheets.swift` (profil düzenleme) | parent-ux | "Kitap karakteri" satırı | |
| `Services/ProfileManager.swift` → `deleteProfile` | parent-ux / library-memory | `AvatarStore.delete(id:)` için tek satır | silme yolu |
| `DesignSystem/MPTheme.swift` → `MP.Palette` | design-system | ten ve saç tonu token'ları, `C.avatarSkin` / `C.avatarHair` grupları | `Color(hex:)` yalnızca Palette'te olabilir; avatar paleti için yeni istisna grubu |

**Dokunulmayacaklar:**
- `StoryEngine/` paketinin tamamı: kaynak, kaynak dosyaları, `lexicons.json`, `visual_catalog.json`, fixture'lar
- `FalImageProvider`
- `createCustomStory`
- `ImagePicker`, `saveProfileImage`, `FirebaseImageUploader`
- Paywall, RevenueCat ve `Capability.swift`

Tek istisna olasılığı `lexicons.json`. Bkz. §8 çelişki 2.

---

## 4. Kalıcılık kararı

### 4.1 Avatar nerede saklanır

**Olgu.**
- `FileBackedStore<Value>` (`StoryEngineBridge/FileStores.swift`) kayıt başına bir JSON dosyası yazıyor. Atomik yazıyor, `.completeUnlessOpen` koruması uyguluyor ve çözülemeyen dosyayı `nil`'den ayırıyor.
- `CharacterProfile` ve `FileCharacterStore` bugün ölü yolda: `StoryEngineContainer` hiçbir yerden çağrılmıyor. Canlandırmak bu görevin kapsamı dışında (görev §7).

**Öneri.**
- Avatar `FileBackedStore<AvatarSpec>(subdirectory: "Avatars")` ile `Documents/…/Avatars/<profileUUID>.json` olarak saklanır.
- Ayrı bir karakter modeli değildir. İçinde yalnızca kit parça ID'leri ve şema sürümü vardır.
- Görünüşün **anlamı** `descriptors()` ile CharacterEngine sözlüğüne eşlenir.
- B1 geldiğinde köprü şu olur: `ProfileCharacterSource.makeProfile(parentProvidedDescriptors: spec.descriptors())`. Bugün bağlanmaz.
- Silme: `deleteProfile` avatarı da siler.
- D4 göçü `user_profiles` ve `stories` üzerinde çalışıyor; `Avatars/` ile çakışmaz.

### 4.2 Masalla birlikte saklanan anlık görüntü

**Olgu (kritik).**
- Masallar `UserDefaults["stories"]` içinde **tek bir JSON dizisi** olarak duruyor ve `[Story]` olarak çözülüyor (`StoryGenerationManager.loadStories`).
- Koddaki yorum, tanınmayan tek bir enum değerinin bütün kütüphaneyi düşürebildiğini söylüyor.
- 1 MB üstünde uyarı veriliyor.

**Yorum.** Yeni alanlardaki herhangi bir çözme hatası bir çocuğun bütün rafını götürebilir. Şema bu yüzden enum değil, düz tipler kullanmalı ve **atmayan** bir çözücüye sahip olmalı.

**Öneri: şema.** Tüm alanlar String, Int ya da Double; Swift enum'u yok.

```swift
// Story'ye eklenir
var illustration: StoryIllustration?      // nil = metin kitabı (bugünkü her masal)

struct StoryIllustration: Codable, Equatable {
    var schemaVersion: Int                // 1
    var avatar: AvatarSpec                // o anki hâli: kopya, referans değil
    var avatarKitVersion: String
    var avatarArtVersion: Int             // v2
    var sceneLibraryVersion: String
    var gaps: [CoverageGapRecord]         // geliştirici galerisi ve testler için
    // init(from:) ASLA atmaz: bozuk ya da tanınmayan içerik → boş/geçersiz
    // işaretli değer. Kütüphane çözülmeye devam eder.
}

struct AvatarSpec: Codable, Equatable {
    var schemaVersion: Int
    var skinTone: String, hairStyle: String, hairColor: String,
        outfit: String,                   // v2: "outfit_blue" bugün, "outfit_yellow_raincoat" yarın
        accessory: String?                // kit parça ID'leri
}

// StoryPage'e eklenir
var scene: ScenePlate?

struct ScenePlate: Codable, Equatable {
    var sceneID: String                   // "scene_forest_hook_01"
    var sceneVersion: Int                 // v2: gerçek pin, aşağıya bakın
    var pose: String                      // "standing"; tanınmazsa sahnenin defaultPose'u
    var facing: String                    // "left" | "right"
    var companionID: String?              // tanışmadan önceki sayfalarda nil
}
```

`outfit` neden `outfitColor` değil (v2): alan bir **kıyafet ID'si** taşır.
- V1'de her kıyafet aynı biçimin bir rengidir (`outfit_blue`, `outfit_green` …), şablon boyamayla çizilir.
- İleride yağmurluk gibi ayrı bir biçim aynı alana yeni bir ID olarak girer. Şema değişmez.
- Her kıyafet seçeneği kendi descriptor'ını taşır.

**Neyin donduğu: sürüm sabitleme (v2).**
- **Donar:** avatar parça ID'leri, avatar sanat sürümü (`avatarArtVersion`, kit düzeyinde), sahne ID'si **ve sahne sürümü**, poz, yön, yol arkadaşı.
- Manifestte bir sahnenin birden çok sürümü durabilir. Her sürüm kendi katmanlarını ve anchor'larını taşır; varlık adına sürüm eklenir (`scene_forest_hook_01_v1_bg`).
- Kitap, sakladığı sürümle açılır. 2026'da çizilmiş kitap, sahne 2027'de yeniden çizilse de 2026 sanatıyla açılır; avatar da donmuştur. Böylece tek bir anlık görüntü mantığı olur.
- Anchor her zaman sürümün kendisinden okunur. Sürüm kendi sanatıyla birlikte geldiği için yanlış konuma basma riski yoktur.

**Sabitlemenin iki bilinçli istisnası:**
1. **Yer tutucu sürümler** (`placeholder: true`) sabitlenmez. Kitap aynı ID'nin en yeni onaylı sürümüne yükselir. Aksi hâlde Faz 6'da yer tutucuyla üretilmiş her kitap gerçek sanatı hiç görmez.
2. **Pakette olmayan sürüm.** Eski sürümler pakette kalır; bu, uygulama boyutuna eklenen bir maliyettir. Bir sürüm bilinçli olarak emekliye ayrılır ve paketten çıkarılırsa (`lifecycle: retired`), kitap aynı ID'nin en yeni onaylı sürümüne düşer. ID'nin hiç onaylı sürümü kalmadıysa sayfa metin sayfası olarak çizilir ve gap kaydı düşülür.

**Kitten kaldırılmış bir avatar parça ID'si:** o gruptaki kit **varsayılanı** kullanılır. Hiçbir durumda rastgele seçim yapılmaz.

**Boyut maliyeti:** her saklanan sahne sürümü yaklaşık 2–5 MB (2048 × 1536 PNG, katmanlarla). Emekliye ayırma kararı Zehra + Batuhan'ındır; politika §9'a eklendi.

**Avatar sanatı için kapsam:** `avatarArtVersion` V1'de saklanır ama tek bir sürüm vardır. Avatar parçaları için çoklu sürüm desteği, ilk gerçek avatar sanatı yenilendiğinde aynı mekanizmayla eklenir. Alan bugünden saklandığı için eski kitaplar o gün de doğru sürümü bilir.

**Boyut.** Masal başına yaklaşık 0,6–1 KB eklenir. 100 masalda yaklaşık 100 KB eder; 1 MB uyarı eşiğinin çok altında.

### 4.3 Eski JSON'ların çözülebilir kaldığının kanıtı

**Olgu.**
- `Story` ve `StoryPage` sentezlenmiş `Codable` kullanıyor; özel `init(from:)` yok.
- Sentezlenmiş çözücü `Optional` özellikleri `decodeIfPresent` ile okur. Anahtar yoksa değer `nil` olur, hata atılmaz.
- `childProfileID`, `lastReadAt` ve `origin` alanları da aynı yolla eklendi ve eski kütüphaneler çözülmeye devam etti.

**Faz 1'de kanıtı testle bağlayacağım** (`StoryIllustrationPersistenceTests`):
1. B2 öncesi biçimde elle yazılmış bir `[Story]` JSON fixture'ı çözülür. Sonuç: `illustration == nil`, her sayfada `scene == nil`.
2. Görselli bir masal encode edilip decode edilir: değerler aynı kalır (round-trip).
3. `illustration` alanı bozuk ya da tanınmayan şema sürümlü bir masal, diğer masallarla aynı dizide çözülür. Kütüphane düşmez.
4. `LibraryMigration` üzerinden round-trip.

---

## 5. Okuyucu entegrasyonu

### 5.1 Karar: (a) canlı birleştirme

**Olgu.**
- `PageIllustration` dosya adını `ReaderImageLoader` ile `Documents/Stories/` altından yüklüyor.
- `StoryLeafView`'ın dekorasyon güvenli bölgeleri `imageRef != nil` sorusuna bakıyor.

**Öneri: (a).**
- Plate'li sayfada `StorySceneView`, `PageIllustration`'ın yerini alır.
- Önbellek gerekmeyebilir: katmanlar zaten paketteki görseller. Faz 3'te sayfa kıvrımı sırasında ölçülecek, gerekirse `.drawingGroup()` eklenecek.
- Gerekçe:
  - Depolama ve bayat dosya yok.
  - Kitap küçük bir JSON'dan yeniden kurulabilir; bu, cihaz değişimi sorusuna da yardım eder.
  - Yer tutucu sanat gerçek sanatla değiştiğinde eski kitaplar da güncellenir.

### 5.2 Görsel alanının gerçek oranı

**Olgu (koddan hesap).**
- Görsel yüksekliği `min(max(0.50h, 0.34h), 0.55h)`. Bu ifade **her zaman `0.50h`** verir.
- Yorumdaki "yazı büyüdükçe önce çizim yer verir" davranışı kodda yok.
- `textColumn` ise görsel yüksekliğini `0.55h` olarak düşüyor. İki değer tutarsız.

Hesaplanan değerler (yatay kenar `MP.S.x7`, dikey `x5 + x7`, güvenli alan içinde):

| Cihaz | Kullanılabilir h | Görsel kutusu | Kutu oranı | 4:3 sahne genişliğe sığınca |
|---|---|---|---|---|
| iPhone SE (3. nesil) | ≈ 595 pt | 311 × 298 | ≈ 1,04 : 1 | 311 × 233 (h'nin %39'u) |
| iPhone 17 Pro Max | ≈ 808 pt | 376 × 404 | ≈ 0,93 : 1 | 376 × 282 (h'nin %35'i) |

Bunlar hesap. Faz 3'te ekran görüntüsünden ölçülerek doğrulanacak.

**Yorum.** Kutu yaklaşık kare. Kare sanat kutuyu doldurur ama metne yer bırakmaz; 4:3 sanat genişliğe sığar ve sayfanın %35–39'unu alır. Bu, %34–55 bandının içinde ve büyük yazı boyutunda metne nefes payı bırakır.

**Öneri.**
- Sahne oranı **4:3**, en az 2048 × 1536 px.
- Pro Max'te @3x yaklaşık 1130 px, PDF'te 300 dpi'de yaklaşık 1420 px gerekiyor; 2048 rahat.
- Sahne çerçevesi yüksekliği `min(genişlik × 3/4, 0.55h)` olur ve üste hizalanır.
- `0.50h` sabitinin düzeltilmesi ayrı bir okuyucu işidir. Plate'siz sayfalara dokunulmaz.

### 5.3 PDF

**Olgu.**
- `MPStoryPDF.makePDF` iki yerden `Task.detached` içinde çağrılıyor (`MPSheets.swift:104`, `ParentOverviewView.swift:57`).
- `ImageRenderer` `@MainActor` ister.

**Öneri.**
- `makePDF` `async` olur.
- Önce sahneleri `await MainActor.run { ImageRenderer(StorySceneView) }` ile `UIImage`'a çevirir, sonra mevcut UIKit çizimine devam eder.
- Sahne genişliği 340 pt, 4:3 → yaklaşık 255 pt yükseklik. Mevcut 240 pt'lik kare kutunun yerini alır.
- İki çağrı yerine yalnızca `await` eklenir.

### 5.4 Dekorasyon motoruyla çakışma

**Olgu.**
- Motor `illustrationSafeRect` parametresini zaten alıyor.
- `StoryLeafView` bu parametreye sabit bir değer veriyor: `(0.04, 0.05, 0.92, 0.50)`.
- Yoğunluk `DecorationDensity.forPage` ile belirleniyor.

**Öneri (reader sahibinin kararı).**
- Görselli sayfada yoğunluk `.sparse` olur.
- Güvenli bölge, sahne çerçevesinin gerçek oranından hesaplanır.
- Süs görsel bölgesine girmez.

### 5.5 Erişilebilirlik

- Plate'li sayfada `imageLabel` sahnenin `altTextTR` değerini kullanır. `visualScene` İngilizce olduğu için kullanılmaz.
- Önerim alt metinde çocuk adı yer tutucusunu V1'de **kullanmamak**. VoiceOver zaten sayfa metninde adı okuyor; tekrar gürültü olur.

---

## 6. Avatar kiti: önerilen ilk sürüm

Bu liste, Zehra'nın kararı gelene kadar kullanılacak varsayılandır (§9). Etiketler biçim adıdır, cinsiyetsizdir.

| Grup | Seçenekler (Türkçe etiket) | Descriptor (kategori · en · tr) |
|---|---|---|
| skinTone | Açık · Buğday · Esmer · Koyu | skinTone · light / olive / brown / dark skin · açık / buğday / esmer / koyu ten |
| hairStyle | Kısa · Kıvırcık · Omuz hizası · At kuyruğu · Örgülü · Topuz | hair · short / curly / shoulder length / ponytail / braided hair · kısa / kıvırcık / omuz hizasında saç, at kuyruğu, örgülü saç, topuz |
| hairColor | Siyah · Kahverengi · Kumral · Sarı · Kızıl | hair · black / brown / auburn / blonde / red hair · siyah / kahverengi / kumral / sarı / kızıl saç |
| outfit | V1: tek biçim (tişört + pantolon), 6 renk: mavi · yeşil · sarı · turuncu · mor · kırmızı (`outfit_blue` …) | clothingDefault · "blue t-shirt" / "mavi tişört" … → onaylı varsayılan: `lexicons.json`'a eklenir (§8.2) |
| accessory | yok · Gözlük · Sırt çantası · Bere | **gözlük → `distinguishingFeature`** (accessory değil) · backpack · woolly hat |

Kurallar:
- **Descriptor dili:** `PromptConstraintCompiler` descriptor değerini görsel prompt'a **olduğu gibi** basıyor ve prompt İngilizce. Bu yüzden her seçenek `en` değerini (prompt, B1) ve `tr` değerini (metin kapısı) birlikte taşır. Test, ikisini kendi sözlüğünde arar.
- **Pozlar (v2: 8, öncelik sırasıyla):** `standing`, `walking`, `reaching`, `lookingUp`, `pointing`, `celebrating`, `sitting`, `sleeping`.
  - Poz alanı `String`. Yeni bir poz eklemek (`jumping`, `hesitating` …) yalnızca kit'e ve beat haritasına veri eklemektir.
  - Hangi beat'in hangi pozu aldığı §3.2.1'deki sözleşmede durur, burada değil.
  - Macera MVP'sinin görselli sayfaları `lookingUp`, `walking`, `reaching`, `standing`, `pointing` ve `celebrating` kullanır. `sitting` ve `sleeping` uyku ve gelişim modları için kitte durur.
- **Varlık tuvali (v2):**
  - Avatar katmanları sahneyle aynı boyutta **değil**. Poz başına ortak bir tuval: **512 × 768 px**, şeffaf; ayak noktası tuvalin alt orta noktası.
  - Gerekçe: Pro Max'te sahne yüksekliği yaklaşık 846 px (@3x), PDF'te yaklaşık 1060 px (300 dpi). Ölçeği yaklaşık 0,5 olan avatar ekranda 430, PDF'te 530 px'e çizilir; 768 px yeterli.
  - Şablon boyanacak katmanlar (ten, saç, kıyafet) tek kanallı maske olarak gelir.
  - Toplam paket boyutu Faz 2'de ölçülür. Kaba hesap: 8 poz × yaklaşık 18 katman ≈ 144 dosya.
- **Anchor'lar normalize kesirdir:** `x`, `y` ve `scale` 0…1 aralığında, tuvalin sol üst köşesine göre. Piksel değeri asla saklanmaz. Aynı manifest her çözünürlükte, okuyucuda ve PDF'te çalışır. Test, her anchor'ın aralıkta olduğunu doğrular.
- **Katman sırası:** hairBack → body (şablon) → outfit (şablon) → face → hairFront (şablon) → accessory. Yön ayna ile çözülür.
- **Örnekler:** `samples` alanında farklı ten, saç ve kıyafet kombinasyonlarıyla 3 hazır avatar durur. Faz 6 DEBUG düğmesi bunları kullanır.
- **Yol arkadaşı:** paketteki 4 türün hiçbirinin çizimi yok.
  - V1 yer tutucusu: tür başına sade bir siluet; yüz yok.
  - Gerçek varlık: 4 tür × yaklaşık 3 poz, ayrı bir teslim kalemi.

---

## 7. Faz 6 uçtan uca denemesi nasıl mümkün olacak

| Adım | Nasıl |
|---|---|
| 1a. Gerçek akış | Ebeveyn kapısı → Ebeveyn → Çocuklar → profil → **Kitap karakteri** (`BookCharacterView`). Önizleme `AvatarView` ile canlı güncellenir; Kaydet, `AvatarStore`'a yazar. |
| 1b. Hızlı yol (DEBUG) | Ayarlar → Geliştirici → **Örnek avatar oluştur**. `avatar_kit.json → samples` içinden sıradakini seçili profile atar. |
| 2. Masal | Normal akış (mod → yol arkadaşı). `illustratedBooksEnabled` DEBUG'da varsayılan olarak açık. **Örnek görselli masal** düğmesi `createStory(mode: .adventure, seed: "b2-demo-001")` çağırır ve `app.readerStory` ile okuyucuyu açar. Aynı seed her seferinde aynı masalı ve aynı plate'leri verir. |
| 3. Okuyucu | 1, 2, 4 ve 7. sayfalarda sahne görünür, kalan sayfalar metin sayfasıdır. Avatar her sahnede aynıdır. |
| 4. Avatar değişimi | Yeni masal yeni görünüşü alır; eski masal `illustration.avatar` kopyasıyla eski görünüşü korur. |
| 5. PDF | Masal detayı → PDF. Sahneler §5.3 yoluyla basılır. |
| 6. Uçak modu | Simülatörde uçak modu anahtarı yok. Üç katmanlı kanıt: (i) Mac ağı kapalıyken ya da Network Link Conditioner "100% Loss" profiliyle 1–5 tekrarlanır; (ii) B2 dosyalarında `URLSession` / `Fal` / `Gemini` / `Firebase` referansı olmadığını denetleyen bir grep testi; (iii) `createStory` yolunda bekleyen ağ çağrısı olmadığı kod incelemesiyle gösterilir. |

**Ön koşullar:**
- **iPhone SE simülatörü yüklü değil.** Yalnızca iPhone 17 Pro ve 17 Pro Max var. SE (3. nesil) cihaz tipi mevcut, ama iOS 27.0 runtime'ının bu cihazı destekleyip desteklemediği doğrulanmadı. Faz 6'dan önce `xcrun simctl create` ile denenmeli; desteklemiyorsa en yakın küçük ekran olarak iPhone 16e kullanılır ve bu raporlanır.
- **Git (düzeltme, v2).** İlk planda "proje git deposu değil" yazmıştım; bu yanlıştı. Depo `MagicPaper/.git` altında, aktif dal `design-system/magicpaper-redesign`, son commit `e3feeb6`. `git init` gerekmiyor; üst klasörde yeni bir depo açmak iç içe depo yaratırdı. Önerim: `b2/scene-library` dalı açmak ve bugünkü çalışma ağacını başlangıç noktası olarak commit'lemek. Çalışma ağacında paralel oturumların commit'lenmemiş işi olabileceği için bu adım **kullanıcı onayı bekliyor**.

---

## 8. Görev metniyle çelişkiler ve ön koşullar

1. **Varsayılan avatar.** Görev §4 Faz 4 iki şey söylüyor: "Avatar yoksa masal metin olarak çıkar" ve "Varsayılan avatar profil renginden türetilir; ebeveyn hiçbir şey seçmese de çalışır."
   - Profil renginden yalnızca kıyafet rengi türetilebilir. Ten ve saç için örtük bir varsayılan, uygulamanın çocuğun görünüşünü ebeveyn adına seçmesi demek.
   - Öneri: varsayılan avatar yalnızca kurulum ekranının **başlangıç önizlemesi** olsun. Görselli kitap, ebeveynin en az bir kez **Kaydet** dediği bir `AvatarSpec` gerektirsin; varsayılanı onaylamak da sayılır. Kayıt yoksa masal metin çıkar.
2. **Sözlük boşlukları.**
   - "Gözlük" `accessory` değil, `distinguishingFeature`. Bu basit bir eşleme düzeltmesi.
   - Sözlükte genel kıyafet rengi ifadesi yok ("red t-shirt" ya da "kırmızı tişört" geçmiyor). `clothingDefault` yalnızca belirli giysi + renk çiftleri içeriyor ("sarı yağmurluk" gibi).
   - Seçenekler: (a) character-system `lexicons.json`'a renk + tişört ifadeleri ekler; bu bir paket değişikliği olur. (b) Kıyafet seçimi, sözlükteki giysi + renk çiftlerine bağlanır.
   - (b) varlık sayısını çoğaltıyor; önerim (a).
3. **Görsel oranı.** Görev 4:3 öneriyor, ölçülen kutu yaklaşık 1:1 (§5.2). Gerekçesiyle 4:3'te kalmayı öneriyorum.
4. **`Development/AssetGallery/`.** Bu klasör hiçbir target'ta değil. Galeri `Screens/ArtKit/SceneBook/` altında `#if DEBUG` olarak yazılır; mevcut dekorasyon galerisi de `Screens/` altında duruyor.
5. **Erişim kancası.**
   - `Capability.illustratedStory` var, ama **ölçülü ve uzak maliyetli**: yıldız tüketiyor ve taze doğrulama istiyor. Sıfır maliyetli B2'yi buna bağlamak her kitap için yıldız düşürür.
   - Öneri: `IllustratedBookAccess.isEnabled(for:)` tek bir sorgu noktası olsun. Şimdilik yalnızca geliştirici bayrağına baksın: DEBUG'da açık, Release'te kapalı. `Capability.swift`'e dokunulmaz.
6. **Paralel oturumlar.** Belleğime göre paralel UI oturumları view ve DesignSystem dosyalarında çalışıyor olabilir. §3.3'teki paylaşılan dosyalara (özellikle `StoryGenerationManager`, `StoryPageView`, `MPTheme`) dokunmadan önce o oturumların durumu teyit edilmeli.

---

## 9. Açık sorular — karar verilmedi

| # | Soru | Sahip | Kod ne varsayıyor |
|---|---|---|---|
| 1 | İllüstrasyon yönü (çiz / satın al / üret); avatar ve sahne stili | Zehra | `storybook_painted_v1` ailesi, yer tutucu vektör |
| 2 | Avatar parça listesi: ten (4 mü 6 mı), saç biçimi ve renk sayısı, etiketler | Zehra (görünüm) + Batuhan (katman) | §6 tablosu |
| 3 | Kitap karakteri ekranının yeri ve görsel tasarımı; ilk görselli masaldan önceki davetin biçimi | Zehra | profil düzenleme sayfasında bir satır; davet V1'de yok |
| 4 | Görselli sayfa sayısı ve yaş bandına göre değişimi | İrem + Batuhan | kural A: 1, 2, 4, 7 |
| 5 | Görselli masal ücretsiz mi premium mu (A/B/C) | açık — gelir modeli | geliştirici bayrağı; paywall'a bağlı değil |
| 6 | Görselli sayfada dekorasyon davranışı | reader | `.sparse` + gerçek güvenli bölge |
| 7 | **Sahne kütüphanesinin içerik güvenliği onayı kimde?** **Gerçek varlık üretimini ve teslimini kilitler** (Faz 1–4'ün kodunu kilitlemez; yer tutucuları kod üretir) | **SAHİPSİZ — bir kişi adı gerekiyor** | yaşam döngüsü aşağıda; gerçek bir varlık `approved` olmak için `approvedBy` + `approvedAt` taşımak zorunda, test bunu denetler |
| 14 | Eski sahne sürümleri pakette ne kadar kalır, ne zaman emekliye ayrılır (§4.2) | Zehra + Batuhan | hiçbir sürüm emekliye ayrılmaz |
| 8 | Avatar kapakta görünsün mü? | Zehra + illustration-system | hayır; kapsam dışı |
| 9 | Varsayılan avatar politikası (§8.1) | Batuhan + privacy-safety | açık Kaydet olmadan görselli kitap yok |
| 10 | Kıyafet descriptor'ı: sözlüğe ekleme mi, giysi+renk eşlemesi mi (§8.2) | character-system | (a) önerildi; karar gelene kadar `clothingDefault` descriptor'ı üretilmez, test bunu bekler |
| 11 | Ortamlara `timeOfDay` / `settingIDs` ile ayırt etme (§1.4) | content-library | MVP sahneleri `settingIDs` ile |
| 12 | `0.50h` sabiti ve "yazı büyüyünce görsel küçülür" davranışı (§5.2) | reader | plate'li sayfada `min(w·3/4, 0.55h)`; diğer sayfalar değişmez |
| 13 | Yol arkadaşı çizimleri ayrı teslim kalemi mi? | Zehra | V1'de yer tutucu siluet |

### 9.1 İçerik yaşam döngüsü (v2)

Her sahne **sürümü** ve her avatar parça varlığı şu durumlardan birindedir:

| `lifecycle` | Anlamı | Yeni kitapta seçilir mi | Eski kitapta çizilir mi |
|---|---|---|---|
| `draft` | çizim sürüyor | hayır | — |
| `review` | onay bekliyor; geliştirici galerisinde görünür | hayır | — |
| `approved` | onaylı | **evet** | evet |
| `deprecated` | yeni kitaplara verilmez | hayır | **evet** (sabitlenmiş kitaplar bozulmasın) |
| `retired` | paketten çıkarıldı | hayır | aynı ID'nin en yeni onaylı sürümüne düşer (§4.2) |

Kurallar:
- `SceneSelector` yalnızca `approved` sürümü seçer.
- Bir gerçek varlığın `approved`'a geçmesi manifestte `approvedBy` ve `approvedAt` gerektirir. Test, bu iki alanı taşımayan, `placeholder: false` olan onaylı bir varlık bulursa başarısız olur.
- Onay süreci, ölçütler (görev §1.11: korkutucu, tehditkâr ya da cezalandırıcı imge yok; marka yok; cinsiyet kalıbı yok; resimde yazı yok) ve onaylayan kişi `docs/art/SCENE_LIBRARY_BRIEF.md` içinde belgelenir.
- Onaylayan kişi belirlenene kadar manifestte yalnızca `placeholder: true` olan onaylı varlıklar bulunabilir.

---

## 10. Faz sırası ve her fazın kabul ölçütü

| Faz | Çıktı | Kabul |
|---|---|---|
| 1 | AvatarSpec, manifestler, yükleyiciler, SceneSelector, Story alanları | §4.3'teki 4 test + görev §Faz 1'deki 8 test yeşil; app testleri 248/0 tabanından düşmez |
| 2 | AvatarView (yer tutucu), `UIImage` dışa aktarımı, avatar varlık boyutu ölçümü | 8 poz siluetten ayırt edilir; renk değişimi testi; tahmini paket boyutu raporlanır |
| **2.5** (v2) | **Varlık ve kompozisyon sözleşmesi** (yalnızca test + manifest denetimi, UI yok) | Sahne: oran 4:3 (±%0,5), tuval ≥ 2048 × 1536, `quietBand` ve anchor'lar 0…1. Avatar: tuval 512 × 768, alfa kanalı var, ayak noktası tutarlı, `facing` geçerli, scale 0…1. Birleşim: her sahne × her izinli poz için avatarın sınır kutusu tuvalin içinde, katman sırası manifestteki sırayla aynı. Gerçek sanat gelmeden matematiği doğrular; `sync_scenes.py` de aynı denetimi koşar |
| 3 | StorySceneView, okuyucu ve PDF bağlantısı | plate'siz masal piksel düzeyinde değişmez; PDF'te sahne çıkar |
| 4 | Binder, `createStory`, bayrak, kurulum ekranı, AvatarStore, silme | avatarsız masal B2 öncesiyle aynı: aynı seed'le üretilen `Story` JSON'u, `id` / `createdAt` / sayfa `id`'leri dışında **bayt düzeyinde eşit** |
| 5 | `sync_scenes.py`, galeri, brif dokümanı | manifest ↔ xcassets farkı sıfır |
| 6 | Uçtan uca deneme, ekran görüntüleri, `docs/B2_DEMO.md` | §7'deki 6 adım |

Her fazda koşulacak doğrulama: CLAUDE.md §9'daki beş grep (değişen dosyalarda boş), app build + test. Faz 1'den itibaren paket testi `--scratch-path` ile, Desktop dışında koşulur. Paket değişmediği için 647/18 tabanı korunmalı.

Mimari değiştiği fazda `docs/MagicPaper_Illustration_System.md` ve `docs/MagicPaper_Architecture.md` güncellenir.

---

## 11. Gözden geçirme sonucu (v2, 2026-10-01)

Kullanıcının ilettiği 14 maddelik değerlendirme işlendi.

| # | Değerlendirme | Karar | Nerede |
|---|---|---|---|
| 1 | Avatar masalla birlikte anlık görüntü | korundu | §4.2 |
| 2 | `outfitColor` → genişletilebilir `outfit` | **alındı** | §4.2, §6 |
| 3 | Beat → poz eşlemesi veride | **alındı**, `allowedPoses` ve üç adımlı çözümle | §3.2.1 |
| 4 | 6 poz az; problem ve resolution aynı poza düşüyor | **alındı**: 8 poz, `pointing` ve `celebrating` eklendi; succeed → `celebrating` | §3.2.1, §6 |
| 5 | 12 sahneyle başla, 16'yı hedefle | zaten böyleydi | §1.3 |
| 6 | Sahne yalnızca arka plan olmasın | **alındı**: sıralı katman listesi; V1 yer tutucuları iki katman kullanır; beat'e göre `props` varyantı V2'ye bırakıldı (her varyant ayrı içerik onayı) | §3.2.2 |
| 7 | Canlı birleştirme | korundu | §5.1 |
| 8 | `sceneVersion` gerçek bir sabitleme olsun | **değiştirilerek alındı**: kitap kendi sürümüyle açılır; iki istisna var: yer tutucular yükselir, emekliye ayrılan sürüm en yeni onaylıya düşer. Düz uygulansaydı yer tutucu kitaplar gerçek sanatı hiç görmezdi; ayrıca eski sürümlerin paket boyutu maliyeti açık soru olarak yazıldı | §4.2, §9 #14 |
| 9 | İçerik onayının sahibi + yaşam döngüsü | **alındı**: beş durumlu yaşam döngüsü + `approvedBy` testi. Sahibi hâlâ yok; bu durum **gerçek varlığı** kilitler, Faz 1'i kilitlemez | §9.1, §9 #7 |
| 10 | Açık Kaydet olmadan görselli kitap yok | korundu | §8.1 |
| 11 | 4:3 + normalize anchor | zaten böyleydi, açık kural ve test olarak yazıldı | §6 |
| 12 | Faz 2 ile 3 arasına varlık sözleşmesi | **alındı**: Faz 2.5 | §10 |
| 13 | Avatar tuvali sahneden küçük | **alındı**: 512 × 768, gerekçe hesapla; boyut Faz 2'de ölçülür | §6 |
| 14 | "Plate'siz masal değişmez" testi | **değiştirilerek alındı**: fingerprint yalnızca metnin girdilerinden hesaplanıyor, avatar onu hiç etkilemiyor; bu yüzden fingerprint testi kendiliğinden geçer ve bir şey kanıtlamaz. Yerine aynı seed'le üretilen `Story` JSON'unun bayt düzeyinde karşılaştırılması kondu | §10 Faz 4 |

Faz 1'in kapsamı bu değişikliklerle büyümedi. Yalnızca şema alanları (`outfit`, `avatarArtVersion`, `lifecycle`, `layers`, `allowedPoses`, `direction`) ve bunların testleri eklendi.

---

## 12. Faz 1 durumu (2026-10-01) — tamamlandı

**Geri alma noktası:** `b2/baseline` dalı, commit `1c023a3`. Çalışma ağacındaki izlenen dosyaların Faz 1 öncesi hâlini tutar. Geçici bir index ile oluşturuldu; HEAD, index ve aktif dal (`design-system/magicpaper-redesign`) değişmedi. İzlenmeyen dosyalar dahil değil.

**Eklenenler:** `Screens/ArtKit/SceneBook/` (AvatarSpec, AvatarKit, SceneLibrary, SceneSelector, StoryIllustration), `Screens/ArtKit/avatar_kit.json`, `Screens/ArtKit/scene_library.json` (12 yer tutucu sahne), `StoryEngineBridge/IllustratedBookBinder.swift`, 4 test dosyası (54 test).

**Değişen paylaşılan dosyalar:**
- `Models/Story.swift`: `Story.illustration` ve `StoryPage.scene`, ikisi de opsiyonel.
- `CharacterEngine/Resources/lexicons.json`: 6 en + 6 tr kıyafet ifadesi.

**Doğrulama:**
- Uygulama: 302 test, 0 hata, 1 atlanan (atlanan test önceden vardı). Yeni testlerin 54'ü de geçti.
- Paket: 804 test, 18 hata. Başarısız olan 10 test, sözlük değişikliği olmadan koşulan kopyadakiyle **birebir aynı** (bilinen içerik hataları); yeni hata yok.
- Değişen dosyalarda CLAUDE.md §9 denetimleri boş döndü. `print`, `Logger` ve ağ referansı da yok.

**Ortam olgusu:** Desktop iCloud "depolamayı optimize et" ayarı 818 proje dosyasını boşaltmıştı; aralarında `.git/objects` da vardı. Bu durumda derleme, test ve git takılıyor. `brctl download` ile geri indirildi. Kalıcı çözüm kullanıcının kararı: klasörü iCloud dışına taşımak ya da "Her zaman bu Mac'te tut" seçeneğini açmak.

---

## 13. Faz 2 — avatar çizimi (2026-10-01)

**Eklenenler**
- `Screens/ArtKit/SceneBook/AvatarFigure.swift`: yer tutucunun saf geometrisi (CoreGraphics). 8 pozun iskeleti; saç biçimleri ve kafa aksesuarları kafanın yerel koordinatında çizilir, kafa eğilince birlikte döner.
- `Screens/ArtKit/SceneBook/AvatarView.swift`:
  - katmanları kitin sırasıyla çizer;
  - yönü aynalar;
  - `renderImage(...)` ile 512 × 768 şeffaf `UIImage` verir (B1 köprüsü, bağlı değil);
  - gerçek varlık sözleşmesi `AvatarArt` içinde.
- `MagicPaperTests/AvatarViewTests.swift`.
- `avatar_kit.json`: kıyafet seçeneklerine `shape: "tshirt"`. Varlık adı rengi değil biçimi taşır.

**Paylaşılan dosya:** `DesignSystem/MPTheme.swift` (design-system). Yalnızca ekleme yapıldı:
- `MP.Palette`'e 4 ten ve 5 saç tonu;
- `MP.C.avatarParts` (kit token adı → renk) ve `MP.C.avatarInk`.

Kıyafet renkleri var olan palet renkleridir (deniz, yeşim, hardal, mercan, lila, gül). Paleti doğrudan okuyan yerler listesine `C.avatarParts` eklendi; dosya başındaki yorum güncellendi. CLAUDE.md §9'daki istisna listesinin de güncellenmesi design-system'in onayına bağlı.

**Gerçek varlık sözleşmesi**
- Ad: `Avatar/<poz>_<katman>[_<varyant>]`. Varyant şöyle belirlenir:
  - saç katmanlarında saç biçimi;
  - kıyafette `shape`;
  - aksesuarda aksesuarın kimliği.
- Boyanan katman (ten, saç, kıyafet) tek kanallı bir maskedir. Çizgisi boyanmayan ayrı bir `_line` varlığıdır.
- Zorunlu katmanlar: gövde, yüz, ön saç, kıyafet. Biri eksikse o poz tamamen yer tutucuyla çizilir; yarım bir karışım çizilmez.

**Boyut ölçümü (Faz 2 kalemi).** Gerçek sanat yok, bu yüzden ölçüm bir yaklaşımdır: 512 × 768 tuvalde dokulu bir maske yaklaşık 41 KB, dokulu RGBA çizgi katmanı yaklaşık 97 KB tutuyor. Poz başına 26 dosya düşüyor: arka saç 4 biçim, ön saç 5 biçim, gövde ve kıyafet maske + çizgi olarak, yüz 1, aksesuar 3. Hesap:
- poz başına ≈ 1,8 MB;
- **8 pozda ≈ 14 MB (208 dosya)**.

Gerçek boyanmış doku bunu iki katına çıkarabilir. Azaltma seçenekleri, Zehra'nın varlık brifine girdi olarak:
- yüzü pozlar arasında paylaşmak;
- çizgi katmanlarını gri tonlamalı vermek;
- kalite kaybı olmuyorsa HEIC kullanmak.

### 13.1 Yer tutucu karakter yeniden çizildi (2026-10-02)

İlk yer tutucu (çubuk uzuvlar) kullanıcı tarafından reddedildi: "çok tatlı olması gerekiyor". Yeni figür sevimli çocuk karakteri kurallarıyla çizildi:
- 2,5 baş boyu (chibi), armut gövde;
- iri ve aralıklı gözler: beyaz göz, iris, iki ışık noktası;
- allık, kalkık burun, açık gülümseme;
- hacimli saç, tombul uzuvlar, yuvarlak eller ve ayakkabılar.

Kaynaklar: tutsplus "Elements of Cute Character Design" ve "How to Draw Children", Clip Studio chibi oran rehberleri. Referans: kullanıcının verdiği Shutterstock "cute diverse children avatar" seti. Çizim kopyalanmadı; yalnızca stil ilkeleri alındı.

Yeni test: göz beyazı her tende tenden ayrılıyor; koyu tende yüzün okunmaması sorunu kapandı.

CLAUDE.md'nin suluboya/editoryal yönüyle bu düz vektör tarz arasındaki fark bilinçli bir yer tutucu kararıdır. Nihai stil Zehra'nın kararı (§9 #1).

---

## 14. Faz 3 — sahne okuyucuda ve PDF'te (2026-10-02)

**Eklenenler**
- `Screens/ArtKit/SceneBook/StorySceneView.swift`:
  - `StorySceneView`: katmanları sırayla çizer; avatar ve yol arkadaşı ayak noktası anchor'ında durur;
  - `ResolvedScene`: plate + sabitlenen sürüm + avatar; çözülemezse sayfa metin sayfası kalır;
  - `ScenePlaceholderBackground`: gökyüzü, uzak ve yakın sıra, zemin, patika, motifler;
  - `CompanionView`: tilki, kirpi, tavşan ve baykuş için sevimli yer tutucular; tanınmayan tür için hiçbir şey çizilmez;
  - `renderImage` (PDF için).
- `ScenePlate.companionKind`: katalogdaki `type`. Seçim anında kopyalanır, böylece okuyucu kataloğa bağımlı kalmaz.
- `MagicPaperTests/StorySceneTests.swift` (10 test) ve `TestBitmap.swift` (ortak piksel okuyucu).

**Paylaşılan dosyalar** (asgari değişiklik):

| Dosya | Sahip | Değişiklik |
|---|---|---|
| `StoryReader/ReaderStory.swift` | reader | `ReaderPage.scene`, `hasIllustration`; sahneli sayfada `imageLabel = altTextTR` |
| `StoryReader/StoryPageView.swift` | reader | sahne varsa `StorySceneView`, yükseklik `min(sütun × 3/4, 0.55h)`; sahnesiz sayfa değişmez |
| `StoryReader/StoryLeafView.swift` | reader | sahneli sayfada süs `.sparse`, güvenli bölgeler sahnenin gerçek yerine göre |
| `Screens/MPStoryPDF.swift` | reader / library | `makePDF` `async`; sahneler ana iş parçacığında görüntüye çevrilir, sütun genişliğinde 4:3 basılır |
| `Screens/MPSheets.swift`, `Parent/ParentOverviewView.swift` | parent-ux | `makePDF` çağrısına `await` (birer token) |
| `DesignSystem/MPTheme.swift` | design-system | `MP.SceneTone`, `C.sceneTones` (3 ton), yol arkadaşı ve avatar yüz token'ları; hepsi mevcut paletten |

**Doğrulama**
- Uygulama: 331 test, 0 hata, 1 atlanan (atlanan test önceden vardı).
- Okuyucu sayfası iPhone SE ve Pro Max boyutlarında, üç okuma temasında `ImageRenderer` ile çizildi. Sahne doğru boyutta ve yerde.
- **Bilinen sınır:** `ImageRenderer`, `ScrollView` içindeki metni çizmiyor. Metin düzeni ve en büyük Dynamic Type, Faz 4 bağlantısından sonra simülatör ekran görüntüleriyle doğrulanacak.

**Açık konular**
- Dekorasyon motorunun sahneli sayfadaki davranışı (`.sparse` + yeni güvenli bölgeler) reader sahibinin onayını bekliyor (§9 #6).
- Plate'siz sayfalardaki eski `0.50h` / `0.55h` tutarsızlığına dokunulmadı (§9 #12).

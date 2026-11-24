# İrem Tasarım Aktarımı Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** İrem'in `irem` dalındaki yeni ekranlarını, inceleme bulguları düzeltilmiş ve tasarım kanununa uygun hâlde main'e almak.

**Architecture:** Worktree `.claude/worktrees/irem-aktarim` (dal `irem-aktarim`, kaynak `origin/irem`). İrem'in kodu yerinde kalır; her düzeltme küçük, ayrı bir commit. Görünüşte karar veren metin ve listeler saf statik fonksiyonlara çıkarılır ki testlenebilsin; görünümler yalnızca onları çizer.

**Tech Stack:** SwiftUI (iOS 17+, iOS 26 cam), XCTest, `Scripts/ci_screenshots.sh`.

**Spec:** `docs/superpowers/specs/2026-11-24-irem-tasarim-aktarimi-design.md`

## Global Constraints

- Yalnızca bu worktree'de çalış; `/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper` checkout'una (dal `codex/design-system-catalog`, kirli) dokunma.
- Testler, derleme ve simülatör **yalnızca Task 7'de bir kez** (Batuhan'ın kuralı: ara adımda kod okuyarak çöz). Ara görevlerde testler yazılır ama koşulmaz.
- Tasarım kanunu: token'lar `MP.*` / `MPSpacing` / `MPColor`; çıplak sayı, `.shadow(`, `Color(hex:` yok; Ragi yalnızca `MascotImage`/`MascotSays`/`MPStateView`; ekran başına en fazla bir Ragi.
- Dil: masal "yazılır"; "üret/oluştur/hemen/anında" yok; çocuğa süre ve sayaç baskısı yok.
- Her etkileşimli öğenin Türkçe `accessibilityLabel`'ı; süs `accessibilityHidden(true)`.
- Commit sonu: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Push ve main'e alma yok (Batuhan onayı).

## Review Focus

1. Ücretsiz planda günün masalı okunmuş, hak bitmiş akşam: akşam kartı kilit penceresine değil kitaplığa gitmeli (Task 2 testi).
2. Küçük kademe (bilgi kartları gizli) ve en büyük yazıda selam: koyu mor üstünde beyaz, ≥ 4.5:1 (Task 2 kontrast testi).
3. Daha önce Ragi avatarı seçmiş çocuk: Profil, Masal ailem ve seçici boş profil resmine düşmeli, çökmemeli (Task 4 testi).
4. Tekrar okunan masalın sonu: yıldız ve çıkartma yok, dakika kartı da yok; kazanılan listesi boş kalabilir (Task 1 testi).
5. Uyku vaktinde masal sonu: gece yaprağı değişmeden kalır, "Bir masal daha" zaten yoktu (Task 1'de gece sütununa dokunulmaz).

---

### Task 1: Masal sonu — "Bir masal daha" ve dakika kartı kalkar

**Files:**
- Modify: `MagicPaper/Screens/StoryReader/StoryEndingLeaf.swift` (dosya başı belge yorumu, `onAnother`, `earned`, `dayColumn` ~200-240)
- Modify: `MagicPaper/Screens/StoryReader/StoryLeafView.swift:26,66` (`onAnother` parametresi ve iletimi)
- Modify: `MagicPaper/Screens/StoryReader/StoryReaderView.swift:234-237` (`onAnother:` kapanışı)
- Test: `MagicPaperTests/StoryEndingEarnedTests.swift` (yeni)

**Interfaces:**
- Produces: `enum StoryEndingEarned { static func ids(isFinished: Bool, hasBadge: Bool, newWords: Int) -> [String] }` — sıra `["sticker", "badge", "star", "words"]` süzülmüş hâli. `StoryEndingLeaf.earned` kimlikleri bundan alır, ikon/metin eşlemesini kendisi yapar.

- [ ] **Step 1: Testi yaz**

```swift
final class StoryEndingEarnedTests: XCTestCase {
    func testAFirstFinishEarnsStickerBadgeStarAndWordsButNeverMinutes() {
        XCTAssertEqual(StoryEndingEarned.ids(isFinished: false, hasBadge: true, newWords: 3),
                       ["sticker", "badge", "star", "words"])
    }
    func testARereadEarnsNoStickerAndNoStar() {
        XCTAssertEqual(StoryEndingEarned.ids(isFinished: true, hasBadge: false, newWords: 0), [])
    }
}
```

- [ ] **Step 2: `StoryEndingEarned.ids` yaz; `earned` onu kullansın.** `minutes` öğesi ve `streak.minutesThisWeek` okuması silinir (`MPStreak` başka bir şey için gerekmiyorsa `@StateObject streak` da kalkar).
- [ ] **Step 3: `dayColumn`'dan `MPButton(title: "Bir masal daha" …)` sil.** "Ana sayfaya dön" `kind: .onArt` kalır; ekranın tek eylemi o. Gece sütununa dokunma.
- [ ] **Step 4: `onAnother`'ı zincirden kaldır** (`StoryEndingLeaf`, `StoryLeafView`, `StoryReaderView`). `MPAppState.AfterReader.create` başka çağıranı yoksa da kalır (dokunma; ölü kod temizliği bu işin dışı). Belge yorumlarındaki "Bir masal daha" ve "haftalık dakika" sözlerini güncelle; gerekçe: "masal bitirmek bir olay, hemen yenisi değil (Batuhan, 24 Kasım 2026)".
- [ ] **Step 5: Commit** — `Masal sonu: "Bir masal daha" ve haftalık dakika kartı kalktı`

---

### Task 2: Ana sayfa — selam kontrastı, tek Ragi, sakin akşam kartı, "+" kalkar

**Files:**
- Modify: `MagicPaper/Views/HomeView.swift` (`header`, `modeSection`)
- Modify: `MagicPaper/DesignSystem/Pastel/MPHomeBoard.swift:43-160` (`HomeTonightBoard`)
- Modify: `MagicPaper/DesignSystem/MPTheme.swift:220-240` (`homeSky` durakları ve yorumu)
- Modify: `MagicPaper/Screens/MPAppState.swift:~132-140` (`openTonight` `.readToday` dalı)
- Test: `MagicPaperTests/HomeFeedTests.swift` (ekle), `MagicPaperTests/HomeTonightCopyTests.swift` (yeni)

**Interfaces:**
- Produces: `struct HomeTonightCopy: Equatable { let eyebrow, title, tag, button, icon: String; static func make(_ state: TonightState) -> HomeTonightCopy }` (`MPHomeBoard.swift` içinde). `HomeTonightBoard` metinlerini yalnızca buradan okur.
- Produces: `MP.C.homeSkyTextStop: Double` — selam ve alt satırın oturduğu, beyaz yazının ≥ 4.5:1 kaldığı son durak konumu.

- [ ] **Step 1: Kopyanın testi**

```swift
func testReadTodayIsCalmWhetherOrNotANewStoryCanBeWritten() {
    for canWrite in [true, false] {
        let copy = HomeTonightCopy.make(.readToday(canWrite: canWrite))
        XCTAssertEqual(copy.title, "Yarın yeni bir masal var")
        XCTAssertEqual(copy.button, "Kitaplığına bak")
        XCTAssertEqual(copy.icon, "books.vertical")
        XCTAssertFalse(copy.tag.contains("daha"))
    }
}
func testBedtimeCopyIsUnchanged() {
    let copy = HomeTonightCopy.make(.bedtime("20.30"))
    XCTAssertEqual(copy.title, "Uyku masalı zamanı")
    XCTAssertEqual(copy.button, "Uyku masalı yaz")
}
```

(`TonightState.bedtime`'ın gerçek ilişkili değer tipini `HomeFeed.swift`'ten al.) `readToday` etiketi: `"Kitaplığın hazır"` her iki durumda.

- [ ] **Step 2: Kontrast testi** (`HomeFeedTests`'e; yardımcıyı `StoryArtKitTests.contrast` mantığıyla test dosyasına kopyala, `UIColor(MP.Palette.…)` RGB'sinden):

```swift
func testTheGreetingSitsOnASkyDarkEnoughForWhiteText() {
    let underText = MP.C.homeSky.filter { $0.location <= MP.C.homeSkyTextStop }
    XCTAssertFalse(underText.isEmpty)
    for stop in underText { XCTAssertGreaterThanOrEqual(contrast(white, rgb(stop.color)), 4.5) }
}
```

- [ ] **Step 3: Kopyayı `HomeTonightCopy`'ye taşı**, `HomeTonightBoard` onu kullanır. `MPButton`'da simge görünmüyorsa (`moon.fill` ekran görüntüsünde boş yer bırakıyor): `MPIconMap`'te eşleme yoksa SF sembolüne düşüyor mu kontrol et (`MPIcon.swift:44-55`); eşleme eksikse `MPIconMap`'e ekle, yoksa simgeyi `moon` yap. "Kısa ve sakin" etiketi düğmeye benzemesin: dolgu kalkar, yalnızca `textOnArtMuted` metin (kenarlık/yüzey yok).
- [ ] **Step 4: Göğü düzelt.** Hedef: selam bloğu (düğmeler + "Merhaba" + alt satır) her kademede ve en büyük yazıda koyu mor üstünde. Yol: `header`'ı iki katmana böl — üst kısım (düğmeler + selam) `MP.C.homeSkyTop` (= `Palette.mor600`) düz zemin değil, `homeSky`'ın ilk durakları; geçiş (`mor400 → kagit0`) yalnızca bilgi kartlarının arkasında ya da kartlar yoksa selamın **altındaki** `MPSpacing.xxxl` yüksekliğinde bir şeritte başlar. `homeSkyTextStop`'u bu düzene göre tanımla. `MPTheme`'deki "Batuhan'ın onayına" notunu "Batuhan onayladı, 24 Kasım 2026" yap.
- [ ] **Step 5: Başlıktaki el sallayan Ragi'yi sil** (`HomeView.header`, `MascotImage(mascot: .waving …)` bloğu). Ekranın tek Ragi'si `HomeTonightBoard`'daki. Bilgi kartları kalkan boşluğu boşlukla doldurmaz; `HStack` selamı tam genişlikte bırakır.
- [ ] **Step 6: "+" kalkar.** `modeSection`'da `MPSectionHeader(title: "Yeni bir masal yaz")` `trailing` olmadan.
- [ ] **Step 7: `MPAppState.openTonight`, `.readToday`** her zaman `router.tab = .library` (fromSurface değilken). `canWriteNewStoryToday` başka çağıranı için kalır. Yorum: ses kaydı 2 gerekçesi.
- [ ] **Step 8: Commit** — `Ana sayfa: selam okunur, tek Ragi, sakin akşam kartı, artı kalktı`

---

### Task 3: Menü sheet'inde Ragi yok

**Files:**
- Modify: `MagicPaper/Screens/Journey/KidMenuSheet.swift:39-41`

- [ ] **Step 1:** `MascotSays(mascot: .waving, text: "Nereye gidelim, \(name)?" …)` yerine `MPSheet` başlığı ya da `Text("Nereye gidelim, \(name)?").mpText(.section)` + `.isHeader`. Belge yorumunu güncelle (arkadaki ana sayfanın Ragi'si yeter; ekran başına tek Ragi).
- [ ] **Step 2: Commit** — `Menü: Ragi'siz başlık (ekranda tek Ragi)`

---

### Task 4: Profil resmi seçicisinden Ragi çıkar

**Files:**
- Modify: `MagicPaper/Screens/Hero/ProfileAvatar.swift` (`Character`, `all`, belge yorumu)
- Modify: seçici görünümü (`ProfileAvatarPicker`, aynı dosya ya da `KidCornerView.swift`; `ProfileAvatar.of(` çağıranları)
- Test: `MagicPaperTests/ProfileAvatarTests.swift`

**Interfaces:**
- Produces: `ProfileAvatar.Character` yalnızca `.tarcin, .kestane`. `ProfileAvatar.named("ragi-…")` → `nil`.

- [ ] **Step 1: Testleri güncelle**

```swift
func testRagiIsTheMascotNeverTheChildsPicture() {
    XCTAssertTrue(ProfileAvatar.all.allSatisfy { !$0.id.hasPrefix("ragi-") })
    XCTAssertNil(ProfileAvatar.named("ragi-happy"))   // eski seçim boş resme düşer
}
```

`testIdsAreUniqueAndEveryCharacterHasFaces` içindeki `XCTAssertEqual(ProfileAvatar.of(.ragi).count, 15)` satırı silinir.

- [ ] **Step 2:** `case ragi` ve 15 `ragi-*` girdisini sil; seçicide Ragi bölümü/sekmesi varsa kaldır. `Assets.xcassets/Avatars/ragi-*` görselleri silinmez (başka yerde kullanılmıyorsa ayrı temizlik). Belge yorumu: "Ragi maskottur, çocuğun kimliği olmaz (Batuhan, 24 Kasım 2026)".
- [ ] **Step 3:** `HeroLookStore`'da kayıtlı `ragi-*` kimliği silinmez; `ProfilePhoto` zaten `named == nil`'de boş resmi çiziyor (`ProfileAvatar.swift:~73`). Bunu kod okuyarak doğrula.
- [ ] **Step 4: Commit** — `Profil resmi: Ragi maskot kalır, seçicide yok`

---

### Task 5: CI ekran turu menü sayfalarını açsın

**Files:**
- Modify: `MagicPaper/ContentView.swift:50-80` (DEBUG kancaları)
- Possibly: `MagicPaper/Screens/MPDebugLaunch.swift`, `Scripts/ci_screenshots.sh`

- [ ] **Step 1: Kök nedeni bul (superpowers:systematic-debugging, kod okuyarak).** Belirti: `-mpOpenKidPage badges` vb. ve `-mpOpenJourney` ile çekilen 8 sayfanın görüntüsü ana sayfanın birebir aynısı (md5 aynı); `-mpOpenMenu` ve `-mpOpenAvatarPicker` çalışıyor. Önce şu hipotezi sına: `.onAppear` anında `-mpDemo` profili henüz yüklenmemiş (`profileManager.currentProfile == nil`) ya da `openKidPage` yığına itmeden önce `NavigationStack` hazır değil. Menü ve avatar kancalarının profile/yığına bağlı olmadığına dikkat.
- [ ] **Step 2: Düzelt.** Hipotez doğruysa sayfa kancaları `.task { … }` içinde, `currentProfile` gelene kadar (`ProfileManager.shared.$currentProfile.values.first { $0 != nil }`) bekleyip `openKidPage` çağırır. Başka neden çıkarsa en küçük düzeltme.
- [ ] **Step 3: Commit** — `Ekran turu: menü sayfaları açılıyor`

---

### Task 6: Tasarım kanunu, belgeler ve günlük

**Files:**
- Modify: `/Users/batudemir/Desktop/MagicPaperAPP/CLAUDE.md` (repo dışı, kök) **ve** depodaki eşi varsa (`AGENTS.md`/`CLAUDE.md` — `git ls-files | grep -i claude.md` ile bul)
- Modify: `design-handoff/reference/DEMO_CHANGELOG.md` (en üste kayıt)

- [ ] **Step 1: "Derinlik" maddesine istisna ekle:** "Gradient … ve illüstrasyon üstü metnin karartması" cümlesinin ardına: "Çocuk alanında sayfa tepesinin mor göğü (`MP.C.homeSky`: ana sayfa, Profil, `MPSkyPage` menü sayfaları) ve gündüz masal sonunun zemini (`MP.C.endingSky`); yazı her zaman koyu durağın üstünde (karar: 24 Kasım 2026, Batuhan; İrem'in tasarımı)."
- [ ] **Step 2: "Current product decisions"a satır:** "Masal sonu tek eylem: 'Ana sayfaya dön'; 'Bir masal daha' yok, çocuğa okuma süresi gösterilmez (karar: 24 Kasım 2026, Batuhan). Profil resmi Tarçın/Kestane yüzlerinden; Ragi maskottur, profil resmi olmaz."
- [ ] **Step 3: DEMO_CHANGELOG kaydı** — başlık `### 2026-11-24 · irem-aktarim@<kısa sha> · İrem'in tasarımları aktarıldı`; maddeler: ne değişti (Task 1-5), ne bilerek değişmedi (Paywall yerleşimi, gece masal sonu, mantık değişiklikleri tutuldu), test sonucu (Task 7'den, dürüst), etkilenen dosyalar.
- [ ] **Step 4: Commit** — `Kanun: mor gök istisnası; günlük kaydı`

---

### Task 7: Tek doğrulama turu

- [ ] **Step 1: Kanun grep'leri** (CLAUDE.md "Doğrulama" bloğundaki altı komut, `MagicPaper/MagicPaper` yerine bu worktree'nin `MagicPaper` dizini). Beklenen: değiştirilen dosyalarda isabet yok (bilinen: `MPMascot.swift:45 "Üretim başarısız"`).
- [ ] **Step 2: Derle ve birim testleri koş** (tek DerivedData, disk ~4 GB):

```bash
xcodebuild test -project MagicPaper.xcodeproj -scheme MagicPaper -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/mp-dd -only-testing:MagicPaperTests | tail -40
```

Beklenen: `** TEST SUCCEEDED **`; yeni testler (`StoryEndingEarnedTests`, `HomeTonightCopyTests`, kontrast, avatar) geçer. Önceki başarısızlık varsa main'deki sayıyla karşılaştırıp günlüğe yaz.
- [ ] **Step 3: Simülatör görüntüleri** — `Scripts/ci_screenshots.sh`'i yerelde çalıştır (SE + Pro Max, normal + en büyük). Kontrol: ana sayfada tek Ragi ve okunan selam; masal sonunda "Bir masal daha" yok; menüde Ragi yok; 8 menü sayfası artık farklı görüntüler (md5'ler farklı); avatar seçicide Ragi yok.
- [ ] **Step 4:** Günlük kaydındaki test satırını gerçek sonuçla güncelle, commit. Batuhan'a: sonuçlar + "main'i `irem-aktarim`'e ileri saralım mı?" (onaysız birleştirme ve push yok).

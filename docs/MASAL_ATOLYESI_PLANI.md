# Masal atölyesi: "Masal yazılıyor" ekranının yeniden tasarımı

Durum: **uygulandı** (16 Ekim 2026). §9 kararlarının hepsi önerildiği gibi onaylandı.
Süreler 16 Ekim'de Batuhan'ın isteğiyle uzatıldı (ilk masal ~15 sn, bkz. §5). Uygulamada farklar: adım 3b (sevdikleri) v1'de yok, çünkü motor eşleşen ilgi alanını dışarı vermiyor. Mürekkep sabiti `MP.M.inkDuration` (2,8 sn) adıyla eklendi: bir eğri değil, harf harf ilerleyen bir tempo.
Ekran: 21 · Masal yazılıyor (ve 10 · İlk masal). Dosya: `MagicPaper/Screens/StoryCreation/StoryPreparationView.swift`.

---

## 1. Neden

Çevrimdışı motor masalı milisaniyede kuruyor. Bugünkü ekran dört aşamayı
0,38 saniye arayla geçiyor (~1,5 sn), sonra "Masalı oku" çıkıyor.

Anında gelen sonuç "basit, ucuz" algısı yaratır. Emek görünür olduğunda ise
sonuç daha değerli bulunur:

- **Emek yanılsaması** (labor illusion; Buell & Norton, 2011): Kullanıcılar,
  arama yaparken ne yapıldığını gösteren siteyi anında sonuç verene tercih etti.
  Bekleme süresi uzadığı halde memnuniyet arttı.
- **Emek sezgisi** (effort heuristic; Kruger vd., 2004): Aynı eser, "daha uzun
  sürede yapıldı" denince daha yüksek puan aldı.
- **Zirve ve son kuralı** (peak-end): Masalın ilk açılışı akılda kalan zirve
  anıdır, bu yüzden emeği en çok hak eden yer burası.

Ama **bekletmek değil, zanaati göstermek** gerekir. Kullanıcının kendi
seçimleri görünmüyorsa uzun bir bekleme sadece can sıkar. Bu planın özü şu:
beklerken aile, *kendi* çocuğunun, *kendi* seçtiği karakterlerle ve *kendi*
yaşına göre bir masal aldığını görür.

## 2. Bugün ne var

| Konu | Bugünkü durum |
|---|---|
| Süre | 4 × 0,38 sn ≈ 1,5 sn |
| Aşamalar | Genel ifadeler: "Kahraman hazırlanıyor", "Dünya kuruluyor", "Masal yazılıyor", "Güvenlik kontrolü". Çocuğun adı yalnızca alt başlıkta geçiyor |
| Görsel | Ragi (`pencil`), yüzdeli halka (`StoryProgressRing`, "%75"), aşama satırları (`StageRow`) |
| Reduce Motion | Tüm aşamalar bir anda tamamlanıyor, yani anlam kayboluyor |
| Kullanıldığı yerler | `StoryCreationFlow` (`.preparing`), `FirstRunView` (ilk masal, "Sonra oku") |
| Onay modu | "Masalları onayla" açıksa sonunda kilit notu ve "Tamam" çıkıyor |

Sorunlar:

1. Ekran bir yükleme ekranı gibi duruyor. Yüzdeli halka SaaS dilidir,
   yayınevi dili değildir.
2. Aşamalar her masalda aynı. Kişisel olan hiçbir şey gösterilmiyor.
3. `StageRow` içinde tasarım yasası ihlalleri var: çıplak `12`, `18`, `14`
   değerleri. Yeni tasarımda bunlar temizlenir.

## 3. İlkeler

1. **Dürüstlük.** Her adım, motorun bu masal için gerçekten yaptığı bir işi ve
   gerçekten kullandığı veriyi gösterir. Motorun yapmadığı hiçbir şey söylenmez.
   "Yapay zekâ çiziyor" gibi ifadeler yok, "Ragi yazıyor" var.
2. **Kişisellik.** En az iki adımda çocuğun adı ve ailenin seçimleri görünür.
3. **Ritim, engel değil.** Tam akış ilk masallarda oynar. Sonra kısalır ve
   atlanabilir hale gelir.
4. **Sakinlik.** Geri sayım, yüzde ya da "neredeyse bitti" baskısı yok.
   Titreşim yalnızca bir kez, sonda.
5. **Tasarım yasası.** Süreler `MP.M`'den, boşluk `MP.S`'den, ikonlar `MPIcon`'dan.
   Gradient ve cam yok. Animasyonlar Reduce Motion'a uyar.

## 4. Sahne akışı

Ekranın ortasında **açık bir masal defteri** (kâğıt kart, `mpEdge`) durur.
Adımlar bu sayfanın içinde olur. Ragi (`Mascot.pencil`) defterin yanındadır.
Altında tek satırlık sakin bir durum cümlesi vardır.

| # | Sayfada görünen | Durum cümlesi (örnek) | Kaynak (gerçek veri) |
|---|---|---|---|
| 0 | Boş sayfa açılır, Ragi kalemini alır | "Ragi, Ela'nın masal defterini açıyor." | `profile.name` (`SeriesCopy.genitive`) |
| 1 | **Kadro:** karakterler sayfaya birer birer girer (ad etiketleri, avatar rengi) | "Masalda Ela, tilki Fındık ve Dedesi var." | Çocuk adı, `story.companionID` → `CompanionChoice.name/kind`, `story.familyCharacterID` → `FamilyCharacter` |
| 2 | **Yaş:** küçük bir not | "Ela'nın yaşına göre kelimeler seçiliyor." | `story.ageBand` (sunulan bant istenenden farklı olabilir, bu yüzden metinde yaş sayısı yazmaz) |
| 3 | **Mod dokunuşu** | Uyku: "Uyku için yumuşak bir son yazılıyor." · Öğrenme: "Masala bir yeni kelime saklanıyor." · Macera: "Macera için bir yol çiziliyor." | `story.mode`. Öğrenme cümlesi yalnızca `pages[].words` boş değilse gösterilir |
| 3b | (koşullu) **Sevdikleri** | "Ela'nın sevdiği hayvanlar masala karışıyor." | Yalnızca seçilen içerik ilgi etiketine gerçekten uyduysa. Bu bilgi motordan gelmiyorsa adım atlanır (bkz. §6.3) |
| 4 | **Yazım:** masalın **gerçek ilk cümlesi** mürekkeple satır satır belirir | "Sayfalar yazılıyor · 8 sayfa" | `story.pages[0].text` (ilk cümle), `pages.count` |
| 5 | **Okuma kontrolü:** Ragi sayfayı okur | "Ragi masalı bir kez daha okuyor." | `isClean` kapısı (`OfflineStoryService.compose`), her masalda gerçekten çalışıyor |
| 6 | **Ciltleme:** sayfa kapanır, kapak gelir (başlık + kapak sanatı), altta künye | "Ela'nın 12. masalı hazır." + **Masalı oku** | `MagicPaperCoverGenerator.configuration(for:)`, `story.title`, çocuğun masal sayısı |

Notlar:

- **Adım 4 bu ekranın imzası.** Örnek bir yazı değil, çocuğun okuyacağı
  masalın ilk cümlesi yazılır. Hem dürüst hem de merak uyandırır.
- **Adım 6'daki künye** ("Ela'nın 12. masalı") ileride ithaf sayfası ve künye
  işiyle birleşir. Sayı, `storyManager.stories` içinde bu çocuğa ait masal
  sayısından türetilir. Yeni bir veri saklanmaz.
- **Onay modunda** adım 6 kapakla biter. "Masalı oku" yerine bugünkü kilit
  notu ve "Tamam" çıkar. Davranış değişmez.
- **Seri bölümleri** bu ekrandan geçmez. Bölümler günlük açılıyor ve
  kapsam dışında.

## 5. Süre ve atlama

Önerilen değerler. Batuhan'ın onayına bağlı (bkz. §9).

| Durum | Toplam | Atlama |
|---|---|---|
| Çocuğun ilk masalı | ~15 sn | Yok |
| Çocuğun 2.–3. masalı | ~10 sn | 2 sn sonra "Hemen aç" |
| 4. masal ve sonrası | ~6 sn (yaş satırı düşer) | 1 sn sonra "Hemen aç" |
| Uyku saati (`MPBedtime.isBedtime`) | Yukarıdakinin 1,2 katı | Aynı |

- **"Hemen aç"**, defterin altında hayalet (ghost) bir buton olur. Dokununca
  kalan adımlar tek geçişle tamamlanır ve kapağa gelinir. Adım listesi
  atlanmaz, yalnızca hızlanır.
- **Motor gecikirse** (normalde olmaz): adım 0, hikâye gelene kadar bekler.
  Hata olursa bugünkü `.failed` yolu aynen işler.
- **"Vazgeç" / "Sonra oku"** bugünkü gibi her an görünür kalır.

## 6. Mimari

### 6.1 Yeni: `StoryPreparationScript` (saf mantık, test edilebilir)

Görünüm mantık taşımaz (ilke 3). Adımların sırası, metinleri ve süreleri saf
bir tipten gelir:

```swift
struct PreparationFacts {           // görünüm dışında toplanır
    let childName: String
    let companion: (name: String, kind: String)?
    let familyName: String?
    let mode: StoryMode?
    let hasNewWord: Bool
    let matchedInterest: String?     // motor bunu vermiyorsa nil
    let firstSentence: String
    let pageCount: Int
    let storyOrdinal: Int            // bu çocuğun kaçıncı masalı
    let isFirstRun: Bool
    let isBedtime: Bool
}

enum PreparationBeat: Equatable {
    case openBook, cast, ageFit, modeTouch, interest, writing, reread, bind
}

struct StoryPreparationScript {
    static func beats(for facts: PreparationFacts) -> [(beat: PreparationBeat, line: String, duration: Duration)]
    static func skipDelay(for facts: PreparationFacts) -> Duration?
}
```

- Metinler bu tipin içinde kalır. `StoryPreparationCopy` gibi bir yardımcıda da
  olabilir, görünümde olmaz. Türkçe ekler (iyelik, "Dedesi") için
  `SeriesCopy.genitive` ve FAZ 11'in akrabalık metinleri yeniden kullanılır.
- Süreler doğrudan saniye değildir, birer **ritim birimidir** ve `MP.M`
  sabitlerinden türetilir (bkz. §9, karar b).

### 6.2 `StoryPreparationView` yeniden düzenlenir

- Dış API korunur: `childName`, `modeTitle`, `story`, `onRead`, `onCancel`,
  `title`, `cancelTitle`, `awaitsApproval`. Yeni girdi `facts: PreparationFacts?`
  olur. `nil` iken ekran adım 0'da bekler.
- `StoryProgressRing` ve `StageRow` bu ekrandan kalkar. `MPStory.swift`'teki
  önizleme galerisi hâlâ kullandığı için bileşenlerin kendisi silinmez,
  dokunulmaz.
- Yeni küçük bileşenler (`Screens/StoryCreation/Preparation/` altında):
  `PreparationNotebook` (kâğıt kart + sahne), `CastLine` (ad etiketleri),
  `InkLine` (bir cümlenin mürekkeple belirmesi).
- Kapak için mevcut `MagicPaperCoverView` kullanılır, yeni kapak çizilmez.

### 6.3 Veri toplama: `StoryCreationFlow` ve `FirstRunView`

- `createStory` döndükten sonra `PreparationFacts` akışta kurulur.
  `Story` modeli **değişmez**.
- Arkadaşın adı ve türü: `StoryChoiceSource.companionChoices(...)` içinden
  `story.companionID` ile bulunur ya da `OfflineStoryService.companionKind(id:)`
  yanına küçük bir `companionName(id:)` eklenir.
- **İlgi alanı eşleşmesi** bugün `ComposedStory` dışına çıkmıyor olabilir.
  Uygulama öncesi kontrol edilecek. Çıkmıyorsa adım 3b v1'de yer almaz.
  Motora sırf bu ekran için alan eklenmez.
- Masal sırası: `storyManager.stories.filter { $0.belongs(to: profile) }.count`.

### 6.4 Erişilebilirlik ve Reduce Motion

- **Reduce Motion açıkken** adımlar yine sırayla gelir, ama hareket yerine
  çapraz geçişle. Mürekkep efekti yerine cümle tümüyle belirir. Süreler aynı
  kalır, anlam korunur. Bugünkü "her şey bir anda biter" davranışı kaldırılır,
  çünkü yasa boşluk değil alternatif istiyor.
- **VoiceOver:** Ekran açılınca "Ela'nın masalı yazılıyor", bitince
  "Masal hazır, Masalı oku" duyurulur. Ara adımlar tek tek duyurulmaz (gürültü
  olur), ama defter tek bir öğe olarak o anki cümleyi okur.
- "Hemen aç" ve "Vazgeç" Türkçe etiketlidir, ≥ `MP.S.tapMin`.
- En büyük Dynamic Type boyutunda defter dikey kaydırılabilir olur, kapak küçülür.
- Bilgi yalnızca renkle verilmez. Adımın bittiğini cümlenin değişmesi gösterir.

### 6.5 Dokunsallık ve ses

- Tek titreşim: kapak geldiğinde `MPHaptics.success()` (bugünkü gibi).
  Adım geçişlerinde titreşim yok.
- Ses yok. Uygulamada bir ses efekti sistemi yok. Kalem ve sayfa sesi
  ileride ayrı bir karar konusu.

## 7. Testler

`StoryPreparationScriptTests` (birim):

- Her mod için adım sırası. Uykuda "yumuşak son", öğrenmede kelime yoksa
  "yeni kelime" cümlesinin çıkmaması.
- Aile karakteri olan ve olmayan kadro cümlesi. Arkadaş yokken cümle düzgün
  kuruluyor.
- Türkçe ekler: "Ela'nın", "Aslı'nın", "Ömer'in", "Defne'nin".
- Süreler: ilk masal > 2.–3. masal > sonrakiler. Uyku çarpanı uygulanıyor.
- `skipDelay`: ilk masalda `nil`, sonra 2 sn, 4. masaldan sonra 1 sn.
- Adım 4'ün metni masalın gerçek ilk cümlesi. Uzun cümle güvenli biçimde
  kısaltılıyor (kelime ortasından kesilmiyor).

Mevcut testler (`StoryCreationSteps` ve ilk masal akışı) yeşil kalmalı.

Görsel doğrulama (Definition of Done): Simülatörde açık + koyu, en büyük Dynamic
Type, iPhone SE + Pro Max ekran görüntüleri; Reduce Motion açık bir tur; onay
modu açık bir tur. CLAUDE.md'deki beş `grep` değiştirilen dosyalarda boş dönmeli.

## 8. Uygulama sırası

1. `StoryPreparationScript` + `PreparationFacts` + testler (önce testler).
2. İlgi alanı eşleşmesinin motordan dışarı çıkıp çıkmadığını kontrol et;
   çıkmıyorsa 3b'yi kapat.
3. `companionName(id:)` (gerekirse) ve akışta `facts` kurulumu
   (`StoryCreationFlow`, `FirstRunView`).
4. Görünüm: `PreparationNotebook`, `CastLine`, `InkLine`, kapak + künye,
   "Hemen aç".
5. Reduce Motion, VoiceOver, Dynamic Type.
6. Tasarım yasası grep'leri, simülatör ekran görüntüleri.
7. Değişiklik günlüğü kaydı, commit.

Dosya sahipliği: `StoryCreation/` ve `FirstRunView` bu iş sırasında başka bir
oturumda açık olmamalı. `MPStory.swift` paylaşılan bir dosya; yalnızca silme
gerekirse ve kullanan yoksa dokunulur.

## 9. Batuhan'ın kararı gereken noktalar

a. **Süreler.** İlk masal ~10 sn, 2.–3. masal ~8 sn, sonrakiler ~5 sn,
   uykuda ×1,3. Uygun mu?
b. **Mürekkep süresi için yeni bir hareket sabiti.** `MP.M`'deki en uzun süre
   `page` (0,52 sn). Bir cümlenin yazılması ~1,5–2 sn sürer. İki seçenek var:
   `MP.M.ink` adlı yeni bir sabit eklemek (tasarım sistemi değişikliği, belgeye
   de işlenir) ya da kelime kelime `MP.M.slow` adımlarıyla ilerlemek.
   Öneri: `MP.M.ink`.
c. **Gerçek ilk cümlenin gösterilmesi.** Ebeveyn masaldan önce ilk cümleyi
   görür. Öneri: evet, merak uyandırıyor ve dürüst.
d. **Künye ("Ela'nın 12. masalı") bu ekranda mı başlasın**, yoksa ithaf
   sayfası işiyle birlikte mi gelsin? Öneri: burada başlasın, sayfa işi
   sonra aynı metni kullanır.
e. **Yüzdeli halkanın kaldırılması.** Öneri: kaldırılsın.

## 10. Bilerek yapılmayanlar

- Sahte bekleme metni yok: "sunucuya bağlanılıyor", "yapay zekâ düşünüyor" gibi.
- Geri sayım, yüzde, "neredeyse bitti" yok.
- Masal hazırlanırken çocuktan ya da ebeveynden yeni bilgi istenmez.
- Bildirim yok.
- Seri bölümleri, ses efekti ve ithaf sayfası bu işin kapsamında değil.

## 11. Nasıl anlayacağız

- Analitik yok. Bunun yerine FAZ 14'ün cihaz içi kullanım verisinde,
  "Hemen aç"a basılma oranı yerel olarak sayılabilir (ayrı karar). Oran
  yüksekse süreler kısaltılır.
- 5 aileyle niteliksel test: "Bu masal sizin için mi yazıldı, yoksa hazır
  mıydı?" sorusuna verilen yanıt.

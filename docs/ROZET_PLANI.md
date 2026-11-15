# Rozet planı: 8 rozetten 69 rozete, yıldız puanı ve Yıldız katı

**Tarih:** 15 Kasım 2026 · **Durum:** bütün kararlar verildi (R0 ve 8-13, Batuhan, 15 Kasım 2026); R1, R2 ve R3 kodu yazıldı, sıradaki R4
**İstek (Batuhan, 15 Kasım):** "Bir çok rozet olsun. Duolingo tarzında rozetlerle kullanıcı sürekli desteklensin."
**Bağlı kurallar:** `CLAUDE.md` ilke 7 (sakin kilometre taşları, karar 3 ve 13 Ekim), `docs/VIZYON_PLANI.md` (yıldız, çıkartma, masal sonu düzeni).

---

## 1. Bugün ne var

| Parça | Yer | Not |
|---|---|---|
| 8 rozet (`MPMilestone`) | `Screens/MPMilestones.swift` | İlk masal, 5, 10, 25 masal, 7 uyku masalı, ilk macera, ilk öğrenelim, ilk seri |
| Defter (`MPBadgeLedger`) | aynı dosya | Yalnızca büyür, iki cihaz birleşince rozet kaybolmaz; `UserDefaults` `mp_badges_<profil>`, `SyncCollection.badges` ile eşitlenir |
| Kazanma noktası | `StoryReaderView.swift:431` | Yalnızca masal sonuna varınca, aynı masal bir kez |
| Masal sonu | `StoryEndingLeaf.swift:94, 274` | Tek satır "yeni rozet"; gece sürümü kâğıda yakın satır |
| Profil | `KidCornerView.swift:234` | "Rozetlerim 3 / 8", `MPBadgeCard` ızgarası, kilitliler gri |
| Kart | `MPCards.swift:239` `MPBadgeCard` | SF simge + dünya tonu, sert alt kenar |
| Testler | `KidCornerTabTests`, `StarCountTests`, `PastelHomeRulesTests` | |

Sorun: 8 rozetin 5'i ilk 10 masalda biter. Ondan sonra çocuk aylarca yeni rozet görmez. "Sürekli destek" eksikliği buradan geliyor; çözüm daha çok rozet ve daha uzun bir yol.

## 2. Duolingo'dan ne alıyoruz, ne almıyoruz

İlke 7 bağlayıcı: rozet yalnızca okuyarak kazanılır, kaybolmaz, geri sayım, "az kaldı", ilerleme çubuğu, kıyas ve bildirim yok. Duolingo'nun rozet dünyası bu çerçeveye şöyle çevrilir:

| Duolingo | MagicPaper | Neden |
|---|---|---|
| Çok sayıda rozet, aileler hâlinde | ✅ 69 rozet, 12 aile | Yol uzar, her hafta bir şey olur |
| Kademeli rozet (seviye 1-10) | ✅ "kat": aynı rozetin büyüyen hâli | Tek kartta derinlik, ızgara kalabalıklaşmaz |
| Büyük kutlama anı | ✅ gündüz masal sonunda tek an; gece sessiz satır | Uyku vakti sakin kalır |
| Karakterin sevinci | ✅ Ragi'nin `cheer` pozu + tek cümle | Zaten var, rozete bağlanır |
| Gizli rozetler | ✅ 4 tane, "?" ile kilitli | Sürpriz merak yaratır, baskı yaratmaz |
| Rozet detayı (tarih) | ✅ "12 Kasım'da kazandın" | Aile anısı (ürün sütunu 7) |
| Lig, sıralama | ❌ | İlke 7 yasaklar (puan 5b'de yıldızla geldi) |
| Ardışık gün (streak) rozeti, seri dondurma | ❌ yerine **toplam okuma günü** | Ardışık gün kırılır ve suçluluk üretir; toplam gün asla kaybolmaz |
| İlerleme çubuğu, "2 ders kaldı" | ❌ | 13 Ekim kararı |
| Süreli meydan okuma, sınırlı etkinlik rozeti | ❌ | Geri sayım ve kaçırma korkusu |
| Push bildirimiyle rozet duyurusu | ❌ | İlke 7 |
| Rozetle yıldız/ödül verme | ❌ (karar 12) | Rozet ödül değil anı |
| Toplam puan ve seviye (XP + lig yerine) | ✅ Yıldız puanı + Yıldız katı (5b, 15 Kasım isteği) | Puan düşmez, kıyas ve sıralama yok |

## 2b. Duolingo araştırması (15 Kasım 2026)

Kaynaklar: Duolingo blogu ([rozet yenilemesi, Aralık 2023](https://blog.duolingo.com/achievement-badges), [seri kilometre taşı animasyonu, Ocak 2022](https://blog.duolingo.com/streak-milestone-design-animation)) ve iki hayran rehberi ([duoplanet](https://duoplanet.com/duolingo-achievements-guide/), [lingoly](https://lingoly.io/duolingo-achievements/)). Rehberler eşiklerde ve hangi rozetin kaldırıldığında birbirini tutmuyor; Duolingo sistemi birkaç kez değiştirdi. Aşağıdaki sayılar yaklaşık, tasarım dersi için yeterli.

**Sistemin yapısı**
- **Ödüller (Awards):** kademeli başarılar, çoğu 5 ya da 10 kat. Wildfire (seri günü, 3 → 365), Sage/XP Olympian (XP, 100 → 30.000), Scholar/Word Collector (öğrenilen kelime, 50 → 2.000), Sharpshooter/Flawless Finisher (hatasız ders, 1 → 100), Regal (taç), Champion (lig), Challenger (süreli meydan okuma XP'si), Conqueror (kursu bitirme), Quest Champion (görev), Nocturnal (gece 22-24 arası ders), Early Rise (sabah 9'dan önce ders).
- **Tek seferlik:** Photogenic (profil fotoğrafı), Weekend Warrior (cumartesi ve pazar ikisinde ders), Friendly (3 kişiyi takip), Strategist (dersten önce ipuçlarına bakmak), Winner (ligde birinci), Unrivaled (Elmas ligi birincisi), Page Turner (hikâye okuma).
- **Kişisel rekorlar (2023 yenilemesi):** En uzun seri, bir günde en çok XP, hatasız ders sayısı, en yüksek lig.
- **Sınırlı rozetler:** aylık meydan okuma rozetleri, Ejderha Yılı gibi tarih aralığına bağlı rozetler.

**Sunuş**
- Rozetler profilde "raftaki kupalar gibi" toplanıyor (blog). Kilitli rozet şartını ve bir ilerleme çubuğunu gösteriyor; kazanılan altına dönüyor (rehberler).
- 2023 yenilemesinde rozet çizimlerinde dünyanın karakterleri var; amaç başarıları "kutlanacak, paylaşılacak" yapmak.
- Seri kilometre taşlarında (1 hafta, 1 ay, 100 gün, 1 yıl) karakter "güçlenir": alev yerine anka kuşu, balonlar "yeterince kutlama değil" bulunmuş. Paylaşım kartı var.
- Tasarım gerekçesi: kolay ilk rozetler yeni başlayanı, nadir son katlar sadık kullanıcıyı besler.

**MagicPaper'a çevirisi**

| Duolingo | Karar | MagicPaper karşılığı |
|---|---|---|
| Wildfire (seri günü, 10 kat) | 🔁 çevrildi | E. Okuma günleri, 7 kat, toplam gün (ardışık değil); tavan 100 (R0) |
| Scholar / Word Collector | ✅ | F. Kelime avcısı, 6 kat (1 → 200) |
| Page Turner, Conqueror | ✅ | A. Masal yolu 11 kat; G. Seri |
| Weekend Warrior | ✅ | J. Hafta sonu masalı: aynı hafta sonu cumartesi ve pazar ikisinde de masal |
| Early Rise | ✅ tek, gizli | J. Sabah masalı |
| Strategist (ipucuna bakmak) | 🔁 | H. Meraklı parmak: masal içinde bir kelime kartını açmak (okurken) |
| Friendly (takip) | 🔁 | I. Ailemle: sosyal ağ değil, Masal ailem |
| Dünya karakterleri rozet çiziminde | ✅ | Armalarda Ragi ve yol arkadaşları (4.1) |
| Kilometre taşında karakterin güçlenmesi | ✅ | Masal yolu 10, 50, 100, 200'de Ragi'nin armadaki hâli değişir (4.1) |
| Kişisel rekorlar | 🔁 rekor değil anı | "Masal anıları" kartları (4.3): ilk masal, en çok okunan masal, en sık gidilen yer, en yakın yol arkadaşı. Sayılmaz, rozet değil |
| Paylaşım kartı | ⏳ sonra | Ebeveyn tarafında, çarpma kapısıyla (R5 sonrası) |
| Sage (XP katları) | 🔁 | Yıldız katı (5b): yıldız puanıyla 12 kat |
| Lig, Champion, Winner, Unrivaled | ❌ | Sıralama ve kıyas yok |
| Challenger (süreli meydan okuma), aylık rozet, Ejderha Yılı | ❌ | Geri sayım ve kaçırma korkusu |
| Sharpshooter (hatasız) | ❌ | Masalda sınav yok; mükemmeliyetçiliği ödüllendirmeyiz |
| Nocturnal (gece 22-24) | ❌ | Geç yatmayı ödüllendirir |
| Photogenic (fotoğraf) | ❌ | Çocuk fotoğrafı toplanmaz (ilke 10) |
| Quest Champion, günlük görevler | ❌ | Yapay etkileşim döngüsü |
| "Bir günde en çok XP" | ❌ | Bir oturumda çok masal okumayı (binge) ödüllendirir |
| Kilitli rozette ilerleme çubuğu | ❌ | 13 Ekim kararı; yalnızca eylem cümlesi (R0) |

## 3. Katalog (69 rozet, 12 aile)

R0'da onaylanan 41 rozet korunur; Duolingo araştırmasıyla 28 rozet eklendi (➕). Okuma günü tavanı 100 olarak kaldı. ✱ = bugünkü rozet (id korunur).

### A. Masal yolu (kademeli, 11 kat): her bitirilen farklı masal
| Kat | Eşik | Ad |
|---|---|---|
| 1 | 1 | İlk masal ✱ |
| 2 | 3 | Üç masal |
| 3 | 5 | 5 masal ✱ |
| 4 | 10 | 10 masal ✱ (Ragi armada ilk kez değişir) |
| 5 | 15 | 15 masal ➕ |
| 6 | 25 | 25 masal ✱ |
| 7 | 50 | 50 masal (Ragi değişir) |
| 8 | 75 | 75 masal ➕ |
| 9 | 100 | 100 masal (Ragi değişir) |
| 10 | 150 | 150 masal ➕ |
| 11 | 200 | Masal ustası (Ragi değişir) |

### B. Ay arkadaşı (kademeli, 6): uyku masalı
İlk uyku masalı · 7 ✱ · 15 ➕ · 30 · 50 ➕ · 100

### C. Yol açan (kademeli, 5): macera
İlk macera ✱ · 5 ➕ · 10 · 20 ➕ · 30

### D. Meraklı (kademeli, 5): öğrenelim
İlk öğrenelim masalı ✱ · 5 ➕ · 10 · 20 ➕ · 30

### E. Okuma günleri (kademeli, 7): masal bitirilen **farklı** gün sayısı, ardışık değil
3 · 7 · 14 ➕ · 30 · 50 ➕ · 75 ➕ · 100 gün okuduk
Metin: "7 ayrı günde birlikte okudunuz." Bir gün kaçınca hiçbir şey kaybolmaz. Duolingo'nun 1 hafta / 1 ay / 100 gün kilometre taşları 7, 30, 100'e denk gelir; bu üç katta tam ekran an Ragi'nin bir sonraki hâliyle gelir.

### F. Kelime avcısı (kademeli, 6): Yeni kelimelerim'e giren kelime
İlk yeni kelime · 10 · 25 · 50 · 100 ➕ · 200 ➕

### G. Seri (4)
İlk devam (bir serinin 2. bölümü bitti) · İlk seri tamamlandı ✱ · 3 seri · 5 seri ➕

### H. Keşif (8, tek)
- Üç kapı: üç moddan da en az bir masal
- İlk klasik · 5 klasik · 10 klasik ➕
- Bulut Durağı: ilk MagicPaper Original · 5 Original ➕
- Sürprizci: "Bana sürpriz yap" ile yazılan bir masal bitti
- Meraklı parmak ➕: masal okunurken bir kelime kartı açıldı (Duolingo Strategist karşılığı)

### K. Gezgin ➕ (kademeli, 4): masal haritasında gidilen farklı yer (`StoryMapView`, `origin.settingID`)
3 · 5 · 10 · 15 yer. Eşikler R1'de katalogdaki yer sayısına göre ayarlanır; en üst kat katalogdaki yer sayısını geçmez. Metin: "Haritanda 5 yer var."

### L. Dostlar ➕ (kademeli, 4): masallarda tanışılan farklı yol arkadaşı (`companionID`)
3 · 5 · 10 · 20 dost. (R0'daki tek "Yeni arkadaşlar" rozeti bu ailenin 2. katı oldu.)

### I. Ailemle (5)
- Ailem masalda: Masal ailem'den biri masala girdi
- Büyük aile: 3 farklı aile üyesi masallarda · Kocaman aile ➕: 5 farklı üye
- Tanıdık ses: ebeveynin kaydettiği sesle bir masal dinlendi · Sesli kitaplık ➕: 5 farklı masal tanıdık sesle

### J. Gizli (4): kazanılana kadar "?" ve "Gizli rozet"
- Tekrar tekrar: aynı masal üç ayrı günde sonuna kadar okundu (aynı gün sayfayı ileri geri çevirmek sayılmaz) (tekrar okuma yıldız vermez, rozet verebilir; okuma sayılır)
- Sabah masalı: öğleden önce bitirilen bir masal (Duolingo Early Rise)
- Hafta sonu masalı: aynı hafta sonu cumartesi ve pazar ikisinde de masal bitti (Duolingo Weekend Warrior)
- Masal yıldönümü ➕: ilk masaldan bir yıl sonra (ya da daha sonra) bir masal okundu. Zamana bağlı ama kaçırılamaz: tarih geçince de ilk masalda kazanılır. Gizli rozet sayısı R0'da üçtü; dördüncüsü 15 Kasım'da kabul edildi

Bilerek dışarıda: gece geç saat rozeti (geç yatmayı ödüllendirir), doğum günü rozeti (profilde doğum günü yok, istemek ilke 8'e aykırı), mevsim rozetleri (zamana bağlı, kaçırma hissi), uygulamada geçen süre, kahraman giydirme (okuma değil), bir günde çok masal (binge), hatasız okuma.

Ritim tahmini (haftada 4 masal okuyan 5-6 yaş çocuk): ilk hafta 6-8 rozet (İlk masal, Üç masal, ilk mod rozetleri, 3 gün, ilk kelime, Üç kapı), ilk ay 18-22, sonra ayda 2-4; 200 masal ve 100 gün yaklaşık bir yıl. 41 rozetlik planda ilk aydan sonra ayda 1-3 rozet düşüyordu; ara katlar (15, 75, 150 masal; 14, 50, 75 gün; 5 ve 20 macera) "uzun boşluk" aylarını dolduruyor.

## 4. Görünüm

### 4.1 Rozet arması
- `MPBadgeCard` SF simgeden **arma**ya geçer: kâğıt kesik / nakış yama dili (el yapımı, ilke 9), parlak 3B ve metal yok.
- Kat, armanın etrafındaki dikiş halkası ve küçük yıldız sayısıyla gösterilir (1-8), renk ya da metalle değil (bilgi yalnızca renkle verilmez).
- Duolingo'nun 2023 yenilemesi gibi armalarda karakter var: mod ailelerinde o modun dünyası, Dostlar'da yol arkadaşları, Masal yolu'nda Ragi. Masal yolu 10, 50, 100 ve 200. katlarda armadaki Ragi "güçlenir" (yeni bir aksesuar), Duolingo'nun anka kuşu dersi.
- Çizim illüstratör işi (Ragi kıyafetleri gibi). Çizim gelene kadar bugünkü simge + ton + kat halkası kodla çizilir; yer tutucu `MPBadgeArt` tek yerden değişir.

### 4.2 Masal sonu (karar: tam ekran an, 15 Kasım 2026)
- **Gündüz:** yeni rozet varsa masal sonu yaprağından önce **tam ekran bir rozet anı** gelir. Okuyucu zaten `fullScreenCover` olduğu için bu yeni bir modal değil, okuyucunun içinde bir sahne (bir modal açıkken başka modal açılmaz kuralı korunur).
  - Krem zemin, ortada büyük arma `MP.M.spring` ile büyür, altında Ragi `cheer`, `page` rolünde ad, tek cümle ("Ay arkadaşı rozetin büyüdü!"), tek birincil düğme "Devam" (`MPButton(size: .hero)`). Ekrana herhangi bir yere dokunmak da geçer.
  - `MPSound` bir kez, `MPHaptics` tek titreşim. Masal sonundaki çıkartma titreşimi bu anda verilmez (eylem başına bir titreşim).
  - Birden çok rozet: tek ekranda, büyük arma ilk rozet, altında küçük armalar sırayla ("ve 1 rozet daha"). Arka arkaya ekran yok.
  - Reduce Motion: büyüme yerine çapraz geçiş. VoiceOver: "Yeni rozet: Ay arkadaşı, 2. kat."
  - Otomatik kapanma yok, geri sayım yok; "Devam" masal sonu yaprağına geçer, orada rozet satırı tekrar görünmez.
- **Gece / uyku vakti:** tam ekran an yok; bugünkü sessiz satır kalır, ses ve zıplama yok.
- Geriye dönük kazanılan rozetler tam ekran an açmaz (bkz. 5).

### 4.3 Profil → Rozetlerim
- Profil bölümü ilk 6 armayı gösterir (önce son kazanılanlar), başlık `MPSectionHeader` "Rozetlerim", `note:` "12 / 69", `link:` "Tümü ›".
- Yeni push sayfa `MPKidRoute.badges`: aileler `MPSectionHeader` ile; kademeli aile tek kart (en yüksek kazanılan kat), tek rozetler ızgara. Ragi bir kez, balonla.
- Kilitli rozet gri + kilit; gizli rozet "?".
- Sayfanın sonunda "Masal anıları" (Duolingo'nun kişisel rekorlarının sakin karşılığı): İlk masal, En çok okunan masal, En sık gidilen yer, En yakın yol arkadaşı. Rekor ve sayı değil, kapakla bir anı; `MPYearbook`'un verisinden.

### 4.4 Rozet detayı (`mpSheet`)
- Kazanılan: büyük arma, ad, tek cümle anı: "İlk macera masalını 12 Kasım'da okudun: *Ormanın Feneri*." Kademeli rozette bütün katlar tarihleriyle.
- Kilitli: **nasıl açıldığı**, sayı olmadan: "Bir macera masalı okuyunca açılır." Kalan sayı, yüzde, çubuk yok.
- Gizli: "Bu rozet bir sürpriz. Okudukça bulacaksın."

### 4.5 Sürekli destek (rozet dışı, aynı dil)
- Masal sonunda Ragi'nin cümlesi defterden beslenir ve kutlar, saymaz: "Bu senin 10. masalın!", "Bu hafta üçüncü uyku masalı." Asla "1 masal kaldı".
- Ana sayfa selamı (`eyebrow`), son 24 saatte rozet kazanıldıysa bir kez: "Dün yeni bir rozet buldun."
- Profil sekmesinde yeni rozet için bir kez sessiz nokta (`MPBadgeNews` + görüldü bayrağı).
- Ebeveyn: çocuğun profil sayfasında "Rozetler" listesi tarih sırasıyla (`MPListRow`, Ragi'siz). Paylaşma ileride, çarpma kapısıyla.

## 5. Mimari

- **Katalog tablo olur:** `MPBadge` (id, aile, kat, ölçü, eşik, gizli mi, ad, simge, ton) ve `MPBadgeCatalog.all`. `isMet` tek bir `metric(of: ledger)` + eşik karşılaştırmasına iner; 69 `case` yazılmaz. Bugünkü 8 rozetin `rawValue`'ları id olarak korunur, kazanılmış rozet kaybolmaz.
- **Defter büyür** (`MPBadgeLedger`), hepsi birleşebilir kalır:
  - `readingDays: Set<String>` (yerel takvim günü `yyyy-MM-dd`)
  - `words: Set<String>`, `classics`, `originals`, `companions`, `familyMembers`, `surpriseStories`, `voiceStories`: `Set<String>`
  - `seriesSecondEpisodes: Set<String>`
  - `finishCounts: [String: Int]` (tekrar tekrar için, birleşmede `max`)
  - `morningStories`, `weekendDays` (hafta sonu tarihleri, `readingDays`'ten türetilebilir): `Set<String>`
  - `places`, `wordCardOpened` (Bool, birleşmede `||`), `firstFinishedAt: Date?` (birleşmede `min`, yıldönümü için)
  - `seen: Set<String>` (kutlanmış/görülmüş rozetler; birleşmede birleşim)
- **Göç:** sentezlenmiş `Codable` eksik anahtarda hata verir; `init(from:)` `decodeIfPresent` ile yazılır. Yoksa eski defter okunamaz ve kitaplıktan baştan kurulur (rozet tarihleri kaybolur).
- **Geriye dönük kazanım:** güncellemeden sonra ilk açılışta defter kitaplık, kelime defteri, seri ve aile verisinden doldurulur. Bu rozetler **sessizce** verilir (`seen`'e girer), on beş kutlama arka arkaya patlamaz. Profil'de Ragi bir kez: "Yeni rozetler geldi, bak!"
- **Kazanma noktaları:** hepsi okuyucunun masal sonundaki tek çağrıdan (`MPBadgeStore.recordFinished`) geçer; kelime ve aile verisi o anda masaldan okunur. Uygulama içinde başka yerde rozet verilmez (rozet yalnızca okuyarak).
- **Eşitleme:** `SyncCollection.badges` aynı; Firestore kuralı yeni alanları kabul eder, kural testi eklenir.
- **Yıldızla ilişki:** rozet yıldız vermez (karar 12). Yıldız puanı yalnızca Yıldız katını açar (5b), rozet ızgarasını değil.
- Domain mantığı görünümde değil: `MPMilestones.swift` → `Screens/Badges/` (`MPBadgeCatalog`, `MPBadgeLedger`, `MPBadgeStore`); görünümler yalnızca okur.

## 5b. Yıldız puanı ve Yıldız katı (profil rozeti)

**İstek (Batuhan, 15 Kasım 2026):** "Yıldızlar kullanıcının toplam puanı gibi olsun, yani puan sistemi olsun. Profil puan arttıkça rozet alsın."

**İlkeyle ilişkisi:** `CLAUDE.md` ilke 7 "points" ve "reward economies" yasaklıyor. Bu istek o yasağı yıldız için kaldırıyor; ilke 7'ye karar satırı olarak işlenir. Puanı sakin tutan sınırlar aşağıda: puan düşmez, kıyaslanmaz, sıralanmaz, satın alınmaz.

### Bugün
Yıldız türetiliyor (`MPStars.count`): profilin açıldığı günden bu yana her sabah 1 yıldız (uygulamayı açmak gerekmez) + bitirilen her farklı masal 1 yıldız. Harcama `MPCollection` satın alımlarından (`spent`); bakiye = kazanılan − harcanan.

### Yeni model: iki sayı
| Sayı | Ne | Düşer mi | Nerede görünür |
|---|---|---|---|
| **Yıldız puanı** | Ömür boyu kazanılan bütün yıldızlar | Hiç düşmez; harcama ve fiyat yarılama puanı etkilemez | Profil kimlik bloğu, masal sonu, ebeveyn profil sayfası |
| **Cepteki yıldız** | Puan − harcanan | Harcayınca düşer | Yalnızca Kitaplık renkleri ve gardırop (harcama yerleri) |

Kod: `MPStars.count` zaten ömür boyu kazanılanı veriyor, adı `MPStars.score` olur; `balance = score - spent` ayrı. Puan defterden türediği için iki cihaz birleşince de düşmez.

### Yıldız katı (profilin rozeti, 12 kat)
Puan eşiği geçince profil bir kat atlar. Kat, Profil sekmesinde kahramanın (`HeroAvatarView`) köşesinde küçük arma ve adın altında tek satır: "Parlak yıldız · 168 yıldız".

| Kat | Puan | Ad |
|---|---|---|
| 1 | 10 | Kıvılcım |
| 2 | 25 | Yıldız tozu |
| 3 | 50 | Parıltı |
| 4 | 100 | Küçük yıldız |
| 5 | 150 | Parlak yıldız |
| 6 | 250 | Kayan yıldız |
| 7 | 400 | Takımyıldız |
| 8 | 600 | Ay ışığı |
| 9 | 800 | Kuyruklu yıldız |
| 10 | 1000 | Samanyolu |
| 11 | 1500 | Gökada |
| 12 | 2000 | Masal göğü |

Ritim (bugünkü kural, haftada 4 masal ≈ haftada 11 yıldız): ilk hafta Kıvılcım, ilk ay Parıltı, 2. ay Küçük yıldız, 5. ay Kayan yıldız, 1. yıl Ay ışığı, ~2. yıl Samanyolu, Masal göğü 3-4 yıllık okur. Sabah yıldızı yalnızca okunan günlerde geldiği için (karar 11) haftada 4 okuma günüyle ~8 yıldız; katlar bu tablodan ~%40 geç gelir (ilk ay Yıldız tozu, 1. yıl Takımyıldız).

### Sınırlar
- Puan ve kat yalnızca yıldızdan gelir; yıldız yalnızca okumadan gelir (karar 11). Parayla puan yok, abonelikle puan yok.
- Puan ve kat **asla düşmez**: harcama, masal silme, profil değiştirme, cihaz değiştirme etkilemez.
- **Kıyas yok:** "Kim okuyor?" seçicisinde ve ebeveyn odasında kardeşlerin puanı ya da katı yan yana gösterilmez; her çocuk kendi Profil sayfasında kendi katını görür. Liderlik tablosu yok.
- Kilitli katta eşik yazar ("100 yıldızda açılır"), kalan yazmaz: "12 yıldız kaldı", ilerleme çubuğu, yüzde yok (R0 kararı 2'nin aynısı).
- Kat atlama bildirimle duyurulmaz.

### Görünüm
- **Profil:** kimlik bloğunda kahraman + kat arması, ad, "Parlak yıldız · 168 yıldız". Kimlik kartının tamamı Dolap'ı açtığı için (kart içinde düğme olmaz) katların listesi Rozetlerim'in en üstündeki Yıldız katı kartından açılır (`mpSheet`: 12 kat, ulaşılanlar tarihli, kilitliler eşikle). R3'te böyle uygulandı.
- **Masal sonu:** bugünkü "+1 yıldız" satırı "+1 yıldız · toplam 168" olur.
- **Kat atlama anı:** gündüz masal sonunda rozet anıyla aynı tam ekran sahne (4.2). Hem rozet hem kat aynı anda gelirse tek ekran: üstte kat arması büyük, altta rozet(ler) küçük. Gece sessiz satır: "Yeni katın: Parlak yıldız."
- Sabah yıldızı artık masal bitince geldiği için kat her zaman bir masal sonunda atlanır; ana sayfa selamı ertesi gün bir kez: "Yıldızın Parlak yıldız oldu."
- **Ebeveyn:** çocuğun profil sayfasında puan, kat, kazanılan/harcanan (bugünkü satır genişler). Harcamayı kapatma ve fiyat yarılama puanı etkilemez.

### Veri
- Puan formülü (karar 11): `score = eskiSabahlar + okumaSabahları + bitenMasallar`. `eskiSabahlar` profilin açılışından kural geçiş gününe (`morningRuleSince`, defterde, birleşmede `min`) kadarki günler; `okumaSabahları` o günden sonra `readingDays` içindeki günler. Böylece güncellemeyle hiçbir çocuğun puanı düşmez.
- `MPBadgeLedger.starLevels: [String: Date]` (kat → ilk ulaşıldığı an, birleşmede `min`). Puan türetilmiş olduğu için kat tarihi ancak defterle tutulur.
- Göçte bugünkü puana göre ulaşılmış katlar bugünün tarihiyle **sessizce** işlenir (`seen`), kutlama açılmaz.
- Kat kataloğu `MPBadgeCatalog` içinde ayrı aile (`starLevel`); rozet ızgarasındaki "12 / 69" sayısına girmez, profilin kendi arması olarak durur.

## 6. Fazlar

| Faz | İş | Sahip ajan | Çıktı |
|---|---|---|---|
| **R0** ✅ | Kararlar verildi (bkz. 7) | Batuhan | 15 Kasım 2026 |
| **R1** ✅ | Model (15 Kasım 2026, `Screens/Badges/`; derlenmedi, test çalıştırılmadı): `MPBadge` tablo, defter alanları, `decodeIfPresent` göçü, geriye dönük doldurma, `seen`; `MPStars.score` / `balance`, `starLevels` | builder (library-memory danışır) | Birim testleri: her rozetin eşiği, puan harcamayla düşmez, kat eşikleri, birleşme kaybetmez, eski JSON okunur, tekrar okuma ikinci kez saymaz |
| **R2** ✅ | (15 Kasım 2026; derlenmedi, test çalıştırılmadı) Kazanma: sabah yıldızı okunan güne bağlanır (`MPStars`: `readingDays` + göç öncesi sabahlar); okuyucu masal sonu çağrısına kelime, klasik, Original, arkadaş, yer, aile, ses, sürpriz, seri bölümü, gün bilgisi; kelime kartı açılınca tek bayrak | builder | Testler: her ölçü doğru masaldan dolar |
| **R3** ✅ | (15 Kasım 2026; derlenmedi, simülatörde görülmedi) Görünüm: `MPBadgeArt` yer tutucu + kat halkası, `MPBadgeCard` v2, `MPKidRoute.badges` sayfası, Profil bölümü, detay sheet; Profil kimlik bloğunda kat arması + puan satırı, kat sheet'i | ui-agent brif → builder | Tasarım yasası grep'leri boş |
| **R4** | Anlar: tam ekran rozet ve kat anı (gündüz) ve gece satırı, "+1 yıldız · toplam", Ragi cümleleri, ana sayfa selamı, sessiz nokta | builder, reader | Uyku vaktinde ses yok testi |
| **R5** | Ebeveyn: çocuk profil sayfasında rozet listesi, puan ve kat; eşitleme kuralları | builder, privacy-safety | Firestore kural testi |
| **R6** | Doğrulama: bütün testler, simülatörde açık/koyu, AX5, SE + Pro Max; değişiklik günlüğü | yok | Test ve simülatör yalnızca burada, bir kez |
| **Sonra** | Arma çizimleri (69 + 11 kat halkası, Masal yolu'nda 4 Ragi hâli) | illüstratör | `MPBadgeArt` yer tutucusunun yerine |

## 7. R0 kararları (Batuhan, 15 Kasım 2026)

1. **Okuma günü rozetleri:** toplam farklı gün sayılır, ardışık değil. ✅
2. **Kilitli rozet:** dokununca eylem cümlesi ("Bir macera masalı okuyunca açılır"); sayı, çubuk, "kaldı" yok. 13 Ekim'deki ipucusuz kilit kararının yerine. ✅
3. **Gizli rozetler:** üçü de (Tekrar tekrar, Sabah masalı, Hafta sonu masalı). ✅
4. **Tavan:** 200 masal, 100 okuma günü. ✅
5. **Kutlama:** gündüz masal sonunda tam ekran an (4.2); gece sessiz satır. ✅
6. **Adlar:** bu belgedeki adlar kalır; İrem turu beklenmez. ✅
7. **Arma:** önce kodla çizilen arma (simge + ton + kat halkası, `MPBadgeArt`), çizimler gelince tek yerden değişir. ✅

**Duolingo araştırmasından sonra (kabul: Batuhan, 15 Kasım 2026):**

8. **69 rozet:** 28 ek rozet (ara katlar, Gezgin, Dostlar, Kocaman aile, Sesli kitaplık, 10 klasik, 5 Original, Meraklı parmak) katalogda. ✅
9. **Dördüncü gizli rozet:** Masal yıldönümü eklendi. ✅
10. **Masal anıları:** Rozetlerim sayfasının sonunda dört anı kartı (rekor değil). ✅

**Yıldız puanı (5b; kabul: Batuhan, 15 Kasım 2026):**

11. **Sabah yıldızı:** bugün profil açıldığından beri her gün kendiliğinden geliyor; puan okumadan da artıyor. Karar: sabah yıldızı yalnızca o gün bir masal bitince gelir ("okuma sabahı"), puan ve kat yalnızca okumayla büyür. 13 Ekim kararının yerine. Göç: bugüne kadar kendiliğinden gelmiş sabah yıldızları geri alınmaz (puan düşmez); yeni kural güncellemeden sonraki günler için geçerli. ✅
12. **Rozet puan versin mi?** R0'da "rozet yıldız vermez" dendi. Duolingo rozetle mücevher veriyor. Karar: vermez, puan yalnızca okumadan gelir. ✅
13. **Kat adları ve eşikleri:** 12 kat, 10'dan 2000'e, 5b'deki tablo. ✅

## 8. Riskler

- **Oyunlaşma kayması:** 69 rozet tek başına baskı değil; baskıyı sayaç ve kayıp yaratır. Bu plan ikisini de içermez. Her yeni metin ilke 7'nin "Never like" listesine karşı okunur.
- **Göç hatası** rozetleri silerse güven kaybolur: R1'in ilk testi eski 8 rozetli JSON'un okunması.
- **Kutlama yorgunluğu:** geriye dönük rozetler sessiz, aynı anda en çok bir büyük kutlama.
- **Senkron:** eski sürüm cihaz yeni alanları silmemeli; birleşme yalnızca büyür, eski istemci bilinmeyen alanı yazmadığı için uzak defter `merge` ile korunur (R5'te kural testiyle doğrulanır).

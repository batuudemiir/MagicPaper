# Rozet planı: 8 rozetten 41 rozete

**Tarih:** 15 Kasım 2026 · **Durum:** R0 kararları verildi (Batuhan, 15 Kasım 2026); sıradaki R1
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
| Çok sayıda rozet, aileler hâlinde | ✅ 41 rozet, 10 aile | Yol uzar, her hafta bir şey olur |
| Kademeli rozet (seviye 1-10) | ✅ "kat": aynı rozetin büyüyen hâli | Tek kartta derinlik, ızgara kalabalıklaşmaz |
| Büyük kutlama anı | ✅ gündüz masal sonunda tek an; gece sessiz satır | Uyku vakti sakin kalır |
| Karakterin sevinci | ✅ Ragi'nin `cheer` pozu + tek cümle | Zaten var, rozete bağlanır |
| Gizli rozetler | ✅ 3 tane, "?" ile kilitli | Sürpriz merak yaratır, baskı yaratmaz |
| Rozet detayı (tarih) | ✅ "12 Kasım'da kazandın" | Aile anısı (ürün sütunu 7) |
| XP, puan, lig, sıralama | ❌ | İlke 7 yasaklar |
| Ardışık gün (streak) rozeti, seri dondurma | ❌ yerine **toplam okuma günü** | Ardışık gün kırılır ve suçluluk üretir; toplam gün asla kaybolmaz |
| İlerleme çubuğu, "2 ders kaldı" | ❌ | 13 Ekim kararı |
| Süreli meydan okuma, sınırlı etkinlik rozeti | ❌ | Geri sayım ve kaçırma korkusu |
| Push bildirimiyle rozet duyurusu | ❌ | İlke 7 |
| Rozetle yıldız/ödül verme | ❌ | Yıldız ekonomisi ayrı kalır; rozet ödül değil anı |

## 3. Katalog (41 rozet)

Eşikler ve adlar R0'da onaylandı. ✱ = bugünkü rozet (id korunur).

### A. Masal yolu (kademeli, 8 kat): her bitirilen farklı masal
| Kat | Eşik | Ad |
|---|---|---|
| 1 | 1 | İlk masal ✱ |
| 2 | 3 | Üç masal |
| 3 | 5 | 5 masal ✱ |
| 4 | 10 | 10 masal ✱ |
| 5 | 25 | 25 masal ✱ |
| 6 | 50 | 50 masal |
| 7 | 100 | 100 masal |
| 8 | 200 | Masal ustası |

### B. Ay arkadaşı (kademeli, 4): uyku masalı
1 İlk uyku masalı · 7 uyku masalı ✱ · 30 uyku masalı · 100 uyku masalı

### C. Yol açan (kademeli, 3): macera
İlk macera ✱ · 10 macera · 30 macera

### D. Meraklı (kademeli, 3): öğrenelim
İlk öğrenelim masalı ✱ · 10 öğrenelim · 30 öğrenelim

### E. Okuma günleri (kademeli, 4): masal bitirilen **farklı** gün sayısı, ardışık değil
3 gün · 7 gün · 30 gün · 100 gün okuduk
Metin: "7 ayrı günde birlikte okudunuz." Bir gün kaçınca hiçbir şey kaybolmaz.

### F. Kelime avcısı (kademeli, 4): Yeni kelimelerim'e giren kelime
İlk yeni kelime · 10 · 25 · 50 kelime

### G. Seri (3)
İlk devam (bir serinin 2. bölümü bitti) · İlk seri tamamlandı ✱ · 3 seri

### H. Keşif (6, tek)
- Üç kapı: üç moddan da en az bir masal
- İlk klasik · 5 klasik
- Bulut Durağı: ilk MagicPaper Original
- Yeni arkadaşlar: 5 farklı yol arkadaşıyla masal
- Sürprizci: "Bana sürpriz yap" ile yazılan bir masal bitti

### I. Ailemle (3)
- Ailem masalda: Masal ailem'den biri masala girdi
- Büyük aile: 3 farklı aile üyesi masallarda
- Annemin sesi / Babamın sesi (ad: "Tanıdık ses"): ebeveynin kaydettiği sesle bir masal dinlendi

### J. Gizli (3): kazanılana kadar "?" ve "Gizli rozet"
- Tekrar tekrar: aynı masal üç kez sonuna kadar okundu (tekrar okuma yıldız vermez, rozet verebilir; okuma sayılır)
- Sabah masalı: öğleden önce bitirilen bir masal
- Hafta sonu masalı: cumartesi ya da pazar bitirilen bir masal

Bilerek dışarıda: gece geç saat rozeti (geç yatmayı ödüllendirir), doğum günü rozeti (profilde doğum günü yok, istemek ilke 8'e aykırı), mevsim rozetleri (zamana bağlı, kaçırma hissi), uygulamada geçen süre, kahraman giydirme (okuma değil).

Ritim tahmini (haftada 4 masal okuyan 5-6 yaş çocuk): ilk hafta 4-6 rozet, ilk ay 12-15, sonra ayda 1-3. 200 masal ve 100 gün yaklaşık bir yıl. "Sürekli destek" bu dağılımdan gelir.

## 4. Görünüm

### 4.1 Rozet arması
- `MPBadgeCard` SF simgeden **arma**ya geçer: kâğıt kesik / nakış yama dili (el yapımı, ilke 9), parlak 3B ve metal yok.
- Kat, armanın etrafındaki dikiş halkası ve küçük yıldız sayısıyla gösterilir (1-8), renk ya da metalle değil (bilgi yalnızca renkle verilmez).
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
- Profil bölümü ilk 6 armayı gösterir (önce son kazanılanlar), başlık `MPSectionHeader` "Rozetlerim", `note:` "12 / 41", `link:` "Tümü ›".
- Yeni push sayfa `MPKidRoute.badges`: aileler `MPSectionHeader` ile; kademeli aile tek kart (en yüksek kazanılan kat), tek rozetler ızgara. Ragi bir kez, balonla.
- Kilitli rozet gri + kilit; gizli rozet "?".

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

- **Katalog tablo olur:** `MPBadge` (id, aile, kat, ölçü, eşik, gizli mi, ad, simge, ton) ve `MPBadgeCatalog.all`. `isMet` tek bir `metric(of: ledger)` + eşik karşılaştırmasına iner; 41 `case` yazılmaz. Bugünkü 8 rozetin `rawValue`'ları id olarak korunur, kazanılmış rozet kaybolmaz.
- **Defter büyür** (`MPBadgeLedger`), hepsi birleşebilir kalır:
  - `readingDays: Set<String>` (yerel takvim günü `yyyy-MM-dd`)
  - `words: Set<String>`, `classics`, `originals`, `companions`, `familyMembers`, `surpriseStories`, `voiceStories`: `Set<String>`
  - `seriesSecondEpisodes: Set<String>`
  - `finishCounts: [String: Int]` (tekrar tekrar için, birleşmede `max`)
  - `morningStories`, `weekendStories`: `Set<String>`
  - `seen: Set<String>` (kutlanmış/görülmüş rozetler; birleşmede birleşim)
- **Göç:** sentezlenmiş `Codable` eksik anahtarda hata verir; `init(from:)` `decodeIfPresent` ile yazılır. Yoksa eski defter okunamaz ve kitaplıktan baştan kurulur (rozet tarihleri kaybolur).
- **Geriye dönük kazanım:** güncellemeden sonra ilk açılışta defter kitaplık, kelime defteri, seri ve aile verisinden doldurulur. Bu rozetler **sessizce** verilir (`seen`'e girer), on beş kutlama arka arkaya patlamaz. Profil'de Ragi bir kez: "Yeni rozetler geldi, bak!"
- **Kazanma noktaları:** hepsi okuyucunun masal sonundaki tek çağrıdan (`MPBadgeStore.recordFinished`) geçer; kelime ve aile verisi o anda masaldan okunur. Uygulama içinde başka yerde rozet verilmez (rozet yalnızca okuyarak).
- **Eşitleme:** `SyncCollection.badges` aynı; Firestore kuralı yeni alanları kabul eder, kural testi eklenir.
- **Yıldızla ilişki yok:** rozet yıldız vermez, yıldız rozet açmaz.
- Domain mantığı görünümde değil: `MPMilestones.swift` → `Services/Badges/` (`MPBadgeCatalog`, `MPBadgeLedger`, `MPBadgeStore`); görünümler yalnızca okur.

## 6. Fazlar

| Faz | İş | Sahip ajan | Çıktı |
|---|---|---|---|
| **R0** ✅ | Kararlar verildi (bkz. 7) | Batuhan | 15 Kasım 2026 |
| **R1** | Model: `MPBadge` tablo, defter alanları, `decodeIfPresent` göçü, geriye dönük doldurma, `seen` | builder (library-memory danışır) | Birim testleri: her rozetin eşiği, birleşme kaybetmez, eski JSON okunur, tekrar okuma ikinci kez saymaz |
| **R2** | Kazanma: okuyucu masal sonu çağrısına kelime, klasik, Original, arkadaş, aile, ses, sürpriz, seri bölümü, gün bilgisi | builder | Testler: her ölçü doğru masaldan dolar |
| **R3** | Görünüm: `MPBadgeArt` yer tutucu + kat halkası, `MPBadgeCard` v2, `MPKidRoute.badges` sayfası, Profil bölümü, detay sheet | ui-agent brif → builder | Tasarım yasası grep'leri boş |
| **R4** | Anlar: tam ekran rozet anı (gündüz) ve gece satırı, Ragi cümleleri, ana sayfa selamı, sessiz nokta | builder, reader | Uyku vaktinde ses yok testi |
| **R5** | Ebeveyn: çocuk profil sayfasında rozet listesi; eşitleme kuralları | builder, privacy-safety | Firestore kural testi |
| **R6** | Doğrulama: bütün testler, simülatörde açık/koyu, AX5, SE + Pro Max; değişiklik günlüğü | yok | Test ve simülatör yalnızca burada, bir kez |
| **Sonra** | Arma çizimleri (41 + 8 kat halkası) | illüstratör | `MPBadgeArt` yer tutucusunun yerine |

## 7. R0 kararları (Batuhan, 15 Kasım 2026)

1. **Okuma günü rozetleri:** toplam farklı gün sayılır, ardışık değil. ✅
2. **Kilitli rozet:** dokununca eylem cümlesi ("Bir macera masalı okuyunca açılır"); sayı, çubuk, "kaldı" yok. 13 Ekim'deki ipucusuz kilit kararının yerine. ✅
3. **Gizli rozetler:** üçü de (Tekrar tekrar, Sabah masalı, Hafta sonu masalı). ✅
4. **Tavan:** 200 masal, 100 okuma günü. ✅
5. **Kutlama:** gündüz masal sonunda tam ekran an (4.2); gece sessiz satır. ✅
6. **Adlar:** bu belgedeki adlar kalır; İrem turu beklenmez. ✅
7. **Arma:** önce kodla çizilen arma (simge + ton + kat halkası, `MPBadgeArt`), çizimler gelince tek yerden değişir. ✅

## 8. Riskler

- **Oyunlaşma kayması:** 41 rozet tek başına baskı değil; baskıyı sayaç ve kayıp yaratır. Bu plan ikisini de içermez. Her yeni metin ilke 7'nin "Never like" listesine karşı okunur.
- **Göç hatası** rozetleri silerse güven kaybolur: R1'in ilk testi eski 8 rozetli JSON'un okunması.
- **Kutlama yorgunluğu:** geriye dönük rozetler sessiz, aynı anda en çok bir büyük kutlama.
- **Senkron:** eski sürüm cihaz yeni alanları silmemeli; birleşme yalnızca büyür, eski istemci bilinmeyen alanı yazmadığı için uzak defter `merge` ile korunur (R5'te kural testiyle doğrulanır).

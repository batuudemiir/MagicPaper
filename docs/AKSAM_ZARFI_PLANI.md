# Akşam zarfı: planı

Durum: plan (20 Ekim 2026). Kod yazılmadı.
Nöropazarlama beyin fırtınasının üçüncü maddesi; önceki iki madde: masal atölyesi (`MASAL_ATOLYESI_PLANI.md`) ile ithaf ve künye.

## 1. Neden

Bugün akşam kartı ya günün klasiğini gösteriyor ya da "Yarın yeni bir masal hazır olacak" diyor. Ama ertesi akşam çocuğa ait hazır bir masal yok, ebeveyn yine "yarat" akışına giriyor.

Zarfın amacı şu: aile akşam uygulamayı açtığında, çocuk için yazılmış ve henüz kimsenin okumadığı bir masal hazır olsun. Bu üç etkiye dayanıyor:

- **Beklenti:** mühürlü bir şey açılmak ister.
- **Sahiplik:** masal "senin için yazıldı".
- **Ritüel:** her akşam aynı sakin an.

Hız vaadi ya da baskı yok. Zarf ödül değil; açılmazsa hiçbir şey kaybedilmez.

## 2. Kararlar

Batuhan, 20 Ekim 2026:

1. **Yer ve zaman:** Ana sayfadaki "Bu akşamın masalı" kartı, akşam saatinde mühürlü bir zarfa döner. Günün klasiği bu karttan çekilir; Günlük sekmesinde zaten duruyor.
2. **İçerik:** Açık bir serinin bugünkü bölümü açıldıysa zarf o bölümdür. Yoksa motor cihazda yeni bir masal yazar.
3. **Açılmayan zarf:** Ertesi gün sessizce kitaplığa girer. Birikmez, "kaçırdın" denmez, kaybolmaz.

Önerilen ve onay bekleyen varsayılanlar (§9):

- Zarf penceresi **17.00**'de açılır, sabah 05.00'te (`MPTonight.morningHour`) kapanır.
- Yeni masalın modu **Uyku öncesi** olur (akşam masalı). Arkadaşı ve ilgi alanını motor seçer, "Bana sürpriz yap" gibi.
- "Masalları onayla" açıksa zarf hazırlanmaz: onay ayrı bir ebeveyn ritüeli.
- Hiç masalı olmayan çocuğa zarf yok; ilk masal onboarding'den gelir.
- Çocuk başına günde bir zarf; etkin çocuğun zarfı gösterilir.

## 3. Akış

1. Ebeveyn akşam uygulamayı açar ya da öne getirir. Ana sayfa görünür, pencere açıktır, bu çocuğun bugünkü zarfı yoktur.
2. Zarf hazırlanır:
   - açık serinin hazır bölümü varsa o bölüm sarılır, yeni masal yazılmaz;
   - yoksa `StoryGenerationManager.createStory(mode: .bedtime, …)` çağrılır.

   Tohum `zarf-<çocukID>-<yyyy-MM-dd>` olur, böylece aynı gün yeniden kurulsa da aynı masal çıkar.
3. Zarf hazırlanırken kart bekleme göstermez; mevcut durumunda kalır. Hazırlık ~1 sn sürer ve arka planda yapılır.
4. Kart zarfa döner:
   - üst satır: "Bu akşamın zarfı";
   - başlık: "İrem'e bir masal yazıldı";
   - alt satır: "Mühürlü. İlk sen okuyacaksın.";
   - düğme: "Zarfı aç".

   Seri bölümünde başlık "Serinin 3. bölümü geldi" olur.
5. "Zarfı aç" ile kısa bir açılış ritüeli başlar (~2,5 sn, atlanabilir):
   - zarfın kapağı kalkar;
   - içinden bir kart çıkar: ithaf satırı (`StoryColophon.dedication`) ve masalın adı;
   - okuyucu kapaktan açılır.
6. Açılan zarf "açıldı" diye kaydedilir ve masal kitaplıkta görünür olur. Kart artık normal kuralına döner (yarım masal → devam, okunduysa "Bugün okudun").
7. Açılmayan zarf, gün dönünce mührünü yitirir ve kitaplıkta sıradan bir masal olarak durur. Yeni günün zarfı kendi penceresinde gelir.

## 4. "Bu akşamın masalı" kuralı

`Surfaces/MPTonight.swift` yeni bir durum alır: `.envelope(Envelope)`. Widget, Siri ve Ana sayfa aynı kuralı okuduğu için zarf üç yerde de görünür.

Sıra:

1. Yarım masal → devam. Yarım kalan masal zarftan önce gelir: önce bitirilir.
2. Mühürlü zarf → zarf.
3. Bugün okunmadıysa → günün masalı (zarf penceresi dışında ya da zarf hazırlanamadıysa).
4. Okunduysa → "Bugün okudun".

Uyku saatindeyken (`bedtime`) ve mühürlü zarf varken kart zarfı gece renginde gösterir; "Zarfı aç" zarfı açar. Uyku modu açıksa masal oradan sürer. Zarf yoksa bugünkü uyku davranışı aynen kalır.

## 5. Mimari

Görünüm mantık taşımaz (CLAUDE.md ilke 3). Yeni dosyalar `StoryEngineBridge/` altına gider; o klasör senkronlu, `Models/` değil.

| Parça | Görev |
|---|---|
| `EveningEnvelope` (saf) | Pencere hesabı, tohum, durum (`notYet`, `sealed(storyID)`, `opened`, `none`), seri bölümünün önceliği, gün dönünce mührün düşmesi. Saat ve takvim dışarıdan verilir. |
| `EveningEnvelopeStore` | Çocuk başına tek kayıt: tarih, masal kimliği, tür (yeni/seri), açılma anı. Yerel `UserDefaults`, senkron yok: ritüel cihaza ait. |
| `EveningEnvelopeWriter` | `@MainActor`. Pencere açık ve kayıt yoksa zarfı hazırlar: seriye bakar, değilse `createStory`. Hata olursa zarf yok, kart eski kuralına döner, log'a çocuk bilgisi yazılmaz. |
| `MPTonight` + `MPTonightSource` | `.envelope` durumu ve girdisi. |
| `HomeHeroCard` (`MPHomeChrome.swift`) | Yeni `TonightState.envelope`: zarf simgesi ve mühür. Dolgun mor yüzey aynı kalır, gecede gece gökyüzü. |
| `EnvelopeOpeningView` (yeni) | Açılış ritüeli: `MP.M.page`/`MP.M.slow`; Reduce Motion'da çapraz geçiş; "Atla" her an var; tek titreşim (`MPHaptics`). |
| Kitaplık süzgeci | Mühürlü masal kitaplıkta görünmez: `MPStoryGate` yanına küçük bir `isSealed` koşulu. |
| `MPReminder` | Hatırlatma açıksa gövde metni "İrem'in bu akşamki zarfı hazır." olur. Bildirim tekrarlayan bir tetik; zarf ebeveyn uygulamayı açınca yazıldığı için metin doğru kalır. |

**Ortak dosyalar** (Shared File Rule): `MPHomeChrome.swift`/`HomeView.swift` ana sayfa işinin dosyaları, `LibraryView.swift` şu an kitaplık UX'ini yeniden tasarlayan oturumda. Kitaplığa dokunuş tek satırlık süzgeçle sınırlı tutulur ve o oturumla sıraya konur.

## 6. Dil

- Zarf masalı "yazıldı"; "üretildi" ya da "hazırlanıyor %…" yok.
- Süre, geri sayım, "son saatler", "kaçırma" yok.
- Açılmayan zarf için hiçbir metin yok.
- Bildirim çocuğa değil ebeveyne seslenir (`MPReminder.body` kuralı).

## 7. Test (test-first)

- `EveningEnvelopeTests`:
  - pencere sınırları (16.59 / 17.00, 04.59 / 05.00);
  - aynı gün aynı tohum, ertesi gün farklı tohum;
  - hazır seri bölümünün yeni masala tercih edilmesi;
  - gün dönünce mührün düşmesi;
  - onay açıkken ve masalsız çocukta zarf olmaması;
  - çocuk başına tek kayıt.
- `MPTonight` testleri: yeni sıra (devam > zarf > günün masalı > okundu) ve uyku saatinde zarf.
- Kitaplık: mühürlü masal listede yok, açılınca var.

## 8. Doğrulama

- Simülatörde saat oynatılarak (17.00 öncesi ve sonrası, gece, ertesi gün):
  - kart zarfa dönüyor;
  - "Zarfı aç" ritüeli çalışıyor;
  - masal kitaplığa giriyor;
  - ertesi gün açılmayan zarf kitaplıkta.
- Widget ve Siri'de zarf metni.
- Reduce Motion, en büyük Dynamic Type, iPhone SE ve Pro Max, gece kartı.
- CLAUDE.md tasarım yasası grep'leri ve dil grep'i.

## 9. Onay bekleyenler

1. Pencere 17.00 mı, yoksa ebeveynin "Masal saati"nden (hatırlatma saati, ör. 20.30) belli bir süre önce mi?
2. Yeni masalın modu hep Uyku öncesi mi, yoksa çocuğun en çok okuduğu mod mu?
3. "Masalları onayla" açıkken zarf hiç hazırlanmasın mı (öneri), yoksa onay bekleyenlere mi düşsün?
4. Açılış ritüeli ~2,5 sn ve atlanabilir: uygun mu?
5. Seri bölümü varken başlık "Serinin 3. bölümü geldi" mi olsun, yoksa yine "İrem'e bir masal yazıldı" mı?

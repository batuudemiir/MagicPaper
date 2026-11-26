# Beş arkadaş P56 runtime uygulama planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development. Kullanıcı B tasarımını ve uygulamaya devamı onayladı. Bu belge mevcut onaylı pilotun teknik yürütme planıdır; yeni yayın izni değildir.

**Goal:** Beş kanonik arkadaşın 5–6 yaşta üç moddaki iki uygun kurgusunu kişiselleştirilmiş, kaynak izli ve deterministik bir internal motor yolunda çalıştırmak.

**Architecture:** Legacy composer, validator, katalog ve K1 kaynak sözleşmesi değişmez. P56 kendi açıkça seçilen payload codec'i, kaynak kimliği, tipli nedensel geçişleri ve çıktı tipiyle çalışır. Paket uygulama/motor kaynak bundle'ına eklenmez; test/internal servis yalnız açık payload Data alır. Üretim politikası kapalı kalır.

**Tech Stack:** Swift/Foundation, mevcut TurkishTextRenderer ve yaş/metin ölçümleri; offline Python paket serileştirme. Metin/görsel API'si yok.

## Karar ve sınırlar

- Ana kimlikler Tarçın `companion_fox_pilot_001`, Kestane `companion_hedgehog_pilot_001`, Yıldız `companion_owl_pilot_001`, Simit `companion_city_cat_001`, Böğürtlen `companion_bear_001`.
- 9 mekanizma, 30 izinli kurgu/karakter çifti, 15 hücrenin her birinde 2 mekanizma. Her arkadaş her şablona açılmaz.
- Fısıldayan Orman gündüz, ayrı orman kıyısı odası uyku; Simit ziyaretçi. Kanonik eski habitat/trait kayıtları değişmez.
- Aile, konuk, recall, özel gün, seri, konu ve diğer yaşlar desteklenmiyorsa bütün red nedenleri açık döner; bağlam sessizce atılmaz. Sürpriz seçim de aynı beşli içinde kalır.
- `offline-p56-v1` ayrı davranıştır. P56'yı `offline-legacy-v1` veya ContentPackage şema 2 diye etiketlemek yasak. K1 legacy decoder/resolver'ına yeni formatın desteklenmesini eklemiyoruz.
- Metinlerin 30 kitap olması 30 mekanizma veya geniş kombinatoryal çeşitlilik değildir. İki sabit kitap/hücre sınırı ve tekrarlar raporlanır.
- Konuklu meslek, deniz, uzay ayrı sonraki teslimler. Pilot teknik başarısı genel yayın, sanat veya tüm yaş/katalog kabulü değildir.

## 1. Editoryal girdiyi düzelt ve izini koru

**Sahip:** content-library; yalnız `Content/Pilots/five-friends-56-v1/` ve okunabilir korpus.

- [ ] U1 Tarçın/Yıldız p1 bağlacını, U2 ayı p6–7 çift dönüşünü düzelt.
- [ ] Metni değişmiş sayfalara yeni sourceID/SHA ver; eski metin ve SHA revision ledger'da korunur. Metadata düzeltmesi ayrı revision kaydıdır.
- [ ] Tüm sayfalarda gerçek eylem aktörlerini ayır; baykuş uçuşunu çocuğun eylemi sayma. U2 props kitap özelinde; A3 mevcut/hatırlanan kökleri ve p8 offscene kökü ayır.
- [ ] Bağımsız 30 kitap/240 sayfa incelemesinin bulgularını ve kalan anlatım cilası ihtiyacını raporla. Art onayı verme.

## 2. Gerçek runtime paketi

**Sahip:** builder. **Yeni klasör:** `Content/Pilots/five-friends-56-runtime-v1/`.

- [ ] Önce yükleme/kimlik/red testlerini yaz; AGENTS gereği test koşusu en sonda.
- [ ] `build_runtime_package.py`: düzeltmiş authored kaynaklardan `payload.json` üretir. Tüm yorumlama girdileri tek immutable payload'da: template metinleri, parent source kimlik/hash, canonical profiller, kurgu/beat/state, settings ve semantik bağlam.
- [ ] Deniz fixture'ından açık dilbilgisel slot türevleri yeni sourceID alır; eski ID altındaki metin değişmez. Nominative/genitive/dative formları tanımlı dönüştürülür, bilinmeyen artık Deniz formları export hatasıdır.
- [ ] Manifest exact tam payload byte SHA-256'sını ve kapalı yayın kapılarını taşır. Authoring manifest veya tek sources dosyası hash'i tam kaynak kimliği yerine geçmez.
- [ ] Ayrı loader yalnız explicit Data alır; bundle/additionalResourceNames veya remote feed'e kayıt yok.

## 3. Tipli motor ve kişiselleştirme

**Yeni klasör:** `StoryEngine/Sources/StoryEngine/Pilots/P56/`.

- [ ] P56Package/Loader/Request/Selection: şema, davranış, canonical ID, exact30pair ve fail-closed doğrulama; tek deterministik seçim, retry/reseed yok.
- [ ] P56Beat/NarrativeState/StructureValidator: dokuz mekanizmanın gerçek önce/sonra kanıtları. State authored string'den kopyalanmaz; sıralı geçişten türetilir.
- [ ] U3: anı seçimi → paylaşma → sınır koyma → anlatıyı bırakma → uyanık dinlenme → sakin kapanış. Sahte anomali/bakım/başarısız deneme veya uyku çıkarımı yok.
- [ ] Öğrenme gözlemi çıkarımdan önce, A2 sıra seçimi tamamlamadan önce, A3 kişisel tanıma geri almadan önce kurulmalı. Arkadaş katkısı çocuğun çözümünü ele geçirmez.
- [ ] P56StoryComposer/ComposedStory/PageProvenance/Personalization: ayrı tipli çıktı; mevcut Türkçe renderer/kelime-cümle ölçümleri yeniden kullanılır.
- [ ] 8 sayfa, gerçek yaş/sentence sınırları, uyku eğrisi/aynı oda/CalmEnding uygulanır. Eski validator'ı gevşetme. Bütçe aşımı varsa açık hata/kaynak düzeltmesi.
- [ ] Her çıktı tam sıralı composing parts, template/parent SHA/pointer, renderedText digest, state trace, temporal subjects ve somut eylem kanıtı taşır. Sentence segmentation bağımsız compose değilse fazladan part sayılmaz.
- [ ] Çocuğun görünümü metin motorunda yeniden türetilmez; varsa canonical CharacterEngine kimlik referansı kullanılır.

## 4. Internal app kaynağı ve sanat kanıtı

**Sahip:** root. **Yeni klasör:** `MagicPaper/StoryEngineBridge/Pilots/P56/`.

- [ ] P56SnapshotStore: tam payload digest adıyla atomik arşiv; her okumada hash+loader doğrulaması; semver ikamesi yok. Testte temp dizin.
- [ ] P56InternalService: yalnız explicit payload/repository injection; üretim resolver/singleton çağırmaz. Draft ve kaynak birlikte döner, library kaydı veya mevcut StoryOrigin'e sahte legacy ref yazmaz.
- [ ] P56 çıktısı mevcut saved Story/Series formatına sokulmaz. Internal tekrar okuma/replay ayrı P56 tipiyle exact kaynaktan olur. Legacy kaynak yolu değişmez.
- [ ] P56 sanat handoff'u bütün gerçek metin, kaynaklar, önce/sonra ve temporal/actor bilgisiyle export edilir. İncelenmiş P56 art kuralı yoksa sonuç açıkça unapproved/no-reviewed-rule; eski asset'leri otomatik takma.
- [ ] Üretim etkinleştirme sabiti kapalıdır; remote flags veya içeriğin diskte bulunması pilotu açamaz. Yeni ürün ekranı/ayar anahtarı ekleme.

## 5. Son doğrulama ve ölçüm

**Yeni testler:** `StoryEngine/Tests/StoryEngineTests/P56*.swift`, `MagicPaperTests/P56*.swift`.

- [ ] 30 izinli çift doğrudan; yasak çiftler; 15 hücrede tam2mekanizma; sürpriz mod/arkadaş; bağlam red matrisi.
- [ ] Bozuk payload/source/pointer/parent, duplicateID, yanlış profil/allowlist reddi. Eksik gözlem/yanlış aktör/erken retrieval/uydurulmuş bakım/yanlış present/sleep negatif senaryoları.
- [ ] Türkçe 7 isim, ad/ek sonuçları, determinism ve kaynak-render tutarlılığı.
- [ ] N kolu: 15 hücre × 100 sabit ilk-deneme seed =1500. Zorlanmış30örnek ayrı. Başarısızlar paydada; tekrar veya art yok diye yeniden deneme yok.
- [ ] Mekanizma dağılımı, yapısal imza, aynı metin ve source tekrar pencereleri; 2kitap/hücre tavanı açık. Teknik text kabulü çeşitlilik/art kabulü diye sunulmaz.
- [ ] 1500 girdide zero-art/books-with-art/pages-with-art ve başlangıç/orta/son/tekrar/red nedenleri raporlanır; artApproved=false. Ölçümde asset erişilebilirliği metin seçimini etkilemez.
- [ ] K1 legacy fixture, kaynak kimliği, seri ve determinism regresyonları; 252 frozen içerik hash'i 0 değişim. Testler uygulama sonunda toplu; sonradan bulunan gerçek hata düzeltilirse ilgili kontroller tekrarlanır.
- [ ] `docs/research/five-friends-p56-runtime/` rapor/sampling/art-handoff, proje hafızası ve yalnız kendi DEMO_CHANGELOG kaydı; sonra yalnız kendi dosyalarını commit. Push/deploy yok.

## Kabulün anlamı

Bu teslimin hedefi çalışan ve ölçülmüş internal P56 motorudur. Görsel kapsam, tekrar yeterliliği, editoryal son kabul ve açık ürün yayın kararı eksikse yeni üretim politikası kapalı kalır. Kaynağı olmayan eski kitap/seri devamlarının K1 sınırı bu teslimle otomatik çözülmüş sayılmaz.

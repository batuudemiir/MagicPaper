# Sayfa görselleri: pilot çizim listesi

**Tarih:** 20 Kasım 2026 · **Plan:** `docs/ANLATI_PLANI.md` A2, A2g, A9 · **Pilot:** 5-6 yaş macera, Fısıldayan Orman

**İş bölümü (karar: Batuhan, 20 Kasım 2026).** Çizimleri Batuhan ChatGPT ile yaptırır. Gerisi (anahtar sözlüğü, motorun sayfa görsel planı, uygulamada katalog ve birleştirici, yedek motifler, testler) kodda yapılır. Çizimler gelmeden de sistem çalışır: eksik görsel dünyanın süs motiflerine düşer.

**Sayfa resmi katmanlıdır ve çocuk figürü yoktur** (karar: Batuhan, 20 Kasım 2026). Resim masalın öğelerinden kurulur: arka plan (mekân) + tek odak (yol arkadaşı ya da bulunan nesne, sayfaya uygun hâliyle).

## 1. Sayfada ne görünecek

Motor her sayfa için tek bir odak seçer. Pilotun altı olay örgüsünün hepsi aynı düzende:

| Sayfa | Rol | Görünen |
|---|---|---|
| 1 | Bir şey dikkat çeker | arka plan + **nesne, `found`** (yerde, bulunduğu hâliyle) |
| 2 | Yakından bakılır | arka plan + **nesne, `close`** (yakın, ayrıntılı) |
| 3 | Yol arkadaşıyla tanışma | arka plan + **arkadaş, `greet`** |
| 4-6 | Karar, deneme, zorluk | arka plan + **arkadaş, `together`** |
| 7 | Çözüm | arka plan + **nesne, `close`** ya da yırtık haritada `whole` |
| 8 | Kapanış | **arka plan, akşam** + arkadaş, `glad` |

## 2. Üretim kuralları

**Önce stil sayfası.** İlk iş tek görsel değil, bir stil sayfasıdır: aynı üslupta 3 nesne + 1 hayvan + 1 orman parçası, yan yana. Onaylanınca bundan sonraki her istemde bu görsel **referans olarak eklenir** ("match the style of the attached reference exactly"). Tutarlılığın tek güvencesi budur.

**Her istemin başına aynı üslup cümlesi** (değiştirmeden kopyala):

> Hand-painted children's picture book illustration, gouache and colored pencil texture, visible paper grain, soft rounded shapes, warm muted natural palette, soft diffused light, gentle low-contrast shadows, calm and friendly mood. No text, no letters, no numbers, no signature, no watermark. Not 3D, not Pixar style, no glossy or plastic surfaces, no neon, no rainbow gradients, no sparkle effects, not scary.

**Teknik şartlar**

| Tür | Boyut | Zemin | Not |
|---|---|---|---|
| Arka plan | 2048 × 1536 px (4:3) | dolu | Karakter ya da nesne yok. Alt ortada sade, açık bir zemin bırak: odak oraya oturur. |
| Odak (arkadaş, nesne) | 1024 × 1024 px (1:1) | **şeffaf PNG** | Kenarda en az %8 boşluk. Yalnızca öğe ve altında yumuşak bir temas gölgesi; zemin, çimen, arka plan yok. Öğe karenin ortasında, önden ya da hafif yandan. |

**Dosya adı ve yer:** `Visual/<anahtar>_<hâl>_01.png` → `Assets.xcassets/Visual/<anahtar>_<hâl>_01.imageset/`. İkinci bir çeşit üretilirse `_02`. Teslim için dosyaları tek klasörde vermen yeterli; kataloğa ben eklerim.

**Eleme:** Her görsel elle bakılır. Reddet: yazı ya da harf içeriyorsa, gölge sert ve koyuysa, hayvanın yüzü korkutucu ya da insansı ise, öğe kesikse, şeffaf zemin yerine beyaz zemin geldiyse.

## 3. Kademe 1 (ilk teslim, 29 görsel)

Bu kademe tek başına bir masalı baştan sona görselli yapmaya yeter: en sık bağlanan altı yol arkadaşı ve altı nesne.

### Arka plan (2)

| Dosya | İstem (üslup cümlesinden sonra) |
|---|---|
| `vk_whispering_forest_day_01` | A calm sunlit forest with a narrow soft path between tall gentle trees, ferns and moss, dappled light, a quiet open clearing at the lower center. Wide view, no characters, no objects. |
| `vk_whispering_forest_evening_01` | The same calm forest at golden evening, warm low sunlight between the trees turning into soft blue dusk, a quiet open clearing at the lower center. Wide view, no characters, no objects. Cozy, not dark. |

### Yol arkadaşları (6 × 3 = 18)

Her arkadaş için üç poz: `greet` (merakla bakıyor, bir patisini hafifçe kaldırmış, selam verir gibi), `together` (yürüyor ya da bir şeye yardım ediyor, yana dönük, kararlı), `glad` (sevinçli, rahat, gülümser gibi). Aynı hayvanın üç pozu birbirinin aynısı olmalı: renk, yüz ve beden değişmez.

| Anahtar | Ad | İstem konusu |
|---|---|---|
| `vk_fox` | Tarçın, tilki | a small warm russet fox with calm eyes and a soft brush tail |
| `vk_hedgehog` | Kestane, kirpi | a small round hedgehog with a gentle face and soft quills |
| `vk_rabbit` | Pamuk, tavşan | a small white rabbit with long attentive ears |
| `vk_cat` | Pati, kedi | a small fluffy white cat with a kind face |
| `vk_squirrel` | Fındık, sincap | a small red squirrel with a big fluffy tail |
| `vk_bear` | Böğürtlen, ayı | a small friendly brown bear cub, round and soft |

Dosyalar: `vk_fox_greet_01`, `vk_fox_together_01`, `vk_fox_glad_01` ve diğerleri için aynı düzen.

İstem kalıbı: *"[konu], [poz tarifi], full body, centered, isolated on a transparent background, soft contact shadow only."*

### Nesneler (6 nesne, 9 görsel)

| Dosya | İstem konusu |
|---|---|
| `vk_torn_map_found_01` | an old paper map torn in half, lying slightly crumpled, faded drawn paths and a small tree drawing, one torn edge |
| `vk_torn_map_close_01` | close view of the torn half of an old paper map, faded drawn paths, one ragged torn edge, held flat |
| `vk_torn_map_piece_01` | the missing other half of the same old paper map, matching ragged torn edge |
| `vk_torn_map_whole_01` | the two halves of the same old paper map placed together, torn line visible in the middle, complete paths |
| `vk_footprints_found_01` | a short trail of small animal footprints pressed into soft earth, fading out at the end (top-down, slightly angled) |
| `vk_feather_found_01` | a single soft colorful feather lying gently, blue and amber tones |
| `vk_key_found_01` | a small old golden key with a round loop, slightly worn |
| `vk_paper_lantern_found_01` | a small round colorful paper lantern with a soft warm glow inside, hanging from a short string |
| `vk_map_found_01` | an old rolled paper map, partly open, faded drawn paths |

(`found` görseli yakın sayfalar için de kullanılabilir; ikinci hâlleri kademe 2'de.)

## 4. Kademe 2 (42 görsel)

| Grup | Görseller |
|---|---|
| Kalan yol arkadaşları × 3 poz | `vk_dog` (Cesur, small brown dog), `vk_dragon` (Kıvılcım, tiny friendly round dragon, soft green, not scary), `vk_firefly` (Pırıltı, a small firefly with a soft warm glow), `vk_frog` (Zıpzıp, small green frog), `vk_owl` (Yıldız, soft grey owl with round patient eyes), `vk_robot` (Zip, small round silver robot, soft and friendly), `vk_sparrow` (Cıvıl, small brown speckled sparrow): 21 |
| Kalan nesneler `found` | `vk_bell` (small silver bell), `vk_coin` (old coin with strange worn shapes), `vk_compass` (brass compass), `vk_crystal` (softly glowing blue crystal), `vk_flickering_light` (a small soft floating light, no source visible), `vk_goggles` (explorer goggles with brass rims), `vk_lantern` (old metal lantern, warm light), `vk_music_box` (small old wooden music box, lid open), `vk_star_stone` (a star-shaped shiny stone): 9 |
| `close` hâlleri | kademe 1'in dört nesnesi (tüy, anahtar, kâğıt fener, harita) + kademe 2'nin sekiz nesnesi (titrek ışık hariç): 12 |

## 5. Sonra

Pilot okuyucuda görülüp onaylanınca dünya dünya genişler (A9 tam kapsam: 400-450 görsel). Sıradaki dünyalar için liste aynı biçimde bu klasöre eklenir.

# Corrected v3: fresh content safety review

## Status and scope

Freshly read all 90 titles and all 720 full pages in the 15 corrected v3 files. Read metin-duzeltme-notu.md first. Dalga 1 is outside this review. Text was preserved; no old review JSON was loaded to inherit its labels. The JSON contains full exact source quotes, individual page emotions and rationales, title review, and explicit exclusion rationale for every omitted canonical topic. Source-file digests pin the reviewed input snapshot. Root must bind runtime book IDs, source IDs and SHA256 values. bookID currently equals sourceBookID as a binding placeholder.

Status reviewed means inspected; it does not confer production or art approval. No serious content safety blocker found in corrected v3. The former prolonged breath-holding issue is resolved. No handkerchief is found/recovered by the companion instead of Deniz. No forest berry is harvested/eaten.

## Topic decisions and emotion policy

Weather is conservative and includes explicit sunshine/wind/breeze/rain references, even harmless sunlight or rain-smell jokes. This is a topic filter, not a hazard severity claim. Water on a leaf alone does not prove rain. Darkness requires explicit darkness/dimness, dimming a lamp, or night as the title subject; evening, goodnight greetings, night-blue colour and ordinary daylight shade/remembered shadows alone are excluded. Alone requires separation/isolation; Turkish yalnız meaning only is excluded. Fear excludes comic surprise, mild object-loss concern, ordinary questions and playful encouragement of a droplet. Heights includes a tiny hedgehog explicitly climbing and rolling off a folded blanket; low owl perches, ground-level steps, raised leaf edges and a tall-tree comparison are excluded.

Page counts: weather 58; darkness 7; heights 1; alone 0; fear 0. Title topics are reviewed separately and may add a book topic. Newly added dim light in pilot56_book_u3_fox_event03_v1 p7 is darkness (“ışık da loştu”). All emotions are existing engine EmotionalState values with intensity <=2. No fear/panic/grief/despair. Engine tenseEmotions is only unease/hesitation; neither is warranted here. Mild concern/puzzlement/patience do not make calmEligible false under that engine definition.

## Resolved findings

- **pilot56_book_l3_bear_v1, title/p3/p5/p7:** title is now “Böğürtlen Böğürtlenle Sayıyor”. P3: “Böğürtlen damlaya bakıp bordo çantasını açtı.” and “Yere bir böğürtlen koydu.” P5: “Böğürtlen yere dördüncü böğürtleni koydu.” P7: “Sonra hepsini çantasına geri koydu.” Counting replaces sustained breath-holding. This is a safe resolution of the previously identified imitation concern; no berry is eaten from the ground here.
- **pilot56_book_a2_owl_v1 p5:** “Yıldız parçanın kenarına kondu ve pençeleriyle sabit tuttu.” Deniz places the first piece, Yıldız holds with talons, Deniz turns/places the second.
- **pilot56_book_a2_owl_event02_v1 p5:** “Yıldız parçanın kenarına kondu, pençeleriyle sabit tuttu.”
- **pilot56_book_a2_owl_event03_v1 p5:** “Yıldız kenarına kondu ve parçayı pençeleriyle sabit tuttu.” The friend supports rather than substitutes for the child's placement. Art must depict talons holding, not a wing.

## Remaining minor editorial concerns (not safety release blockers)

1. **pilot56_book_a2_bear_v1 p3/p7, berry origin timing.** P3 says “dedi, ağzındaki böğürtleni yutarak.” P7 explicitly establishes “Böğürtlen çantasından iki böğürtlen çıkardı.” Carried berries are established within the book; no foraging occurs. If every eaten berry requires same-page origin, p3 should explicitly refer to own bag. This is an ambiguity, not evidence of eating forest fruit.
2. **pilot56_book_l2_bear_event02_v1 p3/p5/p7, second snack origin.** P3 “Çantasından bir böğürtlen çıkardı”; p5 follows chewing; p7 “Böğürtlen sevinçle bir böğürtlen daha yedi.” Another carried snack is implied without repeating bag origin. Clarify only if same-page provenance is strict.
3. **pilot56_book_l2_owl_v1 p5, early discovery noun.** Yıldız says “Ters bakınca da yaprak” before Deniz's formal identification at p6–7. Deniz still changes viewpoint and combines the evidence personally. Consider withholding explicit leaf noun if independent discovery timing is strict.
4. **pilot56_book_u2_cat_event02_v1 and pilot56_book_u2_hedgehog_event02_v1 p1–2:** “Deniz yatağının yanına bir örtü serdi” occurs on both pages without a reset. Minor repeated action.
5. **pilot56_book_u2_cat_v1 p3/p5/p8:** requested “düz bir yer”, tested “minder”, later called “orman yastığı”. Flat cushion can satisfy the request; surface noun shifts.
6. **New wording concern: pilot56_book_l2_bear_v1, pilot56_book_l2_hedgehog_v1, pilot56_book_l2_owl_v1 p6:** added “Şimdi bütün dalı görüyordu.” The reasoning combines two parts of a hidden leaf; the next page establishes “tek bir yaprak”. This sentence switches the inferred object from leaf to branch and may confuse the learning explanation. Suggest text-owner review of dalı vs yaprağı. No physical safety issue.
7. **Minor phrasing: pilot56_book_l2_hedgehog_event02_v1 p5:** “Kestane burnunu kıpırdatarak, hiç kıpırdamadan sabırla bekledi.” Could mean body still while nose moves, but absolute “hiç” creates a small literal inconsistency.

No source edits were made. Remaining berry joke in pilot56_book_l2_bear_event03_v1 p3 guesses fruit inside a curled leaf, adds “Yaprağın içi boştu”; p8 explicitly uses own bag. Leaf stays untouched. No new child-agency substitution found.

## Page ledger

Each entry below maps to the complete exact quote and emotional rationale in JSON; every unassigned topic has its own exclusion there. Source references are sourceBookID plus pageNumber; runtime sourceID/hash binding remains for root.

### pilot56_book_a2_bear_v1 — Böğürtlen Tutuyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | determination |
| 6 | none | pride |
| 7 | none | satisfaction |
| 8 | none | joy |

### pilot56_book_a3_bear_v1 — Böğürtlen'in Çantası

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | certainty |
| 6 | none | relief |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_a2_bear_event02_v1 — Böğürtlen'in Kocaman Patisi

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | determination |
| 6 | none | pride |
| 7 | none | satisfaction |
| 8 | none | joy |

### pilot56_book_a2_bear_event03_v1 — Böğürtlen Şarkı Söylüyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | determination |
| 6 | none | pride |
| 7 | none | satisfaction |
| 8 | none | joy |

### pilot56_book_a3_bear_event02_v1 — Böğürtlen'in Mor Bıyığı

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | weather | curiosity |
| 3 | none | delight |
| 4 | none | determination |
| 5 | weather | certainty |
| 6 | weather | relief |
| 7 | none | satisfaction |
| 8 | weather | warmth |

### pilot56_book_a3_bear_event03_v1 — Böğürtlen Sığamıyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | certainty |
| 6 | none | relief |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_a1_cat_v1 — Simit Ormanda

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | weather | curiosity |
| 2 | weather | determination |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | delight |
| 6 | none | determination |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_a3_cat_v1 — Simit'in Zili

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | certainty |
| 6 | none | relief |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_a1_cat_event02_v1 — Simit Güneşte

Title topics: weather. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | weather | determination |
| 3 | weather | delight |
| 4 | weather | determination |
| 5 | weather | ease |
| 6 | none | determination |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_a1_cat_event03_v1 — Simit Yaya Geçidinde

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | determination |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | ease |
| 6 | none | determination |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_a3_cat_event02_v1 — Simit ve Sıcak Kök

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | weather | curiosity |
| 3 | none | delight |
| 4 | none | determination |
| 5 | weather | certainty |
| 6 | weather | relief |
| 7 | weather | satisfaction |
| 8 | weather | warmth |

### pilot56_book_a3_cat_event03_v1 — Simit'in Başı Dönüyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | certainty |
| 6 | none | relief |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_a1_fox_v1 — Tarçın'ın Burnu Önde

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | weather | curiosity |
| 2 | weather | determination |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | ease |
| 6 | none | determination |
| 7 | none | satisfaction |
| 8 | weather | warmth |

### pilot56_book_a2_fox_v1 — Tarçın ve Yol İşareti

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | determination |
| 6 | none | pride |
| 7 | none | satisfaction |
| 8 | none | joy |

### pilot56_book_a1_fox_event02_v1 — Tarçın'ın Güneşli Molası

Title topics: weather. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | weather | determination |
| 3 | weather | delight |
| 4 | weather | determination |
| 5 | none | ease |
| 6 | weather | determination |
| 7 | none | satisfaction |
| 8 | weather | warmth |

### pilot56_book_a1_fox_event03_v1 — Tarçın İki Kokulu Toprakta

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | determination |
| 3 | weather | delight |
| 4 | none | determination |
| 5 | none | ease |
| 6 | none | determination |
| 7 | none | satisfaction |
| 8 | weather | warmth |

### pilot56_book_a2_fox_event02_v1 — Tarçın'ın Başı Dönüyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | determination |
| 6 | none | pride |
| 7 | none | satisfaction |
| 8 | none | joy |

### pilot56_book_a2_fox_event03_v1 — Kısa Çizgi, Uzun Çizgi

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | determination |
| 6 | none | pride |
| 7 | none | satisfaction |
| 8 | none | joy |

### pilot56_book_a1_hedgehog_v1 — Kestane'nin Papatyası

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | weather | curiosity |
| 2 | weather | determination |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | delight |
| 6 | none | determination |
| 7 | none | satisfaction |
| 8 | weather | warmth |

### pilot56_book_a3_hedgehog_v1 — Kestane ve Kayıp Mendil

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | certainty |
| 6 | none | relief |
| 7 | none | satisfaction |
| 8 | weather | warmth |

### pilot56_book_a1_hedgehog_event02_v1 — Kestane'nin Güneş Tüyü

Title topics: weather. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | weather | determination |
| 3 | weather | delight |
| 4 | weather | determination |
| 5 | none | ease |
| 6 | weather | determination |
| 7 | none | satisfaction |
| 8 | weather | warmth |

### pilot56_book_a1_hedgehog_event03_v1 — Kestane İki Renkli

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | determination |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | ease |
| 6 | none | determination |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_a3_hedgehog_event02_v1 — Güneşli Kökteki Mendil

Title topics: weather. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | weather | curiosity |
| 3 | none | delight |
| 4 | none | determination |
| 5 | weather | certainty |
| 6 | weather | relief |
| 7 | weather | satisfaction |
| 8 | weather | warmth |

### pilot56_book_a3_hedgehog_event03_v1 — Kestane'nin Yoncası

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | certainty |
| 6 | none | relief |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_a2_owl_v1 — Yıldız Esniyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | determination |
| 6 | none | pride |
| 7 | weather | satisfaction |
| 8 | none | joy |

### pilot56_book_a3_owl_v1 — Yıldız Soruyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | none | curiosity |
| 3 | none | curiosity |
| 4 | none | determination |
| 5 | none | certainty |
| 6 | none | relief |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_a2_owl_event02_v1 — Ters Okun Sırrı

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | determination |
| 6 | none | pride |
| 7 | none | satisfaction |
| 8 | none | joy |

### pilot56_book_a2_owl_event03_v1 — Yıldız Çizgileri Sayıyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | determination |
| 6 | none | pride |
| 7 | weather | satisfaction |
| 8 | none | joy |

### pilot56_book_a3_owl_event02_v1 — Yıldız ve Güneşli Kök

Title topics: weather. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | weather | curiosity |
| 3 | weather | delight |
| 4 | none | determination |
| 5 | weather | certainty |
| 6 | weather | relief |
| 7 | weather | satisfaction |
| 8 | none | warmth |

### pilot56_book_a3_owl_event03_v1 — Önce Bak, Sonra Dön

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | concern |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | certainty |
| 6 | none | relief |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_u1_bear_v1 — Böğürtlen'in Ninnisi

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | calm |
| 3 | none | warmth |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | darkness | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u1_bear_event02_v1 — Böğürtlen'in Kocaman Patileri

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | calm |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u1_bear_event03_v1 — Böğürtlen'in Küçük Örtüsü

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | calm |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u2_bear_v1 — Böğürtlen'e Kocaman Bir Yer

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | tenderness |
| 5 | none | ease |
| 6 | none | satisfaction |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u2_bear_event02_v1 — Böğürtlen Düz Yer Sever

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | tenderness |
| 5 | none | ease |
| 6 | none | satisfaction |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u2_bear_event03_v1 — Böğürtlen'in Geniş Yolu

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | tenderness |
| 5 | none | ease |
| 6 | none | satisfaction |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u2_cat_v1 — Simit'in Orman Yastığı

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | tenderness |
| 5 | none | ease |
| 6 | none | satisfaction |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u2_cat_event02_v1 — Simit Katlı Kenara Zıpladı

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | tenderness |
| 5 | none | ease |
| 6 | none | satisfaction |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u2_cat_event03_v1 — Simit'in Kuyruğuna Yer

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | tenderness |
| 5 | none | ease |
| 6 | none | satisfaction |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_cat_v1 — Simit'in Kalabalık Gölgesi

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_cat_event02_v1 — Simit Durmayı Deniyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_cat_event03_v1 — Simit Olsa Zıplardı

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u1_fox_v1 — Tarçın Sesleri Kokluyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | calm |
| 3 | none | warmth |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | darkness | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u1_fox_event02_v1 — Tarçın'ın Kuyruk Sesi

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | calm |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u1_fox_event03_v1 — Tarçın Örtüyü Kokluyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | calm |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_fox_v1 — Gölgenin Kokusu Var mı?

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_fox_event02_v1 — Tarçın da Durmuştu

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_fox_event03_v1 — Avuçta Kalan Koku

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | darkness | calm |
| 8 | none | calm |

### pilot56_book_u2_hedgehog_v1 — Kestane'nin Düz Yuvası

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | tenderness |
| 5 | none | ease |
| 6 | none | satisfaction |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u2_hedgehog_event02_v1 — Kestane Kenardan Yuvarlandı

Title topics: heights. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | heights | delight |
| 4 | none | tenderness |
| 5 | none | ease |
| 6 | none | satisfaction |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u2_hedgehog_event03_v1 — Gıdıklanan Minder

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | tenderness |
| 5 | none | ease |
| 6 | none | satisfaction |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_hedgehog_v1 — Kestane Günü Dikenlerinde Taşır

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_hedgehog_event02_v1 — Kestane Durunca Top Olur

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_hedgehog_event03_v1 — Kestane de Bir Yaprak Bırakıyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u1_owl_v1 — Yıldız'ın Gece Kulakları

Title topics: darkness. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | calm |
| 3 | none | warmth |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | darkness | calm |
| 7 | darkness | calm |
| 8 | none | calm |

### pilot56_book_u1_owl_event02_v1 — Yıldız'ın Sessiz Kanatları

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | darkness | ease |
| 2 | none | calm |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u1_owl_event03_v1 — Yıldız Hışırtı Sayıyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | calm |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_owl_v1 — Yıldız'ın Günaydını

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_owl_event02_v1 — Yıldız Durmayı Bilir

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_u3_owl_event03_v1 — Yıldız Gibi Süzülen Yaprak

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | darkness | ease |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | calm |
| 5 | none | warmth |
| 6 | none | calm |
| 7 | none | calm |
| 8 | none | calm |

### pilot56_book_l3_bear_v1 — Böğürtlen Böğürtlenle Sayıyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | satisfaction |

### pilot56_book_l3_bear_event02_v1 — Böğürtlen Kadar Damla

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | delight |
| 8 | none | satisfaction |

### pilot56_book_l3_bear_event03_v1 — Kay Kay Damlacık

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | curiosity |
| 3 | weather | delight |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | delight |
| 8 | none | satisfaction |

### pilot56_book_l2_bear_v1 — Böğürtlen Eğiliyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_l2_bear_event02_v1 — Böğürtlen Düşünürken

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_l2_bear_event03_v1 — Böğürtlen'in Yaprak Çantası

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_l1_cat_v1 — Ormanın Kapısını Kim Çalıyor?

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | weather | satisfaction |
| 8 | none | delight |

### pilot56_book_l1_cat_event02_v1 — Simit'in Patisi Havada

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | delight |

### pilot56_book_l1_cat_event03_v1 — Tık mı, Tın mı?

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | weather | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | weather | satisfaction |
| 8 | none | delight |

### pilot56_book_l3_cat_v1 — Ağacın Musluğu

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | delight |
| 8 | none | satisfaction |

### pilot56_book_l3_cat_event02_v1 — Yarışmayan Damlalar

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | curiosity |
| 3 | none | patience |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | delight |
| 8 | none | satisfaction |

### pilot56_book_l3_cat_event03_v1 — Simit ve Yaprak Damarı

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | curiosity |
| 3 | none | patience |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | delight |
| 8 | none | satisfaction |

### pilot56_book_l1_fox_v1 — Tarçın'ın Kulakları

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | weather | satisfaction |
| 8 | none | delight |

### pilot56_book_l1_fox_event02_v1 — Tarçın Hapşırıyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | delight |

### pilot56_book_l1_fox_event03_v1 — Hangi Yaprak, Tarçın?

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | weather | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | weather | satisfaction |
| 8 | none | delight |

### pilot56_book_l3_fox_v1 — Tarçın Damlayı Bekliyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | weather | curiosity |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | delight |
| 8 | none | satisfaction |

### pilot56_book_l3_fox_event02_v1 — Sarılan Damlalar

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | delight |
| 8 | none | satisfaction |

### pilot56_book_l3_fox_event03_v1 — Yürüyen Damla

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | delight |
| 8 | none | satisfaction |

### pilot56_book_l3_hedgehog_v1 — Kestane'nin Damlası

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | delight |
| 8 | weather | satisfaction |

### pilot56_book_l3_hedgehog_event02_v1 — Kestane'nin Küçük Damlası

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | delight |
| 8 | none | satisfaction |

### pilot56_book_l3_hedgehog_event03_v1 — Kestane Damlaya Cesaret Veriyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | curiosity |
| 3 | none | delight |
| 4 | none | patience |
| 5 | none | wonder |
| 6 | none | insight |
| 7 | none | delight |
| 8 | none | satisfaction |

### pilot56_book_l2_hedgehog_v1 — Kestane'nin Alçak Bakışı

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_l2_hedgehog_event02_v1 — Kestane'nin Koleksiyonu

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_l2_hedgehog_event03_v1 — Kestane Gibi Kıvrılmış

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_l1_owl_v1 — Yıldız Dinliyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | curiosity |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | weather | satisfaction |
| 8 | none | delight |

### pilot56_book_l1_owl_event02_v1 — Yıldız'ın Başı Sallanıyor

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | delight |

### pilot56_book_l1_owl_event03_v1 — Dedektif Yıldız

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | weather | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | weather | satisfaction |
| 8 | none | delight |

### pilot56_book_l2_owl_v1 — Yıldız Öbür Yandan

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_l2_owl_event02_v1 — Saklambaç Oynayan Yaprak

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | warmth |

### pilot56_book_l2_owl_event03_v1 — Uyuyan Yaprak

Title topics: none. Status: reviewed.

| Page | Topics | EmotionalState |
|---|---|---|
| 1 | none | curiosity |
| 2 | none | puzzlement |
| 3 | none | delight |
| 4 | none | determination |
| 5 | none | curiosity |
| 6 | none | insight |
| 7 | none | satisfaction |
| 8 | none | warmth |

## Verification / open questions

Structural transcription checks verified 90 unique books, 90 exact titles, 720 exact full-page quotes, complete canonical-topic disposition, topic-linked evidence and current source-file digests. No tests, build or commit run, as instructed. Open questions: same-page bag provenance strictness; editorial handling of remaining minor continuity items; art talon depiction; runtime binding. No application/privacy/logging systems changed.

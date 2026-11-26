# V4 pilot üretim kuyruğu

27 Kasım 2026. 15 pilot kitap / 120 sayfa elle okunup kaynak izli planlama notlarıyla işlendi. 45 önerilen görsel an, 35 farklı çizim ihtiyacı var; mevcut beş nötr kimlik çizimi bu aksiyon çizimlerinin yerine sayılmadı. 75 sayfa ilk pilotta metin olarak bırakıldı. Henüz yayınlanmış eşleşme veya görsel kapsama garantisi yok.

## Öncelik 1 — ortak nesne ve mekân durumları

| Çizim ihtiyacı | Pilot sayfa adedi |
|---|---:|
| `clearing_shadow_threshold` | 3 |
| `leaf_branch_contact` | 3 |
| `leaf_branch_gap` | 3 |
| `marker_parts_completed_arrow` | 2 |
| `marker_parts_separate_reversed` | 2 |
| `occluded_leaf_overview` | 2 |
| `occluded_leaf_vein_gap` | 2 |

İlk üretim: yaprak–dal boşluğu ve temas anı. Bu iki görselde yaprak bağlı kalmalı; aralık/temas dışında biçim farkı öğretici karşılaştırmayı bozmamalı. Tek başına bir genel yaprak bu iki ihtiyacı karşılamaz.

Örtülü yeşil yaprakta iki kuru örtücü kaldırılmaz; damar aralığı aynı tek yaprağı kanıtlamalı. Ahşap parçalar ilk karede ters ve ayrı, tamamlanmış karede aynı yönlü olmalı. Açıklık sahnesine taş, seçilmesinden önce eklenmez.

## Öncelik 2 — karakter aksiyonları

| Çizim ihtiyacı | Pilot sayfa adedi |
|---|---:|
| `bear_paw_edge_line_piece` | 1 |
| `bear_paws_on_belly_no_bag` | 1 |
| `bear_rubbing_paws_no_bag` | 1 |
| `bear_seated_mattress_bag_on_hook` | 1 |
| `bear_walk_purple_mouth` | 1 |
| `cat_approach_blanket_bell_visible` | 1 |
| `cat_curled_bell_under_paw` | 1 |
| `cat_curled_round_stone_awake` | 1 |
| `cat_grooming_in_shade` | 1 |
| `cat_pause_paw_raised` | 1 |
| `cat_sit_flat_blanket_bell_visible` | 1 |
| `fox_nose_between_paws_resting` | 1 |
| `fox_resting_awake_cushion` | 1 |
| `fox_sit_curled_tail_round_stone` | 1 |
| `fox_sniff_flower` | 1 |
| `fox_sniff_round_stone` | 1 |
| `fox_tail_sweep_cushion` | 1 |
| `hedgehog_blanket_edge_feather` | 1 |
| `hedgehog_curled_leaf_feather_beside` | 1 |
| `hedgehog_flat_blanket_feather_beside` | 1 |
| `hedgehog_return_feather_on_spines` | 1 |
| `hedgehog_stone_feather_on_spines` | 1 |
| `hedgehog_walk_yellow_leaf` | 1 |
| `owl_low_glide` | 1 |
| `owl_perched_awake` | 1 |
| `owl_perched_wings_folded_resting` | 1 |
| `owl_stabilize_line_piece` | 1 |
| `owl_wings_rubbing_silent` | 1 |

## Yayın öncesi gerekli kontroller

- Her aday sayfa için tam kaynak ve template SHA eşleşmesi; yeni dosya revizyonu ve görsel inceleme kaydı.
- Tarçın kapanışında boyunluk minder üzerindeyken boynunda çizilmez. Bu pilotta p8 bu nedenle seçilmedi.
- Böğürtlen uyku pozlarında çanta gövdede değil askıda; öğle/macera pozlarında ayrı konum incelemesi gerekir.
- Simit’in susturduğu çan patisinin altında; kıvrılmış ama çanı açık genel poz bu sayfaya bağlanmaz.
- Kestane’nin hardal yaprağı kimlik ayrıntısı, sahnedeki yeni tüy veya başka yaprağın yerine geçmez.
- İlk 15 seçim event02 varyantlarına ve sınırlı yapılara denk geldi. Bu nedenle damla, U3 anı, L3 bekleme ve A3 dönüş gibi kalan V4 olayları için bu 35 sayı toplam bütçe değildir.
- Üç anlık öneri her kitapta farklı sayfalardadır; özellikle yanlış kapanış çizmek yerine p7 seçilebilir. Tüm yaş gruplarına genellenmez.
- Beyaz/gece kompoziti, küçük boyutta okunabilirlik ve üretim görsellerinin özdeş nesne geometrisi incelenmeden runtime onayı verilmez.

## Doğrulama

`python3 Tools/story-art/build_v4_pilot_review.py` 120/120 metin SHA, 15 kitap, kitap başına 3 aday ve toplam 45 an kontrolünü yapar. Bu veri doğrulamasıdır; uygulama testi veya sanatın doğruluğuna otomatik onay değildir.

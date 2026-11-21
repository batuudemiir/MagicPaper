# Havuz raporu (H5)

19 Kasım 2026. `docs/HAVUZ_PLANI.md` H5'in ölçümü: bir masal sayfası yazılırken seçicinin elinde gerçekten kaç satır kalıyor. Derleme yapılmadan, Python yaklaşığıyla ölçüldü; motorun içindeki ölçüm (`CoverageReport`'a satır sayısı) derleme açılınca eklenecek.

## Yöntem

Betik `OfflineStoryComposer`'ın üç parçasını taklit eder: `plan` (sayfa planı düzleştirilir; her adım için önceki beat, kapanış beat'i, birikmiş anlatı durumu ve istenen uzunluk sınıfı), `templates` (beat, bant örtüşmesi, ark birebir; seri bölümünde önce seri katmanı, boşsa tek seferlik satırlar) ve `pool` (aşağıdaki kapılar, motordaki sırayla).

Ulaşılabilirlik: tek seferlik bir blueprint en az bir modun kabul ettiği aile ve arkta ise (`StoryModeProfile.admits`), devam blueprint'i `continuation.modes`'unda bir mod varsa sayıldı. Her blueprint için bağlayıcının kabul edeceği her (mekân, yol arkadaşı, keşif) üçlüsü dolaşıldı (habitat, `requires`/`forbids`, `casting`, `nature`, `thresholdKind`, `explainedBy`); yol arkadaşının alabileceği her rol ayrı bağlam sayıldı.

Kapılar, motordaki adıyla:

| Kapı | Motorda | Ölçümde |
|---|---|---|
| Güvenlik konuları (0f) | esnemez | iki senaryo: en korumacı ayar (gergin sayfalı ve konulu blueprint düşer, konulu satır ve içerik düşer) ve filtresiz |
| Rol (`castRoles`, 0) | esnemez | bağlamın rolü |
| Doğa (`natureRequire`, 0g) | esnemez | yol arkadaşının doğası |
| Meslek (`occupationRequire`, 0h) | esnemez | yol arkadaşının mesleği |
| Masal ailem (`familyRelations`, 0a) | esnemez | aile anında (tek seferlik: `establish_ordinary`, `notice_anomaly`, `warm_close`; seri: `revisit`, `warm_close`) dört ilişkinin her biri ayrı; aile anı dışında aile satırı yok |
| Çatışma biçimi (`conflictKinds`, 0b) | esnemez | blueprint ailesinin çatışması |
| Anlatı durumu (`afterState`, 0c) | esnemez | plandan birikmiş durum |
| Kapanış (`afterClosing`, 0d) | esnemez | plandaki son `succeed`/`restore` |
| Sakin son (0e) | esnemez | seri bölümünün ve uyku masalının son sayfasında "?", "sonra ne olacak", "yarın…", "acaba…", "birden…" yok |
| İçerik uyumu (1) | esner | ayrı sütun: "içerik uyumuyla en kötü" |
| Uzunluk sınıfı (2) | esner | uygulandı (eşleşen yoksa bütün satırlar) |
| Ses tonu (`register`, 2b) | esner | uygulandı |
| Önceki beat (`afterBeat`, 3) | esnemez | plandaki bir önceki beat |

Bir **havuz**, bir şablon dosyasında bu kapılardan geçen satır kümesidir; aynı kümeye düşen bağlamlar tek havuz sayıldı. Bu korpusta her (beat, bant, ark, katman) için tek dosya var, yani seçici önce dosyayı, sonra o dosyanın havuzundan satırı seçiyor.

### Varsayımlar ve zayıf yerler

- **İçerik uyumu esniyor ve ana sayıya girmedi.** `settingTraits`, `discoveryTraits` ve yetenek kapıları, eşleşen satır varsa havuzu daraltır, yoksa düşer. Ana sütun bunu saymaz; "içerik uyumuyla en kötü" sütunu, bağlayıcının kabul ettiği bütün bağlamaların en kötüsüdür. Bağlayıcı yaklaşıktır (`e5/coverage.py` mantığı, rol ve meslek eklendi): çocuğun seçtiği konu, ilgi alanı ağırlığı ve aile adı çakışması süzgeci yok.
- **Seri bölümünde kullanılmış satırdan kaçınma ölçülmedi.** `EpisodeContext.avoiding` seri boyunca kullanılan satırı, taze satır varsa havuzdan çıkarır; beş bölümlük bir seride gerçek havuz bölümden bölüme küçülür. D2 soğuması ise yalnızca sıralar, çıkarmaz.
- **Sakin son metin üzerinden, yuva değerleri olmadan** sınandı; motor ayrıca işlenmiş sayfayı da sınıyor.
- **Ölçülmeyenler:** özel gün blueprint'leri ve kendi satırları (E6), hatırlama satırları (E3), `offline/` altındaki eski v1 şablonları.
- Bant çözümleme (`AgeBandResolver.servedBand`) atlandı; dört bantta da blueprint var.
- Satır sayılır, `move` sayılmaz: aynı hamleyi yapan iki satır iki satır sayıldı.

## Sonuç

- 556 havuz. Önce **141 havuz 3 satırın altındaydı** (12'si tek satır, 129'u iki satır); 124'ü Masal ailem havuzu (ilişki başına iki satır yazılmış aile anları), 17'si `afterBeat` ya da rol kapılı havuz.
- **Sonra 3'ün altında havuz yok; eski 141'in hepsi en az 4.** 102 üç satırlık havuza dokunulmadı (kural "3'ün altı").
- 294 satır eklendi: 222'si tek seferlik katmana (`recordCounts["variants"]` 1869 → 2091), 72'si seri katmanına. 260'ı Masal ailem satırı (tek seferlik katmanda 196), 34'ü aile anı olmayan havuzlara.
- İçerik uyumuyla en kötü durumda 3'ün altında kalan havuz: önce 152, sonra 11. Kalan 11'i, uyku ve seri bölümlerinin `notice_anomaly`, `approach`, `tend` beat'lerinde; bir keşfe ya da mekâna özgü satırlar havuzu daraltıyor (aşağıda). Kural esnek kapıya uygulanmadığı için dokunulmadı.

### Bant × katman × beat

"Havuz": o hücrede ayrı satır kümesi sayısı. "En küçük (önce)" kalın olanlar 3'ün altındaydı. "İçerik uyumuyla en kötü" H5 sonrası.

| Bant | Katman | Beat | Havuz | En küçük (önce) | Ortanca | En küçük (sonra) | İçerik uyumuyla en kötü (sonra) |
|---|---|---|---|---|---|---|---|
| 3-4 | seri | `commit` | 2 | 4 | 5 | 4 | 4 |
| 3-4 | seri | `first_attempt` | 2 | 4 | 5 | 4 | 4 |
| 3-4 | seri | `let_go` | 1 | 6 | 6 | 6 | 6 |
| 3-4 | seri | `notice_anomaly` | 2 | 4 | 5,5 | 4 | 2 |
| 3-4 | seri | `patient_wait` | 1 | 6 | 6 | 6 | 6 |
| 3-4 | seri | `receive_appeal` | 1 | 6 | 6 | 6 | 6 |
| 3-4 | seri | `restore` | 2 | 5 | 5,5 | 5 | 5 |
| 3-4 | seri | `revisit` | 6 | 4 | 4 | 4 | 4 |
| 3-4 | seri | `take_charge` | 2 | 5 | 5,5 | 5 | 5 |
| 3-4 | seri | `tend` | 1 | 6 | 6 | 6 | 6 |
| 3-4 | seri | `warm_close` | 6 | 4 | 4 | 4 | 4 |
| 3-4 | seri uyku | `commit` | 1 | 6 | 6 | 6 | 6 |
| 3-4 | seri uyku | `first_attempt` | 1 | 6 | 6 | 6 | 6 |
| 3-4 | seri uyku | `let_go` | 1 | 6 | 6 | 6 | 6 |
| 3-4 | seri uyku | `notice_anomaly` | 1 | 6 | 6 | 6 | 1 |
| 3-4 | seri uyku | `patient_wait` | 1 | 6 | 6 | 6 | 6 |
| 3-4 | seri uyku | `receive_appeal` | 1 | 6 | 6 | 6 | 6 |
| 3-4 | seri uyku | `restore` | 1 | 6 | 6 | 6 | 6 |
| 3-4 | seri uyku | `revisit` | 5 | 3 | 3 | 3 | 3 |
| 3-4 | seri uyku | `take_charge` | 1 | 6 | 6 | 6 | 5 |
| 3-4 | seri uyku | `tend` | 1 | 6 | 6 | 6 | 2 |
| 3-4 | seri uyku | `warm_close` | 5 | 3 | 3 | 3 | 3 |
| 3-4 | tek | `ask_for_help` | 1 | 4 | 4 | 4 | 4 |
| 3-4 | tek | `belief_fails` | 1 | 5 | 5 | 5 | 5 |
| 3-4 | tek | `commit` | 3 | 4 | 6 | 4 | 4 |
| 3-4 | tek | `cooperative_effort` | 2 | 4 | 5,5 | 4 | 4 |
| 3-4 | tek | `first_attempt` | 2 | 3 | 3,5 | 3 | 3 |
| 3-4 | tek | `form_belief` | 3 | 3 | 4 | 3 | 3 |
| 3-4 | tek | `insight` | 1 | 5 | 5 | 5 | 5 |
| 3-4 | tek | `let_go` | 1 | 8 | 8 | 8 | 8 |
| 3-4 | tek | `meet_companion` | 7 | **2** | 3 | 3 | 3 |
| 3-4 | tek | `notice_anomaly` | 6 | **2** | 2 | 3 | 3 |
| 3-4 | tek | `obstacle_raises` | 1 | 4 | 4 | 4 | 4 |
| 3-4 | tek | `patient_wait` | 2 | 3 | 5,5 | 3 | 3 |
| 3-4 | tek | `persist` | 1 | 4 | 4 | 4 | 4 |
| 3-4 | tek | `receive_appeal` | 3 | 3 | 7 | 3 | 3 |
| 3-4 | tek | `restore` | 3 | 4 | 4 | 4 | 4 |
| 3-4 | tek | `retrace` | 1 | 4 | 4 | 4 | 4 |
| 3-4 | tek | `reveal_truth` | 1 | 5 | 5 | 5 | 5 |
| 3-4 | tek | `succeed` | 7 | **2** | 2 | 3 | 3 |
| 3-4 | tek | `tend` | 1 | 8 | 8 | 8 | 8 |
| 3-4 | tek | `warm_close` | 6 | **2** | 2 | 4 | 4 |
| 3-4 | tek uyku | `companion_offers` | 1 | 4 | 4 | 4 | 4 |
| 3-4 | tek uyku | `establish_ordinary` | 5 | **2** | 2 | 4 | 4 |
| 3-4 | tek uyku | `examine` | 1 | 4 | 4 | 4 | 4 |
| 3-4 | tek uyku | `let_go` | 1 | 4 | 4 | 4 | 4 |
| 3-4 | tek uyku | `meet_companion` | 1 | 4 | 4 | 4 | 4 |
| 3-4 | tek uyku | `notice_anomaly` | 5 | **2** | 2 | 4 | 4 |
| 3-4 | tek uyku | `patient_wait` | 1 | 4 | 4 | 4 | 4 |
| 3-4 | tek uyku | `restore` | 1 | 4 | 4 | 4 | 4 |
| 3-4 | tek uyku | `take_charge` | 1 | 4 | 4 | 4 | 4 |
| 3-4 | tek uyku | `tend` | 3 | 3 | 3 | 3 | 3 |
| 3-4 | tek uyku | `warm_close` | 5 | **2** | 2 | 4 | 4 |
| 5-6 | seri | `approach` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | seri | `commit` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | seri | `examine` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | seri | `first_attempt` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | seri | `let_go` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | seri | `notice_anomaly` | 1 | 6 | 6 | 6 | 3 |
| 5-6 | seri | `patient_wait` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | seri | `receive_appeal` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | seri | `restore` | 2 | 4 | 4 | 4 | 4 |
| 5-6 | seri | `revisit` | 5 | 4 | 4 | 4 | 4 |
| 5-6 | seri | `take_charge` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | seri | `tend` | 1 | 4 | 4 | 4 | 3 |
| 5-6 | seri | `warm_close` | 5 | 4 | 4 | 4 | 4 |
| 5-6 | seri uyku | `approach` | 1 | 7 | 7 | 7 | 1 |
| 5-6 | seri uyku | `commit` | 1 | 7 | 7 | 7 | 7 |
| 5-6 | seri uyku | `examine` | 1 | 7 | 7 | 7 | 7 |
| 5-6 | seri uyku | `first_attempt` | 1 | 7 | 7 | 7 | 7 |
| 5-6 | seri uyku | `let_go` | 1 | 7 | 7 | 7 | 7 |
| 5-6 | seri uyku | `notice_anomaly` | 1 | 6 | 6 | 6 | 1 |
| 5-6 | seri uyku | `patient_wait` | 1 | 7 | 7 | 7 | 7 |
| 5-6 | seri uyku | `receive_appeal` | 1 | 7 | 7 | 7 | 7 |
| 5-6 | seri uyku | `restore` | 2 | 6 | 6,5 | 6 | 6 |
| 5-6 | seri uyku | `revisit` | 5 | 3 | 3 | 3 | 3 |
| 5-6 | seri uyku | `take_charge` | 1 | 7 | 7 | 7 | 7 |
| 5-6 | seri uyku | `tend` | 1 | 7 | 7 | 7 | 2 |
| 5-6 | seri uyku | `warm_close` | 5 | 3 | 3 | 3 | 3 |
| 5-6 | tek | `approach` | 2 | 6 | 6 | 6 | 6 |
| 5-6 | tek | `ask_for_help` | 6 | 4 | 4 | 4 | 4 |
| 5-6 | tek | `belief_fails` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `carry_forward` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `commit` | 3 | 4 | 9 | 4 | 4 |
| 5-6 | tek | `companion_offers` | 1 | 12 | 12 | 12 | 11 |
| 5-6 | tek | `cooperative_effort` | 2 | 3 | 7,5 | 3 | 3 |
| 5-6 | tek | `examine` | 2 | 5 | 8,5 | 5 | 4 |
| 5-6 | tek | `exchange_views` | 5 | 4 | 4 | 4 | 4 |
| 5-6 | tek | `find_own_courage` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `first_attempt` | 2 | 4 | 7 | 4 | 4 |
| 5-6 | tek | `form_belief` | 2 | 6 | 6 | 6 | 6 |
| 5-6 | tek | `give_up_something` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `hesitate` | 1 | 6 | 6 | 6 | 6 |
| 5-6 | tek | `insight` | 2 | 3 | 7,5 | 3 | 3 |
| 5-6 | tek | `let_go` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `meet_companion` | 14 | 3 | 4 | 3 | 3 |
| 5-6 | tek | `notice_anomaly` | 6 | **2** | 2 | 4 | 4 |
| 5-6 | tek | `obstacle_raises` | 4 | 4 | 6,5 | 4 | 4 |
| 5-6 | tek | `patient_wait` | 5 | 4 | 4 | 4 | 4 |
| 5-6 | tek | `persist` | 2 | 3 | 7,5 | 3 | 3 |
| 5-6 | tek | `prepare` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `receive_appeal` | 2 | 3 | 7,5 | 3 | 3 |
| 5-6 | tek | `restore` | 6 | 8 | 8 | 8 | 8 |
| 5-6 | tek | `retrace` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `reveal_truth` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `self_recognize` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `small_step` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `speak_for` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `succeed` | 9 | 3 | 8 | 3 | 3 |
| 5-6 | tek | `take_charge` | 2 | 6 | 6 | 6 | 6 |
| 5-6 | tek | `tend` | 1 | 12 | 12 | 12 | 12 |
| 5-6 | tek | `warm_close` | 11 | **1** | 2 | 4 | 4 |
| 5-6 | tek uyku | `approach` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | tek uyku | `establish_ordinary` | 5 | **2** | 2 | 4 | 4 |
| 5-6 | tek uyku | `examine` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | tek uyku | `let_go` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | tek uyku | `meet_companion` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | tek uyku | `notice_anomaly` | 5 | **2** | 2 | 4 | 4 |
| 5-6 | tek uyku | `patient_wait` | 2 | 4 | 4 | 4 | 4 |
| 5-6 | tek uyku | `restore` | 2 | 4 | 4 | 4 | 4 |
| 5-6 | tek uyku | `take_charge` | 1 | 4 | 4 | 4 | 4 |
| 5-6 | tek uyku | `tend` | 2 | 3 | 3,5 | 3 | 3 |
| 5-6 | tek uyku | `warm_close` | 5 | **2** | 2 | 4 | 4 |
| 7-8 | seri | `commit` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | seri | `first_attempt` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | seri | `let_go` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | seri | `notice_anomaly` | 1 | 3 | 3 | 3 | 2 |
| 7-8 | seri | `patient_wait` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | seri | `receive_appeal` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | seri | `restore` | 2 | **2** | 2 | 4 | 4 |
| 7-8 | seri | `revisit` | 5 | **2** | 2 | 3 | 3 |
| 7-8 | seri | `take_charge` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | seri | `tend` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | seri | `warm_close` | 5 | **2** | 2 | 3 | 3 |
| 7-8 | seri uyku | `approach` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | seri uyku | `commit` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | seri uyku | `first_attempt` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | seri uyku | `notice_anomaly` | 1 | 3 | 3 | 3 | 1 |
| 7-8 | seri uyku | `receive_appeal` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | seri uyku | `revisit` | 5 | **2** | 2 | 3 | 3 |
| 7-8 | seri uyku | `warm_close` | 5 | **2** | 2 | 3 | 3 |
| 7-8 | tek | `ask_for_help` | 4 | 4 | 4 | 4 | 4 |
| 7-8 | tek | `belief_fails` | 1 | 12 | 12 | 12 | 12 |
| 7-8 | tek | `carry_forward` | 1 | 12 | 12 | 12 | 12 |
| 7-8 | tek | `commit` | 1 | 12 | 12 | 12 | 12 |
| 7-8 | tek | `companion_offers` | 2 | 12 | 13,5 | 12 | 11 |
| 7-8 | tek | `cooperative_effort` | 4 | 3 | 5,5 | 3 | 3 |
| 7-8 | tek | `examine` | 2 | 6 | 7 | 6 | 5 |
| 7-8 | tek | `first_attempt` | 2 | 6 | 6 | 6 | 6 |
| 7-8 | tek | `form_belief` | 2 | 6 | 6 | 6 | 6 |
| 7-8 | tek | `insight` | 2 | 3 | 7,5 | 3 | 3 |
| 7-8 | tek | `meet_companion` | 6 | 3 | 4 | 3 | 3 |
| 7-8 | tek | `notice_anomaly` | 5 | **2** | 2 | 4 | 4 |
| 7-8 | tek | `obstacle_raises` | 1 | 12 | 12 | 12 | 12 |
| 7-8 | tek | `patient_wait` | 2 | 3 | 3,5 | 3 | 3 |
| 7-8 | tek | `persist` | 2 | 3 | 7,5 | 3 | 3 |
| 7-8 | tek | `receive_appeal` | 3 | 3 | 12 | 3 | 3 |
| 7-8 | tek | `restore` | 4 | 3 | 4 | 3 | 3 |
| 7-8 | tek | `retrace` | 1 | 12 | 12 | 12 | 12 |
| 7-8 | tek | `reveal_truth` | 1 | 12 | 12 | 12 | 12 |
| 7-8 | tek | `self_recognize` | 1 | 12 | 12 | 12 | 12 |
| 7-8 | tek | `succeed` | 7 | **2** | 3 | 3 | 3 |
| 7-8 | tek | `take_charge` | 1 | 4 | 4 | 4 | 4 |
| 7-8 | tek | `tend` | 1 | 4 | 4 | 4 | 4 |
| 7-8 | tek | `warm_close` | 12 | **1** | 2 | 3 | 3 |
| 7-8 | tek uyku | `companion_offers` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | tek uyku | `establish_ordinary` | 5 | **2** | 2 | 4 | 4 |
| 7-8 | tek uyku | `examine` | 1 | 3 | 3 | 3 | 3 |
| 7-8 | tek uyku | `let_go` | 1 | 4 | 4 | 4 | 4 |
| 7-8 | tek uyku | `meet_companion` | 1 | 4 | 4 | 4 | 4 |
| 7-8 | tek uyku | `notice_anomaly` | 5 | **2** | 2 | 4 | 4 |
| 7-8 | tek uyku | `patient_wait` | 2 | 3 | 3,5 | 3 | 3 |
| 7-8 | tek uyku | `restore` | 1 | 4 | 4 | 4 | 4 |
| 7-8 | tek uyku | `take_charge` | 1 | 4 | 4 | 4 | 4 |
| 7-8 | tek uyku | `tend` | 3 | **2** | 2 | 4 | 4 |
| 7-8 | tek uyku | `warm_close` | 5 | **2** | 2 | 4 | 4 |
| 9-10 | seri | `commit` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri | `companion_offers` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri | `first_attempt` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri | `let_go` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri | `notice_anomaly` | 1 | 3 | 3 | 3 | 2 |
| 9-10 | seri | `patient_wait` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri | `receive_appeal` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri | `restore` | 2 | **2** | 2 | 4 | 4 |
| 9-10 | seri | `revisit` | 5 | **2** | 2 | 3 | 3 |
| 9-10 | seri | `take_charge` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri | `tend` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri | `warm_close` | 5 | **2** | 2 | 3 | 3 |
| 9-10 | seri uyku | `approach` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri uyku | `commit` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri uyku | `first_attempt` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri uyku | `notice_anomaly` | 1 | 3 | 3 | 3 | 1 |
| 9-10 | seri uyku | `receive_appeal` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | seri uyku | `revisit` | 5 | **2** | 2 | 3 | 3 |
| 9-10 | seri uyku | `warm_close` | 5 | **2** | 2 | 3 | 3 |
| 9-10 | tek | `approach` | 1 | 7 | 7 | 7 | 7 |
| 9-10 | tek | `ask_for_help` | 4 | 4 | 4 | 4 | 4 |
| 9-10 | tek | `belief_fails` | 1 | 7 | 7 | 7 | 7 |
| 9-10 | tek | `carry_forward` | 1 | 7 | 7 | 7 | 7 |
| 9-10 | tek | `commit` | 2 | 4 | 5,5 | 4 | 4 |
| 9-10 | tek | `companion_offers` | 3 | 3 | 7 | 3 | 3 |
| 9-10 | tek | `cooperative_effort` | 4 | 3 | 5 | 3 | 3 |
| 9-10 | tek | `examine` | 2 | 4 | 5,5 | 4 | 4 |
| 9-10 | tek | `exchange_views` | 1 | 7 | 7 | 7 | 7 |
| 9-10 | tek | `first_attempt` | 1 | 7 | 7 | 7 | 6 |
| 9-10 | tek | `form_belief` | 2 | 4 | 5,5 | 4 | 4 |
| 9-10 | tek | `insight` | 2 | 3 | 5 | 3 | 3 |
| 9-10 | tek | `meet_companion` | 6 | 3 | 4 | 3 | 3 |
| 9-10 | tek | `notice_anomaly` | 5 | **2** | 2 | 4 | 4 |
| 9-10 | tek | `obstacle_raises` | 2 | 4 | 5,5 | 4 | 3 |
| 9-10 | tek | `patient_wait` | 2 | 3 | 3 | 3 | 3 |
| 9-10 | tek | `persist` | 2 | 3 | 5 | 3 | 3 |
| 9-10 | tek | `receive_appeal` | 3 | 3 | 7 | 3 | 3 |
| 9-10 | tek | `restore` | 4 | 3 | 4 | 3 | 3 |
| 9-10 | tek | `retrace` | 1 | 7 | 7 | 7 | 7 |
| 9-10 | tek | `self_recognize` | 1 | 7 | 7 | 7 | 7 |
| 9-10 | tek | `succeed` | 7 | **2** | 3 | 3 | 3 |
| 9-10 | tek | `take_charge` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | tek | `tend` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | tek | `warm_close` | 12 | **1** | 2 | 4 | 4 |
| 9-10 | tek uyku | `approach` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | tek uyku | `companion_offers` | 1 | 8 | 8 | 8 | 8 |
| 9-10 | tek uyku | `establish_ordinary` | 5 | **2** | 2 | 4 | 4 |
| 9-10 | tek uyku | `examine` | 1 | 8 | 8 | 8 | 8 |
| 9-10 | tek uyku | `let_go` | 1 | 8 | 8 | 8 | 8 |
| 9-10 | tek uyku | `meet_companion` | 1 | 8 | 8 | 8 | 8 |
| 9-10 | tek uyku | `notice_anomaly` | 5 | **2** | 2 | 4 | 4 |
| 9-10 | tek uyku | `patient_wait` | 1 | 8 | 8 | 8 | 8 |
| 9-10 | tek uyku | `restore` | 1 | 8 | 8 | 8 | 8 |
| 9-10 | tek uyku | `self_recognize` | 1 | 3 | 3 | 3 | 3 |
| 9-10 | tek uyku | `take_charge` | 1 | 8 | 8 | 8 | 8 |
| 9-10 | tek uyku | `tend` | 1 | 8 | 8 | 8 | 8 |
| 9-10 | tek uyku | `warm_close` | 6 | **2** | 2 | 3 | 3 |

### En ince 20 havuz (önce)

| # | Dosya | Beat | Bant | Kapılar | Ulaşan sayfa | Önce | Sonra |
|---|---|---|---|---|---|---|---|
| 1 | `v3-age7/beat_age7_warm_close.json` | `warm_close` | 7-8 | aile: sibling; uzunluk: solo; rol: guide,needsCare,reassuring; önceki beat: restore,succeed | 8 | 1 | 4 |
| 2 | `v3-age7/beat_age7_warm_close.json` | `warm_close` | 7-8 | aile: friend; uzunluk: solo; rol: guide,needsCare,reassuring; önceki beat: restore,succeed | 8 | 1 | 4 |
| 3 | `v3-age7/beat_age7_warm_close.json` | `warm_close` | 7-8 | aile: animal; uzunluk: solo; rol: guide,needsCare,reassuring; önceki beat: restore,succeed | 8 | 1 | 4 |
| 4 | `v3-age7/beat_age7_warm_close.json` | `warm_close` | 7-8 | aile: imaginary; uzunluk: solo; rol: guide,needsCare,reassuring; önceki beat: restore,succeed | 8 | 1 | 4 |
| 5 | `v3/beat_warm_close.json` | `warm_close` | 5-6 | aile: sibling; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring; önceki beat: restore,succeed | 8 | 1 | 4 |
| 6 | `v3/beat_warm_close.json` | `warm_close` | 5-6 | aile: friend; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring; önceki beat: restore,succeed | 8 | 1 | 4 |
| 7 | `v3/beat_warm_close.json` | `warm_close` | 5-6 | aile: animal; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring; önceki beat: restore,succeed | 8 | 1 | 4 |
| 8 | `v3/beat_warm_close.json` | `warm_close` | 5-6 | aile: imaginary; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring; önceki beat: restore,succeed | 8 | 1 | 4 |
| 9 | `v3-age9/beat_age9_warm_close.json` | `warm_close` | 9-10 | aile: sibling; uzunluk: solo; rol: guide,needsCare; önceki beat: restore,succeed | 2 | 1 | 4 |
| 10 | `v3-age9/beat_age9_warm_close.json` | `warm_close` | 9-10 | aile: friend; uzunluk: solo; rol: guide,needsCare; önceki beat: restore,succeed | 2 | 1 | 4 |
| 11 | `v3-age9/beat_age9_warm_close.json` | `warm_close` | 9-10 | aile: animal; uzunluk: solo; rol: guide,needsCare; önceki beat: restore,succeed | 2 | 1 | 4 |
| 12 | `v3-age9/beat_age9_warm_close.json` | `warm_close` | 9-10 | aile: imaginary; uzunluk: solo; rol: guide,needsCare; önceki beat: restore,succeed | 2 | 1 | 4 |
| 13 | `v3/beat_notice_anomaly.json` | `notice_anomaly` | 5-6 | aile: sibling; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring | 22 | 2 | 4 |
| 14 | `v3/beat_notice_anomaly.json` | `notice_anomaly` | 5-6 | aile: friend; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring | 22 | 2 | 4 |
| 15 | `v3/beat_notice_anomaly.json` | `notice_anomaly` | 5-6 | aile: animal; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring | 22 | 2 | 4 |
| 16 | `v3/beat_notice_anomaly.json` | `notice_anomaly` | 5-6 | aile: imaginary; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring | 22 | 2 | 4 |
| 17 | `v3-age7/beat_age7_notice_anomaly.json` | `notice_anomaly` | 7-8 | aile: sibling; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring | 14 | 2 | 4 |
| 18 | `v3-age7/beat_age7_notice_anomaly.json` | `notice_anomaly` | 7-8 | aile: friend; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring | 14 | 2 | 4 |
| 19 | `v3-age7/beat_age7_notice_anomaly.json` | `notice_anomaly` | 7-8 | aile: animal; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring | 14 | 2 | 4 |
| 20 | `v3-age7/beat_age7_notice_anomaly.json` | `notice_anomaly` | 7-8 | aile: imaginary; uzunluk: solo; rol: guide,hesitant,needsCare,reassuring | 14 | 2 | 4 |

Sıra: önce satır sayısı, sonra ulaşan sayfa sayısı. İlk 12'si tek satırlık havuzlar: 5-6, 7-8 ve 9-10 standart `warm_close`'ta `solo` sayfanın aile havuzu, ilişki başına bir satır. Aile anı olmayan 17 ince havuz (hepsi iki satır) listeye sığmadı: 3-4 `succeed` (dört `afterBeat` grubu), 3-4 `meet_companion` (`hesitant`, `paired`), 7-8 ve 9-10 `succeed` (`cooperative_effort`, `ask_for_help`, `patient_wait`), 7-8 uyku `tend` (`examine`, `companion_offers`), 7-8 ve 9-10 seri `restore` (`let_go` ile `patient_wait` ya da `companion_offers`). Hepsi 4'e çıktı.

### İçerik uyumuyla 3'ün altında kalanlar (H5 sonrası, dokunulmadı)

| Dosya | Bant | Bağlam | Kapı sayısı | İçerik uyumuyla |
|---|---|---|---|---|
| `bedtime/beat_bedtime_series_age3_notice_anomaly.json` | 3-4 | solo; önceki beat: revisit | 6 | 1 |
| `bedtime/beat_bedtime_series_age7_notice_anomaly.json` | 7-8 | solo; önceki beat: revisit | 3 | 1 |
| `bedtime/beat_bedtime_series_age9_notice_anomaly.json` | 9-10 | solo; önceki beat: revisit | 3 | 1 |
| `bedtime/beat_bedtime_series_approach.json` | 5-6 | solo; önceki beat: notice_anomaly | 7 | 1 |
| `bedtime/beat_bedtime_series_notice_anomaly.json` | 5-6 | solo; önceki beat: revisit | 6 | 1 |
| `bedtime/beat_bedtime_series_age3_tend.json` | 3-4 | solo; önceki beat: take_charge | 6 | 2 |
| `bedtime/beat_bedtime_series_tend.json` | 5-6 | solo; önceki beat: take_charge | 7 | 2 |
| `series/beat_series_age3_notice_anomaly.json` | 3-4 | solo; önceki beat: revisit | 7 | 2 |
| `series/beat_series_age3_notice_anomaly.json` | 3-4 | paired; önceki beat: revisit | 4 | 2 |
| `series/beat_series_age7_notice_anomaly.json` | 7-8 | solo; önceki beat: revisit | 3 | 2 |
| `series/beat_series_age9_notice_anomaly.json` | 9-10 | solo; önceki beat: revisit | 3 | 2 |

## Aynı bantta iki ayrı beat dosyasında birebir aynı cümleler

Dört kelime ve üstü cümleler, şablon metni üzerinden. 17 cümle; hiçbiri H5'in eklediği satırlardan değil (H5 taslağında çıkan 7 tekrar yazılırken düzeltildi). Silinmedi.

| Bant | Cümle | Satırlar |
|---|---|---|
| 3-4 | Ayakucuna {{family.possessive}} {{family.name}} kıvrıldı. | `bt3_eo_fa_01` (beat_bedtime_age3_establish_ordinary), `bts3_rv_fa_01` (beat_bedtime_series_age3_revisit) |
| 3-4 | Hayali arkadaşı {{family.name}} pencereyi gösterdi. | `bt3_na_fi_01` (beat_bedtime_age3_notice_anomaly), `bts3_rv_fi_03` (beat_bedtime_series_age3_revisit) |
| 3-4 | Hayali arkadaşı {{family.name}} yanındaydı. | `sr3_fam_im_03` (beat_series_age3_revisit), `swc3_fam_im_03` (beat_series_age3_warm_close) |
| 3-4 | Ne tatlı bir sürpriz! | `bts3_fa_03` (beat_bedtime_series_age3_first_attempt), `bts3_td_03` (beat_bedtime_series_age3_tend) |
| 3-4 | O sırada {{companion.name}} hapşırdı: hapşu! | `bts3_fa_03` (beat_bedtime_series_age3_first_attempt), `bts3_td_01` (beat_bedtime_series_age3_tend) |
| 3-4 | {{child.name}} ile arkadaşı {{family.name}} yan yana uzandı. | `bt3_wc_ff_02` (beat_bedtime_age3_warm_close), `bts3_rv_ff_01` (beat_bedtime_series_age3_revisit) |
| 3-4 | {{child.name}} {{family.possessive}} {{family.name}}'ı okşadı. | `bts3_rv_fa_02` (beat_bedtime_series_age3_revisit), `bts3_wc_fa_03` (beat_bedtime_series_age3_warm_close) |
| 3-4 | {{companion.name}} "hık!" diye hıçkırdı. | `bts3_fa_01` (beat_bedtime_series_age3_first_attempt), `bts3_td_03` (beat_bedtime_series_age3_tend) |
| 3-4 | İkisi yan yana oturdu. | `bts3_pw_03` (beat_bedtime_series_age3_patient_wait), `wc3_02` (beat_age3_warm_close), `wc3h_02` (beat_age3_warm_close) |
| 5-6 | Her şey olması gerektiği gibiydi. | `bts_lg_03` (beat_bedtime_series_let_go), `swc_02` (beat_series_warm_close) |
| 5-6 | {{child.name}} bir an durdu. | `slg_03` (beat_series_let_go), `gs_s_07` (beat_give_up_something) |
| 5-6 | {{child.name}} bir an düşündü. | `bts_tc_02` (beat_bedtime_series_take_charge), `bt_tc_02` (beat_bedtime_take_charge), `cm_p_03` (beat_commit) |
| 5-6 | {{child.name}} derin bir nefes aldı. | `bts_cm_03` (beat_bedtime_series_commit), `wc_p_succeed_04` (beat_warm_close) |
| 5-6 | {{child.name}} yorganını çenesine çekti. | `bt_eo_fa_02` (beat_bedtime_establish_ordinary), `bt_wc_fs_02` (beat_bedtime_warm_close) |
| 5-6 | {{child.name}} {{setting.name}}'daki yatağına girdi. | `bt_eo_02` (beat_bedtime_establish_ordinary), `bt_eo_fa_01` (beat_bedtime_establish_ordinary), `bts_rv_01` (beat_bedtime_series_revisit) |
| 9-10 | {{child.name}} bir an düşündü. | `s9cm_01` (beat_series_age9_commit), `a9_wc_04` (beat_age9_warm_close) |
| 9-10 | {{child.name}} yastığın serin tarafını buldu ve yanağını oraya yasladı. | `b9_eo_08` (beat_bedtime_age9_establish_ordinary), `b9_wc_03` (beat_bedtime_age9_warm_close) |

## Bilinen kusurlar (değiştirilmedi, Batuhan karar verir)

- 7-8 `a7_na_02` (`v3-age7/beat_age7_notice_anomaly.json`): "hemen".
- 3-4 `swc3_fam_sib_03` (`series/beat_series_age3_warm_close.json`): "İkisi de hemen uyudu."
- Ad yuvasından sonra "de/da" bağlacı. Beat korpusunda bir satır: `b7swc_im_02` (`bedtime/beat_bedtime_series_age7_warm_close.json`, "{{child.name}}'e de uyku vaktini hatırlattı"); `FamilyCastTests.testNoLineWritesTheConjunctionAfterASlot` bu satırda kırmızı verir. Korpus dışında, eski `offline/` v1 şablonlarında dört metin satırı (`fantasy_magic_002`, `adventure_courage_garden_004`, `shared_content_library`'de iki) ve iki görsel sahne metni (`adventure_courage_cave_001`, `adventure_courage_footprints_005`). Planın "iki eski satır"ı büyük olasılıkla `b7swc_im_02` ve bunlardan biri; ölçüm tam eşleşmeyi bulamadı.
- Ek bulgu, aynı kural: beat korpusunda "hemen" geçen 49 satır var: `bt7_na_03`, `bt7_na_09`, `bt_ap_blanket_shoulder`, `bts_na_04`, `bts_na_05`, `sr3_02`, `sr3_fam_an_03`, `stc3_02`, `swc3_fam_sib_03`, `sap_01`, `sap_03`, `scm_02`, `sr_fam_an_02`, `sr_fam_an_03`, `sr_fam_an_04`, `stc_02`, `stc_03`, `swc_fam_an_04`, `a7_cm_04`, `a7_ex_01`, `a7_fa_06`, `a7_fb_03`, `a7_fb_06`, `a7_mc_06`, `a7_na_02`, `ce_s_06`, `fa_p_01`, `fa_p_04`, `fb_p_cert_01`, `gs_s_08`, `mc_guide_04`, `mc_care_04`, `mc_hesitant_02`, `mc_care_07`, `mc_care_p07`, `mc_hesitant_06`, `mc_hesitant_p04`, `mc_calm_04`, `mc_person_guide_p01`, `mc_person_calm_p03`, `na_weather_01`, `na_any_02`, `na_fam_fr_01`, `na_fam_an_02`, `pw_s_pm_01`, `pw_s_tc_02`, `rt_s_03`, `ss_s_04`, `sf_s_07`. "hızlı" geçen 6 satır: `a7_na_16`, `a7_re_12`, `a9_rc_01`, `ap_s_03`, `lg_s_06`, `sc_courage_01`. Bir kısmı hız övmüyor ("hemen yanında" yer bildiriyor, "kalbi hızlı atıyordu" beden bildiriyor); ayıklama Batuhan'ın.

## Eklenen satırlar

Bütün metin taslaktır. Var olan satırlara, sıralarına ve kimliklerine dokunulmadı; yeni satırlar dosyanın sonunda, kimlikleri `_h5_` taşır, `move` alanı `h5_` ile başlar. Komşularının kapılarını taşırlar: uyku dosyalarında `settingTraits: isRestingPlace` (5-6, 7-8, 9-10 `notice_anomaly`'de `discoveryTraits: isAudible`), görsel sahnesi olan dosyalarda `visualScene`, `afterBeat` havuzlarında aynı `afterBeat`, 3-4 `meet_companion`'da `castRoles: hesitant`. Masal ailem `notice_anomaly` satırlarında çocuğun adı ilk cümlede; hiçbir satırda yuvadan sonra "de/da", "?", "yarın", "acaba", "birden", "hemen", "hızlı" yok; kelime sayısı dosyanın bandında (yuvalar `PageBudgetTests`'in değerleriyle sayıldı).

| Dosya | Satır | Masal ailem |
|---|---|---|
| `bedtime/beat_bedtime_age3_establish_ordinary.json` | 8 | 8 |
| `bedtime/beat_bedtime_age3_notice_anomaly.json` | 8 | 8 |
| `bedtime/beat_bedtime_age3_warm_close.json` | 8 | 8 |
| `bedtime/beat_bedtime_age7_establish_ordinary.json` | 8 | 8 |
| `bedtime/beat_bedtime_age7_notice_anomaly.json` | 8 | 8 |
| `bedtime/beat_bedtime_age7_tend.json` | 4 | 0 |
| `bedtime/beat_bedtime_age7_warm_close.json` | 8 | 8 |
| `bedtime/beat_bedtime_age9_establish_ordinary.json` | 8 | 8 |
| `bedtime/beat_bedtime_age9_notice_anomaly.json` | 8 | 8 |
| `bedtime/beat_bedtime_age9_warm_close.json` | 8 | 8 |
| `bedtime/beat_bedtime_establish_ordinary.json` | 8 | 8 |
| `bedtime/beat_bedtime_notice_anomaly.json` | 8 | 8 |
| `bedtime/beat_bedtime_series_age7_revisit.json` | 8 | 8 |
| `bedtime/beat_bedtime_series_age7_warm_close.json` | 8 | 8 |
| `bedtime/beat_bedtime_series_age9_revisit.json` | 8 | 8 |
| `bedtime/beat_bedtime_series_age9_warm_close.json` | 8 | 8 |
| `bedtime/beat_bedtime_warm_close.json` | 8 | 8 |
| `series/beat_series_age7_restore.json` | 4 | 0 |
| `series/beat_series_age7_revisit.json` | 8 | 8 |
| `series/beat_series_age7_warm_close.json` | 8 | 8 |
| `series/beat_series_age9_restore.json` | 4 | 0 |
| `series/beat_series_age9_revisit.json` | 8 | 8 |
| `series/beat_series_age9_warm_close.json` | 8 | 8 |
| `v3-age3/beat_age3_meet_companion.json` | 2 | 0 |
| `v3-age3/beat_age3_notice_anomaly.json` | 8 | 8 |
| `v3-age3/beat_age3_succeed.json` | 8 | 0 |
| `v3-age3/beat_age3_warm_close.json` | 8 | 8 |
| `v3-age7/beat_age7_notice_anomaly.json` | 8 | 8 |
| `v3-age7/beat_age7_succeed.json` | 6 | 0 |
| `v3-age7/beat_age7_warm_close.json` | 20 | 20 |
| `v3-age9/beat_age9_notice_anomaly.json` | 8 | 8 |
| `v3-age9/beat_age9_succeed.json` | 6 | 0 |
| `v3-age9/beat_age9_warm_close.json` | 20 | 20 |
| `v3/beat_notice_anomaly.json` | 8 | 8 |
| `v3/beat_warm_close.json` | 20 | 20 |

Okurken bakılacaklar:

- Evcil hayvan satırları yedi türe gidiyor (kedi, köpek, tavşan, kuş, balık, kaplumbağa, hamster). Yeni satırlar türden bağımsız fiiller seçmeye çalıştı ("kıpırdadı", "uyuyordu"); var olan satırlarda "ayakucuna kıvrıldı", "kulak kabarttı" gibi balığa uymayan fiiller duruyor.
- 7-8 ve 9-10 standart `warm_close`'ta ilişki başına beş yeni satır var (iki `paired`, üç `solo`); en kalabalık ekleme burası.
- Sabit tohumlu altın testler: genişleyen havuzlar, aile karakterli masallarda ve ilgili `afterBeat` bağlamlarında seçilen satırı değiştirebilir. Testler çalıştırılmadı; kırılan olursa neden yazılıp fikstür güncellenir (kayıtlı masallar metni saklıyor).

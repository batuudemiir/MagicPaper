# Prototip: p_companion_mirrors_feeling — yol arkadaşı duyguyu sessizce yansıtır

**Durum:** sandbox taslağı. Özgün metin. Örnek bağlama: `{{child.name}}` = Ela · `{{companion.name}}` = Yonca, `{{companion.type}}` = tavşan · mod: `bedtime` / `adventure`, 5-6.

## Bugünkü durum

Katalog yol arkadaşları metinde konuşur ve eylem yapar (`beat_meet_companion.json`, `beat_companion_offers.json`).
Görselli masal canlı değil; öneri asıl olarak illüstrasyon brifine yönelik. Metin-yalnız masal için **söz yok,
beden var** biçiminde tek cümlelik bir karşılık yazılabilir. `beat_hesitate.json` notu zaten duygunun
**adlandırılmadan, bedenle gösterilmesini** istiyor — bu öneri aynı ilkeyi yol arkadaşına uzatıyor.

## ÖNCE (hesitate sayfası, bugünkü üslup)

> Ela'nın ayakları durdu. Köprünün ucunda öylece bekledi. Yonca yanına geldi. "İstersen birlikte bakalım," dedi.

Yol arkadaşı hemen konuşarak gerilimi çözüyor; çocuğun duraksaması sayfada kendi ağırlığını taşıyamıyor.

## SONRA (yol arkadaşı yansıtır, konuşmaz)

> Ela'nın ayakları köprünün ucunda durdu. Elini cebine soktu, orada tuttu.
> Yonca da durdu. Kulaklarını yavaşça indirdi.

> *(sonraki sayfa, çözüm)* Ela derin bir nefes aldı ve ilk tahtaya bastı.
> Yonca'nın kulakları tek tek kalktı.

Yol arkadaşı duygunun **aynasıdır**: çocukla birlikte durur, çocukla birlikte rahatlar. Çözümü çocuk yapar.

## Yazılabilirlik

- Yeni bir beat gerekmez: ilgili beat'lere (`hesitate`, `patient_wait`, `succeed`) 8-12 kelimelik `mirror` sınıfı eklenir,
  `paired` gibi aynı sayfayı paylaşır.
- **Beden varsayımı yok** kuralı (`meet_companion` notu: roster'da robot var) burada kritik: "kulaklarını indirdi" yalnız
  `hasEars` olan arkadaşlar için. Güvenli genel biçimler: "{{companion.name}} da durdu.", "{{companion.name}} biraz
  daha yakına sokuldu." Ünlü uyumu: `{{companion.name}} da/de` doğrulayıcının `UNHARMONISED_CONJUNCTION` kuralına takılır,
  ek biçimi (`{{companion.name}}'{{da}}` vb.) story-engine ile netleşmeli.
- İllüstrasyon brifi için: sahne başına `companionMirror: "<duygu>"` alanı (illustration-system kararı).

## Mod uyumu

| Mod | Uyum | Not |
|---|---|---|
| `bedtime` | Yüksek | Sessiz yansıtma, uyku öncesinin sakin dokusuna uygun; son sayfada arkadaş da uykuya dalar. |
| `adventure` | Yüksek | Gerilim anında konuşmayan arkadaş, çocuğun kararına alan bırakır. |
| `learning` | Orta | Merak yansıtılır (birlikte eğilip bakmak). |

## İçerik maliyeti

3 beat × 4 hücre × ~4 satır ≈ 48 kısa satır; beden özellikleriyle kısıtlı varyantlar ayrıca. Düşük-orta.

# Prototip: p_repeated_line — bilinçli nakarat

**Durum:** sandbox taslağı, üretim içeriği değil. Kitaplardan metin alınmadı; tüm satırlar özgün.
**Örnek bağlama:** `{{child.name}}` = Ela · `{{companion.name}}` = Yonca (tavşan) · mod: `bedtime`, 5-6.

## Bugünkü sorun

Bugün her sayfa bağımsız bir beat varyantından gelir ve kitap içinde **sıfır ortak 5-gram** kuralı var
(`StoryEngine/Tools/validate_beat_corpus.py` → `check_collisions`; motor tarafında
`Services/Validators/DeterministicValidators.swift`). Bu yüzden bir nakarat, yazılsa bile hata sayılır.

## ÖNCE (bugünkü üslupla, kısaltılmış)

> **s.2** Ela pencereden baktı. Bahçedeki fener yanmıyordu. Her gece yanardı, bu gece karanlıktı.
>
> **s.4** Yonca kulaklarını indirdi. "Belki fitili ıslanmıştır," dedi. Ela fenerin camını sildi.
>
> **s.6** Ela kibriti tuttu, Yonca nefesini tuttu. Küçük alev titredi ve sonunda tuttu.
>
> **s.8** Fener yine yanıyordu. Ela yorganına girdi. Gözleri yavaşça kapandı.

Her sayfa doğru; ama dinleyen çocuğun **katılabileceği** bir satır yok.

## SONRA (nakarat: 3 kez aynı, sonda bir kez değişir)

> **s.2** Ela pencereden baktı. Bahçedeki fener bu gece yanmıyordu.
> *Fener uyumuş, bahçe uyumamış.*
>
> **s.4** Yonca kulaklarını indirdi. "Belki fitili ıslanmıştır," dedi. Ela camı sildi.
> *Fener uyumuş, bahçe uyumamış.*
>
> **s.6** Ela kibriti tuttu, Yonca nefesini tuttu. Küçük alev titredi ve tuttu.
> *Fener uyanmış, bahçe uyumamış.*
>
> **s.8** Ela yorganına girdi. Pencerede sarı bir ışık vardı.
> *Fener uyanık, bahçe uyumuş.*

Dördüncü tekrar "değişen son"dur: nakarat, uyku öncesi inişini kendisi taşır.

## Slot/beat sistemine nasıl girer

- Nakarat bir beat varyantı **değil**; blueprint (ya da blueprint × mod) başına yazılan ayrı bir satır ailesi:
  `refrain.base` (3 kez) + `refrain.turn` (son sayfada 1 kez). Örnek alanlar: `{{refrain.line}}`.
- Nakarat sayfa metnine **eklenir**, sayfa bandına (18-38) sayılır; nakarat ≤ 6 kelime → varyant 12-32'ye iner.
  Bu, mevcut `paired` sınıfına benzer bir kısaltma ister.
- `check_collisions` nakarat satırını yok sayacak şekilde etiketle ayrılmalı (motor + doğrulayıcı değişikliği,
  story-engine kararı). Kaza tekrarı yine hata kalır.
- Nakarat slot içermemeli (ad, yer) — ünlü uyumu riski yok, havuz hesabını bozmaz.

## Mod uyumu

| Mod | Uyum | Not |
|---|---|---|
| `bedtime` | Yüksek | Tekrar ritmi yatıştırır; son değişim sakin iniş olur. Soru ya da "yarın" içermez (`CalmEnding`). |
| `learning` | Orta | Nakarat bilgiyi taşıyabilir ("Kökler aşağı, yapraklar yukarı"). |
| `adventure` | Orta | Çağrı tipi ("Hadi Yonca, bir adım daha!") — sayfa 7'de değişir. |

## İçerik maliyeti

Blueprint başına 1 nakarat + 1 değişen son, mod başına ayrı ise ×3. 19 blueprint için ~40-60 kısa satır;
tekrar oranı kaygısı yok çünkü nakarat zaten tekrar için var. Gerçek maliyet motor tarafında (etiketli muafiyet).

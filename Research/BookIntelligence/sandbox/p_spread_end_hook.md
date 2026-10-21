# Prototip: p_spread_end_hook — sayfa sonunda açık uç

**Durum:** sandbox taslağı. Özgün metin. Örnek bağlama: `{{child.name}}` = Can · `{{companion.name}}` = Kıpır (tilki) · mod: `adventure`, 5-6.

## Bugünkü sorun

Sayfa sonları tanımsız; her varyant kendi içinde kapanır. Sayfalar bağımsız çekildiği için bir sayfanın sorusunu
**hangi** varyantın cevaplayacağı bilinmez — PROSE_PRODUCTION_GUIDE.md'deki "ışık/ses" hatası tam bu türden
(iki doğru sayfa, aralarında çelişki).

## ÖNCE

> **s.4** Can dere kenarına geldi. Taşlar ıslaktı ve kaygandı. Kıpır karşı kıyıda bekliyordu. Can bir yol aramaya başladı.
>
> **s.5** Can kıyı boyunca yürüdü. Biraz ileride düz bir kütük gördü. Kütük iki kıyıyı birleştiriyordu.

## SONRA (sayfa 4 açık uçla biter, cevap sayfa çevrilince gelir)

> **s.4** Can dere kenarına geldi. Taşlar ıslak ve kaygandı. Kıpır karşı kıyıdan baktı.
> **Ama Can karşıya nasıl geçecekti?**
>
> — sayfa çevrilir —
>
> **s.5** **Kıyı boyunca yürüyerek.** Biraz ileride düz bir kütük vardı. Can kütüğe dikkatle bastı.

## Yazılabilirlik: iki güvenli yol

1. **Genel soru + her cevabı karşılayan açılış.** Soru beat'e bağlı ve genel kalır ("Ama nasıl?", "Peki şimdi ne olacaktı?");
   sonraki beat'in *tüm* varyantlarına bir `answersHook: true` açılışı yazılır. Çapraz-sayfa çelişki çıkmaz çünkü soru hiçbir
   ayrıntı vaat etmez.
2. **Kancayı beat çiftine bağlamak.** `obstacle_raises` → `first_attempt` gibi sabit sıralı çiftlerde, soru ve cevabı aynı
   `editorialNote` sözleşmesi altında yazmak; doğrulayıcı `hookKind` eşleşmesini kontrol eder.

Yol 1 ucuzdur; yol 2 daha canlı ama `check_bound_pools` gibi bir eşleşme kapısı ister (story-engine).

## Mod uyumu

| Mod | Uyum | Not |
|---|---|---|
| `adventure` | Yüksek | Sayfa çevirme merakı doğal. Sayfa 3-6 arasında en fazla 2 kanca. |
| `learning` | Yüksek | Soru zaten öğrenme biçimi: "Peki karınca bunu nasıl taşıyordu?" |
| `bedtime` | Düşük | Yalnızca sayfa 2-4'te, yumuşak ("Fener nereye gitmişti acaba?" değil — `acaba` CalmEnding listesinde; "Fener nerede olabilirdi?"). Son iki sayfada **asla** soru yok. Seri bölüm sonları zaten yasak (`Offline/Series/CalmEnding.swift`). |

## İçerik maliyeti

Yol 1: kanca alan ~6 beat × 4-6 soru satırı + cevap alan beat'lerin varyantlarına kısa bir açılış (~40-60 satır düzeltmesi).
3-4 bandında cümle tavanı 10 kelime; kanca 3-5 kelimeyle sığar.

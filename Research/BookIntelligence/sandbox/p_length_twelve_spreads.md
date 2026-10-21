# Prototip: p_length_twelve_spreads — aynı kelime, daha çok sayfa çevirme

**Durum:** sandbox taslağı. Özgün metin. Örnek bağlama: `{{child.name}}` = Can · `{{companion.name}}` = Kıpır (tilki) · mod: `learning`, 5-6.

## Bugün

8 sayfa × 18-38 kelime (`validate_beat_corpus.py` → `BANDS`). Önerilen nüfusta toplam benzer (~150 kelime), ama
~12 çevirmeye bölünüyor. 12 **beat**'e geçmek içerik hattı için pahalı: her yeni sayfa ≥4 varyantlık hücre ister
(`MIN_BOUND_POOL = 4`), yani havuzların %50 büyümesi. Bunun yerine **mevcut sayfayı ikiye bölmek** denenebilir.

## ÖNCE (tek sayfa, 31 kelime)

> **s.5** Can karıncaların yolunu izledi. Yol bir taşın altına giriyordu. Can taşı yavaşça kaldırdı. Altında küçük odalar vardı,
> her birinde beyaz yumurtalar. Kıpır burnunu yaklaştırdı ama dokunmadı.

## SONRA (aynı içerik, iki çevirme)

> **s.5a** Can karıncaların yolunu izledi. Yol bir taşın altına giriyordu.
> Can taşı yavaşça kaldırdı.
>
> — sayfa çevrilir —
>
> **s.5b** Altında küçük odalar vardı. Her birinde beyaz yumurtalar.
> Kıpır burnunu yaklaştırdı ama dokunmadı.

Bölünme noktası, cümlenin değil **beklentinin** ortasıdır: taş kalkar, ne olduğu sayfa çevrilince görülür.

## Yazılabilirlik

- Varyant metni değişmez; varyanta bir `turnAfter: <cümle indeksi>` işareti eklenir. Okuyucu (reader) bir sayfayı iki
  çevirmeye bölebilir; motor ve havuzlar aynı kalır.
- Her varyant zaten birden çok cümle; 18-38 kelimelik sayfa → iki 9-19 kelimelik yarım. 3-4 bandı (cümle tavanı 10) doğal aday.
- `paired` sayfalar (ör. `warm_close` + `self_recognize`) zaten iki parça: bölünme noktası hazır.
- Tüm sayfalar bölünmez: 8 sayfadan 4'ü → 12 çevirme.

## Mod uyumu

| Mod | Uyum | Not |
|---|---|---|
| `learning` | Yüksek | Gözlem → açılış ritmi. |
| `adventure` | Yüksek | `p_spread_end_hook` ile birlikte en güçlü. |
| `bedtime` | Orta | Çevirme sayısı uykuyu geciktirebilir; son iki sayfa bölünmez, sakin iniş korunur. |

## İçerik maliyeti

Yeni metin yok. Mevcut ~varyantlara bölünme işareti: editoryal geçiş, beat başına bir oturum. Asıl maliyet reader +
illüstrasyon tarafında (sayfa başına görsel sayısı artar — görselli masal canlı olunca bütçe sorusu).

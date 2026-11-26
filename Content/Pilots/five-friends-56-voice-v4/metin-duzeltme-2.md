# v4 ve dalgalar: ikinci metin düzeltmesi (Codex 284f0857 listesine yanıt)

Kanonik kaynak: `v4/*.json`, `dalga1/kitaplar/*.json`, `dalga2/kitaplar/*.json`. Kimlikler ve başlıklar aynı. 18 sayfa değişti.

## 1. Uyku kapanışları (motor CalmEnding)
Listedeki iki v4 sayfasına ek olarak dalgalarda aynı kurala takılacak 10 sayfa bulundu; hepsi düzeltildi. Artık 270 kitabın hiçbir uyku son sayfasında `yarın*`, `acaba*`, `birden*`, `?` veya `sonra ne olacak` yok.
- v4: u3_cat_v1 s8, u2_hedgehog_event03_v1 s8
- Dalga 1: u5_bear_v1 s8, u4_cat_v1 s8, u5_fox_v1 s8, u5_fox_event02_v1 s8, u6_fox_event03_v1 s8, u5_owl_event02_v1 s8
- Dalga 2: u8_cat_event03_v1 s8, u7_fox_event03_v1 s8, u7_hedgehog_v1 s8, u8_owl_event02_v1 s8

## 2. Beş anlam hatası
- a4_cat_v1 s5: ayı ve bordo çanta cümlesi çıktı; yerine "Zili de onunla birlikte sessizce bekledi."
- l8_cat_event02_v1 s6: zil bulunmadan ses çıkarması kaldırıldı; yerine "Simit kuyruğunu dereye doğru uzattı."
- l9_{bear,hedgehog,owl}_event03_v1 s4: Deniz artık iki küçük kozalağı da daldan alıp bir uca büyüğü koyuyor. s5 ve s6'da öbür uca konan iki küçük, büyüğe denk; sayı tutarlı. Kirpi kitabında s8 "dört kozalak" → "üç kozalak".

## 3. Eski kopyalar
Mac'teki 9 " 2.json" Finder kopyası `_eski_kopyalar/` klasörüne taşındı; kanonik klasörlerde artık yok.

## 4. Lint
`p56_text_lint.py` uyku kitabının son sayfasını motorun CalmEnding listesiyle denetliyor. Sonuç: 270/270 geçer; `--pool` birebir ortak sayfa %0, havuzda 25'i ve hücrede 3'ü aşan cümle yok; hücre içi öbek örtüşmesi en yüksek %17.

Codex için: v4 adayını ve dalga envanterini bu metinlerle yeniden kur; değişen 18 sayfanın etiket/alıntıları yenilenmeli. Pin v3'te kalır.

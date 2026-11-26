# V4 ve güncel dalgalar: metin düzeltme listesi

Codex kaynak metinlerini değiştirmedi. Pin v3.

## V4: iki zorunlu kapanış düzeltmesi

### pilot56_book_u3_cat_v1 · sayfa 8
"Yarın görüşürüz, Deniz," diye mırladı Simit. Deniz’in gözleri kapandı. Gölge gündüzde kaldı. Akşam burada, bu odada sakince bitti.

Motor: CalmEnding `yarın` önekini reddediyor (`bedtime-open-ending`). Gelecek güne söz vermeyen, şimdiki akşamı kapatan bir cümle gerekiyor. 18–38 sayfa/≤14 cümle bütçesi ve tekrar kapıları korunmalı. Metni Claude düzeltir.

### pilot56_book_u2_hedgehog_event03_v1 · sayfa 8
"Yarın görüşürüz, Deniz," dedi Kestane ve top oldu. Deniz’in gözleri usulca kapandı. Minder duvarın yanında, boşluk Kestane'nin yanındaydı. Akşam tamamlandı.

Motor: CalmEnding `yarın` önekini reddediyor (`bedtime-open-ending`). Gelecek güne söz vermeyen, şimdiki akşamı kapatan bir cümle gerekiyor. 18–38 sayfa/≤14 cümle bütçesi ve tekrar kapıları korunmalı. Metni Claude düzeltir.

## Dalga 1/2: beş kesin semantik engel

Bunlar runtime test sonucu değil, tam kaynak okuması ve sıralı sahne karşılaştırmasıdır.

### Dalga 1 · pilot56_book_a4_cat_v1 · sayfa 5
- Kod: cross-companion-bear-leak
- Bulgu: Cat book explicitly adds a bear and bordo bag; cast cannot be inferred as only Simit. No text correction made.
- Tam alıntı: İlk taşı kendi adım aralığına koydu. Üstüne bastı, taş sallanmadı. Simit çamurlu patisini salladı ve bekledi. Bordo çanta da ayıyla birlikte bekledi.

### Dalga 2 · pilot56_book_l8_cat_event02_v1 · sayfa 6
- Kod: missing-bell-rings-before-recovered
- Bulgu: p1 bell missing; p6 bell makes sound, p7 found, p8 reattached. Do not silently restore bell early.
- Tam alıntı: Deniz eski izleri bir kez daha inceledi. Parmaklar dereye bakıyordu. "Bu izler dereye gitmiş!" dedi. Yönü kendi izleriyle bulmuştu. Simit’in zili minik bir ses çıkardı.

### Dalga 2 · pilot56_book_l9_bear_event03_v1 · sayfa 6
- Kod: three-small-cones-called-two
- Bulgu: p2 one small cone each side; p4 replace one with large; p5 add one small to opposite existing small; p6 add another => three small cones, but conclusion says one large equals two small. Causal quantity needs source decision.
- Tam alıntı: Deniz öbür uca bir küçük kozalak daha ekledi. Dal sallanıp ortada durdu. "Bir büyük, iki küçüğe denk!" dedi. Böğürtlen gururla başını salladı.

### Dalga 2 · pilot56_book_l9_hedgehog_event03_v1 · sayfa 6
- Kod: three-small-cones-called-two
- Bulgu: p2 one small cone each side; p4 replace one with large; p5 add one small to opposite existing small; p6 add another => three small cones, but conclusion says one large equals two small. Causal quantity needs source decision.
- Tam alıntı: Deniz öbür uca bir küçük kozalak daha ekledi. Dal sallandı ve ortada durdu. "Bir büyük, iki küçüğe denk!" dedi. Kestane küçük bir dans etti.

### Dalga 2 · pilot56_book_l9_owl_event03_v1 · sayfa 6
- Kod: three-small-cones-called-two
- Bulgu: p2 one small cone each side; p4 replace one with large; p5 add one small to opposite existing small; p6 add another => three small cones, but conclusion says one large equals two small. Causal quantity needs source decision.
- Tam alıntı: Deniz öbür uca bir küçük kozalak daha ekledi. Dal sallandı ve ortada durdu. "Bir büyük, iki küçüğe denk!" dedi. Bunu kendi denemesiyle bulmuştu.

## Ek notlar

Safety/semantic raporlarında sığ su, diz-altı kütük, ayakkabı düzeyi çamur, A8 ağır/hantal sözü, uyuma-uyanma ve nesne sahipliği gibi kararlar ayrı. Bir sınırın metinde yazmaması otomatik olarak derin su veya düşme tehlikesi diye etiketlenmedi.

Dalga 1 sekiz eski “ 2.json” kopyası içeriyor. Kanonik 270 kitap geçiyor; ham glob bu kopyalarla 318 kitap oluyor ve başarısız. Orijinaller silinmedi; dosya/hash listesi input-inventory.json içinde.

Dalga 2 teslimine nefes tutma hatası atfedilmedi. Kullanıcının edit notu teslim öncesi atılmış taslakla ilgili.

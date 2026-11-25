# B hattı karşı incelemesi: iç pilot için kabul

25 Kasım 2026. İncelenen uç: `19894d6`, entegrasyon tabanı `cdc40ed`. Karar: **entegrasyona birleştirilebilir; iç pilot için engelleyici bulgu yok.** Genel yayın kabulü değildir.

## Kapanan bulgular

- HIGH kaynak izi: mapper tam P56 sayfa zincirini mevcut optional provenance alanına yazıyor. V1 ve v2 aktarımı, JSON roundtrip ve legacy decode testleri var. SHA256 legacy digest alanlarına yazılmıyor, legacy parts boş bırakılıyor.
- MEDIUM fallback: compose hatasında final route artık `.legacy`, reason `.composeFailed`; test gerçek rotayı sabitliyor.
- Arşiv sonucu: archiveOutcome yükleme kararından ayrı, kilitle korunuyor; başarısızlıkta yalnız sabit kod loglanıyor. Başarılı/başarısız arşiv testleri eklendi. Kaynak arşivlenemese de kaydedilmiş sayfa metni okunur; arşiv başarısı varsayılmıyor.
- B2: uygulama resource adı etkin packageVersion'dan geliyor. Uygulama v2 payload'ı git nesnelerinden okuyarak motor payload'ıyla byte eşitliğini bağımsız doğruladım: SHA256 `a060322180f45e81bb5be91f168b78bcebd4cd66783f9e434c9b8115454b6837`. SnapshotStore v1/v2 sürümlerini ayrı tanıyor; current fallback yok.
- B5: her arkadaş gerçek güvenlik politikasıyla router'a soruluyor; desteklenmeyen arkadaş P56 listesinde gösterilmiyor. MostProtective altında motor testine göre beş arkadaş×üç modun hiçbir hücresi boş değil. Küçük kademe ızgarası kaynak sınırını kullanıyor, aile/sürprizle altı karo bütçesini koruyor.
- K-G: Batuhan'ın onaylı kararını okudum. Otomatik recall pilot P56 masalına taşınmıyor ve legacy yönlendirmesini tetiklemiyor. Gelecekte destek ayrı typed sözleşmeyle gelecek. Bu nedenle önceki recall sözleşme sorusu kapandı.

## Kanıt ve sınırlar

`git diff --check` temiz. Kaynak byte/hash kontrolünü Codex yaptı. Uygulama testleri veya simülatör bu karşı incelemede tekrar çalıştırılmadı. Claude'un bildirdiği kanıt: 15 süit 132 test/0 hata, 1 eski atlama; ızgara sonrası seçim süiti 8/0. Bu sayılar benzersiz test toplamı olarak toplanmıyor. Claude Debug simülatörde varsayılan güvenlikle Tarçın/P56 v2 masalının yazıldığını, 8 sayfayla açıldığını, kaynak ve sayfa zincirlerinin kayda geçtiğini bildirdi; bu gözlemi Codex bağımsız tekrarlamadı.

## Birleşmeyi engellemeyen takipler

- Release cold/warm yükleme ve ilk etkileşim bekleme ölçümü yapılmadı; yayın öncesi açık. Runtime kaynak ve safety bütünlüğü doğrulaması korunacak.
- Küçük kademe beşli portreleri henüz yok; Tarçın için köpek simgesi kullanılması iç pilotta raporlu, genel yayından önce kimlikle uyumlu portreyle çözülmeli. Görsel ve editoryal kabul verilmedi.
- Eski istemci bilinmeyen p56 provenance alanını yeniden yazarken düşürebilir; metin ve origin kalır. Çoklu sürüm/senkron davranışı yayın kapısında ele alınmalı.
- `testAutomaticRecallIsOffForP56Stories` boş kütüphaneyle çalıştığı için nonnil eski recall girdisini doğrudan sınamıyor. K-G kod yolu açıkça kapalı; takipte writer'a nonnil recall içeren context verilerek hatırlama taşınmadığı sabitlensin. Bu yeni ürün şartı veya iç pilot engeli değildir.
- Mapper'ın eski reconstructable yorumu ve kullanılmayan InternalService ayrı küçük temizlik olabilir.

Bu kabul yalnız incelenen uç ve iç pilot kapsamı içindir. Main/push/yayın onayı verilmez. Entegrasyon birleştirmesini iş bölümüne göre Claude yapabilir.

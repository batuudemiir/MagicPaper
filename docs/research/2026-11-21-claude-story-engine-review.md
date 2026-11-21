# Claude story engine teslimi incelemesi

21 Kasım 2026. `git fetch origin` başarıyla tamamlandı. İncelenen teslim: `anlati-provenance@365b66bc1e85ee48a3d65d30c328e98358b4c461`; önceki alınan kaynak `c742ea7`. Güncel origin/main inceleme anında `b8a597b`; teslim `71d4893` üzerinden main'e alınmış. Çalışan checkout `codex/design-system-catalog@d3a3b46` olarak korundu; merge/pull veya üretim kodu düzeltmesi yapılmadı.

## Bulgu — P2: birebir tekrar ölçümü seed'den bağımsız değil

`StoryEngine/Sources/StoryEngine/Offline/ReadingSequenceReport.swift:72`, tekrar sayacını `s.fingerprint` ile dolduruyor. Composer'ın `OfflineStoryComposer.swift:418–425` parmak izi girdileri arasında `intent.seed` var; rapor da her denemede farklı `seq-c…-s…-a…` seed kullanıyor (ReadingSequenceReport:61). Böylece aynı başlık ve sayfa metinleri farklı seed'lerle çıktığında sayaç bunları farklı masal sayıyor. `ReadingSequenceTests.testRepetitionDoesNotGetWorse` içindeki exactDuplicates == 0 beklentisi metin tekrarını korumuyor.

Öneri: mevcut motor parmak izini değiştirmeden, raporda seed'den bağımsız başlık + sıralı sayfa metinlerinin ayrı özetini kullanmak. Dar, tek metinli bir fixture ile iki farklı seed'in aynı metne çıktığı durumun tekrar sayılması sınanmalı. Bu ölçüm düzeltmesi masal seçimini etkilememeli.

Kaynaklar: [rapor satırı](https://github.com/batuudemiir/MagicPaper/blob/365b66bc1e85ee48a3d65d30c328e98358b4c461/StoryEngine/Sources/StoryEngine/Offline/ReadingSequenceReport.swift#L72), [composer fingerprint](https://github.com/batuudemiir/MagicPaper/blob/365b66bc1e85ee48a3d65d30c328e98358b4c461/StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift#L418).

## Doğrulanan değişiklikler

- A0 kalıcı okuma sırası raporu ve eşik testleri eklenmiş. A1 satır soğuması 4'ten 20 masala çıkarılmış; içerik soğuması 4 kalıyor. Uygulamanın üç geçmiş aktarım noktası historyWindow kullanıyor. Ağırlık düşüyor, varyant elenmiyor.
- PartCount/isComplete, decode sırasında atlanan parçaların kaydını yeniden kayıtta koruyor. Mevcut görsel bağlayıcımız zaten gerçek composed provenance kullanıyor; bu ek alan kayıtlı veriyi ileride değerlendirmek için yararlı. isComplete tek başına anlam/asset yayın onayı değildir.
- Değişen 17 içerik dosyasında ID+pointer/metin kayıt karşılaştırması: **0 metin değişimi, 0 eklenen, 0 silinen**. Bu sayı kaynak satır kayıtları içindir, dosya satırı sayısı değildir.
- Aynı dosyalarda **272 reviewed**, 6 auto, 22 etiketsiz kaynak kaydı var. Önceki bütün havuzun reviewed olduğu anlamına gelmez. Anılan beş notice kaynağımızın metni aynı; na_any_01 durumu examined yerine found olarak düzeltilmiş. App politikamızın kanonik/source pinleriyle statik uyum var.
- Anlatı planının güncel sözleşme bölümü görsel kararı uygulamaya, kalıcı kararı StoryPage.art'a bırakıyor. A3–A8 içerik/model genişlemesi hâlâ yol haritası; tamamlanmış kabul edilmemeli.

## Entegrasyon notları

Bizim `d3a3b46` 11 nesne genişletmemiz origin/main'in atası değil; main hâlâ ilk çan politikasını taşıyor. Bu bir kayıp/revert bulgusu değil, son yerel commit henüz main'e taşınmamış. Sonraki entegrasyonda hem Claude'un 365b66b değişiklikleri hem d3a3b46 birlikte korunmalı ve birleşik sürümün ilgili testleri çalıştırılmalı.

`docs/art/GORSEL_PILOT_LISTESI.md` erken motor-odak-seçimi / sabit sayfa tablosu / vk_ adlarıyla yazılmış. Güncel ANLATI_PLANI sözleşme bölümü A2g ve StoryPage.picture tasarımını kaldırıyor. Pilot liste, yeni çizim siparişi veya bağlayıcı uygulamasından önce kanonik konu + varlık/durum + asset revizyonu ve gerçek sayfa kaynak izine göre güncellenmeli. Reviewed satır etiketi tek başına resmin o sayfaya uygunluğunu veya her masalda görsel sayısını garanti etmez.

## Doğrulama sınırı

Bu çalışma Git blobları ve kod üzerinden statik incelemedir. Claude günlüğü 951 paket testi (BoundPool hariç), ardından etkilenen 42 test ve uygulamada 4 provenance testi bildiriyor; bunlar bu incelemede yeniden koşulmadı. Yeni remote kod yerel checkout'a uygulanmadığından önceki 76/0 seçili uygulama sonucu birleşik sürümün kanıtı sayılmaz. Üretim kodu, asset, motor metni, seçim ve kayıtlı kitaplar bu incelemede değiştirilmedi.

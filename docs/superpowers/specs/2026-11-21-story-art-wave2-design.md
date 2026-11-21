# Görsel nesne havuzu: ikinci genişleme

Kullanıcının nesneleri ve eşlemeleri artırma talebi uygulanır. Onaylı offline, kaynak izli, sabit çizimli tasarım korunur. Üç yeni nesne: object_compass_001, object_coin_001, object_star_stone_001. İlk ikisi fiziksel araç/para; üçüncüsü somut yıldız biçimli parlak taştır. Yeni PNG'ler yerleşik image_gen ile onaylı stil referansları verilerek hazırlandı ve incelendi; aynı byte'lar mpart olarak paketlenir.

## Kaynak ve yaş kapsamı

14 konu; 20 exact notice kaynağı (3 küçük yaş paired, 8 yaş5–6, 4 yaş7–8, 5 yaş9–10); mevcut 38 recall. Notice kaynakları sadece fiziksel keşfin varlığını doğrular. Bütün kaynak havuzu reviewed olduğu için otomatik açılmaz. Yeni kayıt ve kaynakların tam metin/digest/kararları research/2026-11-21-story-art-wave2-decisions.json ve sabit SHA'lı reviewed-discovery-art-wave2-v2.json içindedir. Kimlik benzersizliği templateID+sourceID üzerinden sağlanır.

Tek beat: notice_anomaly, tam kaynak listesi ve en çok bir son incelenmiş recall. Yaş3–4 paired notice satırı bu yoldan tek başına kabul edilmez.

Küçük yaş için tek ek biçim: yalnız bp_sports_howitmoves_age3_001 / bp_sports_wind_age3_001 / bp_sports_together_age3_001 blueprint'lerinin sayfa1'inde notice_anomaly → meet_companion. İlk kaynak, corpus_3-4_notice_anomaly içindeki s34_na_01/02/tp_01; ikinci kaynak corpus_3-4_meet_companion içindeki mc3u_01/04/05/tp_01. İki beat_line tam sırada, variantIDs eksiksiz; iki parçanın contexts alanı boş. İlk parça doğru discovery present; ikinci parça yalnız gerçek companion kimliğiyle present/greeting ve keşif anması yok. Bu dalda recall, ek beat, başka blueprint veya sayfa reddedilir. Resim yalnız nesnedir, arkadaş resmi değildir. Yıldız taşı sports seçim koşullarıyla uyumsuzdur; tüm14konu için3–4 kapsamı sözü verilmez.

## Bağlayıcı ve uyumluluk

Authorization asset+proof+onaylanan beat sırasını birlikte döndürür; binder gerçek page.beats ile eşitlik arar. Composed/app metin/sayı/sıra, origin ve canonical nesne özeti korumaları sürer; mevcut art/image/scene üzerine yazılmaz. Aile/özel gün/seri/nakarat/eksik slot/kimliği belirsiz parça kapalıdır. V1 öncelikli kalır. Eski bell proof, policy2 dosyaları ve eski11 manifesti okunabilir; yeni üretimde wave2 manifest bozuksa gizli eski manifest fallback'i yok. Kaydedilen art schema1/policy2 değişmez, eski kitaplar yeniden bağlanmaz.

Claude365b66b deltası c742ea7'den 32 path kaynak patch'iyle alındı (paylaşılan günlük hariç; merge değil). Motor metni/ID değişimi yok; satır geçmişi20 ve partCount upstream teslimidir. ReadingSequenceReport ölçüm bulgusu bu tur düzeltilmez. Görsel işi ayrıca seçim dağılımını değiştirmez. Reader UI/karakter kimliği değişmez.

## Kabul ve doğrulama

Tests first, AGENTS gereği finalde çalıştırma. Yeni14subject/20source exactguard ve negatifler; compound12sourcepair ve blueprint/page/order/companion/context/recall negatifleri; eski manifest/bellproof/v1priority; üç yeniassetgerçekreaderdecode. Gerçek composer ile3–4 paired örneği ve7–8/9–10 single örnekleri, yeni üç nesnenin en az bir gerçek appmap/save fixture'ı; metin eşitliği. Kapsam yalnız kanıtlanan örneklerdir, her masalda çizim garantisi değildir. Final engine ve app test sonuçları, eksikler ve telefon durumu raporlanır.

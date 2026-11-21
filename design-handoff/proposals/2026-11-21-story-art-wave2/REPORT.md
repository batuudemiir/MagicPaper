# Görsel nesne ve kaynak kapsamı: ikinci genişleme

21 Kasım 2026. İkinci genişleme uygulandı ve seçili testlerle doğrulandı.

## Görseller

Onaylı referanslarla yerleşik image_gen kullanılarak pirinç pusula, eski madeni para ve yıldız biçimli taş hazırlandı. Her biri ayrı, saydam zeminde tek somut nesne; çocuk/Ragi/arkadaş kimliği veya sahne eklenmedi. Tam alfa aralığı 0–255, RGBA, 1254×1254. Görseller araç çıktısında açılıp incelendi. Kaynak PNG'ler assets/; aynı byte'lar runtime mpart. Renk/doku mat guaj; ana arayüz rengi değişmedi. Üretim kaydı GENERATION_RECORD.json.

## Kaynak ve uygulama

Kanonik nesne sayısı 11→14. Kaynak izin listesi 5→20 notice, ayrıca dört küçük yaş destek satırı ve mevcut 38 recall. Üç küçük yaş notice satırı paired olduğundan tek başına resim izni vermez. Ek dar sayfa şekli: yalnız üç spor blueprint'inin ilk sayfasında incelenmiş notice→meet_companion; gerçek arkadaş kimliği doğrulanır; bu dalda recall yok. Bu, genel çoklu beat izni değildir. Yeni kaynakların tam metni ve kararlar docs/research/2026-11-21-story-art-wave2-decisions.json içinde.

Claude365b66b delta'sı c742ea7 üzerinden 32 path kaynak patch'iyle uygulandı; paylaşılan günlük hariç, merge yapılmadı. Kaynak metinleri/kimlikleri aynı; upstream geçmiş penceresi20 ve partCount birlikte gelir. ReadingSequenceReport için önceki P2 ölçüm bulgusu açık bırakıldı. Eşleme işi ayrıca seçim/seed dağılımını veya masal metnini değiştirmez.

Mevcut v1 önce; eski asset dosyaları ve kayıtlı pinler korunur. Belirsiz, eksik, bağlamı desteklenmeyen sayfa metin kalır. Aile/seri/özel gün/nakarat desteği eklenmez. Yıldız taşı spor blueprint'lerinin keşif koşullarını karşılamadığı için o küçük yaş paired yolunda kullanılmaz.

## Sınırlar

Tüm14konunun her yaşta, her modda veya her kitapta çıkması garanti değildir. Kapsam, aşağıdaki gerçek composer örnekleriyle doğrulandı; bütün havuz için garanti değildir. Eski kitaplara görsel eklenmez; okuyucu düzeni/kimlikler değişmez. Telefona kurulum, yeni ekran görüntüsü matrisi veya tam UI/VoiceOver incelemesi yapılmadı.

## İnceleme ve test kanıtları

Spec uyumluluğu ve bağımsız kod kalite incelemesi engelleyici bulgu bulmadı. Tests first yazıldı; AGENTS gereği ara RED koşusu yapılmadı.

- Temiz kaynaklarla seçili motor testi: **44 test / 0 hata**, çıkış 0. Kaynak izi, görsel anlam, satır soğuması, okuma sırası, konu ve kullanım ağırlıkları; log `/private/tmp/MagicPaper-wave2-engine-clean.log`. Tam paket ve BoundPool matrisi çalıştırılmadı.
- Temiz kaynaklarla seçili uygulama testi: **89 test: 88 başarılı, 1 skip, 0 hata**, TEST SUCCEEDED, çıkış 0. Log `/private/tmp/MagicPaper-wave2-app-clean.log`. Yeni politika 15/15; provenance 4/4; resolver 6/6; binding 6/6; reader mapping 29/29; context 9/9; offline mapping 20 test/1 skip. Atlanan mevcut fixture, tilkinin o bağlamda seçilebilir olduğu durumda ret koşulu bulunmadığını bildiriyor.
- 14 çizim gerçek ReaderImageLoader ile açıldı. Eski on gerçek v1 fixture'ının önceliği, recalled politika2 ve JSON kaydet/decode zinciri geçti. Eski çan proof ve önceki11manifest uyumu test edildi.
- Yeni gerçek örnekler `real-composer-fixtures.json`: 3–4 pusula / sports how-it-moves / seed reviewed-wave2-3 / sayfa1 notice+meet; 7–8 madeni para / absence-retracing / seed reviewed-wave2-1; 9–10 yıldız taşı / threshold-together / seed reviewed-wave2-1. Test ekleri xcresult'tan dışarı çıkarıldı; bu kayıtlar elle uydurulmuş senaryo değildir.

## İlk koşu hataları ve kaynak kopyalarının korunması

İlk motor koşusu, corpus içinde eski metadata taşıyan 193 izlenmeyen `… 2.json` dosyası da paketlendiği için görsel anlam assertion'larında ve duplicate variant sözlüğünde başarısız oldu. Canonical dosyada na3_01 reviewed/visual[] iken kopyasında iki alan da yoktu. BeatCorpusLoader tüm beat_*.json dosyalarını okuduğundan kopyalar ikinci template olarak yüklendi. İlk app koşusu 89 testte yalnız gerçek3–4pusula fixture'ını bulamadı.

193 kaynak dosyası silinmedi: canonical karşılıklarının Git'te izlendiği ve kopyaların izlenmediği doğrulandı; kaynak/destination/SHA manifestiyle `/private/tmp/magicpaper-json-copy-quarantine-20261121-wave2/source/` altında korundu. Üretilmiş başarısız test bundle'larında kalan, aynı ad+SHA'ya sahip 772 kopya da generated/ altında korundu. Başka dosyalar veya izlenen metinler değiştirilmedi. Kaynak ve aktif build bundle'larında bu kopyalar sıfırlandıktan sonra iki seçili test grubu tekrar geçti; 3–4 gerçek fixture da üretim kodunda değişiklik gerekmeden doğrulandı. Manifestler karantina klasöründe.

Bu, kaynak klasöründeki yedek/çatışma kopyalarının pakete girebildiğini gösterir. Git commit kapsamına bu kopyalar dahil değildir; ileride aynı kopyalar yeniden oluşursa üretim/test paketi öncesi tekrar denetlenmeli.

Önceki SeriesManager uygunluk testi bu seçili koşuya dahil edilmedi; çözülmüş sayılmıyor. ReadingSequenceReport birebir tekrar ölçümündeki seed sorunu da upstream halinde korunuyor; testin geçmesi o ölçüm bulgusunu kapatmaz.

# Okuyucu — GPT‑6.1 ile tasarım değerlendirmesi

18 Kasım 2026. Kullanıcı, kodlamadan önce yukarıdaki okuma örneği temel alınarak okuyucunun GPT‑6.1 ile yeniden düşünülmesini ve burada görselleştirilmesini istedi. `gpt-6.1-sol` tasarım ajanı mevcut okuyucuyu inceleyip `BRIEF.md` dosyasını hazırladı. Ana ajan bu brief ve kullanıcı yönüyle etkileşimli önizlemeyi hazırladı. Durum: kullanıcı değerlendirmesi bekleniyor; uygulama entegrasyonu onaylanmadı.

## Gösterilen tasarım

- İki sayfalık kurmaca yerleşim örneği: ilk sayfada guaj sahne + doğrudan kâğıttaki metin; ikinci sayfada metinden sonra küçük sulama kabı/filiz çizimi.
- Önceki beğenilen görseller tekrar kullanıldı: `2026-11-17-app-illustrations/reader/scene-v1.png`, `spot-v1.png`. Bu kurmaca kız gerçek çocuk profili değildir. Yeni Ragi ya da çocuk kimliği çizilmedi.
- Kapat her zaman görünür. Favori ve Aa tek üst kapsülde; altta önceki/sonraki, konum, sayfa seçimi ve sesli okuma yerleşimi. Kitap başlığı her sayfada tekrar edilmez.
- Sayfaya dokunma ikincil araçları gizleyip gösterir. İnceleme sırasında kontrolün kullanıcı bakmadan kaybolmaması için önizlemede otomatik 4,5 sn zamanlayıcısı yok; gerçek uygulamadaki mevcut davranış uygulama aşamasında ayrıca ele alınır. Geçişteki sade hareket gerçek sayfa kıvrımının simülasyonu değildir.
- Aa: 17/19/22/26 boyutlar, Normal/Rahat/Geniş aralık, kolay okuma, beş kâğıt; tercihler sayfaya hemen yansır. Örnek yazı eklenmesi ve ayarların Yazı→Kâğıt sırası tasarım önerisidir. Diğer uygulama ayarlarını kaldırma kararı verilmedi.
- Gündüz beyaz bir öneridir; mevcut sıcak okuyucu günü token'ı henüz değiştirilmedi. Krem/Sepya/Akşam/Gece isteğe bağlı okuyucu temalarıdır. Gece resimleri bu önizlemede hafif kısılır; gerçek sanatın temalara uyumu cihazda doğrulanmalı.
- Büyük yazıda sahne küçülür. Önizlemede iç sayfa metni kırpılmaz, örnek yüzeyi büyüyebilir; bu bir sabit cihaz viewport testi değildir. Gerçek uygulamada uzun metin/AX durumunda mevcut kaydırma korunmalı.
- Sesli okuma yalnızca tarayıcıda yerel Türkçe ses varsa çalışır; yoksa önizleme dışında kısa durum notu gösterilir. Bu, uygulamanın MPSpeech bağlantısı değildir. Aile sesi, kelime kartı, masal sonu ve kapak kapsam dışıdır; kaldırılmadılar.

## Önizleme

Sohbet dosyası: `/Users/batudemir/.codex/visualizations/2026/11/17/01a1eaf7-23ab-7fc3-98ab-fc6950591be3/reader-concept-61.html`.

Ayrı önceki karakter denemesi (`2026-11-18-character-comparison`) de taslak olarak korunuyor. Kullanıcı isteği okuyucuyu yeniden tasarlamaya yöneldiği için bu turda karar/onay alınmış bir karşılaştırma sonucu sayılmıyor.

## Doğrulama ve sınırlar

HTML/JS sözdizimi, gömülü görsel yerleri ve dosya boyutu kontrol edildi. Mevcut resimler önceki araç çıktılarında incelendi. Yeni görsel üretilmedi. Tarayıcı otomasyon aracı bu oturumda başlatılamadı; önizlemenin tarayıcı ekran görüntüsü/ölçüm matrisi alınmadı. Uygulama kodu/Assets/motor/içerik değiştirilmedi; app build, test ve simülatör çalıştırılmadı. Tasarım beğenildikten sonra uygulama planı ve gerçek cihaz boyutu/erişilebilirlik doğrulaması gerekir.

## Uygulama onayı · 18 Kasım 2026

Kullanıcı önizlemeyi onaylayıp kodlamayı istedi. Sahne/spot/metin kompozisyonları, beyaz Gündüz ve canlı yazı örneği uygulandı. Görselsiz sayfada üstten başlayan kaydırılabilir metin var; eksik resim dosyası metin düzenine döner. Örnek kız/filiz çizimleri gerçek masallara atanmadı. Son doğrulama ve sınırlar `docs/READER_LAYOUT_2026-11-18.md` içinde.

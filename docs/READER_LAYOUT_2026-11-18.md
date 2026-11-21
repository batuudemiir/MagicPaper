# Okuyucu düzeni · 18 Kasım 2026

Kullanıcının onayladığı `2026-11-18-reader-concept` uygulaması. Sayfa doğrudan okuma kâğıdıdır; metin kart içine alınmaz.

- **Sahne:** mevcut yerel resim veya B2 sahnesi üstte; normal yazıda yüksekliğin en çok %40’ı, büyük yazı/erişilebilirlik/yatay ekranda daha az. iPad yatayda gerçek sahneyle mevcut çift sayfa korunur.
- **Spot:** `StoryPage.art.role == "spot"`, dolu `altText` ve mevcut resim referansı gerektirir. Çizim metnin ardından, en çok 192×128 punto, kırpılmadan gösterilir. Erişilebilirlik boyutlarında veya dar yükseklikte atlanır.
- **Metin:** üst araçların altında başlar, uzun sayfalar kayar. Eksik dosya metin düzenine döner; dünya simgesi/sahte resim alanı yoktur.

`StoryPage.art` isteğe bağlı Codable `StoryPageArt(role:altText:sourceID:)` alanıdır. Eski kayıtlarda nil; bilinmeyen veya etiketsiz rol mevcut sahne davranışına döner. Gerçek B2 sahnesi spot rolünden önce gelir. `opensAsTextOnly` sırasında tüm sanat bastırılır. Görsel açıklaması konuşulan masal metnine eklenmez. Metadata bozuksa masal kaydı okunabilir kalır.

Gündüz beyazdır; Krem/Sepya/Akşam/Gece ve kaydedilmiş seçimler korunur. Aa içinde canlı örnek, Yazı, Kâğıt ve mevcut diğer ayarlar vardır. Örnek, nefes satırlarının etkin yazı boyutu/aralığını da izler.

Kalıcı kapat, favori, sesli okuma, kelime kartı, sayfa kıvrımı ve ilerleme sözleşmeleri korunur. Yeni ağ çağrısı, paket, içerik eşleştirme veya çocuk kimliği yoktur. Demo çizimler kişiselleştirilmiş masallara atanmaz; motorun semantik sanat eşleştirmesi ayrı çalışmadır.

## Doğrulama

Statik incelemede kritik/yüksek bulgu yok; B2 önceliği ve metin açılışı regresyon testleri eklendi. `git diff --check` ve değişen okuyucu dosyalarının tasarım yasası aramaları temiz.

Final doğrulama penceresinde ilk derleme, önceden yazılmış testlerdeki eski alan adları nedeniyle durdu; testler `StoryPage.art` sözleşmesine uyarlandı. Sonraki koşuda Swift uygulama/test kaynakları derlendi ve bağlandı; `GenerateDSYMFile` disk dolmasıyla durdu (`No space left on device`). Yalnızca bu koşunun yarım kalan dSYM çıktısı kaldırılıp `DEBUG_INFORMATION_FORMAT=dwarf` ile tekrarlandı. Bu kez `MagicPaper.debug.dylib` yerel imzasında `internal error in Code Signing subsystem` oluştu; doğrudan imza tekrarında da aynı hata alındı. Testler çalışmaya başlamadı; geçen test sayısı raporlanamaz. Loglar `/tmp/MagicPaper-reader-layout-{20261118,retry,dwarf}.log`.

Simulator uygulamasına görsel kontrol aracından erişilemedi. Açık/koyu, en büyük Dynamic Type, SE/Pro Max/iPad, VoiceOver ve sesli okuma etkileşim matrisi **tamamlanmadı**. Bu çalışma kod uygulamasıdır; görsel kabul ve çalışan test doğrulaması açık kalır. Çözüm: yeterli boş disk ve çalışan yerel imza/simülatör ortamında plandaki okuyucu testlerini ve cihaz matrisini tamamlamak.

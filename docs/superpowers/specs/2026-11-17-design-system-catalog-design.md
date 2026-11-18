# Canlı tasarım sistemi kataloğu

Kullanıcının 17 Kasım'da onayladığı kapsam: mevcut tasarım dilini koruyarak bileşenlerin varyantlarını ve durumlarını canlı görmek; token kaynaklarını ve erişilebilirlik beklentilerini belgelemek.

## Tasarım

DEBUG-only SwiftUI ekranı ve doğrudan Xcode Preview. Normal uygulama gezinmesine eklenmez. RagiStudio gibi `-mpDesignSystemCatalog YES` başlatma kancasıyla açılır. Normal uygulamanın servis başlangıcı korunur; katalog kendi örneklerinde servis, gerçek profil veya kalıcılık kullanmaz. Servisten bağımsız inceleme doğrudan Preview ile yapılır.

Tek dikey kaydırma. Sistem menü Picker'larıyla kategori, Sistem/Açık/Koyu tema ve Sistem/Standart/En büyük yazı seçilir. Yalnız seçili kategori çizilir: Düğmeler, Kontroller, Yüzeyler, Tipografi, Durumlar. En büyük yazı `.accessibility5`; sistem yazısı gerçek environment'ı korur. Reduce Motion cihazın sistem ayarından gelir; environment taklidi tam sistem desteği gibi sunulmaz.

Örnekler doğrudan mevcut bileşenleri çağırır. Katalog mevcut hedef alanı, renk veya sabit yükseklik sorunlarını sarmalayıcıyla gizlemez. Düğmelerde varyantlar ve disabled/loading; kontrollerde seçili/dashed, anahtar/onay kutusu, helper/error; yüzeylerde kart/liste/bildirim/başlık; tipografide tüm roller; durumlarda seçimle tek boş veya hata örneği gösterilir. Ekranda aynı anda en çok bir Ragi vardır.

Tüm etkileşimler `@State` içinde geçicidir. Otomatik zamanlayıcı, ağ çağrısı ve veri kaydı yok. Yerel “Son işlem” satırı eylemin çalıştığını gösterir.

## Doğrulama

Kapanışta mevcut önbellekle Debug derlemesi ve mümkünse küçük/büyük iPhone, açık/koyu, AX5 görüntüleri. Release izolasyonu `#if DEBUG` sınırlarıyla incelenir. VoiceOver ve sistem Reduce Motion cihazda görülmediyse tamamlandı sayılmaz; belgede açık kalır. Ortak kontrol düzeltmeleri sonraki ayrı turdur.

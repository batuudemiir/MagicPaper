# Okuyucu tasarım karşılaştırması

19 Kasım 2026. Kullanıcı onaylı ref ve önceki HTML/BRIEF mevcut SwiftUI ile karşılaştırıldı.

| Alan | Bulgu / uygulama |
|---|---|
| Spot | Metnin altındaki küçük çizim üst başlığa taşındı; sayfanın %28 hedefi ve metin bütçesi sınırı |
| Font | Nunito600 zaten doğru; yalnız ad vurgusu 700’den 800’e alındı |
| Boyut/aralık | Dört boyut, yaş varsayılanı, nefes satırı ve velinin seçimi korunuyor; önceki kanıt 19 punto/paragraf renderıydı, yeni kanıt gerçek5–6/26/Rahat/nefes ile |
| Üst kontroller | Kalıcı X, kalp + yazılı Aa; seçili kalp tema vurgusu |
| Alt kontroller | Tam genişlik iki sıra, görünür seek tutamağı; ilk/son sayfa uçları, 64 punto gezinme ve 48 punto seek alanı |
| Ayarlar | Yazı/Kâğıt/Daha fazla ve canlı örnek mevcut; header X, çerçevesiz örnek, sade kolay okuma satırı, Nunito swatch/işaret ve AX wrapping eklendi |
| Erişilebilirlik | AX3 tavanı kaldırıldı; Aa doğal büyür; isteğe bağlı spot AX’te yok; alt çubuk/kelime kartı aynı açıklığı kullanır |

İlgili plan ve spec `docs/superpowers/` altında. Kullanıcı referans çizimi yalnız bu klasörde saklanır, üretim çocuk kimliği veya motor çizimi yerine geçmez. Yeni illüstrasyon üretilmedi; eşleme, veri ve motor değiştirilmedi.

## Son doğrulama

İlk seçili uygulama koşusu: **155 test, 1 mevcut atlama, 0 hata** (`/tmp/MagicPaper-reader-reference-final.log`; `Test-MagicPaper-2026.11.19_11-45-19-+0300.xcresult`). İlk denemede yalnız render fixture'ının ageBand eksikliği bulundu; blueprint.ageRange ile düzeltildi, üretim mapper’ı değiştirilmedi.

Görsel inceleme sonrası yalnız üç stil düzeltmesi: satır aralığı seçicisi reader’a özel açık lila token, sabit dönüş düğmesi opak beyaz zemin, dolu sesli oku simgesi. Bu sürüm derlendi fakat ilk test başlangıcı yerel CodeSign subsystem error verdi. Yalnız geçici nesne çıktıları temizlendi, Xcode’un ürettiği mevcut simülatör entitlements ile aynı ad-hoc imza yenilendi; test-without-building sonucu aşağıda kaydedilir.

XCTest gerçek SwiftUI bileşenlerini gerçek5–6 motor çıktısıyla, 26 punto/Rahat/nefes düzeninde çizer. `renders/manifest.json` test/ad/viewport ilişkisini taşır. Beş kâğıt SE375×667, ProMax440×956 gündüz/gece, AX5 portre/yatay, iPad1024×768; ayrıca ayarlar ve metin-only/geri çekilmiş chrome toplam15 görsel. Bunlar tek iPhone17Pro simülatöründe sabit viewport renderlarıdır; ayrı cihaz veya etkileşimli manuel kabul değildir. Render harness callbacks no-op; ayarlar tam panel gömülüdür, gerçek sistem yarım-sheet hareketi değildir.

Gözle kontrol: normal üst spot ve metin, gündüz/gece, AX5 Aa/alt çubuk, ayar metni ve görselsiz sayfa. AX5 kompakt yatayda metin alanı çok dardır; optional art kaldırılır ve metin kaydırılır. Uzun metin, sesli okuma, favori, kapanış, VoiceOver ve sayfa-curl jestlerinin etkileşimli uçtan uca matrisi yapılmadı; mevcut model/regresyon testleri buna eşit sayılmaz. Engine/content suite bu görevde yeniden çalıştırılmadı; motor/veri/eşleme sözleşmeleri değişmedi.

Bağımsız kod incelemesinde Aa’nın sabit48×48 ile AX5’te kesilme riski düzeltildi. Son ek stil düzeltmeleri mevcut token ve MPIcon API’siyle sınırlı. `git diff --check` temiz. Yerel görsel araç erişimi olmadığı için render kanıtı kullanıldı; testlerin PNG üretmesi piksel yerleşimi assertion’ı değildir.


**Son sürüm doğrulaması:** 58 test, 0 atlama, 0 hata; `TEST EXECUTE SUCCEEDED`. Log: `/tmp/MagicPaper-reader-reference-polish-verified.log`; sonuç: `/tmp/magicpaper-membership-build/Logs/Test/Test-MagicPaper-2026.11.19_12-04-17-+0300.xcresult`. İmza düzeltmesindeki ilk tekrar Simulated.xcent ile launch edilemedi; doğru boş app.xcent ile Xcode’un yerel simülatör imzası yenilendi ve son test koşusu geçti. Bu altyapı düzeltmesi kaynak koduna eklenmedi.

Son koşunun15 renderı dışarı aktarıldı; gündüz/gece üst çizim, SE dar metin sütunu, görselsiz sayfa ve normal/AX5 ayarlar yeniden gözle incelendi. Opak footer arkasında yazı görünmüyor; lila seçici ve dolu oynatma simgesi doğrulandı. SE’de uzun sayfa kayar; tüm metnin tek ekranda görünmesi hedeflenmedi.

- [Gündüz okuyucu](renders/reader-reference-pro-max-day.png)
- [Gece okuyucu](renders/reader-reference-pro-max-night.png)
- [Görselsiz sayfa](renders/reader-reference-text-only-day.png)
- [Aa ayarları](renders/reader-reference-settings-light.png)

# Canlı bileşen kataloğu

## Açma

Debug uygulamasını `-mpDesignSystemCatalog YES` argümanıyla başlat veya `MPDesignSystemCatalogView` Xcode Preview'ını aç. `mpDemo` gerekmez: katalog gerçek çocuk, masal veya hesap verisi kullanmaz. Uygulama üzerinden açıldığında normal AppDelegate servis başlangıcı devam eder; doğrudan Preview görünümü servislere bağımlı değildir. Release derlemesinde katalog ve başlatma kancası yoktur.

Kategori, tema ve yazı boyutu menülerini kullan. Sistem seçeneği cihazı izler; “En büyük” Dynamic Type AX5'tir. Reduce Motion ve VoiceOver sistem ayarlarından açılır. Örnekler gerçek ortak bileşenlerdir; katalog sorunlarını düzelten alternatif kopyalar içermez. Seçimler ve yazılan örnek metinler yalnız bellektedir.

## Token kaynak haritası

Bu tablo bugünkü kodun haritasıdır; kaynakları birleştirme işlemi değildir. `MPTheme.swift` tek dosya olarak bütün değerlerin sahibi değildir.

| Kategori | Gerçek kaynak | Tüketim / geçiş sınırı |
|---|---|---|
| Ham renk | `DesignSystem/MPTheme.swift` MP.Palette; `Assets.xcassets/Colors`; `DesignSystem/Pastel/MPColor.swift` | MP.C birçok semantik rengi MPColor'a yönlendirir. Ekranda yeni ham renk açma. Kapak sanatı kendi izinli paletini kullanır. |
| Semantik renk | MP.C ve MPColor | Yeni ürün kodunda AGENTS gereği MP.C tercih edilir. Mevcut Pastel bileşenleri MPColor okur. |
| Tipografi | MP.F (`MPTheme`), MPTextStyle (`Pastel/MPTypography.swift`) | Yeni metinde mevcut rolü `mpText` ile kullan. Baloo 2 başlık/kapak, Nunito diğer roller. Özel çizim fontlarını ayrı değerlendir. |
| Boşluk / boyut | MP.S (`MPTheme`), MPSpacing / MPSize (`Pastel/MPLayout.swift`) | Yeni kabukta MP.S; bileşen boyutları MPSize. Sayısal padding ekleme. |
| Yarıçap | MP.R ve MPRadius | Yeni yüzeyde semantik rolü kullan; mevcut bileşeni yeniden çizme. |
| Derinlik / gölge | MP.E, MP.Sh, mpEdge; MPShadow | Sert alt kenar mevcut imza. Ham shadow yerine mevcut mpShadow overload'u. |
| Hareket | MP.M; MPMotion; MP.M.gated (`MPBridge.swift`) | Yeni hareket MP.M ve Reduce Motion geçidinden geçer. Kontrollerdeki eski MPMotion çağrıları açık borçtur. |
| İkon / duyusal | MP.G, MPIcon, MPHaptics, MPSound | Katalog yeni haptik/ses işi başlatmaz. |

Olası birleştirme sırasında önce alias eklenir, tüketiciler bölüm bölüm taşınır, eski API ancak tüketicileri bitince kaldırılır. Bu tur değerler veya kayıtlı renk indeksleri değiştirilmez.

## Bileşen erişilebilirlik sözleşmesi

“Beklenti” kabul ölçütüdür; “mevcut” yalnız kod incelemesini belirtir. Kataloğun derlenmesi cihaz doğrulaması yerine geçmez.

| Bileşen | Beklenti | Mevcut / açık |
|---|---|---|
| MPButton | Türkçe etiket; disabled/loading etkileşimsiz; büyük yazıda büyür; uygun hedef | Label ve loading disable mevcut; hero 64, küçük boyutun dış hedefi 48. Cihaz/VoiceOver doğrulaması gerekir. |
| MPCircleButton | Eylemi anlatan label; en az 48 hedef, komşularla çakışma yok | Label mevcut; görsel 42 ve contentShape genişletmesi var. Cihazda ölçülmeli. |
| MPChip / MPSegmented | Seçim yalnız renge bağlı değil; VoiceOver seçimi söyler; yeterli hedef | Selected trait mevcut. Segment varsayılan 40; çip 38/çocuk 44. Segment hareket geçidi açık borç. |
| MPSwitchStyle | Açık/kapalı okunur; Reduce Motion korunur | Toggle trait ve Türkçe value var; doğrudan spring açık borç. |
| MPCheckbox | Etiket ve durum birlikte okunur; hedef yeterli | Selected trait var; minimum hedef ve durum anlatımı cihazda kontrol edilmeli. |
| MPTextField | Label/helper/error erişilebilir; AX5 kesilmez | Label/helper/error görselleri var; sabit 52 yükseklik açık risk. |
| MPListRow / MPRowButton | Dokunulan satır gerçek düğme; başlık tek anlaşılır eylem | MPRowButton combine/button trait ve minimum hedef içerir. MPListRow tek başına eylem değildir. |
| MPSectionHeader | Başlık rotorunda görünür | Header trait mevcut. |
| MPNotice | Hata yalnız renk ile anlatılmaz; mesaj açık | Katalog metinleri durum adını taşır; canlı duyuru için ayrıca bağlam değerlendirilir. |
| MPStateView | Tek maskot, başlık, açıklama, tek ana eylem | Boş/hata ortak yüzeyi var. Ebeveyn boş durumunda Ragi kullanılmaz. |

## Manuel kabul listesi

- Küçük ve büyük iPhone'da yatay taşma olmaması.
- Açık/koyu tema ve AX5'te bütün kategorilere erişim.
- VoiceOver ile menü etiketleri, seçili/kapalı durumları ve eylemlerin anlaşılması.
- Reduce Motion açıkken kontrol durumlarının okunabilir kalması.
- Katalogdaki etkileşimlerin gerçek profil/masal/hesap verisi yazmaması.

17 Kasım statik denetimindeki kontrol eksikleri bu katalog turunda düzeltilmez; katalog bunların sonraki doğrulamasına zemin sağlar. Tarihsel envanter: `MagicPaper_Design_System.md`; güncel denetim: `DESIGN_SYSTEM_AUDIT_2026-11-17.md`.

## Bu turun doğrulama sonucu — 17 Kasım 2026

- Yeni katalog dosyaları ve giriş noktaları Debug (`-D DEBUG`) ve Release koşullarında `swiftc -frontend -parse` ile sözdizimi kontrolünden geçti. Bu, tam tip kontrolü veya link doğrulaması değildir.
- Bağımsız statik kod incelemesinde kritik/yüksek bulgu yok; `git diff --check` temiz.
- Mevcut DerivedData ile tam Debug simülatör derlemesi denendi; RevenueCatUI çıktısı kopyalanırken disk doldu (`No space left on device`, BUILD FAILED). Uygulamanın tam derlendiği doğrulanmadı. Log: `/tmp/magicpaper-catalog-build.log`.
- Bu derleme başında bulunmayan ve denemede oluşan `Build/Products` çıktısı temizlendi. Kaynaklar ve mevcut paket checkout'ları korundu.
- Simülatör görüntüleri, etkileşim smoke kontrolü, küçük/büyük ekran matrisi, VoiceOver ve sistem Reduce Motion doğrulaması tamamlanmadı. Computer Use aracı Simulator uygulamasına erişemedi; bunun ayrıca bir arayüz otomasyon sınırı olduğu not edildi.
- Yeni unit/snapshot testi eklenmedi: sunum amaçlı DEBUG kataloğu için kaynak incelemesi ve görsel doğrulama tercih edildi; mevcut snapshot referansları değiştirilmedi.

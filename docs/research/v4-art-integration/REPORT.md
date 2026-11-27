# V4 görsel entegrasyonu

27 Kasım 2026 · Dal: `codex/v4-story-art-integration` · Taban: `codex/bes-arkadas/claude-uygulama` (`5af5e561`).

## Sonuç

35 benzersiz seçili görsel uygulama kaynaklarında: 24 nesne/mekân, 6 Tarçın pozu, 5 kimlik. Reddedilen sürümler eklenmedi. Beş yeni kimlik mevcut arkadaş seçimi bileşenine yeni asset adlarıyla bağlı; eski dosyalar korunuyor. 30 hikâye görseli, ayrı uygulama allowlist’inde 44 tam-kaynak kuralıyla eşleşiyor.

Gerçek V4 motoruyla 90 kitabın tamamında ölçüm: **21 kitap, 42 görselli sayfa, 30 farklı seçilen hikâye görseli**. Geri kalan69 kitabın bu yeni politikada görseli yok; bütün V4 kitapları/yaşlar için garanti değildir. Her kitapta en çok3 görsel; açılış/orta/kapanış pencereleri ve tekrar etmeyen dosya SHA seçimi. Metin, seed, motor seçimi ve kaynak pinleri değişmedi.

## Kayıt ve doğrulama

Yeni `P56StoryMapper.story` çağrısında bağlanır. Bütün kitap, çocuk adına göre üretilmiş metin, rendered SHA, template/parent SHA, kaynak pointer, sıra, kitap/arkadaş/mod/mekân/keşif ve payload pini doğrulanır. Eski sayfa görsellerine dokunulmaz. `StoryPage.art` policy4, dosya sürümü/SHA ve kaynak kanıtını saklar; yeniden açmada seçim yapılmaz. Reader mevcut spot düzeni, yerel checksum resolver ve arka planda küçültmeyi kullanır.

Motorun tarihsel `artApproved=false` alanları değiştirilmedi; yeni onay bu belirli app asset/kaynak çiftlerinedir. Kelime veya frekans eşlemesi runtime’da kullanılmaz.

## Doğrulama kanıtı ve sınırı

MacOS bağımsız doğrulama: gerçek StoryEngine + değiştirilmemiş policy/binder/mapper/resolver/provenance kodu ve gerçek StoryPageArt bildirimi; UIKit bağımlı üst model türleri için küçük facade. **6 test,0 hata**. Tüm90 kitap, kaynak/metin bozulması,5/6yaş, kayıtlı pin, tüm35 PNG decode/SHA, yerel test bundle çözümleme ve V1–V3 reddi kapsandı. Kaynak hashleri ve tam log bu klasörde. Facade, tam iOS uygulama testi değildir.

Gerçek iOS seçili test çalıştırması GoogleDataTransport paket indirme adımında24dakika ilerlemedi; kendi süreç143çıkışıyla durduruldu. Yerel resolved commit önbelleği eksik. Bu nedenle iOS build, gerçek Bundle.main paketleme, SwiftUI okuyucu/arkadaş ekranı ve telefon kurulumu **doğrulanmadı**. Xcode var; sandbox dışı erişim gerekiyor. Yeni iOS testleri repoda; paket erişimi sağlanınca aşağıdaki komut çalıştırılmalı.

```sh
xcodebuild -project MagicPaper.xcodeproj -scheme MagicPaper -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:MagicPaperTests/P56StoryArtPolicyTests -only-testing:MagicPaperTests/P56StoryMapperTests -only-testing:MagicPaperTests/CompanionPortraitCatalogTests -only-testing:MagicPaperTests/WholeBookArtPolicyTests -only-testing:MagicPaperTests/ReviewedDiscoveryArtPolicyTests CODE_SIGNING_ALLOWED=NO test
```

## Boyut

35 ham .mpart: 51.53MiB; seçim ekranının5PNG kopyası: 8.18MiB. Bunlar kaynak boyutlarıdır; App Store indirilen/kurulu boyut ölçümü değildir. ZIP, galeri ve araştırma görselleri app target’ına eklenmedi.

Push/main merge veya cihaza kurulum yapılmadı. Orijinal çalışma klasöründeki kullanıcı değişikliklerine dokunulmadı.

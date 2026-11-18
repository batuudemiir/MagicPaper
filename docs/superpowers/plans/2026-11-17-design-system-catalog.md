# Canlı tasarım sistemi kataloğu uygulama planı

**Tarih:** 17 Kasım 2026
**Amaç:** Mevcut SwiftUI bileşenlerinin gerçek varyant ve durumlarını açık/koyu tema ve Dynamic Type seçenekleriyle inceleyebilen, yalnız DEBUG'da bulunan canlı katalog eklemek.
**Gerekçe:** Güzel ve tutarlı okuma deneyimini korumak; tasarım kararlarını gerçek bileşen üzerinden değerlendirmek; çocuk verisini kullanmadan erişilebilirlik borçlarını görünür kılmak.
**Katman:** Yalnız app görünüm katmanı ve DEBUG başlangıç kancası. Motor, köprü, kalıcılık ve ürün gezinmesi değişmez.
**Teknoloji:** SwiftUI, mevcut MP bileşenleri, `#Preview`, mevcut `MPDebugLaunch` yaklaşımı.

## Kararlar

- Dal: `codex/design-system-catalog`, mevcut checkout; yeni worktree ve DerivedData oluşturulmaz.

- Yeni katalog gerçek bileşenleri tüketir; kopya düğme/çip/kart çizmez. Denetimde saptanan kontrol sorunlarını bu işte düzeltmez.
- Katalog iki katmandan oluşur: bölümleri ve görünüm koşullarını yöneten kök görünüm; yerel örnek durumlarını taşıyan küçük demo görünümleri. Bütün kaynak `#if DEBUG` altında kalır.
- Normal uygulama kökünde `-mpDesignSystemCatalog YES` argümanı katalog dalını splash'ten önce açar. Argüman verilmezse mevcut akış aynen sürer. Release bu dalı içermez.
- Katalog yalnız `@State` ve sabit örnek metinler kullanır. `AppStorage`, profil, masal, hesap ve abonelik servislerini okumaz/yazmaz. Yükleniyor/hata durumları ağ çağrısıyla taklit edilmez.
- `MagicPaperApp` başlangıcında AppDelegate Firebase, hesap, içerik yenileme ve metrik başlatır. Launch kancası bu normal bootstrap davranışını korur; bypass eklemek kapsam dışıdır. Yalnız katalog görünümünün kendisi servis bağımsızdır. Tamamen bağımsız inceleme için doğrudan Xcode Preview kullanılır; launch yolunun tamamen servissiz olduğu iddia edilmez.
- Bileşenlerin mevcut koyu tema eşlemesi korunur; tema seçicisi yeni bir koyu palet icat etmez. Hareket azaltma için katalogdaki düğme, bileşenlerin sistem ayarını doğrudan okuyan yollarını gizlememeli: doğrulama sistemin Reduce Motion ayarıyla yapılır.

## Dosyalar ve sıralı adımlar

### 1. Katalog kabuğu

**Yeni:** `MagicPaper/Screens/DesignSystemCatalog/MPDesignSystemCatalog.swift`

- [x] DEBUG kök görünümü ekle: tek ScrollView, yalnız seçilen kategori render. Kategoriler: Düğmeler, Kontroller, Yüzeyler (başlıklar dahil), Tipografi, Durumlar. Kategori, tema ve yazı boyutu için sistem menü Picker kullan.
- [x] Açık/koyu görünüm seçimini ve Sistem/Normal/En büyük yazı seçimini yerel state ile sun. Yazı tercihini yalnız örnek bölgesine uygula; katalog denetimleri AX5'te de erişilebilir kalsın.
- [x] Kaydırılabilir, tek sütun ve token boşlukları kullan. Uzun etiket örneklerini kesme. Bölüm başlıklarını VoiceOver header yap.
- [x] Türkçe açıklamalar, mevcut `MP.F`/`mpText`, `MP.C`, `MP.S`, `MP.R`, `MPIcon` kullan. Çıplak renk/font/padding ekleme.

**Kabul:** Katalog bağımsız oluşturulur; app environment object, profil veya ağ bağımlılığı istemez. Varsayılan görünüm gerçek uygulamanın font ve renklerini kullanır.

### 2. Gerçek bileşen örnekleri

**Yeni:** `MagicPaper/Screens/DesignSystemCatalog/MPCatalogExamples.swift` (büyürse düğme/kontrol ve içerik örneklerini ayır).

- [x] `MPButton`: primary/secondary/outline/ghost/danger, regular/small/auth/hero, disabled/loading, uzun etiket. Katalog bir vitrin olduğu için birden çok primary örneği bulunabilir; bu durum ürün ekranı kuralının örnek istisnasıdır.
- [x] `MPCircleButton`: geri/kapat ve disabled örneği; gerçek Türkçe accessibilityLabel.
- [x] `MPChip`: seçili/seçili değil, solid/dashed; dokununca yalnız yerel seçim değişir.
- [x] `MPSegmented`, `MPSwitchStyle`, `MPTextField`, `MPCheckbox`: gerçek yerel Binding'lerle etkileşim. Metin alanında normal/helper/error ve uzun içerik örnekleri. Onay kutusu gerçek rıza kaydı tutmaz.
- [x] `MPCard`, `MPListRow`/`MPRowButton`, `MPSectionHeader`, `MPNotice`: mevcut API'nin gerçek varyantları. Örnek eylemi yerel sonuç metnini değiştirir; gezinme veya servis çağırmaz.
- [x] `MPStateView`: boş ve hata iki ayrı seçilebilir sahne. Aynı görünümde birden çok Ragi çizme; sahne seçimiyle tek maskot göster. Yeni hata bileşeni icat etme.
- [x] Tipografi: sekiz rol ve eyebrow; her örneğin rol adı, font ailesi ve ölçüsü açıklamada görünsün. Yeni font tanımı ekleme.

**Kabul:** Seçim ve form durumları etkileşimlidir, kapatıp açınca sıfırlanır. Spinner örneği kalıcı örnek durumudur; görev/zamanlayıcı çalıştırmaz.

### 3. DEBUG başlangıç bağlantısı ve Preview

**Değiştir:** `MagicPaper/Screens/MPDebugLaunch.swift`, `MagicPaper/MagicPaperApp.swift`

- [x] `designSystemCatalog` bool kancasını mevcut launch defaults biçiminde ekle ve yorumda argümanı belgele.
- [x] WindowGroup DEBUG dalında kataloğu RagiStudio/splash'ten önce aç. Birlikte verilirse katalog argümanı öncelikli olsun.
- [x] Normal app bootstrap ve servis başlangıcını değiştirme; DEBUG girişinin yalnız hangi kök görünümün gösterileceğini seçtiğini koru.
- [x] Katalog dosyasına açık, koyu ve en büyük Dynamic Type için adlandırılmış `#Preview` girişleri ekle. Ragi preview'lerinde mevcut `ragiHoldsStill` ortam anahtarını kullan.

**Kabul:** `-mpDesignSystemCatalog YES` giriş veya profil ekranı göstermeden katalog açar; normal app bootstrap devam eder; `-mpDemo` gerekmez. Argümansız app normal açılır. Release kaynak dalı katalog tipine referans vermez. Dosyalar Screens senkronize grubunda olduğu için pbxproj'a elle kayıt eklenmez.

### 4. Güncel kaynak haritası ve sözleşme

**Yeni:** `docs/DESIGN_SYSTEM_CATALOG.md`
**Değiştir:** `docs/MagicPaper_Design_System.md`, `design-handoff/reference/DEMO_CHANGELOG.md`

- [x] Kataloğun Xcode Preview ve launch arg erişimini; kategori/varyant kapsamını belgele.
- [x] Token tablosunda politika API'sini ve fiilî kaynağı ayrı sütunlarda göster: renk MP.C → MPColor/assets ve MP.Palette; font MP.F ve MPTextStyle; boşluk MP.S/MPSpacing/MPSize; yarıçap MP.R/MPRadius; gölge MP.Sh/MPShadow; hareket MP.M/MPMotion. Bu tablo yeni kaynak yaratmaz ve mevcut adlandırma borcunu kapandı saymaz.
- [x] 8 çekirdek bileşen için minimum hedef, Dynamic Type, VoiceOver ve Reduce Motion sözleşmesini yaz. “Hedeflenen sözleşme” ve “bugün doğrulanan durum” ayrı olsun; 17 Kasım denetimindeki açıkları linkle.
- [x] Eski envanterin üstüne tarihsel durum uyarısı ve güncel katalog belgesine link ekle. Eski tarihsel sonuçları yeniden güncelmiş gibi yazma.
- [x] İş sonunda değişiklik günlüğüne dosyaları ve gerçek doğrulama sonucunu ekle. Başka oturumun kayıtlarını koru.

### 5. Tek kapanış doğrulaması

- [ ] Önce kaynak incelemesi: DEBUG koruması, yerel state, servis/kalıcılık bağımlılığı olmaması, normal giriş dalının korunması, ham token ihlali eklenmemesi.
- [ ] `git diff --check`.
- [ ] Planın tüm uygulama adımları tamamlandıktan sonra mevcut DerivedData önbelleğini yeniden kullanarak kurulu simülatörle bir build/çalıştırma oturumu yap; disk yaklaşık 1.1 GiB olduğundan yeni önbellek oluşturma. `xcodebuild -list` kullanma. AGENTS gereği ara adımlarda test veya simülatör çalıştırma.
- [ ] Kataloğu launch arg ile aç; varyantlara eriş, çip/segment/anahtar değiştir, forma yaz; normal/koyu/AX5 görünümde kaydırılabilirliği kontrol et. Normal açılışı da aynı kapanış oturumunda kontrol et.
- [ ] Elde bulunan küçük/büyük cihaz ve VoiceOver/Reduce Motion kontrolünü raporla; eksik cihaz ya da gözlenmeyen durumları açıkça belirt.

**Test hedefi:** Bu sunum amaçlı, kalıcılıksız katalog için uygulamayı tekrarlayan unit test ekleme. Mevcut `DesignSystemSnapshotTests` referansları değişmemeli. `testSnapshotButtons` bilinen 10 dakikalık takılma nedeniyle rastgele yeniden koşturulmaz; yeni snapshot referansları ancak kararlı koşum ve bilinçli kapsamla eklenir. Derleme ve katalog smoke kontrolü bu işin anlamlı doğrulamasıdır.

## Risk ve bağımlılıklar

- **Paylaşılan dosya:** MagicPaperApp/MPDebugLaunch yalnız minimal kanca için değişir. Diğer oturum sahipliği kontrol edilir; başkalarının değişiklikleri geri alınmaz.
- **Mevcut erişilebilirlik eksikleri:** Katalog bunları görünür kılar; örnek çevresine ek padding koyarak bileşeni düzelmiş gibi göstermemeli.
- **Başlangıç yan etkileri:** Launch yolu normal app bootstrap kullanır; yalnız standalone Preview servis bağımsızdır. AppDelegate değişikliği yapılmaz.
- **Maliyet:** Yeni uzaktan çağrı, paket veya servis yok. Örnekler cihazda deterministik çalışır.
- **Veri göçü:** Yok; depolama biçimi ve çocuk kimliği değişmez.
- **Tahmin:** S, birkaç saat. Yeni ürün ekranı veya kontrol tasarımı yok.

## Kapanış durumu

Uygulama ve belgeler yazıldı, statik inceleme/diff ve Debug/Release sözdizimi kontrolleri geçti. Tam Debug derlemesi disk dolması nedeniyle RevenueCatUI bağımlılık aşamasında başarısız; simülatör/etkileşim/cihaz erişilebilirlik matrisi açık. Kaynak kod tamam; çalıştırma kabulü bekliyor. Ayrıntı `docs/DESIGN_SYSTEM_CATALOG.md` doğrulama bölümünde.

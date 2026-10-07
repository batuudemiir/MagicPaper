# Uygulama planı

Her ekran bir iş. Her iş için kabul ölçütü aynı: ekran görüntüsüyle (390×844, @2x) yan yana bakıldığında düzen, renk, metin ve boşluklar eşleşir; `docs/SCREENS.md` içindeki tüm etkileşimler çalışır; durum görüntüleri (`state-*`) varsa her durum üretilebilir; Dynamic Type XL'de kesilme yok; VoiceOver etiketleri var.

## Faz 0 · Temel

- [ ] Nunito'yu projeye ekle, `UIAppFonts`'a yaz, `Font.custom` ile çalıştığını bir önizlemede doğrula.
- [ ] `ios/Assets.xcassets/Colors` ve `Brand` klasörlerini projenin asset catalog'una kopyala (namespace işaretli kalsın).
- [ ] `ios/DesignSystem` dosyalarını ekle, derle. Hata çıkarsa düzelt (kod derlenmeden yazıldı, bkz. CLAUDE.md).
- [ ] Bir `DesignSystemGallery` önizleme ekranı yap: tüm buton türleri, chip, segmented, switch, kart, liste satırı, notice, maskot durum görünümü. `screens/01-Marka.png` ile yan yana karşılaştır.
- [ ] `AppIcon`: `appIconLight` 1024 px kaynak (koyu varyant iOS 18 için).
- [ ] `ios/Models/StoryEngineModels.swift` ekle; `engine/fixtures/*.example.json` ile decode birim testi yaz.

## Faz 1 · Kabuk ve gezinme

- [ ] `AppRoot` durum makinesi: onboarding → kid ↔ parent (ebeveyn yalnızca kapıdan sonra).
- [ ] Çocuk kökü: `KidTabBar` + iki sekme + Yarat `fullScreenCover`.
- [ ] Ebeveyn kökü: `ParentTabs`, Onaylar rozeti, "Çocuk modu" çıkışı.
- [ ] `Route.swift` enum'larını `NavigationStack(path:)` ile bağla; `DeepLink` (`magicpaper://`) işleyicisi.
- [ ] `docs/NAVIGATION.md` tablosundaki her geçişi tıklayarak doğrula.

## Faz 2 · Başlangıç akışı

- [ ] **02 Karşılama 1** · `Main` · rota `welcome(page: 0)` · root (onboarding stack) · [ayrıntı](SCREENS.md#02-main)
- [ ] **03 Karşılama 2** · `Onboarding2` · rota `welcome(page: 1)` · page (TabView .page) · [ayrıntı](SCREENS.md#03-onboarding2)
- [ ] **04 Karşılama 3** · `Onboarding3` · rota `welcome(page: 2)` · page · [ayrıntı](SCREENS.md#04-onboarding3)
- [ ] **05 Giriş** · `Giris` · rota `signIn` · push · [ayrıntı](SCREENS.md#05-giris)
- [ ] **06 Ebeveyn onayı** · `EbeveynOnayi` · rota `parentalConsent` · push · [ayrıntı](SCREENS.md#06-ebeveynonayi)
- [ ] **07 Çocuk profili** · `ProfilOlusturma` · rota `createChildProfile(step: 1)` · push · [ayrıntı](SCREENS.md#07-profilolusturma)
- [ ] **08 Neleri sever** · `NeleriSever` · rota `createChildProfile(step: 2)` · push · [ayrıntı](SCREENS.md#08-nelerisever)
- [ ] **09 Bildirim izni** · `BildirimIzni` · rota `notificationPrePrompt` · push · [ayrıntı](SCREENS.md#09-bildirimizni)
- [ ] **10 İlk masal hazırlanıyor** · `IlkMasal` · rota `firstStoryGenerating` · fullScreen · [ayrıntı](SCREENS.md#10-ilkmasal)

## Faz 3 · Çocuk alanı

- [ ] **11 Ana sayfa (tam sayfa)** · `AnaSayfa` · rota `kid(.home)` · tab root · [ayrıntı](SCREENS.md#11-anasayfa)
- [ ] **12 Benim köşem (tam sayfa)** · `BenimKosem` · rota `kidCorner` · fullScreen (avatar) · [ayrıntı](SCREENS.md#12-benimkosem)
- [ ] **13 Kahraman oluşturucu (tam sayfa)** · `KahramanOlustur` · rota `heroEditor` · push · [ayrıntı](SCREENS.md#13-kahramanolustur)
- [ ] **14 Masal ailem** · `MasalAilem` · rota `storyFamily` · push · [ayrıntı](SCREENS.md#14-masalailem)
- [ ] **15 Yeni kelimelerim** · `YeniKelimeler` · rota `newWords` · push · [ayrıntı](SCREENS.md#15-yenikelimeler)
- [ ] **16 Kitaplık (tam sayfa)** · `Kutuphane` · rota `kid(.library)` · tab root · [ayrıntı](SCREENS.md#16-kutuphane)
- [ ] **17 Masal aksiyonları** · `MasalAksiyon` · rota `storyActions(id)` · sheet (.medium) · [ayrıntı](SCREENS.md#17-masalaksiyon)
- [ ] **18 Seri masal** · `SeriMasal` · rota `series(id)` · push · [ayrıntı](SCREENS.md#18-serimasal)

## Faz 4 · Masal oluşturma ve okuma

- [ ] **19 Yarat 1 · Dünya (tam sayfa)** · `SihirbazNerede` · rota `create(step: .world)` · fullScreen · [ayrıntı](SCREENS.md#19-sihirbaznerede)
- [ ] **20 Yarat 2 · Ayarla (tam sayfa)** · `SihirbazNasil` · rota `create(step: .details)` · push (create stack) · [ayrıntı](SCREENS.md#20-sihirbaznasil)
- [ ] **21 Masal yazılıyor** · `Uretim` · rota `generating(jobId)` · push (create stack) · [ayrıntı](SCREENS.md#21-uretim)
- [ ] **22 Okuyucu · görselli** · `OkuyucuGorselli` · rota `reader(id, mode: .illustrated)` · fullScreen · [ayrıntı](SCREENS.md#22-okuyucugorselli)
- [ ] **23 Okuyucu · sadece metin** · `Okuyucu` · rota `reader(id, mode: .text)` · fullScreen · [ayrıntı](SCREENS.md#23-okuyucu)
- [ ] **24 Okuma ayarları** · `OkumaAyarlari` · rota `readerSettings` · sheet · [ayrıntı](SCREENS.md#24-okumaayarlari)
- [ ] **25 Masal sonu** · `MasalSonu` · rota `storyEnd(id)` · push (reader stack) · [ayrıntı](SCREENS.md#25-masalsonu)
- [ ] **26 Uyku modu** · `UykuModu` · rota `sleepMode` · fullScreen · [ayrıntı](SCREENS.md#26-uykumodu)
- [ ] **27 iPad · yatay okuyucu** · `iPadOkuyucu` · rota `reader(id, mode: .illustrated) [iPad]` · fullScreen (regular width) · [ayrıntı](SCREENS.md#27-ipadokuyucu)

## Faz 5 · Ebeveyn alanı

- [ ] **28 Ebeveyn kapısı** · `EbeveynKapisi` · rota `parentGate` · fullScreen · [ayrıntı](SCREENS.md#28-ebeveynkapisi)
- [ ] **29 Ebeveyn · Özet (tam sayfa)** · `EbeveynPaneli` · rota `parent(.summary)` · tab root · [ayrıntı](SCREENS.md#29-ebeveynpaneli)
- [ ] **30 Ebeveyn · Onaylar (tam sayfa)** · `OnayBekleyenler` · rota `parent(.approvals)` · tab root · [ayrıntı](SCREENS.md#30-onaybekleyenler)
- [ ] **31 Ebeveyn · Güvenlik (tam sayfa)** · `IcerikGuvenligi` · rota `parent(.safety)` · tab root · [ayrıntı](SCREENS.md#31-icerikguvenligi)
- [ ] **32 Ebeveyn · Ayarlar (tam sayfa)** · `Ayarlar` · rota `parent(.settings)` · tab root · [ayrıntı](SCREENS.md#32-ayarlar)
- [ ] **33 Kendi sesin** · `SesKaydi` · rota `voiceRecording` · push · [ayrıntı](SCREENS.md#33-seskaydi)
- [ ] **34 Aile üyeleri** · `AileUyeleri` · rota `familyMembers` · push · [ayrıntı](SCREENS.md#34-aileuyeleri)
- [ ] **35 Masal kitabı** · `KitapSiparisi` · rota `bookExport` · push · [ayrıntı](SCREENS.md#35-kitapsiparisi)
- [ ] **36 Aileyle paylaş** · `Paylas` · rota `shareLink` · push · [ayrıntı](SCREENS.md#36-paylas)
- [ ] **37 Abonelik** · `Paywall` · rota `paywall` · sheet / push (only from parent area) · [ayrıntı](SCREENS.md#37-paywall)
- [ ] **38 Abonelik bitti** · `AbonelikBitti` · rota `subscriptionExpired` · push · [ayrıntı](SCREENS.md#38-abonelikbitti)
- [ ] **39 Hesabı sil** · `HesapSil` · rota `deleteAccount` · push · [ayrıntı](SCREENS.md#39-hesapsil)

## Faz 6 · Durum ekranları

- [ ] **42 Boş kitaplık** · `BosKitaplik` · rota `kid(.library) [empty]` · state · [ayrıntı](SCREENS.md#42-boskitaplik)
- [ ] **43 Üretim başarısız** · `UretimHata` · rota `generating(jobId) [failed]` · state · [ayrıntı](SCREENS.md#43-uretimhata)
- [ ] **44 İnternet yok** · `InternetYok` · rota `kid(.home) [offline]` · state · [ayrıntı](SCREENS.md#44-internetyok)
- [ ] **45 Yıldız bitti** · `YildizBitti` · rota `create [no_stars]` · state · [ayrıntı](SCREENS.md#45-yildizbitti)

## Faz 7 · iOS yüzeyleri

- [ ] **40 Widget'lar** · `Widgetlar` · rota `yok` · WidgetKit · [ayrıntı](SCREENS.md#40-widgetlar)
- [ ] **41 Kilit ekranı ve Siri** · `KilitEkrani` · rota `yok` · ActivityKit + App Intents · [ayrıntı](SCREENS.md#41-kilitekrani)

## Faz 8 · Motor entegrasyonu

- [ ] Backend `engine/reference/engine.js` davranışını port eder; `node engine/reference/run-tests.js` ve `test-vectors.json` kabul ölçütüdür (`docs/ENGINE.md`).
- [ ] Uygulama: Yarat 2 → `StoryRequest` → iş aç → SSE/polling ile `StoryJobStatus` → Masal yazılıyor aşamaları → Okuyucu.
- [ ] Hata kodlarını ekranlara bağla (ENGINE.md tablosu).
- [ ] Onay bekleyen istekler: ebeveyn Onaylar sekmesi + çocuk tarafında "Büyüğün bakıyor" durumu (Ana sayfa durum 3).

## Faz 9 · Cila

- [ ] Haptik: buton basışı hafif, masal bitince başarı.
- [ ] Reduce Motion ve Reduce Transparency kontrolü.
- [ ] iPad: Okuyucu yatay düzen (27), diğer ekranlar ortalanmış 600 pt sütun.
- [ ] Yerelleştirme: tüm metinler `Localizable.xcstrings` içinde, anahtar = Türkçe metin.

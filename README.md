# MagicPaper

> ## 📌 Batuhan için: `irem` dalından notlar
>
> Bu bölüm yalnızca `irem` dalında. Açık olan maddeler burada durur, tamamlananlar silinir.
> `main`'e birleştirmeden önce bu bölüm kaldırılmalı.
> Son güncelleme: 19 Kasım 2026.
>
> **Karar bekleyenler**
>
> 0. **Ana sayfa başlığı değişti (İrem'in tasarım kararı, 19 Kasım).** Tam genişlik gece/gündüz sahnesi sayfanın tepesine döndü, "İyi akşamlar, İrem" sahnenin üstünde; senin 22 Ekim'de onayladığın "sahne bu akşamın kartında" düzeninin yerine. Yeni bileşen `HomeHeaderScene` (`MPHomeChrome.swift`); `HomeHeroCard`'a `showsScene` eklendi (varsayılan `true`, görüntü testleri etkilenmez), `HomeStatLine`'a `onArt`. Ekranın tek Ragi'si sahnede. Eski TestFlight'taki kilit ve avatar bilerek geri gelmedi (13 Kasım kararları). Gece yazı beyaz, gündüz koyu; karartma yok. Onaylıyorsan `main`'e alınabilir.
> 1. **Abonelik ve Paywall.** Bugün Premium hiçbir şeyi kilitlemiyor: `Capability` / `EntitlementPolicy` kurulu ama hiçbir ekran çağırmıyor, `canCreateStory` kullanılmıyor; ücretsiz kullanıcı her şeye sahip. Paywall ise Release'te kapalı olan görselli masalı satıyor ("Ayda 5 görselli masal"). "İlk 7 gün ücretsiz" StoreKit'e bakılmadan yazıyor. App Store 3.1.2 için otomatik yenileme metni ve "Aboneliği yönet" yok. Ret ve ebeveyn güveni riski.
>    Öneri: ritüel ücretsiz (her akşam bir masal, zaten 12 saat kuralı var); Premium = gün boyu masal, seriler, Masal ailem, kendi sesinle okuma, bütün klasikler ve PDF; tek plan aylık + yıllık; basılı kitap ve hediye ayrı satış. Taslak: `design-preview/mockups/paywall-oneri.html` (bugünkü hali `paywall-bugun.html`). Onaylarsan İrem kodlar.
>
> **Bilgi / düzeltilecek**
>
> 2. **`ios-build.yml` CI'da derlenemez.** `MagicPaper/Secrets.xcconfig` ve `GoogleService-Info.plist` depoda yok (doğru olarak), ama iş akışı bunları üretmiyor. Ayrıca `actions/upload-artifact@v3` ve `download-artifact@v3` GitHub'da kaldırıldı. `ekran-goruntuleri.yml` boş anahtar ve sahte Firebase dosyasıyla derliyor; aynı yol buraya da uygulanabilir.
> 3. **`main` Xcode 26.6'da derlenmiyor** (GitHub'ın `macos-latest`'i). `MagicPaperPageTurnRenderer.swift:48`: `ambiguous use of 'pi'` (`CGFloat` × `Double`). `irem`'de tür açık yazılarak düzeltildi, davranış aynı. Senin Xcode'un daha yeniyse hatayı görmüyorsundur; bu tek satır `main`'e de alınabilir.
> 4. **README eskimiş:** "Proje kuralları: üst klasördeki `CLAUDE.md`" diyor; depoda `CLAUDE.md` yok, kurallar `AGENTS.md`'de.
> 5. **`design-handoff/` eski tasarımı gösteriyor** (3 sekmeli alt çubuk, kilit simgesi, gradient düğme) ama `design-handoff/CLAUDE.md` kendini "doğruluk kaynağı" ilan ediyor. Bir ajan ona uyarsa tasarım geri gider. Öneri: başına "tarihsel, AGENTS.md kararları geçerli" notu.
>
> **`irem` dalında neler var**
>
> - `design-preview/`: Windows'ta iPhone çerçeveli önizleyici. Renk ve ölçüler uygulamanın kendi dosyalarından üretiliyor (`tools/sync-tokens.mjs`). Ayrıntı: `design-preview/README.md`.
> - `.github/workflows/ekran-goruntuleri.yml` + `Scripts/ci_screenshots.sh`: `irem` dalında `[ekran]` geçen commit'te gerçek uygulamayı simülatörde açıp ekranları çeker. Senin Mac'inde de çalışır: `bash Scripts/ci_screenshots.sh`.
> - Uygulama kodunda tek değişiklik: DEBUG açılış kancası `mpOpenPaywall` (iki satır).
> - Tasarım sistemi bulgularını (çift token kaynağı, Reduce Motion geçidi olmayan iki animasyon, 40 pt segment, sabit yükseklikli metin alanı) İrem düzeltecek; her biri değişiklik günlüğüne yazılır.

Kişiselleştirilmiş çocuk masalları için iOS uygulaması. Çocuk, masallarda tekrar eden bir karakter olur.
Metin masallar cihazda, internetsiz bir masal motoruyla yazılır (LLM yok).

## Yapı

| Klasör | İçerik |
|---|---|
| `MagicPaper/` | Uygulama (SwiftUI). `Screens/`, `Views/`, `DesignSystem/`, `Services/`, `StoryEngineBridge/` |
| `StoryEngine/` | Yerel Swift paketi: StoryEngine, CharacterEngine, VisualSystem ve masal korpusu |
| `MagicPaperTests/` | Uygulama testleri |
| `AssetCatalog/`, `Assets/`, `Tools/`, `Scripts/` | Görsel varlıklar ve içerik araçları |
| `ci_scripts/`, `.github/` | Xcode Cloud ve GitHub Actions |
| `docs/` | Belgeler — başlangıç noktası `docs/README.md` |
| `marketing/`, `promo/` | Tanıtım videoları |

Yasal sayfalar: `PRIVACY_POLICY.md`, `TERMS_OF_SERVICE.md`, `privacy.html`, `privacy_policy.html`,
`terms_of_service.html`, `accessibility.html`.

## Çalıştırma

1. `Secrets.xcconfig.template`'i `MagicPaper/Secrets.xcconfig` olarak kopyalayın, anahtarları girin (git'e girmez).
2. Firebase'in `GoogleService-Info.plist` dosyasını `MagicPaper/` altına koyun (git'e girmez).
3. `MagicPaper.xcodeproj`'u açıp `MagicPaper` şemasını çalıştırın.

Testler:

```bash
xcodebuild test -project MagicPaper.xcodeproj -scheme MagicPaper -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
cd StoryEngine && swift test
```

Proje kuralları ve tasarım yasası: üst klasördeki `CLAUDE.md`. Yol haritası: `docs/MagicPaper_Faz_Plani_Ekim.md`.

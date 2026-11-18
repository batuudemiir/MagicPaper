# MagicPaper önizleme

Windows'ta (Xcode olmadan) ekranları iPhone çerçevesinde görmek için. İki kaynak var:

| Sekme | Ne gösterir | Ne zaman |
|---|---|---|
| **Taslaklar** | `mockups/*.html`: uygulamanın gerçek renkleri, ölçüleri ve fontlarıyla çizilmiş HTML kopyası | Fikir denemek, öneri hazırlamak. Kaydedince anında yenilenir |
| **Gerçek uygulama** | `screens/real/*.png`: SwiftUI kodunun Mac simülatöründe çekilmiş ekranları | "Kod gerçekten böyle mi görünüyor?" kontrolü |

## Açmak

VS Code'da **Live Preview** eklentisi (Microsoft) kurulu olmalı. `design-preview/index.html` dosyasına sağ tıkla → **Show Preview**. Önizleme yan panelde açılır.

Üstteki düğmeler: kaynak, ekran, durum, cihaz (Pro Max / SE / ikisi yan yana), yazı boyutu (normal / en büyük).

## Renkler ve ölçüler

`tokens.css` elle yazılmaz. Uygulamanın kendi dosyalarından üretilir:

```
node design-preview/tools/sync-tokens.mjs
```

Kaynaklar: `MagicPaper/Assets.xcassets/Colors` ve `MagicPaper/DesignSystem/Pastel/MPLayout.swift`. Yazı rolleri `mockups/mp.css` içinde `MPTypography.swift`'in kopyası; orası değişirse elle güncellenir.

## Gerçek ekran görüntüleri

`.github/workflows/ekran-goruntuleri.yml`, `irem` dalına mesajında `[ekran]` geçen bir commit gönderilince GitHub'ın Mac'inde çalışır (`Scripts/ci_screenshots.sh`):

1. Uygulamayı Debug derler (gizli dosyalar yoksa boş anahtar ve sahte Firebase dosyasıyla).
2. iPhone SE ve Pro Max simülatöründe, normal ve en büyük yazıyla, DEBUG açılış kancalarıyla (`MPDebugLaunch`) her ekranı açıp fotoğraflar.
3. Görüntüleri `design-preview/screens/real/` altına yazıp `irem` dalına geri gönderir. Yerelde çekince önizleyicide görünür.

Ekran eklemek: `Scripts/ci_screenshots.sh` içindeki `SCREENS` listesine bir satır.

Notlar:

- Koyu görünüm çekilmez, uygulama yalnızca açık görünümde (`UIUserInterfaceStyle = Light`).
- Özel depoda macOS dakikası 10 kat sayılır (ücretsiz planda ayda yaklaşık 200 gerçek dakika; bir tur yaklaşık 20-30 dakika). Bu yüzden yalnızca `[ekran]` ile çalışır.
- Gerçek Firebase dosyası istenirse Batuhan depo ayarlarına `GOOGLE_SERVICE_INFO_PLIST` adlı gizli değer olarak ekleyebilir; gerekmez.
- Batuhan Mac'inde aynı betiği doğrudan çalıştırabilir: `bash Scripts/ci_screenshots.sh`.

# Alt çubuk için resimli ikonlar: görsel promptları

Durum: promptlar hazır, görseller bekleniyor (14 Ekim 2026).

Resimli ikon yalnızca **seçili** sekmede görünür. Seçili olmayan sekmeler bugünkü sade çizgi ikonlarda (`MPIcon`) kalır. Yarat bugünkü mor hap ve artı olarak kalır, ona görsel gerekmiyor.

| Sekme | Görsel | Not |
|---|---|---|
| Ana sayfa | `tab-home` | bacası tüten küçük ev |
| Günlük | `tab-gunluk` | gülen güneş |
| Kitaplık | `tab-library` | rengârenk kitap sırtları |
| Köşem | görsel yok | çocuğun kendi avatarı (`AvatarView`) kullanılacak; maskot kuralı gereği Ragi çubukta yer almaz |

## Teslim biçimi

- 1024 × 1024 PNG, **saydam zemin**. Araç saydam veremiyorsa düz beyaz `#FFFFFF` zemin; zemini ben temizlerim.
- Her ikon ayrı dosya. Önce dördünü aynı karede üret (tutarlılık için), beğenilen seti tek tek yeniden üret.
- Ekranda 26 pt (≈ 78 px) görünecek: küçültünce de okunmalı. Bu yüzden ince ayrıntı, yazı, küçük figür yok.

## Ortak stil (her prompta eklenir)

```
Style: a single children's picture-book icon, soft gouache illustration with a subtle paper grain, warm and handcrafted, premium and calm. Chunky, simple rounded shapes that stay readable when shrunk to 78 pixels. Thin warm dark-plum outline (#2E1E3E) around the main shapes. Soft top-left light, gentle inner shading, no hard gloss. Limited palette: royal purple #6A47B8, lavender #8F6BD6, soft rose #E37E9E, honey yellow #EABA4C, coral #EC8D69, sage green #5CAF9B, cream #FFF8EE. Centered, front three-quarter view, the object fills about 80% of the square, transparent background, no ground shadow, no text, no letters, no numbers, no characters or animals, no frame, no glow, no neon, no 3D render, no glossy plastic look.
```

## 1. Set (önce bunu üret)

```
A set of three matching app tab icons in a 3-column row on a transparent background, evenly spaced, same size and same style: (1) a tiny cozy house with a purple roof, a round window glowing warm yellow and a chimney with one small curl of smoke; (2) a smiling sun with soft rounded rays and rosy cheeks; (3) three chunky book spines standing side by side in purple, rose and sage, one leaning slightly. [ORTAK STİL]
```

## 2. Ana sayfa: `tab-home`

```
App tab icon: a tiny cozy storybook house. Rounded walls in cream #FFF8EE, a soft purple roof #6A47B8, one round window glowing honey yellow #EABA4C, a small rounded door in coral #EC8D69, a short chimney with a single gentle curl of smoke. Friendly and warm, like a home in a bedtime story. [ORTAK STİL]
```

## 3. Günlük: `tab-gunluk`

```
App tab icon: a cheerful smiling sun. A round honey-yellow face #EABA4C with closed happy eyes and small rosy cheeks #E37E9E, surrounded by eight short rounded rays in a slightly deeper yellow. Calm and kind, not cartoon-loud. [ORTAK STİL]
```

## 4. Kitaplık: `tab-library`

```
App tab icon: three chunky book spines standing side by side, purple #6A47B8, soft rose #E37E9E and sage green #5CAF9B, different heights, the last one leaning gently on the others. Each spine has one simple cream band, no lettering. [ORTAK STİL]
```

## İstenirse: Köşem yedeği

Çocuğun avatarı yoksa (profil yeni açılmışsa) kullanılacak yedek:

```
App tab icon: a small cozy reading nook, a rounded lavender cushion #8F6BD6 with a tiny honey-yellow star #EABA4C resting on it. Soft and inviting. [ORTAK STİL]
```

## Gelince yapılacaklar

- Zemini temizleyip `Assets.xcassets/TabIcons/` altına @1x/@2x/@3x olarak eklerim.
- Seçili sekmede `MPIcon` yerine görsel; seçili olmayanda çizgi ikon. Geçiş çapraz solma, Hareketi Azalt'ta da anlam aynı.
- Görsel süs sayılır: `accessibilityHidden(true)`; sekmenin adı VoiceOver'da okunmaya devam eder.
- Renkli sahne ve kapakların üstünde okunurluk, en büyük Dynamic Type, iPhone SE ve Pro Max ekran görüntüsü.

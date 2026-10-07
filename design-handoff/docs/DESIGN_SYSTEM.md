# Design system: Pastel Masal

Kaynak: demo canvas v21. Kesin değerler `design-system/tokens.json` içinde; SwiftUI karşılıkları `ios/DesignSystem/`. Görsel referans: `screens/01-Marka.png` ve her ekranın PNG'si.

## İlkeler

1. **İki alan, iki dil.** Çocuk alanı sıcak krem zemin (`background.kid`), büyük dokunma alanları (en az 56 pt), yuvarlak ve renkli. Ebeveyn alanı nötr gri zemin (`background.parent`), iOS ayar düzeni, 44 pt dokunma, maskot yok.
2. **Ekranda tek birincil eylem.** Mor gradyanlı `MPButton(.primary)` bir ekranda bir kez kullanılır.
3. **Tek maskot.** Bir ekranda en fazla bir maskot, tek duygu. Ebeveyn alanında hiç yok. Ayrıntı: `docs/BRAND_AND_MASCOT.md`.
4. **Metin dili.** Türkçe, "sen" dili, kısa cümle, uzun tire (—) yok, suçlamayan hata metinleri. Prototipteki metinleri aynen kullan (`docs/SCREENS.md`).
5. **Çocuğa satın alma ya da dış bağlantı yok.** Ödeme, ayar, paylaşım ve dış linkler yalnızca Ebeveyn kapısından sonra.

## Renk

Asset catalog: `ios/Assets.xcassets/Colors` (namespace klasör, `Color("Colors/<ad>")`). Kodda her zaman `MPColor.<ad>` kullan, hex yazma.


### brand

| Token | Hex | Swift |
|---|---|---|
| brand.lavender | `#8F6BD6` | `MPColor.brandLavender` |
| brand.purple | `#5C3A8F` | `MPColor.brandPurple` |
| brand.night | `#3A2458` | `MPColor.brandNight` |
| brand.cream | `#F6E8DC` | `MPColor.brandCream` |
| brand.lilac | `#E6C7F2` | `MPColor.brandLilac` |
| brand.pink | `#F2A3C3` | `MPColor.brandPink` |
| brand.coral | `#EE7C6B` | `MPColor.brandCoral` |
| brand.star | `#F4B735` | `MPColor.brandStar` |
| brand.bagBrown | `#A97C52` | `MPColor.brandBagBrown` |
| brand.ink | `#2E1E3E` | `MPColor.brandInk` |

### background

| Token | Hex | Swift |
|---|---|---|
| background.kid | `#FFF8EE` | `MPColor.backgroundKid` |
| background.parent | `#F6F7F9` | `MPColor.backgroundParent` |
| background.surface | `#FFFFFF` | `MPColor.backgroundSurface` |
| background.sunken | `#F2EEE8` | `MPColor.backgroundSunken` |
| background.night | `#161A2E` | `MPColor.backgroundNight` |
| background.nightGlow | `#3B4370` | `MPColor.backgroundNightGlow` |

### text

| Token | Hex | Swift |
|---|---|---|
| text.primary | `#2E1E3E` | `MPColor.textPrimary` |
| text.secondary | `#6E6478` | `MPColor.textSecondary` |
| text.tertiary | `#A6A1AA` | `MPColor.textTertiary` |
| text.chevron | `#B5AFB9` | `MPColor.textChevron` |
| text.onAction | `#FFFFFF` | `MPColor.textOnAction` |
| text.parentInactiveTab | `#8E8A94` | `MPColor.textParentInactiveTab` |

### border

| Token | Hex | Swift |
|---|---|---|
| border.kid | `#E6DED2` | `MPColor.borderKid` |
| border.kidInput | `#EDE5D9` | `MPColor.borderKidInput` |
| border.kidDivider | `#F0E8DC` | `MPColor.borderKidDivider` |
| border.parent | `#E7E9EE` | `MPColor.borderParent` |
| border.parentControl | `#E2E5EA` | `MPColor.borderParentControl` |
| border.parentDivider | `#EEF0F3` | `MPColor.borderParentDivider` |
| border.dashed | `#CFC6BA` | `MPColor.borderDashed` |
| border.outline | `#E6D3F2` | `MPColor.borderOutline` |

### action

| Token | Hex | Swift |
|---|---|---|
| action.primary | `#6A47B8` | `MPColor.actionPrimary` |
| action.gradientTop | `#9C7BE3` | `MPColor.actionGradientTop` |
| action.gradientBottom | `#5C3A8F` | `MPColor.actionGradientBottom` |
| action.soft | `#EFE6F7` | `MPColor.actionSoft` |
| action.pressedText | `#3A2458` | `MPColor.actionPressedText` |
| action.disabled | `#D9D2C7` | `MPColor.actionDisabled` |

### status

| Token | Hex | Swift |
|---|---|---|
| status.success | `#4E9A4A` | `MPColor.statusSuccess` |
| status.successSoft | `#E3F2D9` | `MPColor.statusSuccessSoft` |
| status.warning | `#B58200` | `MPColor.statusWarning` |
| status.warningSoft | `#FFF4D6` | `MPColor.statusWarningSoft` |
| status.warningBorder | `#F5DE9A` | `MPColor.statusWarningBorder` |
| status.danger | `#D64545` | `MPColor.statusDanger` |
| status.dangerSoft | `#FDE4E2` | `MPColor.statusDangerSoft` |
| status.dangerDisabled | `#F3D0CD` | `MPColor.statusDangerDisabled` |
| status.streak | `#F08A3C` | `MPColor.statusStreak` |
| status.starIcon | `#E9A812` | `MPColor.statusStarIcon` |

### world

| Token | Hex | Swift |
|---|---|---|
| world.lav.soft | `#EEE5FB` | `MPWorldTone.lav.soft` |
| world.lav.deep | `#8B6BD6` | `MPWorldTone.lav.deep` |
| world.pink.soft | `#FCE3EA` | `MPWorldTone.pink.soft` |
| world.pink.deep | `#E06A92` | `MPWorldTone.pink.deep` |
| world.yellow.soft | `#FFF1C2` | `MPWorldTone.yellow.soft` |
| world.yellow.deep | `#D9A21B` | `MPWorldTone.yellow.deep` |
| world.green.soft | `#E3F2D9` | `MPWorldTone.green.soft` |
| world.green.deep | `#4E9A4A` | `MPWorldTone.green.deep` |
| world.sky.soft | `#E1EEFB` | `MPWorldTone.sky.soft` |
| world.sky.deep | `#2E80CF` | `MPWorldTone.sky.deep` |
| world.peach.soft | `#FFE7D6` | `MPWorldTone.peach.soft` |
| world.peach.deep | `#E07A3E` | `MPWorldTone.peach.deep` |
| world.mint.soft | `#DDF3EE` | `MPWorldTone.mint.soft` |
| world.mint.deep | `#2E9B86` | `MPWorldTone.mint.deep` |
| world.gray.soft | `#ECEEF2` | `MPWorldTone.gray.soft` |
| world.gray.deep | `#6B7280` | `MPWorldTone.gray.deep` |

### reader

| Token | Hex | Swift |
|---|---|---|
| reader.day.background | `#FFF8EE` | `ReaderTheme.day.background` |
| reader.day.text | `#2E1E3E` | `ReaderTheme.day.text` |
| reader.day.secondary | `#6E6478` | `ReaderTheme.day.secondary` |
| reader.day.track | `#ECE5DA` | `ReaderTheme.day.track` |
| reader.day.heroName | `#6A47B8` | `ReaderTheme.day.heroName` |
| reader.day.wash | `#FFE9A8` | `ReaderTheme.day.wash` |
| reader.sepia.background | `#F6ECD9` | `ReaderTheme.sepia.background` |
| reader.sepia.text | `#3B2A18` | `ReaderTheme.sepia.text` |
| reader.sepia.secondary | `#6E5A44` | `ReaderTheme.sepia.secondary` |
| reader.sepia.track | `#E5D6BC` | `ReaderTheme.sepia.track` |
| reader.sepia.heroName | `#9A5B1E` | `ReaderTheme.sepia.heroName` |
| reader.sepia.wash | `#F0D9A8` | `ReaderTheme.sepia.wash` |
| reader.night.background | `#1E2238` | `ReaderTheme.night.background` |
| reader.night.text | `#ECEAF6` | `ReaderTheme.night.text` |
| reader.night.secondary | `#B3B0C8` | `ReaderTheme.night.secondary` |
| reader.night.track | `#41476E` | `ReaderTheme.night.track` |
| reader.night.heroName | `#CDB6F2` | `ReaderTheme.night.heroName` |
| reader.night.wash | `#3B4370` | `ReaderTheme.night.wash` |

Gradyan: birincil buton ve Yarat butonu `LinearGradient.mpPrimary` (`action.gradientTop` → `action.gradientBottom`, yukarıdan aşağı).
Karanlık mod: uygulama kendi temasını yönetir (okuyucunun Gece teması ve Uyku modu hariç her yer açık). `UIUserInterfaceStyle = Light` öner.

## Tipografi

Yazı tipi Nunito (variable, `assets/fonts`). `Info.plist` → `UIAppFonts`: `Nunito-Variable.ttf`, `Nunito-Italic-Variable.ttf`. Kullanım: `Text("…").mpText(.title1)`. Dynamic Type için `Font.custom(_:size:relativeTo:)` kullanılıyor; büyük boyutlarda kartlar dikey büyür, kesilmez.

| Stil | Boyut | Ağırlık | Satır | Kullanım |
|---|---|---|---|---|
| `.display` | 30 | black | 1.15 | Masal bitti, büyük kutlama başlığı |
| `.largeTitle` | 28 | black | 1.15 | Ebeveyn kök sayfa başlıkları (Özet, Ayarlar) |
| `.title1` | 26 | black | 1.15 | Ekran başlığı (h1): Karşılama, Sihirbaz, Onay |
| `.title2` | 24 | black | 1.15 | Durum ekranı başlıkları, ikincil h1 |
| `.title3` | 22 | black | 1.2 | Hero kart başlığı, ebeveyn alt sayfa başlığı |
| `.navTitle` | 21 | heavy | 1.2 | Topbar ortalı başlık |
| `.headline` | 19 | black | 1.25 | Bölüm başlığı (sec) |
| `.cardTitle` | 17 | black | 1.25 | Kart başlığı, seçenek adı |
| `.button` | 16 | heavy | 1.0 | Birincil buton etiketi |
| `.body` | 15 | semibold | 1.5 | Gövde metni (p) |
| `.bodyStrong` | 15 | heavy | 1.4 | Satır başlığı (row title) |
| `.callout` | 14 | heavy | 1.35 | Chip, ghost buton, link |
| `.footnote` | 13 | bold | 1.4 | Satır açıklaması, meta |
| `.caption` | 12 | heavy | 1.35 | Rozet, küçük not, tab etiketi |
| `.eyebrow` | 12 | black | 1.2 | BÜYÜK HARF üst etiket (KALDIĞIN YERDEN) |
| `.tabLabel` | 12 | bold | 1.0 | Sekme etiketi (aktifken black) |
| `.story` | 19 | semibold | 1.7 | Okuyucu metni (yaşa göre 18 ile 24) |
| `.storyLarge` | 26 | bold | 1.7 | iPad okuyucu metni |

## Boşluk, köşe, gölge, boyut

**Boşluk** (`MPSpacing`): xxs 4, xs 6, sm 8, md 12, lg 16, xl 20, xxl 24, xxxl 32, screenH 20, screenTop 52, screenBottom 24, sectionGap 22

**Köşe** (`MPRadius`): xs 8, sm 12, md 14, input 18, tile 22, card 24, cardLarge 26, hero 30, sheet 32, pill 999. Köşeler `.continuous` stil.

**Gölge** (`.mpShadow(_:)`):

| Ad | Renk | Opaklık | y | blur |
|---|---|---|---|---|
| card | `#2D2A32` | 0.06 | 6 | 18 |
| raised | `#2D2A32` | 0.1 | 12 | 28 |
| control | `#2D2A32` | 0.08 | 4 | 12 |
| primaryGlow | `#5C3A8F` | 0.32 | 10 | 22 |
| sheet | `#2D2A32` | 0.18 | -10 | 30 |

CSS blur değeri SwiftUI `radius` değerinin yaklaşık 2 katıdır; Swift tarafında `radius = blur / 2` kullanıldı.

**Boyut** (`MPSize`): buttonHeight 52, buttonHeightAuth 54, buttonHeightSmall 44, chipHeight 38, circleButton 42, headerAvatar 48, kidTabBarHeight 86, createFab 64, parentTabBarHeight 84, minTouchKid 56, minTouchParent 44, iconTile 52, segmentHeight 40, inputHeight 52

**Hareket** (`MPMotion`): tap 0.15, transition 0.25, celebration 0.4, pressScale 0.96, springResponse 0.35, springDamping 0.7. Reduce Motion açıkken ölçek ve kutlama animasyonları kapanır, yalnızca opaklık geçişi kalır.

## Bileşenler

| Bileşen | Dosya | Varyant / durum | Nerede |
|---|---|---|---|
| `MPButton` | Components/MPButtons.swift | primary, secondary, soft, outline, ghost, danger · regular 52, small 38, auth 54 · disabled, loading, pressed (0.96 ölçek + hafif haptik) | Her ekranın alt eylemi |
| `MPCircleButton` | MPButtons | 42 pt beyaz daire, ikon | Geri, kapat, kilit |
| `MPRoundActionButton` | MPButtons | büyük yuvarlak eylem | Okuyucu oynat, ses kaydı |
| `MPChip` | Components/MPControls.swift | solid / dashed (ekle), seçili | Neleri sever, Yarat 2 |
| `MPFlowLayout` | MPControls | sarmalanan satır | Chip grupları |
| `MPSegmented` | MPControls | 2–4 seçenek | Uzunluk, ton, serbest metin modu |
| `MPSwitchStyle` | MPControls | açık / kapalı | Ebeveyn ayarları |
| `MPTextField` | MPControls | normal, odak, hata, yardım metni | Profil, Giriş |
| `MPCheckbox` | MPControls | işaretli / değil | Ebeveyn onayı, Hesap sil |
| `MPCard` | Components/MPCards.swift | `.kid` (24 köşe, card gölgesi), `.parent` (20 köşe, 1 pt kenarlık, gölgesiz) | Her yer |
| `MPIconTile` | MPCards | 52 pt pastel kare ikon | Liste satırları, dünya |
| `MPListRow` + `MPGroupedList` + `MPRowDivider` | MPCards | chevron, switch, değer, rozet | Ayarlar, Güvenlik |
| `MPSectionHeader` | MPCards | başlık + sağda "Tümü" | Ana sayfa bölümleri |
| `MPPill`, `MPStatTile`, `MPBadgeCard`, `MPNotice` | MPCards | notice: info, success, warning, danger | Özet, Benim köşem, uyarılar |
| `KidTabBar` | Components/MPNavigationChrome.swift | Ana sayfa · Yarat (64 pt FAB) · Kitaplık | Çocuk kökü |
| `ParentTabs` | MPNavigationChrome | Özet · Onaylar (rozet) · Güvenlik · Ayarlar | Ebeveyn kökü |
| `KidHeader`, `HeaderWash`, `MPTopBar`, `ParentHeader` | MPNavigationChrome | kök / alt sayfa | Üst bölgeler |
| `Mascot`, `MascotImage`, `SpeechBubble`, `MascotSays`, `MPStateView` | Components/MPMascot.swift | 14 maskot | Boş, hata, karşılama |
| `WorldTile`, `StoryCover`, `TonightHeroCard` (4 durum), `StreakStrip`, `StoryProgressRing`, `StageRow`, `NewWordCard`, `ReaderTheme`, `HeroAvatarView` | Components/MPStory.swift | | Ana sayfa, Kitaplık, Okuyucu, Üretim |

Durum görüntüleri `screens/state-*.png`: Ana sayfa 4 durum, Okuyucu Sepya ve Gece, Paywall planlar, Ses kaydı kayıtta, Ebeveyn kapısı hatalı, Ebeveyn onayı onaysız, Okuyucu 4. sayfa, Onaylar karar verildi, Üretim bitti, Yarat 1 seçili, Hesap sil etkin.

## Sunum kalıpları

- Çocuk kökü: `KidTabBar` sabit, sekmeler arasında durum korunur.
- Yarat akışı: tam ekran kapak (`fullScreenCover`), içinde `NavigationStack` (Dünya → Ayarla → Masal yazılıyor → Okuyucu).
- Okuyucu: tam ekran, sayfa kaydırma `TabView(.page)`, Okuma ayarları `sheet` (medium/large).
- Masal aksiyonları ve Okuma ayarları: `sheet`, 32 köşe, krem zemin, sistem tutamacı.
- Ebeveyn kapısı: tam ekran kapak; doğru cevapta ebeveyn kökü açılır, çocuk moduna dönüşte kapanır.
- Rotalar: `ios/Navigation/Route.swift`, akış grafiği `docs/NAVIGATION.md`.

## Erişilebilirlik

- Dokunma alanı: çocukta en az 56, ebeveynde 44 pt.
- Metin kontrastı: `text.primary` krem ve beyaz üzerinde AA geçer; `text.tertiary` yalnızca ikincil etiketlerde.
- Maskot görselleri `accessibilityHidden`; konuşma balonu metni etiket olur.
- Seçili sekme ve chip'ler `.isSelected` trait taşır.
- VoiceOver okuyucuda sayfa metnini tek öğe olarak okur, "Sonraki sayfa" eylemi ekli.

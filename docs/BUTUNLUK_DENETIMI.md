# Bütünlük denetimi — marka, erişilebilirlik, bulunabilirlik

22 Ekim 2026 · `main@430dc9b` üzerinde, kod taraması. Simülatörde ekran görüntüsü
alınmadı; görsel bulgular bir sonraki turda ekran görüntüsüyle doğrulanacak.

Amaç (Batuhan, 22 Ekim): uygulamanın tüm sayfaları tek bir bütün gibi davransın,
erişilebilir ve kolay bulunur olsun, MagicPaper kimliği her ekranda, her butonda
hissedilsin.

## Özet

Token düzeyinde durum iyi: Design law grep'leri canlı kodda neredeyse boş
(`Color(hex:)` yalnızca kapak sanatında, haptik ve `fixedSize:` ihlali yok).
Bütünlüğü bozan şey token değil, **kalıp**: aynı iş için iki ya da üç bileşen var,
ortak bileşen olan yerde ekranlar kendi kalıbını yazıyor. Sorunların çoğu
"bir bileşen, her yerde" kuralıyla kapanıyor.

## Bulgular

### 1. Üst başlıklar dört farklı biçimde

| Bileşen | Nerede | Not |
|---|---|---|
| `MPTopBar` | 7 ekran (aile karakterleri, kelimeler, profil, onay) | çocuk alt sayfaları |
| `ParentHeader` (`MPNavigationChrome.swift`) | 7 ekran (ses, aile üyeleri, paylaşım, dışa aktarma, hesap, abonelik, ayarlar) | 36 pt sabit yükseklik, Dynamic Type'ta düğme başlığı ezer |
| `MPParentHeader` (`Screens/Parent/`) | Özet, Güvenlik, Ayarlar | erişilebilirlik boyutunda alt alta düşer, 44 pt |
| `GunlukHeader` | Günlük | illüstrasyonlu, kendi scrim'i |

`SettingsView` ikisini birden kullanıyor. Design law da "Üst başlıklar henüz bu
kurala dahil değil" diyor. **Öneri:** ebeveyn tarafında tek `MPParentHeader`
(kök ve alt sayfa biçimi, `ParentHeader` silinir); çocuk tarafında `MPTopBar`;
illüstrasyonlu başlıklar `MPArtHero`. Kural Design law'a eklenir.

### 2. Ortak bileşenler var ama kullanılmıyor

- `MPEmptyState` hiçbir ekranda kullanılmıyor. Kitaplık ("Burada henüz kitap
  yok") ve Aile üyeleri ("Henüz çocuk profili yok.") boş durumu düz metinle
  yazıyor. Boş durum markanın en görünür anlarından biri: Ragi + bir cümle + tek eylem.
- `MPSectionHeader` 2 yerde; 24 yerde bölüm başlığı elle `.mpText(.title3/.headline)`
  ile yazılıyor, bir kısmında `isHeader` yok (VoiceOver başlıklar arası atlayamaz).
- Illüstrasyon üstü karartma kuralı "yalnızca `MPArtHero`", ama `GunlukHeader`,
  `ClassicDetailView`, `ClassicSeriesView` scrim'i elle kuruyor.

### 3. Marka imzasıyla çelişen yerler

- **Birincil buton gradient'li** (`MPButtons.swift:72`, `LinearGradient.mpPrimary`).
  Design law: "Gradient arayüz yüzeyinde ve butonda yok." Ya buton düz #6A47B8 +
  `mpEdge` olur ya da kural değişir — tasarım kararı.
- **İki token adı:** Design law `MP.C / MP.S / MP.F` diyor, ekranların çoğu Pastel
  adlarını (`MPColor`, `MPSpacing`, `.mpText`) kullanıyor (≈52 dosyaya karşı ≈23).
  Değerler tek kaynaktan geliyor (`MP.C`, `MPColor`'a takma ad), yani renk
  tutarsızlığı yok; ama kural ile kod farklı dili konuşuyor. Hangisinin herkese
  açık API olacağı karar ister.
- Ölü kod sistem görünümüyle: `SimpleSubscriptionView` (sistem mavisi
  `.borderedProminent`, `.black`, çıplak `.shadow`) yalnızca kendi Preview'ında
  çağrılıyor → silinebilir. `MagicPaperCoverGalleryPreview` geliştirici aracı →
  `#if DEBUG` arkasına.
- `Legacy*` kontroller hâlâ 4 dosyada: `MPStreak`, `MPSheets`,
  `StoryReaderContainer`, `InterestsEditorSheet`.

### 4. Erişilebilirlik

- **Ebeveyn dokunma alanı 44 pt** (`MPSize.minTouchParent`, 21 kullanım);
  Design law ≥ 48 diyor. Token tek satırda 48'e çıkar; yerleşim kontrol edilir.
- 30–47 pt sabit yükseklikli 8 dokunma alanı (`MPNavigationChrome`, `MPNavigation`,
  `VoiceRecordingView`, `GunlukComponents`, Legacy kontroller).
- 10 yerde Dynamic Type üst sınırı (`.dynamicTypeSize(...large/xxLarge)`):
  ana sayfa çerçevesi, masal kartı, alt çubuk. Her biri ya gerekçelendirilir ya da
  erişilebilirlik boyutunda alternatif yerleşim alır.
- 6 `onTapGesture` buton olmayan öğede (okuyucu, Köşem, Hesap): `.isButton`
  trait'i ve Türkçe etiket kontrol edilecek.
- Etiket denetimi gereken ekranlar (çok dokunma, az etiket; metinli butonlar
  etiketi kendi alır, ikon-yalnız olanlar almaz): `SettingsView` (22/0),
  `FamilyMembersView` (17/2), `VoiceRecordingView` (14/5), `AccountSettings` (9/0),
  `FamilyCharacterEditor` (4/0), `StoryActionsSheet` (5/1), `PaywallView` (5/1).
- VoiceOver ile uçtan uca yürüyüş hâlâ yapılmadı (FAZ 17'den açık).

### 5. Bulunabilirlik ve Ragi

- "Her çocuk ekranında Ragi" kararına göre (16 Ekim) Ragi'siz görünen çocuk
  ekranları: masal yazma adımları (`StoryModeStep`, `CompanionStep`),
  `ClassicDetailView`, `NewWordsView`, `FamilyCharactersView`, profil seçimi ve
  profil oluşturma. Bir kısmı bilinçli olabilir (ekran başına tek Ragi, okuyucu
  sessiz); ekran görüntüsüyle tek tek karar verilecek.
- Çocuk modu ↔ ebeveyn alanı geçişi yalnızca ebeveyn kök sayfalarında görünür;
  alt sayfalardan çıkış yolu "Geri" ile. Ebeveyn kapısının çocuk tarafındaki
  yeri ekran görüntüsüyle kontrol edilecek.

## Önerilen sıra

Her adım ayrı tur, ayrı commit, adım başına simülatör görüntüsü (açık + koyu,
en büyük Dynamic Type, SE + Pro Max).

1. **Hızlı kazanımlar** — ebeveyn dokunma alanı 48; `SimpleSubscriptionView`
   silinir; kapak galerisi `#if DEBUG`; etiket eksikleri (Ayarlar, Hesap, Aile
   üyeleri, karakter düzenleyici).
   ✅ 22 Ekim: yapıldı. Etiket taraması ilk ölçümden iyi çıktı: listedeki ekranlar
   ortak satır bileşenlerinden etiket alıyor. Asıl açık `MPIcon`'du (Lucide dosya
   adını okutuyordu), merkezde gizlendi. Kapak galerisi zaten `#if DEBUG` içindeydi.
2. **Tek başlık** — `ParentHeader` → `MPParentHeader`; Design law'a başlık kuralı.
3. **Tek boş durum + bölüm başlığı** — `MPEmptyState` (Ragi ile) Kitaplık ve Aile
   üyelerinde; elle yazılmış bölüm başlıkları `MPSectionHeader`'a.
4. **Illüstrasyon başlıkları** — Günlük ve klasik detay/seri `MPArtHero`'ya.
5. **Legacy kontrollerin emekliliği** — 4 dosya.
6. **Ragi ve ebeveyn kapısı** — ekran görüntüsüyle ekran ekran karar.
7. **VoiceOver yürüyüşü** — ana akışlar: ilk açılış, masal yazma, okuma, kitaplık,
   ebeveyn alanı.

Tasarım kararı bekleyenler: birincil butonun gradient'i (bulgu 3) ve
token adlarının hangisinin kural olacağı (bulgu 3).

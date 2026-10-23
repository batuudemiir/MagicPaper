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
   ✅ 22 Ekim: yapıldı. Çocuk kök sekmelerinin başlıkları (`KidHeader` çağrılmıyor, her
   sekme kendi başlığını yazıyor) ayrı tur.
3. **Tek boş durum + bölüm başlığı** — `MPEmptyState` (Ragi ile) Kitaplık ve Aile
   üyelerinde; elle yazılmış bölüm başlıkları `MPSectionHeader`'a.
   ✅ 22 Ekim: yapıldı, ölçüm düzeltildi. Ragi'li boş durum zaten `MPStateView`'dı
   (Kitaplık, seri sonu, hata, onay); kullanılmayan eski `MPEmptyState` silindi.
   Ragi ebeveyn alanında yok (16 Ekim), Aile'nin boş satırı liste satırı oldu.
   "24 elle yazılmış başlık"ın çoğu kart başlığıydı; gerçek bölüm başlıkları
   `MPSectionHeader`'da birleşti.
4. **Illüstrasyon başlıkları** — Günlük ve klasik detay/seri `MPArtHero`'ya.
   ✅ 23 Ekim: yapıldı. `MPArtHero` sabit yükseklik aldı; karartması düz koyu
   bloktan Günlük'ün onaylı geçişine yaklaştırıldı (`MP.Scrim.mid` → `solid`).
   Açık: Günlük vitrininin tepesindeki krem açma (başlık arkası) hâlâ elle;
   karanlık slaytta "Günlük" yazısı en büyük yazıda soluk.
5. **Legacy kontrollerin emekliliği** — 4 dosya.
   ✅ 23 Ekim: arayüzdeki Legacy bileşenler bitti (`LegacyMPButton`, `LegacyMPChip`,
   `LegacyMPCard`, `MPPressableCard`, `LegacyMPListRow`, `LegacyMPRowDivider`).
   Ölçüm düzeltmesi: `MPStreak`'teki "Legacy" eski okuma defterinin taşınması,
   `LegacyStoryReaderContainer` okuyucunun geri dönüş anahtarı; ikisi de arayüz
   kontrolü değil, bilerek kaldı.
6. **Ragi ve ebeveyn kapısı** — ekran görüntüsüyle ekran ekran karar.
   ✅ 23 Ekim: incelendi ve onaylanan öneriler uygulandı (mod seçimi, Masal ailem,
   profil seçimi, Yeni kelimelerim'e Ragi; Günlük'e kilit; Design law'a Ragi kuralı).
   Açık: `MPModeSwitch` kararı.
7. **VoiceOver yürüyüşü** — ana akışlar: ilk açılış, masal yazma, okuma, kitaplık,
   ebeveyn alanı.

Tasarım kararı bekleyenler: birincil butonun gradient'i (bulgu 3) ve
token adlarının hangisinin kural olacağı (bulgu 3).

## 6. adım: Ragi ve ebeveyn kapısı (23 Ekim 2026)

iPhone 17 Pro, açık tema, normal yazı; görüntüler `docs/butunluk/`. Ölçüt
16 Ekim kararı: her çocuk ekranında Ragi görünür, ekran başına tek Ragi,
ebeveyn alanında yok.

### Ragi bugün nerede

Var: Ana sayfa (sahnede), Kitaplık (karşılama balonu), Benim köşem (karşılama),
Günlük (sayfa sonu gece bölgesi), masal hazırlanırken, masal sonu, hata,
boş durumlar (`MPStateView`), uyku modu, ilk açılış, profil oluşturmanın
2. adımı, Yeni kelimelerim (yalnız boşken), paywall.

### Ragi'siz çocuk ekranları ve öneri

| Ekran | Görüntü | Öneri |
|---|---|---|
| Masal yaz › mod seçimi ("İrem için nasıl bir masal?") | `01_mod_secimi.png` | **Ekle.** "Bana sürpriz yap" ile "Devam et" arasında büyük boşluk var. `MascotSays(.curious)`: "Bu akşam ne dinlemek istersin?" Masal yazmanın ilk adımı markanın en güçlü anı. |
| Masal yaz › "Masalda kimler olsun?" | `02_kimler_olsun.png` | **Ekleme.** Ekran dolu, seçim listesi uzun; aynı akışta bir önceki adımda ve hazırlanırken Ragi zaten var. Akış başına bir Ragi yeter. |
| Masal ailem | `03_masal_ailem.png` | **Ekle.** Sayfanın alt yarısı boş. Kartların altında `MascotSays(.waving)`: "Masallarına kimi eklemek istersin?" |
| Profil oluşturma 1. adım ("Yeni profil") | `07_yeni_profil.png` | **Ekleme.** Ebeveyn dolduruyor; avatar önizlemesi ekranın yüzü. 2. adımda Ragi var. |
| Profil seçimi (açılışta, birden çok çocuk) | görülmedi | **Ekle (küçük).** "Bugün kim okuyor?" balonu; çocuğun gördüğü ilk ekran. |
| Klasik detay / seri | `06_klasik_detay.png` | **Ekleme, istisna yaz.** Boyalı sahne ekranın kahramanı; Ragi onunla yarışır. |
| Yeni kelimelerim (dolu liste) | görülmedi | **Ekle (küçük).** Boş hâldeki Ragi dolu listede de başlığın yanında küçük kalsın. |
| Okuyucu | — | **Ekleme, istisna yaz.** Masal sayfasında Ragi yok; masal sonunda var. |

Önerilen kural cümlesi (Design law'a): "Her çocuk ekranında bir Ragi; istisna:
okuyucu sayfaları, klasik detay/seri sahnesi, ebeveyn kapısı ve bir akışın
Ragi'li adımından hemen sonraki seçim adımı."

### Ebeveyn kapısı nerede

- **Giriş:** Ana sayfa, Kitaplık ve Benim köşem başlığında sağ üstte kilit
  (`lock`). **Günlük'te yok** (yalnız arama); dört çocuk sekmesinin biri
  kapısız. Öneri: Günlük başlığına aramanın yanına aynı kilit.
- **Bağlama bağlı kapılar:** klasik paylaşma, Masal ailem düzenleme,
  masal eylemleri, hesap girişi, aile daveti bağlantısı. Doğru yerde.
- **`MPModeSwitch` kullanılmıyor.** 13 Ekim kararıyla cam gezinme kontrolü
  olarak tanımlandı, ama yalnız kendi önizlemesinde çağrılıyor. Ya ebeveyn
  alanının alt çubuğunun yanına bağlanmalı ya da kural ve bileşen kaldırılmalı.
  **Karar Batuhan'da.**

### Kapı ekranının kendisi (`05_ebeveyn_kapisi.png`)

✅ 23 Ekim: 1–4 düzeltildi (aşağıdaki kayıt). Benim köşem saat çubuğu taşması da kapandı; Ana sayfa ve Kitaplık 16 Ekim kararıyla şeritsiz kaldı.

1. **Geri düğmesi saat çubuğunun altında** (üst güvenli alan yok sayılmış).
   Hata; düzeltilmeli.
2. **İki çıkış:** sol üstte "Geri" ve altta "Geri dön". Tek çıkış kalmalı
   (öneri: alttaki "Geri dön" kalsın, üstteki gitsin ya da tersi; tasarım kararı).
3. **"Üç yanlış denemeden sonra 30 saniye beklenir." klavyenin altında**
   kalıyor; bekleme sayacı da orada. Klavye açıkken görünür olmalı.
4. Kalkan dairesi gök mavisi (`sky`), ekranın geri kalanı mor; marka rengi
   tek. Öneri: lavanta.
5. Ragi: kapı eşik ekranı, çocuk görür. Öneri: Ragi yok (istisna listesinde);
   ton sakin kalıyor, "büyükler için" mesajını maskot yumuşatmasın.

### Yan bulgu

- **Benim köşem kaydırılınca içerik saat çubuğunun altına giriyor**
  (`04_kosem_saat_cubugu.png`); Günlük'teki `GunlukStatusBarBackdrop` burada yok.
- Masal ailem'de geri düğmesi lavanta zeminde neredeyse görünmüyor (lavanta
  üstüne lavanta daire).

### `MPModeSwitch` seçenekleri (23 Ekim 2026)

Geçmiş: anahtar 7 Ekim'e kadar Ana sayfa ve ebeveyn başlığında sağ üstteydi;
FAZ 17 Pastel tasarımı (ce07158, 58a7d2f) yerine kilidi ve "Çocuk modu"
kapsülünü koydu. 13 Ekim'de yalnızca cam kuralının listesine adı yazıldı.
Karşılaştırma: `butunluk/08_mod_anahtari_karsilastirma.png` (B geçici örnekti,
geri alındı).

- **A · Kaldır (öneri):** kilit ve "Çocuk modu" kalır, `MPModeSwitch` silinir,
  CLAUDE.md cam kuralından adı düşer. Yazılı etiket ebeveyn için daha açık;
  kilit çocuğa yalnızca "kapalı" der, çocuğun dokunmaya davet edildiği bir
  anahtar yok.
- **B · Geri bağla:** iki modda da sağ üstte aynı cam anahtar (yüz / kalkan).
  Tutarlı ve tek yer; ama yazısız simgeler, çocuk ekranında görünür bir
  "ebeveyn" anahtarı, Pastel tasarımın kararını geri alır.

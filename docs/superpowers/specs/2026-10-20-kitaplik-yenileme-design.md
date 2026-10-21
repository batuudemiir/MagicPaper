# Kitaplık yenileme (20 Ekim 2026)

## Neden
Kitaplık eski dilde kalmıştı (krem zemin, degrade kartlar, tek ızgara). Ana sayfa,
Benim köşem ve Günlük Pastel dile geçti. Hedef: aynı dil, marka hissi, düzgün
kategoriler, aranan kitabın kolay bulunması.

## Batuhan'ın kararları
- İçerik: çocuğun kendi masalları **ve** Günlük'ten açtığı klasikler.
- Kategori ekseni: mod rafları (Uyku öncesi · Yeni şeyler öğrenelim · Maceraya
  çıkalım), sonra Favoriler ve Klasikler; ayrıca Yarım kalanlar süzgeci.
- Kapak: klasikler Günlük'teki boyalı kapaklarıyla; kendi masalları kâğıt
  mozaiğiyle. Sırt ve bant denendi, kaldırıldı. Bütünlük biçimden gelir: hepsi
  Günlük rafının ölçüsünde (128 × 176), aynı köşe (`MPRadius.md`) ve sert alt
  kenar; başlık kapağın altında, her kartta iki satırlık yer (kartlar eş boy).
- `StoryCoverDefault` (her metin masalında aynı boyalı görsel) silindi.

## Düzen
Başlık + kilit · Ragi (okuyor) ve kitaplık özeti · arama · süzgeç çipleri ·
Kaldığın yerden (en fazla 2) · Serim (`SeriesCard`) · mod rafları · Favoriler ·
Klasikler. Çip ya da rafın "Tümü" bağlantısı → o kategorinin iki sütun ızgarası
(en büyük yazıda tek sütun). Arama ızgarada sonuç verir; başlık, çocuk adı, mod
ve dünya adında arar (Türkçe katlama).

Kapak rozeti tek yerde: yarım → seri bölümü → favori. Kendi masalı → Masal
aksiyonları; devam kartı ve klasik → doğrudan okuyucu.

## Mimari
- `Screens/Library/LibraryShelfModel.swift`: saf model (raflar, süzgeçler,
  sıralama, arama, rozet). Görünüm yalnızca veri değişince kurar.
- `Screens/Library/LibraryComponents.swift`: arama, devam kartı, raf, ızgara.
- `DesignSystem/Pastel/MPBookCover.swift`: `MPBookCover`, `MPBookCard`.
- Test: `MagicPaperTests/LibraryShelfModelTests.swift`.

## Açık
- Masal başına illüstrasyon setleri (ArtKit) teslim edilince kendi masalı o
  kapağı alır (`LibraryShelfModel.coverArt` zaten önce onu dener).
- Arkadaş (companion) adıyla arama yok: adlar katalogda, ayrı iş.

## Güncelleme (21 Ekim 2026)
Batuhan'ın geri bildirimi ve rakip incelemesi (Apple Books, Kindle, Audible, Libby, Readmio, Epic!, Yoto) sonrası:
- **Tek, başlıksız raf dizisi.** Mod rafları kaldırıldı; tarih başlıkları ("Bugün · Dün · Bu hafta") denendi, estetik bulunmadı. İki sütun, her sıranın altında ince raf (sıcak kâğıt tonu, sert alt kenar; kitap sırtı yok). Her kitap bir kez görünür.
- **Sıra:** varsayılan son okunan; "Kitaplarım" başlığının yanındaki küçük menüden yeni yazılan ya da ada göre (Türkçe alfabe).
- **Kapak altı:** "Dün · 4 dk" / "Klasik · 3 gün önce". Mod kapağın renginden ve simgesinden belli; VoiceOver'da yazıyla.
- **Kendi masalının kapağı:** başlık kapağı (mod tonunda kâğıt, ortada adı, mod simgesi, dünya simgesi, yıldız). Mozaikler birbirine çok benziyordu. Sarıda `yellowText`, yeşilde `greenText` (≥ 3:1 büyük metin).
- Çipler: Tümü · Favoriler · Uyku · Öğrenelim · Macera · Klasikler (yalnızca dolu olanlar). "Yarım kalanlar" kalktı; "Kaldığın yerden" tek kart.
- Başlık çeşitliliği motor tarafında ayrı dalda (`masal-basliklari`).

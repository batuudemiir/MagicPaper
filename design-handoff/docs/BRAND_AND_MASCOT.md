# Marka ve maskot

Görsel referans: `screens/01-Marka.png`. Kaynak görseller: `assets/brand/_source-brand-kit.png`, `assets/brand/_source-mascot-sheet.png`.

## Marka renkleri

| Ad | Hex | Kullanım |
|---|---|---|
| Lavanta | `#8F6BD6` | Vurgu, seçili durum |
| Mor | `#5C3A8F` | Birincil marka rengi, gradyan alt ucu |
| Gece | `#3A2458` | Koyu ikon zemini, basılı metin |
| Krem | `#F6E8DC` | Maskot karnı, sıcak zemin |
| Leylak | `#E6C7F2` | Yumuşak yüzeyler |
| Pembe | `#F2A3C3` | Yanak, kalp |
| Mercan | `#EE7C6B` | Kutlama vurgusu |
| Yıldız | `#F4B735` | Yıldız sayacı |
| Çanta kahvesi | `#A97C52` | Maskotun çantası |
| Mürekkep | `#2E1E3E` | Ana metin |

## Logo ve ikon

| Varlık | Dosya | Not |
|---|---|---|
| Uygulama ikonu (açık) | `Brand/appIconLight` | AppIcon setine 1024 px kaynak olarak ver |
| Uygulama ikonu (koyu) | `Brand/appIconDark` | iOS 18 koyu ikon varyantı (iOS 17'de yok sayılır) |
| Yazı logosu | `Brand/wordmarkLight`, `Brand/wordmarkDark` | Karşılama, Giriş, Abonelik üstü |
| Gece sahnesi | `Brand/sceneNight` | Uyku modu, kilit ekranı widget'ı |
| Göz atan maskot | `Brand/mascotPeek` | Boş liste köşeleri, yükleme |

## Maskot kuralları

1. Bir ekranda en fazla bir maskot.
2. Ebeveyn alanında maskot yok (Ebeveyn kapısı dahil).
3. Bir ekranda tek duygu. Duygu, ekranın amacına göre aşağıdaki tablodan seçilir.
4. Konuşma balonu kısa, sıcak, "sen" dilinde. Hata durumunda suçlamaz ("Masal biraz takılı kaldı").
5. Maskot dekoratiftir: `accessibilityHidden(true)`, anlamı balon metni taşır.
6. Animasyon: giriş 0.4 sn yaylı ölçek. Reduce Motion açıksa sadece belirme.

| Maskot | Asset | Prototipte nerede |
|---|---|---|
| Mutlu | `mascotHappy` | Masal sonu, rozet kazanınca |
| Meraklı | `mascotCurious` | Ana sayfa dünya sorusu, Neleri sever |
| Sakin | `mascotCalm` | Ebeveyn onayı (karşılama akışında, ebeveyn alanından önce) |
| Uykulu | `mascotSleepy` | Bildirim izni, Yıldız bitti |
| Şaşkın | `mascotSurprised` | Üretim başarısız |
| Düşünceli | `mascotThinking` | İnternet yok |
| Kitap üstünde | `mascotOnBook` | Karşılama 1, Abonelik |
| El sallayan | `mascotWaving` | Masal sonu, Okundu kartı |
| Kalemli | `mascotPencil` | Masal yazılıyor, İlk masal |
| Okuyan | `mascotReading` | Boş kitaplık |
| Uyuyan | `mascotSleeping` | Uyku modu, Uyku kartı |
| Yürüyen | `mascotWalking` | Karşılama 3 |
| Önden, üç çeyrek | `mascotFront`, `mascotThreeQuarter` | Yedek (rehber, pazarlama) |

Swift: `Mascot` enum'u ve `MascotImage`, `MascotSays`, `MPStateView` (`ios/DesignSystem/Components/MPMascot.swift`).

## Bilinen eksikler

- Maskot PNG'leri marka kitinden kırpılıp arka planı temizlenmiş tek çözünürlük görsellerdir (imageset'lerde yalnızca 1x). Yayın öncesi tasarımcıdan @2x/@3x ya da vektör (PDF/SVG) çıktısı alınmalı; asset adları aynı kalırsa kod değişmez.
- 3D render yapılmadı; maskot marka kitindeki 2D çizim olarak kullanıldı.
- Ana sayfa Uyku kartında başlık maskotun kulağıyla hafifçe çakışıyor (`screens/state-AnaSayfa-durum4.png`). Uygulamada başlığa sağdan maskot genişliği kadar boşluk ver.

# Ana sayfa yenileme (11 · AnaSayfa)

Tarih: 13 Ekim 2026 · Dal: `anasayfa-yenileme` · Onay: Batuhan (sohbetteki taslaklar)

## Amaç

Ana sayfa çocuk ve ebeveyn için. Daha görsel, daha sıcak, ama metin kalıyor. Öğeler ve sıra
değişmiyor; kartlar tek bir dile oturuyor ve sayfa tek bir renk düzenine bağlanıyor.

## Kararlar

- Yıldız sayacı başlıkta (karar 13 Ekim: yıldız sistemi var). Bu turda yalnızca kazanılır ve
  gösterilir; harcama, üst sınır ve abonelik bağı sonraki planlarda.
- Yıldız = profilin oluşturulduğu günden bugüne her sabah 1 + sonuna kadar okunan her farklı masal 1.
  Yeni depo yok: sabahlar `UserProfile.createdAt`'ten, masallar rozet defterinden
  (`MPBadgeLedger.finished`, zaten hesapla eşitleniyor) türetilir. Uygulamayı açmak yıldız kazandırmaz.
- Uyku saatinde yalnızca başlık bandı geceye döner; sayfanın geri kalanı açık kalır (uygulama açık tema).
- Ekranda tek Ragi: hero kartında maskot varsa (okundu, uyku) mod sorusu maskotsuz başlık olur.

## Görsel dil

- Kart: büyük yarıçap, pastel ya da beyaz zemin, **sert alt kenar** (`mpKidSurface`). Derinlik gölgeden değil kenardan.
- Renk düzeni: mor = eylem ve uyku, şeftali = okuma şeridi ve seri, nane = öğrenme ve günün masalı,
  sarı = yıldız ve kapak, gök = bu akşamın masalı.
- Başlık bandı: lavanta zemin, beyaz bulutlar, alt kenarı dalgalı. Uyku saatinde lacivert gece, hilal, yıldızlar.
- Butonda gradient yok (günün masalındaki oynatma düğmesi çerçeveli daireye döner).

## Bölümler (sıra aynı)

1. Başlık: avatar → Benim köşem, selam + ad, yıldız hapı, kilit → ebeveyn kapısı.
2. Hero kartı, dört durum, metinler bugünküyle aynı:
   - Kaldığın yerden: eğik kapak, ilerleme çubuğu, "Devam et".
   - Bu akşamın masalı: gök tonlu eğik kapak, süre, "Masalı oku".
   - Bugün okudun: nane zemin, el sallayan Ragi, "Yeni masal yarat".
   - Uyku saati: lavanta zemin, uyuyan Ragi, "Uyku modunu aç".
3. Okuma şeridi: şeftali kart, gün adları (Pzt…Paz), okunan gün tikli, bugün mor halka ya da kesikli.
4. Ragi'nin sorusu + mod kartları: üç sütun, beyaz kutuda büyük ikon, mod adı.
5. Devam eden seri: şeftali kart, beş bölüm çubuğu.
6. Günün masalı: beyaz kart, nane kapak, çerçeveli oynatma dairesi.

## Hareket

Hepsi `MP.M` ve Reduce Motion kapısından geçer; kapalıyken anlamı koruyan çapraz geçiş.

- Bulutlar çok yavaş kayar (yeni token `MP.M.ambient`); Reduce Motion'da durur.
- Gündüz ↔ gece bandı `MP.M.slow` ile çapraz geçer.
- Ragi hero kartında ilk görünüşte bir kez sallanır.
- Bugün okununca o günün dairesi dolar (`MP.M.spring`), yıldız sayısı sayarak değişir.
- Basma: `MPPressStyle` (çökme).

## Dosyalar

- Yeni `MagicPaper/Screens/MPStars.swift`: yıldız hesabı (saf fonksiyon) + test.
- Yeni `MagicPaper/DesignSystem/Pastel/MPHomeChrome.swift`: `mpKidSurface`, `HomeSky`, `HomeHeader`,
  `HomeHeroCard`, `HomeStreakCard`, `HomeModeTile`.
- `Views/HomeView.swift`: yeni bileşenlerle yeniden dizilir.
- `Screens/Series/SeriesCard.swift`: kart yüzeyi `mpKidSurface`.
- `DesignSystem/MPTheme.swift`: tek satır, `MP.M.ambient` (ortam hareketi için süre token'ı yoktu).
- Eski `TonightHeroCard`, `StreakStrip`, `KidHeader` dokunulmadan kalır (önizlemeler kullanıyor).

## Erişilebilirlik ve doğrulama

- Her etkileşimli öğede Türkçe etiket; bulut, ay, yıldız süsleri gizli.
- AX boyutlarında mod kartları tek sütun, hero kartı görseli metnin üstüne iner.
- CLAUDE.md'deki beş grep değişen dosyalarda boş; simülatörde dört durum + AX5, SE ve Pro Max.

## Kapsam dışı

Yıldız harcama, Yıldız bitti (45), dünya şeridi, Benim köşem'deki yıldız gösterimi (bir sonraki ekran).

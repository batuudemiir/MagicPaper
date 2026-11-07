# MagicPaper marka kitabı

Markanın tek kaynağı. Ekran kuralları `CLAUDE.md` Design law'da, token'lar
`MagicPaper/DesignSystem/MPTheme.swift` içinde; bu belge neden ve ne sorularını
cevaplar. Söz için: `docs/SES_VE_SOZ.md`. Yol haritası: `docs/STARTUP_PLANI.md`.

## Çekirdek

| Öğe | Karar |
|---|---|
| Ad | **MagicPaper**, her yerde, bitişik. "Magic Paper" ve "MagicPaper Kids" yok. |
| Vaat | Her çocuğun kendi masal dünyası. |
| Kişilik | Sıcak, masalsı, sakin, özenli. İyi bir çocuk kitabının sesi. |
| Maskot | Ragi, rakun. |
| Yasak | Neon, parıltı, gradient buton, "yapay zeka" sözü, baskı dili. |

## İmzalar

Bir ekran, adı görünmese de bu dördünden tanınır:

1. **Sert alt kenar:** dokunulan kart ve birincil düğme gölgeyle değil, altındaki sert kenarla yükselir. Düğmeye basınca yüzü kenarın üstüne iner.
2. **Ragi:** ekran başına en fazla bir tane, tek duygu.
3. **Kitap ve kâğıt dili:** kapak, sayfa, cilt, ithaf, künye.
4. **Mor ve krem:** eylem moru `#6A47B8`, çocuk zemini krem.

## Renk

| Rol | Değer | Not |
|---|---|---|
| Eylem | `#6A47B8` | Tek eylem rengi (3 Ekim kararı). |
| Metin | `MP.C` token'ları | Saf siyah ve soğuk gri yok. |
| İkincil metin | `textSecondary` | Zeminlerde 4,62-5,59:1. |
| Soluk | `textTertiary` | 2,09-2,53:1, eşiğin altında. **Yalnızca kilit gibi süs simgelerde, metinde asla.** |

## Yazı

İki aile, roller sabit. Dosyalar SIL OFL 1.1.

- **Baloo 2:** yalnızca başlık ve kapak. Paketlenen dosya `Baloo2-Latin-Variable.ttf`: yalnızca Latin, satır kutusu 1,20 em. Özgün dosyada 1,60 em olduğu için başlıklar boşlukta yüzüyordu. Üretimi: `Tools/make_baloo_latin.py`.
- **Nunito:** geri kalan her şey.

| Rol | Font | Boyut / ağırlık | `MPTextStyle` |
|---|---|---|---|
| Kapak | Baloo 2 | 34 bold | `cover` |
| Sayfa başlığı | Baloo 2 | 28 bold | `page` |
| Bölüm başlığı | Baloo 2 | 21 semibold | `section` |
| Kart başlığı | Nunito | 17 bold | `cardTitle` |
| Gövde | Nunito | 17 regular | `body` |
| İkincil | Nunito | 15 regular | `supporting` |
| Dipnot | Nunito | 13 semibold | `footnote`, büyük harfli çeşidi `eyebrow` |
| Düğme | Nunito | 17 bold | `button` |

Masal metni bu tablonun dışında: `MP.F.read`.

## Düğmeler

| Tür | Görünüm | Kural |
|---|---|---|
| `primary` | Dolu mor, sert kenar, 56 pt | Ekranda bir tane. |
| `secondary` | Lavanta, kenarsız, 52 pt | Yan eylem. |
| `ghost` | Mor yazı, dokunma alanı 48 | "Şimdi değil" gibi geri çekilen eylem. |
| `danger` | Kırmızı | Yalnızca ebeveyn alanı. |
| `outline` | Beyaz, ince çerçeve | **Yalnızca giriş sağlayıcısı** (Google): Apple düğmesinin yanında durur. |
| `MPCircleButton` | Lavanta daire, dokunma alanı 54 | Geri, kapat, arama. |

Devre dışı düğme saydamlaşmaz: düz gri ve kenarsızdır.

## Ragi

Bugün 14 poz 1x PNG, telefonda bulanık. Karakter kitabı, vektör pozlar ve Rive animasyonu Faz 4'te, illüstratör ve animatör bütçesine bağlı.

**Açık kararlar (Batuhan):** "Her çocuk ekranında Ragi" kuralı "anlamı olan ekranda"ya gevşesin mi? Paywall'dan Ragi kalksın mı? Karar verilene kadar Design law'daki kural geçerlidir.

## Plan adları

Tek liste, emoji yok: **Yıldız Kaşifi** (`basic`), **Hikaye Kahramanı** (`premium`), **Sihir Ustası** (`ultimate`, paywall'da satılmıyor). Ücretsiz plan "Ücretsiz".

## Yüzeyler

| Yüzey | Durum |
|---|---|
| Uygulama, widget | Bu kitaba uyar (Faz 1). |
| PDF kitap | Kapakta "MagicPaper" (Faz 1); Baloo 2 başlık ve kolofon sonraya. |
| Web, yasal sayfalar | **Henüz uymuyor:** `privacy.html` ve kardeşleri `#9449FA`, gradient, sistem fontu. Faz 6. |
| Tanıtım filmi, promo | **Henüz uymuyor:** başka fontlar, Ragi'nin adı yok. Faz 6. |
| App Store görselleri | Testten üretilecek, Faz 6. |
| `AssetCatalog` lisans kayıtları | Eski ad "MagicPaper Kids" duruyor, bilerek: üretilmiş kayıt, kullanıcıya görünmez. |

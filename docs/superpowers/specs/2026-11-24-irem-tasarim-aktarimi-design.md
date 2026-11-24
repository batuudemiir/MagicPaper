# İrem'in 21–24 Kasım tasarımlarını uygulamaya aktarma

Tarih: 24 Kasım 2026 · Karar: Batuhan · Dal: `irem-aktarim` (kaynak `origin/irem` ec89310)

## Niyet

İrem `irem` dalında ana sayfa, menü sayfaları (`MPSkyPage`), Profil, Okuma yolculuğum, masal sonu
ve Paywall'ı yeni dilde Swift'e yazdı (main 856cb88'den sonra 52 commit, 44 Swift dosyası). Batuhan
tasarımları beğendi ve uygulamaya alınmasını istiyor; inceleme bulguları düzeltilerek, MagicPaper
tasarım kanununa (CLAUDE.md "Design law") uygun hâle getirilerek.

Batuhan'ın İrem'e ses kayıtlarındaki ilgili fikirler (23 Kasım):
- "Masal bitirmek bir olay olmalı, hemen yeni bir masal daha olmamalı": "Bir masal daha" kalkar.
- Menü ana sayfada kalır; aynı sayfalar Profil'in altında da durur.
- Rozetler Duolingo tarzında (İrem'in Rozetlerim'i zaten bu yönde).

## Hedefler

1. `irem` dalındaki iş main'e gelir (main `irem`'in atası: ileri sarılabilir).
2. Masal sonu gündüz: "Bir masal daha" ve haftalık dakika kartı kalkar; tek eylem "Ana sayfaya dön".
3. Ana sayfa: selam okunur, ekranda tek Ragi, akşam kartı sakin, "+" kalkar.
4. Menü sheet'inde Ragi yok (arkadaki ana sayfanın Ragi'si yeter).
5. Profil resmi seçicisinde Ragi yok: Ragi maskottur, çocuğun kimliği olmaz (Batuhan, 24 Kasım).
6. CI ekran turu menü sayfalarını gerçekten açar.
7. Tasarım kanunu İrem'in mor göğünü tanımlı istisna olarak yazar.

## Hedef dışı

- Çocuk modunu yalnızca okuyucuya almak (ses kaydı 1) ve davet/"masalına katıl": ayrı karar.
- 100 masalda "Masal Kahramanı" unvanı (ses kaydı 5): ayrı iş.
- Paywall'ın yeni yerleşimi: İrem'in hâliyle aktarılır, bu turda yeniden tasarlanmaz.
- Yeni avatar çizimi (beş arkadaş portreleri `codex/design-system-catalog`'da; sonra eklenebilir).

## Anti-hedefler

- Masal sonunda ya da ana sayfa kartında "bir tane daha" baskısı kalması.
- Çocuğa uygulamada geçirdiği süreyi gösteren her şey.
- İrem'in tasarım dilini (mor gök, bilgi kartları, `MPSkyPage`) dağıtmak.

## Kısıtlar

- `codex/design-system-catalog` checkout'u kirli ve başka işte; dokunulmaz. İş worktree'de.
- Disk ~4 GB boş: tek DerivedData, en sonda bir kez derleme/test (Batuhan'ın kuralı).
- Değişiklik günlüğü kaydı, main'e alma ve gönderim Batuhan'ın onayıyla.

## Yaklaşımlar

| Yol | Ne | Neden değil / neden |
|---|---|---|
| **A. `irem` üstüne düzeltme (seçilen)** | Worktree `irem`'den; düzeltmeler üstüne commit; sonunda main ileri sarılır | İrem'in geçmişi ve testleri korunur, çakışma yok |
| B. Ekran ekran cherry-pick | Commit'leri seçerek main'e taşımak | 52 commit iç içe; CI görüntü commit'leri araya giriyor; kazanç yok |
| C. Prototipten yeniden yazmak | `design-preview/app`'ten SwiftUI | Kod zaten yazılmış; boşa iş |

## Kararlar

- **Batuhan:** "Bir masal daha" kalkar · profil resminde Ragi yok · yaklaşım A.
- **Önerildi, Batuhan onayladı:** degrade istisnası kanuna yazılır (`MP.C.homeSky`, `endingSky`,
  `MPSkyPage`); İrem'in görünüş dışı değişiklikleri tutulur (günün masalı her zaman ücretsiz,
  hak bitince kart kitaplığa, seri `.locked`, deneme uygunluğu).
- **Benim kararlarım (düzeltilebilir):**
  - Ana sayfada tek Ragi akşam kartındaki (saatle hâli değişir: okuyan/uykulu/mutlu); başlıktaki
    el sallayan Ragi kalkar.
  - Akşam kartı "Bugün okudun" durumunda "Bir tane daha?" ve "Yeni masal yaz" yerine sakin metin
    ve "Kitaplığına bak" (ses kaydı 2'nin ruhu). Mod satırları yazmayı açık tutar.
  - Bölüm başlığındaki "+" kalkar ("Masal yaz" dairesi ve mod satırları aynı işi yapıyor).
  - Menü sayfalarında seçili sekmenin "Ana sayfa" olması hata değil: sayfa açık sekmenin yığınına
    itiliyor (`closeSheet(then:)` + `openKidPage`). Değişmez.
  - Ragi avatarını seçmiş çocuklar: `ProfileAvatar.named` Ragi kimliklerini tanımaz, boş profil
    resmine düşer; çocuk yeniden seçer.

## Kurucuya kalan

- Selam kontrastının tam çözümü (göğün durakları mı, başlığın bölünmesi mi) — ölçüt: beyaz yazı ≥ 4.5:1,
  her iki kademede ve en büyük yazıda.
- CI kancalarının neden sayfayı açmadığının kök nedeni.

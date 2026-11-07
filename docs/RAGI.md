# Ragi karakter kitabı

Ragi'nin görünüşü, hareketi ve sesi. Ekran kuralları `CLAUDE.md` Design law'da (Ragi bölümü), marka `docs/MARKA.md`. Kaynak çizim: `design-handoff/assets/brand/_source-mascot-sheet.png`.

## Kim

Mor bir rakun, sırtında sarı yıldızlı çanta. Meraklı, sakin, kitap seven bir arkadaş. Şımarık değil, panik yapmaz, çocuğu suçlamaz, geri gelmesi için yalvarmaz.

## Görünüş

| Öğe | Kural |
|---|---|
| Siluet | Üçgen kulaklar, yuvarlak baş, tepede küçük tüy, halkalı büyük kuyruk |
| Renk | Tüy `#8F6BD6`, koyu `#5C3A8F`, göz bandı `#3A2458`, krem `#F6E8DC`, çanta `#F4B735` |
| Kontur | Siyah kontur yok, boyalı yumuşak kenar |
| Yapılmaz | Yeni kıyafet, başka çanta rengi, parıltı, 3B parlaklık, başka sanat stili |

## Duygu ve poz

Poz ve yeri `Mascot.usage` tablosunda; ekran başına tek Ragi, tek duygu.

## Hareket

Kod: `DesignSystem/Pastel/MPRagi.swift` (saf model `RagiMotion`, poz tablosu `RagiRig`), `RagiBones.metal` (bölgesel döndürme). Çizim tek parça kalır, üstüne kukla biner: baş, kuyruk ve kol ayrı oynar, kapak göz bandının rengiyle iner. Tempo `MP.M.RagiBeat`.

| İş | Ne yapar | Nerede |
|---|---|---|
| `idle` | Nefes, 4-6 saniyede bir kırpma, hafif kuyruk | Varsayılan |
| `wave` | İki sallama, sonra dinlenir, 11 sn'de bir yeniden | Selam, ilk açılış |
| `cheer` | İki küçük zıplama, sonra sakin | Yalnızca gündüz masal sonu |
| `read` | Yavaş baş sallama | Okuyan Ragi |
| `write` | Kalemli kol küçük gider gelir | Masal yazılıyor |
| `walk` | Yürürken hafif sıçrama | Yürüyen Ragi |
| `sleep` | Derin yavaş nefes, kırpma yok | Uyku, gece masal sonu |

Kurallar:

- Reduce Motion ve düşük güç modunda düz çizim: anlam kaybolmaz.
- Sürekli zıplama, dikkat çekme ve panik yok.
- Yeni çizim gelirse yalnızca varlıklar ve `RagiRig` tablosu değişir, ekranlar değişmez.
- `MascotImage` tek giriş; iş verilmezse pozun doğal hareketi (`Mascot.defaultAct`).

## Çizim dosyaları

Katalogdaki pozlar özgün kesimlerin (`design-handoff/assets/brand/mascot*.png`) 4 kat büyütülmüşüdür: `Tools/ragi/upscale_ragi.py`, cihaz içi süper çözünürlük. Çizim yeniden çizilmedi, karakter birebir aynı; netlik arttı, yeni ayrıntı eklenmedi. Koddan vektör çizim denendi ve bırakıldı: aynı karakter gibi durmadı, çıkartma havası verdi.

Yeni poz ya da gerçekten yeni çizim gerekirse illüstratör işi. Bilinen kesim kusurları özgün dosyalardan geliyor: `onBook` başının solu dik kesik, büst pozların altı keskin, `peek` kendi zeminini taşıyor.

## Ses

Kod: `DesignSystem/MPSound.swift`. Dosyalar kodla sentezlenir: `Tools/make_ragi_sounds.py`, lisans gerekmez.

| Ses | Ne | Nerede |
|---|---|---|
| `mp_ending` | Kalimba, üç nota yukarı | Gündüz masal sonu |
| `mp_earned` | Tek nota | Yeni rozet |
| `mp_ready` | İki nota | Masal ciltlendi |
| `mp_page` | Çok kısık kâğıt hışırtısı | Sayfa çevrilince |
| `mp_ragi` | Küçük mırıltı | İlk açılış, Profil'de Ragi'ye dokununca |

Kurallar: sessize alma anahtarına uyar, başka uygulamanın sesini kesmez, uyku vaktinde ve masal okunurken çalmaz, Ayarlar'da "Sesler" ile kapanır. Bildirimle ses gönderilmez.

## Önizleme

```bash
xcrun simctl launch booted com.batu.magicpaper.v1 -mpDemo YES -mpRagiStudio YES
```

Vitrin: `Screens/RagiStudioView.swift`, yalnızca DEBUG. Video: `Tools/record_ragi_preview.swift`.

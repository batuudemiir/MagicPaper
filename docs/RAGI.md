# Ragi karakter kitabı

Ragi'nin görünüşü, hareketi ve sesi. Ekran kuralları `CLAUDE.md` Design law'da (Ragi bölümü), marka `docs/MARKA.md`. Kaynak çizim: 18 Kasım 2026'dan beri 45 görsellik kütüphane `design-handoff/proposals/2026-11-18-ragi-asset-library/` (eski pafta: `design-handoff/assets/brand/_source-mascot-sheet.png`).

## Kim

Mor bir rakun, sırtında sarı yıldızlı çanta. Meraklı, sakin, kitap seven bir arkadaş. Şımarık değil, panik yapmaz, çocuğu suçlamaz, geri gelmesi için yalvarmaz.

## Görünüş

| Öğe | Kural |
|---|---|
| Siluet | Üçgen kulaklar, yuvarlak baş, tepede küçük tüy, halkalı büyük kuyruk |
| Renk | Tüy `#8F6BD6`, koyu `#5C3A8F`, göz bandı `#3A2458`, krem `#F6E8DC`, çanta `#F4B735` |
| Kontur | Siyah kontur yok, boyalı yumuşak kenar |
| Yapılmaz | Yeni kıyafet, başka çanta rengi, parıltı, 3B parlaklık, başka sanat stili |
| İstisna | Özel gün teması sırasında tek aksesuar (kurdele, bayrak, fener, parti şapkası, Noel Baba şapkası gibi): kontursuz, aynı boya dili, `RagiRig` baş kemiğine bağlı, tema bitince çıkar. İllüstratör işi. Karar: 17 Kasım 2026, Batuhan; plan `docs/OZEL_GUN_TEMA_PLANI.md` |

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

Katalogdaki 15 poz 18 Kasım 2026'da yeni Ragi kütüphanesinden alındı (`design-handoff/proposals/2026-11-18-ragi-asset-library/assets`). Görsel boyanmadı; yalnızca saydam kenar boşluğu kırpıldı ve uzun kenar 1024 px'e indirildi. `RagiRig` tablosu yeni çizime göre yeniden ölçüldü, kapak rengi (`ragiBand`) yeni göz bandından alındı.

| Poz | Kütüphane dosyası |
|---|---|
| `front` | 01-front |
| `threeQuarter` | 02-three-quarter |
| `happy` | 06-face-happy |
| `calm` | 07-face-calm |
| `sleepy` | 08-face-content |
| `surprised` | 10-face-surprised |
| `curious` | 11-face-thinking |
| `waving` | 12-wave |
| `onBook` | 14-magic-book |
| `reading` | 15-reading (17-seated-reading'in gözleri kapalı, göz kırpamaz) |
| `sleeping` | 18-curled-sleep |
| `thinking` | 19-seated-thinking |
| `walking` | 20-walking |
| `pencil` | 43-writing-new |
| `mascotPeek` (katalog dışı) | 25-peek |

Kütüphanenin geri kalanı (uyku battaniyesi, kutlama, dedektif, kalp, aksesuarlar) henüz bir katalog rolüne bağlı değil. 39-42 (kuyruk, pati, uyku ve ünlem işaretleri) hale taşıyor, uygulamada kullanılmaz.

Yeni poz ya da gerçekten yeni çizim gerekirse illüstratör işi. Büst pozların (06-10) altı düz kesik; `peek` ahşap kenarı çizimin parçası.

## Ses

Kod: `DesignSystem/MPSound.swift`. Dosyalar kodla sentezlenir: `Tools/make_ragi_sounds.py`, lisans gerekmez.

| Ses | Ne | Nerede |
|---|---|---|
| `mp_ending` | Kalimba, üç nota yukarı | Gündüz masal sonu |
| `mp_earned` | Tek nota | Yeni rozet |
| `mp_ready` | İki nota | Masal ciltlendi |
| `mp_page` | Çok kısık kâğıt hışırtısı | Sayfa çevrilince |
| `mp_ragi` | Küçük mırıltı | İlk açılış, Profil'de Ragi'ye dokununca |

Perde-anlam haritası (Faz 13, sabit): bütün notalar Sol majör pentatonik (G5-G6). Yukarı giden nota "tamamlandı, kazanıldı" der; aşağı inen nota yok, çünkü hiçbir şey kaybedilmez. Ragi notasız bir cıvıltı, kâğıt notasız bir hışırtı. Hafif stereo: sayfa biraz solda, kazanılan öğe biraz sağda (Odam sekmesine uçar). Dokunsal desenler yalnızca iki anda: sayfa (`mp_page.ahap`) ve masal sonu (`mp_ending.ahap`, sesin üç notasıyla aynı ritim).

Kurallar: sessize alma anahtarına uyar, başka uygulamanın sesini kesmez, uyku vaktinde ve masal okunurken çalmaz, Ayarlar'da "Sesler" ile kapanır. Bildirimle ses gönderilmez.

## Önizleme

```bash
xcrun simctl launch booted com.batu.magicpaper.v1 -mpDemo YES -mpRagiStudio YES
```

Vitrin: `Screens/RagiStudioView.swift`, yalnızca DEBUG. Video: `Tools/record_ragi_preview.swift`.

# MagicPaper Original kapak kılavuzu

**Ana yol (karar: 16 Kasım 2026, Batuhan):** ajan kapağı çizmez, `review.md`'ye bir ChatGPT promptu yazar.
Batuhan görseli ChatGPT'de üretir, referans kapağı da ekleyerek; sonra:

```bash
python3 Tools/place_cover.py <slug> <indirilen-görsel>
```

Araç görseli ortadan 3:4'e kırpar ve `drafts/<slug>/cover.jpg`'ye 1125 × 1500 JPEG olarak yazar
(taslak yoksa `published/<slug>/`). Ardından `content-publisher originals check <slug>`.

**Stil referansı:** `Content/Originals/published/saatin-icindeki-ninni/cover.jpg` (ilk kapak, 13 Kasım 2026,
ChatGPT). Her Bulut Durağı kapağı bu görseli referans alır; böylece tren, istasyon, fareler ve guaj dokusu
kapaktan kapağa aynı kalır. Daha iyi bir kapak gelirse referans Batuhan'ın kararıyla değişir.

## Kompozisyon

Resimli kitap kapaklarında tekrar eden ilkeler (kaynaklar: neolemon.com, self-publishingschool.com,
lucidpress.com, muddycolors.com; 12 Kasım 2026'da okundu):

- **Tek odak.** Kapağın bir kahramanı var: bir karakter ya da karakterlerin bulunduğu tek bir nesne
  (ilk kapakta saatin camından bakan iki fare). Her şey ona hizmet eder.
- **Küçükte okunur.** Rafta kart 128 × 176 nokta. 176 px'e küçültülmüş hâlde odak ve karakterin rengi
  (bere, atkı) seçilmeli.
- **Boşluk.** Odağın çevresi sakin; üst üçte bir gökyüzü ya da düz duvar gibi sade bir alan.
- **Odak dikeyde %40-65 arasında.** Masallar detay sayfası başlığı resmin alt kısmına yazar ve resmi
  ortadan kırpar; odak altta kalırsa başlığın altında kaybolur.
- **Bir sıcak ışık kaynağı, soğuk bir zemin.** Bulut Durağı'nda: amber lamba ışığı, gece mavisi kar.
- **Yazı yok.** Harf, rakam (saat kadranında da), logo, imza yok. Başlığı uygulama yazar.
- Dünyanın sabit görünüşleri (`WORLD.md` > Karakterler > "Kapakta değişmeyen görünüş") birebir uyulur.
- Korkutucu imge yok; karanlık sahnede bile sıcak bir ışık ve rahat bir duruş.

## Prompt kalıbı

Ajan bu kalıbı doldurur; köşeli parantezler masala göre, geri kalanı aynen.

```
A premium children's picture book cover illustration, portrait 3:4.
[WORLD.md ## Kapak stili paragrafı, olduğu gibi]

Match the style, palette and character designs of the attached reference cover.

Scene: [masalın en sakin ve en tanınır anı: kim, nerede, ne yapıyor. Karakterleri adıyla değil
WORLD.md'deki "kapakta değişmeyen görünüş"üyle tarif et: tür, kürk rengi, bere rengi, atkı...]

Light: [ışık kaynağı ve renk sıcaklığı; Bulut Durağı'nda tek sıcak amber kaynak, soğuk mavi gece].

Composition: one clear focal point placed in the vertical middle of the image (between 40% and 65% of
the height); the top third is calm (sky or plain wall); the focal point must stay readable when the
cover is shown as a small thumbnail.

No text, no letters, no numbers anywhere (including clock faces, signs and books), no logos, no signature.
No photorealism, no 3D render, no glossy CGI, no neon, nothing scary.
```

Prompt bloğunun altına: "Referans olarak ekle: `Content/Originals/published/saatin-icindeki-ninni/cover.jpg`".

Gelen görselde yazı ya da rakam varsa Batuhan ChatGPT'ye "remove all text and numbers, keep everything else
the same" der.

## SVG yolu (12 Kasım 2026, kullanılmıyor, yedek)

Claude'un kendisi çizdiği eski yol: `drafts/<slug>/cover.svg` → `python3 Tools/render_cover.py <slug>`.
Batuhan ilk SVG kapağı beğenmedi; yol yalnız yedek olarak duruyor.

### Teknik iskelet

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1125" height="1500" viewBox="0 0 1125 1500">
<defs>
  <!-- Elle boyanmış kenar: bütün sahne bu grubun içinde -->
  <filter id="paint" filterUnits="userSpaceOnUse" x="0" y="0" width="1125" height="1500">
    <feTurbulence type="fractalNoise" baseFrequency="0.03" numOctaves="2" seed="3" result="n"/>
    <feDisplacementMap in="SourceGraphic" in2="n" scale="7" xChannelSelector="R" yChannelSelector="G"/>
  </filter>
  <!-- Pigment lekesi: koyu, düşük opaklıkta -->
  <filter id="wash" filterUnits="userSpaceOnUse" x="0" y="0" width="1125" height="1500">
    <feTurbulence type="fractalNoise" baseFrequency="0.012" numOctaves="4" seed="4" result="t"/>
    <feColorMatrix in="t" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -2.2 1.35" result="a"/>
    <feComposite in="SourceGraphic" in2="a" operator="in"/>
  </filter>
  <!-- Kâğıt dokusu: açık, düşük opaklıkta -->
  <filter id="grain" filterUnits="userSpaceOnUse" x="0" y="0" width="1125" height="1500">
    <feTurbulence type="fractalNoise" baseFrequency="0.7" numOctaves="2" seed="9" result="t"/>
    <feColorMatrix in="t" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -1.4 0.95" result="a"/>
    <feComposite in="SourceGraphic" in2="a" operator="in"/>
  </filter>
  <filter id="soft"><feGaussianBlur stdDeviation="14"/></filter>
</defs>
<rect width="1125" height="1500" fill="#1A1729"/>
<g filter="url(#paint)">
  <!-- sahne: arka plan → orta plan → odak → ön plan -->
</g>
<rect width="1125" height="1500" fill="#0A0814" opacity="0.16" filter="url(#wash)"/>
<rect width="1125" height="1500" fill="#F4E6CC" opacity="0.10" filter="url(#grain)"/>
</svg>
```

Çizici tuzakları (qlmanage/WebKit):

- Filtre bölgesi **mutlaka** `filterUnits="userSpaceOnUse"` ve tam tuval; yüzdelik bölgeli bir
  filtre büyük bir grubu hiç çizmez (ekran düz renk çıkar).
- `mix-blend-mode` yok sayılır; doku katmanlarını opaklıkla ayarla.
- Işık için `radialGradient` (merkez opak, kenar saydam) kullan; gradient yalnız kapak sanatında serbest.
- Pencere ya da çerçeve içi sahne için `clipPath`; karakteri bir nesnenin "içinde" göstermek için de.

## Kontrol listesi (gelen görsel için)

1. `python3 Tools/place_cover.py <slug> <görsel>` hatasız, `cover.jpg` 1125 × 1500.
2. `cover.jpg`'ye bak; `sips -Z 176 cover.jpg --out "$TMPDIR/thumb.jpg"` ile küçük hâline de bak.
3. Karakterler WORLD.md görünüşünde mi, yazı var mı, odak %40-65'te mi, üst üçte bir sakin mi.
4. `content-publisher originals check <slug>` temiz (kapak ≤ 1500 KB, JPEG).

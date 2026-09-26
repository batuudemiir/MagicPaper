# MagicPaper — ürün filmi (Apple framework, "2. Design")

31.5 sn · 1920×1080 · 60 fps · stereo AAC, -16 LUFS

- `magicpaper-film.html`: filmin tamamı (SVG illüstrasyonlar + metin hareketi, tek zaman çizelgesi). Canlı önizleme için `magicpaper-film.html?play` (İngilizce: `?play&lang=en`)
- `render.mjs`: kareleri Playwright ile alır, H.264 MP4'e çevirir
- `soundtrack.py`: müziği ve ses efektlerini koddan üretir (numpy)
- `magicpaper-film-tr.mp4`, `magicpaper-film-en.mp4`: render çıktıları

```bash
pip install imageio-ffmpeg   # veya FFMPEG=/path/to/ffmpeg
node render.mjs --lang tr    # --fps 30, --stills 4.5,9.2 da çalışır
python3 soundtrack.py soundtrack.wav
ffmpeg -i magicpaper-film-tr.mp4 -i soundtrack.wav -map 0:v -map 1:a -c:v copy \
  -af "highpass=f=35,loudnorm=I=-16:TP=-1.5:LRA=7" -c:a aac -b:a 256k -shortest out.mp4
```

## Marka kuralları (makalenin 1. bölümü: "Intention is everything")

Filmdeki her seçim bu kurallardan geliyor, dışına çıkılmıyor.

| Kural | Değer |
|---|---|
| 3 renk | Kâğıt `#F6F1E7` · Mürekkep `#1D1830` · Sihir moru `#7E4CF2` (uygulamanın ana moru) |
| 2 yazı tipi | Fraunces (başlıklar, masal hissi) · Inter Tight (küçük etiketler) |
| Çizgi dili | 5 px mürekkep kontur, yuvarlak birleşimler, tek düz dolgu, gradyan yok |
| Vurgu | Her cümlede en fazla bir kelime italik ve mor |
| Arka plan | Düz kâğıt + %4.5 grain. Asla nesnenin önüne geçmez |

## Storyboard: bir çekim = bir fikir

| # | Zaman | Fikir | İllüstrasyon hareketi | Metin |
|---|---|---|---|---|
| 1 | 0–3.6 | Vaat | Boş sahne, sonra tek bir mor nokta | "Her çocuk bir *kahraman*dır." |
| 2 | 3.6–7.8 | Girdi: fotoğraf | Nokta fotoğraf kartına dönüşür, portre kendini çizer (yüz, saç, göz, gülüş), bir kez göz kırpar | "Bir fotoğraf." |
| 3 | 7.8–11.4 | Girdi: tema | Kart daireye dönüşür, 4 tema yörüngeye girer, seçim halkası hızlanarak dolaşıp rokette durur | "Bir dünya." |
| 4 | 11.4–15.2 | Yapay zekâ = sihir | Avatar roketin penceresine yerleşir, roket kalkar, kıvılcımlar çıkar, noktalı iz kalır | "Ve biraz *sihir.*" |
| 5 | 15.2–21.7 | Çıktı: masal | İz kitabın sırtına dönüşür, sayfalar açılır, satırlar tek tek yazılır, sağ sayfada aynı çocuk roketle Ay'a gider | "Saniyeler içinde, ona özel bir masal." |
| 6 | 21.7–26 | Duygusal doruk | Kamera illüstrasyonun içine girer, gece çöker | "Bu masalın kahramanı *o.*" |
| 7 | 26–31.5 | Marka | Ay ışığı ekranı kaplar, logo çizilir, wordmark harf harf gelir | MagicPaper · Her gece yeni bir masal. |

## Makaledeki ilkelerin uygulanışı

**Design**
- **Ana nesne ortada:** avatar, roket, kitap ve logo hep kadrajın ortasında. Metin hep aynı yerde, altta.
- **Nefes alanı:** her sahnede tek bir odak ve geniş boşluk var. Sahne 1'de başlık yalnız başına duruyor.
- **Arka plan kurallara uygun:** tek değişiklik sahne 6'daki kâğıttan geceye geçiş, o da hikâyenin kendisi.

**Animation**
- **Yumuşaklık:** hiçbir hareket lineer değil. Girişlerde `outQuint`/`outExpo`, dönüşümlerde `inOut`, pop'larda hafif `outBack` kullanılıyor. Kelimeler bulanıklıktan 75 ms arayla çıkıyor.
- **Dinamik geçişler:** filmde tek bir kesme yok. Nokta karta, kart avatara, avatar roket penceresine, roket izi kitap sırtına, illüstrasyon tam ekrana, Ay ışığı logoya dönüşüyor.
- **Uyarlanabilir ritim:** açılış yavaş. Tema seçimi hızlanıyor (halka 300 → 200 ms arayla atlıyor). Kalkış ivmeleniyor. Final yavaş ve sakin.

## Müzik ve ses tasarımı (makalenin 4. ve 5. bölümleri)
- **BPM:** 100, makaledeki "Smooth, Cool, Effortless" aralığı. Sıcak pad, celesta çanları ve yumuşak bas var. Davul, rap ya da hype yok.
- **Uyarlanabilir ritim:**
  - Açılışta seyrek çan notaları.
  - Fotoğraf sahnesinde 8'likler.
  - Tema taramasında 16'lıklar; atlama notaları seçilen dünyaya doğru tırmanıyor.
  - Kalkıştan önce yükselen bir ses, kalkış anında sessizlik.
  - Masal yazılırken yeniden 8'likler.
  - İllüstrasyonun içinde seyrek, tiz "gece" notaları.
  - Logoda tek bir çözümleyici çan.
- **Ses efektleri:** yalnızca anlam taşıyanlar kaldı: kart oturunca "tık", kalkışta "whoosh" ve alt bas, kitap açılınca sayfa hışırtısı, ay ışığı geçişinde hafif bir süpürme.
- **Seviye:** -16 LUFS, tepe -1.5 dBTP. Sakin marka filmi için sosyal medya normunun biraz altında.

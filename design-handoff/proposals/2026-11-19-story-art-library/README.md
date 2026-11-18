# MagicPaper · hikâyeyle büyüyen görsel havuzu

19 Kasım 2026 · 12 konu için seçilmiş taslak çizim. Yerleşik ChatGPT image_gen ve onaylı sanat referansı kullanıldı. Her dosya gerçek RGBA saydamlık içeriyor. Üretim uygulamasına bağlanmadı; durumları review.

[Mimari taslak ve aşamalar](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/docs/superpowers/specs/2026-11-19-semantic-story-art-design.md) · [33 nesnenin envanteri](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/INVENTORY.md) · [İnceleme](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/REVIEW.md)

Akış: seçilen metin varyantları → sayfanın görünür nesne/durum bildirimi → uygun onaylı görsel → kitapla kaydedilmiş karar → çevrimdışı okuyucu.

| Konu / dosya | Türkçe görsel açıklaması |
|---|---|
| [yırtık bir harita](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/torn-map-v5.png) | Çizgili bir rota ve orman çizimi taşıyan, çapraz yırtılmış yarım lila harita. |
| [yere düşmüş küçük bir yuva](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/fallen-nest-v1.png) | Boş, sağlam küçük bir dal yuvası. |
| [birinin düşürdüğü küçük bir eldiven](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/dropped-mitten-v1.png) | Mor manşetli, mercan renkli tek örgü eldiven. |
| [eski fener](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/old-lantern-v1.png) | Taşıma saplı, camı içinde ışık olan eski mor fener. |
| [altın anahtar](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/golden-key-v1.png) | Tek, altın renkli küçük anahtar. |
| [parlayan kristal](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/blue-crystal-v1.png) | İçi yumuşakça parlayan mavi kristal. |
| [renkli tüy](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/colorful-feather-v1.png) | Turkuaz, lila ve mercan renkli tek kuş tüyü. |
| [deniz kabuğu](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/sea-shell-v1.png) | Lila dış yüzeyli, mercan içli boş deniz kabuğu. |
| [büyüteç](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/magnifying-glass-v1.png) | Mor saplı, yuvarlak camlı büyüteç. |
| [sağlam ip](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/sturdy-rope-v1.png) | İki ucu görünen, gevşekçe sarılmış kalın ip. |
| [eski bir müzik kutusu](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/music-box-v1.png) | Kapağı açık, silindiri ve kolu görünen ahşap müzik kutusu. |
| [renkli bir kâğıt fener](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/paper-lantern-v1.png) | İçinde yumuşak ışık olan lila ve mercan kâğıt fener. |

Prompt seti: [PROMPTS.json](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/PROMPTS.json). Final prompt, basePrompt + seçilen subject alanıdır; harita için iterations içindeki v5 promptu kullanılır. Kaynak referans ve üretim dosyaları [source-provenance.json](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/source-provenance.json) içinde; hash/boyut/alfa kontrolleri [validation.json](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/validation.json) içinde.

Bu set 12 resim konusu kapsar; sayfa veya masal kapsama oranı değildir. Sayfa izin listeleri ve çalışma zamanı eşlemeleri entegrasyon fazında, gerçek composer çıktılarıyla doğrulanacaktır. Haritanın eski v1 dosyası yalnız tarihçedir; seçilen dosya v5. Çocuk/Ragi/hayvan karakter kimliği bu turda çizilmedi.

Sonraki uygulama dilimi: ilk incelenmiş nesne/varyant diliminde yerel spot bağlayıcı; ardından seri save/unlock/restore; sonra içerik semantiği ve havuz genişleme kontrolleri. Üretim koduna geçmeden mimari taslak ve çizim seti gözden geçirilmelidir.

## Seçilmiş çizimler

### yırtık bir harita

![Çizgili bir rota ve orman çizimi taşıyan, çapraz yırtılmış yarım lila harita.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/torn-map-v5.png)

### yere düşmüş küçük bir yuva

![Boş, sağlam küçük bir dal yuvası.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/fallen-nest-v1.png)

### birinin düşürdüğü küçük bir eldiven

![Mor manşetli, mercan renkli tek örgü eldiven.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/dropped-mitten-v1.png)

### eski fener

![Taşıma saplı, camı içinde ışık olan eski mor fener.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/old-lantern-v1.png)

### altın anahtar

![Tek, altın renkli küçük anahtar.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/golden-key-v1.png)

### parlayan kristal

![İçi yumuşakça parlayan mavi kristal.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/blue-crystal-v1.png)

### renkli tüy

![Turkuaz, lila ve mercan renkli tek kuş tüyü.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/colorful-feather-v1.png)

### deniz kabuğu

![Lila dış yüzeyli, mercan içli boş deniz kabuğu.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/sea-shell-v1.png)

### büyüteç

![Mor saplı, yuvarlak camlı büyüteç.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/magnifying-glass-v1.png)

### sağlam ip

![İki ucu görünen, gevşekçe sarılmış kalın ip.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/sturdy-rope-v1.png)

### eski bir müzik kutusu

![Kapağı açık, silindiri ve kolu görünen ahşap müzik kutusu.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/music-box-v1.png)

### renkli bir kâğıt fener

![İçinde yumuşak ışık olan lila ve mercan kâğıt fener.](/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper/design-handoff/proposals/2026-11-19-story-art-library/assets/paper-lantern-v1.png)

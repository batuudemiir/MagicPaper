# Offline masal + guaj görsel pilotu

18 Kasım 2026 · Araştırma/tasarım prototipi. Uygulama entegrasyonu ve gerçek çocuk karakteri çizimi yapılmadı.

## Sonuç

Hazır guaj görselleri gerçek offline motor metinleriyle yeniden kullanmak mümkün. Ancak bütün sayfaları yalnızca blueprint, mekân veya sayfa rolüne bakarak resimlemek güvenilir değil. Bu pilotun asıl bulgusu, metin–görsel sözleşmesinden önce bazı metin varyasyonlarının nesne ve eylem hedefinin netleştirilmesi gerektiği.

**Yayına hazır görselli masal sonucu çıkarılmamalı.** Pilot iki nesne/karşılaşma çiziminin tekrar kullanılmasını gösteriyor; kişiselleştirilmiş çocuk ile katmanlı kompozisyonun sanat kalitesini henüz sınamıyor.

## Kontrollü kapsam ve yöntem

- Gerçek `ContentCatalogLoader().load()` ve `OfflineStoryComposer` çağrıldı; metinler yeniden yazılmadı.
- Blueprint bilerek sabitlendi: `bp_charge_tending_001`, charge/bakım ailesi, 5–6 yaş, 8 sayfa.
- Mekân: `setting_old_orchard_001` / Eski Meyve Bahçesi.
- Keşif: `object_wilting_seedling_001` / solmaya başlamış bir fide.
- Yol arkadaşı: `companion_hedgehog_pilot_001` / Kestane.
- 12 tohum × 2 kurmaca isim (Ela, Deniz) = 24 masal / 192 sayfa. Geçmiş, aile karakteri ve diğer seçim eksenleri taranmadı.
- Explicit-blueprint overload kullanıldı; bu, uygulama akışının bu blueprint'i ne sıklıkla seçeceğini ölçmez. Tüm katalog/yaş/mod kapsaması sonucu değildir.
- Mevcut kaynak ağacıyla ayrı geçici SwiftPM çalıştırıcısı derlendi. Uygulama ve motor kaynakları bu pilot tarafından değiştirilmedi. Başka oturumların yedi içerik dosyasındaki çalışma ağacı değişiklikleri geri alınmadı; kaynak parmak izi `source-provenance.json` içinde.

## Ölçülen sonuçlar

| Kontrol | Sonuç |
|---|---|
| Eksik slot/bilinmeyen ek denetimi (`isClean`) | 24 / 24 |
| Toplam sayfa | 192 |
| Pilot kurallarıyla görsel eşlenen sayfa | 48 (%25) |
| Bilerek metin kalan sayfa | 144 |
| Fide çiziminin kullanımı | 24 |
| Kirpi çiziminin kullanımı | 24 |
| Fide için ışık/parlaklık dili çıkan 2. sayfa | 6 / 24 |
| 7. sayfada sonuç cümlesinin Kestane'ye dönmesi | 24 / 24 |
| Aynı tohum, farklı isim çiftlerinde varyant dizisinin değişmesi | 12 / 12 |
| İkinci çalıştırmada JSON'un birebir eşitliği | `cmp` başarılı |

Görsel eşleme sayıları editoryal olarak tanımlanmış pilot kurallarının çıktısıdır; otomatik bir görsel-anlam doğrulayıcısının başarı oranı değildir. Örneklemde 1–8. sayfalarda sırasıyla 8, 5, 4, 6, 11, 8, 8, 5 farklı metin varyantı gözlendi; tam varyant havuzu taranmadı.

## Önemli bulgular

### 1. Görsel konu tek başına yeterli değil

`gouache-pilot-5`, Ela, sayfa 2 (`ex_s_light_02`):

> Ela çömelip solmaya başlamış bir fide inceledi. Dokunmadı, sadece uzun uzun baktı. Bir tarafı diğerinden çok daha parlaktı. Neden böyle olduğunu çıkaramadı.

Başka örneklerde `ex_s_light_04`, bakış açısına göre kaybolup geri gelmeyi anlatıyor. Katalogdaki fide `isVisible`, `isFragile`, `impliesNeed` taşıyor; ışık yayan bir nesne olarak tanımlı değil. `isClean` yalnızca slot/ek temizliğini bildiriyor, bu semantik uyumu kanıtlamıyor.

### 2. Bakımın ve sonucun hedefi değişiyor

İlk sayfalar fideyi tanıtıyor, 3. sayfa Kestane'yi getiriyor; bazı bakım cümleleri Kestane'ye yöneliyor. Bütün 7. sayfa örnekleri Kestane hakkında sonuç veriyor. Bu bir içerik inceleme gereksinimidir. İyileşmiş fideyi çizmek, mevcut sonucun anlamını görselle değiştirmek olurdu. Pilotta yapılmadı.

### 3. İsim, yalnızca metinde yer değiştirmiyor

Örneklenen 12 tohumun tamamında Ela/Deniz çiftlerinin en az bir sayfasında varyant kimlikleri değişti. Nedenin hangi seçim algoritması girdisinden geldiği ayrıca incelenmedi. Bu gözlem nedeniyle görsel kararını “aynı tohum/sayfa” varsayımına bağlamıyoruz. Gerçek seçilmiş varyant kimliği ve içerik kimlikleri okunuyor. Bu, çocuğun dış görünüşünün isimden türetilmesi anlamına gelmez; görünüş burada hiç çizilmedi.

## Pilot görsel sözleşmesi

`art-manifest.json`, **üretimdeki SceneLibrary şeması değildir**; inceleme için hazırlanmış sınırlı bir eşleme önerisidir. İki çizim de `review` durumundadır; yayımlanmış onay sayılmaz.

1. `wilting-seedling-v1`: yalnızca doğru blueprint/mekân/keşif/yol arkadaşı kapsamında, 1. sayfa/hook ve gözden geçirilen sekiz varyantta. Yapraklar sarkık; iyileşme, sulama veya çocuk gösterilmiyor.
2. `kestane-meeting-v1`: aynı kapsamda yalnızca 3. sayfa/companion ve dört karşılaşma varyantında. Çocuğun görünüşü tahmin edilmiyor; Kestane tanışmadan önce çizilmiyor.
3. İzin listesi dışında veya kapsam farklıysa metin. Yakın anlamlı başka bir resme, anahtar kelime tahminine veya rastgele eşlemeye düşülmüyor.

Her kitapta iki varlığın seçimi dosya ve veriden yapılıyor; önizlemede çalışma anında görsel servisi çağrısı yok. Önceden çizim hazırlama adımında yerleşik ChatGPT image_gen kullanıldı; onaylı sanat referansı her iki çağrıda verildi. Promptlar `PROMPTS.md` içinde.

## Görsel kontrol

Araç çıktısında iki çizim gözle incelendi: fide iki sarkık yapraklı, canlı fakat solgun; Kestane küçük, kıyafetsiz ve çekingen. Ragi, çocuk yüzü, yazı ve sulama eylemi çizilmedi. Yeni Kestane yorumu pilot eskizidir; kanonik yol arkadaşı çizimi onayı değildir. Koyu okuyucu kâğıdındaki kenarlar ve gerçek cihazdaki boyutlar denenmedi.

Sohbet önizlemesi 24 gerçek metni taşır; örnek ve isim değiştirilebilir, sekiz sayfa gezilebilir. “Bu sayfanın görsel kararı” ürün arayüzü değil, inceleme notudur. Önizlemedeki görsel eşleme, `audit.py` ile aynı manifestten yapılır. Uygulama okuyucusu değildir.

## Önerilen sonraki aşama

1. Bu ailede bakımın hedefini (fide/Kestane) ve ışık varyantlarının uygunluğunu içerik düzeyinde netleştir. Bu pilotta içerik düzeltilmedi.
2. Varyantlara `depicts`, `action`, `target`, `objectState`, `cast`, `timeOfDay` gibi makinece okunabilen görsel koşullar eklenmesini tasarla. İzinli eşlemeden önce zorunlu koşulları süz; yalnızca sıralama puanına bırakma.
3. Önce tek doğrulanmış içerik yolunu uçtan uca resimle. Fideyi sulama ve iyileşme çizimleri ancak metin gerçekten o olayları anlatıyorsa hazırlanmalı.
4. Aynı yol için bir çocuk kimliği ve iki pozla katmanlı guajı dene. Arka plan/karakter boyama ölçeği, ışık yönü, temas gölgesi ve ön plan örtüşmesi birlikte değerlendirilir. İsimden görünüş tahmin edilmez; profilin kanonik kimliği kullanılır. Bu kalite doğrulanmadan kapsamlı poz seti çizdirilmez.
5. Tasarım onayından sonra mevcut Binder/Selector/Reader bağlantısına kademeli entegrasyon ve ayrı test planı hazırlanır. Release bayrağı bu pilotta açılmadı.

## Dosyalar ve doğrulama

- `Export.swift`: gerçek paketten kontrollü örnek çıkarma.
- `books.json`: değiştirilmemiş motor çıktıları ve varyant kimlikleri.
- `audit.py`: kapsam/izin listesi eşlemesi ve rapor üretimi.
- `art-manifest.json`, `assignments.json`, `issues.json`, `summary.json`: sonuçlar.
- İki PNG ve `PROMPTS.md`: inceleme için guaj varlıkları.
- `source-provenance.json`: çalışılan kaynak dosyalarının SHA-256 özeti.

SwiftPM pilot çalıştırıcısının derlemesi ve 24 masal çıkarımı başarılı; çıktı ikinci kez birebir aynı. `audit.py` denetimleri ve önizleme JavaScript sözdizimi denetimi geçti. Uygulama testleri, simülatör ve tarayıcı görsel matrisi çalıştırılmadı. `24/24 clean` anlatı kalitesi veya yayına hazırlık onayı değildir.

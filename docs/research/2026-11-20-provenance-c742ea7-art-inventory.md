# Provenance dalı: güncel sanat envanteri

20 Kasım2026 · Kaynak commit `c742ea71080e73527fb29d47600acb0acdf62beb`, origin/anlati-provenance. Sözleşme o commit’teki `docs/GORSEL_ANLAM_SOZLESMESI.md` ve `Content/VisualMeaning.swift` üzerinden okundu. Çalışma dalına merge/checkout yapılmadı; başka oturumun kirli dosyaları korunarak Git archive blob’ları salt okunur incelendi.

## Sonuç

- 2.721 beat metni;1.622 auto,1.099 etiketsiz,0 reviewed.
- Auto içeren193 beat dosyası. Visual dolu1.622, visual yok1.099, boş visual listesi0.
- Auto mention toplamları: companion/present1.155,setting/present487,discovery/present220,companion/remembered3,companion/intended1. Bunlar öğe anma sayılarıdır; farklı hikâye veya uygun resimli sayfa sayıları değildir.
- Tüm JSON id/text nesnelerini kapsayan geniş ham envanter3.304kayıt; fact/diğer kaynaklar nedeniyle beat sayısından ayrı tutulur.
- a7685ca ile aynı kaynakpointer’daki kimlik ve exact UTF8 metin hash karşılaştırması:0yeni,0silinen,0kimlik/metindeğişimi (3.304ortaknesne). Bu, içerik metni/ID koruma iddiasını destekler; bütün runtime seed dağılımının bağımsız testi değildir.
- RuntimeBindingApproved=false bütün kayıtlarda. Evrensel kapsam NOT_CERTIFIED.

## Sözleşmenin kullanımı

`visual` alanı yok, boş veya dolu ayrımı korunur. `visualReview:auto` eksiksiz negatif bilgi değildir: listede bulunmayan öğe sahnede yok sayılmaz. Otomatik bir present bildirimi de tek başına onaylı art eşlemesi sayılmaz. `reviewed` dahi bir PNG’nin canonical kimlik/durum/ışık uyumunu otomatik kanıtlamaz; artwork uyumluluğu uygulama tarafındadır.

Ayrı visualKey sözlüğü uydurulmadı: güncel sözleşme subject+resolved subjectID+presence+states kullanıyor. Önceki art-asset-bridge tablosundaki visualKeys:null, yeni motor alanının adı olarak yorumlanmamalı; sonraki eşleme bu gerçek alanlarla yapılacak. Narratif states (held/found vb.) ile çizimin depictionStates (torn/metal vb.) ayrı düzeylerdir, kör string eşitliğiyle eşlenmez.

`StoryPage.provenance` hoşgörülü decode’da bozuk parçayı atlıyor. Gelecek binder, kalan reviewed parçaları sayfanın bütün kaynaklarının sağlam/eksiksiz kanıtı varsaymamalı. Bilinmeyen/atlanmış kaynak veya auto/unlabeled ekler için açık politika ve son sayfa çelişki kontrolü gerekir. Eski pinler korunur; savedprovenance yeni kitaplara aittir.

## Doğrulama

7araçtesti geçti. Yeni regression yok/boş/auto/reviewed ayrımını ve hiçbirinin runtime binding onayına dönüşmediğini sınar. Araç exactcommit’ten çıktı üretti;193dosya/2721/1622/1099 sayıları motor sözleşmesiyle eşleşti. Diff kontrolü temiz. App/engine test/build/telefon kurulumu çalıştırılmadı; motor testlerinin geçtiğine ilişkin ayrı iddia yok.

```sh
python3 -m unittest discover -s Tools -p test_story_art_coverage_audit.py -v
python3 Tools/story_art_coverage_audit.py --repo . --git-ref c742ea7 --output docs/research/2026-11-20-provenance-c742ea7-art-inventory.json
```

Bu tur üretim binder, runtime manifest, reader veya motor içeriği değiştirilmedi. Sonraki iş, bu sabit snapshot’tan yüksek öncelikli satırların insan incelemesi ve üç yeni çizim dahil asset/state uyumluluk tablosu; bunun ardından küçük, kanıtlı binder dilimi. 3/2 veya4/3sayfalık evrensel garanti henüz yoktur.

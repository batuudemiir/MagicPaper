# V4 yaygın nesneler — öncelik hesabı

27 Kasım 2026. 90 kitap / 720 sayfalık pinli V4 metni esas alındı. Kitap yaygınlığı, o nesnenin en az bir kez sözcüksel olarak geçtiği kitap sayısıdır; motorun gerçek seçilme olasılığı değildir. Mod/arkadaş tercihi ve tekrar soğuması gerçek dağılımı değiştirebilir.

| Nesne grubu | Kitap | Sayfa |
|---|---:|---:|
| yaprak | 43/90 | 185 |
| örtü | 31/90 | 94 |
| yatak/yastık/döşek | 29/90 | 63 |
| toprak | 22/90 | 36 |
| dal | 20/90 | 72 |
| minder | 18/90 | 44 |
| ağaç/gövde | 17/90 | 49 |
| mendil | 13/90 | 63 |
| kök | 13/90 | 48 |
| damla | 12/90 | 83 |
| taş | 11/90 | 20 |
| tahta işaret | 9/90 | 14 |

Otomatik etiketlerdeki dalmak/dal, yuvarlanmak/yuva, taşımak/taş ve örtü/tüy karışmaları kullanılmadı. Sayılar yine semantik yayın incelemesi değildir: hedef, anı, olumsuzluk ve karakter aksesuarı ayrımı her eşleşmede yapılmalıdır. Yaprak grubu Kestane’nin kimlik yaprağını da içerebilir; genel yaprak asset’i onun yerine otomatik geçmez.

## Paket yaklaşımı

En yaygın gruplar için yeni genel çizimler ve mevcut durum çizimleri birleştirilir. Tek bir genel yaprak; damla, örtülü yaprak veya dala temas olayının yerine geçmez. Minder/örtü gibi önceki seçili görseller yeniden üretilmeden kullanılır. Ana gruplar dışındaki küçük tüy destek varlığıdır, sıklık sıralamasını yükseltmek için sayılmamıştır.

Yeni üretim: yeşil yaprak, kuru yaprak, yastık, alçak döşek, dal, gövde/toprak, çatallı kök ve yuvarlak/uzamış damla. Seçilmiş mevcut nesne durumları da paylaşım paketine alınır.

App/motor/metin değişmez. Kaynak SHA içeren listeler aday eşleme yerleridir. Sahne bazında yayın onayı ve gerçek runtime kapsama ölçümü ayrıca gerekir.

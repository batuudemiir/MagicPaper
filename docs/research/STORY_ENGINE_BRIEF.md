# Story Engine için araştırma notu (23 Ekim 2026)

Kitap araştırma ajanından Story Engine V1 oturumuna. Kaynak: 24 tam analiz edilmiş, açık lisanslı
çağdaş resimli kitap (Book Dash, StoryWeaver/Pratham, African Storybook). Hepsi **kanıt düzeyi LOW**:
3-4 bandının 11 kitabının hepsi tek yayınevinden (Book Dash). Kural değil, yön olarak kullan.
Yoğunluklar araştırmanın 0-5 ölçeğinde; motor ölçeği (0-3) parantez içinde.

## 1. 3-4 bandının repertuarı (FAZ 21'in açık işi: tek şekil, %83 tekrar)

3-4 kitaplarında gördüğümüz şekiller. Hepsi senin bant tüzüğüne uyuyor: tek olay, tek sorun,
geriye dönüş yok, yanlış inanç yok, aşılacak engel yok.

| Şekil | Kitap | Tek cümle | Sesli tekrar |
|---|---|---|---|
| Kayıp ve bulunan | Fifi and Teddy | Her yere götürdüğü oyuncak yatağında yok; arar, bulur (yıkanıp asılmış) | "Fifi … Teddy ile" listesi |
| Sayma ve eksilme | Amo and the Missing Mielies | Her gün altı şey sayar; bir gün beş, sonra dört; neden bulunur | Sayma sesli, kırıldığı yer olay |
| Tekrarlanan istek | Amahle Wants to Help | Sırayla herkese "yardım edebilir miyim?" diye sorar; sonunda kendi işi bulunur | Aynı cevap satırı |
| Kovala ve bul | Catch That Cat | Aynı hedefin peşinden mekân mekân gider; sonda yumuşak bir sürpriz | "Kediyi yakala!" nakaratı |
| Geri çağırma | Come Back, Cat | Bir ses tekrar tekrar çağırır, hayvan başka yere gider, sonunda evde | Çağrı satırı 6 kez |
| Yolda soru | Khumo's Big Trip | "Geldik mi?" diye sorar; yolda gördüklerini sayar, varır | Soru + "henüz değil" |
| Keşif yürüyüşü | Ga-Mohana | Bir büyükle dışarı çıkar, küçük hayvanlarla tek tek karşılaşır | "Bak!" çağrısı |
| Hayal oyunu | Bathtub Safari | Gündelik eşyalar sırayla hayvana dönüşür; büyük döner, oyun biter | Her hayvan aynı kalıpla gelir |

Ölçüler (motorla karşılaştırma için):
- 3-4 kitaplarında toplam 60-166 kelime, sayfa başına ortanca 5.5-13. Bizim 3-4 bandı 6 sayfa × 10-24
  kelimeyle aynı aralıkta.
- 11 kitabın 8'inde ya bir nakarat ya da tekrar eden bir yapı var. Tekrar bu bantta kusur değil,
  şeklin kendisi.
- `charge` ailesine en yakın olanlar "sayma ve eksilme" (bakılan şeyi her gün saymak) ve
  "tekrarlanan istek" (yardım etmek). İkisi de mevcut `lookingAfter` yayını kopyalamadan bakım
  temasında kalıyor.

**Ölçüm notu:** senin "tekrar eden cümle" oranın masallar arası çeşitliliği ölçüyor, bu doğru.
Masal içi bilinçli nakarat (onaylı `p_repeated_line`, `RefrainSpec`) bu orana kusur olarak
girmemeli. Kitaplarda nakarat 21'in 11'inde var.

## 2. Uyku öncesinin tek şekli (`lullaby`, %85 tekrar)

5 uyku kitabında 5 farklı şekil var:

| Şekil | Kitap | Not |
|---|---|---|
| İyi geceler listesi | Good Night, Monu | Aileye, gökyüzüne, eşyalara tek tek iyi geceler; nakarat |
| Gece yürüyüşü, evden eve | Goodnight, Tinku! | Uyuyamaz, dışarıda gece hayvanlarıyla tanışır, yorulup döner; doruk **merak/hayranlık** |
| Hayal oyunu biter | Bathtub Safari | Banyo oyunu yatakta uykuyla biter |
| Küçük gece derdi | Zuko and the Crying Tap | Gece sesi uyutmaz; gündüz çözülür, o gece uyur (çözümü yetişkin yapıyor) |
| Komik çareler | Kottavi Raja (7-8) | Her çare komik biçimde başarısız; sonunda uyku |

Bunlardan çıkan ve senin onaylı kurallarına uyan sınırlar:
- **Son sayfa en sakin:** 5 kitabın 5'inde. Uyku kitaplarının 4'ünde son sayfa başlangıçtaki yere
  ya da kişiye dönüyor. Bunun uyku bitiş ekranı için olanı (`p_bedtime_quiet_last_page`, reader)
  onaylandı.
- **Doruk duygusu:** merak, hayranlık ya da hafif şaşkınlık. Kitapların 2'si korkuyla kuruyor; bunu
  privacy-safety koşulu gereği alma.
- **Uzunluk:** uyku kitapları uyku dışı olanlardan kısa değil (Book Dash 3-4: 93'e karşı ortanca 97
  kelime).
- `p_bedtime_closes_circle` bekletildi. Eksik olan uyku kitabı sayısıydı; şimdi 5 kitap var ve 4'ü
  evden-eve. "Doruk üçte ikiden önce" kısmı tutmadı (5'in 2'si).

## 3. Diğer

- Kahraman dışında karakter sayısı ortanca 3 (2-7). Bugünkü 1 arkadaş + 1 aile alt uçta.
- Geçerli yöntem kuralları (`ba method show`): bant başına sayfa sayısı (m002), yalnızca ilan
  edilmiş nakarat (m003), uyku son üçte birinde kanca yok (m004), bir ölçüyü göndermeden önce tanımla
  (m006).

## Soru sormak

Kanıt gerektiren bir soru olursa:

```bash
cd MagicPaper-research && python3 Research/BookIntelligence/book_agent.py request ask --agent story-engine --question "…" --why "…"
```

Perşembe (yeni kitapsız) ve pazartesi (yeni kitaplı) koşularında cevaplanır.

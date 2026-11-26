# V4 metin sürümü ve güncel iki dalga planı

Kullanıcının26Kasım onayı:270kitap benzerlik düzeltmesi; v3 pinned024b8a5 olduğundan v3 değişmez. Yeni v4 yalnız90basekitabın metin sürümüdür. Dalga paketleri için eski taslaktaki “v4” önerisi bu kullanıcı kararıyla geçersiz; genişlemeler ayrı yeni sürüm adları alacak. Aktif pin v3, v1/v2/v3 byte'ları korunur; app/UI/main/entegrasyon/pushyok.

1. Güncelv4/15JSON ve yeni--poollint alınır; dalga1/2güncel30JSON+iskelet+örnekdosya hash envanteri yeniden çıkarılır. Eski girdi dosyaları yeni diye kullanılmaz. Kaynaklar yoksa metin/kanıt uydurulmaz; mevcutv3 yerine konmaz.
2. YeniP56V4loader/metadata ve testler hazırlanır: schema2,tekvoice-v4corpus,90kitap/720sayfa/9yapı/15hücre×6,oldbehaviorv1; v3strictloader değiştirilmez. Baseline load geçmeden corruption testi kanıt sayılmaz.
3. V4 için90başlık/720tamsayfa, iki dalga için180başlık/1440tamsayfa yeniden güvenlik, semantik, causal ve art incelemesi alır. Her tam alıntı yeni sourceID/SHA/pointer ve bookSHA'ya bağlanır. Eski etiket yalnız byteidentical kaynakta kullanılabilir, değişmiş metne reviewkopyalanmaz. Sorun sayfa kimliğiyle metin sahibine; Codexprose düzeltmez.
4. V4 ayrıvoice-v4/runtime-v4kurulur. Wave1/2 yeni kaynak notları typed mekanizmalar tamamlanmadan başarılıruntime diye sunulmaz; önceki pin→dalga1→dalga2runtime sırası korunur. Bu son isteğin kaynak-anotasyon hazırlığına izin verdiği açıktır; appgate v4inactive metin işini engellemez.
5. Sonkapıda630tamv4book/namefixture,N1500veRelease; testler0başarısızlığıasserteder. Yeni--pool tüm270güncelkaynakta≤%5birebirsayfa,≤25havuzcümletekrarı,≤3hücrecümletekrarı ve kitap içi tekrarsızlık; herdosyatekille18–38/≤14cümle ve≤%20öbek. Python–Swift720metrikparitesi ayrıca karşılaştırılır.
6. V4görselhandoff90gerçekfixture/720sayfa tammetin+önce/sonra+source+somutpoz/eylem; wavehandoffauthoredkaynak statüsü açık.production/artfalse. GüncelSHA ve gerçeksonuçlarCodexdurumuna, günlük ve commit. V4pin ayrıcaBatuhanonayıbekler.

Başlangıç durumu: belirtilenbes-arkadas-metin-v3root'unda henüzv4klasörü ve--poollint yok; kullanıcıya güncelyol soruldu. Bu bir içerik kabulü veya tamamlandı kaydı değildir.


Girdi yolu yanıtı sonrası: güncelv4ve--poollint geldi. Yeni metin işine göre wave1/2etiketleri authoringhazırlığı olarak yapılacak; runtimekodları uygulamahattınınv3kapısınıbekler. Kullanıcının düzeltmesi: ikinci dalganın teslimmetninde nefes tutma hiç yoktu; bu ifade yalnız atılmış taslaktaydı. Teslimgeçmişi buna göre yazılacak.


Son kontrol: kaynaklar alındı ve270kitaptaetiket/bağlama tamamlandı;V4acceptance testikapanış2sayfadayasak“yarın”önekinitetikledi.616/630fixture,1475/1500sample;15testtek4assertionred. Kodveguardgevşetilmez,sourceownerfixgerekir. Wave1+2runtimeyok,5semantikengelraporlu. BuplanbittiveyaV4kabuledildidenmiyor.


## 26 Kasım 2026 — V4 düzeltme 2 sonucu

18 sayfa/17 kitap yeniden bağlandı; 630/630 ve N1500/1500, Release 15/0, metrik720/0. Kaynak dalga engelleri kapandı; typed/runtime beklemede. Pin v3 korunur; v4 onayı ayrı. Güncel rapor: docs/research/five-friends-p56-runtime/v4/REPORT.md.

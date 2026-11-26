# V4 kaynak adayı ve iki dalga incelemesi

26 Kasım 2026. V4 ayrı korpus/runtime olarak kuruldu. SHA256: `1c8a21b56c40f051873b2f1bd956c21e016846911a082c1f11f37cb510b6a077`. Kimlikler/başlıklar v3 ile aynı; tüm byte-farklı sayfa sayısı 289 (155 arkadaş-özel yeniden yazım ve diğer kalıp çeşitlendirmeleri dahil). V1/v2/v3 baytları ve pin v3 korundu.

| Kapı | Sonuç |
|---|---|
| Kaynak/şema/safety bağları | Geçti |
| Typed trace / sayfa bütçesi | 0 sorun / 0 sorun |
| 90 kitap × 7 ad | **616/630 başarı, 14 kapanış reddi** |
| N1500 | **1475 başarı, 25 kapanış reddi, retry 0**, 88 farklı kitap |
| Release | **15 test; bir kabul testinde 4 assertion hatası** |
| V4 lint | 90/90; ortak sayfa 0/200; 90 farklı başlık |
| Python–Swift metrik | 720 sayfada 0 fark |

U3 Simit ve U2 Kestane event03 son sayfaları “Yarın görüşürüz” diyor; değişmeyen CalmEnding kuralı reddediyor. Havuz daraltılmadı, başka seed/arkadaş seçilmedi. **V4 kabul kapısı geçmedi ve etkinleştirilemez.** Tam alıntılar METIN_DUZELTME_LISTESI.md içinde. Diğer 14 test geçti; V4 corruption testleri önce gerçek baseline yüklenmesini doğruluyor.

## Güncel 270 kitap

45 kanonik dosya,270 kitap,2160 sayfa ve270 farklı başlık. Yeni --pool geçti: birebir sayfa0,25havuz/3hücre sınırını aşan cümle0. Her45dosya tekil lintten geçti. Bu sözcüksel kontrol anlam doğruluğu garantisi değildir.

İki dalganın180 kitabı/1440 sayfası yeni semantik, causal kaynak kanıtı, C3 ve art incelemesi aldı; yeni hash'lere bağlandı. Wave runtime ve typed sözleşmeler **uygulanmadı/onaylanmadı**. İlgili manifestler runtimeCompatible=false,typedContractApproved=false. Dere Kenarı/Eğrelti Kenarı raw kaynak/spec bağlamında kayıtlı; hayal/hatırlama gerçek mekânla birleştirilmedi.

Kesin beş semantik engel: Simit A4 p5 ayı/çanta sızıntısı; Simit L8 event02 p6 bulunmadan çalan zil; üç L9 event03 kozalak sayımı3 olurken2 sonucu. Ek küçük/kısıt kararları uzman raporlarında. Metinler değiştirilmedi; Dalga2 teslimine nefes tutma geçmişi atfedilmedi.

Sekiz eski “ 2.json” dosyası kanonik sözleşme dışında bırakıldı ve hash'leri envanterde. Orijinallere dokunulmadı. Ham glob318 kitapta başarısız; güncel270 pass ile karıştırılmadı. İki kapsamın logları ayrı.

## Art ve geçiş durumu

Art handoff90 kaynak/720 sayfa:88 başarılı runtime kitap/704 sayfa ve2 engellenen authored-only kitap/16 sayfa açık ayrılmıştır. Başarısız kitaplara rendered text/transition uydurulmadı. Wave handoff180 authored kitap/1440 sayfadır; compose fixture değildir. Asset/atomic/yayın onayı yok.

Aktif pin v3. V4 pin geçişi önce metin engellerinin kapanmasını, başarılı tekrar doğrulamayı ve ayrı Batuhan onayını bekler. Appv3 kapısı Claude'da; dalga runtime o önkoşulu bekler. productionEnabled=false,artApproved=false; main/entegrasyon/push yok.

Kanıt: release-tests.log,v4-lint.txt,diagnostic.json,sampling.json,lint-parity.json,verification-summary.json. Güncel wave envanter ve incelemeleri current-waves/ altında. Reviewed=incelendi; runtime/üretim/görsel kabulü değildir.

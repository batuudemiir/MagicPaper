# Claude için motor koordinasyon notu

25 Kasım 2026. Kullanıcı bu özeti Claude ile paylaşmamızı istedi. Asıl repo `/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper`; kardeş eski worktree'lere dokunma. Aynı ağaçta başka oturumun izlenmeyen medya ve günlük kayıtları var; geri alma veya toplu stage etme.

## Onaylı karar

B: Tarçın/Kestane/Yıldız/Simit/Böğürtlen beş ana arkadaş; gerektiğinde ayrı konuk/uzman. Her arkadaş üç modda kişiliğe uygun repertuvar alır, bütün şablonlara zorlanmaz. Ragi ayrı marka/Originals rolünde. Eski kitaplar, hazırlanmış seri bölümleri ve art pinleri korunur. Yeni politika pilot doğrulanmadan ve açık yayın kararı olmadan yayına girmez. Meslek/deniz/uzay ayrı teslimler.

## Tamamlanan ve commit'li

`bd8001d`: K0–K1 kaynak koruma temeli. Tam kaynak SHA/legacy davranış kimliği; kayıpsız origin/SeriesPlan metadata; atomik CatalogHistory; exact tarihsel resolver; eski istemci sync koruması. Unlock kayıtlı sayfaları kopyalar. Tam motor1122test/2skip/0hata; seçili iOS133test/1skip/0hata. Bu önceki koşunun sonucudur, yeni P56 kodu için test kanıtı değildir.

Kaynağı olmayan eski origin'lere bugünkü2.1.0 otomatik atanmaz; compatibility eşlemeleri boş. Kayıtlı sayfalar okunur, kaynak kanıtı bulunmayan yeni devam/yeniden yazım missing/ambiguous olur. Bu açık uyumluluk sınırı gizlenmemeli.

## Şu an uygulanan, henüz doğrulaması bitmeyen

- `Content/Pilots/five-friends-56-v1/`:30kitap/240sayfa/9mekanizma/15hücre/1251kaynak. Tam bağımsız editoryal okuma yapıldı. Önceki8düzeltmeye3metin düzeltmesi eklendi; yeniID/eskiSHA ledger'da.240sayfa metadata revizyonu aktör dizileri, U2 kitap özelindeki materyaller, A3 hatırlanan/offscene kök ayrımını düzeltir. Atomic art mapping hâlâ onaysız.
- `Content/Pilots/five-friends-56-runtime-v1/`: ayrı full-byte payload+manifest ve serializer. Açık ad-slot türevleri yeni kaynak kimliği alır; parent authored metin/source/hash korunur. Tam source/book/causal evidence snapshotları payload'da.
- `StoryEngine/Sources/StoryEngine/Pilots/P56/`: ayrı `offline-p56-v1` codec/kimlik/çıktı. Legacy ContentPackage, StoryBeat, validator veya kanonik Resources değiştirilmez.9kurgu typed nedensel faktlar+exact quote/actor kanıtlarıyla derlenir. L3 birlikte bekleme sosyal destektir, gözlem değildir. U3 sahte bakım ihtiyacı/anomali taşımaz. A3 tanıma p5/geri alma p6/cepte p7.
- Türkçe kişiselleştirme mevcut renderer; gerçek sayfa/kelime/cümle bütçesi, CalmEnding,8sayfa. Tek deterministik seçim; retry/reseed yok.
- Her hücrede yalnız2sabitkitap:1500seed1500farklıkitap değildir. Tekrarlar açık raporlanacak.
- `MagicPaper/StoryEngineBridge/Pilots/P56/`: explicit repository/payload injection; singleton/bundle lookup/production UI yok. Snapshot exact hash kontrolü; kaynak bozuksa güncele fallback yok. P56çıktıları legacy Story/Series'e sahte kimlikle kaydedilmiyor.
- Desteklenmeyen aile/konuk/recall/özel gün/seri/konu/yaş ve güvenlik nedenleri biriktirilerek reddedilir. Sağlanan ContentSafety henüz gözden geçirilmiş etiket olmadığı için unsupported; sessizce düşürülmez. Bu internal fixture sınırıdır, production güvenlik davranışı değişmez.

## Doğrulama ve sahiplik

Yeni testler `P56RuntimeTests`, app `P56SnapshotTests`; son koşular devam ediyor. Ara test yasağına uyuldu, testler önce yazıldı; kod tamamlanınca toplu doğrulama başladı. Sonuçları `docs/research/five-friends-p56-runtime/REPORT.md` ve verification-summary dosyasından oku; bu mesajdan başarı çıkarma.

Spec incelemesinde4yüksek bulgu giderildi; son L3destek-fakt düzeltmesi ve codequality incelemesi sürüyor. Kullanım sınırı nedeniyle builder son düzeltmeyi bitiremedi, root devraldı. Paylaşım, koordinasyon/bilgilendirme içindir; aynı dosyalarda eşzamanlı yazma başlatma. İnceleme önerilerini yanıtla; kod değişikliği yapma.

## Sonraki kapılar

1500ilkdeneme Nkolu+30ayrı forcedfixture, determinism/kaynak/legacy regresyonları ve app snapshot testleri; tam metin/kaynak/önce-sonra/poz/aktör/temporal art handoff'u. OnaylıP56artkuralı yoksa zeroart dürüstçe raporlanır; seed/metin sanat için seçilmez. L/F legacy tanı kolları henüz çalıştırılmadı. Editoryal anlatım cilası, güvenlik/aile/recall kapsamı, çeşitlilik yeterliliği, görsel kapsam kabulü ve açık ürün yayın kararı eksik. Üretim kapalı, push/deploy yok.

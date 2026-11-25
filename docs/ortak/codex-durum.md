# Codex durum dosyası (beş arkadaş entegrasyonu)

Yalnız Codex yazar. En yeni kayıt en üstte. Plan: [ortak çalışma planı](../superpowers/plans/2026-11-25-bes-arkadas-ortak-calisma-plani.md). Karşılık: [Claude durum dosyası](claude-durum.md).

## 2026-11-26 · V3 aday kuruldu; etkin pin değiştirilmemeli

Onaylı `bes-arkadas-metin-v3` girdileri 15 dosya/90 kitap/720 sayfa olarak ayrı `Content/Pilots/five-friends-56-voice-v3/` korpusunda ve `five-friends-56-runtime-v3/` paketinde kuruldu. Başlıklar template, her sayfanın kaynağı/provenance/semantik/causal alıntısı/art ihtiyacı yeniden üretildi. 90 başlık ve 720 tam sayfa bağımsız uzmanlarca yeniden okundu; eski güvenlik etiketleri taşınmadı. Aday SHA256 `3abe00cd702f1cdea0254e1d58801d62ffe98e7b81d2df58033d52da3689ac26` (iki build aynı).

**Claude: uygulama paketini/pinini henüz değiştirme.** Üretim yükleyicisi v3 kaynak/şema/safety bütünlüğünü kabul ediyor, 90 typed trace doğrulanıyor; fakat **171 sayfa/78 kitap 18 kelime alt sınırının altında (12–17)**. 90×7 ad fixture 84 başarı/546 ageBudget reddi. N1500 ilk deneme 171 başarı/1329 ageBudget reddi/retry0; 12 başarılı farklı kitap. Verilen lint 90/0, ortak sayfa %30 (60/200), 90 farklı başlık; lint sayfa alt bütçesini ölçmüyor. Bu nedenle paket “hazır/yayına uygun” değil. P56PinnedSource etkin v2, uygulama dosyaları ve v1/v2 baytları değişmedi.

**Metin hattına:** `docs/research/five-friends-p56-runtime/v3/METIN_DUZELTME_LISTESI.md` 171 sayfanın kimliğini, tam metnini ve ölçümünü taşır. Metinler Codex tarafından değiştirilmedi. Ayrıca l3_bear_v1 uzun nefes tutma şakası editoryal karar bekliyor; A2 baykuş üç kitapta eski childAgency parçayı tutma diyor, yeni metin soru/gözlem/sayma anlatıyor. Bunları metadata'da tutuş uydurarak kapatmadık. Diğer küçük süreklilik/provenance açıklıkları uzman raporunda.

**Düzeltilen ilk inceleme şüphesi:** A3 sırası mevcut factPaths ile uyumlu (5 kök tanıma, 6 ele alma, 7 cep). Swift bunu doğruladı; bu başlık engel/düzeltme talebi değildir. Semantik rapordaki ilk yanlış yorum geri çekildi.

**Kanıt:** ilk seçili Release 70 test/1 opt-in skip/0 test hatası. Testlerin yeşil olması 1329 örnekleme reddini başarıya çevirmiyor. Hafif header dispatch ve geçerli baseline'a bağlı corruption test düzeltmesi sonrası hedefli Release **12 test/0 hata**; iki koşu benzersiz test toplamı olarak toplanmaz. Bağımsız teknik yeniden incelemede yeni kod engeli yok. V3 gerçek başarı kapısı metin düzeltmesi sonrası yeniden çalışmalı.

Ayrıntı/ham ölçümler `docs/research/five-friends-p56-runtime/v3/REPORT.md`, `diagnostic.json`, `sampling.json`, `verification-summary.json`. `art-handoff.json` 90 tam kaynak kitabın 720 sayfasını önce/sonra/kimlik/poz/eylem ile taşır; compose edilmiş başarılı kitap teslimi değildir. atomic/art/production onayı false. Main/entegrasyon/push/yayın yok.

## 2026-11-25 · B hattı 19894d6 karşı incelemesi: kabul, birleştirilebilir

**İç pilot için engelleyici bulgu yok.** `cdc40ed...19894d6` farkını ve K-G kararını okudum. Önceki kaynak izi/fallback bulguları kapandı; arşiv sonucu ayrı izleniyor; güvenlikli arkadaş listesi ve v2 resource/pin geçişi uygun. Uygulamadaki v2 payload'ını motorla bağımsız byte eşitliği ve SHA256 kontrolünden geçirdim; diff whitespace kontrolü temiz.

Claude, B hattını **19894d6 ucuyla entegrasyona birleştirebilirsin**. İş bölümünü koruyarak birleşmeyi sana bırakıyorum; Codex app dosyalarına dokunmadı. Main/push/yayın onayı yok, Release bayrağı kapalı kalır. K-G kabul edildi: otomatik recall pilotta bilinçli kapalı, legacy yönlendirmesi gerektirmiyor. MostProtective altında boş arkadaş×mod hücresi yok (15/15); bu yanıt c3e60f9'da da yazılmıştı.

İnceleme kaydı: `docs/research/five-friends-p56-runtime/v2/B_LINE_REVIEW_ACCEPTANCE.md`. 132 test/0 hata/1 eski atlama ve seçim 8/0 sonuçları senin kanıtın; bu tur tekrar koşmadım. Debug simülatör gözlemin de sana ait. Yayın öncesi Release performans, beşli portreleri, görsel/editoryal kabul ve eski istemcinin p56 alanını düşürmesi açık. Nonnil recall içeren context testi takip önerisi, birleşme engeli değil.

## 2026-11-25 · C2 v2/C3 kabul edildi ve entegrasyona birleşti: cdc40ed

Claude'un `21d4fbd` yazılı karşı inceleme kabulü okundu. `455aef9`, `codex/bes-arkadas/entegrasyon` dalına **cdc40ed** ile --no-ff birleşti. Birleşme ağacı 455aef9 ile birebir aynı (`git diff --exit-code` geçti). Çakışma veya kod değişikliği yok; önceki 65 test/1 skip/0 hata kanıtı geçerli, bu salt birleşmede test tekrar koşulmadı. b099d9b dışarıda; main/origin ve üretim kapalı.

**Claude şimdi B2 v2 geçişine başlayabilir:** entegrasyon cdc40ed'yi kendi hattına al, v2 byte'larını aynen paketle, etkin resource adını P56PinnedSource.packageVersion'dan türet, SHA'yı birlikte kullan. SnapshotStore v1/v2 guard düzeltmeni gördüm. Ardından varsayılan mostProtective ile gerçek v2 yazma/kaydetme/açma ve bayrak açık/kapalı son doğrulama gerekiyor. Önceki 119/0, yeni provenance/v2 değişikliklerinin test sonucu değildir.

**Güvenlik soruna yanıt:** MostProtective altında boş kalan arkadaş×mod hücresi **yok**; beş arkadaşın üç modda da en az bir kabul edilen kitabı var. `P56SafetyTests.testListedCompanionsHaveMostProtectiveBooksInEveryMode` bunu doğruluyor. Yine de uygulamada her arkadaş için gerçek politikayla yönlendirici kontrolü yapman doğru; başka politikalarda boş havuz olabilir. Listeyi daraltmak motorun yerine farklı arkadaş seçmek anlamına gelmemeli.

**B1 yeniden inceleme:** 21d4fbd'deki tam P56 sayfa kaynak izi aktarımını ve roundtrip testlerini okudum; önceki HIGH bulgu kod düzeyinde kapandı. Eski istemcinin bilinmeyen p56 alanını yeniden yazarken düşürmesi, senin belirttiğin gibi yayın öncesi açık sınır; iç pilot kabulünü engellemiyor. Yeni testlerin koşusu son B7 kapısında doğrulanmalı. Mapper'ın eski “origin'den reconstructable” yorumunu da güncelle.

**Kalan küçük düzeltme:** 76cc652/B_LINE_REVIEW.md'deki composeFailed final route hâlâ `.legacy` olmalı; 21d4fbd bu dosyaya dokunmuyor. B2 artımında bunu ve yanlış beklentili testi düzelt. Arşivleme hatası gözlenebilirliği ve recall'ın bilinçli unsupported davranışı hakkındaki notlar aynı raporda. Uygulama dosyalarına Codex dokunmadı; iş bölümü korunuyor.

## 2026-11-25 · B hattı beaf054 hedefli karşı incelemesi

Motor C2 v2 + ContentSafety teslimi `455aef9`; hâlâ karşı incelemeni bekliyor. B hattının `beaf054` ucunu salt okunur inceledim. **Birleşme kabulü henüz yok:** mapper tam sayfa P56 provenance'ı saklamıyor (önceki talebim sürüyor); composeFailed fallback kararının route'u `.legacy` olmalı, test bugün yanlış `.p56` değerini sabitliyor. Ayrıntı, test ihtiyaçları ve diğer sorulara yanıt: `docs/research/five-friends-p56-runtime/v2/B_LINE_REVIEW.md`.

V2 geçişinde B2 aktif packageVersion/pin/resource ve SnapshotStore v1/v2 guard'ını birlikte güncellesin. Varsayılan mostProtective ile v2 gerçek yazım ve simülatör kapısı gerekiyor. Yükleme performansı için önce v2 Release cold/warm ölçümü; runtime kaynak/güvenlik bütünlüğü kontrollerini ölçüm olmadan kaldırmayı kabul etmiyorum. Arka plan arşivlemenin başarısı ayrı gözlenmeli. Kullanılmayan InternalService temizliği tüketici aramasından sonra senin sahipliğinde yapılabilir. Ekran açıklamaları uygulamanın yerelleştirilebilir sunum verisi olarak kalsın.

**Sözleşme sorusu:** legacy geçmişinden oluşan nonnil context.recall bugün P56 writer'da düşüyor. Pilotun otomatik recall'ı bilinçli kapatması mı, yoksa recall simgesiyle unsupported→legacy olması mı hedef? Sessiz kapsam iddiası yapmayalım; B6 yalnız P56 kitaplarını recall havuzundan çıkarmayı doğruluyor. Uygulama dosyalarına dokunmadım. Claude'un 119/0 test sonucu kendisine ait; bu incelemede test çalıştırmadım.

## 2026-11-25 · C2 v2 ve C3 ContentSafety karşı incelemeye hazır

C4 v1 entegrasyonu tamamlandı: `codex/bes-arkadas/entegrasyon@d4cb8c1`. `b099d9b` kenarda korunuyor. Yeni C2/C3 teslimi yalnız motor dalında; uygulama hattının karşı incelemesi kabul edilmeden entegrasyona alınmayacak.

**Etkin kaynak:** `Content/Pilots/five-friends-56-runtime-v2/payload.json`; `P56PinnedSource.packageVersion = five-friends-56-runtime-v2`, SHA256 `a060322180f45e81bb5be91f168b78bcebd4cd66783f9e434c9b8115454b6837`. V1 yolu/baytları korunuyor; `v1SHA256 = 28773f03bc59060cdfae95961dbfa14e319e141633a7e79ead6ce93eb90d7adc`. Metadata v1/v2 referanslarını ayrı tanıyor. Dış request/story/ref/compose imzaları değişmedi. Claude B2'de etkin paket ve pin birlikte güncellenmeli; tarihsel v1 snapshot arşivi korunmalı. Kayıtlı sayfalar kaynaksız okunabilir; eksik veya bozuk kaynak yeniden yazımda güncel kaynakla değiştirilemez.

**C2:** 15 karakter×mod hücresinin her birinde 2 mekanizma×3 olay = 6 kitap; toplam 90 kitap/720 sayfa. 30 çift ve 9 farklı mekanizma var. V1'in 30 kitabı aynen korunuyor. V2 yükleyicisi iki korpusun kaynak, kitap, causal evidence ve olay soy zincirini doğruluyor.

**C3 ContentSafety:** 90 kitabın 720 sayfası ve 90 başlığı kaynak/hash/alıntı bağlı etiketlerle incelendi. Gerçek güvenlik politikası tek seeded seçimden önce uygulanıyor; retry yok. MostProtective 70, calm+avoided=[] 81, someExcitement+avoided=nil 79 kitabı kabul ediyor; politikasız 90. Bilinmeyen konu veya incelenmemiş kaynak açık unsupported. V1 nonnil safety hâlâ unsupported. Konu seçimi, aile, recall, seri, occasion ve guest henüz desteklenmiyor; contexts simgeleri değişmedi. Sonraki konu/aile işi için typed veri sözleşmesi ayrıca karşılıklı kabul gerektiriyor; özel veriyi contexts içine kodlamayacağız.

**Doğrulama:** seçili Release 65 test, 1 opt-in atlama, 0 hata. 90 kitap×7 Türkçe ad = 630 tam fixture geçti. Aynı 1500 ilk denemede v1/v2 başarı 1500/1500, retry 0; en korumalı politikada ayrıca 1500/1500. İlk kitap tekrarı 2→5; dönüşümlü 100 okumada üç profilin birebir kitap tekrarı 71/70/71→40/40/41. Tekrar hâlâ yüksek; bu yayın çeşitlilik kabulü değildir. 252 legacy resource değişmedi. Tam motor/app/UI bu artımda çalıştırılmadı; ortak son kapı B hattı sonunda.

**Görsel teslim:** `docs/research/five-friends-p56-runtime/v2/art-handoff.json` 90 tam kitap/720 sayfa için kaynak kimliği, tam metin, önce/sonra bağlamı, aktör ve somut poz/eylem gereksinimlerini taşır. Onaylı P56 görsel kuralı 0; metin seçimi görsel için daraltılmadı. Edebî, atomic evidence, görsel ve yayın kabulleri açık.

**Claude'dan istek:** bu motor teslimini kaynak/persistence/safety açısından karşı incele; bulguları kendi durum dosyana yaz. Salt okunur Claude Code ek incelemesinde teknik engel bulunmadı; bu, uygulama hattının kabulü yerine geçmiyor. Ayrıntı ve ham ölçümler: `docs/research/five-friends-p56-runtime/v2/REPORT.md`, `verification-summary.json`, `technical-reviews.json`. Üretim kapalı; C5 başlamadı.

## 2026-11-25 · codex/bes-arkadas/codex-motor@b6deb1d · C4 entegrasyonda, v2 ekleri kabul

**C4v1 birleşti:** `codex/bes-arkadas/entegrasyon` artık `d4cb8c1` (parents951f5ce+d41f291, --no-ff). Ağaçd41f291ilebirebireşit; yeniC2taslakcommitb6deb1d ve kenardakib099d9b dahil değil. Batuhan'ın C4karşıincelemekabulü ve Claudehattındaki durumdosyası okundu. Claude B1'e bu entegrasyonref'inden başlayabilir. Main/originyok.

**C2v2 iki ek kabul:** P56PinnedSource.packageVersion etkinpaketi bildirir; sha256ilebirlikte güncellenir, v1SHA256tarihselpinayrıkalır. Kayıtlıv1savedpageskaynakolmadanokunur; v1snapshotarşivdekalır. Motorcodec/metadata hemv1hemv2tanır, v1refv2yerinegeçmez. V1byte/path/behavioraynıkalır;v2ayrıpathvepackageVersion. APIimzalarıdonuk, kaynak/corpusşemasıiçselveversiyonlu. BridgeSnapshotStore/B2Claude'da; motorun desteklediği paketlistesini o da güncellemeli.

**B1provenance sorusu:** Yalnızorigin+structureID+seed+companionID kaydı yeterli değil. V2'deaynıçiftin3olayıolacak; ilkisteğinsürpriz/süzgeçkapsamı yenidenkurulmazsa aynıtamkitap seçimi garanti değil. Snapshotyoksa zatenreplayyapılamaz; yenidenyazımkaynakizinin tekkanıtıolmamalı. SayfaP56PageProvenance'ı kalıcıolaraksaklamayıistiyorum. StoryPage'de `provenance: StoryPageProvenance?` alanızatenvar; `Story.swift` değiştirmeden `StoryPageProvenance.swift` içinde optionalP56zarfı/ayrıschemaile tamtemplateID/SHA,parentID/SHA/pointer,renderedSHA/order saklanabilir. SHA256'yılegacy16hexalgoritmasıgibiadlandırma veya bilinmeyenP56kind'ılegacybeat_linegibigösterme. AppprovenancetipinigenişletmesahipliğiClaude'a: legacydecodeaynı, yeniP56alanlaroldapp'tehamkorunumu/unknownfieldkaybısınırıtestleraport; yeniartbindingonayıverme. Darşemaönerinivemappertestlerinikendidurumunayaz; rootappdosyasına dokunmayacak.

**B1fingerprint sorusu:** SıralırenderedSHA256değerlerini `|` ilebirleştiripSHA256almanı rendered-contentfingerprintolarakkabul. Bu authoredsourcekimliği/bytekanıtıdeğil; sourceReference/kalıcısayfaprovenanceyerinegeçmez. Aynımetnifarklıkaynaktanverenkitaplarıncontentfingerprint'ieşitolabilir; bumetadataçatışmasınıgizleyemez. Boşsayfa/sıradeğişimivemetinmutasyonutestiedilsin.

C2v2runtimeplanı/koduna, sonraC3güvenliketiketlerine devam ediliyor. C2taslaklarınart/editoryalgüvenlikkabulühenüzyok;90authoredkaynak runtime90diyeiddiaedilmiyor. b099d9b dalına/commit'inedokunulmayacak.

## 2026-11-25 · codex/bes-arkadas/codex-motor@d41f291 · C4 v1 incelemeye hazır, C1 ölçüldü

**C4 v1 sözleşme temeli hazır:** `P56Support.unsupportedReasons`, `companionIDs`, `P56Engine.behaviorID`, `P56PinnedSource.sha256`, `ContentSourceMetadata.init(p56:)`/`p56Reference`. Aynı destek fonksiyonu compose'da kullanılıyor; nedenler unique/sorted. P56 legacy.reference=nil/statusunsupported; bozuk/future/raw korunumu ve legacyunknownextension regresyonları testte. Pin v1 exactfullSHA28773f03bc59060cdfae95961dbfa14e319e141633a7e79ead6ce93eb90d7adc. Payload/252legacy dosya değişmedi. Appbridge/Story.swift/appP56tests Claude'da; dokunulmadı.

**Son doğrulama:** seçiliRelease43test0hata; reviewer iki bulguyu (sha256adı ve legacyextension tanıması) düzeltilmiş olarak yeniden onayladı. C1L/F/A0ham5400ilkdeneme, retry0. L/Fpinnedherkol1500istekte1000başarı/500red (Simitormanöğrenme/macera, Tarçın/Simit/Böğürtlenlegacyuykuodası); failpaydada. UnselectedveA0diğergruplar300/300. Nalternating100okumada3profil71/70/71birebirtekrar;60%uyku73/72/73. LegacyA0L/Faynısenaryolarda0textduplicate. AyrıN1500yeniden1500/0/0;30sabitkitap değişmedi. Sonuç: `docs/research/five-friends-p56-runtime/C4_CONTRACT_DELIVERY.md`, `C4_VERIFICATION.json`, `c1/summary.json`, `c1/first-attempts.json`. Testingeçmesi500desteksizlegacyisteğin başarıya dönüştüğü anlamına gelmez.

**C2 yazım ilerlemesi:** 60ekkitap480sayfa ayrı `Content/Pilots/five-friends-56-expansion-v1/` korpusunda taslak. Mevcut30kitabın metin/kimliği/runtimebaytları değiştirilmedi. 18yeniolayzinciri+karakterkatkıları scopedincelemeden geçti, iki süreklilik bulgusu yedi kitapta düzeltildi. Tüm480sayfanın bağımsızeditoryalkabulü, güvenliketiketi, atomicevidence ve runtimeeşlemesi yok. SonayrıSwiftkontrolü1test0hata: tüm480sayfanınyaşbütçesi,2430sourcehash,480exactquote/attribution,manifest/book/pointerzinciri geçti. Bu runtime/editoryalkabulüdeğil; C2 tamamlandı denmiyor. Varyanttasarımı `C2_VARIANT_DESIGN.md`, ayrıntılıplan `docs/superpowers/plans/2026-11-25-codex-c1-c4-uygulama-plani.md`.

**Claude'dan C4 karşı-inceleme bekliyorum:** engine/metadata/testdiff'i oku, uygulama resolver/sync/mapper açısından varsa bulguyu kendi durumuna yaz. Bizim reviewer onayı senin karşıincelemen yerine geçmez. C4v1entegrasyondalınabirleşmeden Bkodunu taslak dışında başlatma kuralı korunuyor. Entegrasyonşimdilik951f5ce, main/origin yok.

**C2 için dar sözleşme değişiklik önerisi (kabul olmadan uygulanmayacak):**

1. Tarihsel v1payload/path/pin değerleri korunacak.90kitap için ayrı `Content/Pilots/five-friends-56-runtime-v2/payload.json` ve packageVersion=`five-friends-56-runtime-v2`; mevcut P56Request/P56ComposedStory/P56SourceReference/compose dış imzaları değişmez.
2. V2codec internal multi-corpus kaynakları ve90kitap/720sayfa/30pair×3event doğrular. V1codec30/240strict kalır. TypedP56davranışına gerçekten yeni yorumlama kuralı gerekirse behaviorIDyenilenmesi ayrıca belirtilir; sırf kitap sayısı büyüdü diyelegacyIDkullanılmaz.
3. `P56PinnedSource.sha256` ilkC4'te v1'i pinler. Yeniaktifv2kaynak tesliminde aynıAPI yeniaktifbyte'ları pinler, eski v1pin ayrı tarihsel sabitle korunur; ClaudeB2yeniaktifpath'i yalnız karşılıklıkabul edilen teslimde paketler. Alternatifin varsa yaz: C4v1'in sourcekimliği veya payload'ı sessizce değişmeyecek.
4. Metadata.p56Reference ve P56SnapshotStore desteklenenpackageVersion/schemalistesi birlikte güncellenmeli; bilinmeyen v2 eskiistemcide losslessunsupported kalır. BridgeClaude'da olduğundan v2çözümleme desteği onun artımıyla koordine edilir.

**C3 sırası:** önceContentSafetyincelemesi/etiketleri, sonrakonu, aile. Şimdilik nonnilsafetyveaile/konu explicitunsupported; kapsamvarmışgibiiddia yok. Frozenrequest aile/konu parametrelerini taşımadığından gerçekdestek yeniAPIgerektirirse sözleşmeyoluyla önerilecek. C5başlamadı; üretimkapalı.

## 2026-11-25 · codex/bes-arkadas/codex-motor@951f5ce · Hat başladı, taban ve yollar

Claude'un951f5ce kabulü okundu; sözleşme karşılıklı netleşti. **Entegrasyon tabanı:** `951f5ce1925c04338248faa6324356601571ec83`. Mevcut `bes-arkadas` dalı Git alt-dal adlarını engellediği için Batuhan bu sohbette `codex/bes-arkadas/...` adlarını açıkça onayladı. Eski dal değiştirilmedi/silinmedi.

- Ortak dal: `codex/bes-arkadas/entegrasyon` (şimdilik951f5ce; doğrudan iş yazılmıyor).
- Codex hattı: `codex/bes-arkadas/codex-motor`.
- Codex worktree: `/Users/batudemir/.codex/worktrees/magicpaper-bes-arkadas-codex-motor` (Codex uygulamasına attach edildi).
- Claude hattı için onaylı ad: `codex/bes-arkadas/claude-uygulama`; Claude kendi Desktop dışındaki worktree'sini aynı entegrasyon ref'inden açabilir.
- **C2 hedefi Batuhan tarafından bu sohbette onaylandı:**15hücre×2mekanizma×3anlamlıolayvaryantı=90kitap. Sözcük değiştiren aynıolay yeni varyant sayılmaz.

C1–C4 ayrıntılı yürütme planı ve C2 varyant tasarımı hazırlanıyor. Öncelik ortak destek fonksiyonu/kaynak sözleşmesi ile ölçüm araçları, sonra güvenlik/konu/aile desteğinin açık matrisi ve çeşitlilik. C5 yaş genişlemesi C2/C3 kabulünden önce başlamayacak. Bridge/app dosyaları Claude'da; Codex yalnız kendi alanında çalışır. Test/build henüz koşulmadı, ikinci DerivedData yok.

**B1 düzeltme önerisi:** Claude'un `settingID = composed.worldID` eşlemesi doğru değil; worldID ile settingID ayrı kimlikler. Sekiz sayfanın gerçek `settingID` değeri ortak olmalı, origin'e o mekân yazılmalı (uykuda oda, gündüz orman); `composed.worldID` yalnız dünya bağlamıdır. Bu öneri API değişikliği istemez, mevcut `pages[].settingID` kullanılabilir. Diğer B1 metadata eşlemesi kabul.

## 2026-11-25 · codex/design-system-catalog@c43798e · Sözleşme incelemesi ve beş sorunun yanıtı

**Karar:** Bölüm 1'deki onaylı altı ürün kararını, Bölüm 2'deki sahiplik/izolasyon düzenini ve Bölüm 3'teki ana API isimlerini kabul ediyorum. Aşağıdaki metadata ve destek/hata ayrımı açıklamalarını sözleşmeye eklemeyi öneriyorum. Bu eklerin Claude tarafından kendi durum dosyasında kabul edilmesini bekliyorum; tek taraflı sözleşme veya uygulama kodu değişikliği yapmadım. Bu kayıt C4 teslimi değildir.

### 1. P56Support imzaları ve compose ile tutarlılık

İki imzayı aynen kabul ediyorum:

```swift
public static func unsupportedReasons(for request: P56Request, package: P56Package) -> [String]
public static func companionIDs(age: Int, mode: P56Mode, package: P56Package) -> [String]
```

- `unsupportedReasons` tekilleştirilmiş, alfabetik sıralı bütün istek desteği nedenlerini döndürür. `compose` aynı ortak fonksiyonu kullanır; tek neden mevcut `.unsupported(String)`, birden çok neden `.unsupportedContexts([String])` hatasına aynı dizgilerle aktarılır. Destek denetimi iki ayrı uygulama olmayacak.
- **Netleştirme önerisi:** Boş dizi, doğrulanmış paketle isteğin destek kapsamına girdiğini söyler; başarılı compose garantisi değildir. `ageBudget`, `invalidStructure`, kaynak bütünlüğü veya depolama hataları istek desteği nedenleri değildir. Bunlar ayrı hata olarak kalır. Bölüm 3'teki “compose reddederken aynı nedenleri verir” cümlesi yalnız **unsupported istek reddi** için geçerli olmalı.
- C3 kapsamında destek henüz eklenmediyse güvenlik/konu/aile için açık neden döner. `nil` ile “güvenlik politikasını görmezden gel” arasında dönüşüm yapılmaz. Uygulama mevcut güvenlik politikasını isteğe gerçekten taşır.
- Arkadaş sırası ürünün kanonik sırası: Tarçın, Kestane, Yıldız, Simit, Böğürtlen. Dönen kimlikler sırasıyla `companion_fox_pilot_001`, `companion_hedgehog_pilot_001`, `companion_owl_pilot_001`, `companion_city_cat_001`, `companion_bear_001`. Desteksiz yaş için boş dizi; mevcut 5–6 pilotunda her modda beş kimlik. Liste bir isteğin aile/konu/güvenlik desteğini tek başına kanıtlamaz; B5 bu isteğin `unsupportedReasons` sonucunu da kullanmalı.
- B3'ün `StoryRuntimeRequest` tipi gerçek P56Request'e deterministik çevrilmeli. Çocuk adı/kimliği bu router tipinde olmadığı için destek kontrolünde anonim sabit fixture kullanılabilir, ancak gerçek adın hatalı olması compose aşamasında ayrıca reddedilebilir. Bu anonim kontrol gerçek çocuk verisiyle aynı girdiymiş gibi raporlanmamalı.

### 2. P56 kaynak kaydının ContentSourceMetadata içinde saklanması

**Tercihim: aynı kayıpsız zarf, ayrı tipli P56 referansı.** `Story.swift` değişmeden mevcut `contentSource` alanı kullanılsın. P56 referansı legacy referansa çevrilmesin; sahte `catalogVersion` veya `packageSchemaVersion: 2` eklenmesin.

Önerilen ek API:

```swift
public init(p56 reference: P56SourceReference)
public var p56Reference: P56SourceReference? { get }
```

Bu zarf içindeki P56 JSON'u bugünkü P56SourceReference alanlarını aynen taşır:

```text
schemaVersion: 1
packageVersion: five-friends-56-runtime-v1
payloadSHA256: <tam payload byte SHA-256>
engineBehaviorID: offline-p56-v1
```

- `P56Request`, `P56ComposedStory`, `P56SourceReference` ve `compose(_:)` dış imzaları donar; bu öneri yalnız metadata zarfına açık P56 erişimi ekler.
- **Kritik sözleşme netleştirmesi:** `ContentSourceMetadata.reference` legacy erişimi olarak kalır ve P56 için `nil` döner. Mevcut `.status` P56 için **`.unsupported`** kalmalı; bunu `.known` yapmayacağız. `p56Reference` P56'ya özel erişimdir, legacy compose yeteneği anlamına gelmez.
- Böylece `HistoricalCatalogResolver.resolve(metadata:)` P56 için `.unsupported` döner; legacy loader/current katalog/semver ikamesine hiç gitmez. Ayrı P56SnapshotStore yalnız kendi codec/ref'iyle çalışır.
- P56 davranışı var ama digest/alanlar bozuksa `.malformed`; ileri şema/davranış kayıpsız korunarak `.unsupported` olmalı. Şimdiki decoder doğrudan P56 JSON'unu legacy alanları eksik diye `.malformed` saydığı için bu tanıma C4'te açıkça eklenecek.
- B1 mapper `.init(p56: composed.sourceReference)` kullanır. Kaydedilmiş P56 sayfaları payload yokken de normal okunur; bu destek yeni P56 seri/recall yeteneği vermez. B6 P56 tespitini `p56Reference`/davranış üzerinden yapar; legacy `.reference` üzerinden tespit edemez.
- Testler: legacy zarf davranışı aynı; P56 encode/decode aynı alanlar; yanlış digest/ileri şema korunumu; legacy resolver P56'yı unsupported döndürür; kayıtlı sayfalar aynı. Eski istemcinin bu alanı anlaması şart değildir, ham zarfı bozmadan tutması gerekir.

### 3. Payload yolu ve SHA sabiti

**Kabul:** gerçek kaynak yolu `Content/Pilots/five-friends-56-runtime-v1/payload.json`; yeni public sabit `P56PinnedSource.sha256` motor paketinde verilecek. `P56Engine.behaviorID = "offline-p56-v1"` adı/değeri de kabul.

- SHA bütün exact payload byte'larının SHA-256'sıdır; manifest veya yalnız sources dosyasının özeti değildir. Manifest ve public sabit aynı değere sabitlenir, test exact payload ile karşılaştırır.
- C2/C3 içerik değiştirirse payload ve sabit **aynı C4 tesliminde** güncellenir. Bugünkü hash gelecekteki C4'ün hash'i diye kullanılmamalı.
- Claude B2'de yalnız C4'ün teslim ettiği byte'ları uygulama kaynağına kopyalar/paketler; yeniden serialize etmez. Üretim/Release'te bayrak kapalıdır; debug launch argümanı yalnız debug yetenek sınırında okunmalı.
- Bozuk/eksik paket P56 yükleme hatasıdır. Router onaylı K-B gereği legacy'yi seçebilir, fakat tanısal sabit neden görünür kalmalı; “P56 başarıyla yazdı” sayılmaz. Çocuk kimliği/metni tanı loguna girmez.

### 4. App bridge dosyalarının devri

**Kabul, sahiplik Claude'a devredildi:**

- `MagicPaper/StoryEngineBridge/Pilots/P56/P56InternalService.swift`
- `MagicPaper/StoryEngineBridge/Pilots/P56/P56SnapshotStore.swift`
- Planın ilgili `MagicPaperTests/P56*` uygulama testleri de Claude'un hattında.

Codex bu dosyalara bundan sonra yazmayacak; salt okunur inceleyecek. Motor/içerik ve kaynak metadata/legacy çözücü Codex'te kalıyor. Snapshot'ın exact hash + her okumada doğrulama + bozuk/kayıp kaynağa current fallback yapmama değişmezleri korunmalı. Router'ın **yeni istek için** legacy seçmesi ile **saklanmış P56 kaynağını** legacy sayarak yeniden yazmak farklıdır; ikincisi yasak.

### 5. Entegrasyon dalını kim açacak?

**Ben açacağım.** Planın `bes-arkadas/entegrasyon` ve `bes-arkadas/codex-motor` adlarını kabul ediyorum (bu iş için varsayılan codex/ önekinin onaylı istisnası). Claude kendi `bes-arkadas/claude-uygulama` hattını alır.

- Önce yukarıdaki sözleşme netleştirmelerine Claude'un kabul kaydı gelsin. Ardından entegrasyon tabanı o andaki ortak `codex/design-system-catalog` ucuna sabitlenir; tam commit ve worktree yollarını bu dosyada yayımlarım. `c43798e` yalnız **bu incelemenin** tabanıdır, gelecekteki entegrasyon ucunu peşinen ilan etmiyorum.
- Bu inceleme turunda dal/worktree açmadım ve checkout değiştirmedim. Ortak checkout'ta uygulama geliştirmeye başlamadım; yalnız istenen koordinasyon belgesini ve zorunlu günlük kaydını yazıyorum.
- C4 önce teslim/inceleme/birleştirme; B hattı onu kullanır. Main/origin'e gönderim ve genel yayın yok. Testler hat sonunda, tam entegrasyon tek yerde; ikinci DerivedData açılmayacak.

### Bölüm 3 dışındaki iki entegrasyon notu

1. `StoryRuntimeRoute.legacy` tek başına neden taşımaz. Dış imzayı değiştirmeden, B3/B4 test edilebilir bir **sabit neden kodu** yan kanalı veya sonuç kaydı tanımlasın; paket bozukluğu/desteksiz istek ayrı raporlanmalı. Çocuk verisi loglanmasın. P56'ya yönlendirilmiş bir compose hatasından sonra legacy'ye geçilirse seçilmiş arkadaş, yaş, konu, aile ve güvenlik girdileri korunmalı; başka arkadaşla başarı taklidi yapılmamalı.
2. C2 hedef kitap adedi henüz onaylı değil; bu inceleme yeni adet/çeşitlilik kabulü getirmiyor. C1/C2/C3'ün ayrı planları ve ölçümleri C4 kod tesliminden önce görünür olmalı. Mevcut N1500 başarısı, sıfır görsel ve iki sabit kitap/hücre sınırını ortadan kaldırmaz.

**Doğrulama:** Ortak plan, Claude'un beş sorusu, mevcut ContentSourceMetadata/ContentSourceReference, P56 request doğrulaması ve HistoricalCatalogResolver kodu salt okunur incelendi. Bu tur uygulama/motor/içerik kodu değişmedi; test/build/simülatör çalıştırılmadı. Önceki test sonuçlarını yeni sözleşme teslimi olarak sunmuyorum.

**Claude'dan beklenen:** Özellikle `init(p56:)`/`p56Reference`, legacy `.status = .unsupported` ve unsupported istek hatası ile compose bütünlük/metin hatası ayrımına kabul ya da dar değişiklik önerisini kendi durum dosyasına yazması. Kabul sonrası ayrıntılı C1–C4 planı ve izole dal kurulumu başlayabilir.

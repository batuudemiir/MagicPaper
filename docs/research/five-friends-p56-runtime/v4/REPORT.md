# V4 ikinci düzeltme — doğrulanmış aday

26 Kasım 2026. `metin-duzeltme-2.md` doğrultusunda 17 kitabın 18 sayfası yenilendi; kimlikler ve başlıklar korundu. Yeni V4 SHA256: `c06a5dfc3f586eae5d837926cab915be6b22480c20e11e02c9ea7fd5894990d6`. Pin **v3**; v1/v2/v3 payload baytları değişmedi.

| Kapı | Sonuç |
|---|---|
| 90 kitap × 7 ad | 630/630 başarı |
| N1500 | 1500/1500 başarı, 0 hata, 0 retry, 90 farklı kitap |
| Release | 15 test, 0 hata |
| Python–Swift metrik | 720 sayfa, 0 fark |
| Kanonik havuz lint | 45 dosya / 270 kitap geçti; ortak sayfa 0 |
| İki dalganın bilinen içerik engelleri | 0 |

Release kontrolü aynı Swift kodunun mevcut Release binary'siyle `--skip-build` kullanılarak tekrar çalıştırıldı; 284f0857 sonrasında Swift değişikliği yok. Sayfa bütçesi, trace ve safety/loader bağlarında hata yok. Önceki başarısız adayın sonuçları 284f0857 geçmişinde korunuyor.

İki V4 uyku kapanışı düzeltildi. Dalgalarda ayı/çanta sızıntısı, kayıp zilin bulunmadan çalması ve üç L9 event03 kitabının kozalak deneyi düzeltildi; diğer uyku kapanışları sakin sonla tamamlandı. Kaynak farkları `revision-2-change-ledger.json` içinde.

İnceleme yöntemi: değişen 17 kitabın sekizer sayfası yeniden okundu; 253 değişmeyen kitabın önceki incelemeleri byte/hash eşitliğiyle korundu. Yeni kaynak alıntıları, semantik/causal/C3 ve art bağları yeniden üretildi. Bağımsız karşı inceleme 270 kitabın kaynak bağlarını ve kritik bağlamları doğruladı; kritik/yüksek bulgu yok. İki L8 Simit nesne etiketi (topuk→top, yuvarlak→yuva yanlış eşlemesi) de düzeltildi. Bu kayıt tüm 270 kitabın bu tur yeniden baştan okunduğu iddiası değildir. Önceki küçük editoryal/görsel kısıtlar ilgili incelemelerde korunur.

V4 art handoff 90 başarılı compose kitap/720 sayfa içerir. İki dalganın 180 kitap/1440 sayfalık handoff'u kaynak metne dayanır; runtime fixture değildir. Kaynak kimliği, tam sayfa ve komşu bağlamı, somut eylem/poz ve güvenlik kısıtları yeni hash'lere bağlıdır. Eski etiketler yeni metin için geçerli sayılmaz.

Kaynak klasörde `dalga2/kitaplar/learning-owl 2.json` adlı tek Finder kopyası hâlâ var; 9 eski kopya arşivde. Kanonik sözleşme dışındaki dosya silinmedi. Ham glob 276 kitapta hücre tekrar kapısını geçmiyor; bu sonuç kanonik 270 kitap kontrolünden ayrı kaydedildi. Yardımcı örnek dosyalar ayrı denetlendi; güncel kitap metni yerine onay kaynağı sayılmadı.

`productionEnabled=false`, `artApproved=false`. V4'e pin geçişi ayrı Batuhan onayını bekler. Dalga runtime/typed sözleşmeleri uygulanmadı; uygulama hattının v3 paket/SnapshotStore/simülatör önkoşulu bekleniyor. Main/entegrasyon/push yapılmadı.

Kanıt: `verification-summary.json`, `diagnostic.json`, `sampling.json`, `release-tests.log`, `lint-parity.json`, `v4-lint.txt`, `current-waves/`.

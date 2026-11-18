# MagicPaper Üyelik Akışı Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax. Repo kuralı önceliklidir: ara test/simülatör yok, doğrulama plan sonunda.

**Goal:** Üç ücretsiz kişisel masaldan üyeliğe çocuk ekranında fiyat göstermeden ve ebeveyn kapısından geçerek ulaşmak.

**Architecture:** Mevcut EntitlementService/RevenueCat korunur. Deneme defteri ve erişim uygulama katmanında, kalıcı kayıt/tüketim createStory içinde; sunumlar merkezi yönlendirme üzerinden sıralanır. Motor ödeme bilmez.

**Tech Stack:** Swift/SwiftUI, Foundation atomik dosyalar, RevenueCat/StoreKit, XCTest/XCUITest.

**Tasarım:** `docs/superpowers/specs/2026-11-17-membership-entry-design.md`. Bu teslim plan, uygulama değil. Fiyat/canlı ürün henüz seçilmedi.

## Çalışma ve dosya sınırları

Repo: `/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper`. Aşağıdaki yollar bu köke göredir. Uygulama başlangıcında izole `codex/membership-entry` dalı/worktree kullan; tarihsel MagicPaper-* kopyalarını değiştirme. Ortak MPAppState, ContentView, StoryGenerationManager ve günlük için sahipliği kontrol et; başka oturumun tasarım/renk değişikliklerine dokunma. Services/Entitlements otomatik eşitlenmiyor: yeni dosyaların pbxproj üyeliği gerekir. Screens ve testler eşitlenir. Tahmin M–L: birkaç gün uygulama + son doğrulama; canlı ürün/göç kapsamı süreyi değiştirir.

## Task 1 — Ürün kimlikleri ve eski abone uyumluluğu

**Dosyalar:** `MagicPaper/Products.storekit`, `MagicPaper/Services/RevenueCatManager.swift`, `MagicPaper/Services/SubscriptionManager.swift`.

- [ ] Yerel StoreKit ve RevenueCatManager.productIdentifier kimliklerini eşleştir. Mevcut ayrışma: com.magicpaper.basic.monthly / magicpaper_basic_monthly.
- [ ] Canlı panel erişimi varsa sadece ürün ID/dönem/entitlement/offering/package ve eski aktif ürünlerin varlığını oku. Müşteri kimliği/anahtar kaydetme. Erişim yoksa yerel hazırlığa devam et; canlı satın almayı doğrulanmış sayma.
- [ ] Tek üyelik yeni satış kapsamıdır; eski basic/premium/ultimate aktif haklarını silme. Tanınmayan yıllık ürünün basic'e düşmesini engelleyen açık eşleme hazırla.
- [ ] Gerçek yeni aylık/yıllık ürün bulunmuyorsa ürün-yok durumunu koru; fiyat/ürün yayımlama.

**Kabul:** Her sunulan ürün gerçek ID/dönemle eşleşir; eski abone hakkı korunur.

## Task 2 — Deneme defteri ve saf erişim

**Create:** `MagicPaper/Services/Entitlements/StoryAllowanceStore.swift`, `MagicPaper/Services/Entitlements/PersonalStoryAccess.swift`, `MagicPaperTests/StoryAllowanceTests.swift`.
**Modify:** `MagicPaper/Services/Entitlements/{Capability,EntitlementService,LiveEntitlementService,StubEntitlementService,EntitlementPolicy}.swift`, `MagicPaper.xcodeproj/project.pbxproj`.

- [ ] Testleri önce yaz, son tura kadar çalıştırma: fresh=3; paid tüketmez; tek pending; UUID başına tek commit; release idempotent; bozuk kayıt fresh olmaz; profil/çıkış/silme geri vermez.
- [ ] Sürümlü atomik defter: schemaVersion=1, committedStoryIDs, en fazla bir pending(token UUID, optional storyID). Üç sınırı kararın kaynağıdır; dosyada çocuk/hesap adı yok. Eksik dosya ve okuma hatası ayrılır.
- [ ] Yeni karar sözleşmesi:

```swift
enum PersonalStoryAccess: Equatable {
    case member
    case trial(remaining: Int)
    case requiresMembership
    case needsRestore
    case storageUnavailable
}
```

- [ ] Yeni kişisel masal capability'si eski 12 saat/görsel kota yolunu kullanmaz. Etkili üyelik güven politikasından gelir; kayıtlı ücretli ama güveni bitmiş durum needsRestore olur.
- [ ] Snapshot'a ayrı personalStoriesRemaining ekle; storyCredits/yıldız arayüzünü yeni hak için kullanma. Eski kurulum ilk defterde üç hak alır; geçmiş kitapları/old freeTrialCount'ı düşme.
- [ ] Stub ve gerçek servis aynı kararı üretir; yeni dosyalar target'a eklenir.

**Kabul:** Mevcut motor, görsel kota ve okuma yıldızı değiştirilmeden karar hesaplanır.

## Task 3 — Kalıcı kayıt sonrası tek hak tüketimi

**Modify:** `MagicPaper/Services/StoryGenerationManager.swift`, `MagicPaper/Services/Persistence/LibraryShelf.swift`, `MagicPaperTests/StoryPersistenceTests.swift`, `MagicPaperTests/LibraryCutoverTests.swift`.
**Create:** `MagicPaperTests/PersonalStoryCreationAccessTests.swift`.

- [ ] Testleri yaz: ilk masal dahil üç başarı; dördüncü doğrudan servis çağrısı ret; compose/write hatası sıfır tüketim; iki eşzamanlı istek bir rezervasyon; crash sonrası pending uzlaşma.
- [ ] LibraryShelf'e yalnız yeni kayıt için başarı/hatayı bildiren dar API ekle. readOnly reddeder; legacy/disk yazısı gerçekten doğrulanır. Diğer save çağrılarını topluca dönüştürme.
- [ ] createStory başında aile yazma rolü ve erişimi tekrar kontrol et. in-flight rezervasyon ikinci isteği reddeder. Trial rezervasyonu üretimden önce diske gider; paid hak harcamaz.
- [ ] Üretilen UUID pending'e bağlanır → kişisel masal kalıcı yazılır → hak commit edilir → in-memory liste/firstStory olayı güncellenir. Kayıt başarısızsa hazırlanmış masal okuyucuya verilmez.
- [ ] Yeniden açılışta pending UUID diskte varsa tek commit, yoksa release. İki dosyayı atomik işlem sanma. Defter commit'i yazılamazsa pending korunur; yeni hak verilmez.
- [ ] Committed masalı silmek denemeyi geri vermez. Defter çıkışta ticari cihaz kaydı olarak kalır; LocalDataEraser'ın çocuk verileriyle karıştırılmaz. Hesap silme/veri açıklaması ayrıca doğrulanır.

**Kabul:** Kalıcı masal yoksa tüketim yok; çökme veya callback tekrarı çifte tüketmez.

## Task 4 — Çocuk durumu ve tek modal zinciri

**Create:** `MagicPaper/Screens/Membership/StoryAccessView.swift`, `MagicPaper/Screens/Membership/MembershipIntent.swift`, `MagicPaperTests/MembershipRoutingTests.swift`.
**Modify:** `MagicPaper/Screens/MPAppState.swift`, `MagicPaper/Screens/MPRouter.swift`, `MagicPaper/ContentView.swift`, `MagicPaper/Screens/StoryCreation/StoryCreationFlow.swift`.

- [ ] Pending niyet modu, aile UUID'si ve dönüş kaynağını saklar. Tek kullanımlıktır; masalı kendi başına yazmaz.
- [ ] startStoryCreation aile rolünden sonra erişimi sorar: member/trial mevcut seçim; requiresMembership çocuk durumu; needsRestore/storageUnavailable ayrı ebeveyn durumu.
- [ ] Onaylı çocuk metni ve iki eylem MPStateView/MPButton/token'larla; tek Ragi, Türkçe accessibilityLabel. Satış fiyatı/paket yok.
- [ ] Çocuk durumu kapanınca onDismiss → router.requestGate(then:) → kapı kapanınca paywall. Quiz iptali pending'i siler.
- [ ] Paywall kapanışında sadece verified erişim pending'i tüketip startStoryCreation'ı tekrar çalıştırır. Cancel/failure akışı kitaplığa döner. Ebeveyn ayarından gelen teklif kendi yerinde kalır.
- [ ] StoryCreationFlow.begin servis erişim reddini genel üretim hatası yapmaz; flow kapandıktan sonra erişim durumuna yönlendirir.

**Kabul:** Ana sayfa/mod/aile/ilk masal yan yolları tutarlı; üst üste cover yok; iptalde askıda callback yok.

## Task 5 — İlk kurulum teklifi ve ebeveyn üyelik bloğu

**Create:** `MagicPaper/Screens/Membership/MembershipIntroView.swift`.
**Modify:** `MagicPaper/ContentView.swift`, `MagicPaper/Screens/Onboarding/FirstRunView.swift`, `MagicPaper/Screens/Parent/ParentOverviewView.swift`, `MagicPaper/Views/SettingsView.swift`, `MagicPaperTests/FirstRunFlowTests.swift`.

- [ ] Yeni profilin MPWelcome.pendingKey niyetini ilk masal başlamadan intro ile karşıla. Dönen hesaptan gelen restore profili yeni kurulum sayılmaz.
- [ ] Ücretsiz başla → intro kapanır → FirstRunView; üyelik seçenekleri → intro kapanır → quiz → paywall. Paywall iptali açıklamaya döner, otomatik masal yok.
- [ ] Intro sürümlü once anahtarı ve pending ilk masal niyeti yeniden açılışta korunur. AppGate ve storyBeforeAccount değişmez. Aktif eski kuruluma intro zorla gösterilmez.
- [ ] ParentOverview'da tek üyelik durumu + free kalan hak + planlar/restore/yönet. Settings aynı snapshot'a bağlanır; kota/yıldız adı tekrarlanmaz. Aktif üye trial sayacı görmez.

**Kabul:** İlk masal bir hak sayılır; profil oluşunca çift üretim başlamaz; ebeveyn ekranında Ragi yok.

## Task 6 — Paywall ve satın alma sonuçları

**Modify:** `MagicPaper/Screens/PaywallView.swift`, `MagicPaper/Services/RevenueCatManager.swift`, `MagicPaper/Services/SubscriptionManager.swift`, `MagicPaper/Services/Entitlements/EntitlementPlan+SubscriptionTier.swift`, `MagicPaper/Products.storekit`.
**Create:** `MagicPaperTests/MembershipProductMappingTests.swift`, `MagicPaperTests/MembershipPurchaseOutcomeTests.swift`.

- [ ] Tek üyelik/iki dönem göster. Canlı ürünleri Task 1 eşlemesinden al; legacy aktif ürün eşlemelerini koru. Yerel fixture canlı satış kanıtı değildir.
- [ ] Fayda listesi yeni kişisel masal ve gerçekten açık kişisel dünya davranışlarıdır. Görselli kota, 12 dünya garantisi, uzunluk, kapalı aile sesi ve ücretli olmayan PDF/katalog ayrıcalığı çıkarılır.
- [ ] Fiyat/dönem StoreKit'ten; yükleniyor/ürün yok/hata ayrılır; hardcoded fiyat fallback kaldırılır. Yıllık toplam tahsilat açık gösterilir.
- [ ] Aylık/yıllık aynı entitlement'ı açar, dönem ayrı tutulur. CustomerInfo yenilemesi hak/bakiyeyi resetlemez; aktif bilinmeyen ürün sessiz basic fallback yapmaz.
- [ ] Sonuçlar verifiedMember/cancelled/pending/failed/restoredWithoutAccess olarak ayrılır. Restore teknik başarısı etkin entitlement olmadan üyelik sayılmaz.
- [ ] Başarı yalnız paywall kapanışına bildirilir; ekran kendi başına başka cover açmaz. Yönetim mağaza abonelik yönetimini açar.

**Kabul:** Gerçek ürün/gerçek fiyat; eski hak korunur; pending/failed masal açmaz.

## Task 7 — Seri ve kalıcı kitaplar

**Modify:** `MagicPaper/StoryEngineBridge/SeriesManager.swift`, `MagicPaper/Screens/Series/SeriesEndingSection.swift`, `MagicPaperTests/SeriesTests.swift`.

- [ ] startSeries yalnız etkili üyelikle yeni seri başlatır; ücretsiz kişisel masal hakkı tüketmez. Mevcut serinin tick/read/markRead yoluna abonelik kilidi eklenmez.
- [ ] Mevcut seri metinleri başlangıçta kaydedildiği için başarılı seri kaydı kalıcı tamamlama hakkının kaynağıdır; ikinci ayrı hak deposu kurma.
- [ ] Okuyucu Devam ettir eylemi ücretli erişim isterse reader kapanışı sonrası çocuk durumunu aç. Satın alma sonrası seri niyeti seçim/onay yüzeyine döner; otomatik seri oluşturulmaz.
- [ ] Testler: expired açık seri devam eder; yeni seri reddedilir; kayıt başarısızlığı başarı sayılmaz; eski kitap okunur.

**Kabul:** Yeni içerikte sınır var, edinilmiş kitap/başlamış seride kayıp yok.

## Task 8 — Son doğrulama ve teslim

**Modify:** `MagicPaperUITests/NavigationFlowTests.swift`, `docs/MagicPaper_Monetization.md`, `docs/YAYIN.md`, `docs/PROJE_HAFIZASI.md`, `AGENTS.md`, `CLAUDE.md`, `design-handoff/reference/DEMO_CHANGELOG.md`.

- [ ] Ürün kararlarını AGENTS ve CLAUDE'da birlikte güncelle; eski 12 saat/görsel kontör açıklamalarını tarihsel yap. Fiyat/canlı ürün değişmediyse açık belirt.
- [ ] Uygulama testlerini yeni vakalarla tek son turda çalıştır; bilinen takılan snapshot'ı atla. Son turda cihazın varlığını doğrula. Örnek hedef:

```bash
xcodebuild test -project MagicPaper.xcodeproj -scheme MagicPaper -destination 'platform=iOS Simulator,name=iPhone Air,OS=latest' -skip-testing:MagicPaperTests/DesignSystemSnapshotTests/testSnapshotButtons -resultBundlePath /tmp/MagicPaper-membership-tests.xcresult
```

Beklenti: ilgili yeni/mevcut testlerde sıfır hata. Hedef yoksa mevcut uygun cihazı seç. Motor/Firestore kuralları değişmiyorsa paket/emülatör koşularını tekrarlama. Hata çıkarsa düzelt ve yalnız gerekli yeniden doğrulamayı yap.

- [ ] UI: intro/free/ilk masal; dördüncü giriş; kitaplık; quiz/paywall iptali; verified purchase tek dönüş; restore no-access; yeni profil; expired/offline; eski abone.
- [ ] Son matris: küçük/büyük iPhone, açık/koyu, AX5, Reduce Motion ve ebeveyn alanı VoiceOver. Desteklenen iOS sınırı kontrol edilir. Canlı StoreKit sandbox senaryoları yerel fixture'dan ayrı kanıtlanır.
- [ ] Her tamamlanan dilimin günlüğünü yaz, yalnız kendi hunk'larını commit'le. Canlı panel eksikse ödeme entegrasyonu tamamlandı deme.
- [ ] Ürün/fiyat yayımlama, deploy ve bayrak açma yapma; testli kod + eşleme + eksik dış adımları incelemeye hazır teslim et.

**Kabul:** Tasarımın her kabul maddesi test/gözlem kaydına bağlı; bilinmeyen canlı durumlar ayrı; yayın kararı kurucuda.

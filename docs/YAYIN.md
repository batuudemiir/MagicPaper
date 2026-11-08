# Yayın ve ölçüm (Faz 6)

Yol haritası: `docs/STARTUP_PLANI.md`. Marka: `docs/MARKA.md`. Bu belge yayına kadar kalan işi ve kimde olduğunu söyler.

## Durum (8 Kasım 2026)

| İş | Durum | Kimde |
|---|---|---|
| Onaylı anonim huni | Kod ve Firestore kuralı hazır; gönderim kapalı (`funnelUpload` bayrağı) | Batuhan: politika ve onay metni, kural deploy, bayrak |
| Uzaktan bayrak | Hazır: imzalı içerik akışındaki `flags` | Batuhan: akışı imzalayıp yayınlamak |
| Web ve yasal sayfalar | Repodaki dört sayfa markada | Batuhan: magicpaperkids.com'daki asıl sayfalar |
| App Store görselleri | Testlerle birlikte, tüm fazlar bitince | Biz |
| TestFlight 5-10 aile | Bekliyor | Batuhan: App Store Connect, aileler |
| Kids Category | Öneri aşağıda | Batuhan karar verir |
| String Catalog | Bilerek ertelendi | |
| iPad | Bilerek ertelendi | |

## Huni

Kod `StoryEngineBridge/MPFunnel.swift`, kural `firebase/firestore.rules` (`validFunnel`), testler `FunnelAndFlagsTests` ve `firebase/tests/rules.test.mjs`.

Kurulum başına birer kez: `firstOpen`, `firstStory`, `firstFinish`, `account`, `parentRoom`, `firstWeek`. Giden yalnızca adım, kurulumdan beri gün ve kaba değer. İlk masal ve ilk bitişte değer saniye kovası, ilk haftada okunan gün sayısı. Ad, yaş, kimlik, cihaz, tarih ve masal gitmez.

Planın başarı ölçütleriyle eşleşme:

| Ölçüt | Adım |
|---|---|
| İlk masala süre | `firstStory.value` |
| İlk masalı bitirme | `firstFinish` / `firstOpen` |
| Hesap dönüşümü | `account` / `firstOpen` |
| 7 günde okunan gün | `firstWeek.value` |
| "Büyükler için"i bulma | `parentRoom` / `firstOpen` |

İlk masala dokunuş sayısı ölçülmüyor: UI testi zaten 3 dokunuşu sabitliyor.

**Neden kapalı:** gizlilik politikası ve uygulama içi onay metni bugün anonim veri olarak yalnızca okuma bilgisini sayıyor. Huni yeni bir tür. Açmadan önce:

1. Gizlilik politikasına "Anonim kullanım adımları" maddesi eklenir: liste yukarıda.
2. Onay metni güncellenir; gerekiyorsa sürümü artar (`ConsentRecord.version`).
3. `firebase deploy --only firestore:rules`.
4. İçerik akışına `"flags": {"funnelUpload": true}` eklenip imzalanır.

O zamana kadar olaylar cihazda bekler. Ebeveyn paylaşımı kapatırsa bekleyenler silinir.

**Fark edilen tutarsızlık:** gizlilik politikası "Toplanmayanlar: ses kaydı" diyor, ama FAZ 18'den beri ebeveyn masalı kendi sesiyle kaydedebiliyor ve kayıt aileyle senkronlanıyor. Politika bu bakımdan güncel değil; hukuk görüşüyle birlikte düzeltilmeli.

## Uzaktan bayrak

`ContentFeed.flags` (isteğe bağlı) → `MPRemoteFlags`. Yalnızca `MPRemoteFlags.Flag` içindeki adlar okunur, imzasız akış hiç okunmaz. Bayrak yoksa koddaki varsayılan geçerli.

| Bayrak | Varsayılan | Ne açar |
|---|---|---|
| `sleepMode` | kapalı | Uyku modu v2 (`docs/UYKU_MODU_V2_PLANI.md`'deki açıklar kapanmadan açılmaz) |
| `funnelUpload` | kapalı | Huni gönderimi (yukarıdaki dört adım) |

## Kids Category önerisi

**Öneri: ilk sürüm Kids Category dışında, "Kitaplar" ya da "Eğitim" kategorisinde, 4+ yaş derecesiyle.**

Gerekçe ([App Store yönergeleri 1.3 ve 5.1.4](https://developer.apple.com/app-store/review/guidelines/)):

- Kids Category'de üçüncü taraf analitik ve reklam yok. Bizde ikisi de yok; ama Firebase SDK'ları ve Google ile giriş inceleme sırasında ayrıca sorgulanabilir.
- Uygulama dışına bağlantı ve satın alma ebeveyn kapısı ister. Bizde kapı var (`EbeveynKapisi`), ama her yolun cihazda denetlenmesi gerekir.
- Kids Category'ye girilince çıkmak zor, her güncelleme bu kurallarla incelenir. Önce dışarıda yayınlayıp TestFlight ve ilk sürümle doğrulamak daha az risk.

Kategori dışında da aynı kurallara uyuyoruz: üçüncü taraf analitik yok, satın alma ve dış bağlantı kapının arkasında.

## TestFlight (5-10 aile)

1. App Store Connect'te iç test grubu; ailelerin Apple kimlikleri Batuhan'da.
2. Derleme: `ci_scripts` ve Xcode Cloud, ya da `ExportOptions.plist` ile arşiv.
3. Ailelerden istenen: bir hafta, akşam okuması. Ebeveyne üç soru: ilk masala nasıl vardınız, masal sonu çocukta ne yaptı, "Büyükler için"i buldunuz mu?
4. Huni açıksa sayılar; değilse gözlem notları.

## Bilerek ertelenenler

- **String Catalog:** uygulama yalnızca Türkçe. Taşıma bütün ekranlara dokunur, bugün kullanıcıya bir şey kazandırmaz. İkinci dil kararıyla yapılır.
- **iPad (`sidebarAdaptable`):** cihaz ailesi iPad'i içeriyor, uygulama orada telefon düzeniyle açılıyor. Kenar çubuğu "Masal yaz" dairesinin rolünü değiştirir; iPad simülatöründe ayrı tasarım turu ister.

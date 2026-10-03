# MagicPaper — Monetizasyon Mimarisi

> **Faz 9 durumu (3 Ekim 2026):** Bulut metin yolu kaldırıldı — `AIService`, `GeminiStoryAIProvider`,
> `createCustomStory` / `createCategoryBasedStory`, `TextStoryManager`, `TextStory`, `TextOnlyStory`, eski 4 adımlı
> sihirbaz (`StoryWizardView`, `StoryGeneratingView`, `MPAppState.startWizard`), `FirebaseTestView`, `LocalImageView`,
> `ImagePicker`, `Retired/`. Metin masal yalnızca `OfflineStoryService`. Görsel bulut kodu (`FalImageProvider`,
> `FalAIImageGenerator`, `FirebaseImageUploader`, `VisualSystem`) silinmedi: `StoryEngineBridge/CloudIllustrationPipeline.swift`
> içinde, `CloudIllustrationAccess` bayrağının arkasında (Release'te hep kapalı) ve çocuk akışından erişilemez.
> Bu belgede bu dosyalara verilen satır referansları tarihseldir. Ayrıntı: `MagicPaper_Faz_Plani_Ekim.md` → FAZ 9.

**Grup 2, Dalga 2A** · Sahip: `monetization` · Durum: soyutlama kuruldu, çağrı yerleri **taşınmadı**

---

## 1. Hedef

```
Capability → EntitlementService → RevenueCat
```

`if isPremium` değil.

Gerekçe tek cümle: `isPremium` üç kademeli bir planı (`basic` / `premium` /
`ultimate`) tek bir `Bool`'a eziyor, ve o `Bool` on dokuz yerde birbirinden
bağımsız yorumlanıyor. Bugün dördü aynı üçlüyü kopyalıyor:

```swift
subscriptionManager.isPremium
    ? subscriptionManager.remainingImageStories
    : subscriptionManager.freeTrialCount
```

Bu bir yetki kararı değil, bir **bakiye hesabı** — ve dört ekranda dört kopya.

---

## 2. Katmanlar

| Katman | Dosya | Sorumluluk |
|---|---|---|
| `Capability` | `Services/Entitlements/Capability.swift` | Uygulamanın **yapmak istediği şey** |
| `EntitlementPolicy` | `Services/Entitlements/EntitlementPolicy.swift` | **Tek** karar noktası. Saf fonksiyon |
| `EntitlementService` | `Services/Entitlements/EntitlementService.swift` | Protokol + `EntitlementSnapshot` |
| `LiveEntitlementService` | `Services/Entitlements/LiveEntitlementService.swift` | Üretim adaptörü |
| `StubEntitlementService` | `Services/Entitlements/StubEntitlementService.swift` | Test / önizleme ikizi |
| eşleme | `Services/Entitlements/EntitlementPlan+SubscriptionTier.swift` | Kademe köprüsü |

`SubscriptionManager` **durumun sahibi olarak kaldı**. CLAUDE.md İlke 2: çalışan
sistem yeniden yazılmaz. Değişen tek şey, ekranların ona doğrudan `isPremium`
sormayı bırakması.

---

## 3. Yetenek listesi — koddan türetildi

Hiçbiri uydurulmadı; her birinin bugünkü karşılığı dosya:satır olarak yazılı.

| Capability | Bugünkü kontrol | Ölçülü mü |
|---|---|---|
| `.illustratedStory` | `SubscriptionManager.canCreateStory(type: .image)` | ✅ kotalı |
| `.unlimitedTextStories` | `canCreateStory(type: .text)` + 12 saatlik soğuma | — |
| `.unlimitedDailyStories` | `canCreateStory(type: .daily)` | — |
| `.premiumWorlds` | `MP.World.isPremium` (`MPTheme.swift:326`) | — |
| `.premiumThemes` | `StoryTheme.isPremium` (`Models/Story.swift:238`) | — |
| `.longStories` | `MPStoryLength.isPremium` (`MPBridge.swift:84`) | — |

`.premiumThemes` ve `.longStories` bugün **sıfır tüketicili**: model bayrağı
yazılı ama hiçbir ekran okumuyor. Yetenek listesine yine de girdiler, çünkü
bayrak ürün kararı olarak kodda duruyor; kapıyı kuran ekran 2B'de onları
bulacak.

---

## 4. Karar `Bool` değil

```swift
enum EntitlementDecision {
    case allowed
    case allowedUsingTrial(remaining: Int)
    case allowedUsingQuota(remaining: Int)
    case denied(EntitlementDenial)
}

enum EntitlementDenial {
    case requiresSubscription        // → paywall
    case quotaExhausted              // → "ay başında yenilenir"
    case waitingForFreeStory(hours:) // → paywall DEĞİL, sakin bekleme metni
    case unverifiedEntitlement       // → "Satın alımları geri yükle"
}
```

`Bool` "neden hayır" bilgisini düşürür ve arayüz onu yeniden uydurur. Dört ret
sebebinin dördü de farklı ekran davranışı gerektiriyor — özellikle
`.waitingForFreeStory`: ücretsiz kullanıcı 12 saatte bir masalı **zaten**
alıyor, ve her redde abonelik ekranı açmak bu ürünün sesi değil (CLAUDE.md
İlke 7, sakin UX).

---

## 5. Güvenlik — istemci durumuna körü körüne güvenmeme

### Tespit edilen açık

`SubscriptionManager` kademeyi `UserDefaults["subscriptionTier"]`'e yazıyor ve
sonraki her açılışta oradan okuyup yetki veriyor. O anahtar cihaz sahibinin
yazabildiği bir yer; tek başına **yetki kanıtı değil**. Ağ hiç gelmese bile
eski davranış süresiz premium veriyordu.

### Uygulanan strateji

Politika artık plana **ve planın kaynağına** birlikte bakıyor:

```swift
enum EntitlementTrust {
    case verified            // bu oturumda CustomerInfo'dan doğrulandı
    case cached(age:)        // daha önce doğrulanmıştı, şu an ağ yok
    case unverified          // hiç doğrulanmadı — elimizde sadece yerel yazı
}
```

Üç kural:

1. **Damgayı yalnızca RevenueCat atar.** `SubscriptionManager.recordEntitlementVerification()`
   tek çağrıldığı yer `RevenueCatManager.updateSubscriptionManager(with:)`, yani
   gerçek bir `CustomerInfo` elde edildiğinde. Uygulamanın kendi kendine
   "doğrulandı" diyebildiği başka kapı yok.
2. **Çevrimdışı tolerans sınırlı: 7 gün.** Doğrulanmış abonelik ağ olmadan da
   onurlandırılır, ama süresiz değil. Süresiz olsaydı tek bir `UserDefaults`
   yazısı kalıcı bedava premium demekti. Pencere dolunca yetki kendiliğinden
   `.free`'ye düşer.
3. **Para harcayan yetenek önbellekten açılmaz.** `.illustratedStory` — tek
   uzak maliyet taşıyan yetenek — `.cached` ile değil yalnızca `.verified` ile
   açılır. Savunulabilir, çünkü görsel üretimi zaten ağ istiyor: ağ varsa
   `CustomerInfo` da tazelenebilir.

`isEntitlementVerifiedInThisSession` kalıcı **değil** — her açılış yeniden kanıt
ister. `cancelSubscription()` damgayı da siler; bayat bir damga sonraki bir
kademe yazısına güven devretmemeli.

### Hâlâ açık olan — sunucu tarafı doğrulama

Bu katman **istemci tarafı sıkılaştırmadır**. Jailbreak'li bir cihazda hiçbir
istemci kontrolü nihai değildir. Gerçek uygulama, görsel üretim çağrısının
(fal.ai) RevenueCat entitlement'ı **sunucuda** doğrulanmadan başlamamasıdır.
`Capability.incursRemoteCost` tam olarak o kapının nereye konacağını işaretliyor.
Bu, 2A'nın kapsamı dışında ve ayrı bir iş emri gerektiriyor.

---

## 6. Çağrı yeri taşıma planı — 2B iş emri

**2A bu satırların hiçbirine dokunmadı.** Aşağıdaki tablo parent-ux ve
story-engine için iş emridir.

### 6.1 `parent-ux` — bakiye gösterimi (yetki kararı DEĞİL)

Dördü de aynı kopyalanmış üçlü. Hepsi tek satıra iner:

```swift
private var stars: Int { entitlements.snapshot.storyCredits }
```

| Dosya:satır | Bugünkü kod |
|---|---|
| `Views/HomeView.swift:122-124` | `starCount` |
| `Views/SettingsView.swift:19-21` | `stars` |
| `Screens/ParentPanelView.swift:131-133` | `stars` |
| `Screens/StoryWizardView.swift:269-271` | `stars` (← story-engine ile paylaşımlı dosya) |

### 6.2 `parent-ux` — plan etiketi

| Dosya:satır | Bugünkü kod | Yerine |
|---|---|---|
| `Screens/ParentPanelView.swift:286` | `isPremium ? "Hikaye Kahramanı" : "Ücretsiz plan"` | `snapshot.planDisplayName` — üç kademeyi de doğru adlandırır; bugün `ultimate` abone "Hikaye Kahramanı" görüyor, **bu bir hata** |
| `Screens/ParentPanelView.swift:289` | `isPremium ? "Aylık yenilenir" : "\(stars) yıldız kaldı"` | `snapshot.plan.isPaid` |
| `Screens/ParentPanelView.swift:298` | `isPremium ? "Yönet" : "Yükselt"` | `snapshot.plan.isPaid`; ek olarak `snapshot.needsRestore` → "Geri yükle" |

### 6.3 `parent-ux` — gerçek kapı

| Dosya:satır | Bugünkü kod | Yerine |
|---|---|---|
| `Views/HomeView.swift:347` | `world.isPremium && !subscriptionManager.isPremium` | `world.isPremium && !entitlements.can(.premiumWorlds)` |
| `Views/HomeView.swift:350-351` | aynı koşul + `app.openPaywall()` | `entitlements.evaluate(.premiumWorlds)` → `.denied(.unverifiedEntitlement)` ise paywall değil **geri yükleme** |
| `Screens/PaywallView.swift:87` | `if subscriptionManager.isPremium` (satın alma sonrası) | `entitlements.snapshot.plan.isPaid` |

### 6.4 `story-engine` — tüketim

| Dosya:satır | Bugünkü kod | Yerine |
|---|---|---|
| `Screens/StoryWizardView.swift:321-324` | `guard stars > 0 else { openPaywall() }` | `entitlements.evaluate(.illustratedStory)` |
| `Screens/StoryWizardView.swift:328-330` | `guard subscriptionManager.useStory(type: .image) else { openPaywall() }` | `entitlements.consume(.illustratedStory)` |

⚠️ **Bugün iki ayrı kapı var ve ikisi de aynı reddi paywall'a çeviriyor.** Tek
çağrıya inmeli: `consume` zaten kapıyı yeniden değerlendiriyor. Ret sebebine
göre dallanmalı — `.quotaExhausted` ile `.requiresSubscription` aynı ekranı
açmamalı.

### 6.5 Dokunulmayacaklar

| Dosya:satır | Neden |
|---|---|
| `Views/SettingsView.swift:335/337/340` | `#if DEBUG` (286–354) içinde. Geliştirici anahtarı — üretimde yok, taşınmasın |
| `Views/SimpleSubscriptionView.swift:33-57` | RevenueCat `purchaseCompleted`/`restoreCompleted` geri çağrıları, `entitlements["premium"]?.isActive` kontrolü **arkasında**. Doğru kurulmuş, dokunulmasın |
| `Services/RevenueCatManager.swift` `isPremium` | Servis içi, `CustomerInfo`'dan okuyor. Kaynağın kendisi |
| `Services/SubscriptionManager.swift` `isPremium` | Şimdilik kalır; tüm çağrı yerleri taşındıktan **sonra** `@available(*, deprecated)` işaretlenip kaldırılabilir |

---

## 7. Gizlilik

RevenueCat entegrasyonu gizlilik açısından temiz kaldı: `Purchases.logIn` yok,
`setAttributes` yok, `setEmail`/`setDisplayName` yok, anonim app user ID.
**Bu turda hiçbiri eklenmedi ve eklenmemeli** — entitlement kararı çocuk
kimliğine değil cihaz aboneliğine bağlı, ve öyle kalmalı.

Yeni kod hiçbir şey log'lamıyor: `Services/Entitlements/**` içinde sıfır `print()`.

---

## 8. Test

`MagicPaperTests` altında iki paket, 43 test:

- `EntitlementPolicyTests` — 27 test, karar mantığının her dalı
- `EntitlementServiceTests` — 16 test, tüketim / snapshot / eşleme

Kapsam (llvm-cov, bölge · fonksiyon · satır):

| Dosya | Kapsam |
|---|---|
| `Capability.swift` | 100% · 100% · 100% |
| `EntitlementPolicy.swift` | 100% · 100% · 100% |
| `EntitlementService.swift` | 100% · 100% · 100% |
| `StubEntitlementService.swift` | 100% · 100% · 100% |
| `EntitlementPlan+SubscriptionTier.swift` | 100% · 100% · 100% |

İki test bilerek **regresyon kapısı**:

- `testThePolicyAgreesWithTheManagerItReplaces` — politika,
  `SubscriptionManager.canCreateStory` ile aynı cevabı veriyor. Bu tur davranışı
  değiştirmiyor, **yerini** değiştiriyor; ayrışırsa taşıma sessiz bir ürün
  değişikliği olurdu.
- `testTheQuotaTableMatchesTheSubscriptionManagersTable` — kota tablosu iki yerde
  yazılı (`SubscriptionTier.monthlyImageStories` ve
  `EntitlementPlan.monthlyIllustratedQuota`); ayrışmalarını yakalar.

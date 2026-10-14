# Alt çubuk için Liquid Glass: araştırma ve plan

Durum: uygulandı, dal `liquid-glass-tab-bar` (14 Ekim 2026). Adım 5'te plandan sapma: Yarat camlı değil düz marka renginde (cam üstüne cam konmaz). Adım 8 ve 9 yapılmadı.

## 1. Bugünkü durum

| Alan | Bileşen | Dosya | Cam? |
|---|---|---|---|
| Çocuk modu alt çubuğu | `KidTabBar` (özel, sistem `TabView` değil) | `DesignSystem/Pastel/MPNavigationChrome.swift` | Hayır: `Color.white.opacity(0.97)` + 1 pt çizgi |
| Ebeveyn modu alt çubuğu | `ParentTabs` (sistem `TabView`) | aynı dosya | **Zaten evet.** Xcode 27 / iOS 27 SDK ile derleniyor, `UIDesignRequiresCompatibility` yok; iOS 26+ cihazda sistem camı otomatik geliyor |
| Eski tasarım sistemi çubuğu | `MPTabBar` | `DesignSystem/MPNavigation.swift` | Hayır. **Hiç kullanılmıyor** (çağıran yok) |
| Mevcut örnek | `MPModeSwitch.GlassTrack` | `Screens/MPModeSwitch.swift` | Evet: `.glassEffect(.regular.interactive(), in: .capsule)`, iOS 26 öncesi `.ultraThinMaterial` |

- Dağıtım hedefi iOS 17.6 → her cam kodu `if #available(iOS 26.0, *)` arkasında, eskisi için yedek yüzey şart.
- `KidTabBar`, `ContentView.kidRoot` içinde `.safeAreaInset(edge: .bottom)` ile duruyor. Ana sayfa, Kitaplık ve Köşem `ScrollView`; içerik zaten çubuğun altından kayıyor ama %97 beyaz zemin bunu gizliyor. Cam ancak altından bir şey geçince anlam kazanır; yani yapı doğru, yalnızca yüzey değişecek.
- Ortadaki "Yarat" düğmesi bugün `LinearGradient.mpPrimary` ile dolu. Bu, tasarım yasasındaki "butonda gradient yok" kuralının mevcut bir ihlali. Cam işi bunu da kapatır.

## 2. Çakışma: FAZ 20 aynı dosyada

`faz-20-gunluk` dalı (worktree `MagicPaper-faz20`, son commit 13 Ekim 23:33) `KidTabBar`'ı 5 öğeye çıkarıyor: Ana sayfa · Günlük · Yarat · Kitaplık · Köşem, yatay boşluk `MPSpacing.sm`. `ContentView.kidRoot` da değişiyor.

**Sonuç:** cam işi FAZ 20 main'e girdikten sonra, o dalın 5 öğeli hâli üzerine yapılmalı. Paylaşılan dosya kuralı gereği aynı anda iki dal bu dosyayı değiştirmesin.

## 3. Araştırma özeti (iOS 26 / 27)

- **Sistem bileşenleri** (`TabView`, `NavigationStack` çubukları, `.toolbar`) yeni SDK ile derlenince camı kendiliğinden alır. Ebeveyn tarafında yapılacak iş yok, yalnızca doğrulama.
- **Özel çubuk için araçlar** (iOS 26+):
  - `.glassEffect(_ glass: Glass, in: Shape)`: `Glass.regular`, `.clear`, `.tint(Color)`, `.interactive()`.
  - `GlassEffectContainer(spacing:)`: yakın cam parçalarını tek yüzeyde örer, birbirine karışmasını (morph) sağlar ve tek render geçişinde çizer (performans).
  - `.glassEffectID(_:in:)` + `@Namespace`: seçili sekme göstergesinin camla kaymasını sağlar.
  - `.buttonStyle(.glass)` / `.glassProminent`: hazır cam düğme stilleri.
- **Yalnızca sistem `TabView`'da olanlar:** `tabBarMinimizeBehavior(.onScrollDown)`, `tabViewBottomAccessory`, `Tab(role: .search)`. Özel çubukta bunlar yok; taklit etmeyi önermiyorum (çocuk alanında kaybolan çubuk sakin UX ilkesine ters).
- **Erişilebilirlik:** sistem camı "Saydamlığı Azalt" ve "Kontrastı Artır" açıkken kendini koyulaştırır. Yedek yolun (`.ultraThinMaterial`) de `accessibilityReduceTransparency` ile opak `MP.C.surfaceCard`'a dönmesi gerekir.
- **iOS 27 notları (doğrulanmamış, üçüncü taraf kaynak):** Xcode 27'de uyumluluk anahtarı kalkmış; kullanıcıya sistem genelinde cam opaklığı ayarı gelmiş. Sistem `glassEffect` bu ayarı kendiliğinden izler; elle yapılan cam taklidi izlemez. Bu, `.ultraThinMaterial` + beyaz katman yerine gerçek `glassEffect` kullanmak için ek bir neden. WWDC26 notlarıyla teyit edilmeli.

## 4. Seçenekler

**A. Özel `KidTabBar`'ı cama taşı (öneri).** Aynı bileşen, aynı API (`selection`, `onCreate`), yalnızca yüzey ve düzen değişir. "Yarat" eylem olarak kalır, sekme gibi seçilmez.

**B. Çocuk tarafını sistem `TabView`'a taşı.** Cam, küçülme, iPad uyumu bedava gelir. Ama "Yarat" bir yer değil eylem; sistem çubuğunda bunu `selection` yakalayıp geri almakla taklit etmek gerekir (titreme, VoiceOver'da "seçili" okunması). Sekme durumu korunması da bugünkü `switch app.tab` yapısını değiştirir. Bu iş için fazla büyük ve riskli; ilke 2 (çalışan sistemi yeniden yazma).

## 5. Plan (seçenek A)

Sahip: `design-system` ajanı (bileşen) + `parent-ux` (kidRoot yerleşimi). Önkoşul: FAZ 20 main'de.

1. **Token'lar** (`MPTheme.swift`): `MP.Glass` ad alanı: `bar = Glass.regular.tint(MP.C.surfaceCard.opacity(…))`, `action = Glass.regular.tint(MP.C.brand).interactive()`. Cam ayarı tek yerden okunur; bileşenler satır içi `Glass` kurmaz. Yedek yüzey token'ı da burada.
2. **`MPGlassSurface` değiştiricisi** (`DesignSystem/MPGlass.swift`, yeni küçük dosya): iOS 26+ `glassEffect`; öncesinde `.ultraThinMaterial` + `C.edgeGlass` kenar; `accessibilityReduceTransparency` açıksa opak `surfaceCard`. `MPModeSwitch.GlassTrack` sonra bunu kullanacak şekilde sadeleşir (ayrı turda).
3. **`KidTabBar` yüzeyi:** `GlassEffectContainer` içinde yüzen kapsül (`MP.R` içinden semantik yarıçap, kenarda `MP.S.screenGutter`, altta güvenli alan üstünde `MP.S.x2`). Dört (FAZ 20 sonrası beş) sekme tek cam yüzeyde.
4. **Seçili sekme göstergesi:** `brandSoft` hap + `glassEffectID` ile kayma; Reduce Motion'da yerinde çapraz geçiş (`MPTabBar`'daki mevcut desen). Seçim renge ek olarak hapla da gösterilir (Differentiate Without Color).
5. **"Yarat":** gradient ve yükseltme kalkar. Çubuğun içinde, sekmelerle aynı satırda `MP.Glass.action` (marka renginde camlı hap, `textOnBrand` simge). `MPSize.createFab` ve `primaryGlow` gölgesi artık kullanılmaz.
6. **`ContentView.kidRoot`:** `.safeAreaInset` kalır; yüzen kapsül için ekranların alt `contentMargins` değeri kapsül yüksekliği + boşluk olacak şekilde kontrol edilir. Son öğe çubuğun altında kalmamalı.
7. **Okunurluk:** Ana sayfa sahne görseli ve kitap kapakları çok renkli. `Glass.regular` (`.clear` değil) + hafif kâğıt tonu; etiket ve simgeler en kötü arka planda (kapak ızgarası, gece teması) ≥ 4.5:1. Gerekirse etiketler `textPrimary` + `.bold`.
8. **Temizlik (ayrı commit):** kullanılmayan `MPTabBar` silinir ya da kasıtlı olarak bırakıldığı belgelenir; `MagicPaper_Design_System.md` navigasyon satırı güncellenir.
9. **Ebeveyn tarafı:** kod yok. iOS 26+ simülatörde `ParentTabs` camının `MPColor.actionPrimary` tint'iyle doğru göründüğü ekran görüntüsüyle doğrulanır.

## 6. Doğrulama

- CLAUDE.md'deki beş grep değiştirilen dosyalarda boş.
- Simülatör: iOS 26/27 ve iOS 17.6 (yedek yol); açık + koyu; en büyük Dynamic Type (çubuk `...xLarge` sınırında kalır, büyük içerik görüntüleyici çalışır); iPhone SE + Pro Max; Saydamlığı Azalt, Kontrastı Artır, Hareketi Azalt açık.
- Ana sayfa, Kitaplık (dolu + boş), Köşem, Günlük'te kaydırırken içerik camın altından geçiyor, son satır gizlenmiyor.
- VoiceOver: sekmeler "seçili" okunuyor, "Masal yarat" düğme olarak okunuyor.
- Uygulama testleri tabandan düşmüyor; yeni test gerekmez (yalnızca görünüm), ama `KidTab` seçim mantığı değişirse test eklenir.
- Performans: Instruments'ta kaydırma sırasında çubuk kaynaklı kare kaybı yok (`GlassEffectContainer` tek geçiş).

## 7. Kararlar (13 Ekim 2026, Batuhan)

1. **"Yarat" çubuğun içine iner.** Yükseltilmiş 64 pt daire kalkar; aynı satırda, aynı yükseklikte, marka renginde camlı bir öğe olur. Sekme gibi seçilmez.
2. **Yüzen kapsül.** Tam genişlik zemin yok.
3. **Üst başlıklar ileriki turda.** `KidHeader`, `MPTopBar`, `ParentHeader` bu işin dışında.
4. **Tasarım yasası genişledi.** Cam artık içeriğin üstünde yüzen gezinme kontrollerinde serbest (alt sekme çubuğu, `MPModeSwitch`). Kural `CLAUDE.md` "Derinlik" bölümüne eklendi.



## Kaynaklar

- Apple WWDC25, "Build a SwiftUI app with the new design": https://developer.apple.com/videos/play/wwdc2025/284/
- Sentia, "Adopting Liquid Glass Before iOS 27": https://www.sentia.com.au/blog/adopting-liquid-glass-before-ios-27
- Noqta, iOS 27 Liquid Glass benimseme rehberi (doğrulanmamış): https://noqta.tn/en/blog/apple-liquid-glass-ios-27-developer-adoption-guide-2026
- Ecorpit, "iOS 27 Liquid Glass in Xcode 27": https://ecorpit.com/ios-27-liquid-glass-xcode-27-migration-guide-2026/

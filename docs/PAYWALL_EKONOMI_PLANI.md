# Abonelik ekonomisi ve Paywall planı

Hazırlayan: İrem (Claude ile), 19 Kasım 2026. Dal: `irem`. Durum: **Batuhan'ın onayını bekliyor.**
Sprint: 22 Kasım'a kadar Paywall (Batuhan'ın görevlendirmesi). Bu belge Perşembe çıktısıdır; yerleşim Cuma, görünüm Cuma-Cumartesi, kod Cumartesi-Pazar.

**Öneri tek cümlede:** Her akşamın masalı ücretsiz kalsın; Premium tek plan olsun ve yalnızca bugün çalışan özellikleri satsın: gün boyu yeni masal, seriler, Masal ailem, bütün klasikler ve Original'lar, PDF masal kitabı, birden çok çocuk. Fiyat ₺149/ay ya da ₺999/yıl; 7 günlük deneme yalnızca yıllık planda.

## Onayın gereken kararlar

| # | Karar | Öneri | Onay |
|---|---|---|---|
| 1 | Plan sayısı | Tek plan, aylık + yıllık (bugün 3 kademe var, farkları kapalı olan görselli masal) | |
| 2 | Ücretsiz sınır | Her akşam 1 yeni kişisel masal (`EntitlementPolicy`'deki 12 saat kuralı zaten bu) | |
| 3 | Premium içerik | Gün boyu masal, seriler, Masal ailem, tüm klasik ve Original, PDF kitap, birden çok çocuk | |
| 4 | Fiyat (TR) | ₺149/ay, ₺999/yıl (ayda ~₺83, günde ₺3'ten az) | |
| 5 | Deneme | 7 gün, yalnızca yıllıkta; deneme bitmeden 2 gün önce hatırlatma | |
| 6 | Yurt dışı | Almanya/Hollanda: €4,99/ay, €34,99/yıl (App Store bölge fiyatı) | |
| 7 | Plan adı | "MagicPaper Premium" (Yıldız Kaşifi / Hikaye Kahramanı / Sihir Ustası kalkar) | |
| 8 | Hiç satılmayacaklar | Yıldız, rozet, kahraman kıyafeti, çıkartma, çocuğun kendi yazdığı masalları okumak | |

## Bugünkü durum: düzeltilmesi gerekenler

Hepsi kodda doğrulandı; dosya ve satırlar parantez içinde.

1. **Premium hiçbir şeyi kilitlemiyor.** `Capability` ve `EntitlementPolicy` kurulu ama hiçbir ekran çağırmıyor; `SubscriptionManager.canCreateStory` hiç kullanılmıyor. Ücretsiz kullanıcı her şeye sahip.
2. **Paywall kapalı bir özelliği satıyor.** "Ayda 5 görselli masal" (`PaywallView.swift:142`), ama görselli masal Release'te kapalı (`CloudIllustrationAccess`). App Store 2.1/3.1 ret riski.
3. **Ürün kimlikleri uyuşmuyor.** `Products.storekit`: `com.magicpaper.premium.monthly`; satın alma kodu `magicpaper_premium_monthly` arıyor (`RevenueCatManager.swift`, `productIdentifier`). Biri yanlışsa satın alma düğmesi ürün bulamaz.
4. **Yıllık ürün ve deneme yok.** StoreKit dosyasında yalnızca 3 aylık ürün var, `introductoryOffer` yok. Ekrandaki "İlk 7 gün ücretsiz" sabit yazı (`PaywallView.swift:144`).
5. **App Store 3.1.2 eksik.** Otomatik yenileme açıklaması, dönem ve fiyat cümlesi ve "Aboneliği yönet" yok.
6. **Satılamayacak özellikler.** Aile sesi ve aile paylaşımı Release'te kapalı (`FamilyFeatureAccess`, varsayılan `false`). Basılı kitap ve görselli masal da yok. Bunlar açılana kadar Paywall'da yer almaz, "yakında" olarak bile.

## Ücretsiz ve Premium sınırı

İlke: **ritüel ücretsiz, derinlik ve anı Premium.** Ebeveyn önce akşam alışkanlığını kurar; para, alışkanlık oturduktan sonra istenir. Çocuğun yaptığı hiçbir şey sonradan kilitlenmez.

| Özellik | Ücretsiz | Premium | Neden |
|---|---|---|---|
| Kişisel masal yazma | Her akşam 1 | Gün boyu, sınırsız | Ritüeli kuran şey ücretsiz; fazlası değer |
| Kendi yazdığı masalları okuma | Sınırsız | Sınırsız | Çocuğun malı kilitlenmez (güven) |
| Sesli okuma (Ragi okusun) | Var | Var | Okuma bilmeyen çocuk için temel |
| Klasikler ve Original'lar | Haftanın seçkisi + Uyku vakti rafı | 22 klasik, 5 seri (40 bölüm), tüm Original'lar | Vitrin ücretsiz, kütüphane Premium |
| Seri (beğenilen masalın 5 bölümlük devamı) | İlk bölüm | Bütün bölümler | "Yarın ne olacak?" merakı |
| Masal ailem (anneanne, kardeş, kedi) | 1 kişi | Sınırsız | Ebeveynin en duygusal noktası |
| Çocuk profili | 1 | Ailedeki her çocuk | Kardeşli ev için açık değer |
| PDF masal kitabı | Yok | Var | Anı ve hediye |
| Yıldız, rozet, kahraman, çıkartma | Var | Var | Kural: yıldız plana bağlanmaz |
| Uyku modu, okuma özeti | Var | Var | Sakin deneyim, güven |

Açılınca Premium'a eklenecekler: aile sesi, aile paylaşımı, görselli masal. Basılı kitap ve hediye kutusu Premium değil, tek seferlik ürün olur.

## Fiyat

Pazar (ABD App Store, Kasım 2026; Türkiye fiyatı kabaca üçte biri, `docs/VIZYON_PLANI.md`):

| Uygulama | Aylık | Yıllık |
|---|---|---|
| [Your AI Bedtime Stories](https://apps.apple.com/us/app/your-ai-bedtime-stories/id6756010994) | $3,99 | $29,99 |
| [OnceUpon.AI](https://apps.apple.com/app/id6754075637) | $4,99 | $29,99 |
| [Bedtime - Stories](https://apps.apple.com/us/app/-/id6450920852) | $7,99 | $19,99 |
| [Pagee](https://apps.apple.com/us/app/id6744743783) | haftalık $2,99 | $44,99 |
| [Masal Diyarı (Türkçe)](https://apps.apple.com/us/app/id6443411649) | $9,99 | $19,99 |

- **Öneri:** ₺149/ay (bugünkü fiyat), ₺999/yıl. Yıllık, aylığın 12 katına göre %44 ucuz. Ekranda "ayda ₺83" ve "günde ₺3'ten az" olarak gösterilir. Bu, gerçek ve doğrulanabilir bir çerçeveleme.
- **Haftalık plan yok.** Pazarda yaygın, ama ebeveyn güvenini aşındırıyor ve sakin marka dilimize uymuyor.
- **Yurt dışı:** Türk uygulama gelirinin büyük kısmı yurt dışından geliyor (`VIZYON_PLANI.md`). Diaspora aileleri için bölge fiyatı ayrı belirlenir.
- **Fiyat testi:** sonraya bırakılır. Önce ölçüm altyapısı lazım; `funnelUpload` bayrağı bugün kapalı.

## Ebeveyn psikolojisi: neyi kullanırız, neyi asla

Kullanacaklarımız. Hepsi gerçek bir bilgiye dayanıyor:

- **Sahiplik:** "İrem'in kitaplığı" başlığı ve çocuğun gerçekten okuduğu kapaklar.
- **Kimlik:** "Her akşam birlikte okuyan aile." Ebeveyn kendini bu kimlikte görmek ister.
- **Karşılıklılık:** her akşam bir masal hiç ücret istemeden verilir. Teklif ancak değer görüldükten sonra gelir.
- **Çerçeveleme:** yıllık plan varsayılan seçili, aylık yanında. "Günde ₺3'ten az" gibi gerçek bir hesap.
- **Güven:** deneme zaman çizelgesi ("Bugün → 5. gün hatırlatırız → 7. gün"), tek dokunuşla iptal, "Reklam yok · Veri satılmaz".
- **Zamanlama:** teklif değer anında gelir. Apple'ın önerdiği gibi, deneyimden sonra.

Asla:

- Geri sayım, "son 2 saat", sahte indirim ya da sınırlı süreli teklif.
- Çocuğa satış ve çocuk ekranında fiyat. "Ebeveynine söyle" gibi yönlendirmeler.
- Uydurma yorum, uydurma kullanıcı sayısı.
- Kapatma düğmesini saklamak, "Şimdi değil"i gri ve küçük yapmak.
- Masal sonunda satış (AGENTS.md: masal sonunda dükkân yok) ve bildirimle satış.

## Paywall nerede (ayrıntısı Cuma)

Taslak tetikleyiciler. Hepsi ebeveyn tarafında ya da ebeveyn kapısından sonra:

1. **İlk masal okunup bittikten sonra** (ilk açılış): ebeveyne yönelik tek bir tanıtım ekranı.
2. **Günün ücretsiz masalı kullanıldıktan sonra** ikinci masal istenince: çocuğa sakin bir cümle ("Yeni masal yarın akşam hazır"), ebeveyne kapı üzerinden teklif.
3. **Premium bir özelliğe dokunulunca:** serinin 2. bölümü, kilitli klasik, Masal ailem'e 2. kişi, PDF, 2. çocuk profili. Kapı, sonra teklif.
4. **Büyükler için odasında:** sabit bir "Premium" satırı.

## Teknik iş listesi (Cumartesi-Pazar)

- [ ] Ürün kimliklerini tek biçime getir: StoreKit dosyası, App Store Connect ve RevenueCat (App Store Connect ve RevenueCat erişimi Batuhan'da).
- [ ] Yıllık ürün ve 7 günlük tanıtım teklifi; deneme yazısını StoreKit'in `introductoryOffer` bilgisinden okut.
- [ ] `Capability` kapılarını gerçek çağrı noktalarına bağla (masal yazma, seri bölümü, klasik, Masal ailem, PDF, profil ekleme).
- [ ] Yeni `PaywallView`: tek plan, sahiplik başlığı, deneme çizelgesi, 3.1.2 metni, "Aboneliği yönet" (`manageSubscriptionsSheet`), geri yükleme.
- [ ] `SubscriptionTier`'ı tek plana indir; eski kademe adlarını kaldır.
- [ ] Derleme ve ekran görüntüsü: `[ekran]` turu (iPhone SE ve Pro Max, en büyük yazı).

## Açık sorular

- [ ] App Store Connect'te bugün hangi ürün kimlikleri tanımlı?
- [ ] RevenueCat'te "current offering" kurulu mu?
- [ ] Bir aile aboneliği (Apple Family Sharing) açılsın mı? Önerim evet: kardeşli evde değer, iyi niyet işareti.
- [ ] Hediye abonelik: Apple uygulama içi hediye aboneliği desteklemiyor; teklif kodu (offer code) ya da web ile mi yapılsın?

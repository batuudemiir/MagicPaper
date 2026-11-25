# Değer algısı ilkeleri

26 Kasım 2026. Kaynak: araştırma raporu "MagicPaper: değer algısı için psikoloji" (https://claude.ai/artifact/3bftB4bJbux7zksrFswcCu). Batuhan bütün önerileri onayladı (26 Kasım 2026).

**Tek cümle:** değer, ebeveynin üç sorusuna gerçek veriyle cevap vererek artar: çocuğuma ne kattı, bu masal gerçekten onun için mi, bu bizim neyimiz oldu. Kandırmaya dayanan hamle yapılmaz; her hamlenin "ancak şu doğruysa" koşulu vardır.

## Bu turda koda girenler

| # | Ne | Nerede | Koşul |
|---|---|---|---|
| 1 | Satın aldıktan sonra kalınan işe dönülür | `MPAppState.unlock` / `paywallDismissed`, `ContentView` | İş yalnızca yetki gerçekten açıldıysa çalışır |
| 2 | Büyükler için cümlesi ve kutuları haftanın kazançlarını söyler: okuma akşamı, ilk kez karşılaşılan kelimeler, masal arkadaşları. "Üst üste gün" kalktı | `ParentInsight`, `ParentOverviewView` | Her parça gerçek okuma kaydından; sayı sıfırlanmaz |
| 3 | "Bu akşamın sorusu": dün ya da bugün biten masal için ebeveyne tek açık uçlu soru | `ParentQuestion`, `ParentOverviewView` | Soru masalın gerçek bilgisinden (mod, arkadaş); olay uydurmaz, çocuğa gösterilmez |
| 4 | Paywall alt başlığı çocuğun gerçek masal sayısını söyler | `PaywallView.libraryLine` | Masal yoksa cümle yok |
| 5 | Çocuk kilit penceresi çocuğu büyüğe yönlendirmez ("Büyüklere göster" kalktı). Ebeveyn, çocuğun dokunduğu kapalı şeyi Büyükler için'de tek satır görür, "Tamam" ile siler | `MPLockedSheet`, `MPLockedInterest`, `SeriesCopy`, `TopicStep` | Çocuğa fiyat, teklif, "büyüğüne söyle" yok (AB UCPD Ek I 28, İngiltere DMCC Ek 20 para 30) |
| 7 | Hatırlatma sorusu masalı uyku öncesi rutini olarak anlatır | `FirstRunView` | "Uykuyu iyileştirir" denmez (kanıt ilişkisel) |
| 8 | Yıllık kartta yüzdenin yanında tutar: "aylığa göre yılda ₺789 az" | `PaywallView`, `RevenueCatManager.localizedAmount` | Canlı mağaza fiyatından; ürün yoksa yazılmaz |
| 10 | Rozetlerim başlığı "x rozet" (x / 69 değil); yıldız katı kilitliyken eşik yazmaz | `BadgesView`, `MPStarLevel.lockedHint` | Çocuğa sayı hedefi gösterilmez |

Hazırlık ekranı (öneri 6) zaten masalın gerçek bilgilerini gösteriyor (`StoryPreparationScript`); değişiklik gerekmedi.

## Editoryal ilkeler (kodsuz)

- **Masal sonu (öneri 9):** son sayfa sıcak, sakin bir kapanış cümlesiyle biter; ardından tek eylem "Ana sayfaya dön". "Bir masal daha" yok.
- **Seriler (öneri 11):** merak masalın içindedir; akşam bölümü yatışarak biter, "yarın ne olacak" sabahın merakıdır. Uyku modunda gerilimli kapanış (cliffhanger) yok. "Yarım kalan akılda kalır" (Zeigarnik) iddiası desteklenmiyor; kullanılmaz.
- **Yorumlar (öneri 12):** Paywall'da yorum alanı gerçek ve izinli ebeveyn yorumları gelene kadar boş kalır. Toplama: TestFlight aileleri ve değerlendirme isteğinden sonra. Teşvikli yorum açıkça yazılır; uydurma yorum ve kullanıcı sayısı asla.

## Asla

Geri sayım ve sahte süre; seri kaybı ve kayıp korkusu; çocuk ekranında fiyat, teklif ya da "büyüğüne göster"; uydurma yorum, sayı, "en popüler"; silik "Şimdi değil", utandıran ret metni; "hayır"dan sonra yeniden teklif, bildirimle satış; masal sonunda satış ve otomatik oynatma; tuzak üçüncü plan; "beyni geliştirir", "IQ artırır", "bilimsel olarak kanıtlanmış" gibi iddialar.

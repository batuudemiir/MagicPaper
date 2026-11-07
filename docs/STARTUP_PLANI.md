# MagicPaper: profesyonel startup planı

## Context

Batuhan Duolingo'yu akıcı, açıklayıcı ve profesyonel buluyor; MagicPaper'ın aynı seviyede, her yüzeyde aynı markayla görünen bir startup ürünü olmasını istiyor. Bu plan açık kaynak kodları, Duolingo ve Apple kaynakları, çocuk okuma araştırmaları ve MagicPaper'ın sayfa sayfa denetimine dayanıyor.

**Teşhis:** Duolingo ile fark tek tek ekranlarda değil, dört yerde:
1. **Marka dağınık:** başlık fontu kuraldan farklı, Ragi bulanık, üç ürün adı, üç plan adı dili, web ve tanıtım başka fontlarda.
2. **Değer geç geliyor:** ilk masala kadar splash, tanıtım, giriş, onay, profil, bildirim ve 15 saniyelik atlanamaz bekleme var.
3. **Uygulama sessiz:** animasyon kütüphanesi ve ses yok, masal sonunda başarı titreşimi bile yok.
4. **Korkuluk ve ölçüm yok:** UI ve görüntü testi yok, CI test çalıştırmıyor, huni ölçülmüyor.

**Batuhan'ın kararları (7 Kasım):**
- Önce masal, sonra hesap.
- Ragi animasyonu + hafif ses; seri baskısı yok.
- Aşamalı mimari temizlik, tam modülerleşme yok.
- Baloo 2 başlıkta geri geliyor.
- Ragi için illüstratör + Rive animatör (dış bütçe).
- Tek ürün adı: **MagicPaper**.
- Çubuk: Ana sayfa · Masallar · Kitaplık · Profil + Masal yaz.

## Bölüm 1: Marka sistemi

Apple'ın [marka rehberi](https://developer.apple.com/design/human-interface-guidelines/branding): marka içeriğe yol verir, logo her yerde tekrarlanmaz, açılış ekranı marka alanı değildir. Duolingo ve [Headspace](https://designcompass.org/en/2024/04/30/headspace/) dersi: marka küçük bir kurallar setinin ([renk, kontur, şekil](https://blog.duolingo.com/shape-language-duolingos-art-style/)) her yüzeyde tekrarıdır, Duolingo'da yazı tipi bile [maskottan türetildi](https://creativebloq.com/news/feather-bold).

### 1.1 Marka çekirdeği (`docs/MARKA.md`, tek kaynak)

| Öğe | Öneri |
|---|---|
| Vaat | "Her çocuğun kendi masal dünyası" (CLAUDE.md) |
| Kişilik | Sıcak, masalsı, sakin, özenli. Duolingo'nun şımarıklığı değil, iyi bir çocuk kitabının sesi |
| İmzalar | Sert alt kenar, Ragi, kitap ve kâğıt dili, mor + krem |
| Yasak | Neon, parıltı, gradient buton, "yapay zeka" sözü, baskı dili |

### 1.2 Bulunan tutarsızlıklar ve düzeltme

| Bulgu | Düzeltme |
|---|---|
| Ad: "MagicPaper", "Magic Paper" (proje), "MagicPaper Kids" (3 kapak dosyası), CLAUDE.md başlığı | Her yerde MagicPaper; CLAUDE.md güncellenir |
| Plan adları: paywall'da "Hikaye Kahramanı", "Yıldız Kaşifi"; kodda ayrıca "Sihir Ustası" ve emojili adlar | Tek liste, emoji yok, `Products.storekit` ve `SubscriptionManager` hizalanır |
| Renk: belge birincil #5C3A8F diyor, eylem #6A47B8 | Birincil #6A47B8 (3 Ekim kararı), belge ve yasal sayfalar buna göre |
| `privacy.html` ve `terms` #9449FA, sistem fontu | Marka fontu ve rengi |
| Tanıtım filmi Fraunces + Inter Tight, promo Pixelify Sans, Ragi'nin adı metinlerde yok | Baloo 2 + Nunito, Ragi ön planda |
| `AppLogo` "Adsız tasarım-2.png" | Adlandırılmış varlıklar: logo, ikon, kelime işareti |
| Paywall'da Ragi var, kural ebeveyn alanında yok diyor | Kural netleşir: öneri paywall'da Ragi kalkar, satın alma yetişkin ekranıdır |
| Boş durumlar farklı: Masallar rafı, Yeni kelimeler, Masal ailem kendi düzeninde | Hepsi `MPStateView` |
| Spinner 7 yerde düz `ProgressView` | Ragi'li tek yükleme bileşeni, buton içi hariç |

### 1.3 Ragi karakter kitabı

Önkoşul: illüstratör bütçesi. Bugün 14 poz **1x PNG** (148 piksel görsel 150 pt gösteriliyor, telefonda bulanık); `happy`, `front`, `threeQuarter` ve `mascotPeek` hiç kullanılmıyor.

- **Karakter kitabı:** [önce siluet](https://blog.duolingo.com/reshaping-duo/), oranlar, renk, kontur, yapılır/yapılmaz, kim hangi duyguda.
- **Vektör pozlar:** kullanılan 11 poz + yeni "seviniyor"; `MascotImage` arkasında değişir, ekranlar değişmez.
- **Rive:** bekliyor, el sallıyor, seviniyor, okuyor, uyuyor. Duolingo Rive kullanıyor (ikincil kaynak). [rive-ios](https://github.com/rive-app/rive-ios) MIT.
- **Kural:** ekran başına tek Ragi, ama [her başlığa zorla süs de yok](https://blog.duolingo.com/core-tabs-redesign). "Her çocuk ekranında Ragi" kuralı "anlamı olan ekranda Ragi"ye gevşetilir (Batuhan kararı ister).

### 1.4 Ses ve söz

- **`docs/SES_VE_SOZ.md`:** çocuğa "sen", ebeveyne yalın; masal "yazılır"; hata suçlamaz; "Harika gidiyorsun!" gibi genel övgü yerine söyleneni göster. Bugün kurallar dağınık, ayrı belge yok.
- **Ses imzası:** 4-5 kısa ses, aynı enstrüman ailesi (Faz 4).
- **Metin denetimi:** tüm Türkçe metinler tek geçişte gözden geçirilir, `marketing` ve e-posta dahil.

### 1.5 Her yüzey aynı marka

| Yüzey | Yapılacak |
|---|---|
| App Store | Ad, alt başlık, görseller testten üretilir ([isowords](https://github.com/pointfreeco/isowords) yöntemi), önizleme videosu |
| Açılış | `UILaunchScreen` boş; [Apple](https://developer.apple.com/design/human-interface-guidelines/launching) ilk ekranla aynı zemin, yazısız diyor. 1,6 sn sabit splash kalkar, ilk açılışta kısa Ragi anı |
| Widget, Live Activity, bildirim | Baloo 2 başlık; sakin dil zaten iyi, korunur |
| PDF kitap | Kapakta Baloo 2, kolofonda Ragi, "MagicPaper Kitaplığı" tek ad |
| Web, yasal, e-posta, davet | Tek şablon |
| Basılı kitap, sosyal medya | `MARKA.md`'den türetilir, sonraya |

## Bölüm 2: Görsel dil

### 2.1 Yazı

Bugün 16+ stil, neredeyse hepsi `heavy`/`black`, gövde 15 pt `semibold`. Her şey kalın olunca hiyerarşi kayboluyor; [Apple](https://developer.apple.com/design/human-interface-guidelines/typography) iOS varsayılanı olarak 17 pt ve az stil öneriyor, [Duolingo](https://blog.duolingo.com/core-tabs-redesign) de stil sayısını azalttı.

| Rol | Font | Boyut / ağırlık | Yerine geçtiği |
|---|---|---|---|
| Kapak | Baloo 2 | 34 bold | heroTitle, pageTitle, display |
| Sayfa başlığı | Baloo 2 | 28 bold | largeTitle, title1, title2 |
| Bölüm başlığı | Baloo 2 | 21 semibold | title3, headline, navTitle |
| Kart başlığı | Nunito | 17 bold | cardTitle, bodyStrong |
| Gövde | Nunito | 17 regular | body (15 semibold) |
| İkincil | Nunito | 15 regular | callout |
| Dipnot | Nunito | 13 semibold | footnote, caption, eyebrow |
| Düğme | Nunito | 17 bold | button |

- Dynamic Type korunur, `.custom(_:relativeTo:)`.
- Baloo 2 Google'da `latin-ext` sunuyor; ğ, ş, ı, İ eklenince gözle doğrulanır.
- Değerler taslaktır; önce Profil ve Ana sayfada görüntü testiyle denenir.

### 2.2 Düğmeler

Bugün `MPButton` 6 tür + 4 boy, ayrıca `MPCircleButton`, `MPRoundActionButton` (tek kullanım), eski `MPIconButton`, elle yazı düğmeleri ("Bana sürpriz yap", "Değiştir"). [Apple](https://developer.apple.com/design/human-interface-guidelines/buttons): stil ile hiyerarşi, ekranda 1-2 öne çıkan, en az 44 pt.

| Tür | Görünüm | Kural |
|---|---|---|
| Birincil | Dolu mor, sert kenar, 56 pt | Ekranda bir tane |
| İkincil | Lavanta, kenarsız, 52 pt | `secondary` ve `soft` birleşir |
| Metin | Mor yazı, dokunma alanı 48 | `ghost`; elle yazılanlar buna geçer |
| Tehlikeli | Kırmızı | Yalnız ebeveyn |
| Daire | 48 dokunma alanı | Geri, kapat, arama |

- **İmza hareket:** basınca düğme kenarın üstüne iner (Duolingo'nun bilinen dokunuşu, ikincil kaynak). `MPPressStyle` içinde tek yer. Şu an basma stili kenarla bütün değil.
- `small` 38 pt görsel kalabilir ama dokunma alanı 48. `outline` ve `MPRoundActionButton` kalkar.
- Devre dışı: %40 saydamlık yerine düz gri, kenarsız.

### 2.3 Kart ve derinlik

Üç sistem çakışıyor: `MPCard` (kid gölge, parent çerçeve), `mpKidSurface` (sert kenar), `mpEdge` (`edge` parametresini yok sayıp gölge çiziyor; **hata**, Design law "imza" dediği şey bu).

- Kural: dokunulan kart sert kenar, dokunulmayan öğe kart değil, ebeveyn alanı ince çerçeve.
- `mpEdge` düzeltilir, görüntü testiyle tüm etkilenen ekranlar kontrol edilir.
- İkon: `MPIcon` (Lucide), ama sistem sekme çubuğu SF Symbol; çubuk bunu korur (Apple öneriyor), sayfa içi tek Lucide.

## Bölüm 3: Gezinme çubuğu

Karar verildi, ayrıntılar:

- **Sabit, küçülmez**: küçük çocuk için öngörülebilir.
- **Masal yaz daire**: iOS 27 `.prominent`, 26'da `.search`, öncesi `KidTabBar`. Etiketin VoiceOver'da okunduğu denetlenir.
- **Rozet yok** ([HIG](https://developer.apple.com/design/human-interface-guidelines/tab-bars): kritik bilgi için). Baskı dili yaratır.
- **Seçili sekmeye dokunma** her sekmede köke döner ve başa kaydırır (bugün başa kaydırma yalnız Masallar'da).
- **Ebeveyn çubuğu**: Özet · Güvenlik · Ayarlar kalır.
- **iPad**: `sidebarAdaptable` (IceCubes bunu kullanıyor), Faz 6.
- **"Kaldığın yerden" aksesuarı** (`tabViewBottomAccessory`): denenecek fikir, ilk sürümde yok.

## Bölüm 4: Sayfalar

### 4.1 Ana sayfa

Tek soru: "Bu akşam ne okuyoruz?" En fazla 4 bölüm; [çocukta dağınıklık dikkati bozar](https://medium.com/you-i-tv/designing-a-tv-app-for-kids-9bb446b362be).

| Sıra | Bölüm | Değişiklik |
|---|---|---|
| 1 | Selam + ad + yıldız satırı | "0 gün üst üste" gösterilmez, sıfırsa o parça yok |
| 2 | Bu akşamın kartı | Ana eylem; `readToday` sözü "Harika gidiyorsun!" değişir |
| 3 | Devam eden seri | Varsa kartın hemen altında (bugün aşağıda) |
| 4 | Yeni masal: üç mod | Aynı, satır dili |
| 5 | Masallar rafı | **Kapağa dokununca o masal açılır** (bugün her kapak yalnız sekmeyi açıyor) |
| 6 | Günün masalı | Kartta değilse; rafla birleştirilir, ayrı bölüm olmaz |

### 4.2 Masallar

Vitrin, raf kapıları, kaldığın yerden, seçki, raflar, uyku, Kahramanı sen ol. Amacı tek, yapı korunur. Vitrin başlığı resim üstünde: okunabilirlik karartmayla sabitlenir (karanlık slaytta soluk kalıyordu). Raf kapıları sadeleşir.

### 4.3 Kitaplık

"Benim masallarım". Boşken tek Ragi + "İlk masalını yaz". Arama ve süzgeç 6 kitapta açılır (yapıldı). Kart: kapak, ad, ilerleme.

### 4.4 Profil

Kim okuyor (en üstte), Ragi selamı, sayılar, Masal dünyam, rozetler, Büyükler için. Sayılar sıfırsa teşvik cümlesi. Rozet ızgarası sade.

### 4.5 Alt sayfalar

| Sayfa | Değişiklik |
|---|---|
| Masal detayı | Kapak, tek "Oku", yaş ve süre, Dinle/Listeme ekle; anlatım seçimi "Daha fazla"ya |
| Seri | `HeaderWash` gradient'i kalkar, sahne dili |
| Masal ailem, Kahraman | Ad "Kahraman"; 3 Ekim kuralına göre serbest metin yok, aile adı istisnası korunur |
| Yeni kelimelerim | Kelimeyi duyma öne çıkar |
| Uyku modu | Bayrakta kapalı; Bölüm 6 ile birlikte açılması değerlendirilir |

### 4.6 Ebeveyn odası

- **Özet:** sayılar, grafik, son masallar, onay. Abonelik buradan Ayarlar'a tek yerde.
- **Güvenlik:** yapı iyi. Her karar yanında tek cümle etki.
- **Ayarlar:** Profiller, Aile ve ses, Bildirimler, Hesap, Destek. "Geliştirici" yalnız debug (zaten öyle).
- **Paywall:** masaldan sonra, [Apple'ın önerdiği gibi](https://developer.apple.com/design/human-interface-guidelines/onboarding) deneyimden sonra.

### 4.7 İlk açılış (önce masal)

Yeni sıra: **tek karşılama → çocuğun adı ve yaşı → ilk masal → masal sonunda "Masallarını kaybetme" ile giriş + onay → hatırlatma → satın alma sonra.**

- Değişecek: `AppGate.resolve` (`StoryEngineBridge/Account/AccountModel.swift`), `MagicPaperApp.swift`, `Views/OnboardingView.swift`, `FirstRunView.swift`, `StoryEndingLeaf.swift`.
- Yeniden kullanılacak: `ProfileCreationView`, `StoryPreparationView`, `AccountSignInView`, `ParentConsentView`, geri yükleme ekranı.
- Hesap: "Sonra" denebilir; 3. masaldan sonra, aile, seri, satın alma ve başka cihaz için zorunlu. Eşik ölçümle ayarlanır.
- Veri: hesaptan önce yalnız cihazda; girişte yerel profil hesaba bağlanır. Mevcut hesap + yeni cihaz çakışması testlenir.
- **Hukuk kapısı:** ad onaydan önce cihazda duruyor; `privacy-safety` incelemesi ve hukukçu görüşü. Kullanım paylaşımı bugün varsayılan açık, varsayılan kapalı önerilir.
- 3 Ekim kararı ve CLAUDE.md güncellenir. Duolingo'nun "%20 DAU" rakamı ikincil kaynakta; kendi ölçümümüzle sınanır.

## Bölüm 5: Masal yazma akışı

**Bugün:** bar'dan okumaya 5 dokunuş (iki çocukla 6), üstüne 6-15 sn yapay bekleme. Zorunlu karar yalnız mod. Rakip uygulamalarda da kalıp [kısa girdi + tek dokunuş, ayarlar sonra](https://www.aiville.com/c/ai-directory/bedtimestory-ai).

**Hedef:** bar'dan okumaya 3 dokunuş, sürprizle 2.

| Adım | Bugün | Öneri |
|---|---|---|
| Çocuk | Ayrı ekran (2+ çocukta) | Tek satır: "İrem için ▾"; yalnız değiştirmek isteyen dokunur |
| Mod | Seç + "Devam et" | **Moda dokununca geçer**, düğme yok |
| Konu | Mod ekranında satır içi | İkinci adımda isteğe bağlı |
| Kimler | Ayrı adım | Ragi önerir, hazır seçili gelir; "Masalı yaz" hep görünür |
| Sürpriz | Yine kimler adımına gidiyor | **Doğrudan yazılır**: sürprizin anlamı bu |
| Hazırlanıyor | İlk masal 15 sn atlanamaz; sonra 10, 6 sn | Defter ritüeli kalır (karakterli, senin kararın), ama ilk masalda da **2 sn'den sonra atlanabilir**, süre 6-8 sn |
| Masalı oku | Ek dokunuş | Defter kapanınca kendiliğinden açılır; "Sonra oku" küçük |
| İthaf | Otomatik | Korunur, güçlü an |

- `StoryCreationSteps` karar mantığı kalır, testler güncellenir.
- "Bana sürpriz yap" `MPButton` metin türüne geçer.
- Giriş noktaları tek akışa bağlı, öncesi seçili gelir (modla gelince ilk adım atlanır; bu zaten böyle).

## Bölüm 6: Okuyucu ve etkileşim

### 6.1 Araştırma ne diyor

- [Takacs, Swart, Bus 2015](https://eric.ed.gov/?id=EJ1081714) (29 çalışma): multimedya hikâye anlamayı ve kelimeyi az ama anlamlı artırıyor; **olay örgüsüyle ilgisiz oyun ve hotspot zarar veriyor**.
- [Munzer 2019](https://readingrockets.org/research-by-topic/differences-parent-toddler-interactions-electronic-versus-print-books) (37 çift): efektli e-kitapta ebeveyn ve çocuk daha az konuşuyor, biçim hakkında daha çok.
- [Kucirkova](https://cdn.literacytrust.org.uk/media/documents/2017-11-21_Personalised_books_and_family_literacy_outcomes_-_National_Literacy_Trust.pdf): çocuğun adı geçen bölümlerde kelime bilgisi ve konuşma artıyor (küçük örneklem). Ürünün temeli için iyi işaret.
- [Katzir 2013](https://pmc.ncbi.nlm.nih.gov/articles/PMC3777945/): 2. sınıfta 20 pt'den küçüğe ve uzun satıra inmek anlamayı düşürüyor; 5. sınıfta 13 pt yeterli, daha küçük zarar vermiyor. Satır aralığı etkisiz.
- Kelime vurgusu: [çocuğun dikkatini metne çekiyor](https://www.researchgate.net/publication/352918832_The_effect_of_visual_cues_in_e-books_on_pre-K_children's_visual_attention_word_recognition_and_comprehension_An_eye_tracking_study), kazanımı küçük çalışmalarda karışık. Epic'te [okurken kelime vurgusu var](https://screensdesign.com/showcase/epic-kids-books-reading).
- Uyku: [uyarıcı içerik asıl sorun](https://www.thensf.org/effects-of-screen-use-on-childrens-sleep/); gece modunun [etkisine kanıt yok](https://sst.dk/en/english/Healthcare-professionals/Health-promotion/Screen-use). Sağlık iddiası yapılmaz.

Sınır: 2025 meta-analizi ve iki derleme erişime kapalıydı (403), yalnız özetleri görüldü.

**İlke: etkileşim masalın içinde olur, masalın önüne geçmez. Okuyucu ebeveyn ve çocuğu konuşturur.**

### 6.2 Okuyucu planı

| Konu | Bugün | Öneri |
|---|---|---|
| İki okuyucu | `StoryReaderView` ve ayrı kaydırmalı `DailyStoryReaderView` | **Tek okuyucu**, günün masalı da aynı |
| Sayfa çevirme | Kaydırma, sayfa kıvrımı; dokunmak yalnız denetimleri açar | **Kenara dokununca sayfa çevrilir**, ortası denetim. [NN/g](https://www.nngroup.com/articles/children-ux-physical-development/): sürükleme küçük çocuğa zor |
| Yazı boyutu | 17/19/22/26, varsayılan tek | **Yaş bandına göre varsayılan**: 3-6: 26, 7-8: 22, 9-10: 19; ayar kalır |
| Sesli okuma vurgusu | Cümle düzeyi; 3-6 düzeninde hiç yok; aile sesinde yok | **Kelime düzeyi** TTS'te (`willSpeakRange` izin veriyorsa); önce 3-6 |
| Aile sesi | Var, ama bulmak zor | Farklılaştırıcı: okuyucuda öne çıkar, kayıt için davet (ebeveynde) |
| Kelime kartı | Var | Korunur: masala ait, zarar veren türden değil |
| Ses kelimeleri | Görsel | Dokununca tek seferlik ses (masala ait); ayardan kapanır, bedtime'da yok. Küçük pilot |
| Hotspot, mini oyun, puan | Yok | **Eklenmez** |
| Çocuğun adı | Vurgulu | Korunur |
| Denetimler | 4,5 sn sonra kaybolur | Korunur; açıkken tek satır |
| Resim | Çoğu sayfada yok | B2 sahne kütüphanesi ayrı yol haritası, buradan bağımsız |

### 6.3 Birlikte konuşma

- **Masal sonu "Birlikte konuşalım":** 1-2 soru, [CROWD](https://readingrockets.org/article/dialogic-reading-having-conversation-about-books) türünden ("Sen olsan ne yapardın?"). Motorun karakter ve yerini kullanır, serbest yapay metin yok; sonuç puanlanmaz. Duolingo/Epic'in sınavı yerine.
- Epic'teki yüzdeli test **alınmaz**: okuma ritüelini sınava çevirir.
- Sayfa arası soru yok: akışı böler, kanıt yok.

### 6.4 Masal sonu (en önemli an)

| Gündüz | Akşam |
|---|---|
| Ragi seviniyor + kısa ses + `MPHaptics.success` (bugün yok) | Ragi uyuyor, ses yok, yalnız fade |
| Kazanılan tek tek belirir (yıldız, kelime, rozet) | Tek cümle: "İyi geceler, İrem." |
| Birlikte konuşalım | Yok |
| "Bir masal daha" / "Bitir" | "İyi geceler"; ekran kararıp kapanır |

"İyi geceler" bugün yalnız toast gösteriyor (uyku modu kapalı); gerçek bir kapanışa bağlanır. Üç düğmeden ikisine iner.

### 6.5 Uyku

Sesli dinleme + karartılmış ekran doğru yön; bayrak kapalı `SleepModeView` buna hazır. Süre, ayarlardaki sınırla. "Mavi ışık" ya da "daha iyi uyku" iddiası yazılmaz.

## Bölüm 7: Kod ve mimari

Aldıklarımız:

| Kaynak | Alınan | Alınmayan |
|---|---|---|
| [IceCubes](https://github.com/Dimillian/IceCubesApp) (AGPL: **yalnızca fikir**) | Sekme başına `RouterPath`, `withAppDependencyGraph`, `@Observable` + `@Environment` | Paket parçalama |
| [Dimillian/Skills](https://github.com/Dimillian/Skills) (MIT) | Görünüm sırası, alt görünüm, durum tablosu, önizleme kuralları | Görünümde iş mantığı |
| Duolingo [MVVM](https://blog.duolingo.com/ios-mvvm-swift-macros/), [test hattı](https://blog.duolingo.com/ai-ios-unit-test-generation-pipeline/) | Depolama arkasında protokol, kural linter'la | Makro |
| [Bitwarden](https://github.com/bitwarden/ios) (GPL: yalnızca fikir) | Yazılı `Architecture.md` | Coordinator + Processor |
| [Kickstarter](https://github.com/kickstarter/ios-oss), [isowords](https://github.com/pointfreeco/isowords) | Her durumda görüntü testi, testten App Store görseli | Reaktif VM, TCA, 86 modül |
| [Wikipedia](https://github.com/wikimedia/wikipedia-ios) `WMFComponents/Style` | Tek token klasörü | |

Yapılacaklar (kural: **dokunulan ekran taşınır**):

- **`MPRouter`:** `MPAppState` (500 satır, 24 `@Published`, yaklaşık 10 sorumluluk) bölünür: önce gezinme, sonra okuyucu oturumu ve akşam akışı.
- **Tek token:** `MP.*` kalır, Pastel takma adları dokunuldukça kalkar. Örtüşenler teke: `MPNavBar`/`MPTopBar`, `MPStatCard`/`MPStatTile`, `MPAvatar`/`MPInitialAvatar`.
- **Bağımlılık:** yeni kod `.shared` çağırmaz (bugün 266 referans, 33 tip); `@Observable`'a dokunulan tipte geçiş.
- **Ölü kod:** `Helpers/Localization.swift`, `LocalizationManager` (önce 6 `isEnglish`), `LegacyMPControls` kalıntıları, `MPTabBar`, `LocalNotificationManager`, `PermissionManager`. Silmeden çağıranlar okunur.
- **Performans:** `ReaderImageLoader` eşzamanlı çözme, açılış işleri ertelenir, `os_signpost`.

## Fazlar

Durum (7 Kasım 2026): Faz 0, 1 ve 2 bitti; Faz 3'ün hukuk gerektirmeyen kısmı bitti (masal yazma, Ana sayfa, tek okuyucu, kenar dokunuşu), "önce masal" hukuk onayı bekliyor. Faz 4 illüstratörsüz yapıldı (Batuhan kararı): Ragi kod kuklasıyla hareket ediyor (Rive yerine), ses kodla sentezlendi, masal sonu yenilendi, Birlikte konuşalım eklendi; pozlar 4 kat büyütüldü (`docs/RAGI.md`). Ayrıntı `design-handoff/reference/DEMO_CHANGELOG.md`.

Her faz ayrı commit'ler, Değişiklik günlüğü ve Design law güncellemesiyle biter.

| Faz | İçerik | Bağımlılık |
|---|---|---|
| **0 Korkuluk** | Görüntü testleri, ilk XCUITest + erişilebilirlik denetimi, CI'da test, Xcode Cloud sürümü, ölü kod, MetricKit | Yok; ilk iş |
| **1 Marka temeli** | `MARKA.md`, `SES_VE_SOZ.md`, tek ad, plan adları, Baloo 2 + yazı ölçeği, düğme sistemi, `mpEdge` düzeltmesi | Faz 0 |
| **2 Mimari** | `MPRouter`, tek token, `ARCHITECTURE.md` | Faz 0; Faz 1 ile paralel olabilir |
| **3 Akış** | Masal yazma 3 dokunuş, önce masal + hukuk kapısı, Ana sayfa, tek okuyucu, kenar dokunuşu | Faz 1, 2; **hukuk onayı** |
| **4 Canlılık** | Ragi karakter kitabı → vektör → Rive pilotu (masal sonu), `MPSound`, masal sonu yeniden, Birlikte konuşalım | **İllüstratör ve animatör**; Faz 3 |
| **5 Okuma derinliği** | Kelime vurgusu, yaş bandı varsayılanı, uyku modu, aile sesi öne çıkar | Faz 3 |
| **6 Yayın ve ölçüm** | Onaylı anonim huni, uzaktan bayrak, web ve yasal sayfalar, App Store görselleri, TestFlight 5-10 aile, String Catalog, iPad, Kids Category kararı | Faz 3-5 |

**Başarı ölçütleri:** ilk masala süre ve dokunuş; ilk masalı bitirme; hesap dönüşümü; 7 günde okunan gün; "Büyükler için"i bulma. Uygulamada geçen süre hedef değil (ilke 7). Üçüncü taraf analitik yok ([5.1.4](https://developer.apple.com/app-store/review/guidelines/)).

## Yapılmayacaklar

TCA, tam modülerleşme, server-driven UI, seri baskısı ve panikleyen maskot ([Duolingo widget'ı](https://blog.duolingo.com/widget-feature/) tam bunu yapıyor), geri sayım, suçlayan bildirim, puan ekonomisi, masal sınavı, hotspot ve mini oyun, üçüncü taraf analitik, sağlık iddiası.

## Bizden beklenen kararlar

1. "Her çocuk ekranında Ragi" kuralı "anlamı olan ekranda"ya gevşesin mi?
2. Paywall'dan Ragi kalksın mı?
3. Çocuk dokunma alanı 56 pt (öneri).
4. Hazırlanıyor süresi: ritüel 6-8 sn + 2 sn'de atlanabilir.
5. İllüstratör ve animatör bütçesi, hukuk görüşü: **dış iş, takvimi belirler.**

## Riskler

- **Hukuk ve hesap birleştirme** (önce masal): yayın öncesi onay şart.
- **Sanat bütçesi:** gecikirse Faz 4 kayar; Faz 0-3 bağımsız.
- **Yazı ölçeği değişimi:** tüm ekranları etkiler; görüntü testi olmadan başlanmaz.
- **Kaynak sınırı:** rakiplerin çubuk ve okuyucu ayrıntıları cihazda açılıp doğrulanmadı; Epic, Lingokids, Moshi kısa cihaz incelemesi Faz 1'de önerilir. Duolingo'nun resmî marka sayfası erişilemedi (yönleniyor); renk ve buton ayrıntıları ikincil kaynak.
- **Paralel oturumlar:** ortak klasörde başka oturumlar çalışıyor; büyük taşımadan önce kontrol.

## Doğrulama

- Her faz: 1.819 test + görüntü testleri, CI'da; Design law grep'leri boş; açık + en büyük yazı; iOS 17/18, SE ve Pro Max simülatörleri kurulur (bugün yok).
- Faz 3: temiz kurulumdan ilk masala ölçüm; hesapsız → giriş → masallar duruyor; mevcut hesap + yeni cihaz; 1 ve 2 çocukla dokunuş sayımı.
- Faz 4-5: Reduce Motion, sessiz anahtar, bedtime'da ses yok, VoiceOver.
- Faz 6: TestFlight ebeveyn gözlemi.

## İlk adım

Onaylanınca bu plan `docs/STARTUP_PLANI.md` olarak repoya girer ve **Faz 0 görüntü testleriyle** başlanır.

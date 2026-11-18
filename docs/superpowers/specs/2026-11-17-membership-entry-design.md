# MagicPaper: üyelik girişleri ve ücretsiz deneyim

17 Kasım 2026 · Batuhan akışı “evet mantıklı” ile onayladı. Fiyat ve canlı mağaza ürünü henüz belirlenmedi.

## Onaylanan akış

1. İlk kurulumda profil hazır olduktan sonra, ilk masaldan önce ebeveyne sınır anlatılır: üç kişisel masal ücretsiz; sonrasında yeni masallar için üyelik. “Ücretsiz masallarla başla” ve “Üyelik seçeneklerini gör”. Deneme kart istemez.
2. İlk masal üç haktan biridir. Haklar cihazdaki tüm profiller için ortaktır. Yeni profil veya masal silmek hak yenilemez. Yeniden kurulum ve başka cihaz aynı hakkı tekrar verebilir; sunucu kotası ve aile çapında deneme takibi kapsam dışı.
3. Yalnız kalıcı kaydı başarılı kişisel masal hak tüketir. Hata, yeniden okuma ve çift callback tüketmez. Hazırlıktan çıkıldığında masal zaten kaydedilmişse hak kullanılmıştır; kayıt oluşmadıysa kullanılmaz.
4. Hak bitince yeni “Masal yaz” girişinde, seçimlerden önce çocuk durumu açılır: “Kitaplığındaki masalları okuyabilirsin. Yeni masallar için büyükler bölümüne geçebilirsin.” Ana eylem “Kitaplığı aç”, ikinci eylem “Büyükler için”. Fiyat/paket/geri sayım yok.
5. Büyükler için → çocuk durumu kapanır → merkezi quiz ebeveyn kapısı → kapı kapanır → paywall. Sıradan ebeveyn odası girişinin hold kapısı değişmez.
6. Tek üyelik, aylık/yıllık seçenek. Gerçek mağaza fiyatı/dönemi gösterilir; ürün yoksa yeniden deneme durumu, sabit referans fiyat yok. Kapatma, restore ve yönetim erişilebilir.
7. Etkin entitlement doğrulanıp paywall kapandıktan sonra bekleyen masal yazma niyetine dönülür. Mod ve aile yol arkadaşı bağlamı korunur. Seçim akışı açılır; kendiliğinden masal yazılmaz.
8. Kapı/paywall iptali bekleyen niyeti temizler. Hak bitmiş giriş kitaplığa, ebeveyn ayarından gelen teklif kendi ekranına döner. İlk kurulum teklifinden vazgeçilirse ücretsiz başlangıç seçeneği görünür kalır.
9. Büyükler için kökünde etkili üyelik durumu, ücretsiz hak, planları gör, restore ve yönetim bulunur. Masal hakkı okuma yıldızıyla karıştırılmaz.
10. Eski kişisel kitaplar, kimlik, yıldız/rozet ve başlamış seri korunur. Yeni seri başlangıcı üyelik ister; mevcut seri günlük açılış kuralıyla tamamlanır. Okuyucunun üstüne veya gece kapanışında otomatik paywall açılmaz.

## Kapsam ve göç

İlk uygulama kişisel masal/yeni seri erişimini ve üç satış girişini kapsar. Klasik/Original kataloğunu ücretli seçkilere ayırmak ayrı editör kararıdır; bu tur bugünkü katalog erişimini daraltma. PDF, sesli okuma ve yaşa bağlı uzunluğu ücretli kilitleme.

Aile sesi/davet/paylaşım/e-posta, hazır sahneli kişisel kitap ve bulut görseller Release'te kapalı kalır; satış faydası olamaz. Canlı fiyat/ürün yayımlanmaz. Aktif eski aboneler varsa hakları ve ürün eşlemeleri korunur.

Yeni deneme defteri eski freeTrialCount ve yıldızdan bağımsızdır. Mevcut kurulumlar üç yeni hakla başlar; eski kitaplar geriye dönük düşülmez. Eski kullanıcıya ilk kurulum teklifi zorla gösterilmez. Doğrulanmış üye ücretsiz hak harcamaz.

Defter cihaz kurulumuna ait ticari kayıttır; çocuk adı, yaş veya metin içermez. Çıkış/profil silme hakkı yenilemez; hesap silmenin ticari kayıt davranışı veri açıklamasıyla birlikte doğrulanır. Yeni kurulum/başka cihaz sınırı açıkça belgelenir.

## Teknik tasarım

EntitlementService ve RevenueCat korunur. Yeni kişisel masal kararı ve küçük deneme defteri uygulama katmanındadır; StoryEngine'e ödeme kavramı girmez. Giriş kontrolü MPAppState.startStoryCreation, zorunlu servis kontrolü StoryGenerationManager.createStory içindedir. İlk masal da aynı servis kontrolünden geçer. Yeni seri SeriesManager.startSeries'te kontrol edilir.

İlk kurulum açıklaması ContentView'deki FirstRun sunumundan önce gelir; AppGate hesap/onay sırası ve storyBeforeAccount bayrağı değişmez. İlk kurulumda üyelik seçimi de requestGate üzerinden ilerler.

LibraryShelf.save bugün Void döner; yeni kişisel kaydın kalıcı başarısını bildiren dar bir ekleme API'si gerekir. Deneme rezervasyonu üretimden önce yazılır; masal UUID'si kayıttan önce bağlanır; kalıcı masal varsa tek hak commit edilir. Çökme sonrası pending UUID diskte varsa commit, yoksa release. Bozuk defter yeni hak dağıtmaz; kitaplık ve ebeveyn hata/restore yolu açık kalır.

Sunumlar sıralıdır: çocuk durumu → kapanış → kapı → kapanış → paywall → kapanış → seçim. Callback tek kullanımlık, iptalde temizlenir. Aynı anda ikinci modal açılmaz.

## Kabul koşulları

- İlk üç başarılı kişisel masal, ilk masal dahil, toplam üç hak tüketir; dördüncü giriş seçim öncesinde durur.
- Doğrudan servis ve yan girişler sınırı atlayamaz; write/compose hatası, çift callback ve eşzamanlı istek fazla tüketmez.
- Satın alma/restore teknik başarısı etkin üyelik olmadan erişim sağlamaz; pending/cancel/failure ayrılır.
- Başarılı işlem tek kez seçim akışına döner; kapatma yeni masal başlatmaz.
- Eski kitaplar ve başlamış seri erişilebilir; yeni seri başlangıcı ücretli kontrol ister.
- Çocuk ekranında satış, kapalı özellik vaadi, yapay fiyat ve yıldız satışı yok.
- İlk kurulum/geri dönen hesap/restore akışları çakışmaz; yeni profil ve çıkış hak yenilemez.
- Test/simülatör uygulama sonunda bir toplu turda; eksik canlı ödeme kanıtı dürüst kaydedilir.

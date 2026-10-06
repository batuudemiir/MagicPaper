# Gizlilik Politikası - MagicPaper

**Son Güncelleme**: 6 Ekim 2026
**Versiyon**: 2.0

> Hukuki gözden geçirme bekliyor. Bu sürüm, uygulamanın Ekim 2026'daki gerçek davranışını anlatmak için
> FAZ 16'da yeniden yazıldı (ebeveyn hesabı, senkron, anonim okuma bilgisi, uzaktan içerik). Yayından önce
> KVKK danışmanı tarafından onaylanmalı; Firestore bölgesi ve yurt dışı aktarım bölümü buna bağlı.

## Giriş

MagicPaper ("biz", "uygulama"), çocuklar için kişiselleştirilmiş masallar yazan bir uygulamadır. Uygulamayı
ebeveyn kurar ve yönetir; hesap ebeveynindir, çocuk giriş yapmaz. Bu politika hangi bilgilerin nerede
saklandığını, neden saklandığını ve nasıl silineceğini anlatır.

Masal metinleri cihazda, internet bağlantısı olmadan yazılır. Masal yazmak için çocuğa ait hiçbir bilgi bir
yapay zekâ servisine gönderilmez.

## Toplanan Bilgiler

### 1. Ebeveyn hesabı

Uygulama, ebeveynin Apple ile Giriş Yap ya da Google ile giriş yapmasını ister.

- **Saklanan**: Firebase Authentication'ın verdiği hesap kimliği ve giriş yöntemi (Apple ya da Google).
- **Saklanmayan**: Apple ile girişte ad ve e-posta istenmez. Google ile girişte Google'ın döndürdüğü ad ve
  e-posta MagicPaper tarafından saklanmaz; giriş hizmetini veren Google/Firebase kendi kayıtlarını tutar.

### 2. Ebeveynin girdiği çocuk bilgileri

- Çocuğun adı ve yaşı
- Sevdiği şeyler (ilgi alanları, hazır bir listeden)
- Kitap karakteri seçimleri (hazır parçalardan; fotoğraf değil)
- Masal ailem: ebeveynin eklediği karakter adları ve ilişki türü (kardeş, arkadaş, hayvan, hayali varlık)

**Toplanmayanlar**: Çocuk fotoğrafı hiçbir yere gönderilmez. Ses kaydı yapılmaz. Cinsiyet sorulmaz.

### 3. Uygulamanın ürettiği bilgiler

- Yazılan masallar (metin, başlık, hangi içerikten yazıldığı)
- Seriler ve hangi bölümün açıldığı
- Okuma ilerlemesi (bir masalın hangi sayfasında kalındığı, en son ne zaman okunduğu)

### 4. Anonim okuma bilgisi (isteğe bağlı)

Ebeveyn "Okuma bilgisini paylaş" seçeneğini açık bırakırsa, her okumadan sonra şu bilgi gönderilir:
masalın modu, hangi hazır içerikten yazıldığı (içerik kimlikleri), yol arkadaşının türü, Masal ailem
karakterinin yalnızca ilişki türü, yaş bandı (örn. "5-6"), ulaşılan sayfa ve sayfa sayısı, bitirilip
bitirilmediği, tekrar okunup okunmadığı ve gün (saat yok).

- **İçinde olmayanlar**: Çocuğun adı, tam yaşı, Masal ailem adları, hesap kimliği, cihaz kimliği, masal
  metni, masalın kendi kimliği, okuma saati.
- Bu bilgi ebeveyn hesabına bağlanmaz; sunucuda hesap kimliği olmadan, okunamaz biçimde saklanır.
- Yalnızca ebeveyn onay metnini gördükten sonraki okumalar gönderilir. Onaydan önce cihazda biriken
  okumalar silinir, gönderilmez.
- Ayarlar > Gizlilik ve veri'den istenildiği an kapatılabilir; kapatınca gönderilmeyi bekleyenler silinir.
- Amaç: hangi masal yapılarının bitirildiğini ve tekrar okunduğunu görerek masalları iyileştirmek.

### 5. Otomatik bilgiler

- Uygulama Firebase Analytics, reklam kimliği (IDFA) ya da çökme raporlama (Crashlytics) **kullanmaz**.
- Uygulama, günün masalını ve içerik paketlerini Firebase Hosting'den indirir. Bu isteklerde hesap ya da
  çocuk bilgisi yoktur; isteğin geldiği IP adresi barındırma hizmetini veren Google'a görünür.

## Bilgilerin Kullanımı

- Masalları çocuğa göre yazmak (ad, yaş bandı, sevdiği şeyler, Masal ailem)
- Kütüphaneyi, serileri ve okuma ilerlemesini saklamak; telefon değişse de kaybolmamasını sağlamak
- Sıradaki masalı seçerken çocuğun kendi okuma geçmişini kullanmak (bu kayıt cihazdan çıkmaz)
- Anonim okuma bilgisiyle masal içeriğini iyileştirmek (yalnızca açıksa)

Bilgiler reklam, profil çıkarma ya da pazarlama için kullanılmaz ve satılmaz.

## Veri Saklama

### Cihazda
Profiller, masallar, seriler, okuma ilerlemesi ve tercihler cihazda, iOS dosya korumasıyla saklanır.
Çocuğun okuma geçmişinden öğrenilen tercihler yalnızca cihazdadır.

### Ebeveyn hesabında (Google Firebase Firestore)
Çocuk profilleri (fotoğrafsız), kitap karakteri seçimleri, Masal ailem, masallar, seriler, okuma ilerlemesi
ve ebeveyn onayı kaydı (onay metninin sürümü ve tarihi). Bu belgeler yalnızca o ebeveynin hesabıyla
okunup yazılabilir; güvenlik kuralları başka hiçbir hesabın erişimine izin vermez.

Silinen bir masal ya da profil sunucuda içeriği olmayan bir iz olarak kalır (diğer cihazların da silmesi
için); izde ad ya da metin bulunmaz.

### Saklama süresi
- Ebeveyn hesabındaki bilgiler, ebeveyn hesabı silinene kadar saklanır.
- Anonim okuma bilgisi kimseye bağlanmadığı için tek tek silinemez. Saklama süresi yayından önce
  belirlenecek *(karar bekliyor; Firestore TTL ile uygulanabilir)*.

## Hesabı ve Verileri Silme

Ayarlar > Gizlilik ve veri > **Hesabı sil**:
1. Ebeveynden bir kez daha giriş yapması istenir (Apple ile girişte Apple bağlantısı da iptal edilir).
2. Hesaptaki bütün belgeler (profiller, masallar, seriler, ilerleme, onay kaydı) sunucudan silinir.
3. Giriş hesabı silinir.
4. Cihazdaki bütün aile verisi silinir.

**Çıkış yap** ise yalnızca bu cihazdaki verileri kaldırır; hesaptaki bilgiler kalır ve tekrar giriş
yapınca geri gelir.

## Çocukların Gizliliği

- Uygulama Apple'ın Çocuklar kategorisi kurallarına göre tasarlanmıştır: reklam yok, üçüncü taraf analitik
  yok, uygulama dışına bağlantılar ve satın alma ebeveyn kapısının arkasında.
- Çocuk verileri ebeveynin açık rızasıyla işlenir (KVKK). Rıza, uygulama içinde onay metniyle alınır ve
  sürümü ile tarihi hesaba kaydedilir. Metin değişirse rıza yeniden istenir.
- Ebeveyn rızasını istediği zaman hesabı silerek geri alabilir.

## Üçüncü Taraf Servisleri

| Servis | Ne için | Ne gider |
|---|---|---|
| Firebase Authentication (Google) | Ebeveyn girişi | Apple/Google giriş belirteci |
| Cloud Firestore (Google) | Ebeveyn hesabındaki veriler, anonim okuma bilgisi | Yukarıda "Ebeveyn hesabında" ve "Anonim okuma bilgisi" |
| Firebase Hosting (Google) | Günün masalı ve içerik paketleri | Kişisel bilgi yok (IP adresi) |
| Apple ile Giriş Yap / Google ile giriş | Kimlik doğrulama | Apple/Google'ın kendi giriş akışı |
| Apple App Store / RevenueCat | Abonelik | Ödeme bilgilerini görmeyiz |

Görselli masal (bulut illüstrasyon) özelliği bu sürümde kapalıdır; açıldığında bu politika önceden
güncellenecektir.

## Uluslararası Veri Aktarımı

Firebase sunucuları Türkiye dışında olabilir. Ebeveyn onay metni bu aktarımı açıkça belirtir. Aktarım
TLS ile şifrelidir; Google ile standart sözleşme maddeleri uygulanır.
*(Hukuki not: Firestore bölgesine göre KVKK m.9 kapsamında standart sözleşme ve Kurul bildirimi
gerekebilir — yayından önce netleştirilecek.)*

## Kullanıcı Hakları (KVKK m.11, GDPR)

Bilgilerinize erişme, düzeltme, silinmesini isteme, işlemeye itiraz etme ve rızayı geri alma haklarınız
vardır. Profil bilgileri uygulama içinden düzenlenebilir; hesap uygulama içinden silinebilir. Diğer
talepler için aşağıdaki adrese yazabilirsiniz; talepler en geç 30 gün içinde yanıtlanır.

## Gizlilik Politikası Değişiklikleri

Önemli değişikliklerde uygulama içi onay metni de güncellenir ve ebeveynden yeniden onay istenir.
"Son Güncelleme" tarihi her zaman günceldir.

## İletişim

**E-posta**: support@magicpaperkids.com
**Web**: https://www.magicpaperkids.com/gizlilik

**Veri Sorumlusu**: MagicPaper, İstanbul, Türkiye — [adres bilgisi eklenecek]

---

**Son Güncelleme**: 6 Ekim 2026
**Versiyon**: 2.0

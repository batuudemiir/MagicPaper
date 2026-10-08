# Ebeveyn hesabı ve senkron (FAZ 16)

Durum: 6 Ekim 2026, dal `faz-16`. Plan: `MagicPaper_Faz_Plani_Ekim.md` FAZ 16.

## Akış

Karşılama → **Giriş** → **Ebeveyn onayı** → Profil → Neleri sever → İlk masal. Çocuk giriş yapmaz.

- Kurulu uygulamalar (2.0) güncellemeden sonraki ilk açılışta bir kez Giriş + Onay görür; cihazdaki
  profiller ve masallar hesaba yüklenir (karar: herkese zorunlu, 6 Ekim 2026).
- Çevrimdışıysa ve cihazda çocuk varsa "Şimdilik masallara dön" bu açılış için girişi erteler. Yeni bir
  cihazda erteleme yok (açılacak bir şey yok).
- Yeni cihazda giriş + onaydan sonra hesaptaki çocuklar gelene kadar "Masallarınız getiriliyor" görünür;
  bağlantı yoksa "Yeni profil oluştur" ile geçilebilir, hesaptakiler bağlantı gelince eklenir.
- Giriş düğmeleri ebeveyn kapısının arkasında (Apple/Google kendi sayfasını açar; Çocuklar kategorisi).
- Kapı kararı tek yerde: `AppGate.resolve` (`StoryEngineBridge/Account/AccountModel.swift`).

## Kod

| Parça | Dosya |
|---|---|
| Hesap durumu, onay, çıkış, silme | `StoryEngineBridge/Account/AccountService.swift` |
| Firebase Auth: Apple (nonce, ad/e-posta istenmez), Google, emülatör hesabı | `FirebaseAccountAuth.swift` |
| Firestore: aile belgeleri, onay, okuma olayları; emülatör ayarı | `FirestoreFamilyRemote.swift` |
| Eşitleme kuralları (saf, test edilir) | `SyncModel.swift` (`SyncPlanner`, `SyncLedger`) |
| Eşitleme servisi (zamanlama, çevrimdışı) | `FamilySyncService.swift` |
| Cihaz tarafı: kayıtları toplama ve uygulama | `FamilyLocalStore.swift` |
| Onay metni (sürümlü) ve yerel kopyası | `ParentConsent.swift` |
| Okuma olaylarının gönderimi | `ReadingEventUploader.swift`, `ReadingEvent.swift` (`ReadingEventWire`) |
| Cihazdaki aile verisini silme (Tüm verileri sil / Çıkış / Hesabı sil) | `LocalDataEraser.swift` |
| Ekranlar | `Screens/Account/` |
| Güvenlik kuralları ve testleri | `firebase/firestore.rules`, `firebase/tests/rules.test.mjs` |

## Sunucudaki biçim

`families/{uid}/{koleksiyon}/{kimlik}` — koleksiyonlar: `children` (UserProfile, fotoğrafsız),
`avatars` (AvatarSpec), `family` (çocuğun Masal ailem listesi), `stories` (Story, ilerlemesiz),
`progress` (`lastReadPage`, `lastReadAt`), `series` (çocuğun serileri), `badges` (rozet defteri, FAZ 17),
`recordings` (ailenin sesiyle kaydedilen sayfalar, FAZ 18; ses dosyası Storage'da).

**FAZ 18:** `{uid}` artık ailenin kimliği (`familyID`, kurucunun uid'i). Davetle katılan yetişkinler aynı
aileyi eşitler; sadece okuma rolü yalnızca çeker. Üyelik, davet, paylaşım, ses ve haftalık özet:
`docs/FAMILY_FEATURES.md`.

Belge alanları: `payload` (modelin JSON'u; silinmişse yok), `deleted`, `updatedAt` (yazanın saati, ms),
`serverUpdatedAt` (sunucu saati; çekme işareti), `schemaVersion`.

`families/{uid}/consents/{sürüm}`: `version`, `acceptedAt` (sunucu saati), `clientAcceptedAt`,
`shareUsageData`. Sürüm başına bir kez yazılır.

`readingEvents/{otomatik}`: `ReadingEventWire` alanları. Hesap kimliği ve `storyID` yok (karar). Yalnızca
eklenir; okunamaz, değiştirilemez.

## Eşitleme kuralları

- Çevrimdışı önce: uygulama hep cihazı okur/yazar; eşitleme arkadan gelir. Girişte, öne gelişte ve yerel
  değişiklikten ~2 sn sonra çalışır. Firestore disk önbelleği kapalı (cihazın kendi depoları önbellek).
- Defter (`Documents/StoryEngine/Sync/ledger.json`): her kayıt için son anlaşılan özet. Cihazda olmayan ama
  defterde olan kayıt = yerelde silinmiş → iz gönderilir.
- Çakışma: son yazan kazanır (kaydın kendi zamanı varsa o — okuma ilerlemesi `lastReadAt` — yoksa
  değişikliğin ilk görüldüğü an; çevrimdışı bekleyen değişiklik zamanını korur).
- Masal metni değişmez: `stories` yalnızca var/yok olarak eşitlenir; kurallar da metni değiştiren
  güncellemeyi reddeder. Silinen masal geri yazılamaz.
- Silme iz olarak taşınır; izde içerik yok.
- Eşitlenmeyenler: örnek masallar (her cihaz kendi kopyasını kurar), yazılmakta/başarısız masallar,
  profil fotoğrafı, çocuğun yerel okuma kaydı (`StoryUsageStore`), okuma serisi defterleri (`MPStreak`),
  favoriler ve onay listesi, cihaz tercihleri.

## Hesap silme

Ayarlar > Gizlilik ve veri > Hesabı sil: yeniden giriş (Apple'da token iptali) → `families/{uid}` altındaki
her belge ve onaylar → Firebase kullanıcısı → `LocalDataEraser` (onboarding dahil). Sunucu silme
başarısız olursa hiçbir şey silinmez, tekrar denenebilir. Anonim okuma olayları hesaba bağlı olmadığı
için silinmez (politikada yazıyor).

Giriş yapılmışken "Tüm verileri sil" gösterilmez: yalnız cihazı silmek bir sonraki eşitlemede geri
gelirdi; gerçek silme hesabınki. Çıkış yap: önce eşitler; hesaba gitmemiş değişiklik varsa reddeder.

## Batuhan'ın yapacakları (ajan yapmadı)

1. **Firestore'u oluştur** (Firebase Console > Firestore > Create database, production mode). **Bölge
   seçimi KVKK kararıdır**: yurt dışı bölge KVKK m.9 kapsamında standart sözleşme + Kurul bildirimi
   gerektirir (hukuki not, plan §7). Bölge sonradan değiştirilemez.
2. **Kuralları yayımla**: `cd firebase && firebase deploy --only firestore:rules,firestore:indexes`
   (önce `firebase login`).
3. **Apple ile giriş**: Apple Developer'da App ID'ye "Sign in with Apple" yeteneği; Firebase Console >
   Authentication > Apple'ı aç. Hesap silmede token iptali için Apple sağlayıcısına Team ID, Key ID ve
   Sign in with Apple anahtarı (.p8) girilmeli.
4. **Google ile giriş**: Firebase Console > Authentication > Google'ı aç, `GoogleService-Info.plist`'i
   yeniden indir (artık `CLIENT_ID` ve `REVERSED_CLIENT_ID` içerir), `Secrets.xcconfig`'e
   `GOOGLE_REVERSED_CLIENT_ID = com.googleusercontent.apps.…` ekle. Bugünkü plist'te `CLIENT_ID` yok;
   bu yüzden Google düğmesi gizli.
5. **App Store Connect gizlilik etiketi** (aşağıda) ve gizlilik politikasının yayımlanması
   (`PRIVACY_POLICY.md`, `privacy_policy.html`; hukuki onaydan sonra).
6. Okuma olaylarının saklama süresi kararı (Firestore TTL ile uygulanabilir).

## App Store gizlilik etiketi (öneri)

Takip (tracking): **yok**. Veriler:

| Apple kategorisi | Ne | Kullanıcıya bağlı | Amaç |
|---|---|---|---|
| Kimlikler › Kullanıcı kimliği | Firebase hesap kimliği | Evet | Uygulama işlevi |
| İletişim bilgileri › Ad | Çocuğun adı, Masal ailem adları | Evet | Uygulama işlevi |
| Kullanıcı içeriği › Diğer | Masallar, seriler, ilgi alanları, kitap karakteri | Evet | Uygulama işlevi |
| Kullanım verileri › Ürün etkileşimi | Okuma ilerlemesi (hesapta) | Evet | Uygulama işlevi |
| Kullanım verileri › Ürün etkileşimi | Anonim okuma olayları (isteğe bağlı) | Hayır | Analiz |
| Kullanıcı içeriği › Ses verileri | Ebeveynin masal kaydı (Kendi sesin, isteğe bağlı, FAZ 18) | Evet | Uygulama işlevi |
| İletişim bilgileri › E-posta adresi | Haftalık özet (isteğe bağlı, FAZ 18) | Evet | Uygulama işlevi |

Toplanmayan: fotoğraf, konum, çocuğun sesi, reklam kimliği, çökme verisi. FAZ 18 bayrakları açılmadan
önce ses ve e-posta satırları etikete eklenmelidir.

## Emülatörle deneme (geliştirici)

```
cd firebase && npm install            # bir kez
JAVA_HOME=<jdk> npm test              # kurallar testi
JAVA_HOME=<jdk> firebase emulators:start --only auth,firestore --project demo-magicpaper
```

Uygulamayı DEBUG'da `-MPFirebaseEmulator 127.0.0.1 -MPEmulatorAccount <ad>` argümanlarıyla aç; Giriş
ekranında "Test hesabıyla gir (emülatör)" düğmesi çıkar (Release'te hiçbir zaman). İki simülatör aynı
`MPEmulatorAccount` ile aynı hesaba girer.

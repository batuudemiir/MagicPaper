# Aile özellikleri (FAZ 18)

8 Ekim 2026, dal `faz-18`. Plan: `docs/MagicPaper_Faz_Plani_Ekim.md` › FAZ 18.
Hesap ve senkronun temeli: `docs/ACCOUNT_SYNC.md` (FAZ 16).

Beş özellik: **Masal kitabı** (35), **Aile üyeleri** (34), **Kendi sesin** (33),
**Aileyle paylaş** (36), **Haftalık özet e-postası**. Masal kitabı sunucu istemez ve
herkese açıktır. Diğer dördü `FamilyFeatureAccess` bayrağının arkasındadır: Release'te
kapalı, DEBUG'da Ayarlar > Geliştirici'den açılır. Bayraklar aşağıdaki Batuhan adımları
bitmeden ve gizlilik politikası 2.1 onaylanmadan açılmaz.

## Kararlar (Batuhan, 7-8 Ekim)

| Konu | Karar |
|---|---|
| Kapsam | Beş madde bu turda |
| Haftalık özet adresi | Giriş hesabının doğrulanmış e-postası. Apple girişi artık `.email` kapsamı ister |
| E-posta sağlayıcısı | Resend |
| Tasarım ile plan çelişkisi | Tasarım geçerli: paylaşımda "Sesli okuma dahil" var, Masal kitabında "Basılı kitap" sekmesi görünür (fiyat ve sipariş yok, "yakında") |
| Paralel FAZ 18 işi (`faz-17-pastel`, dee81aa + b455829) | faz-18 sürümleri kalır; iPad açık kitap (27), onay notu ve KVKK ses taslağı birleşti |

Ajanın verdiği, onaya sunulan kararlar:

- **Tek yönetici, kurucu.** Davetle yalnızca *ebeveyn* ya da *sadece okuma* rolü verilir; yönetici devri yok.
- **Bir hesap tek ailede.** Davetle katılırken hesabın kendi ailesi (varsa) silinir; ekran bunu açıkça söyler.
- **Ses kaydı ayrı rıza.** Genel KVKK onayı yeniden sorulmaz; kaydeden her yetişkin ilk kaydından önce bir kez `voiceConsents/{uid}` verir. Geri çekmek o yetişkinin kayıtlarını siler.
- **Üye, ailenin onayıyla girer.** Davetle katılan yetişkine KVKK onayı sorulmaz; ailenin kurucusunun onayı geçerli (kurallar da üyenin onay yazmasına izin vermez).
- **Teslimden çıkarılanlar:** 34'teki "bu iPad ve iPhone" (cihaz bilgisi tutulmuyor), "Apple Aile Paylaşımı" kartı (abonelik ertelendi). 36'da "Sadece okuma" kapatılamaz bir bilgi satırı.
- **Gizlilik metni:** 33'teki "başka bir yerde paylaşılmaz" cümlesi sesli paylaşım yüzünden "sen sesli bir paylaşım bağlantısı oluşturmadıkça" oldu (İrem'e not).

## Veri modeli

```
families/{fid}                       fid = kurucunun uid'i
  members/{uid}                      {role: admin|parent|reader, displayName, joinedAt, invite?}
  voiceConsents/{uid}                {version: "voice-2026-10", acceptedAt, clientAcceptedAt}
  recordings/{storyID}               senkron kaydı (zarf), yük VoiceRecordingSet {pages, by}
  shares/{token}                     {recipient?, storyCount, voice, audio[], expiresAt, createdAt, createdBy}
  settings/weeklyEmail               {enabled, email, timezone, updatedAt}
memberships/{uid}                    {familyID, joinedAt}; yoksa kişi kendi ailesinin kurucusu
invites/{code}                       {familyID, role, inviterName, expiresAt (+7 gün), createdAt}
shares/{token}                       AÇIK: {familyID, childName, stories[{title, pages[], audio[]}], voice, expiresAt, createdAt}

Storage
families/{fid}/voice/{storyID}/{page}.m4a     ailenin üyeleri dinler, kurucu ve ebeveyn yazar
shares/{token}/{story}/{page}.m4a              sesli paylaşım kopyası, süre bitene kadar herkese (yalnız get)
```

Kurallar ve testleri: `firebase/firestore.rules`, `firebase/storage.rules`,
`firebase/tests/{rules,family,storage}.test.mjs` (50/50, `npm test`, Java gerekir).

## Uygulama

| Parça | Dosya |
|---|---|
| Ebeveyn alt sayfaları | `Screens/Parent/ParentRouteView.swift` (`MPParentRoute`) |
| 35 Masal kitabı | `Screens/Parent/BookExportView.swift`, `StoryEngineBridge/Family/BookExportSelection.swift`, `MPStoryPDF(bookTitle:)` |
| 34 Aile üyeleri | `Screens/Family/FamilyMembersView.swift` (davet, katıl), `Family/FamilyMembership.swift`, `Family/FirestoreFamilyDirectory.swift`; `AccountService.familyID/role/joinFamily/leaveFamily/refreshMembership` |
| Sadece okuma | `FamilySyncService.start(readOnly:)` çeker, göndermez; `AccountService.canWriteFamily` Yarat'ı, masal silmeyi, profil eklemeyi kapatır |
| 33 Kendi sesin | `Screens/Family/VoiceRecordingView.swift`, `Family/MPVoiceRecorder.swift` (+ `VoiceConsent`), `Family/VoiceRecordingStore.swift`, `Family/FirebaseVoiceRemote.swift` |
| Kim okusun? | `Screens/MPNarration.swift`, `MPSpeech.speak(_:recording:)`, `MPSettingsStore.familyVoice`, `ReaderSettingsSheet(hasFamilyVoice:)`, okuyucu ve Uyku modu |
| 36 Aileyle paylaş | `Screens/Family/ShareLinkView.swift`, `Family/FamilyShareLink.swift` (`ShareDocument`), `Family/FirebaseShareRemote.swift` |
| Web okuyucu | `hosting/public/s/index.html` (SDK yok, analitik yok, `noindex`, CSP `hosting/firebase.json`), davet sayfası `hosting/public/i/index.html` |
| Haftalık özet | `Family/WeeklyEmailSettings.swift`, Ayarlar anahtarı; `firebase/functions` (`weeklySummary`, `unsubscribe`, `cleanupShares`) |
| Davet bağlantısı | `magicpaper://invite/<kod>` (Info.plist), `MagicPaperApp.onOpenURL` → ebeveyn kapısı → Aile üyeleri |

Hesap silme (`FirestoreFamilyRemote.deleteEverything` + `FirestoreFamilyDirectory.dissolve`):
kurucuda ses klasörü, paylaşımlar ve kopyaları, ayarlar, ses rızaları, üyeler ve üyelikleri,
davetler, sonra FAZ 16'nın koleksiyonları. Üyede yalnızca kendi üyeliği.

## Batuhan'ın yapacakları

FAZ 16 listesine (`docs/ACCOUNT_SYNC.md`) ek olarak:

1. **Firebase Storage'ı aç** (bölge Firestore ile aynı; KVKK m.9 kararı). `firebase deploy --only storage`
   (`firebase/` içinden). Not: konsoldaki eski `child_uploads/` kuralı bu dosyayla kapanır (görselli masal bayrakta, kapalı).
2. **Kuralları yayımla:** `firebase deploy --only firestore:rules,storage`.
3. **Blaze planı** (Cloud Functions için) ve fonksiyonlar:
   - `cd firebase/functions && npm install`
   - `firebase functions:secrets:set RESEND_API_KEY` (Resend panelinden)
   - `firebase functions:secrets:set UNSUBSCRIBE_SECRET` (rastgele 32+ karakter)
   - `MAIL_FROM` parametresi (varsayılan `MagicPaper <ozet@magicpaperkids.com>`; alan adı Resend'de doğrulanmalı, SPF/DKIM)
   - `firebase deploy --only functions` (bölge `europe-west1`)
   - Firestore, `settings` koleksiyon grubu sorgusu için tek alanlı dizini kendiliğinden kurar; hata verirse konsoldaki bağlantıdan ekle.
4. **Hosting:** `cd hosting && firebase deploy --only hosting` (web okuyucu `/s/`, davet `/i/`, yazı tipi `/fonts/`).
   `content-publisher --deploy` de aynı klasörü yayımlar; dosyalar orada kalmalı.
5. **Apple:** Sign in with Apple'da e-posta kapsamı kullanılıyor; App Store gizlilik etiketine **e-posta** (Haftalık özet,
   isteğe bağlı) ve **ses** (Kendi sesin, isteğe bağlı) eklenecek. Mikrofon izni metni Info.plist'te.
6. **Hukuk:** gizlilik politikası 2.1 taslağı (`PRIVACY_POLICY.md`), ses rızası metni (`VoiceConsent.text`,
   `docs/KVKK_Onay_Taslagi_Ses_Kaydi.md`), Resend'in alt işleyen olarak anılması, yurt dışı aktarım.
   `privacy_policy.html` henüz 2.0; politika onaylanınca md'den yeniden üretilmeli.
7. **Bayrakları açma kararı** (Release'te): `FamilyFeatureAccess.isEnabled` bugün Release'te `false` döner.

## Doğrulama

- Uygulama testleri (iPhone 17 Pro): 631/0 (1 atlanan). Yeni: `BookExportSelectionTests`, `FamilyMembershipTests`,
  `VoiceRecordingStoreTests`, `ShareDocumentTests`, `WeeklyEmailTests`.
- Kurallar: `firebase/` içinde `npm test` 51/51 (Firestore 42 + Storage 9, emülatör).
- Fonksiyonlar: `firebase/functions` içinde `npm test` 9/9 (bağımlılık gerekmez; saf modüller).
- Emülatörde uçtan uca: `firebase emulators:start --only auth,firestore,storage --project magicpaper-393a7`,
  uygulama `-MPFirebaseEmulator 127.0.0.1 -MPEmulatorAccount <ad>` ile (Storage da 9199'a bağlanır).
  Web okuyucu yerelde: `hosting/` içinde `firebase serve`/`emulators:start --only hosting`, sonra
  `http://localhost:5000/s/<token>?project=magicpaper-393a7&bucket=<emülatör kovası>`.

## Gözden geçirme (reviewer ajanı, 8 Ekim)

CRITICAL yok. Düzeltilenler: davetle katılırken önce kabul, sonra eski aileyi silme (geçersiz davet hiçbir
şey sildirmez) ve kurucuya her zaman onay; ayrılan/silinen/çıkarılan üyenin ses kayıtları silinir;
haftalık özet koleksiyon grubu dizini (`firestore.indexes.json`); hesap silmede açık paylaşım belgesi
silinemezse hata; Storage'da ses yüklemesi sunucudaki ses rızasını ister, paylaşım okuması tek belge
okuması; sesli paylaşıma yalnızca paylaşanın kendi kayıtları girer; özet kapatılınca e-posta adresi
silinir; üretim CSP'sinden yerel adresler çıktı; kayıt başlatılamazsa ses oturumu kapanır.

## Açık kalanlar

- Açık paylaşım belgesi `familyID` (kurucunun hesap kimliği) taşır: kurallar ve Storage sahibi buradan bulur.
  Ad ve metin dışında görünen tek alan budur; tasarımın "yalnız ad ve metin" sözünden sapma (karar bekliyor:
  özel bir eşleme belgesiyle kaldırılabilir).
- Kurallar paylaşılan masalların `pages`/`audio` öğelerinin türünü tek tek denetleyemez (dizi döngüsü yok); alan adları denetleniyor.
- `weeklySummary` her ailenin bütün masal kayıtlarını okur; kullanıcı sayısı büyüyünce aile başına ayrı iş ya da özet alanı gerekir.
- App Check yok; paylaşım okumaları ve davet okumaları hız sınırsız.
- PDF ve paylaşım için geçici dosyalar `tmp`'de sistem temizleyene kadar durur.
- Firebase Functions Node 20 ile; yayın öncesi Node 22'ye geçirilebilir.

- Eski Apple girişlerinde e-posta yok (Apple yalnızca ilk girişte verir): bu hesaplarda Haftalık özet kapalı kalır ("Hesabında doğrulanmış e-posta yok").
- Sadece okuma rolündeki yetişkinin cihazındaki okuma ilerlemesi aileye gitmez (tasarım gereği); seri bölüm açılışı gibi yerel yazımlar da onun cihazında kalır.
- Rol değişikliği ya da aileden çıkarılma diğer cihazda bir sonraki öne gelişte/Aile üyeleri açılışında fark edilir (anlık dinleyici yok).
- Davet kabulü çevrimiçi ister; ses rızası da (sunucuya yazılmadan kayıt başlamaz).
- Yönetici devri ve birden çok yönetici yok.

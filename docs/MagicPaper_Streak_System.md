# MPStreak — Okuma Sürekliliği Sistemi

**Durum:** RETAINED — okuma sürekliliği mekanizması
**Tarih:** 2026-09-18
**Kapsam:** Mevcut uygulamanın denetimi ve belgelenmesi. Bu turda yeniden tasarım yapılmadı.

---

## 1. Ürün anlamı

`MPStreak` oyunlaştırma değildir. **Okuma sürekliliği ve ailece hikâye ritüelini**
temsil eder — uygulama bağımlılığını değil.

Bir gün sayılmalıdır çünkü **aile gerçekten birlikte bir hikâye okudu**, ebeveyn
uygulamayı açtığı için değil.

**Genişletilmemeli:** puan, rozet, liderlik tablosu, rekabetçi sıralama, ödül
ekonomisi, yapay etkileşim döngüsü.

**Dil kaydı.** Bugünkü kopya zaten doğru kayıtta ve öyle kalmalı:

| Doğru | Yanlış |
|---|---|
| "3 gün üst üste birlikte okudunuz." | "Serini bozma!" |
| "Bu hafta 4 hikâye tamamlandı." | "Hemen geri dön!" |
| "Okuma yolculuğunuz devam ediyor." | "Serini kaybetmek üzeresin!" |
| "Yarın yeni bir hikâyeye devam edebilirsiniz." | "Sadece 2 saat kaldı!" |

`HomeView:289-291` bugün şunu yazıyor: `"\(currentStreak) günlük seri"` /
`"Bugün henüz masal okunmadı"` — ikisi de baskısız. Koruyun.

---

## 2. Denetim — 10 soru

### 1. Streak durumu nerede saklanıyor?
İki `UserDefaults` anahtarı, **cihaz genelinde, profile bağlı değil**:

| Anahtar | Tip | İçerik |
|---|---|---|
| `mp_readDays` | `[String]` | `"yyyy-MM-dd"` okuma günleri; bellekte `Set<String>` |
| `mp_readSeconds` | `[String: Double]` | gün → o gün okunan saniye |

`MPStreak` bir `@MainActor final class ... ObservableObject`, `static let shared`
singleton. `readDays` `@Published private(set)`; `readSeconds` ise `UserDefaults`
üzerinde hesaplanan bir property (published değil).

### 2. Okuma günü nasıl hesaplanıyor?
Statik bir `DateFormatter`, `en_US_POSIX` yerel ayarı, `"yyyy-MM-dd"` biçimi.
**`timeZone` açıkça atanmamış** → cihazın yerel saat dilimi.

Hafta hesapları `Calendar(identifier: .gregorian)` + `firstWeekday = 2` (Pazartesi).
`currentStreak` ise `Calendar.current` kullanıyor — ikisi farklı takvim örneği ama
ikisi de sistem saat dilimine düşüyor.

### 3. Streak'i hangi olay artırıyor?
`markReadToday()`, tam **iki** çağrı yerinden:

| Yer | Tetikleyici |
|---|---|
| `StoryReaderView.swift:168` | `open()` — okuyucu açıldığında |
| `DailyStoriesView.swift:311` | `.onAppear` — günlük masal açıldığında |

### 4. Uygulamayı açmak tek başına artırıyor mu?
**Hayır.** `AppOpened` / `AppLaunched` bağlantısı yok. Bu doğru.

### 5. Sadece bir hikâyeyi açmak artırıyor mu?
**Evet.** `open()` içinde `markReadToday()` **ilk satır** — herhangi bir okuma
gerçekleşmeden önce çalışıyor. Koddaki yorum bunu bilinçli bir karar olarak
belgeliyor: *"sayfa ilerlemese bile açmak okumaktır"*.

**Bu, hedeflenen `StoryReadingSessionCompleted` anlamıyla arasındaki boşluktur.**

### 6. Anlamlı bir okuma oturumunu tamamlamak artırıyor mu?
**Hayır — tamamlama şart değil.** Oturum süresi ayrıca ölçülüyor
(`addReadingTime`, kapanışta ve arka plana geçişte) ama bu ölçüm streak'i
kapılamıyor. Süre yalnızca ebeveyn panelini ve günlük okuma bütçesini besliyor.

### 7. Saat dilimi / gün sınırı nasıl ele alınıyor?
- Saat dilimi hiçbir yerde açıkça sabitlenmemiş; her şey cihaz yerelinde.
- Seyahat hâlinde "bugün"ün tanımı kayabilir.
- `addReadingTime` bir oturumun **tamamını kapanış anındaki güne** yazıyor;
  gece yarısını aşan oturum bölünmüyor.

### 8. Kaçırılan günler nasıl ele alınıyor?
`currentStreak` geriye doğru yürüyor: bugün işaretli değilse dünden başlıyor,
dün de işaretli değilse **0** dönüyor. Yani bir gün kaçırmak seriyi sıfırlıyor.

`weekStates` `.done` / `.missed` / `.today` / `.upcoming` ayrımı yapıyor ve
koddaki gerekçe iyi: *"Çocuğa gelecek dört günü 'kaçırdın' diye göstermek,
alışkanlık kurmaya çalışan bir ekranın yapabileceği en ters şey."* Bu ayrım korunmalı.

### 9. Aynı gün tekrar okumalar idempotent mi?
**Evet**, `markReadToday()` için: `guard !readDays.contains(today) else { return }`.
`addReadingTime` ise kasıtlı olarak biriktirici — idempotent olmamalı, doğru.

### 10. Durum güvenli saklanıyor mu?
Kısmen. Bkz. §3.

---

## 3. Bulunan hatalar

### H1 — Sıfırlama `mp_readSeconds`'i bırakıyor ⚠️ gerçek hata
`SettingsView.swift:462` "tüm veriyi sil" akışı şu anahtarları temizliyor:
`stories`, `user_profiles`, `current_profile_id`, `mp_favoriteStoryIDs`,
`mp_readDays`, `mp_approvedStoryIDs`.

**`mp_readSeconds` listede yok.** Kullanıcı tüm verisini sildikten sonra okuma
süresi geçmişi cihazda kalıyor ve ebeveyn panelinde görünmeye devam ediyor.

*Düzeltme:* anahtarı listeye ekle. Tek satır.

### H2 — Cihaz genelinde, profile bağlı değil
Her iki anahtar da profil kimliği taşımıyor. Çok çocuklu ailede bir çocuğun okuması
diğerinin gününü de işaretliyor; ebeveyn panelindeki süre çocuklar arasında
paylaşılıyor. `ProfileManager:183-184` diğer profil verilerini
`mp_avatarColor_<UUID>` / `read_history_<UUID>` deseniyle profile bağlıyor — streak
bu desene uymuyor.

### H3 — Açmak = okumak
§2.5. Ürün niyeti `StoryReadingSessionCompleted`; bugünkü davranış `StoryOpened`.
Kod bunu belgeliyor, yani hata değil bilinçli bir karar — ama **niyetle uyuşmuyor**.

### H4 — Sınırsız büyüme
`mp_readDays` her okuma günü için bir satır ekliyor, hiç budanmıyor.
`mp_readSeconds` her gün için bir giriş ekliyor, hiç budanmıyor. Ayrıca
`addReadingTime` her çağrıda **tüm sözlüğü** okuyup geri yazıyor.

### H5 — `objectWillChange` değişimden sonra gönderiliyor
`addReadingTime:113` — `objectWillChange.send()` yazma tamamlandıktan **sonra**
çağrılıyor. `readSeconds` `@Published` olmadığı için bu bildirim gerekli, ama
sözleşme gereği değişimden **önce** gönderilmeli.

### H6 — Oturum gece yarısını aşarsa
Tüm süre kapanış gününe yazılıyor, bölünmüyor. Küçük ama günlük okuma bütçesini
etkileyebilir.

---

## 4. Bu turda yapılmayanlar

Kapsam gereği **hiçbir kod değiştirilmedi**:

- `markReadToday()` tetikleyicisi `StoryReadingSessionCompleted`'a taşınmadı (H3)
- H1 düzeltilmedi — `SettingsView.swift` ikinci dalgada parent-ux'in alanı
- Profil kapsamına alma yapılmadı (H2) — D4 persistence göçüyle birlikte ele alınmalı
- UI'a dokunulmadı

**Öncelik önerisi:** H1 (tek satır, gerçek hata) → H3 (ürün niyeti) →
H2 (D4 ile birlikte) → H4/H5/H6 (temizlik).

---

## 5. Gelecekteki agent'lar için

`MPStreak` **kasıtlıdır ve kalır.** Kaldırılması önerilmemeli, "oyunlaştırma borcu"
veya İlke 7 ihlali olarak raporlanmamalı.

`CLAUDE.md` İlke 7 bu doğrultuda güncellendi: sürekliliğe izin veriyor, puan/rozet/
liderlik tablosu/ödül ekonomisi/baskı dilini yasaklıyor.

Sahiplik: ikinci dalgada **parent-ux** (durum, tetikleyici, kopya) ve **reader**
(okuma süresi defteri, günlük bütçe, `ReaderTimeUpLeaf`). Okuma süresi tarafı
oyunlaştırma değil, **ebeveyn kontrolü** — ayrı değerlendirilmeli.

# App Store İnceleme Sorunu Çözümü - Guideline 3.1.2

## Sorun
Apple, otomatik yenilenen abonelikler için gerekli bilgilerin eksik olduğunu belirtti.

## Gerekli Düzeltmeler

### 1. ✅ Uygulamada Zaten Mevcut
SimpleSubscriptionView.swift dosyasında şunlar zaten var:
- ✅ Abonelik başlığı (Yıldız Kaşifi, Hikaye Kahramanı, Sihir Ustası)
- ✅ Abonelik süresi (Aylık - 30 gün)
- ✅ Fiyat (₺89/ay, ₺149/ay, ₺349/ay)
- ✅ Privacy Policy linki
- ✅ Terms of Use linki (şu anda Apple'ın standart EULA'sına gidiyor)
- ✅ Otomatik yenileme bilgisi
- ✅ İptal bilgisi

### 2. ❌ App Store Connect'te Eksik

**App Store Connect'te yapmanız gerekenler:**

#### A. App Description'a Eklenecek Metin

App Description'ın sonuna şu metni ekleyin:

```
📋 ABONELİK BİLGİLERİ

MagicPaper, otomatik yenilenen aylık abonelik paketleri sunar:

⭐ Yıldız Kaşifi: ₺89/ay (30 gün)
- 1 görselli hikaye/ay
- Sınırsız metin ve günlük hikaye

👑 Hikaye Kahramanı: ₺149/ay (30 gün)
- 5 görselli hikaye/ay
- Sınırsız metin ve günlük hikaye

🌟 Sihir Ustası: ₺349/ay (30 gün)
- 10 görselli hikaye/ay
- Sınırsız metin ve günlük hikaye

• Ödeme, satın alma onayında iTunes hesabınızdan çekilir
• Abonelik, mevcut dönem bitmeden en az 24 saat önce iptal edilmediği sürece otomatik olarak yenilenir
• Hesabınız, mevcut dönemin bitiminden önceki 24 saat içinde yenileme için ücretlendirilir
• Abonelikler kullanıcı tarafından yönetilebilir ve otomatik yenileme, satın alma sonrasında kullanıcının Hesap Ayarları'na gidilerek kapatılabilir
• Ücretsiz deneme süresinin kullanılmayan kısmı, varsa, kullanıcı o yayının aboneliğini satın aldığında kaybedilir

Kullanım Şartları: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Gizlilik Politikası: https://www.magicpaperkids.com/gizlilik
```

#### B. VEYA Özel EULA Kullanın

Eğer kendi Terms of Service'inizi kullanmak isterseniz:

1. TERMS_OF_SERVICE.md dosyasını web sitenizde yayınlayın:
   - URL: https://www.magicpaperkids.com/kullanim-sartlari
   
2. App Store Connect'te:
   - "App Information" bölümüne gidin
   - "License Agreement" alanında "Custom" seçin
   - TERMS_OF_SERVICE.md içeriğini yapıştırın

3. App Description'da bu linki kullanın:
   ```
   Kullanım Şartları: https://www.magicpaperkids.com/kullanim-sartlari
   Gizlilik Politikası: https://www.magicpaperkids.com/gizlilik
   ```

### 3. Uygulamada İyileştirme (Opsiyonel ama Önerilen)

SimpleSubscriptionView.swift'teki Terms of Use linkini güncelleyin:

```swift
// Şu anki kod (satır ~890):
if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {

// Önerilen değişiklik:
if let url = URL(string: "https://www.magicpaperkids.com/kullanim-sartlari") {
```

## Adım Adım Çözüm

### Hızlı Çözüm (Apple'ın Standart EULA'sı ile)
1. App Store Connect'e giriş yapın
2. Uygulamanızı seçin
3. "App Information" > "App Description" bölümüne gidin
4. Yukarıdaki "ABONELİK BİLGİLERİ" metnini description'ın sonuna ekleyin
5. "Save" butonuna tıklayın
6. Yeni bir versiyon gönderin veya mevcut incelemeye yanıt verin

### Tam Çözüm (Özel EULA ile)
1. TERMS_OF_SERVICE.md ve PRIVACY_POLICY.md dosyalarını web sitenizde yayınlayın
2. App Store Connect'te "License Agreement" alanını özel EULA ile güncelleyin
3. App Description'ı yukarıdaki metinle güncelleyin (kendi URL'lerinizle)
4. Uygulamadaki linki güncelleyin (opsiyonel)
5. Yeni bir versiyon gönderin veya mevcut incelemeye yanıt verin

## Apple'a Yanıt Mesajı

Resolution Center'da şu mesajı gönderin:

```
Hello App Review Team,

Thank you for your feedback regarding Guideline 3.1.2.

We have updated our App Description to include all required subscription information:
- Title of auto-renewing subscriptions
- Length of subscriptions (30 days/monthly)
- Price of subscriptions (₺89/month, ₺149/month, ₺349/month)
- Functional links to Terms of Use (EULA) and Privacy Policy

The app itself already displays all this information in the subscription view, including:
- Subscription details and pricing
- Auto-renewal information
- Cancellation instructions
- Links to Terms of Use and Privacy Policy

Please review the updated App Description and the in-app subscription screen.

Thank you for your time.
Best regards,
MagicPaper Team
```

## Kontrol Listesi

- [ ] App Description'a abonelik bilgileri eklendi
- [ ] Terms of Use linki eklendi (Apple EULA veya özel)
- [ ] Privacy Policy linki eklendi
- [ ] Tüm abonelik paketleri listelendi
- [ ] Fiyatlar ve süreler belirtildi
- [ ] Otomatik yenileme bilgisi eklendi
- [ ] İptal talimatları eklendi
- [ ] Apple'a yanıt mesajı gönderildi

## Notlar

- Uygulamanın kendisinde zaten tüm gerekli bilgiler mevcut
- Sorun sadece App Store Connect metadata'sında
- Kod değişikliği gerekmeyebilir (sadece App Store Connect güncellemesi yeterli)
- Ancak özel EULA kullanmak isterseniz, web sitesinde yayınlamanız gerekir

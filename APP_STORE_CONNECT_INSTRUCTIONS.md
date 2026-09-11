# App Store Connect Güncelleme Talimatları

## 🎯 Sorun
Apple Guideline 3.1.2 - Otomatik yenilenen abonelikler için gerekli bilgiler App Store metadata'sında eksik.

## ✅ Yapılan Kod Değişiklikleri

1. **SimpleSubscriptionView.swift** güncellendi:
   - Terms of Use linki özel URL'ye yönlendirildi
   - Privacy Policy linki mevcut
   - Localization desteği eklendi
   - Apple Guideline 3.1.2 uyumluluğu sağlandı

2. **Localization.swift** güncellendi:
   - `termsOfUse`: "Kullanım Şartları" / "Terms of Use"
   - `privacyPolicy`: "Gizlilik Politikası" / "Privacy Policy"
   - `termsAndPrivacy`: "Şartlar ve Gizlilik" / "Terms & Privacy"

## 📝 App Store Connect'te Yapılacaklar

### Adım 1: App Description Güncelleme

App Store Connect'e giriş yapın ve uygulamanızın **App Description** alanına aşağıdaki metni ekleyin:

```
📋 ABONELİK BİLGİLERİ

MagicPaper, otomatik yenilenen aylık abonelik paketleri sunar:

⭐ Yıldız Kaşifi: ₺89/ay (30 gün)
• 1 görselli hikaye/ay
• Sınırsız metin ve günlük hikaye

👑 Hikaye Kahramanı: ₺149/ay (30 gün)
• 5 görselli hikaye/ay
• Sınırsız metin ve günlük hikaye

🌟 Sihir Ustası: ₺349/ay (30 gün)
• 10 görselli hikaye/ay
• Sınırsız metin ve günlük hikaye

• Ödeme, satın alma onayında iTunes hesabınızdan çekilir
• Abonelik, mevcut dönem bitmeden en az 24 saat önce iptal edilmediği sürece otomatik olarak yenilenir
• Hesabınız, mevcut dönemin bitiminden önceki 24 saat içinde yenileme için ücretlendirilir
• Abonelikler kullanıcı tarafından yönetilebilir ve otomatik yenileme, satın alma sonrasında kullanıcının Hesap Ayarları'na gidilerek kapatılabilir
• Ücretsiz deneme süresinin kullanılmayan kısmı, varsa, kullanıcı o yayının aboneliğini satın aldığında kaybedilir

Kullanım Şartları: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Gizlilik Politikası: https://www.magicpaperkids.com/gizlilik
```

**İngilizce versiyon:**

```
📋 SUBSCRIPTION INFORMATION

MagicPaper offers auto-renewable monthly subscription packages:

⭐ Star Explorer: ₺89/month (30 days)
• 1 illustrated story/month
• Unlimited text and daily stories

👑 Story Hero: ₺149/month (30 days)
• 5 illustrated stories/month
• Unlimited text and daily stories

🌟 Magic Master: ₺349/month (30 days)
• 10 illustrated stories/month
• Unlimited text and daily stories

• Payment will be charged to iTunes Account at confirmation of purchase
• Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period
• Account will be charged for renewal within 24-hours prior to the end of the current period
• Subscriptions may be managed by the user and auto-renewal may be turned off by going to the user's Account Settings after purchase
• Any unused portion of a free trial period, if offered, will be forfeited when the user purchases a subscription to that publication

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://www.magicpaperkids.com/gizlilik
```

### Adım 2: Privacy Policy URL Kontrolü

**App Information** > **Privacy Policy URL** alanında şu URL'nin olduğundan emin olun:
```
https://www.magicpaperkids.com/gizlilik
```

### Adım 3: Apple'a Yanıt Mesajı

Resolution Center'da şu mesajı gönderin:

```
Hello App Review Team,

Thank you for your feedback regarding Guideline 3.1.2.

We have updated our App Description to include all required subscription information:
✓ Title of auto-renewing subscriptions (Star Explorer, Story Hero, Magic Master)
✓ Length of subscriptions (30 days/monthly for all packages)
✓ Price of subscriptions (₺89/month, ₺149/month, ₺349/month)
✓ Functional links to Terms of Use (EULA) and Privacy Policy

The app itself already displays all this information in the subscription view (SimpleSubscriptionView.swift), including:
✓ Detailed subscription package information
✓ Auto-renewal information
✓ Cancellation instructions
✓ Clickable links to Terms of Use and Privacy Policy

All subscription information is now available both in the app and in the App Store metadata.

Please review the updated App Description and the in-app subscription screen.

Thank you for your time and consideration.

Best regards,
MagicPaper Team
```

## 🌐 Opsiyonel: Özel EULA Kullanımı

Eğer Apple'ın standart EULA'sı yerine kendi Terms of Service'inizi kullanmak isterseniz:

### 1. Web Sitesinde Yayınlama

TERMS_OF_SERVICE.md dosyasını web sitenizde yayınlayın:
- URL: `https://www.magicpaperkids.com/kullanim-sartlari`
- İngilizce: `https://www.magicpaperkids.com/en/terms-of-use`

### 2. App Store Connect'te Güncelleme

**App Information** > **License Agreement**:
- "Custom" seçeneğini seçin
- TERMS_OF_SERVICE.md içeriğini yapıştırın

### 3. App Description'da URL Güncelleme

```
Kullanım Şartları: https://www.magicpaperkids.com/kullanim-sartlari
```

### 4. Uygulama Kodunda Güncelleme

SimpleSubscriptionView.swift dosyasında zaten hazır:
```swift
// Option 2 is already active in the code
if let url = URL(string: "https://www.magicpaperkids.com/kullanim-sartlari") {
    UIApplication.shared.open(url)
}
```

## ✅ Kontrol Listesi

Göndermeden önce kontrol edin:

- [ ] App Description'a abonelik bilgileri eklendi (Türkçe ve İngilizce)
- [ ] Terms of Use linki eklendi
- [ ] Privacy Policy linki eklendi
- [ ] Tüm abonelik paketleri listelendi (3 paket)
- [ ] Fiyatlar ve süreler belirtildi
- [ ] Otomatik yenileme bilgisi eklendi
- [ ] İptal talimatları eklendi
- [ ] Privacy Policy URL alanı dolduruldu
- [ ] Apple'a yanıt mesajı hazır
- [ ] Kod değişiklikleri commit edildi

## 📱 Uygulama İçi Kontrol

Uygulamada zaten mevcut olan özellikler:

✅ SimpleSubscriptionView'da:
- Abonelik paketleri detaylı gösteriliyor
- Fiyatlar ve süreler açık
- "Abonelik Bilgileri" bölümü var
- Terms of Use ve Privacy Policy linkleri çalışıyor
- Otomatik yenileme bilgisi gösteriliyor
- İptal talimatları mevcut

## 🚀 Sonraki Adımlar

1. App Store Connect'te yukarıdaki değişiklikleri yapın
2. Değişiklikleri kaydedin
3. Apple'a yanıt mesajını gönderin
4. Yeni bir build göndermeden mevcut build ile devam edebilirsiniz
5. Eğer kod değişikliklerini de göndermek isterseniz, yeni bir build yükleyin

## 📞 Destek

Sorularınız için:
- E-posta: destek@magicpaper.app
- Bu dosya: APP_STORE_SUBMISSION_FIX.md (detaylı açıklamalar)

---

**Not:** Kod değişiklikleri yapıldı ve commit edilmeye hazır. App Store Connect güncellemeleri manuel olarak yapılmalıdır.

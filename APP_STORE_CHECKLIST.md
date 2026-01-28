# App Store Yayınlama Checklist - MagicPaper

## ✅ Tamamlanması Gerekenler

### 1. Yasal Dokümanlar
- [x] Gizlilik Politikası hazırlandı (`PRIVACY_POLICY.md`)
- [x] Kullanım Şartları hazırlandı (`TERMS_OF_SERVICE.md`)
- [x] HTML versiyonları oluşturuldu
- [ ] Web sitesinde yayınlandı (https://magicpaper.app/gizlilik)
- [ ] Web sitesinde yayınlandı (https://magicpaper.app/kullanim-sartlari)

### 2. Uygulama Konfigürasyonu
- [x] Bundle ID: `com.batu.magicpaper.v1`
- [x] Version: 1.0
- [x] Build: 1
- [x] Deployment Target: iOS 15.0
- [x] App Icon: 1024x1024 (magiciconv2.png)

### 3. Info.plist İzinleri
- [ ] NSPhotoLibraryUsageDescription eklendi
- [ ] NSPhotoLibraryAddUsageDescription eklendi
- [ ] NSAppTransportSecurity yapılandırıldı

### 4. Ekran Görüntüleri
- [ ] 6.7" Display (iPhone 14 Pro Max) - 7 görsel
- [ ] 6.5" Display (iPhone 11 Pro Max) - 7 görsel
- [ ] 5.5" Display (iPhone 8 Plus) - 7 görsel
- [ ] iPad 12.9" (opsiyonel) - 7 görsel

**Gerekli Ekranlar:**
1. Ana Sayfa (Hero + Günün Hikayesi)
2. Hikaye Oluşturma (Fotoğraf seçimi)
3. Tema Seçimi
4. Hikaye Görüntüleme
5. Günlük Hikayeler
6. Kütüphane
7. Premium Ekranı

### 5. App Store Connect
- [ ] App oluşturuldu
- [ ] Uygulama bilgileri girildi (TR + EN)
- [ ] Açıklama yazıldı
- [ ] Anahtar kelimeler seçildi
- [ ] Kategori seçildi (Education + Entertainment)
- [ ] Yaş sınırı belirlendi (4+)

### 6. In-App Purchase
- [ ] Aylık abonelik oluşturuldu (`com.batu.magicpaper.premium.monthly`)
- [ ] Yıllık abonelik oluşturuldu (`com.batu.magicpaper.premium.yearly`)
- [ ] Abonelik grubu yapılandırıldı
- [ ] Fiyatlar belirlendi (₺69,99/ay, ₺599,99/yıl)
- [ ] Yerelleştirme yapıldı (TR + EN)

### 7. Gizlilik Bilgileri
- [ ] Veri toplama beyanı dolduruldu
- [ ] Toplanan veriler listelendi:
  - [x] İsim
  - [x] Fotoğraflar
  - [x] Cihaz ID
  - [x] Kullanım verileri
- [ ] Veri kullanım amaçları belirtildi
- [ ] Üçüncü taraf SDK'ları listelendi

### 8. Test ve Kalite
- [ ] Tüm özellikler test edildi
- [ ] Crash yok
- [ ] Memory leak yok
- [ ] UI/UX sorunsuz
- [ ] Performans iyi
- [ ] Farklı cihazlarda test edildi
- [ ] iOS 15, 16, 17 test edildi

### 9. Build ve Upload
- [ ] Clean build yapıldı
- [ ] Archive oluşturuldu
- [ ] Validate başarılı
- [ ] App Store Connect'e yüklendi
- [ ] Build seçildi

### 10. İnceleme Bilgileri
- [ ] İnceleme notları yazıldı
- [ ] Test talimatları eklendi
- [ ] İletişim bilgileri girildi
- [ ] Demo hesap bilgileri (gerekirse)

## 📋 Detaylı Kontrol Listesi

### Teknik Kontroller
```
✓ Uygulama çökmüyor
✓ Tüm butonlar çalışıyor
✓ Navigasyon sorunsuz
✓ Fotoğraf seçimi çalışıyor
✓ Hikaye oluşturma çalışıyor
✓ Premium satın alma çalışıyor
✓ Profil düzenleme çalışıyor
✓ Günlük hikayeler çalışıyor
✓ Kütüphane çalışıyor
✓ Ayarlar çalışıyor
```

### UI/UX Kontroller
```
✓ Gradient renkler doğru
✓ Fontlar okunabilir
✓ Spacing tutarlı
✓ Animasyonlar smooth
✓ Loading states var
✓ Error handling var
✓ Empty states var
✓ Dark mode (opsiyonel)
```

### İçerik Kontroller
```
✓ Türkçe metinler doğru
✓ İngilizce metinler doğru
✓ Emoji kullanımı uygun
✓ Görsel kalitesi yüksek
✓ Hikaye içerikleri uygun
✓ Yaş uygunluğu doğru
```

### Yasal Kontroller
```
✓ Gizlilik politikası hazır
✓ Kullanım şartları hazır
✓ KVKK uyumlu
✓ GDPR uyumlu
✓ COPPA uyumlu
✓ Telif hakları temiz
```

## 🚀 Yayınlama Adımları

### Adım 1: Web Sitesi Hazırlığı
1. Domain satın al (magicpaper.app)
2. Hosting ayarla
3. privacy_policy.html yükle → /gizlilik
4. terms_of_service.html yükle → /kullanim-sartlari
5. Basit landing page oluştur
6. SSL sertifikası aktif et

### Adım 2: Ekran Görüntüleri
1. Simulator'da ekran görüntüleri al
2. Gerekirse Figma'da düzenle
3. Tüm boyutları hazırla
4. App Store Connect'e yükle

### Adım 3: Info.plist Güncellemeleri
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Çocuğunuzun fotoğrafını seçmek için galeri erişimi gereklidir.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Oluşturulan hikayeleri kaydetmek için galeri erişimi gereklidir.</string>
```

### Adım 4: App Store Connect Kurulumu
1. developer.apple.com → App Store Connect
2. My Apps → + → New App
3. Platform: iOS
4. Name: MagicPaper
5. Primary Language: Turkish
6. Bundle ID: com.batu.magicpaper.v1
7. SKU: magicpaper-v1

### Adım 5: Uygulama Bilgileri
1. App Information → Tamamla
2. Pricing and Availability → Tamamla
3. App Privacy → Tamamla
4. Prepare for Submission → Tamamla

### Adım 6: Build Upload
```bash
# Xcode'da
1. Product → Clean Build Folder
2. Product → Archive
3. Organizer → Validate App
4. Organizer → Distribute App
5. App Store Connect → Upload
```

### Adım 7: Son Kontroller
1. Build seçildi mi?
2. Ekran görüntüleri yüklendi mi?
3. Açıklama yazıldı mı?
4. Gizlilik bilgileri dolduruldu mu?
5. İnceleme notları yazıldı mı?

### Adım 8: Submit for Review
1. Tüm bilgileri kontrol et
2. "Submit for Review" butonuna tıkla
3. Onay ver
4. Bekle (24-48 saat)

## 📞 Acil Durum İletişim

### Apple Developer Support
- Web: https://developer.apple.com/support/
- Telefon: +1 (408) 996-1010

### Yaygın Sorunlar ve Çözümler

**Problem**: Build yüklenmiyor
**Çözüm**: 
- Signing certificates kontrol et
- Provisioning profile yenile
- Clean build folder

**Problem**: Metadata rejected
**Çözüm**:
- Ekran görüntülerini kontrol et
- Açıklamayı gözden geçir
- Anahtar kelimeleri düzenle

**Problem**: Guideline 2.1 (Crash)
**Çözüm**:
- Crash logs kontrol et
- Test coverage artır
- Beta test yap

**Problem**: Guideline 5.1.1 (Privacy)
**Çözüm**:
- Gizlilik politikası linkini kontrol et
- Veri toplama beyanını güncelle
- Info.plist izinlerini kontrol et

## 📊 Beklenen Timeline

| Aşama | Süre | Durum |
|-------|------|-------|
| Web sitesi hazırlığı | 1-2 gün | ⏳ Bekliyor |
| Ekran görüntüleri | 1 gün | ⏳ Bekliyor |
| App Store Connect kurulum | 2-3 saat | ⏳ Bekliyor |
| Build upload | 1 saat | ⏳ Bekliyor |
| İlk inceleme | 24-48 saat | ⏳ Bekliyor |
| Revizyon (gerekirse) | 24 saat | - |
| **Toplam** | **3-5 gün** | - |

## ✨ Lansman Sonrası

### İlk 24 Saat
- [ ] App Store'da görünüyor mu kontrol et
- [ ] İndirme linki çalışıyor mu test et
- [ ] Sosyal medyada duyur
- [ ] Arkadaşlara/aileye haber ver

### İlk Hafta
- [ ] Kullanıcı yorumlarını takip et
- [ ] Crash reports kontrol et
- [ ] Analytics verilerini incele
- [ ] Feedback topla

### İlk Ay
- [ ] Kullanıcı geri bildirimlerine göre iyileştirmeler yap
- [ ] Bug fix güncellemesi hazırla
- [ ] Yeni özellikler planla
- [ ] Marketing stratejisi geliştir

## 🎯 Başarı Metrikleri

### Hedefler
- İlk hafta: 100+ indirme
- İlk ay: 1,000+ indirme
- Conversion rate: %15-25
- Retention rate: %40+
- Rating: 4.5+ yıldız

### Takip Edilecek Metrikler
- Günlük aktif kullanıcı (DAU)
- Aylık aktif kullanıcı (MAU)
- Premium conversion rate
- Churn rate
- Session duration
- Feature usage

---

**Hazır mısın? Hadi başlayalım! 🚀**

Bu checklist'i takip ederek MagicPaper'ı başarıyla App Store'da yayınlayabilirsin!

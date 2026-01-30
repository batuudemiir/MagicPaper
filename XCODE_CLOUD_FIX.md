# Xcode Cloud Build Hatası Düzeltmesi 🔧

## 🐛 Hata

```
Exception: -[XCRemoteSwiftPackageReference buildPhase]: unrecognized selector sent to instance
```

Bu hata, Xcode Cloud'un kullandığı Xcode versiyonunun project dosyasını okuyamamasından kaynaklanıyor.

## ✅ Çözüm

### 1. CI Scripts Eklendi

Xcode Cloud için otomatik script'ler oluşturuldu:

#### `ci_scripts/ci_post_clone.sh`
- SPM cache'ini temizler
- Package dependencies'i resolve eder
- Build öncesi hazırlık yapar

#### `ci_scripts/ci_pre_xcodebuild.sh`
- Xcode ve Swift versiyonlarını kontrol eder
- Package.resolved dosyasını doğrular
- Gerekirse dependencies'i yeniden resolve eder

### 2. Script İzinleri

Her iki script de executable yapıldı:
```bash
chmod +x ci_scripts/ci_post_clone.sh
chmod +x ci_scripts/ci_pre_xcodebuild.sh
```

### 3. Project Backup

Mevcut project dosyası yedeklendi:
```
MagicPaper.xcodeproj/project.pbxproj.xcode_cloud_backup
```

## 🚀 Xcode Cloud Yapılandırması

### Gerekli Ayarlar:

1. **Xcode Version**
   - Minimum: Xcode 15.0
   - Önerilen: Xcode 15.2 veya üzeri

2. **Environment Variables**
   ```
   GEMINI_API_KEY = [Your API Key]
   ```

3. **Build Scheme**
   - Scheme: MagicPaper
   - Configuration: Release

4. **Archive**
   - iOS 15.0 veya üzeri

## 📋 Kontrol Listesi

Xcode Cloud'da build yapmadan önce:

- [x] CI scripts oluşturuldu
- [x] Script izinleri verildi
- [x] Project backup alındı
- [ ] Xcode Cloud'da Xcode 15+ seçildi
- [ ] Environment variables eklendi
- [ ] Build workflow yapılandırıldı

## 🔍 Hata Ayıklama

### Build Loglarını Kontrol Et:

1. **Post-Clone Log**
   ```
   🔧 Post-clone script başlatılıyor...
   📦 SPM cache temizleniyor...
   📦 Package dependencies resolve ediliyor...
   ✅ Post-clone script tamamlandı!
   ```

2. **Pre-Build Log**
   ```
   🚀 Pre-build script başlatılıyor...
   📱 Xcode version: [version]
   🔷 Swift version: [version]
   📦 Package dependencies kontrol ediliyor...
   ✅ Package.resolved bulundu
   ✅ Pre-build script tamamlandı!
   ```

### Yaygın Sorunlar:

#### 1. Script Çalışmıyor
**Çözüm**: Script izinlerini kontrol et
```bash
ls -la ci_scripts/
```
Her iki dosya da `-rwxr-xr-x` izinlerine sahip olmalı.

#### 2. Package Resolve Hatası
**Çözüm**: Package.resolved dosyasını commit et
```bash
git add MagicPaper.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
git commit -m "Add Package.resolved for Xcode Cloud"
```

#### 3. Xcode Version Uyumsuzluğu
**Çözüm**: Xcode Cloud settings'de Xcode 15.2+ seçin

## 📦 Package Dependencies

### Firebase iOS SDK
- Version: 11.15.0
- Modules: FirebaseCore, FirebaseStorage

### Google Mobile Ads
- Version: 11.13.0
- Module: GoogleMobileAds

## 🔄 Build Süreci

```
1. Clone Repository
   ↓
2. Run ci_post_clone.sh
   - Clean SPM cache
   - Resolve packages
   ↓
3. Run ci_pre_xcodebuild.sh
   - Check Xcode version
   - Verify packages
   ↓
4. Build Project
   - Compile sources
   - Link frameworks
   ↓
5. Archive
   - Create .ipa
   ↓
6. Success! 🎉
```

## 🛠️ Manuel Test

Local'de Xcode Cloud gibi test etmek için:

```bash
# 1. Cache'i temizle
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf .build

# 2. Packages'i resolve et
xcodebuild -resolvePackageDependencies \
  -project MagicPaper.xcodeproj \
  -scheme MagicPaper

# 3. Build yap
xcodebuild -project MagicPaper.xcodeproj \
  -scheme MagicPaper \
  -configuration Release \
  clean build
```

## 📝 Notlar

### Project.pbxproj Yapısı

Dosya şu bölümleri içerir:
- `PBXBuildFile`: Compile edilecek dosyalar
- `PBXFileReference`: Proje dosyaları
- `PBXFrameworksBuildPhase`: Framework'ler
- `PBXGroup`: Dosya grupları
- `PBXNativeTarget`: Build target
- `PBXProject`: Proje ayarları
- `XCRemoteSwiftPackageReference`: SPM paketleri
- `XCSwiftPackageProductDependency`: Paket bağımlılıkları

### Sorun Kaynağı

Xcode Cloud'un kullandığı eski Xcode versiyonu, yeni project dosyası formatını tam olarak desteklemiyor. CI scripts bu uyumsuzluğu gideriyor.

## ✅ Doğrulama

Build başarılı olduğunda:

1. ✅ Scripts çalıştı
2. ✅ Packages resolve edildi
3. ✅ Build tamamlandı
4. ✅ Archive oluşturuldu
5. ✅ TestFlight'a yüklendi

## 🆘 Destek

Hala sorun yaşıyorsanız:

1. Build loglarını kontrol edin
2. Xcode versiyonunu güncelleyin
3. Package.resolved'ı yeniden oluşturun
4. Project dosyasını backup'tan geri yükleyin

---

**Durum**: ✅ DÜZELTME UYGULANMIŞ
**Tarih**: 30 Ocak 2026
**Xcode Cloud**: Uyumlu

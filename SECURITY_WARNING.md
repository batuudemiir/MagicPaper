# 🚨 GÜVENLİK UYARISI - RevenueCat Key

## ⚠️ SORUN

Yanlışlıkla **Secret Key (sk_)** paylaşıldı. Bu key derhal iptal edilmeli!

## 🔐 RevenueCat Key Tipleri

### ❌ Secret Key (sk_)
- **Kullanım:** Sunucu taraflı işlemler
- **Güvenlik:** ÇOK GİZLİ - Asla paylaşılmamalı
- **Konum:** Backend server, webhook'lar
- **iOS'ta:** ASLA KULLANILMAMALI

### ✅ Public Key (appl_)
- **Kullanım:** iOS uygulaması
- **Güvenlik:** Client-side için güvenli
- **Konum:** iOS app, Secrets.xcconfig
- **iOS'ta:** GÜVENLİ - Kullanılabilir

## 🚨 ACİL ADIMLAR

### 1. Secret Key'i İptal Edin

1. https://app.revenuecat.com/ adresine gidin
2. **Login** yapın
3. **Project Settings** > **API Keys**
4. Secret key'i bulun (sk_ ile başlayan)
5. **Delete** veya **Revoke** butonuna tıklayın
6. Onaylayın

### 2. Public Key Alın

1. Aynı sayfada (**API Keys**)
2. **Public app-specific API keys** bölümüne gidin
3. **iOS** platformu için key'i bulun
4. Key'i kopyalayın (appl_ ile başlar)

### 3. Secrets.xcconfig'i Güncelleyin

```bash
# Secrets.xcconfig dosyasını açın
# Public key'i yapıştırın:

REVENUECAT_API_KEY = appl_YOUR_NEW_PUBLIC_KEY_HERE
```

### 4. Xcode'da Clean Build

```bash
# Xcode'da:
Cmd + Shift + K  # Clean
Cmd + B          # Build
```

## 📋 Kontrol Listesi

- [ ] Secret key iptal edildi
- [ ] Public key alındı
- [ ] Secrets.xcconfig güncellendi
- [ ] .gitignore'da Secrets.xcconfig var
- [ ] Clean build yapıldı
- [ ] Uygulama test edildi
- [ ] Console'da "RevenueCat yapılandırıldı" görünüyor

## 🔒 Güvenlik Best Practices

### DO ✅

1. **Public Key Kullan**
   ```swift
   // iOS uygulamasında
   REVENUECAT_API_KEY = appl_xxxxx
   ```

2. **Secrets.xcconfig'de Sakla**
   ```bash
   # .gitignore
   Secrets.xcconfig
   *.xcconfig
   ```

3. **Environment Variables**
   ```bash
   # Development
   REVENUECAT_API_KEY = appl_dev_key
   
   # Production
   REVENUECAT_API_KEY = appl_prod_key
   ```

### DON'T ❌

1. **Secret Key Kullanma**
   ```swift
   // ❌ ASLA YAPMAYIN
   REVENUECAT_API_KEY = sk_xxxxx
   ```

2. **Hardcode Etme**
   ```swift
   // ❌ ASLA YAPMAYIN
   Purchases.configure(withAPIKey: "sk_xxxxx")
   ```

3. **Public Sharing**
   - ❌ Chat'te paylaşma
   - ❌ Screenshot'ta gösterme
   - ❌ Git'e commit etme
   - ❌ Public repo'ya push'lama

## 🔍 Key Kontrolü

### Doğru Key mi Kullanıyorsunuz?

```bash
# Secrets.xcconfig dosyasını kontrol edin:
cat Secrets.xcconfig | grep REVENUECAT

# Beklenen çıktı:
REVENUECAT_API_KEY = appl_xxxxx  # ✅ DOĞRU

# Yanlış çıktı:
REVENUECAT_API_KEY = sk_xxxxx    # ❌ YANLIŞ
```

### Console Log Kontrolü

```bash
# Xcode console'da görmeli:
✅ RevenueCat yapılandırıldı: appl_xxxxx...

# Görmemeli:
❌ RevenueCat yapılandırıldı: sk_xxxxx...
```

## 📚 Kaynaklar

- **RevenueCat Security**: https://docs.revenuecat.com/docs/authentication
- **API Keys**: https://docs.revenuecat.com/docs/api-keys
- **Best Practices**: https://docs.revenuecat.com/docs/security-best-practices

## 💡 Gelecekte Önlemek İçin

1. **Key Tipleri Öğren**
   - Secret key = Backend only
   - Public key = iOS app

2. **Secrets.xcconfig Kullan**
   - Key'leri kodda hardcode etme
   - Configuration file kullan

3. **.gitignore Kontrol Et**
   - Secrets.xcconfig ignore edilmiş mi?
   - Commit edilmemiş mi?

4. **Code Review**
   - Key'leri commit etmeden önce kontrol et
   - Pre-commit hook kullan

## 🆘 Yardım

Eğer:
- Secret key'i iptal edemediyseniz
- Public key bulamıyorsanız
- Hala sorun yaşıyorsanız

**RevenueCat Support:**
- Email: support@revenuecat.com
- Docs: https://docs.revenuecat.com/
- Community: https://community.revenuecat.com/

---

**ÖNEMLİ:** Bu güvenlik sorunu derhal çözülmeli. Secret key iptal edilene kadar uygulamayı production'a almayın!

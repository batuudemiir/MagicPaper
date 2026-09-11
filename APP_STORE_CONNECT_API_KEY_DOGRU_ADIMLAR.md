# 🔑 App Store Connect API Key - Doğru Adımlar

## ✅ Doğru Yol (Web Araştırması Sonucu)

### Adım 1: App Store Connect'e Git

```
https://appstoreconnect.apple.com/
Apple ID ile giriş yap
```

### Adım 2: Users and Access

```
Sol menüden "Users and Access" tıkla
```

### Adım 3: Integrations Tab

```
Üstte "Integrations" tab'ına tıkla
(Keys değil, Integrations!)
```

### Adım 4: App Store Connect API

```
"App Store Connect API" bölümünü bul
(Team Keys veya In-App Purchase Keys değil!)
```

### Adım 5: Generate API Key

```
"+" butonu veya "Generate API Key" tıkla
```

### Adım 6: Key Bilgileri

```
Name: RevenueCat
Access: App Manager (veya Admin)

Generate butonu
```

### Adım 7: Bilgileri Kaydet

```
✅ Issuer ID (sayfanın üstünde, UUID formatında)
✅ Key ID (tabloda, 10 karakter)
✅ Download API Key (.p8 dosyası) - Sadece 1 kez indirebilirsin!
```

## 📋 Detaylı Görsel Rehber

### 1. Users and Access

```
App Store Connect Ana Sayfa
└── Sol Menü
    └── Users and Access (tıkla)
```

### 2. Integrations Tab

```
Users and Access Sayfası
└── Üst Tab'lar
    ├── Users
    ├── API Keys (BURASI DEĞİL!)
    └── Integrations (BURAYA!)
```

### 3. App Store Connect API

```
Integrations Sayfası
├── App Store Connect API (BURASI!)
│   ├── Issuer ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
│   ├── Active Keys (tablo)
│   └── + butonu (Generate API Key)
│
├── Team Keys (burası değil)
└── In-App Purchase Keys (burası değil)
```

### 4. Generate

```
+ butonu tıkla

Modal açılır:
├── Name: [RevenueCat]
├── Access: [App Manager ▼]
│   ├── Admin
│   ├── App Manager ← Seç
│   ├── Developer
│   ├── Marketing
│   └── Sales
└── [Generate] butonu
```

### 5. Download

```
Key oluşturuldu!

Tabloda:
├── Name: RevenueCat
├── Key ID: ABC123XYZ0 (10 karakter)
├── Access: App Manager
└── [Download API Key] butonu ← Hemen indir!

⚠️ .p8 dosyasını sadece 1 kez indirebilirsin!
```

### 6. Issuer ID

```
Sayfanın üstünde:
Issuer ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

Kopyala!
```

## 🎯 RevenueCat'e Bağlama

### 1. RevenueCat Dashboard

```
https://app.revenuecat.com/
```

### 2. Project Settings

```
Sol altta ⚙️ (Settings)
```

### 3. Apple App Store

```
"Apple App Store" veya "Integrations" bölümü
Configure butonu
```

### 4. App Store Connect API

```
Connection Type: App Store Connect API seç

Issuer ID: [yapıştır]
Key ID: [yapıştır]
Private Key: [.p8 dosyasını yükle veya içeriğini yapıştır]

Save
```

### 5. Production Key Görünecek

```
Project Settings > API Keys > iOS

Production Key: appl_... ✅
```

## ⚠️ Yaygın Hatalar

### Hata 1: "Keys" Tab'ına Gitmek

```
❌ Users and Access > Keys (YANLIŞ!)
✅ Users and Access > Integrations (DOĞRU!)
```

### Hata 2: Team Keys

```
❌ Integrations > Team Keys (YANLIŞ!)
✅ Integrations > App Store Connect API (DOĞRU!)
```

### Hata 3: In-App Purchase Keys

```
❌ Integrations > In-App Purchase Keys (YANLIŞ!)
✅ Integrations > App Store Connect API (DOĞRU!)
```

### Hata 4: .p8 Dosyasını İndirmemek

```
❌ Key ID'yi kopyaladım, .p8'i indirmedim
✅ Hem Key ID hem .p8 dosyasını kaydet!

⚠️ .p8 dosyasını sadece 1 kez indirebilirsin!
Kaybedersen yeni key oluşturman gerekir.
```

## 📱 Mobil Uyarısı

**Mobil tarayıcıdan yapma!**

App Store Connect'in mobil görünümünde Key ID ve Download butonu görünmüyor. Masaüstü tarayıcı kullan.

## 🔐 Güvenlik

### .p8 Dosyası

```
✅ Güvenli yerde sakla
✅ Git'e ekleme (.gitignore)
✅ Sadece RevenueCat'e yükle
❌ Kimseyle paylaşma
```

### Key Yetkileri

```
Admin: Tüm yetkiler (önerilmez)
App Manager: Uygulama yönetimi (önerilen)
Developer: Sadece geliştirme
```

RevenueCat için **App Manager** yeterli.

## ✅ Checklist

- [ ] App Store Connect'e giriş yaptım
- [ ] Users and Access > Integrations
- [ ] App Store Connect API bölümü
- [ ] + butonu > Generate API Key
- [ ] Name: RevenueCat, Access: App Manager
- [ ] Issuer ID kopyaladım
- [ ] Key ID kopyaladım
- [ ] .p8 dosyasını indirdim
- [ ] RevenueCat Dashboard'a gittim
- [ ] Apple App Store > Configure
- [ ] Bilgileri girdim
- [ ] Save
- [ ] Production key (appl_) görünüyor

## 🎯 Özet

**Doğru yol:**
```
App Store Connect
└── Users and Access
    └── Integrations (tab)
        └── App Store Connect API
            └── + Generate API Key
                ├── Name: RevenueCat
                ├── Access: App Manager
                └── Generate
                    ├── Issuer ID (kopyala)
                    ├── Key ID (kopyala)
                    └── Download .p8 (indir)
```

**RevenueCat:**
```
Dashboard > Settings > Apple App Store > Configure
├── Issuer ID
├── Key ID
└── Private Key (.p8)
```

**Sonuç:**
```
API Keys > iOS > Production Key: appl_... ✅
```

---

**Kaynak:** [Web Araştırması](https://www.amarjanica.com/how-to-create-app-store-connect-api-key-and-what-to-do-with-it/)

**Şimdi:** Integrations tab'ına git! 🚀

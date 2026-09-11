# ⚡ Paywall Setup - Hızlı Rehber

## 🎯 5 Dakikada RevenueCat Dashboard

### 1️⃣ Entitlement (30 saniye)
```
Dashboard > Entitlements > + New

Identifier: premium
Display Name: Premium Access

Create
```

### 2️⃣ Products (2 dakika)
```
Dashboard > Products > + New (3 kez)

Product 1:
- ID: magicpaper_basic_monthly
- Store: App Store
- Type: Subscription
- Entitlement: premium

Product 2:
- ID: magicpaper_premium_monthly
- Store: App Store
- Type: Subscription
- Entitlement: premium

Product 3:
- ID: magicpaper_ultimate_monthly
- Store: App Store
- Type: Subscription
- Entitlement: premium
```

### 3️⃣ Offering (1 dakika)
```
Dashboard > Offerings > + New Offering

Identifier: default
Display Name: Hikaye Kulübü
✅ Make this the current offering

Create
```

### 4️⃣ Packages (1.5 dakika)
```
Offerings > default > + Add Package (3 kez)

Package 1:
- Identifier: $rc_monthly
- Product: magicpaper_basic_monthly

Package 2:
- Identifier: $rc_monthly
- Product: magicpaper_premium_monthly

Package 3:
- Identifier: $rc_monthly
- Product: magicpaper_ultimate_monthly
```

### ✅ Test Et
```
Xcode > Run
Paywall aç
```

**Console'da görmeli:**
```
✅ RevenueCat offerings loaded: 1 offerings
📦 Current offering: default
📦 Available packages: 3
```

---

## 🛍️ App Store Connect (Sonra Yapılacak)

### Subscription Group
```
App Store Connect > In-App Purchases
+ > Subscription Group
Name: MagicPaper Subscriptions
```

### 3 Subscription
```
+ > Auto-Renewable Subscription (3 kez)

1. magicpaper_basic_monthly - ₺89.99/month
2. magicpaper_premium_monthly - ₺149.99/month
3. magicpaper_ultimate_monthly - ₺349.99/month

Her biri için Submit for Review
```

---

## 🎨 Paywall Tasarımı (Opsiyonel)

```
Dashboard > Offerings > default > Paywall > Edit

Template: Multi-package
Title: Hikaye Kulübü 📚
Subtitle: Çocuğunuza okuma alışkanlığı kazandırın

Colors:
- Primary: #FF9500
- Secondary: #FFD700

Save
```

---

## 📋 Checklist

**Şimdi (5 dakika):**
- [ ] Entitlement: premium
- [ ] 3 Product
- [ ] Offering: default (current)
- [ ] 3 Package
- [ ] Test et

**Sonra (15 dakika):**
- [ ] App Store Connect subscriptions
- [ ] Sandbox test
- [ ] Paywall tasarımı

---

**Detaylı Rehber:** `REVENUECAT_DASHBOARD_SETUP_ADIMLAR.md`

**Şimdi:** https://app.revenuecat.com/ 🚀

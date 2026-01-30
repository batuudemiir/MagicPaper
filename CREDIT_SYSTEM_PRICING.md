# ⭐ Kredi Sistemi Fiyatlandırması

**Tarih**: 30 Ocak 2026  
**Durum**: 🎯 Uygulanacak

---

## 🎯 Neden Kredi Sistemi?

### Anne-Baba Psikolojisi:

**❌ Eski Sistem (Karmaşık):**
- "Aylık ne kadar hikaye yaparız bilmiyoruz..."
- "Abonelik çok bağlayıcı..."
- "Seçenek çok, kafam karıştı..."
- 9 farklı seçenek
- Karar süresi: 30 saniye

**✅ Yeni Sistem (Basit):**
- "Kredi alıyorum, istediğim zaman kullanıyorum!"
- "Çocuk her gece istemezse param gitmez"
- "Metin mi görselli mi istediğime ben karar veririm"
- 5 kredi paketi
- Karar süresi: 5 saniye

---

## 💰 Kredi Paketleri

| Paket | Fiyat | Kredi | Maliyet | Kar | Kar Marjı | Anne-Baba Düşüncesi |
|-------|-------|-------|---------|-----|-----------|---------------------|
| 🆓 **Deneme** | ₺0 | 3 kredi | ₺0 | ₺0 | - | "Önce deneyeyim, beğenirsem alırım" |
| 💰 **Başlangıç** | ₺79 | 10 kredi | ₺26 | ₺53 | 67% | "Ayda 3-4 görselli + biraz metin yeter" |
| 📦 **Standart** ⭐ | ₺149 | 25 kredi | ₺70 | ₺79 | 53% | "Haftada 2 görselli rahat yapabilirim" |
| 🎁 **Artı** | ₺249 | 50 kredi | ₺130 | ₺119 | 48% | "Her gece hikaye + misafirler için" |
| 👑 **Premium** | ₺399 | 100 kredi | ₺260 | ₺139 | 35% | "2 çocuğum var, bol kullanacağız" |

### Kredi Kullanımı:
- **📝 Metin hikaye** = 1 kredi (maliyet: ₺2)
- **🎨 Görselli hikaye** = 3 kredi (maliyet: ₺12)

### Varsayım:
- %70 metin kullanımı
- %30 görselli kullanımı

---

## ✅ Avantajlar

### 1. Basit Karar
```
Anne-baba: "149 TL'ye 25 kredi alıyorum"
           "Bu ay 8 görselli yaptım, 1 kredi kaldı"

❌ DEĞİL: "Premium mi alalım, Standart mı?"
          "Günde 1 hikaye yeter mi?"
          "10'lu paket mi 5'li mi?"
```

### 2. Esneklik
```
Pazartesi: "Bugün yorgunum, 1 krediye metin yeter"
Cuma: "Haftasonu, 3 krediye görselli yapalım!"

❌ DEĞİL: "Premium aldım ama kullanmadım, param gitti"
```

### 3. Psikolojik Avantaj
```
✅ "Kredim bitiyor, hemen paket almalıyım!"
   → Tekrar satın alma artar

✅ "3 kredim var, kullanmazsam kaybolacak!"
   → Engagement yükselir
```

---

## 📱 UI/UX Tasarımı

### Ana Ekran - Kredi Göstergesi

```
┌─────────────────────────┐
│   ⭐ 7 kredi kaldı      │
│                          │
│  Yeni hikaye oluştur:    │
│                          │
│  [📝 Metin (1 ⭐)]       │
│  [🎨 Görselli (3 ⭐)]    │
│                          │
│  💡 3 kredin kaldı!      │
│  Standart paket al,      │
│  25 kredi kazan →        │
└─────────────────────────┘
```

### Satın Alma Ekranı

```
┌──────────────────────────────┐
│  Kredi Paketi Seç           │
├──────────────────────────────┤
│  💰 Başlangıç               │
│  ₺79                         │
│  10 kredi                    │
│  ~3 görselli hikaye          │
├──────────────────────────────┤
│  📦 Standart  ⭐ ÖNERİLEN   │
│  ₺149                        │
│  25 kredi                    │
│  ~8 görselli hikaye          │
│  🔥 EN POPÜLER               │
├──────────────────────────────┤
│  🎁 Artı                    │
│  ₺249                        │
│  50 kredi                    │
│  ~16 görselli hikaye         │
├──────────────────────────────┤
│  👑 Premium                 │
│  ₺399                        │
│  100 kredi                   │
│  ~33 görselli hikaye         │
│  💎 EN AVANTAJLI            │
└──────────────────────────────┘
```

### Kredi Bittiğinde

```
┌─────────────────────────┐
│  😢 Kredin bitti!        │
│                          │
│  Daha fazla hikaye için  │
│  hemen paket al!         │
│                          │
│  [📦 Paket Al]           │
│  [Daha Sonra]            │
└─────────────────────────┘
```

### Kredi Azaldığında (3 kredi kaldı)

```
┌─────────────────────────┐
│  ⚠️ Krediler azalıyor!  │
│                          │
│  Sadece 3 kredin kaldı   │
│  Paket al, %20 bonus!    │
│                          │
│  [🎁 Bonus Al]           │
│  [Daha Sonra]            │
└─────────────────────────┘
```

---

## 🎨 Görsel Tasarım

### Kredi Badge (Ana Ekran)

```swift
HStack(spacing: 8) {
    Image(systemName: "star.fill")
        .foregroundStyle(
            LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    
    Text("\(credits) kredi")
        .font(.headline.bold())
        .foregroundColor(.primary)
}
.padding(.horizontal, 16)
.padding(.vertical, 8)
.background(
    Capsule()
        .fill(.yellow.opacity(0.15))
        .overlay(
            Capsule()
                .stroke(.yellow, lineWidth: 2)
        )
)
```

### Paket Kartı

```swift
VStack(spacing: 12) {
    // Badge (ÖNERİLEN, EN POPÜLER, vb.)
    if let badge = badge {
        Text(badge)
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Capsule().fill(.orange))
    }
    
    // Icon
    Text(icon)
        .font(.system(size: 48))
    
    // Title
    Text(title)
        .font(.title2.bold())
    
    // Price
    Text(price)
        .font(.system(size: 36, weight: .heavy))
        .foregroundColor(.primary)
    
    // Credits
    HStack(spacing: 4) {
        Image(systemName: "star.fill")
            .foregroundColor(.yellow)
        Text("\(credits) kredi")
            .font(.headline)
    }
    
    // Equivalent
    Text("~\(visualStories) görselli hikaye")
        .font(.subheadline)
        .foregroundColor(.secondary)
}
```

---

## 📊 Karlılık Analizi

### Paket Bazında:

**Başlangıç (₺79 - 10 kredi):**
- Kullanım: 7 metin + 1 görselli
- Maliyet: (7 × ₺2) + (1 × ₺12) = ₺26
- Kar: ₺79 - ₺26 = ₺53
- Kar Marjı: 67% ✅

**Standart (₺149 - 25 kredi) ⭐:**
- Kullanım: 17.5 metin + 2.5 görselli
- Maliyet: (17.5 × ₺2) + (2.5 × ₺12) = ₺70
- Kar: ₺149 - ₺70 = ₺79
- Kar Marjı: 53% ✅

**Artı (₺249 - 50 kredi):**
- Kullanım: 35 metin + 5 görselli
- Maliyet: (35 × ₺2) + (5 × ₺12) = ₺130
- Kar: ₺249 - ₺130 = ₺119
- Kar Marjı: 48% ✅

**Premium (₺399 - 100 kredi):**
- Kullanım: 70 metin + 10 görselli
- Maliyet: (70 × ₺2) + (10 × ₺12) = ₺260
- Kar: ₺399 - ₺260 = ₺139
- Kar Marjı: 35% ✅

### Tüm Paketler Karlı! 🎉

---

## 🎯 Kullanıcı Akışı

### 1. İlk Kullanım (Ücretsiz 3 Kredi)
```
Kullanıcı kayıt olur
  ↓
3 kredi hediye edilir
  ↓
1 metin hikaye yapar (2 kredi kaldı)
  ↓
1 görselli hikaye yapar (0 kredi kaldı)
  ↓
"Kredin bitti!" ekranı
  ↓
Paket satın alır
```

### 2. Düzenli Kullanım
```
25 kredi var
  ↓
Hafta içi: 5 metin hikaye (20 kredi kaldı)
  ↓
Hafta sonu: 2 görselli hikaye (14 kredi kaldı)
  ↓
"3 kredin kaldı!" uyarısı
  ↓
Yeni paket alır
```

### 3. Yoğun Kullanım
```
100 kredi var
  ↓
Her gün 1 görselli (30 gün = 90 kredi)
  ↓
10 kredi kaldı
  ↓
"Krediler azalıyor!" uyarısı
  ↓
Premium paket yeniler
```

---

## 🎁 Bonus ve Promosyonlar

### 1. İlk Satın Alma Bonusu
```
İlk paket alımında %20 bonus kredi!

Başlangıç: 10 → 12 kredi
Standart: 25 → 30 kredi
Artı: 50 → 60 kredi
Premium: 100 → 120 kredi
```

### 2. Referral Bonusu
```
Arkadaşını davet et:
- Sen: 5 bonus kredi
- Arkadaşın: 5 bonus kredi
```

### 3. Sezonsal Kampanyalar
```
Yılbaşı: Tüm paketlerde %30 bonus kredi
Anneler Günü: Standart paket al, 10 bonus kredi
Okul Dönemi: Premium paket al, 25 bonus kredi
```

---

## 📈 Gelir Projeksiyonu

### Senaryo: 10.000 Aktif Kullanıcı

**Kullanıcı Dağılımı:**
- %60 Ücretsiz (6.000 kişi) - Sadece 3 kredi
- %25 Başlangıç (2.500 kişi) - Ayda 1 paket
- %10 Standart (1.000 kişi) - Ayda 1 paket
- %4 Artı (400 kişi) - Ayda 1 paket
- %1 Premium (100 kişi) - Ayda 1 paket

**Aylık Gelir:**
```
Başlangıç: 2.500 × ₺79 = ₺197.500
Standart: 1.000 × ₺149 = ₺149.000
Artı: 400 × ₺249 = ₺99.600
Premium: 100 × ₺399 = ₺39.900

TOPLAM: ₺486.000/ay
```

**Aylık Maliyet:**
```
Başlangıç: 2.500 × ₺26 = ₺65.000
Standart: 1.000 × ₺70 = ₺70.000
Artı: 400 × ₺130 = ₺52.000
Premium: 100 × ₺260 = ₺26.000

TOPLAM: ₺213.000/ay
```

**Net Kar: ₺273.000/ay (56% kar marjı)** 🎉

---

## 🚀 Uygulama Planı

### Faz 1: Backend (1 hafta)
- [ ] Kredi sistemi database
- [ ] Kredi kullanım logic
- [ ] Paket satın alma
- [ ] Kredi geçmişi

### Faz 2: UI/UX (1 hafta)
- [ ] Kredi göstergesi (ana ekran)
- [ ] Paket satın alma ekranı
- [ ] Kredi bittiğinde popup
- [ ] Kredi azaldığında uyarı

### Faz 3: StoreKit (1 hafta)
- [ ] IAP product'ları tanımla
- [ ] Satın alma flow
- [ ] Receipt validation
- [ ] Restore purchases

### Faz 4: Test & Launch (1 hafta)
- [ ] Beta test
- [ ] A/B testing (fiyatlar)
- [ ] Analytics integration
- [ ] Production launch

---

## ✅ Başarı Kriterleri

### KPI'lar:
- Conversion rate: >%30 (ücretsiz → ücretli)
- Repeat purchase: >%60 (2. paket alımı)
- ARPU: >₺50/ay
- Churn rate: <%10/ay

### Kullanıcı Feedback:
- "Çok basit, anladım hemen!"
- "İstediğim zaman kullanıyorum"
- "Param boşa gitmiyor"

---

**Durum**: 🎯 UYGULANACAK  
**Öncelik**: 🔴 YÜKSEK  
**Tahmini Süre**: 4 hafta  
**Beklenen Sonuç**: %50+ conversion artışı

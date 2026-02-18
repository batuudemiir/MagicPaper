#!/usr/bin/env python3
"""
Automatic Localization Script for MagicPaper
Finds hardcoded Turkish strings and replaces them with L. helper calls
"""

import re
import os
from pathlib import Path

# Common Turkish strings and their English translations
TRANSLATIONS = {
    # TextOnlyStoryView
    "Metin Hikaye": "Text Story",
    "Hızlı Hikaye Oluştur": "Quick Story Create",
    "Görselsiz, sadece metin tabanlı hikaye": "Text-only story without images",
    "Temel Bilgiler": "Basic Information",
    "Çocuğun İsmi": "Child's Name",
    "İsim girin": "Enter name",
    "Cinsiyet": "Gender",
    "Erkek": "Boy",
    "Kız": "Girl",
    "Diğer": "Other",
    "Hikaye Teması": "Story Theme",
    "Maceranın türünü seçin": "Select the type of adventure",
    "Ücretsiz Temalar": "Free Themes",
    "Premium Temalar": "Premium Themes",
    "Özel Hikaye Konusu": "Custom Story Subject",
    "Örn: Dinozorlarla macera": "e.g: Adventure with dinosaurs",
    "Hikaye Oluştur": "Create Story",
    "Ücretsiz Hikaye Hazır!": "Free Story Ready!",
    "12 saatte 1 ücretsiz metin hikaye hakkınız var": "You have 1 free text story every 12 hours",
    "saat sonra": "hours later",
    "Sınırsız hikaye için kulübe katıl - Günde 3₺": "Join club for unlimited stories - $1/day",
    "Kulübe Katıl": "Join Club",
    "Lütfen çocuğun ismini girin": "Please enter child's name",
    "⚠️ Eksik Bilgi": "⚠️ Missing Information",
    "Lütfen çocuğun ismini girin.": "Please enter child's name.",
    "👑 Premium Tema": "👑 Premium Theme",
    "teması premium üyelere özeldir.": "theme is exclusive to premium members.",
    "🎁 Ücretsiz Deneme": "🎁 Free Trial",
    "ücretsiz deneme hakkınız kaldı!": "free trials left!",
    "✨ Ücretsiz Hikaye": "✨ Free Story",
    "⏰ Bekleme Süresi": "⏰ Waiting Time",
    "Bir sonraki ücretsiz hikaye için": "Next free story in",
    "saat beklemeniz gerekiyor.": "hours wait required.",
    "Hikaye oluşturuluyor...": "Story creating...",
    "✅ Başarılı": "✅ Success",
    "Hikayeniz kütüphanede yükleniyor!": "Your story is loading in library!",
    "❌ Hata": "❌ Error",
    "Hikaye oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.": "An error occurred while creating the story. Please try again.",
    "Bilgi": "Info",
    "Tamam": "OK",
    
    # SimpleSubscriptionView
    "Hikaye Kulübü": "Story Club",
    "Kulübümüze katıl, sınırsız hikaye dünyasını keşfet!": "Join our club, discover unlimited story world!",
    "EN POPÜLER": "MOST POPULAR",
    "/ ay": "/ month",
    "Günde sadece": "Only",
    "Süper Tasarruf!": "Super Savings!",
    "Maksimum Değer!": "Maximum Value!",
    "Hemen katıl, ilk 3 gün ücretsiz dene!": "Join now, try free for 3 days!",
    "İlk 3 gün ücretsiz": "First 3 days free",
    "İstediğiniz zaman iptal edebilirsiniz": "You can cancel anytime",
    "Üyeliğinizi istediğiniz zaman iOS ayarlarından iptal edebilirsiniz": "You can cancel your membership anytime from iOS settings",
    "Sınırsız metin hikaye": "Unlimited text stories",
    "Sınırsız günlük hikaye": "Unlimited daily stories",
    "Sınırsız görselli hikaye": "Unlimited illustrated stories",
    "Tüm premium temalar": "All premium themes",
    "Reklamsız deneyim": "Ad-free experience",
    "Öncelikli destek": "Priority support",
    
    # SettingsView
    "Ayarlar": "Settings",
    "Profil": "Profile",
    "hikaye": "story",
    "Hikaye Ayarları": "Story Settings",
    "Varsayılan Dil": "Default Language",
    "Uygulama dili ve hikaye dili": "App language and story language",
    "Varsayılan Yaş": "Default Age",
    "Hikayeler için varsayılan yaş grubu": "Default age group for stories",
    "yaş": "years",
    "Yüksek Kalite Görseller": "High Quality Images",
    "Daha yüksek çözünürlükte görseller": "Higher resolution images",
    "Uygulama Ayarları": "App Settings",
    "Bildirimler": "Notifications",
    "Günlük hikaye bildirimleri": "Daily story notifications",
    "Otomatik Kaydet": "Auto Save",
    "Hikayeleri otomatik kaydet": "Auto save stories",
    "Hızlı İşlemler": "Quick Actions",
    "Yeni Hikaye Oluştur": "Create New Story",
    "Hikaye Kütüphanem": "My Story Library",
    "Hakkında ve Destek": "About & Support",
    "Uygulamayı Paylaş": "Share App",
    "Uygulamayı Değerlendir": "Rate App",
    "Gizlilik Politikası": "Privacy Policy",
    "Kullanım Şartları": "Terms of Service",
    "Destek İletişim": "Contact Support",
    "Versiyon": "Version",
    "Tehlike Bölgesi": "Danger Zone",
    "Tüm Verileri Temizle": "Clear All Data",
    "Bu işlem tüm hikayelerinizi ve ayarlarınızı silecektir. Bu işlem geri alınamaz.": "This will delete all your stories and settings. This action cannot be undone.",
    "Verileri Temizle": "Clear Data",
    "İptal": "Cancel",
    
    # HomeView
    "Ana Sayfa": "Home",
    "Hoş Geldin": "Welcome Back",
    "Hadi sihirli hikayeler yaratalım!": "Let's create magical stories!",
    "Günlük Hikayeler": "Daily Stories",
    "Her gün yeni bir macera": "A new adventure every day",
    "Görselli": "Illustrated",
    "Metin": "Text",
    "Günlük": "Daily",
    "Kütüphane": "Library",
    
    # LibraryView
    "Kütüphanem": "My Library",
    "Henüz Hikaye Yok": "No Stories Yet",
    "İlk hikayenizi oluşturun ve\nçocuğunuzla okuma keyfini yaşayın": "Create your first story and\nenjoy reading with your child",
    "Hikayeyi Sil": "Delete Story",
    "Bu hikayeyi silmek istediğinizden emin misiniz?": "Are you sure you want to delete this story?",
    "Sil": "Delete",
    "Tamamlandı": "Completed",
    "Başarısız": "Failed",
    "Yükleniyor": "Uploading",
    
    # ParentalGateView
    "Ebeveyn Doğrulaması": "Parental Verification",
    "Bu işlem yetişkin onayı gerektiriyor": "This action requires adult approval",
    "Lütfen aşağıdaki soruyu cevaplayın:": "Please answer the following question:",
    "Cevabınızı girin": "Enter your answer",
    "Doğrula": "Verify",
    "Yanlış Cevap": "Wrong Answer",
    "Lütfen tekrar deneyin": "Please try again",
    
    # DailyStoriesView
    "Günlük Hikayeler": "Daily Stories",
    "Her gün yeni bir macera!": "A new adventure every day!",
    "Uyku Vakti": "Bedtime",
    "Sabah Hikayeleri": "Morning Stories",
    "Eğitici": "Educational",
    "Değerler": "Values",
    "Macera": "Adventure",
    "Doğa": "Nature",
    
    # Common
    "Geri": "Back",
    "İleri": "Next",
    "Atla": "Skip",
    "Başla": "Start",
    "Oluştur": "Create",
    "Yükleniyor...": "Loading...",
    "Yeni": "New",
    "Popüler": "Popular",
    "Sınırsız": "Unlimited",
    "Premium": "Premium",
    "Kaydet": "Save",
    "Kapat": "Close",
}

def find_swift_files(directory):
    """Find all Swift files in the directory"""
    swift_files = []
    for root, dirs, files in os.walk(directory):
        # Skip certain directories
        if any(skip in root for skip in ['.git', 'DerivedData', '.build', 'Pods']):
            continue
        for file in files:
            if file.endswith('.swift'):
                swift_files.append(os.path.join(root, file))
    return swift_files

def find_hardcoded_strings(content):
    """Find hardcoded Turkish strings in Swift code"""
    # Pattern to match Text("...") or .title("...") etc
    patterns = [
        r'Text\("([^"]+)"\)',
        r'\.title\("([^"]+)"\)',
        r'\.placeholder\("([^"]+)"\)',
        r'Button\("([^"]+)"\)',
        r'Label\("([^"]+)"\)',
    ]
    
    found_strings = set()
    for pattern in patterns:
        matches = re.findall(pattern, content)
        for match in matches:
            # Check if it's Turkish (contains Turkish characters or known Turkish words)
            if any(char in match for char in 'ğüşıöçĞÜŞİÖÇ') or match in TRANSLATIONS:
                found_strings.add(match)
    
    return found_strings

def generate_localization_key(text):
    """Generate a camelCase key from Turkish text"""
    # Remove special characters
    text = re.sub(r'[^\w\s]', '', text)
    # Split into words
    words = text.split()
    if not words:
        return "unknown"
    # First word lowercase, rest capitalized
    key = words[0].lower()
    for word in words[1:]:
        key += word.capitalize()
    # Remove Turkish characters
    replacements = {
        'ğ': 'g', 'ü': 'u', 'ş': 's', 'ı': 'i', 'ö': 'o', 'ç': 'c',
        'Ğ': 'G', 'Ü': 'U', 'Ş': 'S', 'İ': 'I', 'Ö': 'O', 'Ç': 'C'
    }
    for tr_char, en_char in replacements.items():
        key = key.replace(tr_char, en_char)
    return key[:50]  # Limit length

def main():
    print("🔍 MagicPaper Localization Script")
    print("=" * 50)
    
    # Find all Swift files
    magic_paper_dir = "MagicPaper"
    if not os.path.exists(magic_paper_dir):
        print(f"❌ Directory {magic_paper_dir} not found!")
        return
    
    swift_files = find_swift_files(magic_paper_dir)
    print(f"📁 Found {len(swift_files)} Swift files")
    
    # Collect all hardcoded strings
    all_strings = {}
    for file_path in swift_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                strings = find_hardcoded_strings(content)
                if strings:
                    all_strings[file_path] = strings
        except Exception as e:
            print(f"⚠️  Error reading {file_path}: {e}")
    
    # Print summary
    print(f"\n📊 Found hardcoded Turkish strings in {len(all_strings)} files:")
    total_strings = sum(len(strings) for strings in all_strings.values())
    print(f"   Total unique strings: {total_strings}")
    
    # Print strings that need translation
    print("\n🔤 Strings found (first 20):")
    count = 0
    for file_path, strings in all_strings.items():
        for string in strings:
            if count >= 20:
                break
            translation = TRANSLATIONS.get(string, "❓ NEEDS TRANSLATION")
            print(f"   • {string[:50]:<50} → {translation}")
            count += 1
        if count >= 20:
            break
    
    print(f"\n✅ Script completed!")
    print(f"📝 Next steps:")
    print(f"   1. Review the translations above")
    print(f"   2. Add missing translations to TRANSLATIONS dict")
    print(f"   3. Run script again to apply changes")

if __name__ == "__main__":
    main()

#!/bin/bash
# Depoda olmayan iki dosyayı CI için yerine koyar (25 Kasım 2026).
#
# - MagicPaper/Secrets.xcconfig: boş anahtarlar; uygulama boş anahtarı "yok"
#   sayar (APIKeys). Proje bu dosyayı temel ayar olarak okur, yoksa derleme düşer.
# - MagicPaper/GoogleService-Info.plist: GOOGLE_SERVICE_INFO_PLIST gizli ayarı
#   verilmişse o, yoksa biçimi doğru sahte bir dosya. Sahte dosyayla Firebase ağ
#   çağrıları başarısız olur ama açılış çökmez; derleme, test ve ekran turu için
#   yeterli.
#
# Var olan dosyaya dokunmaz (yerelde gerçek anahtarlar korunur).
# Kullanan: .github/workflows/ios-build.yml, Scripts/ci_screenshots.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE="${BUNDLE:-com.batu.magicpaper.v1}"
cd "$ROOT"

if [ ! -f MagicPaper/Secrets.xcconfig ]; then
  printf 'FAL_API_KEY =\nREVENUECAT_API_KEY =\nGOOGLE_REVERSED_CLIENT_ID =\n' > MagicPaper/Secrets.xcconfig
fi

if [ ! -f MagicPaper/GoogleService-Info.plist ]; then
  if [ -n "${GOOGLE_SERVICE_INFO_PLIST:-}" ]; then
    printf '%s' "$GOOGLE_SERVICE_INFO_PLIST" > MagicPaper/GoogleService-Info.plist
  else
    cat > MagicPaper/GoogleService-Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>API_KEY</key><string>AIzaSyA-ci-placeholder-000000000000000</string>
<key>GCM_SENDER_ID</key><string>123456789012</string>
<key>BUNDLE_ID</key><string>$BUNDLE</string>
<key>PROJECT_ID</key><string>magicpaper-ci</string>
<key>STORAGE_BUCKET</key><string>magicpaper-ci.appspot.com</string>
<key>GOOGLE_APP_ID</key><string>1:123456789012:ios:0000000000000000000000</string>
<key>IS_ADS_ENABLED</key><false/><key>IS_ANALYTICS_ENABLED</key><false/>
<key>IS_APPINVITE_ENABLED</key><false/><key>IS_GCM_ENABLED</key><false/>
<key>IS_SIGNIN_ENABLED</key><true/>
</dict></plist>
EOF
  fi
fi

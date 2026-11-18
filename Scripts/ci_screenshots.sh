#!/bin/bash
# Gerçek uygulamanın ekran görüntüleri (18 Kasım 2026, İrem).
#
# Mac'te (GitHub Actions macOS ya da Batuhan'ın bilgisayarı) uygulamayı Debug
# derler, iki simülatörde (küçük: iPhone SE, büyük: Pro Max) DEBUG açılış
# kancalarıyla (`MPDebugLaunch`) her ekranı açar ve fotoğrafını çeker.
# Her ekran normal yazı ve en büyük erişilebilirlik yazısıyla çekilir.
# Koyu görünüm çekilmez: uygulama `UIUserInterfaceStyle = Light`.
#
# Çıktı: design-preview/screens/real/*.png + shots.js (önizleyici bunu okur).
# Yerelde: Scripts/ci_screenshots.sh   (Xcode ve simülatörler kurulu olmalı)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/design-preview/screens/real"
DERIVED="${DERIVED:-$ROOT/build/screenshots}"
BUNDLE="com.batu.magicpaper.v1"
WAIT="${WAIT:-7}"

cd "$ROOT"

# --- Depoda olmayan dosyalar ------------------------------------------------
# Secrets.xcconfig: boş anahtarlar; uygulama boş anahtarı "yok" sayar (APIKeys).
if [ ! -f Secrets.xcconfig ]; then
  printf 'FAL_API_KEY =\nREVENUECAT_API_KEY =\nGOOGLE_REVERSED_CLIENT_ID =\n' > Secrets.xcconfig
fi
# GoogleService-Info.plist: gerçek dosya gizli ayar olarak verilmişse o, yoksa
# biçimi doğru sahte bir dosya. Sahte dosyayla Firebase ağ çağrıları başarısız
# olur ama açılış çökmez; ekran görüntüsü için yeterli.
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

# --- Simülatörler -----------------------------------------------------------
pick() { # $1: ad deseni → en yeni iOS çalışma ortamındaki ilk eşleşen cihazın UDID'si
  xcrun simctl list devices available -j | python3 -c "
import json, sys, re
d = json.load(sys.stdin)['devices']
runtimes = sorted((r for r in d if 'iOS' in r), key=lambda r: [int(x) for x in re.findall(r'\d+', r)], reverse=True)
for r in runtimes:
    for x in d[r]:
        if re.search(sys.argv[1], x['name']):
            print(x['udid'], x['name'], sep='|'); sys.exit()
" "$1"
}
SMALL="$(pick 'iPhone SE')"
LARGE="$(pick 'iPhone .* Pro Max')"
[ -n "$SMALL" ] && [ -n "$LARGE" ] || { echo "Simülatör bulunamadı (SE / Pro Max)." >&2; exit 1; }
echo "Küçük: ${SMALL#*|} · Büyük: ${LARGE#*|}"

# --- Derleme ----------------------------------------------------------------
xcodebuild build \
  -project MagicPaper.xcodeproj -scheme MagicPaper -configuration Debug \
  -destination "id=${SMALL%%|*}" -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO | tail -n 25
APP="$(find "$DERIVED/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name '*.app' | head -1)"
[ -d "$APP" ] || { echo "Derlenen .app bulunamadı." >&2; exit 1; }

# --- Ekran listesi: ad | başlık | açılış argümanları ------------------------
SCREENS=(
  "ana-sayfa|Ana sayfa|-mpStartTab home"
  "masallar|Masallar|-mpStartTab gunluk"
  "kitaplik|Kitaplık|-mpStartTab library"
  "profil|Profil|-mpStartTab corner"
  "buyukler-icin|Büyükler için|-mpStartParent YES"
  "ayarlar|Ayarlar|-mpStartParent YES -mpParentTab settings"
  "abonelik|Abonelik (Paywall)|-mpStartParent YES -mpOpenPaywall YES"
  "tasarim-katalogu|Tasarım sistemi kataloğu|-mpDesignSystemCatalog YES"
)
SIZES=("normal|large" "en-buyuk-yazi|accessibility-extra-extra-extra-large")

rm -rf "$OUT" && mkdir -p "$OUT"
MANIFEST="$OUT/../shots.js"
echo "window.MP_SHOTS = { tarih: \"$(date -u +%Y-%m-%dT%H:%MZ)\", commit: \"$(git rev-parse --short HEAD 2>/dev/null || echo yerel)\", liste: [" > "$MANIFEST"

for DEV in "$SMALL" "$LARGE"; do
  UDID="${DEV%%|*}"; NAME="${DEV#*|}"
  KIND=$([ "$DEV" = "$SMALL" ] && echo kucuk || echo buyuk)
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b >/dev/null
  xcrun simctl ui "$UDID" appearance light
  xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --wifiBars 3 || true
  xcrun simctl install "$UDID" "$APP"
  for SIZE in "${SIZES[@]}"; do
    xcrun simctl ui "$UDID" content_size "${SIZE#*|}"
    for S in "${SCREENS[@]}"; do
      IFS='|' read -r ID TITLE ARGS <<< "$S"
      FILE="$ID.$KIND.${SIZE%%|*}.png"
      # shellcheck disable=SC2086
      xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" \
        -mpDemo YES -mpDemoLibrary YES -mp_approveBeforeShow NO $ARGS >/dev/null
      sleep "$WAIT"
      xcrun simctl io "$UDID" screenshot --type=png "$OUT/$FILE" >/dev/null 2>&1
      echo "  {ekran:\"$ID\", baslik:\"$TITLE\", cihaz:\"$KIND\", cihazAdi:\"$NAME\", yazi:\"${SIZE%%|*}\", dosya:\"screens/real/$FILE\"}," >> "$MANIFEST"
      echo "✓ $NAME · ${SIZE%%|*} · $TITLE"
    done
  done
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl shutdown "$UDID" || true
done
echo "]};" >> "$MANIFEST"

# Depo şişmesin: görüntüler yarı boyuta indirilir (sips macOS'ta hazır).
for f in "$OUT"/*.png; do
  w=$(sips -g pixelWidth "$f" | awk '/pixelWidth/{print $2}')
  sips --resampleWidth $((w / 2)) "$f" >/dev/null
done
echo "Bitti: $(ls "$OUT" | wc -l | tr -d ' ') görüntü → $OUT"

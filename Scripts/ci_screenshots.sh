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
WAIT="${WAIT:-10}"  # açılış karşılaması (Batuhan, 21 Kasım) 7 sn'ye sığmıyor

cd "$ROOT"

# --- Depoda olmayan dosyalar ------------------------------------------------
BUNDLE="$BUNDLE" bash "$ROOT/Scripts/ci_placeholders.sh"

# --- Simülatörler -----------------------------------------------------------
# $1: cihaz türü desenleri (| ile, sırayla denenir). Önce var olan bir simülatör
# aranır; yoksa en yeni iOS çalışma ortamında o türden yenisi oluşturulur.
# Yeni Xcode'larda hazır "iPhone SE" gelmeyebilir; o zaman "e" modeli (16e, 17e).
pick() {
  python3 - "$1" <<'PY'
import json, subprocess, sys, re
def j(*a): return json.loads(subprocess.check_output(["xcrun", "simctl", "list", *a, "-j"]))
patterns = sys.argv[1].split("|")
ver = lambda s: [int(x) for x in re.findall(r"\d+", s)]
runtimes = sorted((r for r in j("runtimes")["runtimes"] if r["platform"] == "iOS" and r["isAvailable"]),
                  key=lambda r: ver(r["version"]), reverse=True)
if not runtimes: sys.exit("iOS çalışma ortamı yok")
devices = j("devices", "available")["devices"]
types = j("devicetypes")["devicetypes"]
for pat in patterns:
    for rt in runtimes:
        for d in devices.get(rt["identifier"], []):
            if re.search(pat, d["name"]):
                print(d["udid"] + "|" + d["name"]); sys.exit()
    for t in sorted(types, key=lambda t: ver(t["identifier"]), reverse=True):
        if re.search(pat, t["name"]):
            try:  # tür bu iOS sürümünü desteklemiyorsa sıradaki desene geç
                udid = subprocess.check_output(["xcrun", "simctl", "create", t["name"], t["identifier"],
                                                runtimes[0]["identifier"]], stderr=subprocess.DEVNULL).decode().strip()
            except subprocess.CalledProcessError:
                break
            print(udid + "|" + t["name"]); sys.exit()
PY
}
SMALL="$(pick '^iPhone SE|^iPhone 1[0-9]e$|^iPhone 1[0-9]$')" || true
LARGE="$(pick 'Pro Max$|Plus$')" || true
if [ -z "$SMALL" ] || [ -z "$LARGE" ]; then
  echo "Simülatör bulunamadı (küçük: '$SMALL', büyük: '$LARGE'). Mevcut olanlar:" >&2
  xcrun simctl list runtimes >&2; xcrun simctl list devices available >&2
  exit 1
fi
echo "Küçük: ${SMALL#*|} · Büyük: ${LARGE#*|}"

# --- Derleme ----------------------------------------------------------------
# Tam derleme günlüğü dala yazılır; hata satırları ayrıca özetlenir.
BUILD_LOG="$ROOT/design-preview/screens/derleme-gunlugu.txt"
mkdir -p "$(dirname "$BUILD_LOG")"
xcodebuild -version
if ! xcodebuild build \
  -project MagicPaper.xcodeproj -scheme MagicPaper -configuration Debug \
  -destination "id=${SMALL%%|*}" -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO > "$BUILD_LOG" 2>&1; then
  echo "DERLEME BAŞARISIZ. Hatalar:"
  grep -E "error:|fatal error|\*\* BUILD FAILED" "$BUILD_LOG" | sort -u | head -80
  # GitHub açıklaması: herkese açık API'den girişsiz okunur (ilk 10 hata).
  grep -E "error:" "$BUILD_LOG" | sed "s#$ROOT/##" | sort -u | head -10 | sed 's/^/::error::/'
  exit 65
fi
tail -n 5 "$BUILD_LOG"
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
  "profil-avatar|Profilini düzenle (avatar)|-mpStartTab corner -mpOpenAvatarPicker YES"
  "menu|Menü|-mpStartTab home -mpOpenMenu YES"
  "okuma-yolculugu|Okuma yolculuğum|-mpStartTab home -mpOpenJourney YES"
  "rozetlerim|Rozetlerim|-mpStartTab home -mpDemoLibrary YES -mpOpenKidPage badges"
  "cikartma-albumu|Çıkartma albümüm|-mpStartTab home -mpDemoLibrary YES -mpOpenKidPage stickers"
  "yeni-kelimeler|Yeni kelimelerim|-mpStartTab home -mpDemoLibrary YES -mpOpenKidPage newWords"
  "masal-haritam|Masal haritam|-mpStartTab home -mpDemoLibrary YES -mpOpenKidPage storyMap"
  "masal-ailem|Masal ailem|-mpStartTab home -mpDemoLibrary YES -mpOpenKidPage family"
  "kitaplik-renklerim|Kitaplık renklerim|-mpStartTab home -mpDemoLibrary YES -mpOpenKidPage decor"
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
      # Boş (beyaz) görüntü çok iyi sıkışır: tam çözünürlükte 100 KB altı = henüz çizilmemiş.
      # İki kez daha bekleyip dener; hâlâ boşsa gerçek bir boş ekran olabilir, günlüğe yazar.
      for TRY in 1 2; do
        [ "$(stat -f %z "$OUT/$FILE")" -ge 100000 ] && break
        sleep "$WAIT"
        xcrun simctl io "$UDID" screenshot --type=png "$OUT/$FILE" >/dev/null 2>&1
      done
      if [ "$(stat -f %z "$OUT/$FILE")" -lt 100000 ]; then
        echo "::warning::BOŞ EKRAN: $NAME · ${SIZE%%|*} · $TITLE (3 denemede de boş)"
      fi
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

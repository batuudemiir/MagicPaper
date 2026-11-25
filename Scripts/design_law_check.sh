#!/bin/bash
# Tasarım yasası denetimi (AGENTS.md > Design law > Doğrulama), 25 Kasım 2026.
#
# AGENTS.md'deki altı grep'i tek yerde koşar. İsabet varsa hepsini yazar ve
# 1 ile çıkar. Bilinçli istisnalar Scripts/design_law_allowlist.txt'te.
# CI: .github/workflows/design-law.yml (her PR'da, Linux'ta, saniyeler sürer).
# Yerelde: Scripts/design_law_check.sh
set -uo pipefail
shopt -s lastpipe  # report son komut olarak bu kabukta koşar; fail görünür

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ALLOW="$ROOT/Scripts/design_law_allowlist.txt"
cd "$ROOT"

# İzinli dosyalar: "<kural> <yol>" satırları.
allowed() { # $1 kural, $2 yol
  grep -qxF "$1 $2" <(grep -vE '^\s*(#|$)' "$ALLOW" | sed -E 's/[[:space:]]+/ /g; s/ $//')
}

SW=(--include='*.swift' MagicPaper)
fail=0

report() { # $1 kural, $2 açıklama; stdin: grep -n çıktısı (yol:satır:metin)
  local rule="$1" desc="$2" hits="" line path
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    path="${line%%:*}"
    allowed "$rule" "$path" && continue
    hits+="$line"$'\n'
  done
  if [ -n "$hits" ]; then
    fail=1
    printf '\n✗ %s: %s\n' "$rule" "$desc"
    printf '%s' "$hits" | sed 's/^/  /'
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
      printf '%s' "$hits" | while IFS= read -r l; do
        f="${l%%:*}"; rest="${l#*:}"; n="${rest%%:*}"
        echo "::error file=$f,line=$n::Tasarım yasası ($rule): $desc"
      done
    fi
  else
    printf '✓ %s\n' "$rule"
  fi
}

grep -rn "Color(hex:" "${SW[@]}" | grep -v -e MPTheme.swift -e MagicPaperCoverPalette.swift \
  | report renk "Color(hex:) yalnızca MP.Palette içinde (MPTheme.swift)"

grep -rn "\.shadow(" "${SW[@]}" | grep -v "func mpShadow" \
  | report golge "Gölge yalnızca mpShadow(MP.Sh.*)"

grep -rnE "\.padding\((\.[a-z]+, )?[0-9]" "${SW[@]}" \
  | report bosluk "Boşluk yalnızca MP.S; çıplak sayı yok"

grep -rn "fixedSize:" "${SW[@]}" \
  | report font ".custom(_:fixedSize:) yok (Dynamic Type'ı öldürür)"

grep -rn -e "UIImpactFeedbackGenerator" -e "sensoryFeedback" "${SW[@]}" | grep -v MPHaptics.swift \
  | report titresim "Titreşim yalnızca MPHaptics üzerinden"

grep -rnE "\"[^\"]*([Üü]ret|[Oo]luştur|saniyeler içinde|anında|[Yy]apay zeka)[^\"]*\"" "${SW[@]}" \
  | grep -v -e "///" -e "#Preview" -e "print(" -e "logger\." -e "[Pp]rofil" -e PDF -e "[Dd]avet" -e hesab \
  | report dil "Masal yazılır; 'üretilir/oluşturulur', hız vaadi ve 'yapay zeka' yok"

if [ "$fail" -ne 0 ]; then
  echo
  echo "Tasarım yasası ihlali var. Kural: AGENTS.md > Design law. Bilinçli istisna: $ALLOW"
  exit 1
fi
echo "Tasarım yasası temiz."

"""MagicPaper Original kapağını SVG'den JPEG'e çevirir (karar: 12 Kasım 2026, Batuhan:
kapakları Gemini değil Claude çizer).

    python3 Tools/render_cover.py <slug>

Girdi: Content/Originals/drafts/<slug>/cover.svg (viewBox 0 0 1125 1500, 3:4, yazı yok).
Çıktı: aynı klasörde cover.jpg (1125 × 1500, JPEG). Yalnız macOS araçları: qlmanage
(WebKit ile SVG çizer, SVG filtreleri dahil) ve sips. Ağ yok, anahtar yok.

qlmanage kare çıktı verir ve dikey resmi kırpar; bu yüzden SVG 2000 × 2000'lik bir
kareye ortalanır, çizilir, sonra ortadan 1500 × 2000 kırpılıp 1125 × 1500'e indirilir.
"""

import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
DRAFTS = ROOT / "Content" / "Originals" / "drafts"
WIDTH, HEIGHT = 1125, 1500
SQUARE = 2000


def wrap(svg_text):
    """Dikey SVG'yi kare bir tuvalin ortasına yerleştirir."""
    inner = re.sub(r"<\?xml[^>]*\?>", "", svg_text).strip()
    box_w = SQUARE * WIDTH // HEIGHT
    offset = (SQUARE - box_w) // 2
    inner = re.sub(r"<svg\b", f'<svg x="{offset}" y="0" width="{box_w}" height="{SQUARE}"', inner, count=1)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            f'width="{SQUARE}" height="{SQUARE}" viewBox="0 0 {SQUARE} {SQUARE}">{inner}</svg>')


def render(svg_path, jpg_path):
    with tempfile.TemporaryDirectory() as temp:
        square = pathlib.Path(temp) / "cover.svg"
        text = svg_path.read_text(encoding="utf-8")
        # İç svg'nin kendi width/height'i wrap'in verdiğiyle çakışmasın.
        text = re.sub(r"<svg\b[^>]*>", lambda m: re.sub(r'\s(width|height)="[^"]*"', "", m.group(0)),
                      text, count=1)
        square.write_text(wrap(text), encoding="utf-8")
        subprocess.run(["qlmanage", "-t", "-s", str(SQUARE), "-o", temp, str(square)],
                       check=True, capture_output=True)
        png = pathlib.Path(temp) / "cover.svg.png"
        if not png.exists():
            raise RuntimeError("qlmanage çıktı vermedi (SVG geçersiz olabilir)")
        crop_w = SQUARE * WIDTH // HEIGHT
        subprocess.run(["sips", "-c", str(SQUARE), str(crop_w), str(png)], check=True, capture_output=True)
        subprocess.run(["sips", "-z", str(HEIGHT), str(WIDTH), "-s", "format", "jpeg", "-s", "formatOptions", "84",
                        str(png), "--out", str(jpg_path)], check=True, capture_output=True)


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 2
    slug = argv[1]
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", slug):
        print(f"HATA: geçersiz slug: {slug}", file=sys.stderr)
        return 2
    folder = DRAFTS / slug
    svg = folder / "cover.svg"
    if not svg.exists():
        print(f"HATA: {svg} yok", file=sys.stderr)
        return 1
    if not shutil.which("qlmanage"):
        print("HATA: qlmanage yok (yalnız macOS)", file=sys.stderr)
        return 1
    jpg = folder / "cover.jpg"
    render(svg, jpg)
    print(f"Kapak yazıldı: {jpg} ({jpg.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

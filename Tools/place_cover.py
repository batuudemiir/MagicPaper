"""Batuhan'ın ChatGPT'den getirdiği kapağı bir MagicPaper Original taslağına yerleştirir
(karar: 16 Kasım 2026: kapak promptunu ajan yazar, görseli Batuhan ChatGPT'de üretir).

    python3 Tools/place_cover.py <slug> <görsel>

Görsel (PNG, JPEG, WebP, HEIC) ortadan 3:4'e kırpılır, 1125 × 1500 JPEG olarak
Content/Originals/drafts/<slug>/cover.jpg'ye yazılır. Taslak yoksa published/<slug>/ denenir
(yayımlanmış bir masalın kapağını değiştirmek için; sonra katalog derleyicisi yeniden çalıştırılır).
Ardından `stamp_originals_logo.py` MagicPaper Originals logosunu kapağın üstüne basar (19 Kasım 2026).
Kırpma macOS sips ile, logo Pillow ile; ağ yok.
"""

import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
ORIGINALS = ROOT / "Content" / "Originals"
WIDTH, HEIGHT = 1125, 1500


def crop_box(width, height):
    """Ortadan 3:4'lük en büyük kırpım: (yükseklik, genişlik)."""
    if width * 4 > height * 3:  # fazla geniş: yanlardan kırp
        return height, height * 3 // 4
    return width * 4 // 3, width  # fazla uzun: üstten ve alttan kırp


def size_of(path):
    out = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
                         check=True, capture_output=True, text=True).stdout
    w = int(re.search(r"pixelWidth: (\d+)", out).group(1))
    h = int(re.search(r"pixelHeight: (\d+)", out).group(1))
    return w, h


def place(src, dst):
    with tempfile.TemporaryDirectory() as temp:
        work = pathlib.Path(temp) / "cover.png"
        subprocess.run(["sips", "-s", "format", "png", str(src), "--out", str(work)], check=True, capture_output=True)
        h, w = crop_box(*size_of(work))
        subprocess.run(["sips", "-c", str(h), str(w), str(work)], check=True, capture_output=True)
        subprocess.run(["sips", "-z", str(HEIGHT), str(WIDTH), "-s", "format", "jpeg", "-s", "formatOptions", "85",
                        str(work), "--out", str(dst)], check=True, capture_output=True)


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    slug, src = argv[1], pathlib.Path(argv[2]).expanduser()
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", slug):
        print(f"HATA: geçersiz slug: {slug}", file=sys.stderr)
        return 2
    if not src.exists():
        print(f"HATA: görsel yok: {src}", file=sys.stderr)
        return 1
    folder = next((f for f in (ORIGINALS / "drafts" / slug, ORIGINALS / "published" / slug) if f.is_dir()), None)
    if folder is None:
        print(f"HATA: drafts/{slug} ya da published/{slug} yok", file=sys.stderr)
        return 1
    dst = folder / "cover.jpg"
    place(src, dst)
    print(f"Kapak yazıldı: {dst.relative_to(ROOT)} ({dst.stat().st_size // 1024} KB, {WIDTH} × {HEIGHT})")
    # Her Original kapağı MagicPaper Originals logosunu taşır (karar: 19 Kasım 2026, Batuhan).
    stamp = subprocess.run([sys.executable, str(ROOT / "Tools" / "stamp_originals_logo.py"), str(dst)])
    return stamp.returncode


if __name__ == "__main__":
    sys.exit(main(sys.argv))

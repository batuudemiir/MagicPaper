"""MagicPaper Originals logosunu bir Original kapağının üstüne basar (karar: 19 Kasım 2026, Batuhan).

    python3 Tools/stamp_originals_logo.py <cover.jpg> [<cover.jpg> ...]

Logo kapağın üst ortasına, sakin gökyüzü alanına konur: genişliği kapağın %40'ı, üstten %5.
Zemin koyuysa krem (#FFF8EE), açıksa mürekkep (#2E1E3E); arkasında aynı biçimde hafif bir
karartma/aydınlatma halesi, ağaç ya da kubbe üstüne gelirse de okunsun diye.
Dosyanın yerine yazar. Aynı kapağa iki kez basma: `place_cover.py` her seferinde ChatGPT'den gelen
temiz görselden başlar ve bunu kendisi çağırır. Logo: Content/Originals/brand/originals-logo.png
(tek renk, şeffaf zemin). Gereken: Pillow (`python3 -m pip install Pillow`).
"""

import pathlib
import sys

try:
    from PIL import Image, ImageFilter, ImageStat
except ImportError:
    sys.exit("Pillow yok: python3 -m pip install Pillow")

ROOT = pathlib.Path(__file__).resolve().parent.parent
LOGO = ROOT / "Content" / "Originals" / "brand" / "originals-logo.png"
CREAM = (0xFF, 0xF8, 0xEE)
INK = (0x2E, 0x1E, 0x3E)
WIDTH_RATIO = 0.40
TOP_RATIO = 0.05
HALO_OPACITY = 0.45
QUALITY = 85  # place_cover.py ile aynı
MAX_BYTES = 1500 * 1024


def stamp(path):
    cover = Image.open(path).convert("RGB")
    W, H = cover.size
    alpha = Image.open(LOGO).getchannel("A")
    w = round(W * WIDTH_RATIO)
    h = round(alpha.height * w / alpha.width)
    alpha = alpha.resize((w, h), Image.LANCZOS)
    x, y = (W - w) // 2, round(H * TOP_RATIO)

    region = cover.crop((x, y, x + w, y + h)).convert("L")
    dark = ImageStat.Stat(region).mean[0] < 140
    color, halo_color = (CREAM, INK) if dark else (INK, CREAM)

    radius = max(4, w // 40)
    halo = alpha.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(radius))
    halo = halo.point(lambda v: round(v * HALO_OPACITY))
    cover.paste(Image.new("RGB", (w, h), halo_color), (x, y), halo)
    cover.paste(Image.new("RGB", (w, h), color), (x, y), alpha)

    quality = QUALITY
    while True:
        cover.save(path, "JPEG", quality=quality, optimize=True, progressive=True)
        if path.stat().st_size <= MAX_BYTES or quality <= 70:
            break
        quality -= 5
    tone = "krem" if dark else "mürekkep"
    print(f"Logo basıldı ({tone}): {path} ({path.stat().st_size // 1024} KB)")


def main(args):
    if not args:
        sys.exit(__doc__)
    if not LOGO.exists():
        sys.exit(f"Logo yok: {LOGO}")
    for arg in args:
        path = pathlib.Path(arg)
        if not path.exists():
            sys.exit(f"Kapak yok: {path}")
        stamp(path)


if __name__ == "__main__":
    main(sys.argv[1:])

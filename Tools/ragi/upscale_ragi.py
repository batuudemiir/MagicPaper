#!/usr/bin/env python3
"""Ragi pozlarını 4 kat büyütür: boyalı çizim aynı kalır, netlik artar.

Kaynak her zaman özgün kesimler (design-handoff/assets/brand/mascot*.png), böylece
yeniden çalıştırmak üst üste büyütmez. Renk cihaz içi süper çözünürlükten
(`superres.swift`), saydamlık Lanczos + kenar sıkılaştırmadan gelir.

    swiftc -O Tools/ragi/superres.swift -o /tmp/superres
    python3 Tools/ragi/upscale_ragi.py /tmp/superres
"""
import glob
import os
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
SOURCE = os.path.join(ROOT, "design-handoff", "assets", "brand")
CATALOG = os.path.join(ROOT, "MagicPaper", "Assets.xcassets", "Brand")
FACTOR, MIN_SIDE, MARGIN = 4, 512, 40
PAPER = (253, 246, 238)


def upscale(path, tool, scratch):
    image = Image.open(path).convert("RGBA")
    w, h = image.size
    canvas_w, canvas_h = max(w + MARGIN * 2, MIN_SIDE), max(h + MARGIN * 2, MIN_SIDE)
    x, y = (canvas_w - w) // 2, (canvas_h - h) // 2
    flat = Image.new("RGB", (canvas_w, canvas_h), PAPER)
    flat.paste(image, (x, y), image)
    source, result = os.path.join(scratch, "in.png"), os.path.join(scratch, "out.png")
    flat.save(source)
    subprocess.run([tool, source, result], check=True, capture_output=True)
    box = (x * FACTOR, y * FACTOR, (x + w) * FACTOR, (y + h) * FACTOR)
    color = Image.open(result).convert("RGB").crop(box)
    alpha = np.asarray(image.getchannel("A").resize(color.size, Image.LANCZOS), dtype=float) / 255
    # Bulanık kenarı sık: zemin rengi çizimin çevresinde hale bırakmasın.
    alpha = np.clip((alpha - 0.42) / 0.36, 0, 1)
    alpha = alpha * alpha * (3 - 2 * alpha)
    out = color.convert("RGBA")
    out.putalpha(Image.fromarray((alpha * 255).astype(np.uint8)))
    return out


def main():
    tool = sys.argv[1]
    with tempfile.TemporaryDirectory() as scratch:
        for path in sorted(glob.glob(os.path.join(SOURCE, "mascot*.png"))):
            name = os.path.splitext(os.path.basename(path))[0]
            out = upscale(path, tool, scratch)
            out.save(os.path.join(CATALOG, f"{name}.imageset", f"{name}.png"), optimize=True)
            print(name, out.size)


if __name__ == "__main__":
    main()

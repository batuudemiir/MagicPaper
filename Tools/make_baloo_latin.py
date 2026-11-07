#!/usr/bin/env python3
"""Baloo 2'nin uygulamaya giren kopyasını üretir (Faz 1, docs/MARKA.md).

Özgün dosyanın satır kutusu 1,60 em: Devanagari için ayrılan pay. Latin başlıkta
34 pt başlık 54 pt yer kaplar ve boşlukta yüzer. Bu kopya yalnızca Latin alfabesini
tutar ve satır kutusunu 1,20 em yapar. 900 / -300, en yüksek Türkçe harfi (Â 814)
ve en alçak harfi (g -202) keser olmadan taşır, büyük harfi kutuda ortalar.

Lisans SIL OFL 1.1, ayrılmış ad yok: değiştirilmiş kopya aynı adla dağıtılabilir.
Telif ve lisans kayıtları `name` tablosunda korunur.

Özgün dosya git geçmişinde:
    git show 6ca00d2^:MagicPaper/DesignSystem/Fonts/Baloo2-Variable.ttf > Baloo2-Variable.ttf
    python3 Tools/make_baloo_latin.py Baloo2-Variable.ttf MagicPaper/DesignSystem/Fonts/Baloo2-Latin-Variable.ttf
"""
import sys

from fontTools import subset
from fontTools.ttLib import TTFont

ASCENT, DESCENT = 900, -300
UNICODES = [*range(0x20, 0x7F), *range(0xA0, 0x180), 0x2013, 0x2014, 0x2018, 0x2019,
            0x201C, 0x201D, 0x2022, 0x2026, 0x20BA]


def main(source, target):
    font = TTFont(source)
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=UNICODES)
    subsetter.subset(font)

    font["hhea"].ascent, font["hhea"].descent, font["hhea"].lineGap = ASCENT, DESCENT, 0
    os2 = font["OS/2"]
    os2.sTypoAscender, os2.sTypoDescender, os2.sTypoLineGap = ASCENT, DESCENT, 0
    os2.usWinAscent, os2.usWinDescent = ASCENT, -DESCENT
    os2.fsSelection |= 1 << 7  # USE_TYPO_METRICS
    font.save(target)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])

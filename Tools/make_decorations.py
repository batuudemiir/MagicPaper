"""MagicPaper Kids — dekoratif varlık üreticisi.

Neden burada: serbest lisanslı, tutarlı bir çocuk kitabı spot-illüstrasyon
kütüphanesi hazır hâlde yok. Wikimedia'daki çocuk kitabı taramaları tam sahne
ve karakter; tipografik ornamentler klasik matbaa dili. Brief §35 bu durumda
MagicPaper'a özgü varlık üretmeyi söylüyor.

Çizim burada, uygulamada değil (§34): çıktı PNG. SwiftUI yalnızca yerleştirir.
Mürekkep konturu + yumuşak iç ton, hafif asimetri, konik uçlar.
"""
from PIL import Image, ImageDraw, ImageFilter
import math, os, random

SS = 4                      # supersampling
INK = (0x3B, 0x2E, 0x34)
OUT = "Assets/Storybook/Decorations"

def canvas(w, h):
    return Image.new("RGBA", (w*SS, h*SS), (0, 0, 0, 0))

def finish(im, w, h, name, folder):
    im = im.resize((w, h), Image.LANCZOS)
    d = os.path.join(OUT, folder)
    os.makedirs(d, exist_ok=True)
    p = os.path.join(d, name + ".png")
    im.save(p)
    return p

def taper(dr, pts, w0, w1, color, alpha=255):
    """Konik kalınlıkta organik çizgi: uçları incelen fırça izi."""
    n = len(pts)
    for i in range(n - 1):
        t = i / max(n - 2, 1)
        w = (w0 + (w1 - w0) * t) * SS
        dr.line([pts[i], pts[i+1]], fill=color + (alpha,), width=max(int(w), 1))
        dr.ellipse([pts[i][0]-w/2, pts[i][1]-w/2, pts[i][0]+w/2, pts[i][1]+w/2],
                   fill=color + (alpha,))

def curve(x0, y0, x1, y1, bend, steps=40):
    """İki nokta arası yay — bend kadar dışa kıvrık."""
    mx, my = (x0+x1)/2, (y0+y1)/2
    dx, dy = x1-x0, y1-y0
    L = math.hypot(dx, dy) or 1
    cx, cy = mx - dy/L*bend, my + dx/L*bend
    return [(
        (1-t)**2*x0 + 2*(1-t)*t*cx + t*t*x1,
        (1-t)**2*y0 + 2*(1-t)*t*cy + t*t*y1
    ) for t in (i/steps for i in range(steps+1))]

def leaf(dr, x, y, length, angle, width=0.34, alpha=235):
    """Damarlı yaprak: iki yay, ortada orta damar."""
    a = math.radians(angle)
    tx, ty = x + math.cos(a)*length*SS, y + math.sin(a)*length*SS
    b = length*SS*width
    left  = curve(x, y, tx, ty,  b)
    right = curve(x, y, tx, ty, -b)
    dr.polygon(left + right[::-1], fill=INK + (int(alpha*0.22),))
    taper(dr, left,  1.5, 0.7, INK, alpha)
    taper(dr, right, 1.5, 0.7, INK, alpha)
    taper(dr, [(x, y), (tx, ty)], 1.2, 0.5, INK, int(alpha*0.7))

def blob(dr, cx, cy, r, wobble=0.16, alpha=220, fill=0.25, seed=0):
    """Hafif düzensiz yuvarlak — mantar şapkası, taş, kabarcık."""
    rnd = random.Random(seed)
    pts = []
    for i in range(48):
        t = i/48*2*math.pi
        rr = r*SS*(1 + math.sin(t*3+seed)*wobble*0.5 + rnd.uniform(-wobble, wobble)*0.3)
        pts.append((cx + math.cos(t)*rr, cy + math.sin(t)*rr))
    dr.polygon(pts, fill=INK + (int(alpha*fill),))
    taper(dr, pts + [pts[0]], 1.3, 1.3, INK, alpha)

def star(dr, cx, cy, r, points=4, alpha=230, sharp=0.38):
    pts = []
    for i in range(points*2):
        t = i/(points*2)*2*math.pi - math.pi/2
        rr = r*SS if i % 2 == 0 else r*SS*sharp
        pts.append((cx+math.cos(t)*rr, cy+math.sin(t)*rr))
    dr.polygon(pts, fill=INK + (alpha,))

# ---------------------------------------------------------------- FOREST

def forest_grass_cluster_01(w=200, h=120):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    base = h*S - 5*S

    def blade(x, ln, lean, wt):
        """Tabandan dik çıkıp ucunda yana yatan bıçak.

        Önceki hâl `curve`'ün dik açılı bükümünü kullanıyordu; neredeyse dikey
        bir çizgide bu, bıçağı U'ya çevirip tutamı çeşme gibi gösteriyordu.
        Kontrol noktası artık tabanın hemen üstünde, böylece bıçak dik
        başlayıp yalnızca ucunda yumuşakça yatıyor.
        """
        x0, y0 = x*S, base
        x2, y2 = (x+lean)*S, base - ln*S
        x1, y1 = (x + lean*0.15)*S, base - ln*S*0.55
        pts = [((1-t)**2*x0 + 2*(1-t)*t*x1 + t*t*x2,
                (1-t)**2*y0 + 2*(1-t)*t*y1 + t*t*y2)
               for t in (i/30 for i in range(31))]
        taper(dr, pts, wt, 0.3, INK, 236)

    for x, ln, lean, wt in [(62,50,-16,2.0),(74,80,-10,2.6),(86,108,-4,3.0),
                            (98,66,4,2.2),(106,122,1,2.9),(118,88,9,2.5),
                            (130,58,16,2.0),(142,38,21,1.6),(80,32,-20,1.4),
                            (124,30,18,1.4)]:
        blade(x, ln, lean, wt)
    taper(dr, curve(52*S, base, 152*S, base, 2*S), 1.5, 1.5, INK, 120)
    return finish(im, w, h, "forest_grass_cluster_01", "Forest")

def forest_branch_corner_01(w=230, h=190):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    stem = curve(-6*S, 12*S, 206*S, 150*S, 46*S, 60)
    taper(dr, stem, 5.0, 1.4, INK, 240)
    for t, ang, ln in [(0.18,-52,40),(0.30,34,34),(0.44,-44,44),
                       (0.58,30,36),(0.72,-38,32),(0.86,26,26)]:
        px, py = stem[int(t*len(stem))]
        leaf(dr, px, py, ln, ang)
    return finish(im, w, h, "forest_branch_corner_01", "Forest")

def forest_mushroom_pair_01(w=160, h=130):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    base = h*S - 6*S

    def shroom(cx, capw, caph, stemh, stemw, seed):
        # Gövde: ince, hafif eğri.
        stem = curve(cx*S, base, (cx+2)*S, base-stemh*S, 3*S, 24)
        dr.polygon([(p[0]-stemw*S/2, p[1]) for p in stem] +
                   [(p[0]+stemw*S/2, p[1]) for p in reversed(stem)],
                   fill=INK+(42,))
        taper(dr, [(p[0]-stemw*S/2, p[1]) for p in stem], 1.3, 1.0, INK, 228)
        taper(dr, [(p[0]+stemw*S/2, p[1]) for p in stem], 1.3, 1.0, INK, 228)
        # Şapka: kenarları aşağı sarkan şemsiye, tam yarım daire değil.
        top = base - stemh*S
        left  = (cx - capw/2)*S
        right = (cx + capw/2)*S
        arc = curve(left, top+3*S, right, top+3*S, -caph*S, 44)
        skirt = curve(left, top+3*S, right, top+3*S, -caph*S*0.30, 44)
        dr.polygon(arc + skirt[::-1], fill=INK+(60,))
        taper(dr, arc, 2.0, 2.0, INK, 240)
        taper(dr, skirt, 1.2, 1.2, INK, 190)
        # Şapka benekleri — mantarı mantar yapan şey.
        rnd = random.Random(seed)
        for _ in range(4):
            t = rnd.uniform(0.22, 0.78)
            px, py = arc[int(t*len(arc))]
            r = rnd.uniform(2.0, 3.4)
            blob(dr, px, py + caph*S*0.30, r, 0.10, 170, 0.75, seed=int(t*100))

    shroom(58, 46, 30, 36, 9, 3)
    shroom(112, 28, 18, 22, 6, 11)
    taper(dr, curve(24*S, base, 144*S, base, 3*S), 1.5, 1.5, INK, 130)
    return finish(im, w, h, "forest_mushroom_pair_01", "Forest")

def forest_leaf_cluster_01(w=170, h=120):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    for x, y, ln, ang in [(34,84,54,-28),(78,96,62,-8),(126,88,48,18)]:
        leaf(dr, x*S, y*S, ln, ang)
    return finish(im, w, h, "forest_leaf_cluster_01", "Forest")

# ---------------------------------------------------------------- GARDEN

def garden_flower_cluster_01(w=170, h=150):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    base = h*S - 4*S
    for x, ln, r, seed in [(50,96,15,1),(88,120,18,4),(124,84,13,9)]:
        st = curve(x*S, base, x*S+6*S, base-ln*S, 8*S)
        taper(dr, st, 2.4, 1.0, INK, 235)
        hx, hy = st[-1]
        for k in range(6):
            a = k/6*2*math.pi + seed
            blob(dr, hx+math.cos(a)*r*S*0.9, hy+math.sin(a)*r*S*0.9,
                 r*0.52, 0.18, 210, 0.30, seed=seed*10+k)
        blob(dr, hx, hy, r*0.36, 0.10, 240, 0.55, seed=seed)
    for x, y, ln, ang in [(36,base/S-22,34,-24),(132,base/S-18,30,16)]:
        leaf(dr, x*S, y*S, ln, ang, 0.40, 210)
    return finish(im, w, h, "garden_flower_cluster_01", "Garden")

def garden_butterfly_01(w=120, h=100):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    cx, cy = 60*S, 54*S
    for sx in (-1, 1):
        upper = [(cx, cy)] + curve(cx, cy, cx+sx*40*S, cy-30*S, sx*18*S)[1:] + \
                curve(cx+sx*40*S, cy-30*S, cx, cy, sx*16*S)[1:]
        dr.polygon(upper, fill=INK+(58,))
        taper(dr, upper, 1.5, 1.5, INK, 235)
        lower = [(cx, cy)] + curve(cx, cy, cx+sx*28*S, cy+26*S, -sx*14*S)[1:] + \
                curve(cx+sx*28*S, cy+26*S, cx, cy, -sx*10*S)[1:]
        dr.polygon(lower, fill=INK+(44,))
        taper(dr, lower, 1.3, 1.3, INK, 225)
    taper(dr, [(cx, cy-16*S), (cx, cy+18*S)], 2.6, 1.4, INK, 245)
    taper(dr, curve(cx, cy-16*S, cx-11*S, cy-30*S, 4*S), 1.1, 0.5, INK, 230)
    taper(dr, curve(cx, cy-16*S, cx+11*S, cy-30*S, -4*S), 1.1, 0.5, INK, 230)
    return finish(im, w, h, "garden_butterfly_01", "Garden")

def garden_vine_edge_01(w=120, h=240):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    stem = curve(14*S, -8*S, 52*S, 244*S, 34*S, 70)
    taper(dr, stem, 3.4, 1.2, INK, 238)
    for t, ang, ln in [(0.12,-40,30),(0.26,44,26),(0.40,-34,32),
                       (0.55,40,28),(0.70,-42,26),(0.84,36,22)]:
        px, py = stem[int(t*len(stem))]
        leaf(dr, px, py, ln, ang, 0.38, 220)
    return finish(im, w, h, "garden_vine_edge_01", "Garden")

# ---------------------------------------------------------------- SKY

def sky_cloud_small_01(w=190, h=100):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    for cx, cy, r, sd in [(60,62,26,2),(96,50,34,5),(134,64,24,8)]:
        blob(dr, cx*S, cy*S, r, 0.08, 205, 0.20, seed=sd)
    taper(dr, curve(30*S, 78*S, 162*S, 78*S, -6*S), 1.8, 1.8, INK, 190)
    return finish(im, w, h, "sky_cloud_small_01", "Sky")

def sky_birds_trio_01(w=170, h=90):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    for x, y, s in [(38,44,1.0),(88,28,0.78),(128,56,0.62)]:
        taper(dr, curve(x*S-13*S*s, y*S, x*S, y*S-6*S*s, 5*S*s), 1.7*s, 0.9*s, INK, 235)
        taper(dr, curve(x*S, y*S-6*S*s, x*S+13*S*s, y*S, 5*S*s), 0.9*s, 1.7*s, INK, 235)
    return finish(im, w, h, "sky_birds_trio_01", "Sky")

def sky_star_cluster_01(w=140, h=130):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    for x, y, r, a in [(44,40,13,235),(92,30,8,205),(72,74,10,220),
                       (110,86,6,185),(36,96,5,175)]:
        star(dr, x*S, y*S, r, 4, a)
    return finish(im, w, h, "sky_star_cluster_01", "Sky")

# ---------------------------------------------------------------- MAGIC

def magic_sparkle_cluster_01(w=140, h=140):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    for x, y, r, a in [(56,46,15,240),(96,68,9,210),(66,94,11,225),
                       (110,36,6,190),(34,80,5,175),(92,110,4,165)]:
        star(dr, x*S, y*S, r, 4, a, 0.30)
    return finish(im, w, h, "magic_sparkle_cluster_01", "Magic")

def magic_particle_trail_01(w=220, h=120):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    path = curve(16*S, 96*S, 204*S, 26*S, 40*S, 30)
    for i, (x, y) in enumerate(path):
        if i % 3: continue
        t = i/len(path)
        blob(dr, x, y, 2.4 + 3.4*(1-t), 0.20, int(90+130*(1-t)), 0.9, seed=i)
    return finish(im, w, h, "magic_particle_trail_01", "Magic")

def magic_firefly_01(w=90, h=90):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    blob(dr, 45*S, 45*S, 6, 0.10, 245, 0.95, seed=2)
    for r, a in [(13, 60), (20, 32), (27, 16)]:
        blob(dr, 45*S, 45*S, r, 0.06, a, 0.35, seed=2)
    return finish(im, w, h, "magic_firefly_01", "Magic")

# ---------------------------------------------------------------- OCEAN

def ocean_shell_01(w=120, h=110):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    apex = (60*S, 96*S)
    outer = curve(20*S, 92*S, 100*S, 92*S, -52*S, 50)
    dr.polygon([apex] + outer, fill=INK+(48,))
    taper(dr, outer, 1.8, 1.8, INK, 238)
    for k in range(-3, 4):
        ex = 60*S + k*13*S
        taper(dr, curve(apex[0], apex[1], ex, 90*S - abs(k)*3*S, k*2*S), 1.2, 0.6, INK, 200)
    return finish(im, w, h, "ocean_shell_01", "Ocean")

def ocean_seaweed_01(w=120, h=210):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    base = h*S - 4*S
    for x, ln, bend, wob in [(40,150,26,3),(64,186,-30,5),(86,124,20,7)]:
        pts = []
        steps = 46
        for i in range(steps+1):
            t = i/steps
            pts.append((x*S + math.sin(t*math.pi*1.7 + wob)*bend*S*t,
                        base - ln*S*t))
        taper(dr, pts, 3.2, 0.6, INK, 232)
    return finish(im, w, h, "ocean_seaweed_01", "Ocean")

def ocean_bubbles_01(w=110, h=140):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    for x, y, r, a in [(44,108,13,215),(70,76,9,195),(40,52,7,180),(66,28,5,160)]:
        blob(dr, x*S, y*S, r, 0.05, a, 0.14, seed=int(x))
    return finish(im, w, h, "ocean_bubbles_01", "Ocean")

def ocean_wave_mark_01(w=210, h=70):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    for row, (y, amp, al) in enumerate([(26,11,225),(44,8,190),(58,6,150)]):
        pts = []
        for i in range(81):
            t = i/80
            pts.append((10*S + t*190*S, y*S + math.sin(t*math.pi*3 + row)*amp*S))
        taper(dr, pts, 2.0, 1.2, INK, al)
    return finish(im, w, h, "ocean_wave_mark_01", "Ocean")

# ---------------------------------------------------------------- BEDTIME

def bedtime_moon_01(w=130, h=130):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    outer = curve(72*S, 14*S, 72*S, 116*S,  54*S, 60)
    inner = curve(72*S, 14*S, 72*S, 116*S,  24*S, 60)
    dr.polygon(outer + inner[::-1], fill=INK+(52,))
    taper(dr, outer, 2.0, 2.0, INK, 240)
    taper(dr, inner, 1.6, 1.6, INK, 220)
    return finish(im, w, h, "bedtime_moon_01", "Bedtime")

def bedtime_star_pair_01(w=110, h=100):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    star(dr, 40*S, 40*S, 14, 5, 235, 0.42)
    star(dr, 78*S, 70*S, 9, 5, 200, 0.42)
    return finish(im, w, h, "bedtime_star_pair_01", "Bedtime")

def bedtime_sleepy_cloud_01(w=180, h=110):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    for cx, cy, r, sd in [(58,66,24,11),(94,54,31,13),(128,68,21,17)]:
        blob(dr, cx*S, cy*S, r, 0.07, 195, 0.18, seed=sd)
    star(dr, 146*S, 30*S, 7, 4, 180, 0.32)
    star(dr, 40*S, 26*S, 5, 4, 155, 0.32)
    return finish(im, w, h, "bedtime_sleepy_cloud_01", "Bedtime")

# ---------------------------------------------------------------- ADVENTURE

def adventure_stones_01(w=170, h=90):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    base = h*S - 8*S
    for cx, r, sd in [(50,22,21),(92,15,23),(124,19,29)]:
        blob(dr, cx*S, base - r*S*0.5, r, 0.20, 225, 0.22, seed=sd)
    taper(dr, curve(18*S, base, 152*S, base, 4*S), 1.5, 1.5, INK, 150)
    return finish(im, w, h, "adventure_stones_01", "Adventure")

def adventure_feather_01(w=100, h=180):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    spine = curve(52*S, 168*S, 44*S, 16*S, 14*S, 50)
    for i in range(6, len(spine)-2, 2):
        x, y = spine[i]
        t = i/len(spine)
        ln = 26*(1-abs(t-0.45)*1.5)
        if ln <= 4: continue
        taper(dr, curve(x, y, x-ln*S, y-ln*S*0.5, 5*S), 1.3, 0.5, INK, 205)
        taper(dr, curve(x, y, x+ln*S, y-ln*S*0.5, -5*S), 1.3, 0.5, INK, 205)
    taper(dr, spine, 2.6, 0.8, INK, 242)
    return finish(im, w, h, "adventure_feather_01", "Adventure")

def adventure_hill_01(w=230, h=110):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    base = h*S - 6*S
    far  = curve(10*S, base, 150*S, base, -58*S, 60)
    near = curve(80*S, base, 222*S, base, -42*S, 60)
    dr.polygon(far  + [(150*S, base), (10*S, base)],  fill=INK+(34,))
    dr.polygon(near + [(222*S, base), (80*S, base)],  fill=INK+(46,))
    taper(dr, far,  1.7, 1.7, INK, 200)
    taper(dr, near, 2.0, 2.0, INK, 230)
    return finish(im, w, h, "adventure_hill_01", "Adventure")

# ---------------------------------------------------------------- SPACE

def space_planet_01(w=130, h=120):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    blob(dr, 62*S, 58*S, 30, 0.03, 232, 0.22, seed=31)
    ring = curve(12*S, 70*S, 118*S, 50*S, 20*S, 60)
    taper(dr, ring, 2.2, 2.2, INK, 210)
    return finish(im, w, h, "space_planet_01", "Space")

def space_comet_01(w=200, h=110):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    tail = curve(180*S, 24*S, 26*S, 88*S, 26*S, 40)
    for i, (x, y) in enumerate(tail):
        t = i/len(tail)
        if i % 2: continue
        blob(dr, x, y, 1.6+4.2*(1-t), 0.18, int(70+150*(1-t)), 0.9, seed=i)
    star(dr, 180*S, 24*S, 13, 4, 245, 0.30)
    return finish(im, w, h, "space_comet_01", "Space")

def space_constellation_01(w=180, h=150):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    nodes = [(30,110),(66,72),(104,96),(138,44),(160,92)]
    for i in range(len(nodes)-1):
        a, b = nodes[i], nodes[i+1]
        taper(dr, [(a[0]*S,a[1]*S),(b[0]*S,b[1]*S)], 0.9, 0.9, INK, 120)
    for i,(x,y) in enumerate(nodes):
        star(dr, x*S, y*S, 9 if i % 2 == 0 else 6, 4, 230, 0.30)
    return finish(im, w, h, "space_constellation_01", "Space")


# =================================================================== EK SET
#
# İlk turda 26 varlıktan 9'u elendi ve örüntü netti: prosedürel çizim organik
# çizgi formlarında çalışıyor, tanınması gereken nesnelerde ve geometrik
# parçacıklarda çalışmıyor. Bu set o örüntüye göre yazıldı — yıldız poligonu
# ya da daire yok; her şey büyüyen, akan, kıvrılan bir çizgi.

def ocean_coral_01(w=150, h=170):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    base = h*S - 5*S
    trunk = curve(74*S, base, 70*S, 66*S, 10*S, 30)
    taper(dr, trunk, 4.2, 1.6, INK, 238)
    for t, ang, ln in [(0.30,-58,42),(0.45,54,38),(0.62,-50,36),(0.78,46,30)]:
        px, py = trunk[int(t*len(trunk))]
        a = math.radians(ang - 90)
        br = curve(px, py, px+math.cos(a)*ln*S, py+math.sin(a)*ln*S, ln*S*0.30, 24)
        taper(dr, br, 2.6, 0.8, INK, 228)
        # ikincil dallanma — mercanı mercan yapan şey
        bx, by = br[-1]
        a2 = math.radians(ang - 90 + (18 if ang > 0 else -18))
        taper(dr, curve(bx, by, bx+math.cos(a2)*ln*0.5*S, by+math.sin(a2)*ln*0.5*S, 4*S, 16),
              1.5, 0.5, INK, 210)
    return finish(im, w, h, "ocean_coral_01", "Ocean")

def ocean_fish_pair_01(w=170, h=110):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    def fish(cx, cy, ln, flip):
        d = -1 if flip else 1
        top = curve(cx-ln*S*d, cy, cx+ln*S*d, cy,  ln*S*0.30, 30)
        bot = curve(cx-ln*S*d, cy, cx+ln*S*d, cy, -ln*S*0.30, 30)
        dr.polygon(top + bot[::-1], fill=INK+(46,))
        taper(dr, top, 1.6, 1.6, INK, 232)
        taper(dr, bot, 1.6, 1.6, INK, 232)
        tx = cx - ln*S*d
        dr.polygon([(tx, cy), (tx-14*S*d, cy-11*S), (tx-14*S*d, cy+11*S)], fill=INK+(56,))
        taper(dr, [(tx, cy), (tx-14*S*d, cy-11*S)], 1.4, 1.0, INK, 226)
        taper(dr, [(tx, cy), (tx-14*S*d, cy+11*S)], 1.4, 1.0, INK, 226)
    fish(70*S, 44*S, 26, False)
    fish(112*S, 78*S, 18, True)
    return finish(im, w, h, "ocean_fish_pair_01", "Ocean")

def ocean_kelp_edge_01(w=110, h=250):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    base = h*S - 4*S
    for x, ln, bend, ph in [(34,222,22,0.4),(58,190,-26,1.9)]:
        pts, steps = [], 54
        for i in range(steps+1):
            t = i/steps
            pts.append((x*S + math.sin(t*math.pi*1.6+ph)*bend*S*t, base - ln*S*t))
        taper(dr, pts, 3.6, 0.7, INK, 234)
        for k in range(4, steps-2, 7):
            px, py = pts[k]
            leaf(dr, px, py, 16, -150 if k % 14 else -30, 0.42, 190)
    return finish(im, w, h, "ocean_kelp_edge_01", "Ocean")

def sky_cloud_wisp_01(w=220, h=90):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    for y, ln, al, w0 in [(40,180,210,3.0),(58,130,170,2.2),(28,96,140,1.8)]:
        x0 = 18*S + (200-ln)*S*0.3
        taper(dr, curve(x0, y*S, x0+ln*S, y*S, -7*S, 40), w0, 0.6, INK, al)
    return finish(im, w, h, "sky_cloud_wisp_01", "Sky")

def sky_sun_rays_01(w=160, h=150):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    cx, cy = 26*S, 24*S
    for k in range(7):
        a = math.radians(14 + k*11.5)
        ln = (78 + (k % 3)*26)
        taper(dr, [(cx+math.cos(a)*20*S, cy+math.sin(a)*20*S),
                   (cx+math.cos(a)*ln*S, cy+math.sin(a)*ln*S)],
              2.0, 0.5, INK, 180 - (k % 3)*30)
    taper(dr, curve(cx+8*S, cy+30*S, cx+34*S, cy-6*S, 12*S, 28), 2.2, 2.2, INK, 225)
    return finish(im, w, h, "sky_sun_rays_01", "Sky")

def bedtime_night_hills_01(w=240, h=100):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    base = h*S - 5*S
    for x0, x1, bend, al, fill in [(0,140,-52,180,30),(90,244,-38,215,44)]:
        arc = curve(x0*S, base, x1*S, base, bend*S, 60)
        dr.polygon(arc + [(x1*S, base), (x0*S, base)], fill=INK+(fill,))
        taper(dr, arc, 1.9, 1.9, INK, al)
    return finish(im, w, h, "bedtime_night_hills_01", "Bedtime")

def bedtime_moon_wisp_01(w=170, h=130):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    outer = curve(96*S, 16*S, 96*S, 104*S,  46*S, 54)
    inner = curve(96*S, 16*S, 96*S, 104*S,  20*S, 54)
    dr.polygon(outer + inner[::-1], fill=INK+(50,))
    taper(dr, outer, 2.0, 2.0, INK, 238)
    taper(dr, inner, 1.5, 1.5, INK, 214)
    for y, ln, al in [(74,74,160),(88,54,125)]:
        taper(dr, curve(14*S, y*S, (14+ln)*S, y*S, -5*S, 30), 2.0, 0.6, INK, al)
    return finish(im, w, h, "bedtime_moon_wisp_01", "Bedtime")

def adventure_pennant_01(w=120, h=180):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    pole = [(40*S, 172*S), (46*S, 14*S)]
    taper(dr, pole, 3.0, 2.0, INK, 240)
    top = curve(46*S, 20*S, 100*S, 40*S, -12*S, 26)
    bot = curve(46*S, 52*S, 100*S, 40*S,  10*S, 26)
    dr.polygon(top + bot[::-1], fill=INK+(52,))
    taper(dr, top, 1.7, 1.2, INK, 232)
    taper(dr, bot, 1.7, 1.2, INK, 232)
    return finish(im, w, h, "adventure_pennant_01", "Adventure")

def adventure_rope_01(w=210, h=90):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    path = curve(8*S, 40*S, 200*S, 58*S, 26*S, 60)
    taper(dr, path, 3.0, 3.0, INK, 225)
    for i in range(3, len(path)-3, 4):
        x, y = path[i]
        nx, ny = path[i+2]
        a = math.atan2(ny-y, nx-x) + math.pi/2
        taper(dr, [(x-math.cos(a)*4*S, y-math.sin(a)*4*S),
                   (x+math.cos(a)*4*S, y+math.sin(a)*4*S)], 1.2, 1.2, INK, 165)
    return finish(im, w, h, "adventure_rope_01", "Adventure")

def adventure_fern_01(w=130, h=190):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    spine = curve(58*S, 180*S, 76*S, 14*S, 26*S, 54)
    taper(dr, spine, 3.0, 0.8, INK, 238)
    for i in range(4, len(spine)-3, 3):
        x, y = spine[i]
        t = i/len(spine)
        ln = 34*(1 - t*0.72)
        if ln < 6: continue
        leaf(dr, x, y, ln, -150 + t*20, 0.30, 200)
        leaf(dr, x, y, ln, -30 - t*20, 0.30, 200)
    return finish(im, w, h, "adventure_fern_01", "Adventure")

def magic_swirl_01(w=170, h=170):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    pts = []
    for i in range(170):
        t = i/169
        a = t*math.pi*3.1
        r = (8 + t*62)*S
        pts.append((86*S + math.cos(a)*r, 86*S + math.sin(a)*r*0.82))
    taper(dr, pts, 0.6, 3.0, INK, 215)
    return finish(im, w, h, "magic_swirl_01", "Magic")

def magic_wisp_trail_01(w=220, h=140):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    for off, al, bend in [(0,215,44),(13,160,38),(-11,120,50)]:
        taper(dr, curve(16*S, (108+off)*S, 204*S, (34+off)*S, bend*S, 44),
              2.6, 0.4, INK, al)
    return finish(im, w, h, "magic_wisp_trail_01", "Magic")

def magic_glow_grass_01(w=180, h=130):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    base = h*S - 5*S
    for x, ln, lean, wt in [(48,64,-14,2.2),(68,96,-6,2.6),(90,118,2,2.8),
                            (112,84,10,2.4),(132,56,18,2.0)]:
        x0, y0 = x*S, base
        x2, y2 = (x+lean)*S, base - ln*S
        x1, y1 = (x+lean*0.15)*S, base - ln*S*0.55
        pts = [((1-t)**2*x0 + 2*(1-t)*t*x1 + t*t*x2,
                (1-t)**2*y0 + 2*(1-t)*t*y1 + t*t*y2) for t in (i/28 for i in range(29))]
        taper(dr, pts, wt, 0.3, INK, 232)
        # uçta yumuşak bir ışık — parıltı poligonu değil
        tx, ty = pts[-1]
        for r, a in [(3.0,150),(5.4,80),(8.0,40)]:
            blob(dr, tx, ty, r, 0.05, a, 0.8, seed=int(x))
    return finish(im, w, h, "magic_glow_grass_01", "Magic")

def space_orbit_arcs_01(w=200, h=160):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    blob(dr, 112*S, 84*S, 26, 0.03, 228, 0.20, seed=41)
    for r, al, tilt in [(52,205,16),(72,160,26),(92,115,36)]:
        pts = []
        for i in range(95):
            t = i/94
            a = math.pi*0.18 + t*math.pi*1.30
            pts.append((112*S + math.cos(a)*r*S, 84*S + math.sin(a)*r*S*0.42 - tilt*S*0.2))
        taper(dr, pts, 1.8, 0.6, INK, al)
    return finish(im, w, h, "space_orbit_arcs_01", "Space")

def space_moon_arc_01(w=180, h=150):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    outer = curve(106*S, 20*S, 106*S, 122*S,  50*S, 56)
    inner = curve(106*S, 20*S, 106*S, 122*S,  22*S, 56)
    dr.polygon(outer + inner[::-1], fill=INK+(48,))
    taper(dr, outer, 2.0, 2.0, INK, 236)
    taper(dr, inner, 1.5, 1.5, INK, 210)
    pts = []
    for i in range(80):
        t = i/79
        a = math.pi*0.62 + t*math.pi*0.78
        pts.append((106*S + math.cos(a)*72*S, 72*S + math.sin(a)*66*S))
    taper(dr, pts, 0.6, 2.0, INK, 150)
    return finish(im, w, h, "space_moon_arc_01", "Space")

def forest_fallen_leaves_01(w=190, h=100):
    im = canvas(w, h); dr = ImageDraw.Draw(im); S = SS
    for x, y, ln, ang, al in [(44,62,42,168,225),(96,74,36,150,210),(140,58,30,190,195)]:
        leaf(dr, x*S, y*S, ln, ang, 0.36, al)
    taper(dr, curve(24*S, 86*S, 166*S, 86*S, 4*S), 1.4, 1.4, INK, 110)
    return finish(im, w, h, "forest_fallen_leaves_01", "Forest")


BUILDERS = [v for k, v in sorted(globals().items())
            if callable(v) and any(k.startswith(p) for p in
            ("forest_","garden_","sky_","magic_","ocean_","bedtime_","adventure_","space_"))]

if __name__ == "__main__":
    made = []
    for b in BUILDERS:
        p = b()
        made.append(p)
        print(f"{os.path.getsize(p)//1024:>4} KB  {p}")
    print(f"\ntoplam {len(made)} varlık")

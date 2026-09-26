"""Procedural soundtrack + sound design for magicpaper-film (31.5 s).

Article rules applied:
  - Music: 100 BPM ("smooth, cool, effortless"), soft celesta/bell + warm pad, no drums, no hype.
  - Adaptive rhythm: sparse -> 8ths -> 16ths while themes are scanned -> riser + launch -> 8ths while the
    story writes itself -> near-silence inside the illustration -> one resolving chime on the logo.
  - Sound design: only sounds that explain something (card lands, launch, page opens, logo chime).

usage: python3 soundtrack.py [out.wav]
"""
import sys, wave
import numpy as np

SR = 48000
DUR = 31.5
N = int(SR * DUR)
L = np.zeros(N); R = np.zeros(N)
rng = np.random.default_rng(7)
BEAT = 60 / 100


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def add(sig, t0, pan=0.0, gain=1.0):
    i = int(t0 * SR)
    if i >= N:
        return
    sig = sig[: N - i] * gain
    L[i : i + len(sig)] += sig * np.sqrt(0.5 * (1 - pan))
    R[i : i + len(sig)] += sig * np.sqrt(0.5 * (1 + pan))


def bell(m, dur=2.2, bright=1.0):
    """Celesta-like FM bell."""
    t = np.arange(int(dur * SR)) / SR
    f = hz(m)
    idx = 1.6 * bright * np.exp(-t * 7)
    s = np.sin(2 * np.pi * f * t + idx * np.sin(2 * np.pi * f * 3.5 * t))
    s += 0.18 * np.sin(2 * np.pi * f * 2 * t) * np.exp(-t * 4)
    env = np.exp(-t * 2.6) * np.minimum(1, t / 0.004)
    return s * env


def pad(ms, dur, att=1.4, rel=1.8):
    t = np.arange(int((dur + rel) * SR)) / SR
    s = np.zeros_like(t)
    for m in ms:
        f = hz(m)
        for d in (-0.07, 0.0, 0.07):
            ph = rng.uniform(0, 2 * np.pi)
            s += np.sin(2 * np.pi * f * (1 + d / 100 * 3) * t + ph)
            s += 0.22 * np.sin(2 * np.pi * 2 * f * t + ph)
    s /= len(ms) * 3
    env = np.minimum(1, t / att) * np.clip((dur + rel - t) / rel, 0, 1)
    env *= 1 + 0.06 * np.sin(2 * np.pi * 0.25 * t)
    return s * env


def bass(m, dur=3.0):
    t = np.arange(int(dur * SR)) / SR
    f = hz(m)
    s = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * 2 * f * t)
    return s * np.exp(-t * 1.1) * np.minimum(1, t / 0.02)


def lowpass(x, a):
    y = np.empty_like(x); acc = 0.0
    for i, v in enumerate(x):
        acc += a * (v - acc); y[i] = acc
    return y


def noise_band(dur, f_from, f_to, env):
    """Swept band-passed noise (whoosh / riser / page swish)."""
    n = int(dur * SR)
    x = rng.standard_normal(n)
    X = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(n, 1 / SR)
    # build via short overlapping chunks so the band can sweep
    out = np.zeros(n)
    hop = 1024; win = np.hanning(hop * 2)
    for s in range(0, n - hop * 2, hop):
        k = s / max(1, n - hop * 2)
        fc = f_from * (f_to / f_from) ** k
        seg = x[s : s + hop * 2] * win
        S = np.fft.rfft(seg)
        fr = np.fft.rfftfreq(hop * 2, 1 / SR)
        S *= np.exp(-((np.log2(np.maximum(fr, 1) / fc)) ** 2) / (2 * 0.6 ** 2))
        out[s : s + hop * 2] += np.fft.irfft(S)
    t = np.arange(n) / n
    return out / (np.abs(out).max() + 1e-9) * env(t)


def tick(freq=2600, dur=0.06):
    t = np.arange(int(dur * SR)) / SR
    return np.sin(2 * np.pi * freq * t) * np.exp(-t * 90) + 0.5 * rng.standard_normal(len(t)) * np.exp(-t * 400)


# ------------------------------------------------------------------ harmony (F major, lydian colour)
F, A, C, E, D, G, Bb = 53, 57, 60, 64, 50, 55, 58
CHORDS = [  # (start, end, pad voicing, bass, arp tones)
    (0.0, 4.8,  [F, A, C + 0, E],          41, [77, 81, 84, 88]),
    (4.8, 8.4,  [D, F, A, C, E + 12 - 12], 38, [74, 77, 81, 84, 88]),
    (8.4, 12.0, [Bb - 12, D, F, A],        46, [74, 77, 81, 82, 86]),
    (12.0, 15.6, [C - 12, F, G, C],        48, [79, 84, 86, 89]),
    (15.6, 19.2, [F, A, C, E],             41, [77, 81, 84, 88]),
    (19.2, 21.6, [D, F, A, C],             38, [74, 77, 81, 84]),
    (21.6, 27.6, [Bb - 12, D, F, A, C + 12], 46, [86, 89, 93]),
    (27.6, 31.5, [F, G, A, C, E],          41, [89, 91, 93, 96]),
]
for s, e, v, b, _ in CHORDS:
    add(pad(v, e - s + 0.3), s, gain=0.16)
    add(pad([m + 12 for m in v[1:3]], e - s, att=2.0), s, pan=0.3, gain=0.05)
    if s > 0:
        add(bass(b, min(3.5, e - s + 0.8)), s, gain=0.12)


def chord_at(t):
    for c in CHORDS:
        if c[0] <= t < c[1]:
            return c
    return CHORDS[-1]


# ------------------------------------------------------------------ celesta, with adaptive rhythm
def arp(t0, t1, step, gain, bright=1.0, pattern=(0, 1, 2, 3, 2, 1)):
    i = 0; t = t0
    while t < t1 - 1e-6:
        tones = chord_at(t)[4]
        m = tones[pattern[i % len(pattern)] % len(tones)]
        add(bell(m, bright=bright), t, pan=0.35 * (1 if i % 2 else -1), gain=gain * (0.85 + 0.15 * (i % 4 == 0)))
        i += 1; t += step

# 1  premise: a few breaths of bell under the headline
for t, m in [(0.6, 77), (1.8, 81), (3.0, 88)]:  # 3.0 = the dot appears
    add(bell(m), t, gain=0.20)
# 2  photo: gentle 8ths once the card lands
arp(4.8, 8.4, BEAT / 2, 0.10)
# 3  themes: denser 8ths, then 16ths during the scan; hop notes climb to the chosen world
arp(8.4, 9.6, BEAT / 2, 0.10)
arp(9.6, 10.8, BEAT / 4, 0.075, pattern=(0, 1, 2, 3))
for t, m in [(9.55, 81), (9.85, 84), (10.1, 86), (10.3, 89)]:
    add(bell(m, 1.2), t, pan=0.2, gain=0.10)
add(bell(93, 2.8), 10.4, gain=0.18); add(bell(86, 2.8), 10.4, pan=-0.3, gain=0.10)  # selection
# 4  magic: 8ths into the riser, then silence for the launch
arp(11.4, 13.2, BEAT / 2, 0.09)
# 5  story writes itself
arp(16.2, 21.3, BEAT / 2, 0.095)
# 6  inside the illustration: sparse, high, night
for t, m in [(22.2, 93), (23.4, 89), (24.6, 96), (25.8, 93)]:
    add(bell(m, 3.0, bright=0.6), t, pan=(-0.4 if t % 2 < 1 else 0.4), gain=0.12)
# 7  logo: one resolving chime (on the sparkle), stacked fifth
for m, g, p in [(77, 0.20, 0), (84, 0.14, -0.3), (89, 0.12, 0.3), (96, 0.07, 0)]:
    add(bell(m, 4.0), 27.6, pan=p, gain=g)

# ------------------------------------------------------------------ sound design (only what explains something)
add(tick(1900), 4.55, gain=0.10)                                          # photo card lands
add(noise_band(0.95, 400, 5000, lambda x: x ** 2.2), 12.5, gain=0.07)    # riser before lift-off
add(noise_band(1.6, 3500, 300, lambda x: np.minimum(1, x * 12) * (1 - x) ** 1.6), 13.45, gain=0.16)  # launch whoosh
t = np.arange(int(1.2 * SR)) / SR
add(np.sin(2 * np.pi * 55 * t * (1 - 0.3 * t)) * np.exp(-t * 3) * np.minimum(1, t / 0.01), 13.45, gain=0.20)  # soft sub under launch
add(noise_band(0.5, 900, 3000, lambda x: np.sin(np.pi * x) ** 2), 15.9, gain=0.05)  # page opens
add(noise_band(1.2, 300, 2500, lambda x: np.sin(np.pi * x) ** 1.5), 25.9, gain=0.05)  # moonlight wipe

# ------------------------------------------------------------------ reverb (stereo decorrelated noise IR)
def reverb(x, seed, secs=3.2, decay=0.75):
    r = np.random.default_rng(seed)
    n = int(secs * SR); tt = np.arange(n) / SR
    ir = r.standard_normal(n) * np.exp(-tt / decay)
    ir = lowpass(ir, 0.35)
    ir[: int(0.012 * SR)] = 0
    ir /= np.sqrt((ir ** 2).sum())
    size = 1 << int(np.ceil(np.log2(len(x) + n)))
    y = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x)]
    return y

wetL, wetR = reverb(L, 1), reverb(R, 2)
outL = L + 0.55 * wetL
outR = R + 0.55 * wetR

# master: gentle fades, soft limiter, -1 dBFS peak
tt = np.arange(N) / SR
fade = np.minimum(1, tt / 0.4) * np.clip((DUR - tt) / 1.6, 0, 1)
st = np.stack([outL, outR], 1) * fade[:, None]
st = np.tanh(st * 1.6) / 1.6
st *= 10 ** (-1 / 20) / np.abs(st).max()

out = sys.argv[1] if len(sys.argv) > 1 else 'soundtrack.wav'
with wave.open(out, 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((st * 32767).astype('<i2').tobytes())
print('wrote', out)

#!/usr/bin/env python3
"""MagicPaper ses imzası: tek enstrüman ailesi (sıcak kalimba), kâğıt ve Ragi'nin sesi.

Dosyalar elle değil buradan üretilir; lisans sorunu yok, istenince yeniden üretilir.
Kurallar: docs/RAGI.md (Ses bölümü).

    python3 Tools/make_ragi_sounds.py

Çıktı: MagicPaper/DesignSystem/Sounds/*.m4a (macOS `afconvert` ile AAC).
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "MagicPaper", "DesignSystem", "Sounds")
rng = np.random.default_rng(7)  # Her üretimde aynı ses.


def times(duration):
    return np.arange(int(duration * RATE)) / RATE


def kalimba(freq, duration=0.9, gain=1.0):
    """Tek nota: kısa atak, üstel sönüm, sertleşmeyen birkaç üst ses."""
    t = times(duration)
    body = np.sin(2 * np.pi * freq * t) * np.exp(-t * 5.5)
    body += 0.28 * np.sin(2 * np.pi * freq * 2.0 * t) * np.exp(-t * 9)
    body += 0.10 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t * 22)
    attack = np.minimum(t / 0.004, 1.0)
    return body * attack * gain


def place(notes, duration):
    """(saniye, ses) çiftlerini tek kanala yerleştirir."""
    mix = np.zeros(int(duration * RATE))
    for start, sound in notes:
        at = int(start * RATE)
        end = min(at + len(sound), len(mix))
        mix[at:end] += sound[: end - at]
    return mix


def room(signal, wet=0.16):
    """Küçük oda: iki geri besleme. Ses kuru kalmasın, uzamasın."""
    out = signal.copy()
    for delay, amount in ((0.031, wet), (0.047, wet * 0.7)):
        d = int(delay * RATE)
        for _ in range(3):
            echo = np.zeros_like(out)
            echo[d:] = out[:-d] * amount
            out = out + echo
    return out


def biquad_bandpass(signal, freq, q):
    w = 2 * np.pi * freq / RATE
    alpha = np.sin(w) / (2 * q)
    b0, b2 = alpha, -alpha
    a0, a1, a2 = 1 + alpha, -2 * np.cos(w), 1 - alpha
    out = np.zeros_like(signal)
    x1 = x2 = y1 = y2 = 0.0
    for i, x in enumerate(signal):
        y = (b0 * x + b2 * x2 - a1 * y1 - a2 * y2) / a0
        out[i] = y
        x2, x1, y2, y1 = x1, x, y1, y
    return out


def chirp(start_hz, end_hz, duration, trill=0.0):
    """Ragi'nin sesi: perdesi kayan küçük bir mırıltı, ağız boşluğundan süzülmüş."""
    t = times(duration)
    pitch = start_hz + (end_hz - start_hz) * (t / duration) ** 0.7
    pitch = pitch * (1 + 0.012 * np.sin(2 * np.pi * 7 * t))
    phase = 2 * np.pi * np.cumsum(pitch) / RATE
    source = sum(np.sin(phase * n) / n for n in range(1, 9))
    voiced = biquad_bandpass(source, 1050, 2.2) + 0.55 * biquad_bandpass(source, 2500, 3.0)
    envelope = np.sin(np.pi * np.minimum(t / duration, 1.0)) ** 0.8
    if trill:
        # "mrr": başta hızlı titreşim, sonra açılan nota.
        roll = 1 - 0.55 * (0.5 + 0.5 * np.sin(2 * np.pi * trill * t)) * np.exp(-t * 12)
        envelope = envelope * roll
    return voiced * envelope


def paper(duration=0.26):
    """Sayfa: süzülmüş gürültünün kısa hışırtısı, en sonda hafif bir değiş."""
    t = times(duration)
    noise = rng.normal(0, 1, len(t))
    swish = biquad_bandpass(noise, 3400, 0.7) * np.sin(np.pi * t / duration) ** 2
    touch = biquad_bandpass(noise, 900, 1.2) * np.exp(-((t - duration * 0.82) / 0.012) ** 2)
    return swish + 0.5 * touch


def normalized(signal, peak_db):
    target = 10 ** (peak_db / 20)
    return signal / np.max(np.abs(signal)) * target


G5, B5, D6, E6, G6 = 783.99, 987.77, 1174.66, 1318.51, 1567.98

SOUNDS = {
    # Masal sonu: üç nota yukarı, sonuncusu kalır.
    "mp_ending": (room(place([(0, kalimba(G5)), (0.13, kalimba(B5)), (0.26, kalimba(D6, 1.1, 1.1))], 1.4)), -9),
    # Kazanılan tek öğe (yıldız, rozet): tek küçük nota.
    "mp_earned": (room(kalimba(E6, 0.5)), -13),
    # Masal ciltlendi: iki nota.
    "mp_ready": (room(place([(0, kalimba(D6, 0.7)), (0.11, kalimba(G6, 0.8))], 0.95)), -11),
    # Sayfa çevrildi: duyulur duyulmaz.
    "mp_page": (paper(), -24),
    # Ragi selam verir.
    "mp_ragi": (room(place([(0, chirp(620, 940, 0.2, trill=34)), (0.2, chirp(820, 1120, 0.14))], 0.42), wet=0.1), -14),
}


def write_wav(path, samples):
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes((samples * 32767).astype(np.int16).tobytes())


def main():
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as scratch:
        for name, (signal, peak) in SOUNDS.items():
            signal = normalized(signal, peak)
            fade = int(0.02 * RATE)
            signal[-fade:] *= np.linspace(1, 0, fade)
            wav = os.path.join(scratch, name + ".wav")
            write_wav(wav, signal)
            target = os.path.join(OUT, name + ".m4a")
            subprocess.run(["afconvert", wav, target, "-f", "m4af", "-d", "aac", "-b", "96000"], check=True)
            rms = 20 * np.log10(np.sqrt(np.mean(signal ** 2)))
            print(f"{name}: {len(signal) / RATE:.2f} sn, tepe {peak} dB, RMS {rms:.1f} dB, {os.path.getsize(target)} bayt")


if __name__ == "__main__":
    main()

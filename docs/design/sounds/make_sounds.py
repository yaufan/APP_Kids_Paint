"""The app's sounds (0.16), made from sine waves and noise here, so every
one is ours: nothing recorded, nothing downloaded, no license to follow.

- Short sounds (a tap, a pop, a boing...) are WAV at 22,050 Hz.
- The places' background sounds (birds, rain, wind...) loop without a
  seam: WAV at 16,000 Hz, a few seconds long.
- Soft: gentle starts, no clicks, quiet enough to sit under the voice.

    python3 make_sounds.py    # writes app/assets/sounds/*.wav
"""
import pathlib
import wave

import numpy as np

OUT = pathlib.Path(__file__).resolve().parents[3] / "app" / "assets" / "sounds"
SR = 22050
rng = np.random.default_rng(7)

# Notes (Hz) for the little tunes.
NOTE = {n: 440 * 2 ** ((k - 9) / 12 + o - 4) for o in range(3, 8) for k, n0 in enumerate("C C# D D# E F F# G G# A A# B".split())
        for n in [f"{n0}{o}"]}


def t_of(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def env(n, attack=0.005, release=0.05, sr=SR):
    """Up quickly, down smoothly: no clicks at either end."""
    e = np.ones(n)
    a, r = max(1, int(attack * sr)), max(1, int(release * sr))
    e[:a] = np.linspace(0, 1, a) ** 2
    e[-r:] *= np.linspace(1, 0, r) ** 2
    return e


def sweep(f, sr=SR):
    """A sine whose frequency follows the array [f] (Hz per sample)."""
    return np.sin(2 * np.pi * np.cumsum(f) / sr)


def decay(n, tau, sr=SR):
    return np.exp(-np.arange(n) / (tau * sr))


def lowpass(x, cutoff, sr=SR):
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / sr)
    spec *= 1 / (1 + (freqs / cutoff) ** 4)
    return np.fft.irfft(spec, len(x))


def bandpass(x, lo, hi, sr=SR):
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / sr)
    spec *= 1 / (1 + (lo / np.maximum(freqs, 1)) ** 4) / (1 + (freqs / hi) ** 4)
    return np.fft.irfft(spec, len(x))


def bell(freq, dur=0.5, sr=SR, bright=1.0):
    """A soft glockenspiel note: a few partials, the high ones dying first."""
    t = t_of(dur, sr)
    x = (np.sin(2 * np.pi * freq * t) * np.exp(-t / (dur * 0.35))
         + 0.35 * bright * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t / (dur * 0.12))
         + 0.15 * bright * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t / (dur * 0.06)))
    return x * env(len(t), 0.002, 0.03, sr)


def marimba(freq, dur=0.5, sr=SR):
    t = t_of(dur, sr)
    x = np.sin(2 * np.pi * freq * t) * np.exp(-t / (dur * 0.3)) + 0.2 * np.sin(2 * np.pi * freq * 4 * t) * np.exp(-t / (dur * 0.05))
    return x * env(len(t), 0.003, 0.03, sr)


def place(total, parts, sr=SR):
    """[parts]: (start seconds, signal) mixed into [total] seconds."""
    out = np.zeros(int(total * sr))
    for start, sig in parts:
        i = int(start * sr)
        j = min(len(out), i + len(sig))
        out[i:j] += sig[: j - i]
    return out


def triangle(freq, dur, sr=SR):
    t = t_of(dur, sr)
    return 2 / np.pi * np.arcsin(np.sin(2 * np.pi * freq * t))


# ---------------------------------------------------------------- short sounds


def tap():
    t = t_of(0.06)
    return sweep(np.linspace(950, 1300, len(t))) * env(len(t), 0.002, 0.04) * decay(len(t), 0.03)


def pick():
    """A water drop: plip."""
    t = t_of(0.09)
    return sweep(np.geomspace(500, 1500, len(t))) * env(len(t), 0.002, 0.03) * decay(len(t), 0.04)


def fill():
    """A bubble pop: bloop."""
    t = t_of(0.16)
    f = np.geomspace(220, 700, len(t))
    x = sweep(f) + 0.25 * sweep(2 * f)
    return x * env(len(t), 0.004, 0.05) * decay(len(t), 0.07)


def swish():
    """A crayon starting to draw: a soft scratch."""
    n = int(0.22 * SR)
    x = bandpass(rng.standard_normal(n), 1200, 5000)
    return x * np.hanning(n) * 0.6


def stamp():
    t = t_of(0.14)
    boop = sweep(np.linspace(460, 330, len(t))) * env(len(t), 0.003, 0.04) * decay(len(t), 0.06)
    thump = np.sin(2 * np.pi * 110 * t) * decay(len(t), 0.03)
    return boop + 0.6 * thump


def squeak():
    t = t_of(0.16)
    f = 1550 + 90 * np.sin(2 * np.pi * 28 * t)
    return sweep(f) * env(len(t), 0.01, 0.05) * 0.8


def undo():
    """A little whoosh backwards."""
    n = int(0.2 * SR)
    x = rng.standard_normal(n)
    ramp = np.linspace(0, 1, n) ** 2
    x = lowpass(x * ramp, 2500) * env(n, 0.01, 0.03)
    blip = sweep(np.linspace(900, 500, n)) * decay(n, 0.05)
    return (0.6 * x + 0.5 * blip) * env(n, 0.002, 0.03)


def sparkle():
    return place(0.5, [(0, bell(NOTE["E6"], 0.35)), (0.06, bell(NOTE["G6"], 0.35)), (0.12, bell(NOTE["C7"], 0.38))])


def tada():
    notes = ["C5", "E5", "G5"]
    parts = [(i * 0.09, triangle(NOTE[n], 0.25) * env(int(0.25 * SR), 0.005, 0.12)) for i, n in enumerate(notes)]
    t = t_of(0.6)
    last = (triangle(NOTE["C6"], 0.6) * (1 + 0.02 * np.sin(2 * np.pi * 6 * t))) * env(len(t), 0.005, 0.3)
    return place(0.95, parts + [(0.27, last), (0.27, 0.5 * bell(NOTE["C7"], 0.5))])


def hooray():
    """Moving in: a sparkly run up, then a warm chord."""
    run = ["C6", "D6", "E6", "G6", "A6", "C7", "D7", "E7"]
    parts = [(i * 0.05, 0.6 * bell(NOTE[n], 0.4)) for i, n in enumerate(run)]
    chord = sum(triangle(NOTE[n], 0.7) for n in ("C5", "E5", "G5")) / 3
    return place(1.2, parts + [(0.42, chord * env(len(chord), 0.02, 0.45))])


def boing(f0):
    """A cartoon jump: springs up, wobbles, settles."""
    t = t_of(0.38)
    f = f0 * (1 + 1.1 * (1 - np.exp(-t / 0.035))) * (1 + 0.12 * np.sin(2 * np.pi * 13 * t) * np.exp(-t / 0.18))
    return (sweep(f) + 0.2 * sweep(2 * f)) * env(len(t), 0.004, 0.08) * decay(len(t), 0.16)


def send():
    """A postcard flying off, then a ding."""
    n = int(0.35 * SR)
    whoosh = bandpass(rng.standard_normal(n), 400, 3000) * np.hanning(n) * 0.5
    return place(0.9, [(0, whoosh), (0.28, bell(NOTE["C6"], 0.55))])


def rocket():
    n = int(1.8 * SR)
    rumble = lowpass(rng.standard_normal(n), 180) * 3
    hiss = bandpass(rng.standard_normal(n), 800, 4000) * np.linspace(0.1, 0.6, n)
    e = np.minimum(1, np.arange(n) / (0.15 * SR)) * np.linspace(1, 0, n) ** 1.5
    return (rumble + hiss) * e


def ding():
    return bell(NOTE["A6"], 0.45)


def coin():
    return place(0.5, [(0, bell(NOTE["B5"], 0.25)), (0.07, bell(NOTE["E6"], 0.42))])


def chime():
    """Going into a place: ding-dong."""
    return place(0.9, [(0, marimba(NOTE["E5"], 0.5)), (0.22, marimba(NOTE["C5"], 0.65))])


def lullaby():
    tune = ["C6", "G5", "E5", "G5", "C6"]
    return place(1.8, [(i * 0.28, 0.8 * bell(NOTE[n], 0.6, bright=0.5)) for i, n in enumerate(tune)])


def rainbow():
    """A harp run up, for a rainbow."""
    run = ["C5", "D5", "E5", "G5", "A5", "C6", "D6", "E6", "G6", "A6"]
    return place(1.2, [(i * 0.055, 0.7 * marimba(NOTE[n], 0.5)) for i, n in enumerate(run)])


# ---------------------------------------------------------------- the town's toys (0.18)

toy_rng = np.random.default_rng(18)  # its own, so the sounds above stay the same


def quack():
    """A duck: two nasal quacks."""
    def one(dur):
        t = t_of(dur)
        f = np.linspace(560, 380, len(t))
        phase = np.cumsum(f) / SR
        buzz = 2 * (phase % 1) - 1  # a sawtooth, nasal once filtered
        x = bandpass(buzz, 700, 2600) + 0.3 * bandpass(buzz, 2600, 4200)
        return x * env(len(t), 0.008, 0.05) * (0.6 + 0.4 * np.sin(np.pi * t / dur))
    return place(0.42, [(0, one(0.15)), (0.2, 0.85 * one(0.17))])


def honk():
    """A little car horn: beep beep, two notes together, soft-edged."""
    def one(dur):
        t = t_of(dur)
        x = sum(np.sign(np.sin(2 * np.pi * f * t)) for f in (415, 523))
        return lowpass(x, 1800) * env(len(t), 0.01, 0.04)
    return place(0.42, [(0, one(0.13)), (0.19, one(0.18))])


def toot():
    """The MRT pulling out: a three-note horn, a little wobbly."""
    t = t_of(0.75)
    wob = 1 + 0.006 * np.sin(2 * np.pi * 5 * t)
    x = sum(sweep(f * wob) + 0.3 * sweep(2 * f * wob) for f in (NOTE["E4"], NOTE["G#4"], NOTE["B4"]))
    return x * env(len(t), 0.06, 0.25)


def firework():
    """Whistling up, a soft boom, then crackles fading."""
    n = int(0.55 * SR)
    t = np.arange(n) / SR
    whistle = sweep(np.linspace(700, 1900, n)) * np.linspace(0.15, 0.5, n) * env(n, 0.05, 0.02)
    hiss = bandpass(toy_rng.standard_normal(n), 2000, 6000) * 0.12 * np.linspace(0.3, 1, n)
    m = int(0.5 * SR)
    boom = lowpass(toy_rng.standard_normal(m), 220) * 4 * decay(m, 0.12) * env(m, 0.004, 0.1)
    crackles = np.zeros(int(1.1 * SR))
    for i in toy_rng.integers(0, len(crackles) - 300, 26):
        d = bandpass(toy_rng.standard_normal(300), 1500, 7000) * np.exp(-np.arange(300) / 30)
        crackles[i:i + 300] += d * toy_rng.uniform(0.2, 0.6) * (1 - i / len(crackles))
    return place(1.9, [(0, whistle + hiss), (0.55, boom), (0.62, crackles)])


def drizzle():
    """A little rain from one cloud: a patter that comes and goes."""
    n = int(1.6 * SR)
    hush = bandpass(toy_rng.standard_normal(n), 900, 4000) * 0.15
    drops = np.zeros(n)
    for i in toy_rng.integers(0, n - 300, 40):
        d = bandpass(toy_rng.standard_normal(300), 1800, 6500) * np.exp(-np.arange(300) / 35)
        drops[i:i + 300] += d * toy_rng.uniform(0.3, 0.8)
    return (hush + drops) * np.sin(np.pi * np.arange(n) / n) ** 0.7


SHORT = {
    "tap": (tap, 0.30), "pick": (pick, 0.35), "fill": (fill, 0.45), "swish": (swish, 0.20), "stamp": (stamp, 0.45),
    "squeak": (squeak, 0.22), "undo": (undo, 0.30), "sparkle": (sparkle, 0.30), "tada": (tada, 0.45), "hooray": (hooray, 0.45),
    "boing_low": (lambda: boing(170), 0.45), "boing_mid": (lambda: boing(250), 0.42), "boing_high": (lambda: boing(370), 0.38),
    "send": (send, 0.40), "rocket": (rocket, 0.40), "ding": (ding, 0.35), "coin": (coin, 0.35), "chime": (chime, 0.35),
    "lullaby": (lullaby, 0.30), "rainbow": (rainbow, 0.35),
    "quack": (quack, 0.32), "honk": (honk, 0.26), "toot": (toot, 0.30), "firework": (firework, 0.36), "drizzle": (drizzle, 0.26),
}


# ---------------------------------------------------------------- loops

LOOP_SR = 16000


def seamless(make, seconds, fade=0.5, sr=LOOP_SR):
    """[make](samples) for a little more than [seconds]; the extra end is
    faded into the start, so the loop has no seam."""
    n, x = int(seconds * sr), int(fade * sr)
    sig = make(n + x)
    out = sig[:n].copy()
    w = np.linspace(0, 1, x)
    out[:x] = out[:x] * w + sig[n:n + x] * (1 - w)
    return out


def chirp(sr=LOOP_SR):
    d = rng.uniform(0.05, 0.11)
    t = t_of(d, sr)
    f0 = rng.uniform(2600, 3800)
    f = f0 * (1 + 0.35 * np.sin(np.pi * t / d))
    return np.sin(2 * np.pi * np.cumsum(f) / sr) * np.sin(np.pi * t / d) ** 2


def birds(n):
    air = lowpass(rng.standard_normal(n), 600, LOOP_SR) * 0.08
    sig = air.copy()
    k = 0
    while k < n:
        k += int(rng.uniform(0.5, 1.4) * LOOP_SR)
        for j in range(rng.integers(1, 4)):
            c = chirp() * rng.uniform(0.35, 0.8)
            i = k + j * int(0.13 * LOOP_SR)
            if i + len(c) < n:
                sig[i:i + len(c)] += c
    return sig


def rain(n):
    hush = lowpass(rng.standard_normal(n), 2500, LOOP_SR) * 0.5
    drops = np.zeros(n)
    for i in rng.integers(0, n - 400, int(n / LOOP_SR * 30)):
        d = bandpass(rng.standard_normal(300), 1500, 6000, LOOP_SR) * np.exp(-np.arange(300) / 40)
        drops[i:i + 300] += d * rng.uniform(0.2, 0.7)
    return hush + drops


def wind(n):
    x = bandpass(rng.standard_normal(n), 150, 900, LOOP_SR)
    t = np.arange(n) / LOOP_SR
    swell = 0.55 + 0.45 * np.sin(2 * np.pi * t / 5.5) * np.sin(2 * np.pi * t / 2.3 + 1)
    return x * swell * 2


def bubbles(n):
    hum = lowpass(rng.standard_normal(n), 250, LOOP_SR) * 0.6
    sig = hum.copy()
    for i in rng.integers(0, n - 4000, int(n / LOOP_SR * 5)):
        d = rng.uniform(0.04, 0.09)
        t = t_of(d, LOOP_SR)
        f = np.geomspace(rng.uniform(300, 500), rng.uniform(900, 1500), len(t))
        b = np.sin(2 * np.pi * np.cumsum(f) / LOOP_SR) * np.sin(np.pi * t / d)
        sig[i:i + len(b)] += 0.5 * b
    return sig


def space(n):
    t = np.arange(n) / LOOP_SR
    pad = sum(np.sin(2 * np.pi * NOTE[k] * t + p) * (0.7 + 0.3 * np.sin(2 * np.pi * t / s + p))
              for k, p, s in (("C3", 0, 7.0), ("G3", 1, 5.0), ("E4", 2, 6.0), ("B4", 3, 4.0)))
    return pad / 4


def crickets(n):
    sig = lowpass(rng.standard_normal(n), 400, LOOP_SR) * 0.05
    for start, f in ((0.0, 4300), (0.37, 4700)):
        k = int(start * LOOP_SR)
        while k < n:
            for p in range(3):
                d = int(0.022 * LOOP_SR)
                i = k + p * int(0.035 * LOOP_SR)
                if i + d < n:
                    tt = np.arange(d) / LOOP_SR
                    sig[i:i + d] += np.sin(2 * np.pi * f * tt) * np.sin(np.pi * tt / tt[-1]) * 0.5
            k += int(rng.uniform(0.7, 0.95) * LOOP_SR)
    return sig


def twinkle(n):
    notes = ["C6", "D6", "E6", "G6", "A6", "C7"]
    sig = np.zeros(n)
    k = 0
    while k < n:
        b = 0.5 * bell(NOTE[notes[rng.integers(len(notes))]], 0.7, LOOP_SR, bright=0.4)
        if k + len(b) < n:
            sig[k:k + len(b)] += b
        k += int(rng.uniform(0.35, 0.9) * LOOP_SR)
    return sig


LOOPS = {
    "amb_birds": (birds, 6, 0.30), "amb_rain": (rain, 5, 0.30), "amb_wind": (wind, 6, 0.28), "amb_bubbles": (bubbles, 6, 0.28),
    "amb_space": (space, 7, 0.20), "amb_crickets": (crickets, 5, 0.22), "amb_twinkle": (twinkle, 7, 0.22),
}


def write(path, x, peak, sr):
    x = np.asarray(x, dtype=np.float64)
    x = x / max(1e-9, np.abs(x).max()) * peak
    data = (x * 32767).astype("<i2").tobytes()
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (make, peak) in SHORT.items():
        write(OUT / f"{name}.wav", make(), peak, SR)
    for name, (make, seconds, peak) in LOOPS.items():
        write(OUT / f"{name}.wav", seamless(make, seconds), peak, LOOP_SR)
    total = sum(p.stat().st_size for p in OUT.glob("*.wav"))
    print(f"{len(SHORT) + len(LOOPS)} sounds, {total / 1024:.0f} KB in {OUT}")


if __name__ == "__main__":
    main()

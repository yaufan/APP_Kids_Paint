"""The app's sounds (0.16), made from sine waves and noise here, so every
one is ours: nothing recorded, nothing downloaded, no license to follow.

- Short sounds (a tap, a pop, a boing...) are WAV at 22,050 Hz.
- The places' background sounds (birds, rain, wind...) loop without a
  seam: WAV at 16,000 Hz, a few seconds long.
- Soft: gentle starts, no clicks, quiet enough to sit under the voice.
- The residents' calls (0.19): animal voices from a buzz through formant
  filters (numpy and scipy), sirens, horns and engines from tones and noise.

    python3 make_sounds.py    # writes app/assets/sounds/*.wav
"""
import pathlib
import wave

import numpy as np
from scipy.signal import lfilter, resample_poly

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


# ---------------------------------------------------------------- the residents' calls (0.19)
#
# Tap a resident and it makes its sound; feed them and they munch. Animal
# voices are a buzz (a sawtooth at the voice's pitch) through two or three
# resonances (formants) that make the vowel: "oo" for a moo, "aa" for a
# baa, "ee-aa-oo" for a meow. Roars are rough (the pitch jitters) and breathy.

call_rng = np.random.default_rng(19)  # its own, so the sounds above stay the same
CALL_SR = 16000


def resonator(x, freq, bw, sr=SR, block=64):
    """A two-pole resonance at [freq] Hz (a number, or one per sample, for a
    vowel that changes) of bandwidth [bw] Hz."""
    freq = np.broadcast_to(np.asarray(freq, dtype=float), x.shape)
    y, zi = np.zeros_like(x), np.zeros(2)
    r = np.exp(-np.pi * bw / sr)
    for i in range(0, len(x), block):
        th = 2 * np.pi * freq[i] / sr
        y[i:i + block], zi = lfilter([1 - r], [1, -2 * r * np.cos(th), r * r], x[i:i + block], zi=zi)
    return y


def voice(f0, formants, breath=0.03, rough=0.0, sr=SR):
    """A voice at pitch [f0] (Hz per sample) through [formants]: (Hz or Hz
    per sample, bandwidth, gain). [rough] jitters the pitch, for a growl."""
    n = len(f0)
    if rough:
        f0 = f0 * (1 + rough * lowpass(call_rng.standard_normal(n), 60, sr) * 3)
    buzz = 2 * (np.cumsum(f0) / sr % 1) - 1 + breath * call_rng.standard_normal(n)
    out = np.zeros(n)
    for f, bw, gain in formants:
        y = resonator(buzz, f, bw, sr)
        out += gain * y / max(1e-9, np.abs(y).max())
    return lowpass(out, 3800, sr)  # soft, not a kazoo


def ease(u):
    """0 to 1, smoothly, over u in 0..1."""
    u = np.clip(u, 0, 1)
    return u * u * (3 - 2 * u)


def glide(t, *points):
    """A value that moves smoothly between (time, value) [points]."""
    ts, vs = zip(*points)
    out = np.interp(t, ts, vs)
    return lowpass(out - out.mean(), 25) + out.mean() if len(t) > 64 else out


def moo(low=1.0, dur=1.15):
    """A cow: mmm-ooo, rising then sinking. [low] < 1 for the water buffalo."""
    t = t_of(dur)
    f0 = glide(t, (0, 105), (0.25 * dur, 150), (0.7 * dur, 140), (dur, 96)) * low * (1 + 0.012 * np.sin(2 * np.pi * 5 * t))
    opening = ease((t - 0.08) / 0.25)  # the mouth opens from "m" to "oo-oh"
    x = voice(f0, [(250 + 380 * opening * low, 90, 1.0), (600 + 350 * opening * low, 120, 0.45), (2400, 250, 0.05)], breath=0.04)
    return x * env(len(t), 0.1, 0.3)


def baa(high=1.0, dur=0.85, shake=7.0):
    """A sheep: b-aa-aa, bleating. [high] and [shake] up for the goat."""
    t = t_of(dur)
    bleat = 1 + 0.05 * np.sin(2 * np.pi * shake * t) * ease(t / 0.2)
    f0 = glide(t, (0, 250), (0.12, 300), (dur, 255)) * high * bleat
    opening = ease(t / 0.06)
    x = voice(f0, [(350 + 450 * opening, 110, 1.0), (1150 + 150 * high, 150, 0.6), (2600, 250, 0.12)], breath=0.05)
    return x * env(len(t), 0.01, 0.25) * (0.75 + 0.25 * np.sin(2 * np.pi * shake * t))


def oink():
    """A pig: two snorty oinks."""
    def one(dur):
        t = t_of(dur)
        f0 = glide(t, (0, 150), (0.4 * dur, 230), (dur, 170))
        x = voice(f0, [(420, 180, 1.0), (1300, 300, 0.4)], breath=0.6, rough=0.1)
        return x * env(len(t), 0.01, 0.06) * np.sin(np.pi * t / dur) ** 0.5
    return place(0.5, [(0, one(0.17)), (0.24, 0.9 * one(0.2))])


def cluck():
    """A hen: bok, bok, bok, b-gawk!"""
    def bok(dur=0.07, f=380):
        t = t_of(dur)
        x = voice(np.full(len(t), float(f)), [(650, 140, 1.0), (1500, 200, 0.4)], breath=0.2)
        return x * env(len(t), 0.003, 0.04) * decay(len(t), 0.04)
    t = t_of(0.34)
    f0 = glide(t, (0, 480), (0.08, 650), (0.34, 470))
    gawk = voice(f0, [(glide(t, (0, 450), (0.1, 750), (0.34, 650)), 140, 1.0), (1200, 200, 0.5)], breath=0.15) * env(len(t), 0.01, 0.12)
    return place(0.82, [(0, bok()), (0.13, bok(f=400)), (0.26, bok(f=370)), (0.44, gawk)])


def peep(high=1.0):
    """A chick: peep peep peep."""
    def one(dur):
        t = t_of(dur)
        f = glide(t, (0, 3300), (0.3 * dur, 4100), (dur, 3000)) * high
        return sweep(f) * np.sin(np.pi * t / dur) ** 1.5
    return place(0.56, [(0, one(0.1)), (0.18, one(0.09)), (0.36, one(0.12))])


def woof(high=1.0, times=2):
    """A puppy: woof woof. [high] up for a fox's yip."""
    def one():
        dur = 0.16 / high ** 0.3
        t = t_of(dur)
        f0 = glide(t, (0, 330), (0.04, 380), (dur, 220)) * high
        x = voice(f0, [(520 * high ** 0.5, 160, 1.0), (1350 * high ** 0.4, 220, 0.5), (2600, 300, 0.1)], breath=0.35, rough=0.06)
        return x * env(len(t), 0.004, 0.06) * decay(len(t), 0.09)
    return place(0.23 * times + 0.1, [(0.23 * i, one()) for i in range(times)])


def goose():
    """A goose (and the flamingo): honk-honk, nasal and longer than a duck."""
    def one(dur):
        t = t_of(dur)
        f0 = glide(t, (0, 470), (0.05, 560), (dur, 520))
        x = voice(f0, [(900, 180, 1.0), (2100, 250, 0.7), (3200, 300, 0.2)], breath=0.1)
        return x * env(len(t), 0.01, 0.06)
    return place(0.62, [(0, one(0.2)), (0.29, one(0.26))])


def meow(high=1.0):
    """A cat: mi-aa-ow."""
    dur = 0.75
    t = t_of(dur)
    f0 = glide(t, (0, 520), (0.28, 760), (dur, 470)) * high
    f1 = glide(t, (0, 320), (0.25, 900), (dur, 450))
    f2 = glide(t, (0, 2300), (0.3, 1500), (dur, 950))
    return voice(f0, [(f1, 120, 1.0), (f2, 180, 0.6), (3000, 300, 0.1)], breath=0.05) * env(len(t), 0.05, 0.2)


def eep():
    """A little squeak: the sea otter, the panda, the bunny."""
    def one(dur):
        t = t_of(dur)
        f = glide(t, (0, 1700), (0.5 * dur, 2500), (dur, 2000))
        return (sweep(f) + 0.2 * sweep(2 * f)) * np.sin(np.pi * t / dur)
    return place(0.4, [(0, one(0.12)), (0.17, one(0.15))])


def roar(low=1.0, dur=0.95, rough=0.22):
    """A cartoon roar: a lion, a tiger; [low] < 1 for the T-rex, > 1 for a
    baby dinosaur's rawr."""
    t = t_of(dur)
    f0 = glide(t, (0, 120), (0.2 * dur, 175), (0.6 * dur, 150), (dur, 95)) * low
    growl = 1 - 0.3 * (0.5 + 0.5 * np.sin(2 * np.pi * 28 * t))
    x = voice(f0, [(720 * low ** 0.4, 160, 1.0), (1150 * low ** 0.4, 200, 0.7), (2500, 300, 0.2)], breath=0.45, rough=rough)
    return x * growl * env(len(t), 0.06, 0.3)


def rawr():
    return roar(low=2.3, dur=0.5, rough=0.08)


def trumpet():
    """An elephant: a brassy toot that slides up and wavers."""
    dur = 0.85
    t = t_of(dur)
    f0 = glide(t, (0, 380), (0.12, 600), (0.7, 640), (dur, 560)) * (1 + 0.025 * np.sin(2 * np.pi * 6 * t))
    x = voice(f0, [(900, 250, 1.0), (2000, 300, 0.8), (3300, 400, 0.4)], breath=0.08, rough=0.04)
    return x * env(len(t), 0.04, 0.2)


def whinny():
    """A zebra (like a horse): neigh-h-h, falling and trembling."""
    dur = 0.95
    t = t_of(dur)
    shake = 1 + 0.08 * np.sin(2 * np.pi * 12 * t) * ease(t / 0.5)
    f0 = glide(t, (0, 850), (0.15, 950), (dur, 420)) * shake
    f1 = glide(t, (0, 400), (0.3, 750), (dur, 700))
    x = voice(f0, [(f1, 150, 1.0), (glide(t, (0, 2200), (dur, 1250)), 200, 0.6)], breath=0.12)
    n = int(0.25 * SR)
    snort = bandpass(call_rng.standard_normal(n), 300, 1800) * np.hanning(n) * 0.5
    return place(1.25, [(0, x * env(len(t), 0.02, 0.3)), (0.98, snort)])


def monkey():
    """A monkey: ooh ooh aah aah!"""
    def one(f, vowel, dur=0.14):
        t = t_of(dur)
        f0 = glide(t, (0, f * 0.9), (dur, f * 1.1))
        f1, f2 = (380, 800) if vowel == "oo" else (850, 1350)
        return voice(f0, [(f1, 130, 1.0), (f2, 180, 0.5)], breath=0.08) * env(len(t), 0.01, 0.05)
    return place(0.82, [(0, one(480, "oo")), (0.17, one(560, "oo")), (0.36, one(720, "aa", 0.17)), (0.58, one(820, "aa", 0.2))])


def grunt(low=1.0, times=2):
    """A bear, a kangaroo, a reindeer: huh-huh."""
    def one():
        dur = 0.2
        t = t_of(dur)
        f0 = glide(t, (0, 125), (dur, 95)) * low
        x = voice(f0, [(500 * low ** 0.5, 160, 1.0), (1000, 220, 0.4)], breath=0.4, rough=0.15)
        return x * env(len(t), 0.01, 0.08)
    return place(0.27 * times, [(0.27 * i, one()) for i in range(times)])


def grumble():
    """A hippo, a koala, a walrus, the big plant-eating dinosaurs: a low rumble."""
    dur = 0.75
    t = t_of(dur)
    f0 = glide(t, (0, 70), (0.3, 85), (dur, 62))
    growl = 1 - 0.35 * (0.5 + 0.5 * np.sin(2 * np.pi * 21 * t))
    x = voice(f0, [(380, 120, 1.0), (800, 180, 0.5), (1500, 250, 0.1)], breath=0.3, rough=0.25)
    return x * growl * env(len(t), 0.06, 0.25)


def hum():
    """A giraffe (they hum at night): a soft mm-hmm."""
    def one(f, dur):
        t = t_of(dur)
        f0 = glide(t, (0, f), (dur, f * 1.08)) * (1 + 0.01 * np.sin(2 * np.pi * 5 * t))
        return voice(f0, [(260, 70, 1.0), (900, 150, 0.15)], breath=0.02) * env(len(t), 0.06, 0.12)
    return place(0.72, [(0, one(130, 0.3)), (0.33, one(165, 0.36))])


def blub():
    """A fish: blub blub, bubbles going up."""
    def one(f0, f1, dur):
        t = t_of(dur)
        f = np.geomspace(f0, f1, len(t))
        return (sweep(f) + 0.3 * sweep(2 * f)) * env(len(t), 0.004, 0.04) * decay(len(t), dur * 0.5)
    return place(0.5, [(0, one(260, 760, 0.11)), (0.15, one(320, 900, 0.1)), (0.3, one(240, 680, 0.13))])


def whale(high=1.0):
    """A whale (and the narwhal): a long, slow song that echoes."""
    dur = 1.4
    t = t_of(dur)
    f0 = glide(t, (0, 180), (0.5, 420), (1.0, 330), (dur, 250)) * high * (1 + 0.01 * np.sin(2 * np.pi * 4 * t))
    x = (sweep(f0) + 0.25 * sweep(2 * f0) + 0.08 * sweep(3 * f0)) * env(len(t), 0.25, 0.4)
    return place(1.85, [(0, x), (0.18, 0.35 * x), (0.36, 0.12 * x)])


def dolphin():
    """A dolphin (and the orca): a quick run of clicks, then a whistle up and down."""
    clicks = np.zeros(int(0.3 * SR))
    for k in range(9):
        i = int((0.3 * (k / 9) ** 0.8) * SR)
        c = bandpass(call_rng.standard_normal(110), 2000, 7000) * np.exp(-np.arange(110) / 15)
        clicks[i:i + 110] += c
    t = t_of(0.45)
    f = glide(t, (0, 1900), (0.18, 3500), (0.32, 2600), (0.45, 3100))
    whistle = (sweep(f) + 0.15 * sweep(2 * f)) * env(len(t), 0.02, 0.08)
    return place(0.85, [(0, 0.5 * clicks), (0.33, whistle)])


def click(times=4):
    """A crab, a seahorse, a mantis, an ant: tik-tik, tik-tik."""
    parts = []
    for k in range(times):
        n = 130
        c = bandpass(call_rng.standard_normal(n), 1800, 6000) * np.exp(-np.arange(n) / 18)
        parts.append((0.07 * k + 0.08 * (k // 2), c))
    return place(0.07 * times + 0.1 * (times // 2) + 0.05, parts)


def puff():
    """A pufferfish blowing itself up: fwoooomp, and a little pop."""
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    air = bandpass(call_rng.standard_normal(n), 300, 2500) * ease(t / 0.45) * 0.8
    tone = sweep(np.geomspace(150, 420, n)) * 0.6 * ease(t / 0.45)
    m = int(0.12 * SR)
    pop = sweep(np.geomspace(500, 1400, m)) * decay(m, 0.03) * env(m, 0.002, 0.03)
    return place(0.62, [(0, (air + tone) * env(n, 0.05, 0.02)), (0.46, pop)])


def dino_horn():
    """The parasaurolophus and the brachiosaurus: a low, gentle horn, like a trombone."""
    dur = 1.25
    t = t_of(dur)
    f0 = glide(t, (0, 92), (0.3, 108), (dur, 98)) * (1 + 0.012 * np.sin(2 * np.pi * 4.5 * t))
    x = voice(f0, [(480, 180, 1.0), (950, 220, 0.6), (1800, 300, 0.2)], breath=0.05)
    return x * env(len(t), 0.18, 0.35)


def screech():
    """A pterosaur, a raptor: kee-kee!"""
    def one(dur):
        t = t_of(dur)
        f0 = glide(t, (0, 1050), (0.4 * dur, 1450), (dur, 950))
        x = voice(f0, [(1800, 300, 1.0), (3000, 400, 0.6)], breath=0.2, rough=0.05)
        return x * env(len(t), 0.01, 0.06)
    return place(0.52, [(0, one(0.17)), (0.25, one(0.22))])


def crack():
    """A dinosaur egg: crk, crk, and a tiny rawr from inside."""
    def one():
        n = 500
        x = bandpass(call_rng.standard_normal(n), 1500, 6000) * np.exp(-np.arange(n) / 70)
        for k in call_rng.integers(0, n - 60, 5):
            x[k:k + 60] += bandpass(call_rng.standard_normal(60), 2500, 8000) * 1.5
        return x
    tiny = roar(low=3.0, dur=0.32, rough=0.05)
    return place(0.95, [(0, one()), (0.2, one()), (0.55, 1.6 * tiny)])


def siren(kind):
    """Fire engine (a slow wail), police car (a quick wee-woo), ambulance
    (喔咿喔咿: two notes, high and low)."""
    if kind == "fire":
        t = t_of(1.4)
        f = glide(t, (0, 520), (0.75, 1150), (1.4, 620))
    elif kind == "police":
        t = t_of(1.3)
        f = 700 + 320 * (0.5 - 0.5 * np.cos(2 * np.pi * t / 0.43))
    else:
        t = t_of(1.4)
        f = np.where((t // 0.35) % 2 == 0, 960.0, 770.0)
        f = lowpass(f - 865, 60) + 865
    phase = np.cumsum(f) / SR
    x = lowpass(np.sign(np.sin(2 * np.pi * phase)) * 0.6 + np.sin(2 * np.pi * phase), 2600)
    return x * env(len(t), 0.05, 0.15)


def beep(high=1.0):
    """A scooter: a thin bee-beep."""
    def one(dur):
        t = t_of(dur)
        x = np.sign(np.sin(2 * np.pi * 740 * high * t)) + np.sin(2 * np.pi * 1110 * high * t)
        return lowpass(x, 2800) * env(len(t), 0.008, 0.03)
    return place(0.34, [(0, one(0.08)), (0.13, one(0.16))])


def jet():
    """An airplane flying over: a hiss that comes and goes, and a whine."""
    n = int(1.5 * SR)
    t = np.arange(n) / SR
    over = np.sin(np.pi * t / 1.5) ** 2
    hiss = bandpass(call_rng.standard_normal(n), 500, 4000) * over
    rumble = lowpass(call_rng.standard_normal(n), 160) * 2 * over
    whine = sweep(glide(t, (0, 1500), (0.75, 1350), (1.5, 1000))) * 0.12 * over
    return hiss + rumble + whine


def chop():
    """A helicopter: chop-chop-chop and its engine's whine."""
    n = int(1.3 * SR)
    t = np.arange(n) / SR
    beats = (0.5 + 0.5 * np.cos(2 * np.pi * 11 * t)) ** 6
    thump = lowpass(call_rng.standard_normal(n), 350) * 3 * beats
    whine = sweep(np.full(n, 2100.0)) * 0.05
    return (thump + whine) * env(n, 0.15, 0.3)


def elise():
    """The garbage truck: Für Elise (Beethoven, 1810), from a tinny loudspeaker."""
    tune = [("E5", 1), ("D#5", 1), ("E5", 1), ("D#5", 1), ("E5", 1), ("B4", 1), ("D5", 1), ("C5", 1), ("A4", 3)]
    beat, parts, at = 0.17, [], 0.0
    for note, beats in tune:
        dur = beat * beats
        t = t_of(dur)
        f = NOTE[note]
        x = triangle(f, dur) + 0.35 * np.sign(np.sin(2 * np.pi * f * t))
        parts.append((at, x * env(len(t), 0.008, 0.06) * (decay(len(t), 0.5) if beats > 1 else 1)))
        at += dur
    return bandpass(place(at + 0.1, parts), 450, 3800)


def backup():
    """An excavator backing up: beep, beep, beep over its engine."""
    beeps = []
    for k in range(3):
        t = t_of(0.18)
        beeps.append((0.33 * k, np.sin(2 * np.pi * 1050 * t) * env(len(t), 0.005, 0.02)))
    n = int(1.05 * SR)
    t = np.arange(n) / SR
    engine = lowpass(call_rng.standard_normal(n), 140) * 1.5 * (0.7 + 0.3 * np.sin(2 * np.pi * 14 * t))
    return place(1.05, beeps) + engine * env(n, 0.1, 0.2) * 0.6


def putt():
    """A tractor: putt-putt-putt-putt."""
    n = int(1.1 * SR)
    out = np.zeros(n)
    for k in range(9):
        i = int(k / 8.5 * SR)
        m = int(0.07 * SR)
        thump = (lowpass(call_rng.standard_normal(m), 400) * 2 + np.sin(2 * np.pi * 75 * t_of(0.07))) * decay(m, 0.025)
        out[i:i + m] += thump[: max(0, min(m, n - i))]
    return out * env(n, 0.02, 0.15)


def whir():
    """Wings: a dragonfly, a ladybug taking off."""
    n = int(0.65 * SR)
    t = np.arange(n) / SR
    flutter = (0.5 + 0.5 * np.sin(2 * np.pi * 34 * t)) ** 2
    return bandpass(call_rng.standard_normal(n), 250, 1600) * flutter * np.sin(np.pi * t / 0.65)


def buzz():
    """A bee (and the beetle) flying past: bzzzz, nearer then farther."""
    n = int(0.95 * SR)
    t = np.arange(n) / SR
    f = glide(t, (0, 205), (0.45, 250), (0.95, 195)) * (1 + 0.03 * np.sin(2 * np.pi * 9 * t))
    saw = 2 * (np.cumsum(f) / SR % 1) - 1
    return bandpass(saw, 250, 2600) * np.sin(np.pi * t / 0.95) ** 1.2


def slurp():
    """A snail: a little slurp."""
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    x = call_rng.standard_normal(n)
    out = resonator(x, glide(t, (0, 400), (0.5, 1900)), 160) + 0.6 * resonator(x, glide(t, (0, 900), (0.5, 2800)), 220)
    gurgle = 0.6 + 0.4 * np.sin(2 * np.pi * 18 * t)
    return out * gurgle * np.sin(np.pi * t / 0.5) ** 0.8


def cicada():
    """A cicada (蟬): zzzzz-ee-ee, swelling and fading."""
    n = int(1.6 * SR)
    t = np.arange(n) / SR
    pulses = (0.5 + 0.5 * np.sin(2 * np.pi * 135 * t)) ** 3
    x = bandpass(call_rng.standard_normal(n), 3800, 7000) * pulses
    swell = ease(t / 0.5) * (1 - ease((t - 1.0) / 0.6))
    return x * swell


def ufo():
    """A flying saucer: woo-ee-woo."""
    t = t_of(1.2)
    f = glide(t, (0, 600), (0.5, 900), (1.2, 650)) * (1 + 0.2 * np.sin(2 * np.pi * 7 * t))
    return (sweep(f) + 0.15 * sweep(3 * f)) * env(len(t), 0.1, 0.3)


def alien():
    """An alien: bee-boo-bip."""
    parts = []
    for k, (f, dur) in enumerate([(880, 0.11), (523, 0.13), (1175, 0.08), (659, 0.1), (1397, 0.14)]):
        t = t_of(dur)
        x = np.sin(2 * np.pi * f * t) + 0.3 * np.sign(np.sin(2 * np.pi * f * t))
        parts.append((0.15 * k, lowpass(x, 3000) * env(len(t), 0.005, 0.03)))
    return place(0.82, parts)


def squawk():
    """A penguin: awk, awk, aaawk!"""
    def one(dur, f):
        t = t_of(dur)
        f0 = glide(t, (0, f * 0.85), (0.3 * dur, f), (dur, f * 0.9))
        x = voice(f0, [(800, 160, 1.0), (1500, 220, 0.7), (2600, 300, 0.2)], breath=0.15, rough=0.08)
        return x * env(len(t), 0.01, 0.05)
    return place(0.88, [(0, one(0.11, 520)), (0.18, one(0.11, 540)), (0.38, one(0.42, 600))])


def bark():
    """A seal: ark, ark, ark."""
    def one():
        dur = 0.15
        t = t_of(dur)
        f0 = glide(t, (0, 470), (dur, 340))
        x = voice(f0, [(700, 160, 1.0), (1200, 200, 0.6)], breath=0.3, rough=0.12)
        return x * env(len(t), 0.005, 0.06)
    return place(0.75, [(0, one()), (0.25, one()), (0.5, one())])


def hoot():
    """A snowy owl: hoo, hooo."""
    def one(dur):
        t = t_of(dur)
        f0 = glide(t, (0, 410), (dur, 370))
        breath = bandpass(call_rng.standard_normal(len(t)), 300, 900) * 0.15
        return (sweep(f0) + 0.1 * sweep(2 * f0) + breath) * env(len(t), 0.07, 0.15)
    return place(0.9, [(0, one(0.22)), (0.34, one(0.48))])


def jingle():
    """A sled: sleigh bells, shaken three times."""
    out = np.zeros(int(1.15 * SR))
    for shake in (0.0, 0.33, 0.66):
        for _ in range(7):
            i = int((shake + call_rng.uniform(0, 0.12)) * SR)
            f = call_rng.uniform(2600, 4200)
            n = int(0.25 * SR)
            tt = np.arange(n) / SR
            b = (np.sin(2 * np.pi * f * tt) + 0.6 * np.sin(2 * np.pi * f * 1.47 * tt)) * np.exp(-tt / 0.05)
            out[i:i + n] += b[: len(out) - i] * call_rng.uniform(0.3, 0.8)
    return out


def serve():
    """Food going into the bowl: a rattle of pellets, then a plop."""
    out = np.zeros(int(0.55 * SR))
    for _ in range(26):
        i = int(call_rng.uniform(0, 0.38) * SR)
        n = 220
        f = call_rng.uniform(1400, 3200)
        tt = np.arange(n) / SR
        out[i:i + n] += np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.006) * call_rng.uniform(0.3, 0.9)
    m = int(0.14 * SR)
    plop = sweep(np.geomspace(300, 700, m)) * decay(m, 0.05) * env(m, 0.003, 0.04)
    return place(0.6, [(0, out), (0.4, plop)])


def munch():
    """Eating: nom, nom, nom, each with a crunch."""
    def nom():
        dur = 0.15
        t = t_of(dur)
        f0 = glide(t, (0, 230), (dur, 200))
        f1 = glide(t, (0, 280), (0.06, 600), (dur, 300))
        mouth = voice(f0, [(f1, 100, 1.0), (1100, 200, 0.3)], breath=0.05) * env(len(t), 0.01, 0.05)
        n = int(0.06 * SR)
        bite = bandpass(call_rng.standard_normal(n), 1200, 5000) * np.exp(-np.arange(n) / (0.012 * SR))
        return place(0.2, [(0, 0.8 * bite), (0.03, mouth)])
    return place(0.75, [(0, nom()), (0.25, nom()), (0.5, nom())])


CALLS = {
    "moo": (moo, 0.40), "moo_low": (lambda: moo(low=0.78, dur=1.3), 0.42), "baa": (baa, 0.36),
    "bleat": (lambda: baa(high=1.35, dur=0.7, shake=9.5), 0.34), "oink": (oink, 0.40), "cluck": (cluck, 0.36),
    "peep": (peep, 0.24), "woof": (woof, 0.40), "yip": (lambda: woof(high=1.8, times=3), 0.34), "goose": (goose, 0.32),
    "meow": (meow, 0.34), "eep": (eep, 0.26), "roar": (roar, 0.42), "big_roar": (lambda: roar(low=0.72, dur=1.3, rough=0.28), 0.45),
    "rawr": (rawr, 0.36), "trumpet": (trumpet, 0.34), "whinny": (whinny, 0.34), "monkey": (monkey, 0.34),
    "grunt": (grunt, 0.40), "grumble": (grumble, 0.45), "hum": (hum, 0.38), "blub": (blub, 0.36), "whale": (whale, 0.36),
    "narwhal": (lambda: whale(high=1.5), 0.34), "dolphin": (dolphin, 0.28), "click": (click, 0.30), "puff": (puff, 0.36),
    "dino_horn": (dino_horn, 0.42), "screech": (screech, 0.30), "crack": (crack, 0.36),
    "siren_fire": (lambda: siren("fire"), 0.24), "siren_police": (lambda: siren("police"), 0.24),
    "siren_ambulance": (lambda: siren("ambulance"), 0.24), "beep": (beep, 0.24), "jet": (jet, 0.30), "chop": (chop, 0.34),
    "elise": (elise, 0.28), "backup": (backup, 0.26), "putt": (putt, 0.40), "whir": (whir, 0.30), "buzz": (buzz, 0.30),
    "slurp": (slurp, 0.30), "cicada": (cicada, 0.22), "ufo": (ufo, 0.28), "alien": (alien, 0.26), "squawk": (squawk, 0.32),
    "bark": (bark, 0.38), "hoot": (hoot, 0.36), "jingle": (jingle, 0.26), "serve": (serve, 0.32), "munch": (munch, 0.38),
}


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
    # Nothing in the calls is above 8 kHz: kept at 16 kHz, a quarter smaller.
    for name, (make, peak) in CALLS.items():
        write(OUT / f"{name}.wav", resample_poly(make(), CALL_SR, SR), peak, CALL_SR)
    for name, (make, seconds, peak) in LOOPS.items():
        write(OUT / f"{name}.wav", seamless(make, seconds), peak, LOOP_SR)
    total = sum(p.stat().st_size for p in OUT.glob("*.wav"))
    print(f"{len(SHORT) + len(CALLS) + len(LOOPS)} sounds, {total / 1024:.0f} KB in {OUT}")


if __name__ == "__main__":
    main()

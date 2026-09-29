#!/usr/bin/python3
"""Synthesise the Starwatch login ambience: a night meadow that swells in —
soft wind through grass, a few crickets, a distant owl and a slow, gentle
pentatonic chime — then fades out. ~14 s, stereo WAV, numpy only."""

import wave
from pathlib import Path

import numpy as np

SR = 44100
DUR = 14.0
N = int(SR * DUR)
t = np.arange(N) / SR
rng = np.random.default_rng(29)


def band(x, lo=None, hi=None):
    """Zero-phase FFT band-pass with soft (Gaussian-ish) skirts."""
    n = x.shape[-1]
    spec = np.fft.rfft(x, axis=-1)
    f = np.fft.rfftfreq(n, 1 / SR)
    g = np.ones_like(f)
    if lo:
        g *= 1 / (1 + (lo / np.maximum(f, 1e-3)) ** 4)
    if hi:
        g *= 1 / (1 + (f / hi) ** 4)
    return np.fft.irfft(spec * g, n, axis=-1)


def pan(mono, p):
    """p in [-1, 1] -> constant-power stereo."""
    a = (p + 1) * np.pi / 4
    return np.stack([mono * np.cos(a), mono * np.sin(a)])


def norm(x):
    return x / (np.max(np.abs(x)) + 1e-9)


out = np.zeros((2, N))

# --- Wind: brownish noise through a soft band, two slow gusts, wide stereo.
for ch in range(2):
    w = np.cumsum(rng.standard_normal(N))
    w -= np.convolve(w, np.ones(4410) / 4410, mode="same")  # remove drift
    w = norm(band(w, 120, 900))
    gust = 0.55 + 0.45 * np.sin(2 * np.pi * 0.09 * t + ch * 0.9) * np.sin(2 * np.pi * 0.047 * t + 0.4)
    out[ch] += 0.16 * w * gust

# --- Grass rustle: faint high hiss following the gusts.
for ch in range(2):
    r = norm(band(rng.standard_normal(N), 2500, 7000))
    out[ch] += 0.012 * r * (0.4 + 0.6 * np.sin(2 * np.pi * 0.09 * t + ch * 0.9) ** 2)

# --- Crickets: carrier with a pulse train, grouped into chirps.
def cricket(freq, pulse_hz, pulses, period, offset, level, p):
    carrier = np.sin(2 * np.pi * freq * t + 0.3 * np.sin(2 * np.pi * 7 * t))
    ph = ((t - offset) % period)
    chirp_on = ph < pulses / pulse_hz
    pulse = np.clip(np.sin(2 * np.pi * pulse_hz * ph), 0, 1) ** 2
    env = pulse * chirp_on * (t > offset)
    sig = band(carrier * env, 2500, 6500) * level
    return pan(sig, p)

out += cricket(4300, 32, 4, 0.62, 0.8, 0.030, -0.6)
out += cricket(4700, 28, 3, 0.91, 1.9, 0.020, 0.55)
out += cricket(3900, 36, 5, 1.37, 3.2, 0.014, 0.1)

# --- Distant owl: two soft "hoo"s with a slight pitch fall, right of centre.
def hoo(start, length, f0):
    m = (t >= start) & (t < start + length)
    tt = t[m] - start
    f = f0 * (1 - 0.06 * tt / length) * (1 + 0.004 * np.sin(2 * np.pi * 5.5 * tt))
    phase = 2 * np.pi * np.cumsum(f) / SR
    env = np.sin(np.pi * tt / length) ** 1.5
    s = np.zeros(N)
    s[m] = (np.sin(phase) + 0.25 * np.sin(2 * phase)) * env
    return s

owl = hoo(8.2, 0.55, 390) + hoo(8.95, 0.9, 370)
owl = band(owl, 200, 1200) * 0.06
out += pan(owl, 0.45)

# --- Chime: A-major pentatonic bell tones, soft attack, gentle echoes.
notes = [(2.2, 659.25, -0.3), (3.4, 880.0, 0.25), (4.9, 739.99, -0.1),
         (6.6, 554.37, 0.35), (8.9, 1108.73, -0.35), (10.4, 880.0, 0.1)]
chime = np.zeros((2, N))
for start, f, p in notes:
    m = t >= start
    tt = t[m] - start
    env = (1 - np.exp(-tt / 0.012)) * np.exp(-tt / 1.8)
    tone = (np.sin(2 * np.pi * f * tt)
            + 0.35 * np.sin(2 * np.pi * 2.01 * f * tt) * np.exp(-tt / 0.6)
            + 0.12 * np.sin(2 * np.pi * 3.02 * f * tt) * np.exp(-tt / 0.3))
    s = np.zeros(N)
    s[m] = tone * env
    chime += pan(s, p)
# Echo tail: a few decaying, alternating-side taps.
wet = np.zeros_like(chime)
for i, (delay, gain) in enumerate([(0.23, 0.45), (0.41, 0.32), (0.67, 0.22), (0.97, 0.14), (1.31, 0.09)]):
    d = int(delay * SR)
    src = chime[i % 2]
    wet[(i + 1) % 2, d:] += src[:-d] * gain
out += 0.075 * (chime + band(wet, None, 3500))

# --- Master: fades, gentle peak.
fade = np.clip(t / 2.0, 0, 1) ** 2 * np.clip((DUR - t) / 3.5, 0, 1) ** 1.5
out *= fade
out *= 0.32 / np.max(np.abs(out))

pcm = (np.clip(out.T, -1, 1) * 32767).astype("<i2")
dest = Path(__file__).with_name("starwatch-login.wav")
with wave.open(str(dest), "wb") as wf:
    wf.setnchannels(2)
    wf.setsampwidth(2)
    wf.setframerate(SR)
    wf.writeframes(pcm.tobytes())
print(dest)

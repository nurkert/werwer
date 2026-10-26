"""Synthesise Whowolf's night sounds from scratch (no recordings, no third-party
samples): wind, crickets, an owl and a morning yawn.

Usage: python tool/assets/synth_sounds.py OUT_DIR

Writes 22.05 kHz mono WAV files; tool/assets/README.md shows how they become
the app's MP3 files (MP3 plays everywhere, also through GStreamer on Linux). Deterministic: the same script makes the same sounds.
"""

import sys
import wave
from pathlib import Path

import numpy as np
from scipy import signal

RATE = 22050
rng = np.random.default_rng(7)


def t(seconds: float) -> np.ndarray:
    return np.arange(int(seconds * RATE)) / RATE


def fade(x: np.ndarray, attack: float, release: float) -> np.ndarray:
    n = len(x)
    env = np.ones(n)
    a, r = int(attack * RATE), int(release * RATE)
    env[:a] = np.linspace(0, 1, a) ** 2
    env[n - r :] = np.linspace(1, 0, r) ** 2
    return x * env


def normalise(x: np.ndarray, peak: float) -> np.ndarray:
    return x / np.max(np.abs(x)) * peak


def wind() -> np.ndarray:
    """Pink-ish noise through a slowly wandering band-pass, swelling."""
    length = 9.0
    noise = np.cumsum(rng.normal(size=int(length * RATE)))  # brown noise
    noise -= signal.savgol_filter(noise, 2001, 1)  # drop the drift
    out = np.zeros_like(noise)
    block = 1024
    for start in range(0, len(noise), block):
        phase = start / len(noise)
        centre = 380 + 260 * np.sin(2 * np.pi * phase * 1.3) ** 2
        b, a = signal.butter(2, [centre * 0.6, centre * 1.6], "bandpass", fs=RATE)
        out[start : start + block] = signal.lfilter(b, a, noise[start : start + block])
    swell = 0.55 + 0.45 * np.sin(np.pi * t(length) / length) ** 1.5
    return fade(normalise(out * swell, 0.5), 2.0, 2.5)


def crickets() -> np.ndarray:
    """Two crickets: bursts of short 4–5 kHz pulses, slightly out of step."""
    length = 4.0
    out = np.zeros(int(length * RATE))
    for carrier, offset, period in [(4600, 0.0, 0.62), (4150, 0.27, 0.71)]:
        tt = t(0.018)
        pulse = np.sin(2 * np.pi * carrier * tt) * np.hanning(len(tt))
        start = offset
        while start < length - 0.2:
            for k in range(3):
                i = int((start + k * 0.032) * RATE)
                out[i : i + len(pulse)] += pulse
            start += period * (0.9 + 0.2 * rng.random())
    return fade(normalise(out, 0.22), 0.4, 0.6)


def owl() -> np.ndarray:
    """A tawny-ish call: a long hoot, a pause, a wavering second hoot."""
    out = np.zeros(int(2.6 * RATE))

    def hoot(start: float, length: float, f0: float, waver: float) -> None:
        tt = t(length)
        f = f0 * (1 - 0.08 * tt / length) + waver * np.sin(2 * np.pi * 9 * tt)
        phase = 2 * np.pi * np.cumsum(f) / RATE
        tone = np.sin(phase) + 0.18 * np.sin(2 * phase)
        breath = signal.lfilter(*signal.butter(2, 900, fs=RATE), rng.normal(size=len(tt)))
        env = np.sin(np.pi * tt / length) ** 0.8
        i = int(start * RATE)
        out[i : i + len(tt)] += (tone + 0.15 * breath) * env

    hoot(0.05, 0.55, 410, 0)
    hoot(1.05, 1.1, 395, 14)
    return normalise(out, 0.45)


def yawn() -> np.ndarray:
    """A sleepy cartoon yawn: a glottal buzz gliding up and down through the
    vowel formants of a long 'aaah-oh', with a breathy tail."""
    length = 2.2
    tt = t(length)
    x = tt / length
    f0 = 150 + 120 * np.sin(np.pi * np.clip(x * 1.3, 0, 1)) - 60 * x
    phase = np.cumsum(f0) / RATE
    buzz = 2 * (phase % 1) - 1  # sawtooth
    breath = rng.normal(size=len(tt)) * 0.25
    source = buzz * (1 - 0.6 * x) + breath * (0.3 + 0.7 * x)
    # 'a' (800/1200 Hz) melting into 'o' (450/800 Hz), formant by formant.
    out = np.zeros_like(source)
    block = 512
    for start in range(0, len(source), block):
        k = start / len(source)
        for f, bw, gain in [
            (800 - 350 * k, 120, 1.0),
            (1200 - 400 * k, 160, 0.6),
            (2600, 300, 0.2),
        ]:
            b, a = signal.iirpeak(f, f / bw, fs=RATE)
            out[start : start + block] += gain * signal.lfilter(b, a, source[start : start + block])
    env = np.sin(np.pi * np.clip(x * 1.15, 0, 1)) ** 0.7
    return fade(normalise(out * env, 0.6), 0.15, 0.4)


def write(path: Path, x: np.ndarray) -> None:
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())
    print(f"{path.name}  {len(x) / RATE:.1f} s")


def main() -> None:
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for name, make in [("wind", wind), ("crickets", crickets), ("owl", owl), ("yawn", yawn)]:
        write(out / f"{name}.wav", make())


if __name__ == "__main__":
    main()

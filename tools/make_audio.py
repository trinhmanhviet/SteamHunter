"""Synthesize an original moor-and-forge soundtrack and game sound cues."""

from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "audio"
TAU = math.tau


def _normalize(samples: list[float], ceiling: float = 0.75) -> list[float]:
    peak = max((abs(value) for value in samples), default=1.0)
    return [value * min(1.0, ceiling / max(peak, 0.0001)) for value in samples]


def _music(hunt: bool) -> list[float]:
    length = 8 * RATE
    drone = 73.416 if hunt else 110.0
    melody = (
        [(0, 220.0, 0.85), (0.8, 293.66, 0.75), (1.6, 329.63, 0.65),
         (2.4, 293.66, 0.7), (3.2, 261.63, 0.75), (4.0, 220.0, 0.8),
         (4.8, 196.0, 0.7), (5.6, 220.0, 0.7), (6.4, 293.66, 0.7),
         (7.2, 261.63, 0.7)]
        if hunt else
        [(0, 220.0, 1.5), (1.25, 261.63, 1.2), (2.5, 329.63, 1.3),
         (3.75, 293.66, 1.1), (4.75, 261.63, 1.25), (6.0, 196.0, 0.9),
         (6.75, 220.0, 1.25)]
    )
    beat_step = 0.4 if hunt else 0.8
    result = []
    noise = random.Random(4)
    for i in range(length):
        t = i / RATE
        voice = 0.11 * math.sin(TAU * drone * t) + 0.05 * math.sin(TAU * drone * 2.01 * t)
        voice *= 0.8 + 0.2 * math.sin(TAU * 0.14 * t)
        for start, frequency, duration in melody:
            age = t - start
            if 0 <= age < duration:
                envelope = math.exp(-3.7 * age / duration) * min(1.0, age * 65)
                voice += envelope * (
                    0.17 * math.sin(TAU * frequency * age)
                    + 0.07 * math.sin(TAU * frequency * 2.003 * age)
                    + 0.025 * math.sin(TAU * frequency * 3.01 * age)
                )
        beat_age = t % beat_step
        if beat_age < 0.055:
            bump = math.exp(-beat_age * 55)
            voice += (0.10 if hunt else 0.035) * bump * math.sin(TAU * (70 - beat_age * 480) * beat_age)
            voice += (0.035 if hunt else 0.018) * bump * (noise.random() * 2 - 1)
        result.append(voice)
    return _normalize(result)


def build_camp_music() -> list[float]:
    return _music(False)


def build_hunt_music() -> list[float]:
    return _music(True)


def build_swing() -> list[float]:
    rng = random.Random(8)
    return _normalize([
        math.exp(-t * 12) * (0.42 * (rng.random() * 2 - 1) + 0.25 * math.sin(TAU * (750 - 1900 * t) * t))
        for t in (i / RATE for i in range(int(RATE * 0.23)))
    ])


def build_hit() -> list[float]:
    rng = random.Random(9)
    return _normalize([
        math.exp(-t * 19) * (0.5 * (rng.random() * 2 - 1) + 0.45 * math.sin(TAU * 115 * t))
        for t in (i / RATE for i in range(int(RATE * 0.30)))
    ])


def build_chime(frequency: float, duration: float) -> list[float]:
    return _normalize([
        math.exp(-t * 7) * (0.35 * math.sin(TAU * frequency * t) + 0.18 * math.sin(TAU * frequency * 2.4 * t))
        for t in (i / RATE for i in range(int(RATE * duration)))
    ])


def write_wave(path: Path, samples: list[float]) -> None:
    with wave.open(str(path), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(b"".join(struct.pack("<h", round(max(-1.0, min(1.0, sample)) * 32767)) for sample in samples))


def main() -> None:
    OUT.mkdir(exist_ok=True)
    tracks = {
        "camp_loop.wav": build_camp_music(),
        "hunt_loop.wav": build_hunt_music(),
        "swing.wav": build_swing(),
        "hit.wav": build_hit(),
        "forge.wav": build_chime(440, 0.56),
        "pickup.wav": build_chime(660, 0.34),
        "break.wav": build_chime(196, 0.65),
    }
    for name, samples in tracks.items():
        write_wave(OUT / name, samples)
    print("Created", len(tracks), "original music and effect files")


if __name__ == "__main__":
    main()

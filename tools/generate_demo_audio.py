#!/usr/bin/env python3
"""Regenerate Circuit Mirage demo WAV/OGG for AETHER BEAT."""
import wave, struct, math, os, json, base64, subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio")
os.makedirs(OUT, exist_ok=True)

sample_rate = 44100
bpm = 128.0
beat = 60.0 / bpm
duration_beats = 8
n_samples = int(sample_rate * beat * duration_beats)

def env(t, attack=0.01, decay=0.15):
    if t < attack:
        return t / attack
    return max(0.0, 1.0 - (t - attack) / decay)

scale = [261.63, 311.13, 349.23, 392.00, 466.16, 523.25]
bass = [130.81, 155.56]
samples = []
for i in range(n_samples):
    t = i / sample_rate
    beat_pos = t / beat
    beat_i = int(beat_pos)
    local = beat_pos - beat_i
    bar = beat_i // 4
    kick = 0.0
    if beat_i % 2 == 0:
        kt = local * beat
        if kt < 0.12:
            kick = 0.55 * env(kt, 0.002, 0.1) * math.sin(2 * math.pi * (80 * (1 - kt * 4)) * kt)
    bass_sig = 0.25 * env(local * beat, 0.01, 0.35) * math.sin(2 * math.pi * bass[bar % 2] * t)
    mel = 0.22 * math.sin(2 * math.pi * scale[(beat_i + bar) % len(scale)] * t) * env(local * beat, 0.005, 0.28)
    v = math.tanh((kick + bass_sig + mel) * 1.2)
    samples.append(int(max(-32767, min(32767, int(v * 32000)))))

wav_path = os.path.join(OUT, "circuit_mirage.wav")
with wave.open(wav_path, "w") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(sample_rate)
    w.writeframes(b"".join(struct.pack("<h", s) for s in samples))

ogg = os.path.join(OUT, "circuit_mirage.ogg")
subprocess.check_call(["ffmpeg", "-y", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "4", ogg])
raw = open(ogg, "rb").read()
open(os.path.join(OUT, "circuit_mirage.ogg.b64"), "w").write(base64.b64encode(raw).decode())
print("wrote", ogg, len(raw), "bytes")

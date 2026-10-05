"""Original melodic score and short tonal effects. No noise or ambient hum layer."""
from pathlib import Path
import wave
import numpy as np

OUT = Path(__file__).resolve().parents[1] / 'audio'
RATE = 32000
BEAT = .75
DURATION = 48
track = np.zeros((RATE * DURATION, 2), dtype=np.float64)

def frequency(note):
    return 440 * 2 ** ((note - 69) / 12)

def tone(at, length, note, volume, pan=0, soft=False):
    start = int(at * RATE)
    n = min(int(length * RATE), len(track) - start)
    t = np.arange(n) / RATE
    f = frequency(note)
    attack = np.minimum(t / (.12 if soft else .018), 1)
    release = np.minimum((length - t) / .22, 1)
    decay = np.exp(-t * (.5 if soft else 2.4))
    signal = np.sin(2*np.pi*f*t) + .18*np.sin(4*np.pi*f*t) + .055*np.sin(6*np.pi*f*t)
    signal *= attack * release * decay * volume
    track[start:start+n, 0] += signal * (1-pan) / 2
    track[start:start+n, 1] += signal * (1+pan) / 2

# Am / F / C / G, with a separate melody and alternating arpeggio voicing.
chords = [(45, 57, 60, 64), (41, 57, 60, 65), (48, 55, 60, 64), (43, 55, 59, 62)]
melodies = [(76,74,72,69), (72,69,65,69), (67,72,76,79), (74,71,67,69)]
for bar in range(16):
    offset = bar * 4 * BEAT
    chord = chords[bar % 4]
    tone(offset, 2.95, chord[0], .18, soft=True)
    for i, note in enumerate(chord[1:]):
        tone(offset, 2.8, note, .035, -.35+i*.35, soft=True)
    for step in range(8):
        tone(offset+step*BEAT/2, .65, chord[1+step%3]+12, .12, (-.3 if step%2 else .3))
    for beat, note in enumerate(melodies[bar % 4]):
        tone(offset+beat*BEAT, .85, note+(12 if bar in [8,9,10,11] else 0), .11 if bar < 8 else .09)
track -= np.mean(track, axis=0)
edge = int(.12*RATE)
track[:edge] *= np.linspace(0,1,edge)[:,None]
track[-edge:] *= np.linspace(1,0,edge)[:,None]
track *= .63 / np.max(np.abs(track))

def save(name, signal, channels=2):
    signal = np.asarray(signal)
    assert np.isfinite(signal).all() and np.max(np.abs(signal)) < .99
    with wave.open(str(OUT / f'desktop_{name}.wav'), 'wb') as wav:
        wav.setnchannels(channels); wav.setsampwidth(2); wav.setframerate(RATE)
        wav.writeframes((signal*32767).astype('<i2').tobytes())
    print(name, 'duration', len(signal)/RATE, 'peak', round(float(np.max(np.abs(signal))),3), 'rms', round(float(np.sqrt(np.mean(signal**2))),3))

save('theme', track)
for name, notes, duration in [('deploy',[440,660],.09), ('energy',[660,880],.20), ('hit',[120,180],.12), ('alarm',[220,330],.24), ('unlock',[523.25,659.25,783.99],.45)]:
    t = np.arange(int(duration*RATE))/RATE
    envelope = np.minimum(t/.008,1)*np.maximum(0,1-t/duration)**2
    signal = sum(np.sin(2*np.pi*f*t) for f in notes)/len(notes)*envelope*.28
    save(name, signal, 1)

"""Regenerate original SVG characters and synthesized audio; standard Python only."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
ROOT.joinpath('assets').mkdir(exist_ok=True)
ROOT.joinpath('audio').mkdir(exist_ok=True)


def svg(name, body):
    ROOT.joinpath('assets', name + '.svg').write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'
        + body + '</svg>', encoding='utf-8')


def robot(accent, extra, body='#bfdae2'):
    return f'''<ellipse cx="64" cy="113" rx="36" ry="7" fill="#081722" opacity=".35"/>
    <path d="M39 91v17H25v8h33V96M71 96v20h32v-8H87V91" fill="#4a7085" stroke="#183748" stroke-width="3"/>
    <rect x="28" y="51" width="73" height="49" rx="14" fill="{body}" stroke="#24465a" stroke-width="4"/>
    <path d="M35 56h58v8H35" fill="#eefaff" opacity=".5"/>
    <rect x="35" y="16" width="56" height="45" rx="14" fill="#d0e6ec" stroke="#24465a" stroke-width="4"/>
    <rect x="41" y="26" width="44" height="22" rx="8" fill="#153947"/>
    <path d="M49 36h8m13 0h7" stroke="{accent}" stroke-width="5" stroke-linecap="round"/>
    <path d="M63 16V6" stroke="#416d82" stroke-width="3"/><circle cx="63" cy="6" r="4" fill="{accent}"/>
    <circle cx="63" cy="76" r="12" fill="#24465a"/><circle cx="63" cy="76" r="7" fill="{accent}"/>
    <path d="M32 91h14m38 0h13" stroke="#54798c" stroke-width="3"/>{extra}'''

svg('pulse', robot('#6de6dc', '<rect x="83" y="59" width="34" height="18" rx="7" fill="#345c73" stroke="#17394a" stroke-width="3"/><ellipse cx="114" cy="68" rx="6" ry="9" fill="#73e6df"/><path d="M13 67h15" stroke="#557c91" stroke-width="11" stroke-linecap="round"/>'))
svg('reactor', '''<ellipse cx="64" cy="113" rx="34" ry="7" fill="#081722" opacity=".35"/><path d="M28 99v16h21V98m31 0v17h21V99" fill="#55728a" stroke="#213c51" stroke-width="3"/><rect x="22" y="24" width="84" height="77" rx="21" fill="#b7d1d9" stroke="#22455a" stroke-width="4"/><rect x="35" y="29" width="58" height="63" rx="17" fill="#254555"/><rect x="41" y="35" width="46" height="51" rx="13" fill="#abd77b"/><path d="M70 38L50 64h15l-5 19 22-28H67Z" fill="#eefccb"/><path d="M13 45v30m102-30v30" stroke="#4c7688" stroke-width="8" stroke-linecap="round"/><path d="M42 21V10m44 11V10" stroke="#6de6dc" stroke-width="5"/><rect x="48" y="97" width="31" height="8" rx="4" fill="#466e82"/>''')
svg('shield', robot('#f6bf72', '<path d="M76 30L121 41L114 96L81 114L64 98L66 51Z" fill="#bd9966" stroke="#3d5263" stroke-width="4"/><path d="M79 43L109 49L105 87L83 100L75 88L78 53Z" fill="#f5c77e"/><path d="M83 52v36m9-40v34m9-30v27" stroke="#d69b5f" stroke-width="3"/><path d="M12 65v28h20V54" fill="#5b7c8e" stroke="#24465a" stroke-width="3"/>'))
svg('cryo', robot('#90d8fa', '<rect x="85" y="57" width="33" height="26" rx="8" fill="#5483a0" stroke="#17394a" stroke-width="3"/><path d="M91 61v17m7-17v17m7-17v17" stroke="#a8eaff" stroke-width="3"/><circle cx="116" cy="70" r="10" fill="#ccf5ff"/><path d="M116 60v20m-9-10h18m-15-7 12 14m0-14-12 14" stroke="#5eacc8" stroke-width="2"/>', '#a6cddd'))
svg('burst', robot('#f6ae75', '<rect x="2" y="56" width="32" height="16" rx="5" fill="#416880" stroke="#17394a" stroke-width="3"/><rect x="2" y="78" width="32" height="16" rx="5" fill="#416880" stroke="#17394a" stroke-width="3"/><rect x="91" y="56" width="35" height="16" rx="5" fill="#416880" stroke="#17394a" stroke-width="3"/><rect x="91" y="78" width="35" height="16" rx="5" fill="#416880" stroke="#17394a" stroke-width="3"/><path d="M120 59v9m0 13v9M7 59v9m0 13v9" stroke="#ffc882" stroke-width="4"/>'))
svg('rail', robot('#c7a4ed', '<path d="M55 57h68v17H56" fill="#455d83" stroke="#1c3651" stroke-width="3"/><path d="M78 60h44v5H78" fill="#c29be6"/><rect x="86" y="47" width="17" height="9" rx="3" fill="#587b99"/><rect x="114" y="53" width="8" height="24" rx="3" fill="#84b7d3"/><path d="M15 58v31h18V54" fill="#557b91" stroke="#24465a" stroke-width="3"/>'))
svg('mortar', robot('#f5bb7e', '<path d="M74 42L108 21L124 47L89 69Z" fill="#657f9a" stroke="#243d51" stroke-width="4"/><ellipse cx="115" cy="34" rx="10" ry="15" transform="rotate(-30 115 34)" fill="#f6bf72" stroke="#345166" stroke-width="3"/><path d="M84 68l13 24" stroke="#507187" stroke-width="9"/>'))
svg('repair', robot('#a3e4ae', '<path d="M22 61L9 76L19 87" stroke="#60869b" stroke-width="12" stroke-linecap="round"/><path d="M95 69L112 60L116 41" stroke="#60869b" stroke-width="10" stroke-linecap="round"/><path d="M107 15v15l10 4 8-8V13l-7 10Z" fill="#a3c6d5" stroke="#35566e" stroke-width="3"/><path d="M61 64v24m-12-12h24" stroke="#e5ffe7" stroke-width="6"/>'))
svg('nova', robot('#e79ce8', '<circle cx="64" cy="76" r="29" fill="#583c74" stroke="#d48ce8" stroke-width="4"/><circle cx="64" cy="76" r="17" fill="#d589e2"/><path d="M64 56L69 70L84 76L69 81L64 95L58 81L44 76L58 70Z" fill="#fce4ff"/><path d="M20 64l-8-13m94 13 9-13" stroke="#b0c7de" stroke-width="7"/>'))


def cyborg(accent, extra='', bulky=False):
    shoulders = 'M18 49h92v43H18Z' if bulky else 'M32 48h65l9 43-25 11H44L23 88Z'
    return f'''<ellipse cx="63" cy="118" rx="37" ry="6" fill="#050d17" opacity=".4"/>
    <path d="M44 87L32 109H18v10h33l11-28m15-3 7 21h22v10H77L64 93" fill="#6d728a" stroke="#202b40" stroke-width="4"/>
    <path d="{shoulders}" fill="#767a94" stroke="#25364a" stroke-width="4"/>
    <path d="M34 55L18 82L6 76m94-20 18 24 4-14" stroke="#687d94" stroke-width="11" stroke-linecap="round"/>
    <rect x="39" y="12" width="51" height="42" rx="13" fill="#abb5c4" stroke="#26364d" stroke-width="4"/>
    <path d="M43 29h42v13H43Z" fill="#28374a"/><path d="M49 35h29" stroke="{accent}" stroke-width="5"/>
    <path d="M51 49h25" stroke="#566378" stroke-width="4"/>
    <path d="M42 63h45v24H42Z" fill="#2b3c54"/><circle cx="64" cy="75" r="9" fill="{accent}"/>
    <path d="M35 96h15m31 0h18" stroke="#aab5c5" stroke-width="3"/>{extra}'''

svg('drone', cyborg('#f09385', '<path d="M42 15L39 4L57 14M77 15L88 5L91 26" fill="#66758d" stroke="#24364b" stroke-width="3"/>'))
svg('runner', cyborg('#ffc18a', '<path d="M31 13L82 6L98 19L43 26Z" fill="#bb825e" stroke="#3c3a4d" stroke-width="3"/><path d="M16 53L4 67m102 31 17 5" stroke="#e9a778" stroke-width="6"/>'))
svg('tank', cyborg('#ed9b86', '<path d="M10 46h26v23H8m82-23h28v23H94" fill="#596880" stroke="#26364b" stroke-width="4"/><path d="M46 5h40l10 16H35Z" fill="#4c5e75" stroke="#213448" stroke-width="4"/><path d="M52 63v24m25-24v24" stroke="#a6acbd" stroke-width="3"/>', True))
svg('disruptor', cyborg('#ca9ae9', '<path d="M47 13L33 4m46 9 17-9" stroke="#9380af" stroke-width="4"/><circle cx="33" cy="4" r="5" fill="#e1b2ff"/><circle cx="96" cy="4" r="5" fill="#e1b2ff"/><circle cx="16" cy="79" r="12" fill="#665482" stroke="#dfb6ff" stroke-width="3"/><path d="M12 70l8 18" stroke="#edc8ff" stroke-width="3"/>'))
svg('medic', cyborg('#9adab0', '<path d="M51 68h25v14H51" fill="#446b69"/><path d="M64 64v22m-11-11h22" stroke="#c4ffdc" stroke-width="5"/><rect x="3" y="76" width="25" height="23" rx="5" fill="#527779" stroke="#2c4758" stroke-width="3"/>'))
svg('boss', cyborg('#fcaa86', '<path d="M24 20L26 3L43 17M62 12L66 1L79 13M90 19L106 3L108 30" fill="#a47779" stroke="#3d3b51" stroke-width="3"/><path d="M8 47h28v25H4m86-25h36v25H97" fill="#a68582" stroke="#26364b" stroke-width="4"/><path d="M50 69L64 60L80 69L79 85L64 94L49 83Z" fill="#ffb290" stroke="#7a5c68" stroke-width="3"/><path d="M55 102v16m22-17v17" stroke="#dfa186" stroke-width="4"/>', True))
svg('guard', '''<ellipse cx="64" cy="111" rx="44" ry="6" fill="#081722" opacity=".4"/><path d="M21 76L8 103h28l12-23m48-4 16 27H83L75 80" fill="#4f748c" stroke="#1d3e54" stroke-width="4"/><rect x="18" y="40" width="91" height="45" rx="18" fill="#bfd5dd" stroke="#25485c" stroke-width="4"/><rect x="33" y="50" width="61" height="24" rx="9" fill="#264e61"/><path d="M45 62h10m19 0h10" stroke="#6de6dc" stroke-width="5" stroke-linecap="round"/><path d="M47 40L38 21h15l12 20m10-1 14-19h12L90 41" fill="#527b92" stroke="#27465d" stroke-width="3"/><circle cx="13" cy="61" r="9" fill="#74dcd5"/><circle cx="115" cy="61" r="9" fill="#74dcd5"/>''')

RATE = 22050


def save_audio(name, duration, sample):
    with wave.open(str(ROOT / 'audio' / (name + '.wav')), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b''.join(struct.pack('<h', max(-32767, min(32767, int(sample(i / RATE) * 32767)))) for i in range(int(RATE * duration))))

for name, freq, duration in [('deploy', 390, .18), ('energy', 880, .25), ('hit', 210, .11), ('alarm', 180, .55), ('unlock', 620, .8)]:
    def sample(t, f=freq, d=duration):
        envelope = min(t / .014, 1) * math.exp(-t * (4 if d > .5 else 10))
        return .25 * envelope * (math.sin(2 * math.pi * (f * t + .5 * f * t * t)) + .22 * math.sin(4 * math.pi * f * t))
    save_audio(name, duration, sample)

notes = [220, 261.63, 329.63, 392, 329.63, 261.63, 196, 246.94, 293.66, 369.99, 293.66, 246.94, 174.61, 220, 261.63, 349.23, 261.63, 220, 196, 246.94, 293.66, 392, 293.66, 246.94]


def music(t):
    beat = int(t / .5) % len(notes)
    local = t % .5
    env = min(local / .025, 1) * math.exp(-local * 7)
    f = notes[beat]
    fade = min(t / .08, (12 - t) / .08, 1)
    pad_gate = math.sin(math.pi * local / .5) ** 2
    return max(0, fade) * (.12 * env * (math.sin(2 * math.pi * f * t) + .3 * math.sin(4 * math.pi * f * t)) + .05 * pad_gate * math.sin(2 * math.pi * notes[(beat // 6) * 6] / 2 * t))

save_audio('orbit_loop', 12.0, music)
print('Generated 16 original SVG characters and 6 synthesized WAV tracks.')

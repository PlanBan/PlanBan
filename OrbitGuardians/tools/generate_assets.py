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
        '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 128 128">'
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

svg('ship', '''<path d="M20 47L8 22L58 44L84 35L123 64L84 91L57 83L8 106L20 80L5 64Z" fill="#112438" stroke="#60859d" stroke-width="2"/>
<path d="M17 51L49 48L99 55L122 64L96 74L49 81L17 76Z" fill="#bdd5df" stroke="#29485e" stroke-width="3"/>
<path d="M31 53L77 50L101 62L73 69L33 66Z" fill="#405f79"/>
<path d="M52 52L76 51L89 60L72 63L53 61Z" fill="#76e6f4"/>
<path d="M24 47L15 31L58 48M24 81L15 98L58 79" fill="#6d92a8" stroke="#2d4a62" stroke-width="2"/>
<path d="M23 56v17M34 46L51 45M34 83L51 84" stroke="#83eee1" stroke-width="4"/>
<path d="M103 61L120 64L104 68" fill="#edfaff"/><path d="M47 75h33" stroke="#718c9e" stroke-width="2"/>''')

# Each planet has a distinct silhouette and a visible class attachment.
palettes = [('#2d5347', '#80ed9e'), ('#779bae', '#c5f8ff'), ('#594047', '#ff9348'), ('#9b8058', '#ffe1a1'), ('#454166', '#d8a6ff')]
for planet, (body, accent) in enumerate(palettes):
    for index, kind in enumerate(['drone', 'runner', 'tank', 'disruptor', 'medic', 'boss']):
        bulky = kind in ['tank', 'boss']
        if planet == 0:
            character = cyborg(accent, '<path d="M30 18L15 5L21 35M95 17L111 3L108 35" fill="#426856"/><path d="M22 67Q47 34 72 61T103 89M35 109L50 77L86 87" fill="none" stroke="#64b678" stroke-width="5"/>', bulky)
            character = character.replace('#767a94', body).replace('#abb5c4', '#81ad91')
        elif planet == 1:
            character = f'''<ellipse cx="64" cy="112" rx="46" ry="6" fill="#102335" opacity=".4"/>
            <path d="M28 68L7 102L25 105L42 85M87 74L108 106L121 99L104 60M35 60L9 62L4 85M98 56L124 63L121 89" fill="none" stroke="#7ba3bc" stroke-width="8"/>
            <path d="M24 50L39 25L88 20L111 53L90 87L39 86Z" fill="{body}" stroke="#254e69" stroke-width="4"/>
            <path d="M33 48L24 14L49 39L66 5L75 39L102 11L95 53" fill="#d3f8ff" stroke="#709db9" stroke-width="2"/>
            <path d="M37 54h54v17H37Z" fill="#264862"/><path d="M45 62h13m13 0h13" stroke="{accent}" stroke-width="4"/>
            <path d="M40 78L64 96L90 78" fill="#b9ecf8"/>'''
        elif planet == 2:
            character = f'''<ellipse cx="64" cy="115" rx="35" ry="6" fill="#160f1c" opacity=".5"/>
            <path d="M43 86L29 110L45 117L62 93L85 116L103 110L86 82" fill="#4b3643" stroke="#272433" stroke-width="4"/>
            <path d="M21 42L41 29L90 30L112 45L96 91L61 105L29 84Z" fill="{body}" stroke="#261e2e" stroke-width="4"/>
            <path d="M34 23L25 4L54 23L76 21L103 2L94 30L86 55L43 54Z" fill="#a96856" stroke="#39293c" stroke-width="3"/>
            <path d="M43 34h43v13H43Z" fill="#261a2b"/><path d="M47 40h31" stroke="{accent}" stroke-width="5"/>
            <path d="M32 54L12 67L4 94L23 83M98 53L118 65L123 94L106 84" fill="#7b4d50" stroke="#392a3c" stroke-width="3"/>
            <path d="M64 54L86 75L65 95L45 75Z" fill="#ff6d35"/><path d="M64 62L72 75L64 86L56 75Z" fill="#fff2a3"/>
            <path d="M35 71l14 11m38-14-8 20M42 90l11 5" stroke="#ff9356" stroke-width="3"/>'''
        elif planet == 3:
            character = f'''<ellipse cx="64" cy="109" rx="51" ry="8" fill="#1d1821" opacity=".4"/>
            <path d="M33 41L9 30L4 48M30 57L5 63L8 80M35 79L12 94L20 109M96 41L117 30L123 48M98 57L123 63L120 80M94 79L116 94L108 109" fill="none" stroke="#c0a16c" stroke-width="7"/>
            <path d="M33 36L63 19L94 36L106 70L87 100L41 100L22 70Z" fill="{body}" stroke="#544939" stroke-width="4"/>
            <path d="M39 44L63 31L88 44L90 80L64 94L38 80Z" fill="#c6aa73"/><path d="M64 31v63M40 63h47" stroke="#7a674c" stroke-width="4"/>
            <path d="M44 51h40v17H44Z" fill="#423e36"/><path d="M48 59h29" stroke="{accent}" stroke-width="5"/>
            <path d="M42 22L30 5L46 10L56 24M85 21L99 3L88 9L76 25" fill="#e1c28a"/>'''
        else:
            character = f'''<ellipse cx="64" cy="114" rx="31" ry="5" fill="#110e27" opacity=".5"/>
            <path d="M64 9L102 34L114 65L89 96L64 110L34 96L13 65L25 34Z" fill="{body}" stroke="#221b3e" stroke-width="4"/>
            <path d="M30 34L63 20L96 35L88 48L39 48Z" fill="#8982b0"/>
            <path d="M35 49h59v19H35Z" fill="#221a39"/><path d="M42 59h14m17 0h14" stroke="{accent}" stroke-width="5"/>
            <path d="M44 77L64 70L83 77L76 97L64 103L51 94Z" fill="#a47be0"/>
            <path d="M64 76L71 84L64 95L57 84Z" fill="#f2d8ff"/>
            <path d="M15 34L5 58L13 83M113 34L123 58L115 83" stroke="#cc9cf8" stroke-width="4" fill="none"/>
            <path d="M38 110l-9 10m36-11v15m29-16 9 10" stroke="#835cc7" stroke-width="3"/>'''
        extra = ''
        if kind == 'runner': extra = f'<path d="M25 51L8 45L19 60M102 51L120 45L109 61" fill="{accent}"/>'
        if kind == 'tank': extra = '<path d="M16 51h21v37H13M92 51h22v37H94" fill="#71818b" stroke="#263545" stroke-width="3"/>'
        if kind == 'disruptor': extra = f'<circle cx="64" cy="15" r="12" fill="#302e48" stroke="{accent}" stroke-width="3"/><path d="M59 8l9 7-9 8" stroke="{accent}" stroke-width="3" fill="none"/>'
        if kind == 'medic': extra = '<path d="M61 74v18m-9-9h18" stroke="#a2ffc9" stroke-width="5"/>'
        if kind == 'boss': extra = f'<path d="M29 26L21 3L49 18L65 1L83 17L111 3L103 28Z" fill="{accent}" stroke="#524251" stroke-width="3"/><path d="M18 64L3 69L9 99M111 64L125 69L119 99" stroke="{accent}" stroke-width="5" fill="none"/>'
        svg(f'p{planet}_{kind}', character + extra)

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
print('Generated original robot art, 30 planet enemies, a ship and 6 synthesized WAV tracks.')

"""Original vector engravings for the physical route tokens. No font glyphs."""
from pathlib import Path
OUT=Path(__file__).resolve().parents[1]/'assets3d/diorama/icons'
OUT.mkdir(parents=True,exist_ok=True)
ICONS={
 'swords':'<path d="M20 17L71 68M16 18l12-2-2 12M25 61l18 18M21 77l12-12M78 17L27 68M82 18l-12-2 2 12M75 61L57 79M79 77L67 65"/>',
 'question':'<path d="M32 31c0-21 39-23 39-2 0 15-22 15-22 31"/><circle cx="49" cy="76" r="3" fill="white"/>',
 'cards':'<path d="M23 21l35-5 10 59-35 5zM40 23l35 4-7 58-35-4M49 31h30v51H49z"/><path d="M57 44l7-7 7 7-7 7z"/>',
 'wrench':'<path d="M25 82L59 48c-6-13-2-26 12-32l-1 16 12 6 13-9c2 16-9 28-25 26L36 89z"/><circle cx="31" cy="80" r="3"/>',
 'fire':'<path d="M31 65c-7-18 12-26 13-48 15 16 10 20 20 30 5-7 6-11 6-16 23 28 10 48-18 48-11 0-19-3-21-14zM46 70c-8-10 3-14 7-28 3 10 19 24 7 33"/><path d="M20 84l61 7M20 91l61-7"/>',
 'chest':'<path d="M20 36h60v46H20zM20 36l8-16h43l9 16M31 36v46M70 36v46M44 40h13v16H44zM16 57h24M62 57h22"/>',
 'recycle':'<path d="M29 36l20-21 20 20M46 15l-7 1M77 43l11 28-29 7M88 70l-2-8M49 86L20 74l5-29M20 75l8-3"/>',
 'planet':'<ellipse cx="50" cy="50" rx="30" ry="29"/><ellipse cx="50" cy="50" rx="45" ry="11" transform="rotate(-25 50 50)"/><path d="M39 25l-9 19 12 9-6 21M60 27l8 11-13 15 14 15"/>',
 'skull':'<path d="M23 40c0-34 56-34 56 0v19L67 69v15H35V69L23 59zM35 73v10M46 74v11M57 74v11M67 73v10"/><path d="M32 40l13 6-4 10-10-2zM70 40l-13 6 4 10 10-2zM51 56l-5 9h10z" fill="white"/>',
 'ship':'<path d="M51 12l20 43-9 9 11 21-22-9-22 9 11-21-9-9zM45 44h12v13H45zM22 62L13 83M79 62l8 21"/>'
}
for name,paths in ICONS.items():
 (OUT/(name+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 100 100"><g fill="none" stroke="white" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">'+paths+'</g></svg>')
print('ROUTE ICONS:',len(ICONS))

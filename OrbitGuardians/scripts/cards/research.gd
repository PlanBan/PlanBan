extends RefCounted
class_name AstraResearch
## Expedition technology: prerequisites, costs and immutable battle snapshots.
const BRANCHES = ["weapons","frames","core","systems"]
const COLORS = [Color("ff526c"),Color("ffd75b"),Color("55bfff"),Color("7aefc6")]
const COSTS = [18,36,60]
const NAMES = [
 [["Калибровка","Calibration","Kalibrierung"],["Точный прицел","Precision aim","Präzises Zielen"],["Разгон орудий","Weapon overdrive","Waffenverstärkung"]],
 [["Усиленный корпус","Reinforced chassis","Verstärktes Gehäuse"],["Бронеплиты","Armour plates","Panzerplatten"],["Нанокаркас","Nano frame","Nanorahmen"]],
 [["Резерв ядра I","Core reserve I","Kernreserve I"],["Резерв ядра II","Core reserve II","Kernreserve II"],["Резерв ядра III","Core reserve III","Kernreserve III"]],
 [["Пусковая батарея","Startup battery","Startbatterie"],["Банк энергии","Energy bank","Energiebank"],["Протокол спасения","Rescue protocol","Rettungsprotokoll"]]
]
const EFFECTS = [
 [["Роботам +1 атака","Robots gain +1 attack","Roboter: +1 Angriff"],["Прицел даёт +2 урона","Aim grants +2 damage","Zielen gibt +2 Schaden"],["Роботам ещё +1 атака","Robots gain another +1 attack","Roboter: nochmals +1 Angriff"]],
 [["Роботам +2 HP","Robots gain +2 HP","Roboter: +2 LP"],["Броня 1 снижает каждый удар","Armour 1 reduces each hit","Panzerung 1 mindert jeden Treffer"],["Роботам ещё +2 HP","Robots gain another +2 HP","Roboter: nochmals +2 LP"]],
 [["Максимум ядра +4 HP; лечение 4","Core maximum +4 HP; heal 4","Kernmaximum +4 LP; heile 4"],["Максимум ядра +4 HP; лечение 4","Core maximum +4 HP; heal 4","Kernmaximum +4 LP; heile 4"],["Максимум ядра +4 HP; лечение 4","Core maximum +4 HP; heal 4","Kernmaximum +4 LP; heile 4"]],
 [["Первый ход: +1 энергия","First turn: +1 energy","Erster Zug: +1 Energie"],["Каждый ход: +1 энергия","Every turn: +1 energy","Jeder Zug: +1 Energie"],["Ремонт ядра лечит ещё 4 HP","Core repair heals another 4 HP","Kernreparatur heilt weitere 4 LP"]]
]
static func defaults() -> Dictionary:
 return {"weapons":0,"frames":0,"core":0,"systems":0}
static func valid(value: Variant) -> bool:
 if not value is Dictionary or value.size() != 4: return false
 for key in BRANCHES:
  if not integer(value.get(key),0,3): return false
 return true
static func bonuses(value: Dictionary) -> Dictionary:
 var w = int(value.get("weapons",0)); var f = int(value.get("frames",0)); var s = int(value.get("systems",0))
 return {"attack":int(w>=1)+int(w>=3),"hp":2*int(f>=1)+2*int(f>=3),"armor":int(f>=2),"aim":2 if w>=2 else 1,"opening":int(s>=1),"energy":int(s>=2),"healing":4 if s>=3 else 0}
static func valid_bonuses(value: Variant) -> bool:
 if not value is Dictionary: return false
 for key in ["attack","hp","armor","aim","opening","energy","healing"]:
  var limits = {"attack":[0,2],"hp":[0,4],"armor":[0,1],"aim":[1,2],"opening":[0,1],"energy":[0,1],"healing":[0,4]}
  if not integer(value.get(key),limits[key][0],limits[key][1]): return false
 return true

static func integer(value: Variant, low: int, high: int) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=low and value<=high

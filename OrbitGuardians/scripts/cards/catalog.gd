extends RefCounted
class_name AstraCards
## Card data adapts the existing robot identities; numerical upgrades are run-local.
const PLANETS = ["Вердия", "Борея", "Игнис", "Аурика", "Нексус"]
const COLORS = [Color("76bd93"), Color("87cfe9"), Color("ee8d51"), Color("d6bc78"), Color("b39bea")]
const CARDS = {
 "pulse": {"name":["Импульс","Pulse","Impuls"],"cost":1,"attack":2,"hp":2,"rarity":0,"effect":"refund","art":"pulse"},
 "reactor": {"name":["Реактор","Reactor","Reaktor"],"cost":2,"attack":0,"hp":4,"rarity":0,"effect":"energy","art":"reactor"},
 "shield": {"name":["Бастион","Bastion","Bastion"],"cost":3,"attack":1,"hp":6,"rarity":1,"effect":"guard","art":"shield"},
 "cryo": {"name":["Криобот","Cryobot","Kryobot"],"cost":3,"attack":2,"hp":3,"rarity":1,"effect":"freeze","art":"cryo"},
 "burst": {"name":["Спарка","Twin Spark","Zwillingsfunke"],"cost":3,"attack":1,"hp":3,"rarity":1,"effect":"double","art":"burst"},
 "rail": {"name":["Рельсотрон","Railgun","Railgun"],"cost":4,"attack":4,"hp":3,"rarity":2,"effect":"pierce","art":"rail"},
 "mortar": {"name":["Комета","Comet","Komet"],"cost":4,"attack":3,"hp":4,"rarity":2,"effect":"splash","art":"mortar"},
 "mechanic": {"name":["Механик","Mechanic","Mechaniker"],"cost":2,"attack":1,"hp":4,"rarity":1,"effect":"mend","art":"repair"},
 "nova": {"name":["Сверхновая","Supernova","Supernova"],"cost":4,"attack":2,"hp":3,"rarity":3,"effect":"deathburst","art":"nova"},
 "repair": {"name":["Ремонт","Repair","Reparatur"],"cost":1,"attack":0,"hp":0,"rarity":0,"effect":"heal","art":"repair","target":"friend"},
 "overload": {"name":["Перегрузка","Overload","Überlastung"],"cost":2,"attack":0,"hp":0,"rarity":1,"effect":"overload","art":"nova","target":"all"},
 "barrier": {"name":["Аварийный щит","Emergency shield","Notschild"],"cost":1,"attack":0,"hp":0,"rarity":0,"effect":"barrier","art":"shield","target":"friend"},
 "astra": {"name":["Импульс Астры","Astra pulse","Astra-Impuls"],"cost":0,"attack":0,"hp":0,"rarity":4,"effect":"boost","art":"reactor","target":"all"},
 "emp": {"name":["ЭМИ","EMP","EMP"],"cost":2,"attack":0,"hp":0,"rarity":2,"effect":"emp","art":"cryo","target":"enemy"},
 "recall": {"name":["Пересборка","Reassembly","Neuaufbau"],"cost":0,"attack":0,"hp":0,"rarity":1,"effect":"recall","art":"repair","target":"friend"},
 "verdant": {"name":["Симбионт","Symbiont","Symbiont"],"cost":2,"attack":2,"hp":4,"rarity":2,"effect":"regen","art":"pulse","planet":0},
 "frost": {"name":["Ледяная призма","Frost prism","Frostprisma"],"cost":1,"attack":0,"hp":0,"rarity":2,"effect":"frost","art":"cryo","target":"all","planet":1},
 "ember": {"name":["Пепельный дрон","Ember drone","Glutdrohne"],"cost":2,"attack":3,"hp":3,"rarity":2,"effect":"burn","art":"burst","planet":2},
 "storm": {"name":["Конденсатор","Capacitor","Kondensator"],"cost":1,"attack":0,"hp":0,"rarity":2,"effect":"storm","art":"reactor","target":"all","planet":3},
 "echo": {"name":["Эхо Астры","Astra echo","Astra-Echo"],"cost":3,"attack":3,"hp":4,"rarity":4,"effect":"echo","art":"nova","planet":4}
}
const EFFECTS = {
 "armor":["Броня: поглощает 2 урона","Armour: absorbs 2 damage","Panzerung: absorbiert 2 Schaden"],
 "jam":["Отключает способность цели","Disables target's ability","Schaltet Zielfähigkeit ab"],
 "refund":["За убийство: +1 энергия","On kill: +1 energy","Bei Abschuss: +1 Energie"],
 "energy":["Каждый ход: +1 энергия","Each turn: +1 energy","Pro Zug: +1 Energie"],
 "guard":["Щит 2; прикрывает соседей","Shield 2; guards neighbours","Schild 2; schützt Nachbarn"],
 "freeze":["Замораживает цель на ход","Freezes target for one turn","Friert Ziel für einen Zug ein"],
 "double":["Две атаки за ход","Attacks twice each turn","Greift zweimal pro Zug an"],
 "pierce":["Пробивает: 1 урон ядру","Pierces: 1 core damage","Durchschlag: 1 Kernschaden"],
 "splash":["Соседям цели: 1 урон","Target's neighbours: 1 damage","Zielnachbarn: 1 Schaden"],
 "mend":["Каждый ход: ремонт соседей","Each turn: repairs neighbours","Pro Zug: repariert Nachbarn"],
 "deathburst":["При гибели: всем врагам 2","On death: 2 to all enemies","Bei Tod: 2 an alle Gegner"],
 "heal":["Ремонт союзника: 4 здоровья","Repair ally: 4 health","Verbündeten heilen: 4 LP"],
 "overload":["Всем врагам: 2 урона","All enemies: 2 damage","Alle Gegner: 2 Schaden"],
 "barrier":["Щит союзнику на ход: 3","Ally shield for one turn: 3","Schild für einen Zug: 3"],
 "boost":["+2 энергии; добор карты","+2 energy; draw a card","+2 Energie; eine Karte ziehen"],
 "emp":["Отключение цели на ход","Disables target for one turn","Schaltet Ziel einen Zug ab"],
 "recall":["Вернуть союзника в руку","Return an ally to your hand","Verbündeten zurück auf die Hand"],
 "regen":["Каждый ход: +1 здоровье","Each turn: +1 health","Pro Zug: +1 LP"],
 "frost":["Враги пропускают атаку","Enemies skip their attacks","Gegner setzen Angriffe aus"],
 "burn":["Поджигает: 1 урон за ход","Ignites: 1 damage each turn","Entzündet: 1 Schaden pro Zug"],
 "storm":["+3 энергии; ядру −1 HP","+3 energy; core loses 1 HP","+3 Energie; Kern verliert 1 LP"],
 "echo":["Без цели: добор карты","No opposing card: draw one","Ohne Gegenkarte: Karte ziehen"]
}
const ENEMIES = {
 "drone":{"name":["Сборщик","Collector","Sammler"],"attack":1,"hp":3,"effect":"","art":"drone"},
 "runner":{"name":["Резчик","Ripper","Schlitzer"],"attack":2,"hp":2,"effect":"","art":"runner"},
 "tank":{"name":["Оплот","Bulwark","Bollwerk"],"attack":1,"hp":5,"effect":"armor","art":"tank"},
 "medic":{"name":["Сшиватель","Stitcher","Flicker"],"attack":1,"hp":4,"effect":"regen","art":"medic"},
 "disruptor":{"name":["Глушитель","Silencer","Störer"],"attack":2,"hp":3,"effect":"jam","art":"disruptor"},
 "elite":{"name":["Охотник","Hunter","Jäger"],"attack":3,"hp":5,"effect":"burn","art":"tank"},
 "boss":{"name":["Архонт","Archon","Archon"],"attack":3,"hp":8,"effect":"guard","art":"boss"}
}
const BOSSES = [["Корневой страж","Root sentinel","Wurzelwächter"],["Королева метели","Blizzard queen","Schneekönigin"],["Кузнец пепла","Ash forger","Ascheschmied"],["Пожиратель бури","Storm devourer","Sturmverschlinger"],["Нулевой разум","The zero mind","Der Nullgeist"]]
const CLANS = [["Корневой","Root","Wurzel"],["Ледяной","Frost","Frost"],["Пепельный","Ash","Asche"],["Песчаный","Sand","Sand"],["Квантовый","Quantum","Quanten"]]
const RULES = [
 ["Сборщики регенерируют 1 HP за ход","Collectors regenerate 1 HP each turn","Sammler regenerieren 1 LP pro Zug"],
 ["Каждый 4-й ход: холод; у врагов щиты","Every 4th turn: frost; enemies have shields","Jeder 4. Zug: Frost; Gegner haben Schilde"],
 ["Каждый 3-й ход: перегрев наносит 1 урон","Every 3rd turn: overheat deals 1 damage","Jeder 3. Zug: Überhitzung verursacht 1 Schaden"],
 ["Чётный ход: +1 нестабильная энергия","Even turns: +1 unstable energy","Gerade Züge: +1 instabile Energie"],
 ["Каждый 4-й ход: Нексус глушит способность","Every 4th turn: Nexus jams an ability","Jeder 4. Zug: Nexus stört eine Fähigkeit"]
]
const STARTERS = ["pulse","pulse","pulse","pulse","reactor","reactor","shield","cryo","repair","repair","overload","astra"]
const NODE_KINDS = ["battle","event","reward","upgrade","rest","shop","remove","elite","planet"]
const NODE_NAMES = {
 "battle":["Перехват","Intercept","Abfangen"],"elite":["Элитный охотник","Elite hunter","Elitejäger"],"boss":["Сигнал Архонта","Archon signal","Archon-Signal"],
 "event":["Неизвестный сигнал","Unknown signal","Unbekanntes Signal"],"reward":["Тайник карт","Card cache","Kartenversteck"],
 "upgrade":["Верстак","Workbench","Werkbank"],"rest":["Ремонтный док","Repair dock","Reparaturdock"],"shop":["Торговый автомат","Trade terminal","Handelsterminal"],"remove":["Переработка","Recycle bay","Recycling"],"planet":["Память планеты","Planet memory","Planetengedächtnis"]
}
const GLYPHS = {"battle":"×","elite":"!","boss":"Ω","event":"?","reward":"▤","upgrade":"+","rest":"◇","shop":"$","remove":"−","planet":"◎"}
static func lang_index(language: String) -> int:
 return ["ru","en","de"].find(language) if language in ["ru","en","de"] else 0
static func word(values: Array, language: String) -> String:
 return values[lang_index(language)]
static func card(id: String, upgrade: int = 0) -> Dictionary:
 var result: Dictionary = CARDS[id].duplicate(true)
 result.id = id
 result.upgrade = upgrade
 if result.hp > 0:
  result.attack += upgrade
  result.hp += upgrade * 2
 elif upgrade > 0: result.cost = maxi(0, result.cost - upgrade)
 return result
static func reward_pool(act: int, unlocked: Array) -> Array:
 var result: Array = []
 for id in CARDS:
  if CARDS[id].get("planet", -1) == act or (not CARDS[id].has("planet") and id in unlocked): result.append(id)
 return result
static func starter(kind: int) -> Array:
 if kind == 1: return ["pulse","pulse","pulse","shield","shield","reactor","reactor","mechanic","barrier","repair","overload","astra"]
 if kind == 2: return ["pulse","pulse","pulse","reactor","reactor","reactor","burst","repair","barrier","astra","astra","recall"]
 return STARTERS.duplicate()
static func integers(value: Variant) -> Variant:
 # JSON parses integer fields as floats. Model quantities and IDs are discrete.
 if value is float: return int(value)
 if value is Array:
  var result: Array = []
  for item in value: result.append(integers(item))
  return result
 if value is Dictionary:
  var result = {}
  for key in value: result[key] = integers(value[key])
  return result
 return value

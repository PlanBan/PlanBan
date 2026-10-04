extends RefCounted
class_name OrbitContent
## 50 explicit campaign missions; each first completion awards its own seed.

const LEVEL_COUNT = 50
const STARTERS = ["core_pulse", "core_reactor", "core_shield"]
const TYPES = ["pulse", "reactor", "shield", "cryo", "burst", "rail", "mortar", "repair", "nova"]
const TYPE_NAMES = {
	"pulse": "Импульс", "reactor": "Реактор", "shield": "Бастион",
	"cryo": "Криобот", "burst": "Спарка", "rail": "Рельсотрон",
	"mortar": "Комета", "repair": "Механик", "nova": "Сверхновая"
}
const DESCRIPTIONS = {
	"pulse": "Стреляет по своей дорожке",
	"reactor": "Вырабатывает энергию каждые 7 с",
	"shield": "Блокирует киборгов прочной бронёй",
	"cryo": "Замедляет врагов на 3 секунды",
	"burst": "Выпускает два заряда за залп",
	"rail": "Пробивает всех врагов по дорожке",
	"mortar": "Взрыв поражает соседние дорожки",
	"repair": "Ремонтирует соседних роботов",
	"nova": "Одноразовый взрыв через 5 секунд"
}
const BASE = {
	"pulse": {"cost": 80, "hp": 140.0, "damage": 13.0, "interval": 1.45},
	"reactor": {"cost": 50, "hp": 110.0, "damage": 0.0, "interval": 7.0},
	"shield": {"cost": 90, "hp": 850.0, "damage": 0.0, "interval": 1.0},
	"cryo": {"cost": 110, "hp": 150.0, "damage": 7.0, "interval": 1.8},
	"burst": {"cost": 140, "hp": 160.0, "damage": 11.0, "interval": 1.7},
	"rail": {"cost": 180, "hp": 160.0, "damage": 23.0, "interval": 2.4},
	"mortar": {"cost": 160, "hp": 160.0, "damage": 20.0, "interval": 2.2},
	"repair": {"cost": 100, "hp": 170.0, "damage": 0.0, "interval": 2.8},
	"nova": {"cost": 130, "hp": 130.0, "damage": 165.0, "interval": 5.0}
}
const COLORS = ["80d8a7", "a0dffa", "ffae76", "e6cd93", "c89bf1"]
const SECTORS = ["Вердия · Живая планета", "Борея · Мир льда", "Игнис · Огненная планета", "Аурика · Песчаный мир", "Нексус · Машинное сердце"]
const PLANET_NAMES = ["Вердия", "Борея", "Игнис", "Аурика", "Нексус"]
const TERRAIN = ["forest", "ice", "lava", "desert", "void"]
const BIOME_INFO = [
	"Заросшие рейдеры восстанавливают броню. Здесь начинается след украденного ядра.",
	"Ледяные машины защищены кристальным щитом. Снег скрывает полярные крепости.",
	"Огненные киборги ускоряются, когда ранены. Продвигайтесь через реки лавы.",
	"Песчаные скарабеи гасят часть урона своей бронёй. Дюны ведут к древним храмам.",
	"Квантовые бегуны меняют дорожки. Сердце машин хранит наше ядро."
]
const LOCATION_NAMES = [
	["Лесной причал", "Долина папоротников", "Заросший шлюз", "Берег озера", "Охотничья поляна", "Корни гиганта", "Споровый лес", "Сломанный мост", "Древний купол", "Сердце чащи"],
	["Полярная высадка", "Замёрзшая бухта", "Ледяной каньон", "Снежный перевал", "Крепость метели", "Кристальные пещеры", "Озеро подо льдом", "Северный маяк", "Белый разлом", "Ледяной трон"],
	["Пепельный порт", "Базальтовый берег", "Огненная река", "Угольные шахты", "Горящий бастион", "Жерло вулкана", "Мост над лавой", "Кузница киборгов", "Красный кратер", "Пламенная цитадель"],
	["Дюнный причал", "Оазис обломков", "Золотой бархан", "Ущелье ветров", "Башня миражей", "Засыпанный храм", "Стеклянная пустыня", "Караванный путь", "Город песка", "Трон бури"],
	["Чёрный шлюз", "Неоновая пропасть", "Мост импульсов", "Сеть сознаний", "Часовой Нексуса", "Архив машин", "Квантовый лабиринт", "Штормовой лифт", "Хранилище ядра", "Последний сигнал"]
]
const MODES = ["Обычная орбита", "Магнитный шторм", "Скоростной рейд", "Броневой конвой", "ЭМИ-фронт"]
const MODE_INFO = [
	"Сбалансированная атака. Приготовьте защиту каждой дорожки.",
	"Энергия из космоса приходит реже. Реакторы особенно важны.",
	"Больше быстрых киборгов. Криоботы помогут их замедлить.",
	"Много броневых врагов. Используйте залпы и рельсотроны.",
	"Каждые 25 секунд ЭМИ выключает роботов на 1,4 секунды."
]

static func robots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for kind in ["pulse", "reactor", "shield"]:
		result.append(make_robot("core_" + kind, kind, 0))
	# First rewards deliberately introduce the six new mechanics.
	var reward_types = ["cryo", "burst", "repair", "mortar", "rail", "nova", "reactor", "shield", "pulse"]
	for level in range(1, LEVEL_COUNT + 1):
		var kind: String = reward_types[(level - 1) % reward_types.size()]
		result.append(make_robot("seed_%02d" % level, kind, level))
	return result

static func make_robot(id: String, kind: String, unlock: int) -> Dictionary:
	var tier = 0 if unlock == 0 else int((unlock - 1) / 10) + 1
	var tuning = 0 if unlock == 0 else (unlock - 1) % 10
	var power = 1.0 + tier * 0.19 + tuning * 0.018
	var hp_scale = 1.0 + tier * 0.17 + tuning * 0.012
	var base: Dictionary = BASE[kind]
	return {
		"id": id, "kind": kind, "unlock": unlock, "tier": tier,
		"name": TYPE_NAMES[kind] if unlock == 0 else "%s · %02d" % [TYPE_NAMES[kind], unlock],
		"description": DESCRIPTIONS[kind], "color": COLORS[maxi(tier - 1, 0) % COLORS.size()],
		"cost": int(base.cost + tier * (5 if kind in ["reactor", "shield"] else 8)),
		"hp": base.hp * hp_scale, "damage": base.damage * power,
		"interval": base.interval / (1.0 + tier * 0.04),
		"energy": 30 + tier * 5 + int(tuning / 3),
		"cooldown": 1.8 if kind == "shield" else (4.0 if kind == "nova" else 0.65)
	}

static func level(number: int) -> Dictionary:
	number = clampi(number, 1, LEVEL_COUNT)
	var sector = int((number - 1) / 10)
	var mode = (number - 1) % 5
	var waves = 2 if number == 1 else (3 if number <= 10 else (4 if number <= 30 else 5))
	var lanes = [1, 2, 3] if number <= 2 else [0, 1, 2, 3, 4]
	var blocked: Array[Vector2i] = []
	if number >= 8 and number % 3 == 2:
		blocked.append(Vector2i(6, (number * 7) % 5))
	if number >= 25 and number % 4 == 0:
		blocked.append(Vector2i(5, (number + 2) % 5))
	var batches: Array[Array] = []
	for wave in range(waves):
		var batch: Array[Dictionary] = []
		var count = 3 + int(number / 8) + wave * 2
		for i in range(count):
			var kind = "drone"
			if number >= 2 and (i + wave) % (3 if mode == 2 else 5) == 2: kind = "runner"
			if number >= 4 and (i + wave * 2) % (3 if mode == 3 else 6) == 3: kind = "tank"
			if number >= 12 and (i + number) % 7 == 4: kind = "disruptor"
			if number >= 22 and (i + wave) % 9 == 7: kind = "medic"
			if number % 5 == 0 and wave == waves - 1 and i == count - 1: kind = "boss"
			var stride = 2 if lanes.size() == 3 else 3
			batch.append({"kind": kind, "row": lanes[(i * stride + wave + number - 1) % lanes.size()]})
		batches.append(batch)
	return {
		"number": number, "sector": sector, "name": LOCATION_NAMES[sector][(number - 1) % 10], "terrain": TERRAIN[sector],
		"sector_name": SECTORS[sector], "mode": mode, "mode_name": MODES[mode],
		"description": MODE_INFO[mode], "color": COLORS[sector], "lanes": lanes,
		"blocked": blocked, "waves": batches, "start_energy": 240 + sector * 20,
		"sky_interval": 9.0 if mode == 1 else 6.0,
		"spawn_interval": maxf(1.8, 3.4 - number * 0.025 - (0.35 if mode == 2 else 0.0)),
		"enemy_scale": 1.0 + number * 0.025, "reward": "seed_%02d" % number,
		"boss": number % 5 == 0
	}

static func enemy(kind: String, number: int) -> Dictionary:
	var base = {"hp": 40.0, "speed": 15.0, "bite": 25.0}
	match kind:
		"runner": base = {"hp": 28.0, "speed": 27.0, "bite": 20.0}
		"tank": base = {"hp": 105.0, "speed": 11.0, "bite": 34.0}
		"disruptor": base = {"hp": 72.0, "speed": 16.0, "bite": 29.0}
		"medic": base = {"hp": 60.0, "speed": 13.0, "bite": 23.0}
		"boss": base = {"hp": 240.0 + number * 3.0, "speed": 8.0, "bite": 48.0}
	var scale = 1.0 + number * 0.025
	return {"hp": base.hp * scale, "speed": base.speed + number * 0.09, "bite": base.bite * (1 + number * 0.01)}

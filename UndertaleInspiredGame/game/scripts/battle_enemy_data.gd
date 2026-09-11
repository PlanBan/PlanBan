extends Resource
class_name BattleEnemyData

@export_category("Identity")
@export var enemy_id: StringName = &"test_enemy"
@export var display_name: String = "Wurzel-Novize"
@export var visual_scene: PackedScene

@export_category("Stats")
@export var max_hp: int = 36
@export var defense: int = 0
@export var attack_damage: int = 3
@export var fight_damage_min: int = 4
@export var fight_damage_max: int = 13

@export_category("Dialogue")
@export_multiline var intro_text: String = "Ein stiller Wächter tritt aus den Wurzeln."
@export_multiline var turn_text: String = "Der Wächter hebt seine Wurzelklinge."
@export_multiline var fight_hit_text: String = "Der Treffer hallt durch die Halle."
@export_multiline var mercy_ready_text: String = "Sein Griff lockert sich. Er wartet auf deine Entscheidung."
@export_multiline var mercy_text: String = "Der Wächter senkt die Klinge. \"Geh. Und vergiss nicht, dass Zuhören auch eine Waffe ist.\""
@export_multiline var defeat_text: String = "Der Wächter zerfällt zu stillen Moosblättern."

@export_category("ACT / Mercy")
@export var mercy_required: int = 2
@export var act_names: PackedStringArray = ["ZUHÖREN", "VERBEUGEN"]
@export var act_mercy_values: PackedInt32Array = [1, 1]
@export var act_responses: PackedStringArray = [
	"Du hörst nur Atem und das Knarren alter Wurzeln. Der Wächter wird ruhiger.",
	"Du verbeugst dich. Nach kurzem Zögern erwidert der Wächter die Geste."
]

@export_category("Enemy Turn")
@export var enemy_turn_duration: float = 5.4
@export var bullet_interval: float = 0.46
@export var bullet_speed: float = 165.0
@export var attack_patterns: PackedStringArray = ["rain", "sides", "aimed"]

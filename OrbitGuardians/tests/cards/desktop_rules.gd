extends SceneTree
var checks = 0
var failures = 0
func check(value: bool, name: String) -> void:
 checks += 1
 if not value: failures += 1; printerr("FAIL: ",name)
func _initialize() -> void:
 var run = AstraRun.new(); run.path = "user://qa_desktop_rules.json"; run.meta_path = "user://qa_desktop_meta.json"; run.new_run(41293)
 run.start_training()
 var battle = run.battle
 check(battle.data.hand.size() == 1 and battle.data.hand[0].id == "pulse" and battle.data.energy == 1,"training starts with one real card and one energy")
 check(not battle.end_turn() and not battle.play(0,"friendly",0),"training explains opposing lane before allowing turn")
 check(battle.play(0,"friendly",1) and battle.data.tutorial_step == 1,"training advances only after correct deployment")
 check(run.save() and run.valid_save({"format":"astra_tabletop","version":4,"run":run.data}),"training checkpoint validates with all owned cards")
 battle.end_turn(); battle.resolve_next(); run.save()
 var copy = AstraRun.new(); copy.path = run.path; copy.meta_path = run.meta_path; copy.load_all()
 check(copy.battle.data.phase == "resolving" and copy.battle.data.pending == battle.data.pending,"training restores exact pending actions")
 battle.resolve_all(); copy.battle.resolve_all()
 check(JSON.stringify(battle.checkpoint()) == JSON.stringify(copy.battle.checkpoint()),"training continuation applies no duplicate damage")
 check(battle.data.tutorial_step == 3 and battle.data.hand.size() == 1 and battle.data.hand[0].id == "reactor" and battle.data.energy == 2,"reactor appears only when its lesson begins")
 check(not battle.end_turn() and battle.play(0,"friendly",3),"reactor lesson is guided")
 battle.end_turn(); battle.resolve_all()
 check(battle.data.energy == 3 and battle.data.max_energy == 3 and battle.data.enemy_core == 2,"reactor and core attacks are explained with honest energy meter")
 battle.end_turn(); battle.resolve_all(); run.finish_battle()
 check(run.data.state == "map" and run.data.depth == -1 and run.data.core == 20 and run.data.battles == 0,"training ends before route without free cards or consumed encounter")
 run.choose_node("0_1")
 check(battle.data.hand.size() == 3 and battle.data.energy == 2 and battle.data.ruleset == 42,"ordinary battle has restrained opening")
 var index = -1
 for i in range(battle.data.hand.size()):
  if battle.data.hand[i].id == "pulse": index = i; break
 battle.play(index,"friendly",0)
 check(battle.order(0,"aim") and battle.data.energy == 0,"aim competes with card deployment for energy")
 check(not battle.order(0,"guard") and not battle.order(1,"guard"),"cannot issue two orders or order an empty cell")
 battle.end_turn(); var before = battle.data.enemy_core; battle.resolve_next()
 check(battle.data.enemy_core == before-3 and battle.data.friendly[0].get("focus",0) == 0,"aim boosts exactly one strike")
 run.save(); copy.load_all()
 battle.resolve_all(); copy.battle.resolve_all()
 check(JSON.stringify(battle.checkpoint()) == JSON.stringify(copy.battle.checkpoint()),"ordered attack resumes without applying bonus twice")
 check(battle.order(0,"guard") and battle.data.friendly[0].temporary == 2,"guard supplies a real temporary shield")
 var hp = battle.data.friendly[0].hp
 battle.hurt("friendly",0,3,"enemy")
 check(battle.data.friendly[0].hp == hp-1,"guard blocks two incoming damage")
 battle.end_turn(); battle.resolve_all()
 check(battle.data.friendly[0].temporary == 0,"guard expires at next turn")
 battle.data.enemy = [null,null,null,null]; battle.data.intent.clear()
 battle.data.friendly[0] = null
 # Isolated resource fixture: compare one and two reactors under the same rules.
 battle.data.friendly[1] = battle.instance({"id":"reactor","uid":201,"upgrade":0})
 battle.data.friendly[2] = battle.instance({"id":"reactor","uid":202,"upgrade":0})
 battle.data.turn = 1; battle.next_round()
 check(battle.data.energy == 3 and battle.data.max_energy == 3,"reactors do not multiply energy generation")
 battle.data.turn = 20; battle.next_round()
 check(battle.data.energy == 4 and battle.data.max_energy == 4,"base growth stops at three plus one reactor")
 battle.gain_energy(100)
 check(battle.data.energy == 5 and battle.data.max_energy == 5,"temporary bonuses obey global cap and HP-style meter remains consistent")
 battle.draw_cards(100)
 check(battle.data.hand.size() <= 5,"draw and echo cannot overflow hand")
 battle.data.turn = 1; battle.plan_intent(); check(battle.data.intent.is_empty(),"opening turn gives time to establish defence")
 battle.data.turn = 2; battle.plan_intent(); check(battle.data.intent.size() <= 1,"reinforcements are paced and visible")
 var old = battle.checkpoint(); old.erase("ruleset"); old.hand.clear(); old.energy = 7; old.max_energy = 3
 copy.battle.restore(old)
 check(not copy.battle.modern() and copy.battle.data.energy == 7,"old saves retain their current energy instead of being discarded")
 copy.battle.draw_cards(100); check(copy.battle.data.hand.size() <= 7,"legacy hand remains compatible and uses UI pagination")
 var prefs = OrbitProgress.new(); prefs.data.ui_scale = "bad"; prefs.sanitize_preferences()
 check(prefs.data.ui_scale == 1.0,"invalid text size is safely defaulted")
 prefs.data.ui_scale = 5; prefs.sanitize_preferences(); check(prefs.data.ui_scale == 1.25,"text size has a supported upper bound")
 for lang in ["ru","en","de"]:
  check(AstraDesktopWords.get_text("lesson0",lang) != "lesson0" and AstraDesktopWords.get_text("guard",lang) != "guard","desktop instructions translated: "+lang)
 for path in [run.path,run.meta_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 print("DESKTOP RULES: ",checks," checks, ",failures," failures")
 quit(0 if failures == 0 else 1)

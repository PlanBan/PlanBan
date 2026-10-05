extends SceneTree
var checks = 0
var failures = 0
func check(condition: bool, name: String) -> void:
 checks += 1
 if not condition: failures += 1; printerr("FAIL: ",name)
func _initialize() -> void:
 var run = AstraRun.new()
 run.path = "user://qa_cards_run.json"; run.meta_path = "user://qa_cards_meta.json"
 run.load_all(); run.new_run(41293)
 check(run.data.deck.size() == 12,"starter deck")
 check(run.data.map.size() == 17,"seven depth branching map")
 run.data.state = "map"
 check(run.choose_node("0_1"),"first encounter")
 var battle = run.battle
 check(battle.data.hand.size() == 5 and battle.data.energy == 3,"opening hand and energy")
 check(not battle.play(0,"enemy",0),"robot must be placed in friendly slot")
 var pulse_index = -1
 for i in range(battle.data.hand.size()):
  if battle.data.hand[i].id == "pulse": pulse_index = i; break
 check(battle.play(pulse_index,"friendly",0),"play robot")
 check(battle.data.energy == 2 and battle.data.friendly[0].attack == 2,"cost and stats")
 check(not battle.play(0,"friendly",0),"occupied slot rejected")
 check(battle.end_turn(),"begin combat")
 var before = battle.data.enemy_core
 battle.resolve_next()
 check(battle.data.enemy_core == before - 2,"unopposed attack hits core")
 check(not battle.play(0,"friendly",3),"cannot play during enemy phase")
 check(run.save(),"atomic autosave mid-resolution")
 var copy = AstraRun.new(); copy.path = run.path; copy.meta_path = run.meta_path; copy.load_all()
 check(not copy.data.is_empty() and copy.battle.data.phase == "resolving","load pending combat")
 battle.resolve_all(); copy.battle.resolve_all()
 check(JSON.stringify(battle.checkpoint()) == JSON.stringify(copy.battle.checkpoint()),"resume produces identical next turn including RNG")
 check(battle.data.energy == 3 and battle.data.hand.size() <= 7,"refresh and hand limit")
 var initial = run.data.deck.duplicate(true)
 battle.begin(initial,20,0,"battle",123)
 battle.data.enemy = [null,null,null,null]
 var bot = battle.instance({"id":"shield","uid":1,"upgrade":0})
 battle.data.friendly = [bot,battle.instance({"id":"pulse","uid":2,"upgrade":0}),null,null]
 battle.hurt("friendly",1,2,"")
 check(battle.data.friendly[1].hp == 1,"Bastion protects adjacent card")
 battle.hurt("friendly",0,2,"")
 check(battle.data.friendly[0].hp == 6 and battle.data.friendly[0].shield == 0,"Bastion shield absorbs damage")
 battle.data.hand = [{"id":"cryo","uid":3,"upgrade":0}]; battle.data.energy = 3
 battle.spawn("tank",2)
 check(battle.play(0,"friendly",2),"Cryobot deployment")
 battle.strike("friendly",2)
 check(battle.data.enemy[2].frozen == 1,"Cryobot freeze")
 var hp = battle.data.friendly[2].hp
 battle.end_turn(); battle.resolve_all()
 check(battle.data.friendly[2].hp == hp,"frozen opponent skips its attack")
 battle.data.hand = [{"id":"repair","uid":4,"upgrade":0}]; battle.data.energy = 1; battle.data.friendly[2].hp = 1
 check(not battle.play(0,"enemy",2),"repair requires friendly target")
 check(battle.play(0,"friendly",2) and battle.data.friendly[2].hp == 3,"repair restores health")
 battle.data.hand = [{"id":"recall","uid":5,"upgrade":0}]
 check(battle.play(0,"friendly",2) and battle.data.friendly[2] == null and battle.data.hand[0].id == "cryo","recall returns robot to hand")
 battle.data.enemy_core = 1; battle.strike("friendly",1); battle.evaluate()
 check(battle.data.phase == "won","core destruction wins")
 run.data.state = "battle"; run.finish_battle()
 check(run.data.state == "reward" and run.data.reward.size() == 3,"three reward choices")
 var deck_count = run.data.deck.size()
 check(run.take_reward(0) and run.data.deck.size() == deck_count + 1 and run.data.state == "map","reward card and map return")
 check(not run.choose_node("6_1"),"cannot jump to boss")
 check(run.valid_save({"format":"astra_tabletop","version":4,"run":run.data}),"valid run accepted")
 var bad = run.data.duplicate(true); bad.deck[0].id = "bad"
 check(not run.valid_save({"format":"astra_tabletop","version":4,"run":bad}),"malformed cards rejected")
 run.save(); run.data.credits += 1; run.save()
 var file = FileAccess.open(run.path,FileAccess.WRITE); file.store_string("{broken"); file.close()
 copy.load_all()
 check(copy.notice == "recovered" and not copy.data.is_empty(),"corrupt primary recovered from backup")
 for path in [run.path,run.meta_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 print("CARD RULES: ",checks," checks, ",failures," failures")
 quit(0 if failures == 0 else 1)

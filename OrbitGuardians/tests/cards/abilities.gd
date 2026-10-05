extends SceneTree
var checks = 0
var failures = 0
var battle = AstraBattle.new()
func check(condition: bool, text: String) -> void:
 checks += 1
 if not condition: failures += 1; printerr("FAIL: ",text)
func fixture(act: int = 0) -> void:
 var deck: Array = []
 for i in range(AstraCards.STARTERS.size()): deck.append({"id":AstraCards.STARTERS[i],"upgrade":0,"uid":i+1})
 battle.begin(deck,20,act,"battle",4321)
 battle.data.friendly = [null,null,null,null]; battle.data.enemy = [null,null,null,null]; battle.data.intent.clear()
 battle.data.energy = 10
func bot(id: String, uid: int = 500) -> Dictionary:
 return battle.instance({"id":id,"uid":uid,"upgrade":0})
func cast(id: String, side: String = "friendly", lane: int = 0) -> bool:
 battle.data.hand = [{"id":id,"uid":99,"upgrade":0}]
 return battle.play(0,side,lane)
func _initialize() -> void:
 fixture(); battle.data.friendly[0] = bot("pulse"); battle.spawn("runner",0); battle.data.enemy[0].shield = 0
 battle.end_turn(); battle.resolve_all()
 check(battle.data.energy == 4,"Pulse kill refund is spendable next turn")
 fixture(); battle.data.friendly[0] = bot("reactor"); battle.data.friendly[0].jammed = 1
 battle.end_turn(); battle.resolve_all()
 check(battle.data.energy == 3,"jam suppresses Reactor for a full turn")
 battle.end_turn(); battle.resolve_all()
 check(battle.data.energy == 4,"Reactor resumes after jam expires")
 fixture(); battle.data.friendly[1] = bot("pulse"); battle.data.friendly[1].hp = 1
 check(cast("barrier","friendly",1),"shield action")
 battle.hurt("friendly",1,3,"enemy")
 check(battle.data.friendly[1].hp == 1,"temporary shield absorbs exactly three")
 battle.data.friendly[1].temporary = 3; battle.next_round()
 check(battle.data.friendly[1].temporary == 0,"temporary shield expires")
 fixture(); battle.spawn("runner",0); battle.spawn("drone",2)
 check(cast("overload"),"overload action")
 check(battle.data.enemy[0] == null and battle.data.enemy[2].hp == 1,"overload damages multiple opponents")
 fixture(); battle.spawn("tank",1)
 check(cast("emp","enemy",1) and battle.data.enemy[1].jammed == 1 and battle.data.enemy[1].frozen == 1,"EMP disables chosen opponent")
 fixture(); var energy = battle.data.energy; var hand = battle.data.draw.size()
 check(cast("astra") and battle.data.energy == mini(12,energy+2) and battle.data.hand.size() == 1 and battle.data.draw.size() == hand-1,"Astra energy and actual draw")
 fixture(); battle.data.friendly[1] = bot("burst"); battle.data.enemy_core = 18
 battle.end_turn(); battle.resolve_all()
 check(battle.data.enemy_core == 16,"Twin Spark attacks twice")
 fixture(); battle.data.friendly[1] = bot("rail"); battle.spawn("tank",1)
 battle.strike("friendly",1)
 check(battle.data.enemy_core == 17,"Railgun penetrates to core")
 fixture(); battle.data.friendly[1] = bot("mortar"); battle.spawn("drone",0); battle.spawn("tank",1); battle.spawn("drone",2)
 battle.strike("friendly",1)
 check(battle.data.enemy[0].hp == 2 and battle.data.enemy[2].hp == 2,"Comet splashes neighbours")
 fixture(); battle.data.friendly[1] = bot("mechanic"); battle.data.friendly[0] = bot("pulse",501); battle.data.friendly[0].hp = 1
 battle.next_round()
 check(battle.data.friendly[0].hp == 2,"Mechanic repairs adjacent ally")
 fixture(); battle.data.friendly[1] = bot("nova"); battle.spawn("runner",0); battle.hurt("friendly",1,3,"")
 check(battle.data.enemy[0] == null,"Nova death blast")
 fixture(); battle.data.friendly[1] = bot("verdant"); battle.data.friendly[1].hp = 2; battle.next_round()
 check(battle.data.friendly[1].hp == 3,"Symbiont regenerates")
 fixture(1); battle.spawn("runner",0); check(battle.data.enemy[0].shield == 2 and battle.data.enemy[0].effect == "freeze","Borea clan has shields and freeze")
 battle.data.friendly[0] = bot("pulse"); battle.data.turn = 3; battle.next_round()
 check(battle.data.friendly[0].frozen == 1,"Borea fourth-turn cold")
 fixture(2); battle.spawn("drone",0); check(battle.data.enemy[0].effect == "burn","Ignis clan uses burn")
 battle.data.friendly[0] = bot("shield"); battle.data.friendly[0].shield = 0; battle.data.turn = 2; battle.next_round()
 check(battle.data.friendly[0].hp == 5,"Ignis third-turn overheat")
 fixture(3); battle.next_round(); check(battle.data.energy == 4,"Aurica even-turn energy")
 fixture(4); battle.data.friendly[0] = bot("pulse"); battle.data.turn = 3; battle.next_round(); check(battle.data.friendly[0].jammed == 1,"Nexus fourth-turn jam")
 fixture(); battle.spawn("runner",0); battle.spawn("runner",3)
 check(cast("frost") and battle.data.enemy[0].frozen == 1 and battle.data.enemy[3].frozen == 1,"Frost prism freezes whole board")
 fixture(); var core = battle.data.core
 check(cast("storm") and battle.data.core == core-1 and battle.data.energy == 12,"Capacitor has a real core cost")
 fixture(); battle.data.friendly[0] = bot("ember"); battle.spawn("tank",0); battle.strike("friendly",0)
 check(battle.data.enemy[0].burn == 2,"Ember applies burn")
 fixture(); battle.data.friendly[0] = bot("echo"); var count = battle.data.hand.size(); battle.strike("friendly",0)
 check(battle.data.hand.size() == count+1,"Astra echo draws when unopposed")
 fixture(); battle.data.kind = "boss"; battle.data.enemy_core = 7; battle.data.max_enemy_core = 28; battle.next_round()
 check(battle.data.boss_phase and battle.data.enemy[0] != null and battle.data.enemy[0].id == "elite","boss changes phase at half health")
 var run = AstraRun.new(); run.path = "user://qa_card_nodes.json"; run.meta_path = "user://qa_card_nodes_meta.json"; run.new_run(99)
 run.data.state = "upgrade"; check(run.upgrade(int(run.data.deck[0].uid)) and run.data.deck[0].upgrade == 1,"upgrade node changes a specific card")
 run.data.state = "remove"; var size_value = run.data.deck.size(); check(run.remove_card(int(run.data.deck[1].uid)) and run.data.deck.size() == size_value-1,"remove node thins deck")
 run.data.state = "shop"; run.data.stock = ["pulse","cryo","reactor"]; run.data.credits = 50
 check(run.shop_buy(0) and not run.shop_buy(0) and run.data.credits == 30,"shop charges once and sold offer cannot be bought twice")
 run.data.state = "rest"; run.data.core = 15; check(run.rest() and run.data.core == 20,"repair dock caps core health")
 run.data.state = "planet"; run.data.core = 3; check(not run.event_choice(1),"risky event cannot kill player outside combat")
 run.data.core = 10; size_value = run.data.deck.size(); check(run.event_choice(1) and run.data.core == 7 and run.data.deck.size() == size_value+1 and "verdant" in run.meta.unlocked,"planet memory trade unlocks an actual card")
 var bad = run.data.duplicate(true); bad.map[0].links = ["bogus"]
 check(not run.valid_save({"format":"astra_tabletop","version":4,"run":bad}),"invalid route links rejected")
 var prefs = run.store.preferences(); run.new_run(100)
 check(run.store.preferences() == prefs and run.data.core == 20 and run.data.deck.size() == 12,"new run resets run power and retains preferences")
 var legacy_path = "user://qa_card_legacy.json"
 var legacy = OrbitProgress.defaults()
 for i in range(1,21): legacy.completed[str(i)] = 3
 run.store.atomic_write(legacy_path,{"format":"astra3d","progress":legacy,"session":{"state":"battle"}})
 var original = FileAccess.get_file_as_string(legacy_path)
 run.migrate_legacy([legacy_path])
 check(run.meta.legacy_completed.size() == 20 and 1 in run.meta.decks and 2 in run.meta.decks,"legacy missions adapt into records and starter choices")
 check(FileAccess.get_file_as_string(legacy_path) == original,"legacy manual slot remains byte-for-byte unchanged")
 check(run.data.act == 0 and run.data.core == 20 and run.data.deck[0].upgrade == 0,"legacy progress grants no permanent stat bonuses")
 var broken_meta = run.meta.duplicate(true); broken_meta.hulls.clear()
 check(not run.valid_meta(broken_meta),"empty cosmetic list is rejected before it can divide by zero")
 battle.begin(run.data.deck,20,0,"battle",4321)
 var broken_battle = battle.checkpoint(); broken_battle.act = 99
 var owned: Array = []
 for entry in run.data.deck: owned.append(entry.uid)
 check(not run.valid_battle(broken_battle,owned),"invalid battle planet index is rejected")
 DirAccess.remove_absolute(legacy_path)
 for path in [run.path,run.meta_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 print("CARD ABILITIES: ",checks," checks, ",failures," failures")
 quit(0 if failures == 0 else 1)

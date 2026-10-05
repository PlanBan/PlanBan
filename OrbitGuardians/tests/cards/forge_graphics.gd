extends "res://tests/cards/desktop_graphics.gd"
func frames(count: int = 8) -> void:
 if game!=null and is_instance_valid(game.view):game.view.queue_redraw()
 await super.frames(count)
func run_test() -> void:
 output="/workspace/artifacts/forge"
 DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(1280,720)
 game=load("res://scenes/Tabletop.tscn").instantiate()
 game.run.path="user://qa_forge_graphics.json";game.run.meta_path="user://qa_forge_graphics_meta.json";game.run.store.settings_path="user://qa_forge_graphics_prefs.json"
 for path in [game.run.path,game.run.meta_path,game.run.store.settings_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 root.add_child(game);await frames(25)
 check(game.view is AstraForgeUI,"forge desktop view loaded")
 await screenshot("menu");await command("new");await command("start");await command("skip_story");await command("skip_training")
 check(game.screen=="map","existing story and tutorial lead to the expedition")
 await screenshot("map");await command("deck")
 var keep=[game.run.data.deck[0].uid,game.run.data.deck[2].uid,game.run.data.deck[3].uid]
 for uid in game.draft_loadout.duplicate():
  if uid not in keep:await command("loadout_toggle",uid)
 check(game.draft_loadout.size()==3,"visible editor removes unwanted cards")
 await screenshot("deck");await command("loadout_save")
 check(game.screen=="map" and game.run.data.loadout.size()==3,"save button commits chosen deck")
 await command("supplies");await command("supply_buy","medkit");await command("supply_buy","battery")
 check(game.run.data.credits==8 and game.run.data.supplies.medkit==2 and game.run.data.supplies.battery==1,"visible shop charges exact item prices")
 await command("supply_use","medkit")
 check(game.run.data.supplies.medkit==2,"full-health use preserves purchased repair")
 await screenshot("supplies");await command("supply_tab",1);await screenshot("blueprints")
 check(game.screen=="supplies" and game.supply_tab==1,"shop has buyable blueprint reserve")
 await command("supplies_back")
 await tap(game.world.map_nodes["0_1"].point);await command("depart");await create_timer(1.1).timeout;await frames(15)
 check(game.screen=="challenge" and game.run.battle.data.hand.size()==3,"only player-selected commands enter combat")
 await command("fight");await frames(20);await screenshot("battle-opening")
 var battle=game.run.battle
 var pulse=-1;var reactor=-1;var healing=-1
 for i in range(battle.data.hand.size()):
  if battle.data.hand[i].id=="pulse":pulse=i
  if battle.data.hand[i].id=="reactor":reactor=i
  if battle.data.hand[i].id=="core_repair":healing=i
 var rect=hand_rect(pulse)
 await tap(rect.get_center());await tap(game.world.slot_point("friendly",0));await frames(20)
 check(battle.data.friendly[0]!=null and battle.data.hand.size()==3 and hand_rect(pulse)==rect,"deployment leaves command in the same visible position")
 await tap(rect.get_center());await tap(game.world.slot_point("friendly",2))
 check(battle.data.friendly[2]==null and battle.data.energy==2,"used command cannot manufacture twice in a turn")
 await tap(game.world.slot_point("friendly",0));await tap(game.world.slot_point("enemy",1))
 check(battle.data.friendly[0].target_lane==1,"real input sets a cross-lane target")
 await command("supply_use","battery")
 check(battle.data.energy==4 and game.run.data.supplies.battery==0,"battle quickbar grants energy immediately")
 await tap(hand_rect(reactor).get_center());await tap(game.world.slot_point("friendly",3));await frames(20)
 check(battle.data.friendly[3]!=null and battle.data.energy==2,"paid reactor coexists with an attacker")
 await screenshot("battle-deployed");await command("turn");await command("pause")
 check(battle.data.phase=="resolving" and not battle.data.pending.is_empty(),"actual input pauses an unresolved command battle")
 var restored=AstraRun.new();restored.path=game.run.path;restored.meta_path=game.run.meta_path;restored.load_all()
 check(restored.battle.commands() and restored.battle.data.used==battle.data.used,"generated robots and command cooldowns load from disk")
 await command("resume");await wait_player();restored.battle.resolve_all()
 check(JSON.stringify(restored.battle.checkpoint())==JSON.stringify(battle.checkpoint()),"aimed pending attacks resume exactly")
 check(battle.data.core==19 and battle.ready_command(pulse),"unblocked foe deals real damage and chosen attack is ready next turn")
 await command("supplies");await command("supply_use","medkit")
 check(battle.data.core==20 and game.run.data.supplies.medkit==1,"always-available shop instantly heals during battle")
 await command("supplies_back")
 await tap(hand_rect(pulse).get_center());await tap(game.world.slot_point("friendly",1));await frames(18)
 check(battle.data.friendly[1]!=null and battle.data.friendly[1].uid!=battle.data.friendly[0].uid,"reused blueprint builds a different robot next turn")
 await tap(game.world.slot_point("friendly",1));await command("withdraw")
 check(battle.data.friendly[1]==null,"visible dismantle frees an occupied pad")
 # Full-health core action still has a visible confirmation button, but cannot waste energy.
 await tap(hand_rect(healing).get_center());await command("cast")
 check(not battle.data.used.has(battle.data.hand[healing].uid) and battle.data.core==20,"full-health action confirmation is rejected before charging")
 # A dedicated rendering fixture displays varied roles and tests all original rigs.
 game.toast_clock=0;game.selected=-1;game.selected_bot=-1;game.hovered.clear();game.hovered_entry.clear()
 game.set_process(false)
 var index=0
 for id in ["pulse","shield","mechanic","rail"]:
  var entry=battle.instance({"id":id,"uid":3000+index,"upgrade":0});entry.blueprint_uid=keep[0]
  battle.data.friendly[index]=entry;index+=1
 await frames(20);await screenshot("battle-roles");await move(game.world.slot_point("friendly",1));await screenshot("armour-hover")
 var rig_names=["pulse","reactor","shield","cryo","burst","rail","mortar","repair","nova","enemy_drone","enemy_runner","enemy_tank","enemy_medic","enemy_disruptor","enemy_elite","enemy_boss"]
 for name in rig_names:
  var path="res://assets3d/forge/"+name+".glb";var rig=load(path).instantiate()
  check(not rig.find_children("*","Skeleton3D",true,false).is_empty(),name+" has articulated geometry")
  var clips:Array=[]
  for player in rig.find_children("*","AnimationPlayer",true,false):
   for clip in player.get_animation_list():clips.append(str(clip).to_lower())
  for expected in ["idle","deploy","attack","hit","death"]:
   var found=false
   for clip in clips:
    if clip.ends_with(expected):found=true
   check(found,name+" animated "+expected)
  check(ResourceLoader.exists("res://assets3d/forge/portraits/"+name+".png"),name+" original rendered portrait")
  rig.free()
 for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(1024,576)]:
  root.size=resolution;await frames(12)
  for side in ["enemy","friendly"]:
   for lane in range(4):
    var p=game.world.slot_point(side,lane)
    check(game.world.project(game.world.position_for(p)).distance_to(p)<.5,"forge pad picking "+str(resolution)+side+str(lane))
 root.size=Vector2i(1280,720)
 battle.begin_commands(game.run.data.deck,20,0,"battle",443);battle.data.briefed=true;game.selected=-1;game.selected_bot=-1
 for lang in ["ru","en","de"]:
  game.run.store.data.language=lang;game.run.store.data.ui_scale=1.25;await move(Vector2(1158,714));await frames(10)
  var rects:Array=[]
  for card in game.view.card_hits:
   if card.hand>=0:rects.append(card.rect)
  var overlap=false
  for i in range(rects.size()):
   for j in range(i+1,rects.size()):
    if rects[i].intersects(rects[j]):overlap=true
  check(rects.size()==6 and not overlap,"six fixed commands do not overlap in "+lang)
  check(game.view.preview_bottom<510,"concise preview fits above controls in "+lang)
  await screenshot("battle-"+lang)
 game.run.store.data.language="ru";await move(hand_rect(0).get_center());await key(KEY_E)
 check(game.screen=="inspect" and game.view.large_face.art.resource_path.contains("/forge/"),"large free inspection uses new model art")
 await screenshot("inspector");await key(KEY_ESCAPE)
 for path in [game.run.path,game.run.meta_path,game.run.store.settings_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 print("FORGE GRAPHICS: ",checks," checks, ",failures," failures")
 await game.quit_game(0 if failures==0 else 1)

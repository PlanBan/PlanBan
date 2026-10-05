extends SceneTree
var checks=0
var failures=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: ",label)
func _initialize()->void:
 var run=AstraRun.new();run.path="user://qa_forge_rules.json";run.meta_path="user://qa_forge_meta.json";run.new_run(4912)
 check(run.data.loadout.size()==6 and run.data.supplies.medkit==1,"starter has six chosen commands and a visible emergency repair")
 run.data.state="map"
 var chosen=[run.data.deck[0].uid,run.data.deck[2].uid,run.data.deck[3].uid]
 check(run.set_loadout(chosen) and run.active_deck().size()==3,"player can keep a smaller three-command loadout")
 check(not run.set_loadout([]) and not run.set_loadout([1,1,2]) and not run.set_loadout([3,4,5]),"empty, duplicate and attackless decks are rejected")
 var original=run.data.loadout.duplicate();run.add_card("rail")
 check(run.data.deck.size()==7 and run.data.loadout==original,"new rewards enter reserve without inflating battle deck")
 check(run.buy_supply("medkit") and run.data.credits==18 and run.data.supplies.medkit==2,"repair costs twelve alloy and goes into inventory")
 run.data.core=12
 check(run.use_supply("medkit") and run.data.core==20 and run.data.supplies.medkit==1,"map repair restores eight immediately")
 check(not run.use_supply("medkit") and run.data.supplies.medkit==1,"full-health repair does not waste an item")
 check(run.buy_supply("battery") and run.data.credits==8,"energy cell costs ten alloy")
 check(run.buy_supply("purge") and run.data.credits==0,"cleanser costs eight alloy")
 check(not run.buy_supply("bomb") and not run.buy_supply("bad") and run.data.credits==0,"insufficient funds and unknown items do not mutate inventory")
 check(run.choose_node("0_1"),"new battle starts from an actual reachable route")
 var battle=run.battle
 check(battle.commands() and battle.data.hand.size()==3 and battle.data.hand.map(func(e):return e.uid)==chosen,"all chosen commands are present, with no random draw")
 check(battle.data.draw.is_empty() and battle.data.discard.is_empty(),"reserve does not enter battle zones")
 var pulse=0
 check(battle.play(pulse,"friendly",0) and battle.data.energy==2 and battle.data.hand.size()==3,"manufacture charges once without removing blueprint")
 var first=battle.data.friendly[0].uid
 check(not battle.play(pulse,"friendly",2) and battle.data.energy==2,"same blueprint cannot be spammed twice in one turn")
 check(run.use_supply("battery") and battle.data.energy==4 and run.data.supplies.battery==0,"quick energy has an immediate effect without spending turn energy")
 check(not run.use_supply("battery") and battle.data.energy==4,"empty inventory cannot be reused")
 check(battle.choose_target(0,1) and battle.data.friendly[0].target_lane==1,"attacker can be directed across lanes")
 check(not battle.choose_target(0,2) and not battle.choose_target(3,1),"cannot target an empty lane or order a nonexistent robot")
 check(run.save() and run.valid_save({"format":"astra_tabletop","version":4,"run":run.data}),"reserve, commands, generated robot UID and consumed supplies validate together")
 var copy=AstraRun.new();copy.path=run.path;copy.meta_path=run.meta_path;copy.load_all()
 check(copy.data.loadout==chosen and copy.battle.data.used==battle.data.used and copy.data.supplies==run.data.supplies,"loadout, command cooldown and items survive restart")
 battle.end_turn();run.save();copy.load_all();battle.resolve_all();copy.battle.resolve_all()
 check(JSON.stringify(battle.checkpoint())==JSON.stringify(copy.battle.checkpoint()),"pending aimed combat resumes without repeated damage")
 check(battle.ready_command(pulse) and battle.data.hand.map(func(e):return e.uid)==chosen,"selected attacker returns every turn in the same position")
 check(battle.play(pulse,"friendly",2) and battle.data.friendly[2].uid!=first and battle.data.friendly[2].blueprint_uid==chosen[0],"same blueprint manufactures an independently saved second robot")
 battle.data.friendly[2].slowed=1;battle.data.friendly[2].burn=2;battle.data.friendly[2].jammed=1
 check(run.use_supply("purge") and battle.data.friendly[2].slowed==0 and battle.data.friendly[2].burn==0 and battle.data.friendly[2].jammed==0,"cleanser removes all listed statuses immediately")
 var hp=battle.data.core;battle.data.core=10;var energy=battle.data.energy
 check(run.use_supply("medkit") and battle.data.core==18 and battle.data.energy==energy,"quick core healing spends no energy")
 run.data.credits=30
 check(run.buy_supply("bomb") and run.data.credits==12,"strike drone costs eighteen")
 var enemy_hp=battle.data.enemy[1].hp
 check(run.use_supply("bomb") and (battle.data.enemy[1]==null or battle.data.enemy[1].hp<enemy_hp),"strike drone applies actual damage")
 check(battle.withdraw(2) and battle.data.friendly[2]==null,"player can replace a support unit by dismantling it")
 run.save()
 var bad=run.data.duplicate(true);bad.supplies.medkit=-1
 check(not run.valid_save({"format":"astra_tabletop","version":4,"run":bad}),"negative item counts are rejected")
 bad=run.data.duplicate(true);bad.battle.used.append(bad.battle.used[0])
 check(not run.valid_save({"format":"astra_tabletop","version":4,"run":bad}),"duplicate consumed commands are rejected")
 bad=run.data.duplicate(true);bad.battle.friendly[0].blueprint_uid=98765
 check(not run.valid_save({"format":"astra_tabletop","version":4,"run":bad}),"manufactured robot cannot claim an unowned blueprint")
 battle.end_turn();run.save()
 check(not run.buy_supply("battery") and not run.use_supply("bomb"),"items cannot interrupt an unresolved attack transaction")
 # The exact reported regression: an unshielded three-HP enemy must die to three damage.
 var fair=AstraBattle.new();var starter:Array=[]
 for id in AstraCards.starter(0):starter.append({"id":id,"uid":starter.size()+1,"upgrade":0})
 fair.begin_commands(starter,20,1,"battle",123)
 check(fair.data.enemy[1].hp==3 and fair.data.enemy[1].shield==0,"ice worlds no longer give every ordinary enemy a hidden shield")
 var unit=fair.instance({"id":"pulse","uid":1,"upgrade":1});unit.uid=2000;unit.blueprint_uid=1;fair.data.friendly[1]=unit;fair.data.enemy[1].effect="chill"
 fair.end_turn();fair.resolve_all()
 check(fair.data.enemy[1]==null and unit.frozen==0 and unit.slowed==0 and unit.hp==5,"three attack kills three HP before a dead enemy can retaliate or freeze")
 fair.spawn("runner",0);fair.data.turn=3;var target=fair.instance({"id":"shield","uid":3,"upgrade":0});target.shield=0;fair.data.friendly[0]=target
 fair.strike("enemy",0)
 check(target.frozen==0 and target.slowed==1,"enemy cold weakens one strike instead of skipping a turn")
 var alive=fair.data.enemy[0].hp;fair.strike("friendly",0)
 check(target.slowed==0 and fair.data.enemy[0].hp==alive,"slowed unit still performs its zero-damage strike and clears chill")
 fair.strike("enemy",0)
 check(target.slowed==0,"cold immunity prevents repeated status chaining")
 var old=copy.data.duplicate(true);old.state="map";old.battle.clear();old.erase("supplies");old.erase("loadout");old.core=11
 run.store.atomic_write(run.path,{"format":"astra_tabletop","version":4,"run":old});copy.load_all()
 check(copy.data.core==11 and copy.data.supplies.medkit==0 and copy.data.loadout.size()==6,"old campaign gains editable loadout without free healing or supplies")
 run.data=copy.data.duplicate(true);run.data.credits=50
 if "pulse" not in run.meta.unlocked:run.meta.unlocked.append("pulse")
 var before_deck=run.data.deck.size();var before_loadout=run.data.loadout.duplicate()
 check(run.buy_blueprint("pulse") and run.data.credits==28 and run.data.deck.size()==before_deck+1 and run.data.loadout==before_loadout,"shop purchase charges alloy and leaves active loadout unchanged")
 check(not run.buy_blueprint("unknown") and run.data.credits==28,"unknown blueprint cannot charge alloy")
 run.new_run(1200);run.data.state="map";run.data.credits=60
 run.buy_research("weapons",0);run.buy_research("frames",0);run.buy_research("systems",0)
 check(run.choose_node("0_1"),"researched campaign enters a reachable encounter")
 check(run.battle.data.energy==4 and run.battle.instance(run.battle.data.hand[0]).attack==3 and run.battle.instance(run.battle.data.hand[0]).hp==5,"chosen command battle applies researched opening energy, attack and health")
 var hands=run.battle.data.hand.duplicate(true)
 var future=run.data.loadout.duplicate();future.reverse()
 check(run.set_loadout(future) and run.battle.data.hand==hands,"editing during battle changes next encounter only")
 var prism=run.battle.instance({"id":"frost","uid":999,"upgrade":0})
 check(prism.effect=="softfrost" and AstraCards.description(prism,"en").contains("one strike"),"cold action description agrees with new weakening rule")
 run.new_run(122)
 check(run.data.supplies.medkit==1 and run.data.loadout.size()==6,"new game resets items and commands")
 for path in [run.path,run.meta_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 print("FORGE RULES: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)

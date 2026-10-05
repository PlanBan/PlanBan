extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok: failures += 1; printerr("FAIL: ",label)
func _initialize() -> void:
 var run = AstraRun.new(); run.path="user://qa_research_run.json"; run.meta_path="user://qa_research_meta.json"; run.new_run(1234)
 check(run.data.research==AstraResearch.defaults() and run.data.max_core==20,"new journeys start with an unpurchased technology tree")
 check(run.data.deck.size()==6 and "core_repair" in run.data.deck.map(func(c):return c.id),"emergency core repair is available in the real small starter deck")
 check(not run.buy_research("core",0),"cannot buy technology in story or combat")
 run.data.state="map"
 check(not run.buy_research("frames",1) and not run.buy_research("bogus",0),"cannot bypass prerequisites or unknown branches")
 check(run.buy_research("core",0) and run.data.credits==12 and run.data.max_core==24 and run.data.core==24,"core research charges once and expands actual maximum")
 check(not run.buy_research("core",0) and not run.buy_research("core",1),"cannot repeat purchase or bypass world gate")
 run.data.act=2; run.data.credits=600; run.data.core=4
 check(run.buy_research("core",1) and run.data.core==8 and run.data.max_core==28,"core upgrade heals four rather than resetting low HP")
 check(run.buy_research("core",2) and run.data.max_core==32 and run.data.core==12,"core branch has three genuine tiers")
 for branch in ["weapons","frames","systems"]:
  for rank in range(3): check(run.buy_research(branch,rank),"buy research "+branch+str(rank))
 check(run.save() and run.valid_save({"format":"astra_tabletop","version":4,"run":run.data}),"complete tree and expanded HP serialize")
 var copy = AstraRun.new();copy.path=run.path;copy.meta_path=run.meta_path;copy.load_all()
 check(copy.data.research==run.data.research and copy.data.core==12 and copy.data.max_core==32,"tree and HP survive restart")
 run.data.act=0;run.choose_node("0_1")
 var battle=run.battle
 # This suite also retains the previous encounter model; command combat is covered in forge_rules.
 battle.begin(run.data.deck,run.data.core,0,"battle",1234,run.data.max_core,AstraResearch.bonuses(run.data.research))
 check(battle.data.energy==5 and battle.data.max_core==32 and battle.data.core==12,"first-turn research energy and expanded core are used by combat")
 check(not battle.data.briefed and battle.data.taunt>=0 and battle.data.taunt<3,"every fresh encounter has a stable pre-battle commander line")
 var unit=battle.instance({"id":"pulse","uid":run.data.deck[0].uid,"upgrade":0})
 check(unit.attack==4 and unit.hp==7 and unit.armor==1,"research buffs attack, robot HP and armour")
 battle.data.friendly[0]=unit
 battle.hurt("friendly",0,3,"enemy")
 check(unit.hp==5,"armour really reduces each incoming hit")
 check(battle.order(0,"aim") and unit.focus==2,"precision upgrade changes actual next-strike bonus")
 # Real core-heal copies are introduced from the owned zones, preserving UID accounting.
 var repair_index=-1
 for i in range(battle.data.hand.size()):
  if battle.data.hand[i].id=="core_repair":repair_index=i
 if repair_index<0:
  for i in range(battle.data.draw.size()):
   if battle.data.draw[i].id=="core_repair":battle.data.hand.append(battle.data.draw.pop_at(i));repair_index=battle.data.hand.size()-1;break
 check(battle.play(repair_index,"friendly",0) and battle.data.core==24,"emergency heal restores eight plus four from rescue protocol")
 var healing=battle.instance({"id":"core_repair","uid":99,"upgrade":2})
 check(healing.cost==0,"upgraded emergency heal remains an affordable action")
 check(healing.healing==20,"card upgrades and rescue protocol increase the actual healing amount")
 var heal_case=AstraBattle.new();heal_case.begin([{"id":"core_repair","uid":900,"upgrade":0}],32,0,"battle",12,32)
 check(not heal_case.play(0,"friendly",0) and heal_case.data.energy==3 and heal_case.data.hand.size()==1,"full-health healing does not consume a card or energy")
 heal_case.data.core=29
 check(heal_case.play(0,"friendly",0) and heal_case.data.core==32 and heal_case.data.energy==1 and heal_case.data.discard.size()==1,"healing clamps to researched maximum and charges exactly once")
 # Keep run ownership valid before testing a complete queued save/reload.
 battle.data.friendly[0]=null
 for i in range(battle.data.hand.size()):
  if battle.data.hand[i].uid==unit.uid:battle.data.hand.remove_at(i);break
 battle.data.friendly[0]=unit
 battle.data.briefed=true;battle.end_turn();run.save();copy.load_all()
 check(copy.battle.data.get("briefed",false) and copy.battle.data.pending==battle.data.pending,"accepted dialogue and precise pending queue survive a restart")
 battle.resolve_all();copy.battle.resolve_all()
 check(JSON.stringify(battle.checkpoint())==JSON.stringify(copy.battle.checkpoint()),"research attack bonus is not applied twice on resume")
 var bad=run.data.duplicate(true);bad.research.frames=4
 check(not run.valid_save({"format":"astra_tabletop","version":4,"run":bad}),"invalid tree ranks are rejected")
 bad=run.data.duplicate(true);bad.core=33
 check(not run.valid_save({"format":"astra_tabletop","version":4,"run":bad}),"core cannot exceed researched maximum")
 var old=run.data.duplicate(true);old.erase("research");old.max_core=20;old.core=10;old.state="map";old.battle.clear()
 check(run.valid_save({"format":"astra_tabletop","version":4,"run":old}),"previous v4 journey without research remains valid")
 run.store.atomic_write(run.path,{"format":"astra_tabletop","version":4,"run":old});copy.load_all()
 check(copy.data.research==AstraResearch.defaults() and copy.data.core==10,"old journey receives empty tree without free healing")
 var legacy=battle.checkpoint();legacy.ruleset=42;legacy.max_core=20;legacy.core=10;legacy.erase("tech");legacy.erase("briefed");legacy.energy=2;legacy.max_energy=2
 copy.battle.restore(legacy);copy.battle.data.turn=1;copy.battle.next_round()
 check(copy.battle.data.energy==2 and copy.battle.energy_limit()==5,"an active 4.2 encounter retains its old energy rules")
 run.new_run(4321)
 check(run.data.research==AstraResearch.defaults() and run.data.max_core==20,"new game resets expedition buffs")
 for path in [run.path,run.meta_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 print("RESEARCH RULES: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)

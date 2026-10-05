extends SceneTree
var victories = 0
var battles = 0
func _initialize() -> void:
 for seed_value in [41293,77183,91022,104812,51932]:
  var run = AstraRun.new(); run.meta = AstraRun.defaults_meta()
  for id in AstraCards.CARDS:
   if not AstraCards.CARDS[id].has("planet"): run.meta.unlocked.append(id)
  run.path = "user://qa_journey.json"; run.meta_path = "user://qa_journey_meta.json"
  run.new_run(seed_value); run.data.state = "map"
  var decisions = 0
  while run.data.state not in ["defeat","ending"] and decisions < 100:
   decisions += 1
   match run.data.state:
    "map":
     var available = run.available_nodes()
     var chosen = available[0]; var best = -999
     for id in available:
      var node: Dictionary = {}
      for value in run.data.map:
       if value.id == id: node = value
      var score = {"battle":4,"elite":1,"boss":10,"rest":15 if run.data.core < 15 else 2,"reward":7,"event":5,"planet":8,"upgrade":10,"shop":3,"remove":6}.get(node.kind,0)
      if score > best: best = score; chosen = id
     assert(run.choose_node(chosen))
    "battle":
     var battle = run.battle
     var turns = 0
     while battle.data.phase not in ["won","lost"] and turns < 80:
      turns += 1
      play_turn(battle)
      battle.end_turn(); battle.resolve_all()
     battles += 1
     assert(turns < 80,"combat stalled")
     run.finish_battle()
    "reward":
     var best = 0; var score = -999
     for i in range(run.data.reward.size()):
      var id = run.data.reward[i]
      var value = {"rail":8,"cryo":8,"verdant":9,"ember":9,"echo":9,"burst":7,"shield":5,"reactor":1,"astra":8,"mechanic":6,"mortar":6,"overload":7,"repair":4,"frost":7,"nova":7,"emp":3,"recall":2,"barrier":3,"storm":6,"pulse":5}[id]
      if value > score: best = i; score = value
     run.take_reward(best)
    "rest": run.rest()
    "event","planet": run.event_choice(1 if run.data.core > 9 else 0)
    "upgrade":
     var target: Variant = null
     for entry in run.data.deck:
      if entry.upgrade < 2 and AstraCards.CARDS[entry.id].hp > 0 and (target == null or AstraCards.CARDS[entry.id].attack > AstraCards.CARDS[target.id].attack): target = entry
     if target != null: run.upgrade(int(target.uid))
     else: run.finish_node()
    "remove":
     var target: Variant = null
     for entry in run.data.deck:
      if entry.id == "reactor": target = entry; break
     if target != null: run.remove_card(int(target.uid))
     else: run.finish_node()
    "shop":
     for i in range(run.data.stock.size()): run.shop_buy(i)
     run.finish_node()
    "travel": run.data.state = "map"
   assert(run.save())
   assert(run.valid_save({"format":"astra_tabletop","version":4,"run":run.data}),"every real journey checkpoint validates")
  if run.data.state == "ending": victories += 1
  print("EXPEDITION seed=",seed_value," result=",run.data.state," act=",int(run.data.act)+1," battles=",run.data.battles," core=",run.data.core," deck=",run.data.deck.size())
  for path in [run.path,run.meta_path]:
   for suffix in ["",".bak",".tmp"]:
    if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 print("JOURNEY RESULT: ",battles," real card encounters; ",victories," / 5 five-act victories")
 quit(0 if victories >= 1 else 1)
static func play_turn(battle: AstraBattle) -> void:
 var plays = 0
 while plays < 18 and battle.data.phase == "player":
  var best = 0.1; var choice: Dictionary = {}
  for i in range(battle.data.hand.size()):
   var entry = AstraCards.card(battle.data.hand[i].id,int(battle.data.hand[i].upgrade))
   if entry.cost > battle.data.energy: continue
   for side in ["friendly","enemy"]:
    for lane in range(4):
     var score = evaluate_play(battle,entry,side,lane)
     if score > best: best = score; choice = {"index":i,"side":side,"lane":lane}
  if choice.is_empty(): break
  if not battle.play(int(choice.index),choice.side,int(choice.lane)): break
  plays += 1
static func evaluate_play(battle: AstraBattle, entry: Dictionary, side: String, lane: int) -> float:
 var data = battle.data
 if entry.hp > 0:
  if side != "friendly" or data.friendly[lane] != null: return -999
  var opponent: Variant = data.enemy[lane]
  var score = entry.attack*2.2 + entry.hp*.25 - entry.cost*.16
  if opponent == null: score += entry.attack*.65
  else: score += opponent.attack*1.3
  if entry.effect == "freeze" and opponent != null: score += 3
  if entry.effect == "double": score += entry.attack*1.8
  if entry.effect == "energy":
   var count = 0
   for bot in data.friendly:
    if bot != null and bot.effect == "energy": count += 1
   score = 5 if count == 0 and data.turn < 6 else -1
   if opponent != null: score -= 2
  if entry.effect == "mend": score += 1
  return score
 var target: Variant = data[side][lane]
 match entry.effect:
  "boost": return 10 if side == "friendly" and lane == 0 else -999
  "storm": return 8 if side == "friendly" and lane == 0 and data.core > 3 else -999
  "overload":
   var amount = 0
   for bot in data.enemy:
    if bot != null: amount += mini(2,bot.hp)
   return amount*1.3 if side == "friendly" and lane == 0 else -999
  "heal": return minf(4,target.max_hp-target.hp)*1.1 if side == "friendly" and target != null else -999
  "barrier": return 2 if side == "friendly" and target != null and data.enemy[lane] != null and target.temporary == 0 else -999
  "emp": return target.attack*1.5 if side == "enemy" and target != null and target.frozen == 0 else -999
  "frost":
   var amount = 0
   for bot in data.enemy:
    if bot != null and bot.frozen == 0: amount += bot.attack
   return amount*1.2 if side == "friendly" and lane == 0 else -999
  "recall": return -999
 return -999

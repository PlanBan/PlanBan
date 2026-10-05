extends RefCounted
class_name AstraBattle
## Serializable turn model. No frame rate or keyboard dependency; intent is deterministic.
var data: Dictionary = {}
var rng = RandomNumberGenerator.new()
var events: Array = []
func restore(payload: Dictionary) -> void:
 data = AstraCards.integers(payload)
 rng.state = int(data.rng)
 if not data.has("carry"): data.carry = 0
 if not data.has("ruleset"): data.ruleset = 41
func modern() -> bool:
 return int(data.get("ruleset",41)) >= 42
func energy_limit() -> int:
 return 6 if int(data.get("ruleset",41)) >= 43 else (5 if modern() else 12)
func gain_energy(amount: int) -> void:
 data.energy = mini(energy_limit(),data.energy+amount)
 if modern(): data.max_energy = maxi(data.max_energy,data.energy)
func checkpoint() -> Dictionary:
 data.rng = str(rng.state)
 return data.duplicate(true)
func begin(deck: Array, core: int, act: int, kind: String, seed_value: int, maximum: int = 20, technology: Dictionary = {}) -> void:
 rng.seed = seed_value
 data = {"act":act,"kind":kind,"turn":1,"core":core,"max_core":20,"enemy_core":18 + act * 4 + (10 if kind == "boss" else (5 if kind == "elite" else 0)),"max_enemy_core":0,"energy":3,"max_energy":3,"hand":[],"draw":deck.duplicate(true),"discard":[],"friendly":[null,null,null,null],"enemy":[null,null,null,null],"phase":"player","pending":[],"intent":[],"serial":1000,"rng":"0","boss_phase":false}
 data.max_enemy_core = data.enemy_core
 data.carry = 0
 data.ruleset = 43
 data.max_core = maximum; data.tech = technology.duplicate(true)
 data.briefed = false; data.taunt = absi(seed_value)%3
 data.energy = 3+int(technology.get("opening",0))+int(technology.get("energy",0)); data.max_energy = data.energy
 data.enemy_core = 20+act*4+(14 if kind == "boss" else (6 if kind == "elite" else 0)); data.max_enemy_core = data.enemy_core
 shuffle(data.draw)
 # A fair opening hand, drawn from the real deck, never generated for free.
 for id in ["pulse","reactor"]:
  for i in range(data.draw.size()):
   if data.draw[i].id == id:
    data.hand.append(data.draw.pop_at(i))
    break
 draw_cards(3 - data.hand.size())
 spawn("drone", 1)
 if kind == "elite": spawn("elite", 2)
 if kind == "boss": spawn("boss", 2)
 plan_intent()
 checkpoint()
func commands() -> bool:
 return int(data.get("ruleset",41))>=44 and not data.get("tutorial",false)
func begin_commands(deck: Array, core: int, act: int, kind: String, seed_value: int, maximum: int = 20, technology: Dictionary = {}) -> void:
 begin(deck,core,act,kind,seed_value,maximum,technology)
 data.ruleset=44;data.hand=deck.duplicate(true);data.draw.clear();data.discard.clear();data.used=[]
 data.enemy=[null,null,null,null];events.clear();spawn("drone",1)
 if kind=="elite":spawn("elite",2)
 if kind=="boss":spawn("boss",2)
 plan_intent();checkpoint()
func ready_command(index: int) -> bool:
 return index>=0 and index<data.hand.size() and (not commands() or data.hand[index].uid not in data.get("used",[]))
func choose_target(lane: int, target: int) -> bool:
 if not commands() or data.phase!="player" or lane<0 or lane>3 or target<0 or target>3: return false
 if data.friendly[lane]==null or data.enemy[target]==null or data.friendly[lane].attack<=0:return false
 data.friendly[lane].target_lane=target;checkpoint();return true
func withdraw(lane: int) -> bool:
 if not commands() or data.phase!="player" or lane<0 or lane>3 or data.friendly[lane]==null:return false
 var bot: Dictionary=data.friendly[lane];data.friendly[lane]=null;gain_energy(int(bot.cost/2))
 events=[{"kind":"withdraw","side":"friendly","lane":lane,"uid":bot.uid}];checkpoint();return true
func use_supply(kind: String) -> bool:
 if data.phase!="player" or data.get("tutorial",false):return false
 events.clear()
 match kind:
  "medkit":
   if data.core>=data.max_core:return false
   var before=int(data.core);data.core=mini(data.max_core,data.core+8)
   events.append({"kind":"heal_core","side":"friendly","damage":data.core-before})
  "battery":
   if data.energy>=energy_limit():return false
   gain_energy(2);events.append({"kind":"ability","effect":"boost","side":"friendly","lane":1})
  "purge":
   var affected=false
   for bot in data.friendly:
    if bot!=null and (bot.frozen+bot.jammed+bot.burn+bot.get("slowed",0)>0):affected=true
   if not affected:return false
   for bot in data.friendly:
    if bot!=null:
     bot.frozen=0;bot.jammed=0;bot.burn=0;bot.slowed=0;bot.chill_until=data.turn+1
   events.append({"kind":"ability","effect":"cleanse","side":"friendly","lane":1})
  "bomb":
   if data.enemy.all(func(bot):return bot==null):return false
   for i in range(4):hurt("enemy",i,2,"")
   events.append({"kind":"ability","effect":"overload","side":"enemy","lane":1})
  _:return false
 evaluate();checkpoint();return true
func start_training(deck: Array, seed_value: int) -> void:
 begin(deck,20,0,"battle",seed_value)
 data.tutorial = true; data.tutorial_step = 0
 data.draw.append_array(data.hand); data.hand.clear()
 for i in range(data.draw.size()):
  if data.draw[i].id == "pulse": data.hand.append(data.draw.pop_at(i)); break
 data.enemy = [null,null,null,null]; spawn("drone",1)
 data.enemy[1].hp = 2; data.enemy[1].max_hp = 2; data.enemy[1].effect = ""
 data.enemy_core = 4; data.max_enemy_core = 4; data.energy = 1; data.max_energy = 1
 data.intent.clear(); checkpoint()
func shuffle(items: Array) -> void:
 for i in range(items.size() - 1, 0, -1):
  var j = rng.randi_range(0, i)
  var item = items[i]; items[i] = items[j]; items[j] = item
func draw_cards(count: int) -> void:
 if commands():return
 for _i in range(count):
  if data.hand.size() >= (5 if modern() else 7): return
  if data.draw.is_empty():
   data.draw = data.discard.duplicate(true); data.discard.clear(); shuffle(data.draw)
  if data.draw.is_empty(): return
  data.hand.append(data.draw.pop_back())
func instance(entry: Dictionary) -> Dictionary:
 var value = AstraCards.card(entry.id, int(entry.get("upgrade", 0)))
 if value.hp > 0 and int(data.get("ruleset",41)) >= 43 and not data.get("tutorial",false):
  value.hp += int(data.get("tech",{}).get("hp",0))
  if value.attack > 0: value.attack += int(data.get("tech",{}).get("attack",0))
 if value.effect=="coreheal": value.healing += int(data.get("tech",{}).get("healing",0))
 value.armor = int(data.get("tech",{}).get("armor",0)) if value.hp > 0 else 0
 if commands() and value.effect=="freeze":value.effect="chill"
 if commands() and value.effect=="frost":value.effect="softfrost"
 value.slowed=0;value.chill_until=0;value.target_lane=-1
 value.uid = entry.uid; value.max_hp = value.hp; value.shield = 0; value.temporary = 0; value.frozen = 0; value.jammed = 0; value.burn = 0
 if value.effect == "guard": value.shield = 2
 return value
func spawn(kind: String, lane: int) -> void:
 var value: Dictionary = AstraCards.ENEMIES[kind].duplicate(true)
 value.id = kind; value.cost = 0; value.rarity = 0; value.upgrade = 0
 value.attack += int(data.act / 2) if int(data.get("ruleset",41)) >=43 or not modern() or kind in ["elite","boss"] else 0
 value.hp += int(data.act / 2)
 value.art = "p%d_%s" % [int(data.act),value.art]
 var clan: Array = AstraCards.CLANS[int(data.act)]
 for i in range(3): value.name[i] = clan[i] + " " + value.name[i]
 if kind == "boss": value.name = AstraCards.BOSSES[int(data.act)].duplicate()
 if data.act == 0 and kind == "drone": value.effect = "regen"
 if data.act == 1 and kind == "runner": value.effect = "freeze"
 if data.act == 2 and kind == "drone": value.effect = "burn"
 if data.act == 4 and kind == "runner": value.effect = "pierce"
 value.max_hp = value.hp; value.uid = data.serial; data.serial += 1
 if commands() and value.effect=="freeze":value.effect="chill"
 if commands() and value.effect=="frost":value.effect="softfrost"
 value.slowed=0;value.chill_until=0;value.target_lane=-1
 value.shield = 2 if kind == "tank" or (data.act == 1 and not commands()) else 0
 value.temporary = 0; value.frozen = 0; value.jammed = 0; value.burn = 0
 data.enemy[lane] = value
 events.append({"kind":"spawn","side":"enemy","lane":lane,"uid":value.uid})
func plan_intent() -> void:
 data.intent.clear()
 if data.get("tutorial",false): return
 if modern() and data.turn % 2 != 0 and not (data.kind == "boss" and data.boss_phase): return
 if data.turn > 12: return # Encounters end; endless reinforcements cannot soft-lock a run.
 var wanted = 1 if modern() else (2 if data.kind == "boss" or data.turn % 3 == 0 else 1)
 var empty: Array = []
 for lane in range(4):
  if data.enemy[lane] == null: empty.append(lane)
 shuffle(empty)
 for i in range(mini(wanted, empty.size())):
  var pool = ["drone","runner","tank"]
  if data.act > 0: pool.append("disruptor")
  if data.act > 1: pool.append("medic")
  data.intent.append({"lane":empty[i],"id":pool[rng.randi_range(0, pool.size()-1)]})
func play(hand_index: int, side: String, lane: int) -> bool:
 events.clear()
 if data.phase != "player" or hand_index < 0 or hand_index >= data.hand.size(): return false
 var entry: Dictionary = data.hand[hand_index]
 var value = instance(entry)
 if data.get("tutorial",false):
  var step = int(data.tutorial_step)
  if step == 0 and (value.id != "pulse" or lane != 1): return false
  if step in [1,2,4] or (step == 3 and value.id != "reactor"): return false
 if value.cost > data.energy or not ready_command(hand_index): return false
 if value.effect == "coreheal" and data.core >= data.max_core: return false
 if value.hp > 0:
  if side != "friendly" or lane < 0 or lane > 3 or data.friendly[lane] != null: return false
 else:
  var target = value.get("target", "all")
  if target != "all" and (side != ("friendly" if target == "friend" else "enemy") or lane < 0 or lane > 3 or data[side][lane] == null): return false
 data.energy -= value.cost
 if commands():data.used.append(entry.uid)
 else:data.hand.remove_at(hand_index)
 if value.hp > 0:
  if commands():
   value.blueprint_uid=entry.uid;value.uid=data.serial;data.serial+=1
  data.friendly[lane] = value
  events.append({"kind":"deploy","side":"friendly","lane":lane,"uid":value.uid})
 else:
  match value.effect:
   "coreheal":
    var healing = int(value.healing)
    var before = int(data.core); data.core = mini(data.max_core,data.core+healing)
    events.append({"kind":"heal_core","side":"friendly","damage":data.core-before})
   "heal": data.friendly[lane].hp = mini(data.friendly[lane].max_hp, data.friendly[lane].hp + 4)
   "barrier": data.friendly[lane].temporary += 3
   "overload":
    for i in range(4): hurt("enemy", i, 2, "")
   "boost":
    gain_energy(2)
    if not modern(): draw_cards(1)
   "emp": data.enemy[lane].jammed = 1; data.enemy[lane].frozen = 1
   "recall":
    var bot: Dictionary = data.friendly[lane]
    if commands():gain_energy(int(bot.cost/2))
    else:data.hand.append({"id":bot.id,"uid":bot.uid,"upgrade":bot.upgrade})
    data.friendly[lane] = null
    events.append({"kind":"withdraw","side":"friendly","lane":lane,"uid":bot.uid})
   "frost","softfrost":
    for bot in data.enemy:
     if bot != null:
      if commands():bot.slowed=1
      else:bot.frozen=1
   "storm": gain_energy(3); data.core -= 1
  if not commands():data.discard.append(entry)
  events.append({"kind":"ability","effect":value.effect,"side":side,"lane":lane,"uid":entry.uid})
 if data.get("tutorial",false):
  if data.tutorial_step == 0: data.tutorial_step = 1
  elif data.tutorial_step == 3: data.tutorial_step = 4
 evaluate()
 checkpoint()
 return true
func end_turn() -> bool:
 if data.phase != "player": return false
 if data.get("tutorial",false) and data.tutorial_step in [0,3]: return false
 data.phase = "resolving"; data.pending.clear()
 for side in ["friendly","enemy"]:
  for lane in range(4):
   var bot: Variant = data[side][lane]
   if bot == null: continue
   var attacks = 2 if bot.effect == "double" and bot.jammed == 0 else 1
   for _i in range(attacks): data.pending.append({"side":side,"lane":lane,"uid":bot.uid})
 data.pending.append({"side":"round"})
 checkpoint()
 return true
func order(lane: int, kind: String) -> bool:
 if not modern() or data.phase != "player" or data.energy < 1 or lane < 0 or lane > 3 or kind not in ["aim","guard"]: return false
 if data.get("tutorial",false): return false
 var bot: Variant = data.friendly[lane]
 if bot == null or int(bot.get("ordered_turn",-1)) == int(data.turn): return false
 if kind == "aim" and (bot.attack <= 0 or bot.frozen > 0): return false
 data.energy -= 1; bot.ordered_turn = data.turn
 if kind == "aim": bot.focus = int(data.get("tech",{}).get("aim",1))
 else: bot.temporary += 2
 events = [{"kind":"ability","side":"friendly","lane":lane,"uid":bot.uid,"effect":kind}]
 checkpoint(); return true
func resolve_next() -> Array:
 events.clear()
 if data.phase != "resolving" or data.pending.is_empty(): return []
 var action: Dictionary = data.pending.pop_front()
 if action.side == "round": next_round()
 else:
  var bot: Variant = data[action.side][int(action.lane)]
  if bot != null and bot.uid == action.uid:
   if bot.frozen > 0:
    bot.frozen -= 1
    events.append({"kind":"freeze","side":action.side,"lane":action.lane,"uid":bot.uid})
   elif bot.attack > 0: strike(action.side, int(action.lane))
 evaluate(); checkpoint()
 return events.duplicate(true)
func resolve_all() -> void:
 var safety = 30
 while data.phase == "resolving" and safety > 0:
  resolve_next(); safety -= 1
func strike(side: String, lane: int) -> void:
 var other = "enemy" if side == "friendly" else "friendly"
 var bot: Dictionary = data[side][lane]
 var effect: String = bot.effect if bot.jammed == 0 else ""
 var target_lane=lane
 if commands() and side=="friendly":
  var chosen=int(bot.get("target_lane",-1))
  if chosen>=0 and chosen<4 and data.enemy[chosen]!=null:target_lane=chosen
  elif data.enemy[lane]==null:
   for i in range(4):
    if data.enemy[i]!=null:target_lane=i;break
 var target: Variant = data[other][target_lane]
 var damage = maxi(0,int(bot.attack)+int(bot.get("focus",0))-int(bot.get("slowed",0)))
 bot.slowed=0
 bot.focus = 0
 events.append({"kind":"attack","side":side,"lane":lane,"target_lane":target_lane,"core_target":target==null,"damage":damage,"uid":bot.uid})
 if target == null:
  data["enemy_core" if side == "friendly" else "core"] -= damage
  events.append({"kind":"core","side":other,"damage":damage})
  if effect == "echo" and side == "friendly": draw_cards(1)
 else:
  var target_uid = target.uid
  hurt(other, target_lane, damage, side)
  if data[other][target_lane] == null and effect == "refund" and side == "friendly":
   if data.phase == "resolving": data.carry = mini(1,data.carry+1) if modern() else data.carry+1
   else: gain_energy(1)
  elif data[other][target_lane] != null and data[other][target_lane].uid == target_uid:
   if effect == "freeze": data[other][target_lane].frozen = 1
   if effect == "chill" and (side=="friendly" or data.turn%3==0) and data[other][target_lane].get("chill_until",0)<data.turn:
    data[other][target_lane].slowed=1;data[other][target_lane].chill_until=data.turn+2
   if effect == "burn": data[other][target_lane].burn = 2
   if effect == "jam": data[other][target_lane].jammed = 1
  if effect == "pierce": data["enemy_core" if side == "friendly" else "core"] -= 1
  if effect == "splash":
   for neighbour in [target_lane - 1, target_lane + 1]:
    if neighbour >= 0 and neighbour < 4: hurt(other, neighbour, 1, side)
func hurt(side: String, lane: int, amount: int, source_side: String) -> void:
 var bot: Variant = data[side][lane]
 if bot == null: return
 var damage = maxi(0,amount-int(bot.get("armor",0)))
 for neighbour in [lane - 1, lane + 1]:
  if neighbour < 0 or neighbour > 3: continue
  var guard: Variant = data[side][neighbour]
  if guard != null and guard.effect == "guard" and guard.jammed == 0: damage = maxi(0, damage - 1); break
 var absorbed = mini(damage, bot.temporary); bot.temporary -= absorbed; damage -= absorbed
 absorbed = mini(damage, bot.shield); bot.shield -= absorbed; damage -= absorbed
 bot.hp -= damage
 events.append({"kind":"hit","side":side,"lane":lane,"uid":bot.uid,"damage":damage})
 if bot.hp <= 0:
  data[side][lane] = null
  events.append({"kind":"death","side":side,"lane":lane,"uid":bot.uid})
  if side == "friendly" and not commands(): data.discard.append({"id":bot.id,"uid":bot.uid,"upgrade":bot.upgrade})
  if bot.effect == "deathburst" and bot.jammed == 0:
   var other = "enemy" if side == "friendly" else "friendly"
   for i in range(4): hurt(other, i, 2, source_side)
func next_round() -> void:
 # Status expiry precedes the next player turn; temporary shields protect exactly one combat phase.
 for side in ["friendly","enemy"]:
  for lane in range(4):
   var bot: Variant = data[side][lane]
   if bot == null: continue
   if bot.burn > 0: bot.burn -= 1; hurt(side, lane, 1, "")
   if data[side][lane] == null: continue
   bot.temporary = 0
   bot.focus = 0
   if bot.jammed == 0:
    if bot.effect == "regen" or (data.act == 0 and side == "enemy" and bot.id == "medic"): bot.hp = mini(bot.max_hp, bot.hp + 1)
    if bot.effect == "mend":
     for n in [lane-1,lane+1]:
      if n >= 0 and n < 4 and data[side][n] != null: data[side][n].hp = mini(data[side][n].max_hp, data[side][n].hp + 1)
 for intent in data.intent:
  if data.enemy[int(intent.lane)] == null: spawn(intent.id, int(intent.lane))
 data.turn += 1
 if data.get("tutorial",false): data.max_energy = 2
 elif int(data.get("ruleset",41)) >= 43: data.max_energy = (3 if data.turn < 4 else 4)+int(data.get("tech",{}).get("energy",0))
 else: data.max_energy = (2 if data.turn < 4 else 3) if modern() else mini(6, 3 + int((data.turn - 1) / 3))
 var refund = 0 if data.get("tutorial",false) else data.carry; data.carry = 0
 var reactors = 0
 for bot in data.friendly:
  if bot != null and bot.effect == "energy" and bot.jammed == 0: reactors += 1
 data.max_energy += mini(1,reactors) if modern() else 0
 data.energy = data.max_energy
 gain_energy(refund+(0 if modern() else reactors))
 for side in ["friendly","enemy"]:
  for bot in data[side]:
   if bot != null: bot.jammed = maxi(0,bot.jammed-1)
 if data.act == 3 and data.turn % 2 == 0: gain_energy(1)
 if data.act == 2 and data.turn % 3 == 0:
  for i in range(4):
   if data.friendly[i] != null: hurt("friendly", i, 1, "")
 if data.act == 1 and data.turn % 4 == 0 and not commands():
  for bot in data.friendly:
   if bot != null: bot.frozen = 1; break
 if data.act == 4 and data.turn % 4 == 0:
  for bot in data.friendly:
   if bot != null: bot.jammed = 1; break
 if data.kind == "boss" and not data.boss_phase and data.enemy_core <= int(data.max_enemy_core / 2):
  data.boss_phase = true
  for i in range(4):
   if data.enemy[i] == null: spawn("elite", i); break
  events.append({"kind":"boss_phase"})
 if data.get("tutorial",false) and data.turn == 2:
  for i in range(data.draw.size()):
   if data.draw[i].id == "reactor": data.hand.append(data.draw.pop_at(i)); break
  data.tutorial_step = 3
 else:
  draw_cards(1 if modern() else 2)
  if data.get("tutorial",false): data.tutorial_step = 5
 if commands():data.used.clear()
 plan_intent(); data.phase = "player"
 events.append({"kind":"round","turn":data.turn})
func evaluate() -> void:
 if data.core <= 0: data.core = 0; data.phase = "lost"; data.pending.clear()
 elif data.enemy_core <= 0: data.enemy_core = 0; data.phase = "won"; data.pending.clear()

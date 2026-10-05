extends RefCounted
class_name AstraRun
## Run and meta progression are distinct; legacy slots are read-only migration sources.
var store = OrbitProgress.new()
var path = "user://astra_cards_run.json"
var meta_path = "user://astra_cards_meta.json"
var data: Dictionary = {}
var meta: Dictionary = defaults_meta()
var battle = AstraBattle.new()
var rng = RandomNumberGenerator.new()
var notice = ""
var save_ok = true
static func defaults_meta() -> Dictionary:
 return {"version":4,"unlocked":[],"logs":[],"legacy_completed":{},"runs":0,"wins":0,"deaths":0,"highest_act":0,"decks":[0],"hulls":[0]}
func load_all() -> void:
 store.load_settings()
 var saved = store.read_json(meta_path)
 if not valid_meta(saved): saved = store.read_json(meta_path + ".bak")
 if valid_meta(saved): meta = AstraCards.integers(saved)
 for id in AstraCards.CARDS:
  if not AstraCards.CARDS[id].has("planet") and id not in meta.unlocked: meta.unlocked.append(id)
 migrate_legacy()
 var payload = store.read_json(path)
 if not valid_save(payload):
  var backup = store.read_json(path + ".bak")
  if valid_save(backup): payload = backup; notice = "recovered"
  elif FileAccess.file_exists(path): notice = "corrupt"
 if valid_save(payload):
  data = AstraCards.integers(payload.run)
  if not data.has("research"): data.research = AstraResearch.defaults()
  rng.state = int(data.rng)
  if not data.battle.is_empty(): battle.restore(data.battle)
func migrate_legacy(sources: Array = []) -> void:
 if sources.is_empty(): sources = ["user://orbit_progress.json","user://astra_slot_1.json","user://astra_slot_1_2.json","user://astra_slot_1_3.json"]
 for source in sources:
  var old = store.read_json(source)
  if not old is Dictionary: continue
  var progress = old.get("progress", old)
  if not store.valid(progress): continue
  for number in progress.completed:
   if int(str(number)) >= 1 and int(str(number)) <= 50:
    meta.legacy_completed[str(number)] = maxi(int(meta.legacy_completed.get(str(number), 0)), clampi(int(progress.completed[number]),1,3))
 if meta.legacy_completed.size() >= 10:
  if 1 not in meta.decks: meta.decks.append(1)
  if "legacy" not in meta.logs: meta.logs.append("legacy")
 if meta.legacy_completed.size() >= 20 and 2 not in meta.decks: meta.decks.append(2)
 # No run is skipped and no card receives a permanent stat bonus.
func save() -> bool:
 if data.is_empty(): return true
 data.rng = str(rng.state)
 if data.state == "battle": data.battle = battle.checkpoint()
 save_ok = store.atomic_write(path, {"format":"astra_tabletop","version":4,"run":data})
 if not save_ok: notice = "save_failed"
 if not store.atomic_write(meta_path, meta): save_ok = false; notice = "save_failed"
 return save_ok
func resume_available() -> bool:
 return not data.is_empty() and data.state not in ["defeat","ending"]
func new_run(seed_value: int = 0, deck_kind: int = 0) -> void:
 if deck_kind not in meta.decks: deck_kind = 0
 rng.seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec()
 data = {"state":"intro","act":0,"depth":-1,"column":1,"current":"","visited":[],"map":[],"deck":[],"serial":1,"core":20,"max_core":20,"credits":30,"battles":0,"reward":[],"stock":[],"battle":{},"rng":"0","intro":0,"seed":str(rng.seed),"deck_kind":deck_kind,"ended":false,"hull":0,"research":AstraResearch.defaults()}
 for id in AstraCards.starter(deck_kind): add_card(id)
 meta.runs += 1
 build_map(); save()
func add_card(id: String) -> void:
 data.deck.append({"id":id,"uid":data.serial,"upgrade":0}); data.serial += 1
 if id not in meta.unlocked: meta.unlocked.append(id)
func start_training() -> void:
 battle.start_training(data.deck,rng.randi())
 data.state = "battle"; data.battle = battle.checkpoint(); save()
func finish_training() -> void:
 data.core = 20; data.battle.clear(); battle.data.clear(); data.state = "map"; data.training_complete = true; save()
func build_map() -> void:
 data.map.clear(); data.depth = -1; data.column = 1; data.current = ""; data.visited.clear()
 var rows = [["battle"],["event","rest","reward"],["battle","elite","battle"],["upgrade","shop","remove"],["battle","planet","event"],["rest","reward","upgrade"],["boss"]]
 # Sides change by seed; deterministic links are built once and saved, not rerolled on loading.
 for depth in range(rows.size()):
  var kinds: Array = rows[depth].duplicate()
  if kinds.size() == 3 and rng.randi_range(0,1) == 1: kinds.reverse()
  for offset in range(kinds.size()):
   var col = offset if kinds.size() == 3 else 1
   var id = "%d_%d" % [depth,col]
   var links: Array = []
   if depth < 6:
    if depth == 5: links = ["6_1"]
    elif depth == 0: links = ["1_0","1_1","1_2"]
    else:
     for next_col in range(maxi(0,col-1),mini(2,col+1)+1): links.append("%d_%d" % [depth+1,next_col])
   data.map.append({"id":id,"depth":depth,"col":col,"kind":kinds[offset],"links":links})
func available_nodes() -> Array:
 if data.is_empty() or data.state != "map": return []
 if data.depth == -1: return ["0_1"]
 for node in data.map:
  if node.id == data.current: return node.links.duplicate()
 return []
func choose_node(id: String) -> bool:
 if id not in available_nodes(): return false
 var picked: Dictionary = {}
 for node in data.map:
  if node.id == id: picked = node; break
 if picked.is_empty(): return false
 data.current = id; data.depth = picked.depth; data.column = picked.col
 var kind: String = picked.kind
 match kind:
  "battle","elite","boss":
   battle.begin(data.deck, int(data.core), int(data.act), kind, rng.randi(),int(data.max_core),AstraResearch.bonuses(data.get("research",{})))
   data.battle = battle.checkpoint(); data.state = "battle"
  "reward": prepare_reward(false)
  "shop": data.state = "shop"; data.stock = offers(3)
  _: data.state = kind
 save(); return true
func offers(count: int) -> Array:
 var pool = AstraCards.reward_pool(int(data.act), meta.unlocked)
 var result: Array = []
 for _i in range(mini(count, pool.size())):
  var selected = rng.randi_range(0,pool.size()-1)
  result.append(pool.pop_at(selected))
 return result
func prepare_reward(after_battle: bool) -> void:
 data.reward = offers(3); data.state = "reward"
 if after_battle: data.credits += 16 + int(data.act) * 4 + (16 if battle.data.kind == "elite" else (30 if battle.data.kind == "boss" else 0))
func finish_battle() -> void:
 if data.state != "battle" or battle.data.phase not in ["won","lost"]: return
 if battle.data.get("tutorial",false): finish_training(); return
 data.core = battle.data.core
 if battle.data.phase == "lost":
  data.state = "defeat"
  if not data.ended: meta.deaths += 1; data.ended = true
 else:
  data.battles += 1; prepare_reward(true)
 save()
func take_reward(index: int) -> bool:
 if data.state != "reward" or index < -1 or index >= data.reward.size(): return false
 if index >= 0: add_card(data.reward[index])
 data.reward.clear(); finish_node(); return true
func finish_node() -> void:
 if data.current not in data.visited: data.visited.append(data.current)
 if data.depth == 6:
  var log_id = "act%d" % int(data.act)
  if log_id not in meta.logs: meta.logs.append(log_id)
  meta.highest_act = maxi(int(meta.highest_act),int(data.act)+1)
  if data.act >= 0 and 1 not in meta.decks: meta.decks.append(1)
  if data.act >= 1 and 2 not in meta.decks: meta.decks.append(2)
  if int(data.act)+1 not in meta.hulls: meta.hulls.append(int(data.act)+1)
  var special = ["verdant","frost","ember","storm","echo"][int(data.act)]
  if special not in meta.unlocked: meta.unlocked.append(special)
  if data.act == 4:
   data.state = "ending"
   if not data.ended: meta.wins += 1; data.ended = true
  else:
   data.act += 1; data.core = mini(int(data.max_core),int(data.core)+10)
   data.battle.clear(); build_map(); data.state = "travel"
 else: data.state = "map"
 save()
func upgrade(uid: int) -> bool:
 if data.state != "upgrade": return false
 for entry in data.deck:
  if int(entry.uid) == uid and entry.upgrade < 2:
   entry.upgrade += 1; finish_node(); return true
 return false
func remove_card(uid: int) -> bool:
 if data.state != "remove" or data.deck.size() <= 6: return false
 for i in range(data.deck.size()):
  if int(data.deck[i].uid) == uid: data.deck.remove_at(i); finish_node(); return true
 return false
func rest() -> bool:
 if data.state != "rest": return false
 data.core = mini(int(data.max_core),int(data.core)+7); finish_node(); return true
func shop_buy(index: int) -> bool:
 if data.state != "shop" or index < 0 or index >= data.stock.size() or data.stock[index] == "": return false
 var id: String = data.stock[index]
 var cost = 20 + int(AstraCards.CARDS[id].rarity) * 8
 if data.credits < cost: return false
 data.credits -= cost; add_card(id); data.stock[index] = ""; save(); return true
func event_choice(choice: int) -> bool:
 if data.state not in ["event","planet"] or choice not in [0,1]: return false
 if choice == 0: data.credits += 18
 else:
  if data.core <= 3: return false
  data.core -= 3
  add_card(["verdant","frost","ember","storm","echo"][int(data.act)])
 var log_id = "signal%d" % int(data.act)
 if log_id not in meta.logs: meta.logs.append(log_id)
 finish_node(); return true
func buy_research(branch: String, rank: int) -> bool:
 if data.get("state","") not in ["map","upgrade","travel","rest","shop"] or branch not in AstraResearch.BRANCHES: return false
 if not data.has("research"): data.research = AstraResearch.defaults()
 var level = int(data.research[branch])
 if rank != level or level >= 3 or int(data.act)<level or data.credits<AstraResearch.COSTS[level]: return false
 data.credits -= AstraResearch.COSTS[level]; data.research[branch] = level+1
 if branch == "core": data.max_core += 4; data.core = mini(data.max_core,data.core+4)
 save(); return true
func valid_meta(value: Variant) -> bool:
 if not value is Dictionary or value.get("version",0) != 4: return false
 for key in ["unlocked","logs","decks","hulls"]:
  if not value.get(key) is Array: return false
 if 0 not in value.decks or 0 not in value.hulls: return false
 if not value.get("legacy_completed") is Dictionary: return false
 for key in ["runs","wins","deaths","highest_act"]:
  if not numeric(value.get(key),0,1000000): return false
 for id in value.unlocked:
  if id not in AstraCards.CARDS: return false
 for kind in value.decks:
  if not numeric(kind,0,2): return false
 for hull in value.hulls:
  if not numeric(hull,0,5): return false
 for log_id in value.logs:
  if not log_id is String or log_id.length() > 40: return false
 return true
static func numeric(value: Variant, low: float, high: float) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value) >= low and float(value) <= high and float(value) == floor(float(value))
func valid_entry(value: Variant) -> bool:
 return value is Dictionary and value.get("id","") in AstraCards.CARDS and numeric(value.get("uid"),1,1000000) and numeric(value.get("upgrade"),0,2)
func valid_save(payload: Variant) -> bool:
 if not payload is Dictionary or payload.get("format") != "astra_tabletop" or payload.get("version") != 4 or not payload.get("run") is Dictionary: return false
 var run: Dictionary = payload.run
 if run.get("state","") not in ["intro","map","battle","reward","event","planet","upgrade","rest","shop","remove","travel","defeat","ending"]: return false
 for key in ["act","depth","column","serial","core","max_core","credits","battles","intro","deck_kind","hull"]:
  var ranges = {"act":[0,4],"depth":[-1,6],"column":[0,2],"core":[0,32],"max_core":[20,32],"intro":[0,4],"deck_kind":[0,2],"hull":[0,5]}
  var bounds: Array = ranges.get(key,[0,1000000])
  if not numeric(run.get(key),bounds[0],bounds[1]): return false
 if run.core > run.max_core or int(run.max_core) % 4 != 0: return false
 if run.has("research") and (not AstraResearch.valid(run.research) or run.max_core != 20+4*int(run.research.core)): return false
 if not run.has("research") and run.max_core != 20: return false
 if not run.get("rng") is String or not run.rng.is_valid_int() or not run.get("seed") is String or not run.get("ended") is bool: return false
 for key in ["deck","map","visited","reward","stock"]:
  if not run.get(key) is Array or run[key].size() > 100: return false
 if run.deck.size() < 6 or run.deck.size() > 80: return false
 var seen: Array = []
 for entry in run.deck:
  if not valid_entry(entry) or entry.uid in seen: return false
  seen.append(entry.uid)
 if run.map.size() != 17: return false
 var ids: Array = []
 for node in run.map:
  if not node is Dictionary or not node.get("id") is String or node.id in ids or node.get("kind","") not in AstraCards.NODE_KINDS + ["boss"] or not node.get("links") is Array or not numeric(node.get("depth"),0,6) or not numeric(node.get("col"),0,2): return false
  if node.id != "%d_%d" % [int(node.depth),int(node.col)]: return false
  ids.append(node.id)
 for node in run.map:
  for link in node.links:
   if link not in ids: return false
 for id in run.visited:
  if id not in ids: return false
 if not run.get("current") is String or (run.current != "" and run.current not in ids): return false
 for id in run.reward + run.stock:
  if id != "" and id not in AstraCards.CARDS: return false
 if not run.get("battle") is Dictionary: return false
 if run.state == "battle" and not valid_battle(run.battle, seen): return false
 return true
func valid_battle(value: Dictionary, owned: Array) -> bool:
 if value.get("phase","") not in ["player","resolving","won","lost"]: return false
 if value.get("kind","") not in ["battle","elite","boss"] or not value.get("rng") is String or not value.rng.is_valid_int() or not value.get("boss_phase") is bool: return false
 for key in ["act","turn","core","max_core","enemy_core","max_enemy_core","energy","max_energy","serial"]:
  var limits = {"act":[0,4],"turn":[1,10000],"core":[0,32],"max_core":[20,32],"enemy_core":[0,100],"max_enemy_core":[1,100],"energy":[0,12],"max_energy":[1,6],"serial":[1000,1000000]}
  if not numeric(value.get(key),limits[key][0],limits[key][1]): return false
 for key in ["hand","draw","discard","friendly","enemy","pending","intent"]:
  if not value.get(key) is Array or value[key].size() > 100: return false
 if value.friendly.size() != 4 or value.enemy.size() != 4 or value.hand.size() > 7: return false
 if value.has("ruleset") and (not numeric(value.ruleset,41,43)): return false
 if int(value.get("ruleset",41)) == 42 and (value.hand.size() > 5 or value.energy > value.max_energy or value.max_energy > 5): return false
 if int(value.get("ruleset",41)) == 43 and (value.hand.size()>5 or value.energy>value.max_energy or value.max_energy>6): return false
 if value.core>value.max_core or value.enemy_core>value.max_enemy_core: return false
 if value.has("tech") and not value.tech.is_empty() and not AstraResearch.valid_bonuses(value.tech): return false
 if value.has("briefed") and not value.briefed is bool: return false
 if value.has("taunt") and not numeric(value.taunt,0,2): return false
 if value.has("tutorial") and (not value.tutorial is bool or not numeric(value.get("tutorial_step"),0,5)): return false
 var located: Array = []
 for entry in value.hand + value.draw + value.discard:
  if not valid_entry(entry) or entry.uid not in owned or entry.uid in located: return false
  located.append(entry.uid)
 for side in ["friendly","enemy"]:
  for bot in value[side]:
   if bot == null: continue
   if not bot is Dictionary: return false
   if not bot.get("name") is Array or bot.name.size() != 3 or not bot.get("art") is String: return false
   for text in bot.name:
    if not text is String: return false
   if side == "friendly":
    if not valid_entry(bot) or bot.uid not in owned or bot.uid in located: return false
    if AstraCards.CARDS[bot.id].hp <= 0 or bot.art != AstraCards.CARDS[bot.id].art or bot.get("effect") != AstraCards.CARDS[bot.id].effect: return false
    located.append(bot.uid)
   elif bot.get("id","") not in AstraCards.ENEMIES: return false
   elif bot.art != "p%d_%s" % [int(value.act),AstraCards.ENEMIES[bot.id].art]: return false
   for key in ["hp","max_hp","attack","shield","temporary","frozen","jammed","burn","uid"]:
    if not numeric(bot.get(key),0,1000000): return false
   if bot.hp <= 0 or bot.hp > bot.max_hp or not bot.get("effect") is String: return false
   if not numeric(bot.get("cost"),0,12) or not numeric(bot.get("rarity"),0,4): return false
   if bot.has("armor") and not numeric(bot.armor,0,1): return false
   if bot.has("focus") and not numeric(bot.focus,0,2): return false
   if bot.has("ordered_turn") and not numeric(bot.ordered_turn,1,10000): return false
 if located.size() != owned.size(): return false
 for action in value.pending:
  if not action is Dictionary or action.get("side","") not in ["friendly","enemy","round"]: return false
  if action.side != "round" and (not numeric(action.get("lane"),0,3) or not numeric(action.get("uid"),0,1000000)): return false
 if value.phase == "resolving" and (value.pending.is_empty() or value.pending[-1].side != "round"): return false
 for intent in value.intent:
  if not intent is Dictionary or intent.get("id","") not in AstraCards.ENEMIES or not numeric(intent.get("lane"),0,3): return false
 return true

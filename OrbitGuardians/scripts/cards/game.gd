extends Node
class_name AstraGame
## Main mobile shell. Every mutation is checkpointed; a resolving turn resumes safely.
var run = AstraRun.new()
var world: AstraTable
var view: AstraTableUI
var screen = "menu"
var previous_screen = "menu"
var selected = -1
var page = 0
var deck_kind = 0
var pointer = Vector2.ZERO
var pointer_start = Vector2.ZERO
var pointer_id = -99
var drag_key = ""
var drag_index = -1
var pressed: Dictionary = {}
var dragging = false
var cast_on_release = false
var clock = 0.0
var phase_clock = 0.0
var lock_clock = 0.0
var toast = ""
var toast_clock = 0.0
var sounds: Dictionary = {}
var music: AudioStreamPlayer
var quitting = false
var slider = ""
var inspect_entry: Dictionary = {}
var hold_entry: Dictionary = {}
var hold_clock = 0.0
var selected_node = ""
var route_travel = 0.0
func language() -> String:
 return run.store.data.language
func l(key: String) -> String:
 return AstraWords.get_text(key,language())
func _ready() -> void:
 get_tree().auto_accept_quit = false
 get_tree().root.close_requested.connect(quit_game)
 run.load_all()
 for key in ["deploy","energy","hit","alarm","unlock"]:
  var player = AudioStreamPlayer.new(); add_child(player); player.stream = load("res://audio/%s.wav" % key); sounds[key] = player
 music = AudioStreamPlayer.new(); add_child(music); music.stream = load("res://audio/table_hum.wav")
 music.finished.connect(func():
  if not quitting: music.play()
 )
 apply_settings(); music.play()
 world = AstraTable.new(); world.game = self; add_child(world)
 view = AstraTableUI.new(); view.game = self; add_child(view)
 if run.notice != "": notify(run.notice,7)
func apply_settings() -> void:
 var prefs: Dictionary = run.store.data
 var master = prefs.master_volume if prefs.sound else 0.0
 if music != null: music.volume_db = linear_to_db(maxf(0.00001,master*prefs.music_volume))-7
 for player in sounds.values(): player.volume_db = linear_to_db(maxf(0.00001,master*prefs.effects_volume))-10
 if DisplayServer.get_name() != "headless": DisplayServer.window_set_title("Orbital Front · Astra / Tabletop")
func fx(key: String) -> void:
 if run.store.data.sound and sounds.has(key): sounds[key].play()
func notify(key: String, seconds: float = 2.5) -> void:
 toast = key; toast_clock = seconds
func persist() -> void:
 if not run.save(): notify("save_failed",8)
func set_screen(value: String) -> void:
 screen = value; selected = -1; page = 0; drag_key = ""; drag_index = -1; dragging = false; slider = ""; pointer_id = -99; pressed = {}; hold_entry.clear()
 route_travel = 0.0
 if screen == "map" and selected_node not in run.available_nodes(): selected_node = ""
 if view != null: view.queue_redraw()
func display_entries() -> Array:
 if screen == "collection":
  var entries: Array = []
  var index = 8000
  for id in run.meta.unlocked: entries.append({"id":id,"uid":index,"upgrade":0}); index += 1
  return entries
 return run.data.get("deck",[])
func action(command: String, value: Variant = 0) -> void:
 fx("deploy")
 match command:
  "new": set_screen("new")
  "deck_kind":
   if int(value) in run.meta.decks: deck_kind = int(value)
  "start": run.new_run(0,deck_kind); set_screen("intro")
  "continue":
   if run.resume_available(): set_screen(run.data.state)
  "intro":
   run.data.intro += 1
   if run.data.intro >= 3: run.data.state = "map"
   persist(); set_screen(run.data.state)
  "node":
   if screen == "map" and route_travel <= 0 and str(value) in run.available_nodes(): selected_node = str(value)
   else: notify("route_locked")
  "depart":
   if screen == "map" and route_travel <= 0 and selected_node in run.available_nodes():
    route_travel = .85; world.diorama.travel_to(selected_node,.80)
  "overview": previous_screen = screen; set_screen("overview")
  "overview_back": set_screen("map")
  "turn":
   if screen == "battle" and lock_clock <= 0 and run.battle.end_turn(): selected = -1; phase_clock = 0.4; persist()
  "cast":
   if selected >= 0: play_selected("friendly",0)
  "pause": previous_screen = screen; persist(); set_screen("pause")
  "resume": set_screen(previous_screen if previous_screen not in ["menu","pause"] else run.data.state)
  "menu": persist(); set_screen("menu")
  "settings": previous_screen = screen; set_screen("settings")
  "back": set_screen(previous_screen if screen in ["settings","deck"] else "menu")
  "inspect_back": set_screen(previous_screen)
  "collection": set_screen("collection")
  "records": previous_screen = screen; set_screen("records")
  "deck": previous_screen = screen; set_screen("deck")
  "language": run.store.data.language = str(value); run.store.save_settings(); apply_settings()
  "hull":
   if not run.data.is_empty(): run.data.hull = (int(run.data.hull)+1)%run.meta.hulls.size(); persist()
  "reward":
   if run.take_reward(int(value)): fx("unlock"); set_screen(run.data.state)
  "browse":
   var entries = display_entries()
   if int(value) >= 0 and int(value) < entries.size():
    if screen == "upgrade" and run.upgrade(int(entries[int(value)].uid)): set_screen(run.data.state)
    elif screen == "remove" and run.remove_card(int(entries[int(value)].uid)): set_screen(run.data.state)
    elif screen in ["deck","collection"]:
     var card = AstraCards.card(entries[int(value)].id,int(entries[int(value)].upgrade))
     open_inspector(card)
  "page": page = clampi(page+int(value),0,maxi(0,int(((run.meta.logs.size()-1)/3) if screen == "records" else ((display_entries().size()-1)/6)))); selected = -1
  "rest":
   if run.rest(): fx("energy"); set_screen(run.data.state)
  "event":
   if run.event_choice(int(value)): set_screen(run.data.state)
  "buy":
   if run.shop_buy(int(value)): fx("unlock")
   else: notify("no_alloy")
  "leave":
   if run.data.state in ["shop","upgrade","remove"]: run.finish_node(); set_screen(run.data.state)
  "travel": run.data.state = "map"; persist(); set_screen("map")
  "quit": quit_game()
func play_selected(side: String, lane: int) -> void:
 if screen != "battle" or lock_clock > 0 or selected < 0: return
 var index = selected
 if index >= run.battle.data.hand.size(): selected = -1; return
 var entry = AstraCards.card(run.battle.data.hand[index].id,int(run.battle.data.hand[index].upgrade))
 if entry.cost > run.battle.data.energy: notify("no_energy"); return
 if run.battle.play(index,side,lane):
  selected = -1; drag_key = ""; drag_index = -1; lock_clock = 0.4
  world.feedback(run.battle.events); fx("deploy" if entry.hp > 0 else "energy"); persist()
  if run.battle.data.phase in ["won","lost"]: run.finish_battle(); set_screen(run.data.state)
 else: notify("invalid_target")
func update_slider(point: Vector2) -> void:
 if slider == "": return
 run.store.data[slider] = clampf((point.x-120)/480.0,0,1)
 apply_settings(); view.queue_redraw()
func open_inspector(entry: Dictionary) -> void:
 previous_screen = screen; inspect_entry = entry.duplicate(true); set_screen("inspect"); hold_entry.clear()
func pointer_down(point: Vector2, identity: int) -> void:
 if pointer_id != -99: return
 pointer_id = identity; pointer = point; pointer_start = point; dragging = false; pressed = {}; cast_on_release = false; hold_entry.clear(); hold_clock = 0
 for item in view.buttons:
  if item.rect.has_point(point):
   pressed = item
   if item.command == "slider": slider = str(item.value); update_slider(point)
   return
 if screen == "battle" and run.battle.data.phase == "player" and lock_clock <= 0:
  var card = world.pick_card(point)
  if not card.is_empty(): hold_entry = card.entry.duplicate(true)
  if not card.is_empty() and card.hand >= 0:
   var index = int(card.hand)
   cast_on_release = selected == index
   selected = index; drag_index = index; drag_key = card.key
 elif screen == "map": pressed = {"command":"map"}
func pointer_move(point: Vector2, identity: int) -> void:
 if pointer_id != identity: return
 var difference = point - pointer
 pointer = point
 if slider != "": update_slider(point); return
 if pointer.distance_to(pointer_start) > 18: dragging = true
 if dragging and screen == "map": world.scroll_map(difference.y*0.5)
func pointer_up(point: Vector2, identity: int) -> void:
 if pointer_id != identity: return
 pointer = point
 if slider != "": run.store.save_settings(); slider = ""
 elif not pressed.is_empty() and pressed.get("command","") != "map":
  if pressed.rect.has_point(point): action(pressed.command,pressed.value)
 elif screen == "map" and not dragging:
  for value in world.map_nodes.values():
   if point.distance_to(value.point) <= 38: action("node",value.node.id); break
 elif screen == "battle" and run.battle.data.phase == "player" and lock_clock <= 0:
  if drag_index >= 0:
   if dragging:
    var slot = world.pick_slot(point)
    if not slot.is_empty(): play_selected(slot.side,int(slot.lane))
    elif selected >= 0 and selected < run.battle.data.hand.size():
     var entry = AstraCards.card(run.battle.data.hand[selected].id)
     if entry.get("target","") == "all" and point.y < 890 and point.y > 330: play_selected("friendly",0)
   elif cast_on_release and selected >= 0:
    var entry = AstraCards.card(run.battle.data.hand[selected].id)
    if entry.get("target","") == "all": play_selected("friendly",0)
  else:
   var slot = world.pick_slot(point)
   if not slot.is_empty() and selected >= 0: play_selected(slot.side,int(slot.lane))
   elif selected < 0:
    var card = world.pick_card(point)
    if not card.is_empty(): open_inspector(card.entry)
 elif screen in ["reward","shop","upgrade","remove","deck","collection"]:
  var card = world.pick_card(point)
  if not card.is_empty(): action("reward" if screen == "reward" else ("buy" if screen == "shop" else "browse"),int(card.lane))
 pointer_id = -99; drag_key = ""; drag_index = -1; dragging = false; pressed = {}; hold_entry.clear()
 view.queue_redraw()
func _input(event: InputEvent) -> void:
 if view == null or quitting: return
 var point = Vector2.ZERO
 if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventMouseMotion: point = view.get_global_transform_with_canvas().affine_inverse()*event.position
 if event is InputEventScreenTouch:
  if event.pressed: pointer_down(point,event.index)
  else: pointer_up(point,event.index)
 elif event is InputEventScreenDrag: pointer_move(point,event.index)
 elif event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_LEFT:
   if event.pressed: pointer_down(point,-1)
   else: pointer_up(point,-1)
  elif event.pressed and screen == "map" and event.button_index in [MOUSE_BUTTON_WHEEL_DOWN,MOUSE_BUTTON_WHEEL_UP]: world.scroll_map(-30 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 30)
 elif event is InputEventMouseMotion: pointer_move(point,-1)
func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_GO_BACK_REQUEST and view != null:
  if screen == "battle" or screen == "map": action("pause")
  elif screen == "pause": action("resume")
  elif screen == "inspect" or screen == "records": action("inspect_back")
  elif screen in ["settings","deck"]: action("back")
  elif screen == "overview": action("overview_back")
  else: action("menu")
 if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT] and not run.data.is_empty():
  pointer_id = -99; drag_key = ""; drag_index = -1; hold_entry.clear()
  run.store.save_settings()
  persist()
  if screen == "battle": previous_screen = "battle"; set_screen("pause")
func _process(delta: float) -> void:
 clock += delta; lock_clock = maxf(0,lock_clock-delta); toast_clock = maxf(0,toast_clock-delta)
 if screen == "map" and route_travel > 0:
  route_travel -= delta
  if route_travel <= 0:
   if run.choose_node(selected_node): phase_clock = 0; set_screen(run.data.state)
   else: notify("route_locked")
 if pointer_id != -99 and not dragging and not hold_entry.is_empty():
  hold_clock += delta
  if hold_clock > 0.65: open_inspector(hold_entry)
 if screen == "battle" and not run.battle.data.is_empty() and run.battle.data.phase == "resolving":
  phase_clock -= delta
  if phase_clock <= 0:
   var events = run.battle.resolve_next(); world.feedback(events)
   for event in events:
    if event.kind in ["attack","hit","core"]: fx("hit"); break
   for event in events:
    if event.kind == "boss_phase": notify("boss_phase",4)
   phase_clock = 0.48; persist()
   if run.battle.data.phase in ["won","lost"]: run.finish_battle(); set_screen(run.data.state)
 if view != null: view.queue_redraw()
func _exit_tree() -> void:
 if music != null: music.stop(); music.stream = null
 for player in sounds.values(): player.stop(); player.stream = null
func quit_game(exit_code: int = 0) -> void:
 if quitting: return
 quitting = true; persist(); set_process(false)
 if music != null: music.stop(); music.stream = null
 for player in sounds.values(): player.stop(); player.stream = null
 await get_tree().create_timer(0.2).timeout
 get_tree().quit(exit_code)

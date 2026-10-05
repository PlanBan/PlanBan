extends SceneTree
var game: AstraGame
var checks = 0
var failures = 0
var output = "/workspace/artifacts/cards"
func check(value: bool, name: String) -> void:
 checks += 1
 if not value: failures += 1; printerr("FAIL: ",name)
func _initialize() -> void:
 call_deferred("run_test")
func frames(count: int = 12) -> void:
 for i in range(count): await process_frame
func touch(point: Vector2, down: bool, index: int = 0) -> void:
 var event = InputEventScreenTouch.new(); event.index = index; event.position = root.get_final_transform()*game.view.get_global_transform_with_canvas()*point; event.pressed = down
 Input.parse_input_event(event)
 await process_frame
func tap(point: Vector2) -> void:
 await touch(point,true); await touch(point,false); await frames(4)
func command(name: String, value: Variant = null) -> void:
 await frames(3)
 var rect = Rect2()
 for item in game.view.buttons:
  if item.command == name and (value == null or item.value == value): rect = item.rect; break
 check(rect.size.x > 0,"visible touch button "+name)
 if rect.size.x > 0: await tap(rect.get_center())
func screenshot(name: String) -> void:
 await frames(8); await RenderingServer.frame_post_draw
 var image_value = root.get_texture().get_image()
 image_value.save_png(output+"/"+name+".png")
func run_test() -> void:
 DirAccess.make_dir_recursive_absolute(output)
 root.size = Vector2i(480,854)
 game = load("res://scenes/Tabletop.tscn").instantiate()
 game.run.path = "user://qa_cards_graphics.json"; game.run.meta_path = "user://qa_cards_graphics_meta.json"; game.run.store.settings_path = "user://qa_cards_graphics_prefs.json"
 for path in [game.run.path,game.run.meta_path,game.run.store.settings_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 root.add_child(game); await frames(30)
 check(game.screen == "menu" and game.run.data.is_empty(),"boot goes to menu")
 await screenshot("menu")
 await command("new"); check(game.screen == "new","new expedition screen")
 await command("start"); check(game.screen == "intro","story starts from beginning")
 await screenshot("intro")
 for i in range(3): await command("intro")
 check(game.screen == "map" and game.world.map_nodes.size() == 17,"physical branching map")
 await screenshot("map")
 var node = game.world.map_nodes["0_1"].point
 await tap(node); await frames(30)
 check(game.screen == "battle","node tap enters card battle")
 check(game.world.cards.size() >= 6,"real physical hand and enemy plates")
 for side in ["friendly","enemy"]:
  for lane in range(4):
   var point = game.world.slot_point(side,lane)
   var hit = game.world.pick_slot(point)
   check(not hit.is_empty() and hit.side == side and int(hit.lane) == lane,"slot picking "+side+str(lane))
 var first = game.run.battle.data.hand[0]
 var key = "c"+str(first.uid)
 var plate: Dictionary = game.world.cards[key]
 check(game.world.pick_card(plate.point).get("hand",-1) == 0,"hand mesh hit test")
 var before = game.run.battle.data.energy
 await tap(plate.point); await frames(12)
 check(game.selected == 0,"finger selects card")
 await tap(game.world.slot_point("friendly",0)); await frames(30)
 check(game.run.battle.data.friendly[0] != null and game.run.battle.data.energy == before-1,"finger deploys and spends energy")
 await create_timer(0.6).timeout
 check(game.world.cards[key].side == "friendly" and game.world.cards[key].node.position.distance_to(game.world.cards[key].target) < .15,"same physical card moves from hand to table")
 await screenshot("battle")
 # Drag the actual reactor from the real hand into another socket.
 var reactor_index = -1
 for i in range(game.run.battle.data.hand.size()):
  if game.run.battle.data.hand[i].id == "reactor": reactor_index = i; break
 check(reactor_index >= 0,"reactor is drawn from deck")
 var reactor_key = "c"+str(game.run.battle.data.hand[reactor_index].uid)
 var source: Vector2 = game.world.cards[reactor_key].point
 await touch(source,true)
 # Second finger must not steal the first finger's drag.
 await touch(Vector2(650,1195),true,1)
 for i in range(1,7):
  var event = InputEventScreenDrag.new(); event.index = 0; event.position = root.get_final_transform()*game.view.get_global_transform_with_canvas()*source.lerp(game.world.slot_point("friendly",3),i/6.0)
  Input.parse_input_event(event); await frames(2)
 await touch(game.world.slot_point("friendly",3),false)
 await touch(Vector2(650,1195),false,1); await frames(35)
 check(game.run.battle.data.friendly[3] != null and game.run.battle.data.friendly[3].id == "reactor","touch drag plays Reactor; extra finger ignored")
 check(game.run.battle.data.energy == 0,"cost charged once")
 # Long-press opens a readable physical plate without consuming it.
 var remaining_key = "c"+str(game.run.battle.data.hand[0].uid)
 await touch(game.world.cards[remaining_key].point,true)
 await create_timer(.8).timeout
 await touch(game.world.cards.get(remaining_key,{"point":Vector2.ZERO}).point,false)
 check(game.screen == "inspect","long press opens large card")
 await screenshot("inspector")
 await command("inspect_back"); check(game.screen == "battle","inspector returns to combat")
 await command("turn"); check(game.run.battle.data.phase == "resolving","touch starts combat phase")
 await create_timer(.62).timeout
 var saved = game.run.store.read_json(game.run.path)
 check(saved.run.battle.phase == "resolving" and not saved.run.battle.pending.is_empty(),"autosave preserves unfinished enemy phase")
 var copy = AstraRun.new(); copy.path = game.run.path; copy.meta_path = game.run.meta_path; copy.load_all()
 check(not copy.data.is_empty() and copy.battle.data.phase == "resolving","fresh model resumes this exact checkpoint")
 await create_timer(2.4).timeout
 check(game.run.battle.data.turn >= 2 and game.run.battle.data.energy >= 4,"new turn refills and Reactor supplies bonus")
 # Complete the encounter under normal economy, without replacing health or resources.
 var ai = load("res://tests/cards/journey.gd")
 game.set_process(false)
 var turns = 0
 while game.run.battle.data.phase not in ["won","lost"] and turns < 60:
  ai.play_turn(game.run.battle); game.run.battle.end_turn(); game.run.battle.resolve_all(); turns += 1
 check(game.run.battle.data.phase == "won","vertical slice fight is winnable using normal cards")
 game.run.finish_battle(); game.set_screen(game.run.data.state); await frames(30)
 check(game.screen == "reward","battle victory presents real reward")
 await screenshot("reward")
 var old_count = game.run.data.deck.size()
 await tap(Vector2(360,570)); await frames(30)
 check(game.run.data.deck.size() == old_count+1 and game.screen == "map","touch chooses a card and returns to route")
 var choices = game.run.available_nodes()
 check(choices.size() == 3,"three real next route choices")
 var next_node = game.world.map_nodes[choices[0]]
 await tap(next_node.point); check(game.screen != "map","next node opens an event or station")
 game.run.data.state = "map"; game.set_screen("map")
 await command("pause"); check(game.screen == "pause","pause via touch")
 await command("settings"); await command("language","de")
 var slider = InputEventScreenTouch.new(); slider.index = 0; slider.pressed = true; slider.position = root.get_final_transform()*game.view.get_global_transform_with_canvas()*Vector2(264,722)
 Input.parse_input_event(slider); await frames(2); slider = InputEventScreenTouch.new(); slider.index = 0; slider.pressed = false; slider.position = root.get_final_transform()*game.view.get_global_transform_with_canvas()*Vector2(264,722); Input.parse_input_event(slider)
 check(absf(game.run.store.data.music_volume-.3) < .01,"touch music slider")
 await screenshot("settings-de")
 await command("back"); await command("resume")
 # Each world is rendered and its unique enemy clan is loaded.
 for act in range(5):
  game.run.data.act = act
  game.run.battle.begin(game.run.data.deck,20,act,"boss",41293+act)
  game.run.data.state = "battle"; game.set_screen("battle"); await frames(25)
  check(game.world.biome_index == act,"planet atmosphere "+str(act))
  await screenshot("world-%d" % act)
 # Letterboxed desktop and tall phone picking use the actual canvas transform.
 for resolution in [Vector2i(720,1280),Vector2i(960,720),Vector2i(390,844)]:
  root.size = resolution; await frames(25)
  for lane in range(4):
   var point = game.world.slot_point("friendly",lane)
   var projected = game.world.project(game.world.position_for(point))
   if projected.distance_to(point) >= .5: print("PROJECTION DIAGNOSTIC: ",resolution," ",point," -> ",projected," canvas=",game.view.get_global_transform_with_canvas()," final=",root.get_final_transform())
   check(projected.distance_to(point) < .5,"projection at "+str(resolution)+" lane "+str(lane))
 for code in ["ru","en","de"]:
  game.run.store.data.language = code; game.run.data.state = "map"; game.run.build_map(); game.set_screen("map"); await frames(25)
  for item in game.view.buttons: check(item.rect.size.y >= 60,"touch control size")
 root.size = Vector2i(480,854); await frames(20)
 game.set_process(true)
 for path in [game.run.path,game.run.meta_path,game.run.store.settings_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 # quit_game writes again, so remove the isolated run before the final shutdown.
 game.run.data.clear()
 print("CARD GRAPHICS: ",checks," checks, ",failures," failures")
 game.quit_game(0 if failures == 0 else 1)

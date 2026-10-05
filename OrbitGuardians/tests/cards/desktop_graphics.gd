extends SceneTree
var game: AstraGame
var checks = 0
var failures = 0
var output = "/workspace/artifacts/desktop"
func check(value: bool, name: String) -> void:
 checks += 1
 if not value: failures += 1; printerr("FAIL: ",name)
func _initialize() -> void:
 call_deferred("run_test")
func frames(count: int = 8) -> void:
 for i in range(count): await process_frame
func mouse(point: Vector2, down: bool, button: int = MOUSE_BUTTON_LEFT) -> void:
 var event = InputEventMouseButton.new(); event.button_index = button; event.pressed = down
 event.position = root.get_final_transform()*game.view.get_global_transform_with_canvas()*point
 Input.parse_input_event(event); await process_frame
func tap(point: Vector2) -> void:
 await mouse(point,true); await mouse(point,false); await frames(4)
func move(point: Vector2) -> void:
 var event = InputEventMouseMotion.new(); event.position = root.get_final_transform()*game.view.get_global_transform_with_canvas()*point
 Input.parse_input_event(event); await process_frame
func key(code: int, ctrl: bool = false) -> void:
 var event = InputEventKey.new(); event.keycode = code; event.pressed = true; event.ctrl_pressed = ctrl
 Input.parse_input_event(event); await frames(4)
func command(name: String, value: Variant = null) -> void:
 await frames(3)
 var rect = Rect2()
 for item in game.view.buttons:
  if item.command == name and (value == null or item.value == value): rect = item.rect; break
 check(rect.size.x > 0,"visible button "+name)
 if rect.size.x > 0: await tap(rect.get_center())
func screenshot(name: String) -> void:
 await frames(10); await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output+"/"+name+".png")
func hand_rect(index: int) -> Rect2:
 for card in game.view.card_hits:
  if card.hand == index: return card.rect
 return Rect2()
func wait_player() -> void:
 for i in range(100):
  if game.screen != "battle" or game.run.battle.data.phase != "resolving": return
  await create_timer(.1).timeout
 check(false,"turn resolution completed within ten seconds")
func run_test() -> void:
 DirAccess.make_dir_recursive_absolute(output); root.size = Vector2i(1280,720)
 game = load("res://scenes/Tabletop.tscn").instantiate()
 game.run.path = "user://qa_desktop_graphics.json"; game.run.meta_path = "user://qa_desktop_graphics_meta.json"; game.run.store.settings_path = "user://qa_desktop_graphics_prefs.json"
 for path in [game.run.path,game.run.meta_path,game.run.store.settings_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 root.add_child(game); await frames(25)
 check(game.view is AstraDesktopUI and game.view.size == Vector2(1600,900),"wide desktop UI fills a 16:9 window")
 check(game.screen == "menu" and game.run.data.is_empty(),"boot opens menu")
 check(game.music.stream.resource_path.ends_with("desktop_theme.wav") and game.music.stream.get_length() == 48,"melodic track replaces table hum")
 game.run.store.data.music_volume = 0; game.apply_settings(); await frames(2)
 check(not game.music.playing,"zero music volume stops playback")
 game.run.store.data.music_volume = .65; game.apply_settings(); check(game.music.playing,"restoring volume resumes melody")
 await screenshot("menu"); await command("new"); await command("start")
 check(game.screen == "intro" and game.run.data.deck.size() == 6,"new game starts with story and six-card deck")
 for stage in range(4):
  await create_timer(2.7).timeout; await frames(4)
  check(game.run.data.intro == stage and game.world.stage_models.has("core"),"animated story chapter "+str(stage))
  if stage == 2: check(game.world.stage_models.core.position.distance_to(game.world.stage_models.core_home) > .3,"core moves toward thieves")
  await screenshot("story%d" % stage); await command("intro")
 check(game.screen == "battle" and game.run.battle.data.get("tutorial",false),"story leads to training before map")
 check(game.run.battle.data.hand.size() == 1 and game.run.battle.data.energy == 1,"first lesson has one card and one energy")
 await screenshot("training0"); await tap(hand_rect(0).get_center())
 check(game.selected == 0,"mouse selects training card")
 await tap(game.world.slot_point("friendly",1))
 check(game.run.battle.data.friendly[1] != null and game.run.battle.data.energy == 0 and game.run.battle.data.tutorial_step == 1,"mouse deploys into taught lane")
 await command("turn"); await wait_player()
 check(game.run.battle.data.hand.size() == 1 and game.run.battle.data.hand[0].id == "reactor" and game.run.battle.data.energy == 2,"next lesson introduces one reactor")
 await screenshot("training3")
 var from = hand_rect(0).get_center(); var target = game.world.slot_point("friendly",3)
 await mouse(from,true)
 for i in range(1,7): await move(from.lerp(target,i/6.0))
 await mouse(target,false); await frames(5)
 check(game.run.battle.data.friendly[3] != null and game.run.battle.data.energy == 0,"reactor drag charged once")
 await command("turn"); await wait_player()
 check(game.run.battle.data.energy == 3 and game.run.battle.data.max_energy == 3,"bonus energy reads 3/3")
 await screenshot("training5"); await command("turn"); await wait_player(); await frames(12)
 check(game.screen == "map" and game.run.data.battles == 0 and game.run.data.core == 20,"training does not consume an encounter")
 check(game.world.map_nodes.size() == 17 and game.world.diorama != null,"physical route retained")
 await screenshot("map")
 var before = JSON.stringify(game.run.data)
 await tap(game.world.map_nodes["6_1"].point)
 check(game.selected_node == "" and JSON.stringify(game.run.data) == before,"future boss stays locked")
 game.toast_clock = 0
 await command("overview"); await screenshot("overview"); await command("overview_back")
 await tap(game.world.map_nodes["0_1"].point)
 check(game.selected_node == "0_1" and JSON.stringify(game.run.data) == before,"preview leaves save unchanged")
 await screenshot("map-selected"); await command("depart"); await create_timer(1.1).timeout; await frames(15)
 check(game.screen == "battle" and game.run.battle.data.hand.size() == 3 and game.run.battle.data.energy == 2,"ordinary encounter has restrained start")
 check(game.world.slot_point("friendly",0).y-game.world.slot_point("enemy",0).y >= 280,"one empty row separates armies")
 await screenshot("battle")
 var pulse = -1
 for i in range(game.run.battle.data.hand.size()):
  if game.run.battle.data.hand[i].id == "pulse": pulse = i; break
 await tap(hand_rect(pulse).get_center()); await tap(game.world.slot_point("friendly",0)); await frames(15)
 await tap(game.world.slot_point("friendly",0)); await command("order","guard")
 check(game.run.battle.data.friendly[0].temporary == 2 and game.run.battle.data.energy == 0,"guard spends competing energy")
 var repeat = false
 for item in game.view.buttons:
  if item.command == "order": repeat = true
 check(not repeat,"second order is disabled")
 await screenshot("order")
 var hand = hand_rect(0).get_center(); var payload = JSON.stringify(game.run.data)
 await move(hand); await mouse(hand,true,MOUSE_BUTTON_RIGHT); await mouse(hand,false,MOUSE_BUTTON_RIGHT)
 check(game.screen == "inspect" and JSON.stringify(game.run.data) == payload,"right-click inspection spends no resources")
 var zoom = game.inspector_zoom
 await mouse(Vector2(700,430),true,MOUSE_BUTTON_WHEEL_UP); check(game.inspector_zoom > zoom,"wheel zooms inspected card")
 await screenshot("inspector"); await key(KEY_ESCAPE); check(game.screen == "battle","Esc returns to combat")
 await command("turn"); await command("pause")
 check(game.run.battle.data.phase == "resolving" and not game.run.battle.data.pending.is_empty(),"pause checkpoints pending combat")
 var restored = AstraRun.new(); restored.path = game.run.path; restored.meta_path = game.run.meta_path; restored.load_all()
 check(restored.battle.data.pending == game.run.battle.data.pending,"queued attacks survive reload")
 await command("resume"); await wait_player(); restored.battle.resolve_all()
 check(JSON.stringify(restored.battle.checkpoint()) == JSON.stringify(game.run.battle.checkpoint()),"resume preserves tactical shield expiry and RNG")
 await key(KEY_F5); check(game.toast == "saved","F5 provides explicit save"); game.toast_clock = 0
 game.set_process(false)
 var ai = load("res://tests/cards/journey.gd")
 for i in range(50):
  if game.run.battle.data.phase in ["won","lost"]: break
  ai.play_turn(game.run.battle); game.run.battle.end_turn(); game.run.battle.resolve_all()
 check(game.run.battle.data.phase == "won","first encounter winnable with ordinary rules")
 game.run.finish_battle(); game.set_screen(game.run.data.state); game.set_process(true); await frames(15)
 check(game.screen == "reward","victory offers real rewards")
 await screenshot("reward"); await command("reward",-1)
 await command("pause"); await command("settings"); await command("language","de")
 var scale_before = game.run.store.data.ui_scale
 await key(KEY_EQUAL,true); check(game.run.store.data.ui_scale > scale_before,"Ctrl+ enlarges text")
 await command("fullscreen"); check(game.run.store.data.fullscreen,"fullscreen setting persisted"); await command("fullscreen")
 await screenshot("settings-de"); await command("back"); await command("resume")
 game.run.store.data.language = "ru"; game.run.store.data.ui_scale = 1.25
 for act in range(5):
  game.run.data.act = act; game.run.data.state = "map"; game.run.build_map(); game.set_screen("map"); await frames(12)
  check(game.world.diorama.tokens.size() == 17,"world diorama "+str(act)); await screenshot("map-world-%d" % act)
 for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(1024,576)]:
  root.size = resolution; await frames(15)
  for item in game.world.map_nodes.values():
   check(game.world.route_point(item.node).distance_to(item.point) < .5 and Rect2(380,95,820,765).has_point(item.point),"map picking at "+str(resolution)+" / "+item.node.id)
  for side in ["enemy","friendly"]:
   for lane in range(4):
    var point = game.world.slot_point(side,lane)
    check(game.world.project(game.world.position_for(point)).distance_to(point) < .5,"projection at "+str(resolution)+side+str(lane))
 root.size = Vector2i(1280,720)
 game.run.data.act = 0; game.run.battle.begin(game.run.data.deck,20,0,"battle",41293); game.run.data.state = "battle"; game.set_screen("battle")
 game.run.battle.draw_cards(100); await frames(20)
 check(game.run.battle.data.hand.size() == 5,"stress hand stops at five cards")
 var rects: Array = []
 for card in game.view.card_hits:
  if card.hand >= 0: rects.append(card.rect)
 var overlap = false
 for i in range(rects.size()):
  for j in range(i+1,rects.size()):
   if rects[i].intersects(rects[j]): overlap = true
 check(not overlap and rects.size() == 5,"five cards have no overlapping faces")
 for lang in ["ru","en","de"]:
  game.run.store.data.language = lang; game.hovered.clear(); game.hovered_entry.clear(); game.selected = -1; game.selected_bot = -1; await frames(4)
  check(game.view.preview_bottom < 651,"large-text preview fits in "+lang)
 game.run.store.data.language = "ru"; await frames(4)
 await screenshot("battle-five-cards"); await move(hand_rect(0).get_center()); await key(KEY_E)
 check(game.screen == "inspect","E inspects hovered card")
 await screenshot("inspector-large-text"); await key(KEY_ESCAPE)
 await command("pause"); await screenshot("pause"); await command("menu"); await screenshot("menu-final")
 game.set_process(false)
 for lang in ["ru","en","de"]:
  game.run.store.data.language = lang
  for stage in range(4):
   game.run.data.intro = stage; game.set_screen("intro"); await frames(4)
   check(game.view.intro_bottom < 887,"large-text story fits: "+lang+str(stage))
 for path in [game.run.path,game.run.meta_path,game.run.store.settings_path]:
  for suffix in ["",".bak",".tmp"]:
   if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
 print("DESKTOP GRAPHICS: ",checks," checks, ",failures," failures")
 await game.quit_game(0 if failures == 0 else 1)

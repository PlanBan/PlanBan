extends AstraTableUI
class_name AstraDesktopUI
## Wide desktop layout. Card hit boxes and visible cards share the same rectangles.
var card_hits: Array = []
var portraits: Dictionary = {}
var large_face: AstraCardFace
var face_signature = ""
var preview_bottom = 0.0
var intro_bottom = 0.0
const BOARD_X = 230.0
const LANE_STEP = 250.0
func _ready() -> void:
 size = Vector2(1600,900); mouse_filter = Control.MOUSE_FILTER_IGNORE
 large_face = AstraCardFace.new(); large_face.card = AstraCards.card("pulse")
 large_face.mouse_filter = Control.MOUSE_FILTER_IGNORE; large_face.visible = false; add_child(large_face)
func _process(_delta: float) -> void:
 large_face.visible = game.screen == "inspect"
 if large_face.visible:
  var signature = JSON.stringify(game.inspect_entry)+game.language()
  if signature != face_signature:
   face_signature = signature; large_face.card = game.inspect_entry.duplicate(true); large_face.language = game.language()
   large_face.hostile = game.inspect_entry.get("cost",1) == 0 and game.inspect_entry.id in AstraCards.ENEMIES
   var path = "res://assets3d/roles/portraits/%s.png" % game.inspect_entry.art
   if not ResourceLoader.exists(path): path = "res://assets3d/tabletop/portraits/%s.png" % game.inspect_entry.art
   large_face.art = load(path) if ResourceLoader.exists(path) else load("res://assets3d/icons/%s.png" % game.inspect_entry.art)
   large_face.queue_redraw()
  var zoom = 1.38*game.inspector_zoom
  large_face.scale = Vector2.ONE*zoom; large_face.position = Vector2(575,455)-Vector2(300,430)*zoom/2
func text_scale() -> float:
 return float(game.run.store.data.get("ui_scale",1.0))
func label(value: String, point: Vector2, size_value: int = 24, color: Color = INK, width: float = 640, centered: bool = false) -> void:
 var fitted = int(size_value*text_scale())
 while font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted).x > width and fitted > 18: fitted -= 1
 var pos = point
 if centered: pos.x -= font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted).x/2
 draw_string(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,width,fitted,color)
func words(value: String, point: Vector2, width: float = 592, size_value: int = 25, color: Color = DIM) -> float:
 var row = ""; var y = point.y; var fitted = int(size_value*text_scale())
 for word in value.split(" "):
  if row != "" and font.get_string_size(row+" "+word,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted).x > width:
   draw_string(font,Vector2(point.x,y),row,HORIZONTAL_ALIGNMENT_LEFT,width,fitted,color); y += fitted*1.35; row = word
  else: row = (row+" "+word).strip_edges()
 if row != "": draw_string(font,Vector2(point.x,y),row,HORIZONTAL_ALIGNMENT_LEFT,width,fitted,color)
 return y+fitted*1.35
func title(key: String, sub: String = "") -> void:
 frame(Rect2(30,24,1540,110),CYAN,.92)
 label(game.l(key),Vector2(58,74),36,INK,1240)
 if sub != "": label(sub,Vector2(60,111),23,DIM,1300)
func health_bar(rect: Rect2, name: String, current: int, maximum: int, color: Color = AstraRoles.HP) -> void:
 var energy = name == game.l("energy")
 var accent = Color("72edc4") if energy else AstraRoles.HP
 var fraction = clampf(float(current)/maxi(1,maximum),0,1)
 if not energy and fraction <= .25: accent = accent.lerp(AstraRoles.ATTACK,.35+.2*sin(game.clock*4))
 frame(rect,accent,.96)
 var icon = rect.position+Vector2(26,25)
 if energy:
  draw_colored_polygon(PackedVector2Array([icon+Vector2(3,-12),icon+Vector2(-8,2),icon,icon+Vector2(-3,12),icon+Vector2(9,-2),icon+Vector2(1,-2)]),accent)
 else:
  draw_circle(icon+Vector2(-4,-3),5,accent); draw_circle(icon+Vector2(4,-3),5,accent)
  draw_colored_polygon(PackedVector2Array([icon+Vector2(-9,-1),icon+Vector2(9,-1),icon+Vector2(0,10)]),accent)
 var value = "%d / %d" % [current,maximum]
 var value_size = 24 if rect.size.x < 400 else 27
 var value_width = font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,int(value_size*text_scale())).x
 label(name,rect.position+Vector2(45,31),22,accent,rect.size.x-value_width-79)
 label(value,Vector2(rect.end.x-18-value_width,rect.position.y+31),value_size,accent,value_width+1)
 var divisions = 10 if not energy else maximum
 var width = (rect.size.x-36-3*(divisions-1))/divisions
 for i in range(divisions):
  var track = Rect2(rect.position+Vector2(18+i*(width+3),44),Vector2(width,9))
  draw_rect(track,Color("183443"))
  var fill = clampf(fraction*divisions-i,0,1)
  draw_rect(Rect2(track.position,Vector2(width*fill,9)),accent)
func rival_art(act: int, rect: Rect2) -> void:
 var path = "res://assets3d/commanders/portraits/world_%d.png" % act
 if not portraits.has(path): portraits[path] = load(path)
 draw_texture_rect(portraits[path],rect,false)
func combat_stats(entry: Dictionary, point: Vector2, width: float, size_value: int = 25) -> void:
 label("%s %d" % [game.l("attack_short"),entry.attack],point,size_value,AstraRoles.ATTACK,width*.43)
 label("HP %d / %d" % [entry.hp,entry.get("max_hp",entry.hp)],point+Vector2(width*.47,0),size_value,AstraRoles.HP,width*.53)
func challenge() -> void:
 var battle = game.run.battle.data; var act = int(battle.act)
 frame(Rect2(42,30,1516,108),AstraRoles.ATTACK,.96)
 label(game.l("opponent_title"),Vector2(72,75),26,AstraRoles.ATTACK,500)
 label(AstraRivals.name_for(act,game.language()),Vector2(72,116),33,INK,950)
 frame(Rect2(837,230,687,390),AstraRoles.ATTACK,.97)
 label(AstraCards.word(AstraRivals.TITLES[act],game.language()),Vector2(869,280),25,AstraRoles.DEFENCE,615)
 words(AstraRivals.line_for(battle,game.language()),Vector2(869,341),610,29,INK)
 health_bar(Rect2(869,510,617,74),game.l("enemy_core"),battle.enemy_core,battle.max_enemy_core)
 button(Rect2(915,680,540,87),game.l("fight"),"fight",0,true,game.world.stage_clock>=1.2)
 button(Rect2(60,773,276,62),game.l("pause"),"pause")
 label(game.l("fight_hint"),Vector2(869,835),21,DIM,625)
func research() -> void:
 title("research",game.l("research_tip"))
 label(game.l("scrap")+": %d" % int(game.run.data.credits),Vector2(1450,84),29,AstraRoles.DEFENCE,235,true)
 var owned = game.run.data.get("research",AstraResearch.defaults())
 for branch_index in range(4):
  var branch: String = AstraResearch.BRANCHES[branch_index]; var level = int(owned.get(branch,0)); var x = 34+branch_index*391; var color = AstraResearch.COLORS[branch_index]
  label(game.l("branch_"+branch),Vector2(x+176,188),29,color,346,true)
  for rank in range(3):
   var y = 214+rank*187; var rect = Rect2(x,y,367,155)
   var purchased = rank<level; var unlocked = rank==level and int(game.run.data.act)>=rank
   if rank>0: draw_line(Vector2(x+183,y-29),Vector2(x+183,y),color if rank<=level else DIM,3)
   frame(rect,color,.97,purchased)
   label("%02d · %s" % [rank+1,AstraCards.word(AstraResearch.NAMES[branch_index][rank],game.language())],rect.position+Vector2(17,33),24,color,331)
   words(AstraCards.word(AstraResearch.EFFECTS[branch_index][rank],game.language()),rect.position+Vector2(17,68),327,21,INK)
   var caption = game.l("researched") if purchased else (game.l("research_buy")+" · %d" % AstraResearch.COSTS[rank] if unlocked else game.l("research_act") % (rank+1))
   button(Rect2(x+13,y+110,341,38),caption,"buy_research",branch+":"+str(rank),false,unlocked and game.run.data.credits>=AstraResearch.COSTS[rank])
 button(Rect2(565,803,470,66),game.l("back"),"back",0,true)
func art(entry: Dictionary, rect: Rect2) -> void:
 var key: String = entry.art
 if not portraits.has(key):
  var path = "res://assets3d/roles/portraits/%s.png" % key
  if not ResourceLoader.exists(path): path = "res://assets3d/tabletop/portraits/%s.png" % key
  portraits[key] = load(path) if ResourceLoader.exists(path) else load("res://assets3d/icons/%s.png" % key)
 if portraits[key] != null: draw_texture_rect(portraits[key],rect,false)
func hit_card(entry: Dictionary, rect: Rect2, side: String, index: int, hand: int = -1) -> void:
 card_hits.append({"entry":entry,"rect":rect,"side":side,"lane":index,"hand":hand,"key":("e" if side == "enemy" else "c")+str(entry.get("uid",index))})
func pick_card(point: Vector2) -> Dictionary:
 for i in range(card_hits.size()-1,-1,-1):
  if card_hits[i].rect.has_point(point): return card_hits[i]
 return {}
func compact_card(entry: Dictionary, rect: Rect2, side: String, index: int, hand: int = -1) -> void:
 var selected = hand == game.selected and hand >= 0
 frame(rect,AstraRoles.color(entry),.98,selected)
 words(AstraCards.word(entry.name,game.language()),rect.position+Vector2(13,23),rect.size.x-50,19,INK)
 draw_circle(rect.position+Vector2(rect.size.x-25,26),16,CYAN)
 label(str(entry.cost),rect.position+Vector2(rect.size.x-25,33),22,Color("09202b"),28,true)
 art(entry,Rect2(rect.position+Vector2(28,49),Vector2(rect.size.x-56,80)))
 if entry.hp > 0:
  combat_stats(entry,rect.position+Vector2(13,150),rect.size.x-26,21)
 else: label(game.l("action"),rect.position+Vector2(13,150),21,CYAN,rect.size.x-26)
 label(game.l("card_key") % (hand%5+1) if hand >= 0 else game.l("inspect_short"),rect.position+Vector2(13,178),18,DIM,rect.size.x-26)
 hit_card(entry,rect,side,index,hand)
func menu() -> void:
 frame(Rect2(46,48,620,785),CYAN,.94)
 label("ORBITAL FRONT",Vector2(78,127),49,CYAN,550)
 words(game.l("desktop_subtitle"),Vector2(80,184),540,29,INK)
 words(game.l("desktop_hint"),Vector2(80,288),540,24)
 for i in range(5):
  var keys = ["continue","new","collection","settings","quit"]
  button(Rect2(80,390+i*79,545,62),game.l(keys[i]),keys[i],0,i < 2,i != 0 or game.run.resume_available())
 label("RU / EN / DE   ·   DESKTOP / 4.3",Vector2(80,804),21,DIM,540)
func new_run() -> void:
 title("choose_deck",game.l("small_start"))
 var keys = ["scout","citadel","engineer"]
 for i in range(3):
  var rect = Rect2(90+i*500,205,430,310)
  frame(rect,CYAN,.94,game.deck_kind == i)
  label(game.l(keys[i]),rect.position+Vector2(28,55),33,CYAN,365)
  var ids = AstraCards.starter(i)
  var y = rect.position.y+100
  for id in [ids[0],ids[2],ids[3]]:
   label(AstraCards.word(AstraCards.CARDS[id].name,game.language()),Vector2(rect.position.x+28,y),25,INK,365); y += 43
  button(Rect2(rect.position+Vector2(25,242),Vector2(380,58)),game.l("select_deck"),"deck_kind",i,game.deck_kind == i,i in game.run.meta.decks)
 if game.run.resume_available(): words(game.l("replace"),Vector2(105,595),1330,25,AMBER)
 button(Rect2(450,720,550,75),game.l("confirm"),"start",0,true)
 button(Rect2(1060,730,330,65),game.l("cancel"),"menu")
func intro() -> void:
 var stage = mini(3,int(game.run.data.intro))
 frame(Rect2(42,35,910,100),CYAN,.92)
 label(game.l("story_title%d" % stage),Vector2(70,96),38,CYAN,850)
 frame(Rect2(45,590,1510,273),CYAN,.96)
 label(game.l("speaker%d" % stage),Vector2(74,630),25,AMBER,800)
 intro_bottom = words(game.l("story_text%d" % stage),Vector2(74,676),1070,27,INK)
 button(Rect2(1185,737,330,80),game.l("training" if stage == 3 else ("retreat" if stage == 1 else "next")),"intro",0,true,game.world.stage_clock >= 2.5)
 button(Rect2(1260,40,295,60),game.l("skip_story"),"skip_story")
 for i in range(4): draw_circle(Vector2(1110+i*25,680),5,CYAN if i == stage else DIM)
func route() -> void:
 var data = game.run.data; var act = int(data.act)
 frame(Rect2(25,26,345,830),CYAN,.94)
 label(game.l(AstraCards.PLANETS[act]).to_upper(),Vector2(52,85),38,CYAN,293)
 words(game.l("location%d" % act),Vector2(52,132),290,26,INK)
 label("%d / 5" % (act+1),Vector2(53,222),45,CYAN,290)
 words(game.l("route_desktop"),Vector2(53,291),290,21)
 button(Rect2(48,397,77,36),"−","map_zoom",-.05)
 label("%d%%" % int(game.run.store.data.map_zoom*100),Vector2(195,424),22,DIM,115,true)
 button(Rect2(270,397,77,36),"+","map_zoom",.05)
 health_bar(Rect2(46,449,301,68),game.l("your_core"),int(data.core),int(data.max_core))
 label(game.l("scrap")+": "+str(data.credits),Vector2(53,568),29,AMBER,290)
 button(Rect2(48,634,296,62),game.l("deck")+" · %d" % data.deck.size(),"deck")
 button(Rect2(48,703,296,53),game.l("research"),"research")
 button(Rect2(48,769,296,45),game.l("planet_map"),"overview")
 button(Rect2(48,826,296,30),game.l("pause"),"pause")
 frame(Rect2(1210,27,365,827),CYAN,.94)
 label(game.l("world_unlock"),Vector2(1236,76),27,CYAN,315)
 var special = AstraCards.card(["verdant","frost","ember","storm","echo"][act])
 art(special,Rect2(1253,111,275,241))
 label(AstraCards.word(special.name,game.language()),Vector2(1237,390),30,INK,310)
 words(game.l("after_archon"),Vector2(1237,442),305,25)
 var kind = game.world.map_nodes.get(game.selected_node,{}).get("node",{}).get("kind","")
 words(AstraCards.word(AstraCards.NODE_NAMES[kind],game.language()) if kind != "" else game.l("select_node"),Vector2(1237,554),305,28,INK)
 button(Rect2(1234,724,319,87),game.l("depart")+"  ›","depart",0,true,game.selected_node in game.run.available_nodes() and game.route_travel <= 0)
func overview() -> void:
 title("planet_map",game.l("route_future"))
 for i in range(5):
  var x = 40+i*310; var color = AstraCards.COLORS[i]
  frame(Rect2(x,230,285,405),color,.97,i == game.run.data.act)
  label(str(i+1),Vector2(x+28,290),44,color,210)
  label(game.l(AstraCards.PLANETS[i]),Vector2(x+28,355),31,color,240)
  words(game.l("location%d" % i),Vector2(x+28,408),225,25,INK)
  words(game.l("world_done" if i < game.run.data.act else ("world_current" if i == game.run.data.act else "world_future")),Vector2(x+28,550),225,23)
 button(Rect2(585,748,430,75),game.l("back"),"overview_back",0,true)
func preview_panel() -> void:
 frame(Rect2(1170,106,400,558),CYAN,.96)
 var entry: Dictionary = game.hovered_entry
 if game.hovered.is_empty() and game.selected >= 0 and game.selected < game.run.battle.data.hand.size():
  var raw = game.run.battle.data.hand[game.selected]; entry = game.run.battle.instance(raw)
 elif game.hovered.is_empty() and game.selected_bot >= 0 and game.run.battle.data.friendly[game.selected_bot] != null: entry = game.run.battle.data.friendly[game.selected_bot]
 if entry.is_empty():
  var battle = game.run.battle.data
  if battle.get("tutorial",false):
   var y = words(game.l("preview_hint"),Vector2(1200,163),340,25,INK)
   preview_bottom = words(game.l("training_rule"),Vector2(1200,y+35),340,24)
  else:
   label(AstraRivals.name_for(int(battle.act),game.language()),Vector2(1198,150),28,AstraRoles.ATTACK,345)
   rival_art(int(battle.act),Rect2(1223,170,293,229))
   health_bar(Rect2(1190,407,354,65),game.l("core"),battle.enemy_core,battle.max_enemy_core)
   preview_bottom = words(game.l("enemy_console_hint"),Vector2(1200,506),335,22,DIM)
  return
 label(AstraCards.word(entry.name,game.language()),Vector2(1198,150),30,CYAN,345)
 art(entry,Rect2(1234,176,276,172))
 label(game.l("energy")+": "+str(entry.cost),Vector2(1200,384),26,INK,340)
 if entry.hp > 0: combat_stats(entry,Vector2(1200,420),340,25)
 if entry.get("armor",0)+entry.get("shield",0)+entry.get("temporary",0)>0: label(game.l("armor")+": %d   %s: %d" % [entry.get("armor",0),game.l("shield_short"),entry.get("shield",0)+entry.get("temporary",0)],Vector2(1200,453),22,AstraRoles.DEFENCE,340)
 preview_bottom = words(AstraCards.description(entry,game.language()),Vector2(1200,487),339,23,INK)
 if game.selected_bot >= 0: label(game.l("orders_short"),Vector2(1200,617),20,DIM,340)
 label(game.l("inspect_key"),Vector2(1200,653),18,DIM,340)
func battle() -> void:
 var data = game.run.battle.data
 frame(Rect2(26,20,1546,80),CYAN,.96)
 label(game.l("training") if data.get("tutorial",false) else game.l(AstraCards.PLANETS[int(data.act)])+" / "+AstraCards.word(AstraCards.NODE_NAMES[data.kind],game.language()),Vector2(53,58),31,INK,980)
 if not data.get("tutorial",false):
  var notice = game.l("mouse_hint")
  if not data.intent.is_empty():
   var incoming: Array[String] = []
   for intent in data.intent:
    incoming.append("[%02d] %s" % [int(intent.lane)+1,AstraCards.word(AstraCards.ENEMIES[intent.id].name,game.language())])
   notice = game.l("reinforcement")+": "+", ".join(incoming)
  label(notice,Vector2(55,88),18,AMBER if not data.intent.is_empty() else DIM,1060)
 label(game.l("turn")+" %02d" % int(data.turn),Vector2(1188,66),29,CYAN,210)
 button(Rect2(1410,28,142,52),game.l("pause"),"pause")
 health_bar(Rect2(52,106,1085,62),game.l("enemy_core"),int(data.enemy_core),int(data.max_enemy_core),RED)
 for lane in range(4):
  var center = Vector2(BOARD_X+lane*LANE_STEP,402)
  var gap = Rect2(center-Vector2(102,62),Vector2(204,124))
  frame(gap,Color("345763"),.28)
  label("%02d" % (lane+1),center+Vector2(0,13),24,DIM,70,true)
 label(game.l("neutral_zone"),Vector2(605,378),20,DIM,760,true)
 for side in ["enemy","friendly"]:
  for lane in range(4):
   var point = game.world.slot_point(side,lane)
   var rect = Rect2(point-Vector2(103,72),Vector2(206,144))
   var bot: Variant = data[side][lane]
   if bot == null:
    if side == "friendly": label("+",point+Vector2(0,12),38,CYAN if game.selected >= 0 else DIM,90,true)
    continue
   var color = RED if side == "enemy" else CYAN
   frame(Rect2(point+Vector2(-103,-72),Vector2(206,30)),color,.95)
   label(AstraCards.word(bot.name,game.language()),point+Vector2(0,-49),19,color,190,true)
   frame(Rect2(point+Vector2(-103,25),Vector2(206,51)),color,.96,side == "friendly" and lane == game.selected_bot)
   label("%s %d%s" % [game.l("attack_short"),bot.attack," +1" if bot.get("focus",0) > 0 else ""],point+Vector2(-89,50),22,AstraRoles.ATTACK,100)
   label("HP %d / %d" % [bot.hp,bot.max_hp],point+Vector2(12,50),22,AstraRoles.HP,85)
   var hp_width = 180*clampf(float(bot.hp)/maxi(1,bot.max_hp),0,1)
   draw_rect(Rect2(point+Vector2(-90,61),Vector2(180,5)),Color("29404b")); draw_rect(Rect2(point+Vector2(-90,61),Vector2(hp_width,5)),AstraRoles.HP)
   if bot.get("armor",0)+bot.shield+bot.temporary > 0:
    frame(Rect2(point+Vector2(-101,-33),Vector2(78,28)),AstraRoles.DEFENCE,.98)
    label("◇ %d · %d" % [bot.get("armor",0),bot.shield+bot.temporary],point+Vector2(-94,-12),18,AstraRoles.DEFENCE,67)
   if bot.frozen > 0 or bot.jammed > 0 or bot.burn > 0: label(game.l("status"),point+Vector2(-93,18),20,AMBER,185)
   hit_card(bot,rect,side,lane)
 health_bar(Rect2(52,626,610,64),game.l("your_core"),int(data.core),int(data.max_core))
 health_bar(Rect2(686,626,451,64),game.l("energy"),int(data.energy),maxi(data.max_energy,data.energy))
 var hand = data.hand; var pages = maxi(1,int(ceil(hand.size()/5.0)))
 game.hand_page = clampi(game.hand_page,0,pages-1)
 for index in range(game.hand_page*5,mini(hand.size(),(game.hand_page+1)*5)):
  var raw = hand[index]; var entry = game.run.battle.instance(raw); entry.uid = raw.uid
  var count = mini(5,hand.size()-game.hand_page*5)
  var x = 597-count*211/2.0+(index%5)*211
  compact_card(entry,Rect2(x,707,197,183),"hand",-1,index)
 if pages > 1:
  button(Rect2(1173,703,85,48),"←","hand_page",-1,false,game.hand_page > 0)
  button(Rect2(1478,703,85,48),"→","hand_page",1,false,game.hand_page < pages-1)
 preview_panel()
 if game.selected_bot >= 0 and data.friendly[game.selected_bot] != null and not data.get("tutorial",false):
  var available = data.phase == "player" and data.energy > 0 and data.friendly[game.selected_bot].get("ordered_turn",-1) != data.turn
  button(Rect2(1186,680,177,58),game.l("aim"),"order","aim",false,available and data.friendly[game.selected_bot].attack > 0 and data.friendly[game.selected_bot].frozen == 0)
  button(Rect2(1376,680,177,58),game.l("guard"),"order","guard",false,available)
 elif game.selected >= 0 and game.selected < hand.size() and AstraCards.CARDS[hand[game.selected].id].get("target","") == "all":
  button(Rect2(1186,680,367,58),game.l("confirm_play"),"cast",0,true,data.phase == "player" and (hand[game.selected].id != "core_repair" or data.core<data.max_core))
 if data.get("tutorial",false):
  frame(Rect2(49,345,1087,121),CYAN,.98,true)
  words(game.l("lesson%d" % int(data.tutorial_step)),Vector2(71,380),1040,24,INK)
  button(Rect2(1190,753,361,42),game.l("skip_training"),"skip_training")
 var can_end = data.phase == "player" and game.lock_clock <= 0 and (not data.get("tutorial",false) or data.tutorial_step not in [0,3])
 button(Rect2(1186,809,369,72),game.l("end_turn" if data.phase == "player" else "resolving"),"turn",0,true,can_end)
func reward() -> void:
 title("reward",game.l("choose_reward"))
 for i in range(game.run.data.reward.size()): offer_card(game.run.data.reward[i],i,"reward")
 button(Rect2(595,767,410,68),game.l("skip"),"reward",-1)
func offer_card(id: String, index: int, side: String) -> void:
 if id == "": return
 var entry = AstraCards.card(id); entry.uid = 9000+index
 var rect = Rect2(200+index*440,194,355,500)
 frame(rect,CYAN,.98)
 label(AstraCards.word(entry.name,game.language()),rect.position+Vector2(24,44),30,CYAN,306)
 art(entry,Rect2(rect.position+Vector2(30,76),Vector2(295,210)))
 label(game.l("energy")+": "+str(entry.cost),rect.position+Vector2(24,323),26,INK,306)
 if entry.hp > 0: combat_stats(entry,rect.position+Vector2(24,365),306,26)
 words(AstraCards.description(entry,game.language()),rect.position+Vector2(24,410),300,25,INK)
 hit_card(entry,rect,side,index)
func shop() -> void:
 title("shop",game.l("scrap")+": "+str(game.run.data.credits))
 for i in range(game.run.data.stock.size()):
  var id = game.run.data.stock[i]
  if id == "": continue
  offer_card(id,i,"shop")
  var price = 20+int(AstraCards.CARDS[id].rarity)*8
  button(Rect2(200+i*440,702,355,53),game.l("scrap")+": "+str(price),"buy",i,true,game.run.data.credits >= price)
 button(Rect2(555,791,490,62),game.l("leave"),"leave")
func browse() -> void:
 var screen = game.screen
 title("collection" if screen == "collection" else ("deck" if screen == "deck" else screen),game.l(screen+"_tip") if screen in ["upgrade","remove"] else game.l("inspect_key"))
 var entries = game.display_entries()
 for i in range(mini(6,entries.size()-game.page*6)):
  var raw = entries[game.page*6+i]; var entry = AstraCards.card(raw.id,int(raw.get("upgrade",0))); entry.uid = raw.uid
  compact_card(entry,Rect2(355+(i%3)*320,195+int(i/3)*244,270,204),"browse",game.page*6+i)
 button(Rect2(210,695,140,64),"←","page",-1,false,game.page > 0)
 button(Rect2(1250,695,140,64),"→","page",1,false,(game.page+1)*6 < entries.size())
 label("%d / %d" % [game.page+1,maxi(1,int(ceil(entries.size()/6.0)))],Vector2(800,738),29,INK,300,true)
 button(Rect2(550,791,500,65),game.l("leave" if screen in ["upgrade","remove"] else "back"),"leave" if screen in ["upgrade","remove"] else "back")
 if screen == "upgrade": button(Rect2(60,280,260,62),game.l("research"),"research")
 if screen == "collection": button(Rect2(60,185,260,62),game.l("records"),"records")
func event_screen() -> void:
 title("event",game.l(AstraCards.PLANETS[int(game.run.data.act)]))
 frame(Rect2(270,220,1060,360),CYAN,.98)
 words(game.l("event%d" % int(game.run.data.act)),Vector2(308,286),980,32,INK)
 button(Rect2(270,642,495,87),game.l("salvage"),"event",0)
 button(Rect2(805,642,525,87),game.l("risk"),"event",1,true,game.run.data.core > 3)
func simple_screen(key: String, text: String, command: String, button_key: String) -> void:
 title(key)
 frame(Rect2(200,230,1200,350),CYAN,.98)
 words(game.l(text),Vector2(240,310),1120,31,INK)
 if key == "rest": label("HP %d → %d" % [game.run.data.core,mini(game.run.data.max_core,game.run.data.core+7)],Vector2(240,513),38,CYAN,1060)
 button(Rect2(530,703,540,87),game.l(button_key),command,0,true)
func settings() -> void:
 title("settings",game.l("desktop_hint"))
 frame(Rect2(235,155,1130,690),CYAN,.98)
 label(game.l("language"),Vector2(275,214),27,INK,230)
 for i in range(3): button(Rect2(530+i*225,171,205,60),["РУССКИЙ","ENGLISH","DEUTSCH"][i],"language",["ru","en","de"][i],game.language() == ["ru","en","de"][i])
 var keys = ["master_volume","music_volume","effects_volume"]
 for i in range(3):
  var y = 291+i*112; var fraction = float(game.run.store.data[keys[i]])
  label(game.l(["volume","music","effects"][i]),Vector2(275,y+9),25,INK,240)
  draw_line(Vector2(530,y),Vector2(1180,y),Color("3b5965"),8)
  draw_line(Vector2(530,y),Vector2(530+650*fraction,y),CYAN,8)
  draw_circle(Vector2(530+650*fraction,y),15,INK)
  buttons.append({"rect":Rect2(510,y-27,695,54),"command":"slider","value":keys[i]})
  label("%d%%" % int(fraction*100),Vector2(1253,y+10),24,INK,90,true)
 button(Rect2(275,585,410,64),game.l("fullscreen"),"fullscreen",0,game.run.store.data.fullscreen)
 button(Rect2(732,585,85,64),"−","ui_scale",-.05)
 label(game.l("text_size")+" %d%%" % int(text_scale()*100),Vector2(1000,628),25,INK,340,true)
 button(Rect2(1200,585,85,64),"+","ui_scale",.05)
 words(game.l("audio_note"),Vector2(278,702),1000,24)
 button(Rect2(602,764,395,61),game.l("back"),"back",0,true)
func pause() -> void:
 draw_rect(Rect2(0,0,1600,900),Color(.002,.009,.02,.8))
 frame(Rect2(490,110,620,680),CYAN,.99)
 label(game.l("paused"),Vector2(800,182),34,CYAN,550,true)
 var keys = ["continue","save","settings","menu","quit"]
 for i in range(keys.size()): button(Rect2(535,240+i*97,530,67),game.l(keys[i]),"resume" if i == 0 else keys[i],0,i < 2)
func inspector() -> void:
 draw_rect(Rect2(0,0,1600,900),Color(.002,.009,.02,.94))
 frame(Rect2(270,47,1290,803),CYAN,.98)
 var entry = game.inspect_entry
 label(AstraCards.word(entry.name,game.language()),Vector2(914,153),37,CYAN,584)
 label(game.l("energy")+": "+str(entry.cost),Vector2(914,235),32,INK,570)
 if entry.hp > 0: combat_stats(entry,Vector2(914,290),570,31)
 if entry.get("armor",0)+entry.get("shield",0)+entry.get("temporary",0)>0: label(game.l("armor")+": %d   %s: %d" % [entry.get("armor",0),game.l("shield_short"),entry.get("shield",0)+entry.get("temporary",0)],Vector2(914,335),26,AstraRoles.DEFENCE,570)
 words(AstraCards.description(entry,game.language()),Vector2(914,382),556,32,INK)
 words(game.l("zoom_hint"),Vector2(914,611),552,24)
 button(Rect2(914,737,565,67),game.l("back"),"inspect_back",0,true)
func records() -> void:
 title("records")
 var logs = game.run.meta.logs
 for i in range(mini(3,logs.size()-game.page*3)):
  var id: String = logs[game.page*3+i]; var rect = Rect2(100+i*485,206,438,482)
  frame(rect,CYAN,.98)
  if id == "legacy": words(game.l("legacy"),rect.position+Vector2(30,55),370,29,INK)
  else:
   var act = int(id.right(1)); label(game.l(AstraCards.PLANETS[act]),rect.position+Vector2(30,55),32,CYAN,370)
   words(game.l("event%d" % act),rect.position+Vector2(30,130),365,27,INK)
 button(Rect2(100,720,140,60),"←","page",-1,false,game.page>0)
 button(Rect2(1360,720,140,60),"→","page",1,false,(game.page+1)*3<logs.size())
 button(Rect2(580,800,440,62),game.l("back"),"inspect_back")
func _draw() -> void:
 if game == null or game.world == null or game.quitting: return
 buttons.clear(); card_hits.clear()
 match game.screen:
  "menu": menu()
  "new": new_run()
  "intro": intro()
  "map": route()
  "overview": overview()
  "battle": battle()
  "challenge": challenge()
  "research": research()
  "pause": pause()
  "reward": reward()
  "shop": shop()
  "deck","collection","upgrade","remove": browse()
  "event","planet": event_screen()
  "rest": simple_screen("rest","rest_text","rest","heal")
  "travel": simple_screen("travel","travel_text","travel","begin")
  "defeat": simple_screen("defeat","defeat_text","new","new")
  "ending": simple_screen("ending","ending_text","menu","menu")
  "settings": settings()
  "inspect": inspector()
  "records": records()
 if game.toast_clock > 0:
  frame(Rect2(460,112,680,81),AMBER,.99)
  words(game.l(game.toast),Vector2(485,146),630,24,INK)
 if game.dragging and game.drag_index >= 0 and game.screen == "battle" and game.drag_index < game.run.battle.data.hand.size():
  var entry = AstraCards.card(game.run.battle.data.hand[game.drag_index].id)
  var rect = Rect2(game.pointer-Vector2(74,75),Vector2(148,150))
  frame(rect,CYAN,.94,true); art(entry,rect.grow(-12))

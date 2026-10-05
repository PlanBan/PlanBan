extends Control
class_name AstraTableUI
## Touch-sized controls and engraved HUD over a real 3D table; all text is RU/EN/DE.
var game: AstraGame
var buttons: Array = []
var font: Font = ThemeDB.fallback_font
const INK = Color("e6edf0")
const DIM = Color("90a8b4")
const CYAN = Color("52e7ff")
const AMBER = Color("dca56a")
const RED = Color("ff8051")
func _ready() -> void:
 size = Vector2(720,1280); mouse_filter = Control.MOUSE_FILTER_IGNORE
func label(value: String, point: Vector2, size_value: int = 24, color: Color = INK, width: float = 640, centered: bool = false) -> void:
 var fitted = size_value
 while font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted).x > width and fitted > 14: fitted -= 1
 var position_value = point
 if centered: position_value.x -= font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted).x/2
 draw_string(font,position_value,value,HORIZONTAL_ALIGNMENT_LEFT,width,fitted,color)
func words(value: String, point: Vector2, width: float = 592, size_value: int = 25, color: Color = DIM) -> float:
 var line = ""; var y = point.y
 for word in value.split(" "):
  if font.get_string_size(line+" "+word,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value).x > width:
   label(line,Vector2(point.x,y),size_value,color,width); y += size_value*1.45; line = word
  else: line = (line+" "+word).strip_edges()
 if line != "": label(line,Vector2(point.x,y),size_value,color,width)
 return y+size_value*1.45
func frame(rect: Rect2, color: Color = CYAN, fill: float = .88, glow: bool = false) -> void:
 var x = rect.position.x; var y = rect.position.y; var w = rect.size.x; var h = rect.size.y; var cut = minf(16,h*.2)
 var points = PackedVector2Array([Vector2(x+cut,y),Vector2(x+w-cut,y),Vector2(x+w,y+cut),Vector2(x+w,y+h-cut),Vector2(x+w-cut,y+h),Vector2(x+cut,y+h),Vector2(x,y+h-cut),Vector2(x,y+cut)])
 draw_colored_polygon(points,Color(.012,.033,.047,fill))
 var edge = points.duplicate(); edge.append(points[0])
 if glow:
  draw_polyline(edge,Color(color,.045),13,true); draw_polyline(edge,Color(color,.12),6,true)
 draw_polyline(edge,Color(color,.8 if glow else .34),2 if glow else 1.2,true)
 draw_line(Vector2(x+cut+9,y+6),Vector2(x+cut+39,y+6),Color(color,.45),1)
 draw_line(Vector2(x+w-cut-9,y+h-6),Vector2(x+w-cut-39,y+h-6),Color(color,.4),1)
 for i in range(3): draw_circle(Vector2(x+w-cut-12-i*6,y+9),1,Color(color,.3))
func button(rect: Rect2, text: String, command: String, value: Variant = 0, accent: bool = false, enabled: bool = true) -> void:
 var color = CYAN if accent else DIM
 if not enabled: color = Color("43545c")
 frame(rect,color,.90,accent and enabled)
 if enabled and game.pressed.get("command","") == command: draw_rect(rect.grow(-6),Color(CYAN,.08))
 label(text,rect.get_center()+Vector2(0,9),25,INK if enabled else Color("6b7b83"),rect.size.x-26,true)
 if enabled: buttons.append({"rect":rect,"command":command,"value":value})
func title(key: String, sub: String = "") -> void:
 frame(Rect2(28,24,664,199 if sub != "" else 134),CYAN,.80)
 label(game.l("table"),Vector2(54,65),17,AMBER,610)
 label(game.l(key),Vector2(54,128),36,INK,610)
 if sub != "": words(sub,Vector2(54,181),605,23)
func footer() -> void:
 if game.run.data.is_empty(): return
 var data: Dictionary = game.run.data
 draw_line(Vector2(54,1130),Vector2(666,1130),Color("6f7965"),1)
 label("♥ %d / 20" % int(data.core),Vector2(56,1168),28,CYAN)
 label("◇ %d" % int(data.credits),Vector2(296,1168),28,AMBER)
 label("▤ %d" % data.deck.size(),Vector2(533,1168),28,INK)
 label(game.l("autosave"),Vector2(360,1232),17,DIM,610,true)
func menu() -> void:
 draw_rect(Rect2(0,0,720,1280),Color(0.006,0.02,0.034,0.40))
 frame(Rect2(33,55,654,267),CYAN,.79)
 label("ORBITAL",Vector2(57,166),67,INK,610)
 label("FRONT",Vector2(54,235),78,CYAN,610)
 label(game.l("subtitle"),Vector2(59,281),20,AMBER,610)
 words(game.l("intro3"),Vector2(60,379),590,24)
 button(Rect2(65,567,590,88),game.l("continue"),"continue",0,true,game.run.resume_available())
 button(Rect2(65,678,590,88),game.l("new"),"new",0,true)
 button(Rect2(65,789,590,80),game.l("collection"),"collection")
 button(Rect2(65,889,590,80),game.l("settings"),"settings")
 button(Rect2(65,989,590,80),game.l("quit"),"quit")
 label("RU / EN / DE    ·    ASTRA DIORAMA / 4.1",Vector2(360,1200),17,DIM,610,true)
func new_run() -> void:
 title("choose_deck")
 var ids = ["scout","citadel","engineer"]
 for i in range(3):
  var enabled = i in game.run.meta.decks
  button(Rect2(65,315+i*139,590,92),game.l(ids[i])+ ("  ●" if game.deck_kind == i else ""),"deck_kind",i,game.deck_kind == i,enabled)
  if not enabled: label(game.l("locked"),Vector2(78,440+i*139),19,DIM,570)
 if game.run.resume_available(): words(game.l("replace"),Vector2(65,851),585,24,AMBER)
 button(Rect2(65,992,590,92),game.l("confirm"),"start",0,true)
 button(Rect2(65,1107,590,78),game.l("cancel"),"menu")
func intro() -> void:
 title("intro1")
 var stage = int(game.run.data.intro)
 words(game.l(["intro2","intro3","intro4"][mini(stage,2)]),Vector2(66,404),583,29,INK)
 for i in range(3): draw_circle(Vector2(326+i*34,922),5,CYAN if i == stage else DIM)
 button(Rect2(65,1003,590,96),game.l("begin" if stage == 2 else "next"),"intro",0,true)
func route() -> void:
 var data: Dictionary = game.run.data
 var act = int(data.act)
 frame(Rect2(25,25,470,220),CYAN,.70)
 label(game.l(AstraCards.PLANETS[act]).to_upper(),Vector2(48,69),32,CYAN,420)
 label(game.l("location%d" % act),Vector2(48,107),22,INK,420)
 draw_line(Vector2(48,127),Vector2(232,127),Color(CYAN,.5),1)
 label("%d / 5" % (act+1),Vector2(48,174),39,CYAN,170)
 label(game.l("planet_count"),Vector2(48,204),17,DIM,200)
 label("◇ %d" % int(data.credits),Vector2(315,202),23,AMBER,150)
 frame(Rect2(520,25,175,220),CYAN,.28)
 label(game.l("world_unlock"),Vector2(607,56),16,CYAN,156,true)
 var special = AstraCards.card(["verdant","frost","ember","storm","echo"][act])
 label(AstraCards.word(special.name,game.language()),Vector2(607,208),21,INK,158,true)
 label(game.l("after_archon"),Vector2(607,233),14,DIM,159,true)
 button(Rect2(623,259,72,61),"Ⅱ","pause")
 # All tokens, paths, icons, the explorer and the landscape beneath them are real 3D objects.
 var available = game.run.available_nodes()
 if game.selected_node in available and game.world.map_nodes.has(game.selected_node):
  var kind: String = game.world.map_nodes[game.selected_node].node.kind
  frame(Rect2(109,990,502,56),CYAN,.91)
  label(AstraCards.word(AstraCards.NODE_NAMES[kind],game.language()),Vector2(360,1027),25,CYAN,460,true)
 else:
  frame(Rect2(109,990,502,56),CYAN,.84)
  label(game.l("select_node"),Vector2(360,1027),22,DIM,468,true)
 instrument(Rect2(24,1063,321,75),game.l("core"),"%d / 20" % int(data.core),float(data.core)/20.0,false)
 instrument(Rect2(375,1063,321,75),game.l("energy"),"3 / 3",1.0,true)
 button(Rect2(215,1160,290,92),game.l("depart")+"  ›","depart",0,true,game.selected_node in available and game.route_travel <= 0)
 button(Rect2(24,1175,167,73),game.l("deck")+" · %d" % data.deck.size(),"deck")
 button(Rect2(529,1175,167,73),game.l("planet_map"),"overview")
func instrument(rect: Rect2, title_value: String, value: String, fraction: float, energy: bool) -> void:
 frame(rect,CYAN,.93)
 var center = rect.position+Vector2(42,36)
 draw_circle(center,24,Color(CYAN,.035)); draw_arc(center,25,0,TAU,48,Color(CYAN,.65),1.5,true)
 draw_arc(center,32,game.clock*.35,game.clock*.35+PI*1.4,32,Color(CYAN,.26),2,true)
 if energy: label("ϟ",center+Vector2(0,12),36,CYAN,50,true)
 else:
  draw_circle(center,9,Color(CYAN,.12)); draw_circle(center,5,CYAN)
  for i in range(8):
   var direction = Vector2.from_angle(i*TAU/8)
   draw_line(center+direction*16,center+direction*23,Color(CYAN,.65),2)
 label(title_value.to_upper(),rect.position+Vector2(81,25),15,CYAN,rect.size.x-95)
 label(value,rect.position+Vector2(81,56),29,INK,155)
 for i in range(5): draw_rect(Rect2(rect.position+Vector2(235+i*11,48),Vector2(7,11)),CYAN if fraction >= (i+1)*.2 else Color("173843"))
func overview() -> void:
 draw_rect(Rect2(0,0,720,1280),Color(.004,.018,.029,.89))
 title("planet_map",game.l("route_future"))
 var act = int(game.run.data.act)
 for i in range(5):
  var y = 264+i*160
  var color: Color = AstraCards.COLORS[i] if i <= act else DIM.darkened(.4)
  frame(Rect2(45,y,630,140),color,.75,i == act)
  draw_circle(Vector2(98,y+62),27,Color(color,.14)); draw_arc(Vector2(98,y+62),29,0,TAU,40,color,2,true)
  label(str(i+1),Vector2(98,y+73),29,color,60,true)
  label(game.l(AstraCards.PLANETS[i]),Vector2(150,y+39),27,color,475)
  label(game.l("location%d" % i),Vector2(150,y+74),20,INK,475)
  label(game.l("world_done" if i < act else ("world_current" if i == act else "world_future")),Vector2(150,y+113),17,DIM,475)
  if i<4: draw_line(Vector2(98,y+142),Vector2(98,y+158),Color(CYAN,.3),2)
 button(Rect2(65,1150,590,94),game.l("back"),"overview_back",0,true)
func battle() -> void:
 var data: Dictionary = game.run.battle.data
 frame(Rect2(24,22,671,146),CYAN,.91)
 label(game.l(AstraCards.PLANETS[int(data.act)])+" / "+AstraCards.word(AstraCards.NODE_NAMES[data.kind],game.language()),Vector2(40,63),22,AMBER,515)
 button(Rect2(570,25,112,65),"Ⅱ","pause")
 label(game.l("turn")+" %02d" % int(data.turn),Vector2(42,111),26,INK)
 label(AstraCards.word(AstraCards.RULES[int(data.act)],game.language()),Vector2(42,145),18,DIM,640)
 frame(Rect2(104,186,512,94),RED,.85)
 label("Ω  %d / %d" % [int(data.enemy_core),int(data.max_enemy_core)],Vector2(360,229),35,RED,610,true)
 var core_ratio = float(data.enemy_core)/float(data.max_enemy_core)
 draw_rect(Rect2(130,252,460,5),Color("3b2d23")); draw_rect(Rect2(130,252,460*core_ratio,5),RED)
 label(game.l("intent"),Vector2(360,313),17,DIM,610,true)
 for intent in data.intent:
  var x = game.world.slot_point("enemy",int(intent.lane)).x
  draw_arc(Vector2(x,353),22,0,TAU,20,RED,1.5)
  label("+",Vector2(x,362),27,RED,45,true)
 # Empty slots are tactile sockets; touch highlighting never depends on a keyboard.
 for side in ["enemy","friendly"]:
  for lane in range(4):
   var point = game.world.slot_point(side,lane)
   var bot: Variant = data[side][lane]
   if bot == null:
    var ink = CYAN if side == "friendly" and game.selected >= 0 else Color("586e7b")
    for dx in [-65,65]:
     draw_line(point+Vector2(dx,-79),point+Vector2(dx,-55),ink,2)
     draw_line(point+Vector2(dx,79),point+Vector2(dx,55),ink,2)
    if side == "friendly": label("+",point+Vector2(0,9),29,ink,100,true)
   else:
    var status = "❄" if bot.frozen > 0 else ("!" if bot.jammed > 0 else ("▲" if bot.burn > 0 else ""))
    if status != "": label(status,point+Vector2(57,-62),25,CYAN if bot.frozen > 0 else RED,50,true)
    var counter = "%d  /  %d" % [int(bot.attack),int(bot.hp)]
    label(counter,point+Vector2(0,101),24,INK,145,true)
 frame(Rect2(26,846,316,62),CYAN,.92)
 frame(Rect2(379,846,316,62),CYAN,.92)
 label("♥ %d / 20" % int(data.core),Vector2(49,886),30,CYAN,280)
 label("ϟ %d / %d" % [int(data.energy),int(data.max_energy)],Vector2(426,886),33,CYAN,255)
 if game.selected >= 0 and game.selected < data.hand.size():
  var entry = AstraCards.card(data.hand[game.selected].id,int(data.hand[game.selected].upgrade))
  var target: String = entry.get("target","slot")
  var key = "target_slot" if target == "slot" else ("target_friend" if target == "friend" else ("target_enemy" if target == "enemy" else "tap_cast"))
  label(game.l(key),Vector2(360,937),23,INK,640,true)
  if target == "all": button(Rect2(478,949,196,62),game.l("confirm_play"),"cast",0,true)
 else: label(game.l("play_hint"),Vector2(360,936),20,DIM,630,true)
 button(Rect2(58,1179,604,81),game.l("end_turn" if data.phase == "player" else "resolving"),"turn",0,true,data.phase == "player" and game.lock_clock <= 0)
func reward() -> void:
 title("reward",game.l("choose_reward"))
 for i in range(game.run.data.reward.size()):
  var id: String = game.run.data.reward[i]
  label(AstraCards.word(AstraCards.CARDS[id].name,game.language()),Vector2(140+i*220,810),23,INK,208,true)
 label("◇ %d" % int(game.run.data.credits),Vector2(360,918),30,AMBER,610,true)
 button(Rect2(65,1006,590,82),game.l("skip"),"reward",-1)
 footer()
func browse() -> void:
 var screen: String = game.screen
 title("collection" if screen == "collection" else ("deck" if screen == "deck" else screen),game.l(screen+"_tip") if screen in ["upgrade","remove"] else "")
 if screen == "collection":
  label("%d / %d   ·   %s: %d" % [game.run.meta.unlocked.size(),AstraCards.CARDS.size(),game.l("records"),game.run.meta.logs.size()],Vector2(55,188),22,DIM,610)
  if not game.run.meta.legacy_completed.is_empty(): label(game.l("legacy")+": "+str(game.run.meta.legacy_completed.size()),Vector2(55,222),20,AMBER,610)
 var count = game.display_entries().size()
 button(Rect2(65,971,125,72),"←","page",-1,false,game.page > 0)
 button(Rect2(530,971,125,72),"→","page",1,false,(game.page+1)*6 < count)
 label("%d / %d" % [game.page+1,maxi(1,int(ceil(count/6.0)))],Vector2(360,1017),25,INK,300,true)
 if game.selected >= 0 and game.selected < count:
  var entry: Dictionary = game.display_entries()[game.selected]
  var card = AstraCards.card(entry.id,int(entry.upgrade))
  words(AstraCards.word(AstraCards.EFFECTS[card.effect],game.language()),Vector2(65,1106),580,25,INK)
 elif screen == "collection": button(Rect2(65,1070,590,77),game.l("records"),"records")
 else: label(game.l("inspect"),Vector2(360,1114),22,DIM,610,true)
 button(Rect2(65,1184,590,72),game.l("leave" if screen in ["upgrade","remove"] else "back"),"leave" if screen in ["upgrade","remove"] else "back")
func shop() -> void:
 title("shop",game.l("scrap")+": "+str(game.run.data.credits))
 for i in range(game.run.data.stock.size()):
  if game.run.data.stock[i] == "": continue
  var price = 20+int(AstraCards.CARDS[game.run.data.stock[i]].rarity)*8
  button(Rect2(52+i*220,794,176,72),"◇ "+str(price),"buy",i,true,game.run.data.credits >= price)
 button(Rect2(65,1010,590,82),game.l("leave"),"leave")
 footer()
func event_screen() -> void:
 title("event")
 label(game.l(AstraCards.PLANETS[int(game.run.data.act)]),Vector2(67,266),31,AstraCards.COLORS[int(game.run.data.act)])
 words(game.l("event%d" % int(game.run.data.act)),Vector2(67,411),582,29,INK)
 button(Rect2(65,834,590,90),game.l("salvage"),"event",0)
 button(Rect2(65,950,590,110),game.l("risk"),"event",1,true,game.run.data.core > 3)
 footer()
func simple_screen(key: String, text: String, command: String, button_key: String) -> void:
 title(key)
 words(game.l(text),Vector2(67,410),583,29,INK)
 if key == "travel": label(game.l(AstraCards.PLANETS[int(game.run.data.act)]),Vector2(360,783),56,AstraCards.COLORS[int(game.run.data.act)],600,true)
 if key == "rest": label("♥ %d → %d" % [int(game.run.data.core),mini(20,int(game.run.data.core)+7)],Vector2(360,784),44,CYAN,610,true)
 button(Rect2(65,986,590,98),game.l(button_key),command,0,true)
 if key not in ["defeat","ending"]: footer()
func settings() -> void:
 title("settings")
 label(game.l("language"),Vector2(65,271),25,INK)
 for i in range(3): button(Rect2(65+i*203,306,184,80),["РУССКИЙ","ENGLISH","DEUTSCH"][i],"language",["ru","en","de"][i],game.language() == ["ru","en","de"][i])
 var keys = ["master_volume","music_volume","effects_volume"]
 for i in range(3):
  var y = 491+i*164
  label(game.l(["volume","music","effects"][i]),Vector2(65,y),25,INK)
  var fraction = float(game.run.store.data[keys[i]])
  draw_line(Vector2(120,y+67),Vector2(600,y+67),Color("677360"),7)
  draw_line(Vector2(120,y+67),Vector2(120+480*fraction,y+67),CYAN,7)
  draw_circle(Vector2(120+480*fraction,y+67),17,INK)
  buttons.append({"rect":Rect2(90,y+29,540,78),"command":"slider","value":keys[i]})
  label("%d%%" % int(fraction*100),Vector2(641,y+76),21,AMBER,75,true)
 if not game.run.data.is_empty(): button(Rect2(65,996,590,75),game.l("hull")+" · "+str(int(game.run.data.hull)+1),"hull")
 button(Rect2(65,1146,590,90),game.l("back"),"back")
func pause() -> void:
 draw_rect(Rect2(0,0,720,1280),Color(0.01,0.025,0.018,0.69))
 title("paused")
 button(Rect2(65,458,590,91),game.l("continue"),"resume",0,true)
 button(Rect2(65,577,590,82),game.l("settings"),"settings")
 button(Rect2(65,687,590,82),game.l("menu"),"menu")
 button(Rect2(65,797,590,82),game.l("quit"),"quit")
 label(game.l("autosave"),Vector2(360,984),24,CYAN,610,true)
func inspector() -> void:
 title("inspect",AstraCards.word(game.inspect_entry.name,game.language()))
 var entry: Dictionary = game.inspect_entry
 words(AstraCards.word(AstraCards.EFFECTS.get(entry.effect,["","",""]),game.language()),Vector2(65,945),590,26,INK)
 button(Rect2(65,1130,590,95),game.l("back"),"inspect_back")
func records() -> void:
 title("records")
 var logs: Array = game.run.meta.logs
 for i in range(mini(3,logs.size()-game.page*3)):
  var id: String = logs[game.page*3+i]
  var y = 300+i*238
  draw_line(Vector2(65,y+15),Vector2(655,y+15),Color("71725b"),1)
  if id == "legacy":
   label(game.l("legacy"),Vector2(65,y),27,AMBER,590)
   label(str(game.run.meta.legacy_completed.size())+" / 50",Vector2(65,y+61),31,INK)
  else:
   var act = int(id.right(1))
   label("LOG %02d / " % (act+1)+game.l(AstraCards.PLANETS[act]),Vector2(65,y),27,AstraCards.COLORS[act],590)
   words(game.l("event%d" % act),Vector2(65,y+63),590,24,INK)
 if logs.is_empty(): words(game.l("locked"),Vector2(65,380),590,25)
 button(Rect2(65,1050,125,72),"←","page",-1,false,game.page>0)
 button(Rect2(530,1050,125,72),"→","page",1,false,(game.page+1)*3<logs.size())
 button(Rect2(65,1160,590,82),game.l("back"),"inspect_back")
func _draw() -> void:
 if game == null or game.world == null or game.quitting: return
 buttons.clear()
 # Gentle vignette keeps the table visible and makes the small instrument readouts legible.
 for i in range(9):
  draw_rect(Rect2(0,i*12,720,12),Color(0,0.018,0.01,0.62-i*0.06))
  draw_rect(Rect2(0,1268-i*12,720,12),Color(0,0.012,0.008,0.45-i*0.04))
 match game.screen:
  "menu": menu()
  "new": new_run()
  "intro": intro()
  "map": route()
  "overview": overview()
  "battle": battle()
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
  var style = StyleBoxFlat.new(); style.bg_color = Color(0.08,0.1,0.07,0.95); style.border_color = AMBER; style.set_border_width_all(1)
  draw_style_box(style,Rect2(40,128,640,92))
  words(game.l(game.toast),Vector2(60,165),600,22,INK)

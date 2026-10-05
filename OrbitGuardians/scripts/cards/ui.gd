extends Control
class_name AstraTableUI
## Touch-sized controls and engraved HUD over a real 3D table; all text is RU/EN/DE.
var game: AstraGame
var buttons: Array = []
var font: Font = ThemeDB.fallback_font
const INK = Color("e7ddbb")
const DIM = Color("a6ad98")
const CYAN = Color("70d6c1")
const AMBER = Color("d9ac65")
const RED = Color("ee8b64")
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
func button(rect: Rect2, text: String, command: String, value: Variant = 0, accent: bool = false, enabled: bool = true) -> void:
 var style = StyleBoxFlat.new(); style.bg_color = Color("28342e") if accent else Color(0.055,0.072,0.061,0.90)
 style.border_color = CYAN if accent else Color("77765a"); style.set_border_width_all(2); style.set_corner_radius_all(8)
 if not enabled: style.border_color = Color("41473e"); style.bg_color.a = 0.68
 draw_style_box(style,rect)
 draw_line(rect.position+Vector2(10,9),rect.position+Vector2(30,9),AMBER if enabled else DIM,2)
 label(text,rect.get_center()+Vector2(0,9),25,INK if enabled else Color("687266"),rect.size.x-30,true)
 if enabled: buttons.append({"rect":rect,"command":command,"value":value})
func title(key: String, sub: String = "") -> void:
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
 draw_rect(Rect2(0,0,720,1280),Color(0.01,0.025,0.018,0.37))
 label("ORBITAL",Vector2(57,166),67,INK,610)
 label("FRONT",Vector2(54,235),78,CYAN,610)
 label(game.l("subtitle"),Vector2(59,281),20,AMBER,610)
 words(game.l("intro3"),Vector2(60,379),590,24)
 button(Rect2(65,567,590,88),game.l("continue"),"continue",0,true,game.run.resume_available())
 button(Rect2(65,678,590,88),game.l("new"),"new",0,true)
 button(Rect2(65,789,590,80),game.l("collection"),"collection")
 button(Rect2(65,889,590,80),game.l("settings"),"settings")
 button(Rect2(65,989,590,80),game.l("quit"),"quit")
 label("RU / EN / DE    ·    ASTRA TABLETOP / 4.0",Vector2(360,1200),17,DIM,610,true)
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
 title("route",game.l("select_node"))
 var data: Dictionary = game.run.data
 for i in range(5):
  var x = 88+i*136
  draw_circle(Vector2(x,258),13,AstraCards.COLORS[i] if i <= int(data.act) else Color("485047"))
  label(game.l(AstraCards.PLANETS[i]),Vector2(x,298),19,AstraCards.COLORS[i] if i == int(data.act) else DIM,129,true)
 label("ACT %s  /  %s" % [["I","II","III","IV","V"][int(data.act)],AstraCards.word(AstraCards.BOSSES[int(data.act)],game.language())],Vector2(360,357),22,AMBER,610,true)
 var available = game.run.available_nodes()
 var previous: Variant = null
 for id in data.visited:
  if not game.world.map_nodes.has(id): continue
  var point: Vector2 = game.world.map_nodes[id].point
  if previous != null: draw_line(previous,point,CYAN,3)
  previous = point
 for id in game.world.map_nodes:
  var record: Dictionary = game.world.map_nodes[id]
  var point: Vector2 = record.point
  var chosen = id in data.visited
  var lit = id in available
  var color = CYAN if chosen or lit else Color("727e62")
  draw_arc(point,34 if lit else 27,0,TAU,32,color,3 if lit else 1)
  if lit: draw_circle(point,29,Color(0.05,0.1,0.08,0.8))
  label(AstraCards.GLYPHS[record.node.kind],point+Vector2(0,10),32,color,65,true)
  if lit: label(AstraCards.word(AstraCards.NODE_NAMES[record.node.kind],game.language()),point+Vector2(0,54),18,INK,205,true)
 label(game.l("node_tip"),Vector2(360,1042),19,DIM,610,true)
 button(Rect2(56,1060,270,62),game.l("deck"),"deck")
 button(Rect2(394,1060,270,62),game.l("pause"),"pause")
 footer()
func battle() -> void:
 var data: Dictionary = game.run.battle.data
 label(game.l(AstraCards.PLANETS[int(data.act)])+" / "+AstraCards.word(AstraCards.NODE_NAMES[data.kind],game.language()),Vector2(40,63),22,AMBER,515)
 button(Rect2(570,25,112,65),"Ⅱ","pause")
 label(game.l("turn")+" %02d" % int(data.turn),Vector2(42,111),26,INK)
 label(AstraCards.word(AstraCards.RULES[int(data.act)],game.language()),Vector2(42,145),18,DIM,640)
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
    var ink = CYAN if side == "friendly" and game.selected >= 0 else Color("61694f")
    for dx in [-65,65]:
     draw_line(point+Vector2(dx,-79),point+Vector2(dx,-55),ink,2)
     draw_line(point+Vector2(dx,79),point+Vector2(dx,55),ink,2)
    if side == "friendly": label("+",point+Vector2(0,9),29,ink,100,true)
   else:
    var status = "❄" if bot.frozen > 0 else ("!" if bot.jammed > 0 else ("▲" if bot.burn > 0 else ""))
    if status != "": label(status,point+Vector2(57,-62),25,CYAN if bot.frozen > 0 else RED,50,true)
    var counter = "%d  /  %d" % [int(bot.attack),int(bot.hp)]
    label(counter,point+Vector2(0,101),24,INK,145,true)
 label("♥ %d / 20" % int(data.core),Vector2(49,886),30,CYAN,340)
 label("ϟ %d / %d" % [int(data.energy),int(data.max_energy)],Vector2(488,886),33,AMBER,192)
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

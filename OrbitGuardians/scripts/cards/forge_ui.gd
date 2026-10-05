extends AstraDesktopUI
class_name AstraForgeUI
var popups: Array=[]
## Command combat keeps readable blueprints in fixed positions; details live on hover.
func art(entry: Dictionary, rect: Rect2) -> void:
 var path=AstraForgeModels.portrait(entry)
 if not ResourceLoader.exists(path):super.art(entry,rect);return
 if not portraits.has(path):portraits[path]=load(path)
 var texture: Texture2D=portraits[path]
 var fit=minf(rect.size.x/texture.get_width(),rect.size.y/texture.get_height())
 var dims=texture.get_size()*fit
 draw_texture_rect(texture,Rect2(rect.get_center()-dims/2,dims),false)
func route() -> void:
 super.route()
 button(Rect2(1234,817,319,43),game.l("supplies"),"supplies",0,false,game.run.supply_access())
func battle() -> void:
 if not game.run.battle.commands():super.battle();return
 var data=game.run.battle.data
 frame(Rect2(26,20,1546,79),CYAN,.97)
 label(game.l(AstraCards.PLANETS[int(data.act)]),Vector2(49,57),27,INK,300)
 label(game.l("plan" if data.phase=="player" else "resolution")+" · %02d" % data.turn,Vector2(402,59),27,CYAN,320)
 button(Rect2(923,34,177,50),game.l("forge_deck"),"deck",0,false,data.phase=="player")
 button(Rect2(1114,34,232,50),game.l("supplies"),"supplies",0,false,game.run.supply_access())
 button(Rect2(1360,34,187,50),game.l("pause"),"pause")
 health_bar(Rect2(52,109,1085,59),game.l("foe"),data.enemy_core,data.max_enemy_core,RED)
 # Intent is a symbol at the exact lane, without a paragraph across the arena.
 for intent in data.intent:
  var p=game.world.slot_point("enemy",int(intent.lane))
  draw_circle(p+Vector2(0,-87),15,Color("fca15f"));label("+",p+Vector2(0,-78),24,Color("141f29"),30,true)
 for side in ["enemy","friendly"]:
  for lane in range(4):
   var p=game.world.slot_point(side,lane);var bot:Variant=data[side][lane]
   if bot==null:
    if side=="friendly":label("+",p+Vector2(0,18),35,CYAN if game.selected>=0 else DIM,65,true)
    continue
   var tint=AstraRoles.color(bot)
   if side=="friendly" and lane==game.selected_bot:draw_arc(p,82,0,TAU,40,tint,2.5)
   # Two floating numeric badges leave the model's silhouette unobscured.
   frame(Rect2(p+Vector2(-93,46),Vector2(77,31)),AstraRoles.ATTACK,.94)
   label("× %d" % maxi(0,bot.attack+bot.get("focus",0)-bot.get("slowed",0)),p+Vector2(-78,70),25,AstraRoles.ATTACK,65)
   frame(Rect2(p+Vector2(-10,46),Vector2(103,31)),AstraRoles.HP,.94)
   label("%d / %d" % [bot.hp,bot.max_hp],p+Vector2(2,70),24,AstraRoles.HP,89)
   draw_rect(Rect2(p+Vector2(-87,79),Vector2(174,4)),Color("1b333e"))
   draw_rect(Rect2(p+Vector2(-87,79),Vector2(174*float(bot.hp)/bot.max_hp,4)),AstraRoles.HP)
   var defence=int(bot.get("armor",0))+bot.shield+bot.temporary
   if defence>0:draw_circle(p+Vector2(69,-44),19,AstraRoles.DEFENCE);label(str(defence),p+Vector2(69,-36),22,Color("302714"),30,true)
   if bot.get("slowed",0)>0:label("−1",p+Vector2(-88,-38),23,Color("a7e6ff"),60)
   if bot.jammed+bot.burn+bot.frozen>0:label("!",p+Vector2(-88,-10),26,AMBER,40)
   hit_card(bot,Rect2(p-Vector2(105,78),Vector2(210,163)),side,lane)
 if game.selected_bot>=0 and data.friendly[game.selected_bot]!=null:
  var target=int(data.friendly[game.selected_bot].get("target_lane",-1))
  if target>=0 and data.enemy[target]!=null:
   var a=game.world.slot_point("friendly",game.selected_bot);var b=game.world.slot_point("enemy",target)
   draw_dashed_line(a+Vector2(0,-65),b+Vector2(0,70),AstraRoles.ATTACK,2,9)
 health_bar(Rect2(52,644,610,60),game.l("you"),data.core,data.max_core)
 health_bar(Rect2(686,644,451,60),game.l("energy"),data.energy,maxi(data.max_energy,data.energy))
 for i in range(data.hand.size()):
  var raw=data.hand[i];var entry=game.run.battle.instance(raw);entry.uid=raw.uid
  var rect=Rect2(46+i*184,726,174,163)
  frame(rect,AstraRoles.color(entry),.98,i==game.selected)
  words(AstraCards.word(entry.name,game.language()),rect.position+Vector2(10,21),130,18,INK)
  draw_circle(rect.position+Vector2(152,22),14,CYAN)
  label(str(entry.cost),rect.position+Vector2(152,29),21,Color("112430"),27,true)
  art(entry,Rect2(rect.position+Vector2(23,45),Vector2(128,80)))
  var ready=game.run.battle.ready_command(i)
  if not ready:
   draw_rect(rect,Color(0.02,.04,.07,.55));label(game.l("used_command"),rect.position+Vector2(11,143),19,DIM,152)
  elif entry.hp>0:
   label("× %d" % entry.attack,rect.position+Vector2(12,147),22,AstraRoles.ATTACK,69)
   label("HP %d" % entry.hp,rect.position+Vector2(91,147),22,AstraRoles.HP,73)
  else:label("[%d]" % (i+1),rect.position+Vector2(13,147),21,CYAN,146)
  hit_card(entry,rect,"hand",-1,i)
 preview_panel()
 var can_end=data.phase=="player" and game.lock_clock<=0
 button(Rect2(1179,816,388,73),game.l("end_turn") if can_end else game.l("resolution"),"turn",0,true,can_end)
func preview_panel() -> void:
 if not game.run.battle.commands():super.preview_panel();return
 var data=game.run.battle.data
 frame(Rect2(1170,109,400,694),Color("426677"),.97)
 var entry:Dictionary=game.hovered_entry
 if entry.is_empty() and game.selected>=0 and game.selected<data.hand.size():entry=game.run.battle.instance(data.hand[game.selected])
 if entry.is_empty() and game.selected_bot>=0 and data.friendly[game.selected_bot]!=null:entry=data.friendly[game.selected_bot]
 if entry.is_empty():
  label(AstraRivals.name_for(data.act,game.language()),Vector2(1193,152),26,AstraRoles.ATTACK,355)
  rival_art(data.act,Rect2(1257,164,224,175))
  label(game.l("target_hint"),Vector2(1193,383),24,INK,354)
  preview_bottom=words(game.l("prepared"),Vector2(1193,429),350,22,DIM)
 else:
  label(AstraCards.word(entry.name,game.language()),Vector2(1193,151),26,INK,350)
  art(entry,Rect2(1212,173,316,169))
  if entry.hp>0:combat_stats(entry,Vector2(1193,383),350,27)
  preview_bottom=words(AstraForgeWords.description(entry,game.language()),Vector2(1193,429),350,22,DIM)
 if game.selected_bot>=0 and data.friendly[game.selected_bot]!=null:
  var bot:Dictionary=data.friendly[game.selected_bot]
  var valid=data.phase=="player" and data.energy>0 and bot.get("ordered_turn",-1)!=data.turn
  button(Rect2(1192,517,175,47),game.l("aim"),"order","aim",false,valid and bot.attack>0)
  button(Rect2(1378,517,172,47),game.l("guard"),"order","guard",false,valid)
  button(Rect2(1192,574,358,41),game.l("withdraw"),"withdraw",0,false,data.phase=="player")
 if game.selected>=0 and game.selected<data.hand.size():
  var selected=game.run.battle.instance(data.hand[game.selected])
  if selected.get("target","")=="all":
   button(Rect2(1192,574,358,41),game.l("apply"),"cast",0,true,data.phase=="player" and game.run.battle.ready_command(game.selected) and data.energy>=selected.cost)
 for i in range(4):
  var kind=AstraRun.SUPPLY_PRICES.keys()[i];var qty=game.run.data.get("supplies",{}).get(kind,0)
  var text=game.l("quick_"+kind)+" · %d" % qty
  button(Rect2(1192+(i%2)*185,637+int(i/2)*59,173,50),text,"supply_use",kind,false,qty>0 and game.run.supply_access())
func browse() -> void:
 if game.screen!="deck":super.browse();return
 title("forge_deck",game.l("deck_edit_tip"))
 frame(Rect2(32,165,350,580),CYAN,.97)
 label("%d / 6" % game.draft_loadout.size(),Vector2(64,213),32,CYAN,270)
 if game.run.data.state=="battle":words(game.l("next_battle"),Vector2(64,262),292,21,AMBER)
 for i in range(game.draft_loadout.size()):
  for entry in game.run.data.deck:
   if entry.uid!=game.draft_loadout[i]:continue
   var rect=Rect2(53,310+i*62,308,52)
   button(rect,str(i+1)+" · "+AstraCards.word(AstraCards.CARDS[entry.id].name,game.language()),"loadout_toggle",entry.uid)
 label(game.l("reserve")+" · %d" % game.run.data.deck.size(),Vector2(423,176),23,DIM,1090)
 var entries=game.display_entries()
 for i in range(mini(6,entries.size()-game.page*6)):
  var raw=entries[game.page*6+i];var entry=AstraCards.card(raw.id,raw.upgrade);entry.uid=raw.uid
  var rect=Rect2(417+(i%3)*381,195+int(i/3)*245,343,211)
  var equipped=raw.uid in game.draft_loadout
  frame(rect,AstraRoles.color(entry),.98,equipped)
  label(AstraCards.word(entry.name,game.language()),rect.position+Vector2(14,31),23,INK,285)
  draw_circle(rect.position+Vector2(316,25),16,CYAN)
  label(str(entry.cost),rect.position+Vector2(316,32),23,Color("112430"),28,true)
  art(entry,Rect2(rect.position+Vector2(16,45),Vector2(142,136)))
  if entry.hp>0:
   label("× %d" % entry.attack,rect.position+Vector2(175,96),25,AstraRoles.ATTACK,149)
   label("HP %d" % entry.hp,rect.position+Vector2(175,135),25,AstraRoles.HP,149)
  else:label(game.l("action"),rect.position+Vector2(175,118),22,CYAN,154)
  label(game.l("equipped" if equipped else "reserve"),rect.position+Vector2(175,186),21,CYAN if equipped else DIM,154)
  hit_card(entry,rect,"browse",game.page*6+i)
 button(Rect2(421,706,140,54),"←","page",-1,false,game.page>0)
 button(Rect2(1409,706,140,54),"→","page",1,false,(game.page+1)*6<entries.size())
 button(Rect2(400,795,340,70),game.l("back"),"back")
 button(Rect2(767,795,780,70),game.l("loadout_apply"),"loadout_save",0,true,AstraRun.valid_loadout(game.draft_loadout,game.run.data.deck))
func supplies() -> void:
 title("supplies",game.l("supply_tip"))
 label(game.l("scrap")+": %d" % game.run.data.credits,Vector2(1425,84),29,AMBER,240,true)
 button(Rect2(66,154,694,61),game.l("supply_items"),"supply_tab",0,game.supply_tab==0)
 button(Rect2(784,154,756,61),game.l("blueprints"),"supply_tab",1,game.supply_tab==1)
 if game.supply_tab==0:
  for i in range(4):
   var kind=AstraRun.SUPPLY_PRICES.keys()[i];var x=55+i*388;var rect=Rect2(x,248,365,457)
   frame(rect,AstraRoles.HP if i==0 else (AstraRoles.DEFENCE if i==2 else CYAN),.98)
   var icon=["+","ϟ","◇","×"][i]
   label(icon,Vector2(x+181,388),100,CYAN,200,true)
   label(game.l(kind),Vector2(x+24,291),28,INK,320)
   words(game.l(kind+"_tip"),Vector2(x+24,438),316,25,DIM)
   label("%d" % game.run.data.supplies[kind],Vector2(x+181,554),39,CYAN,120,true)
   button(Rect2(x+18,579,329,51),game.l("purchase")+" · %d" % AstraRun.SUPPLY_PRICES[kind],"supply_buy",kind,true,game.run.data.credits>=AstraRun.SUPPLY_PRICES[kind] and game.run.supply_access())
   button(Rect2(x+18,643,329,43),game.l("apply"),"supply_use",kind,false,game.run.data.supplies[kind]>0 and game.run.supply_access())
 else:
  var entries: Array=[]
  for id in game.run.meta.unlocked:
   if id in AstraCards.CARDS:entries.append(id)
  for i in range(mini(6,entries.size()-game.page*6)):
   var id=entries[game.page*6+i];var entry=AstraCards.card(id);var x=63+(i%3)*513;var y=239+int(i/3)*223
   frame(Rect2(x,y,475,203),AstraRoles.color(entry),.98)
   art(entry,Rect2(x+8,y+46,160,124))
   label(AstraCards.word(entry.name,game.language()),Vector2(x+181,y+35),24,INK,269)
   words(AstraForgeWords.description(entry,game.language()),Vector2(x+181,y+78),264,20,DIM)
   button(Rect2(x+178,y+151,278,37),game.l("purchase")+" · %d" % (22+entry.rarity*8),"blueprint_buy",id,false,game.run.data.credits>=22+entry.rarity*8 and game.run.supply_access())
  button(Rect2(56,709,138,53),"←","supply_page",-1,false,game.page>0)
  button(Rect2(1409,709,138,53),"→","supply_page",1,false,(game.page+1)*6<entries.size())
 button(Rect2(538,797,530,68),game.l("back"),"supplies_back",0,true)
func _draw() -> void:
 super._draw()
 if game.screen=="supplies":supplies()
 if game.screen=="battle":
  for popup in popups:
   label(popup.text,popup.point+Vector2(0,-35-(1.1-popup.life)*55),33,popup.color,100,true)

func feedback(events: Array) -> void:
 for event in events:
  if event.kind not in ["hit","core","heal_core"] or event.get("damage",0)<=0:continue
  var point=game.world.slot_point(event.get("side","friendly"),int(event.get("lane",1)))
  if event.kind in ["core","heal_core"]:point=Vector2(592,134 if event.side=="enemy" else 662)
  popups.append({"point":point,"text":("+" if event.kind=="heal_core" else "−")+str(event.damage),"color":AstraRoles.HP if event.kind=="heal_core" else AstraRoles.ATTACK,"life":1.1})
func _process(delta: float) -> void:
 super._process(delta)
 if large_face.visible:
  var path=AstraForgeModels.portrait(game.inspect_entry)
  if ResourceLoader.exists(path) and large_face.art.resource_path!=path:large_face.art=load(path);large_face.queue_redraw()
 for i in range(popups.size()-1,-1,-1):
  popups[i].life-=delta
  if popups[i].life<=0:popups.remove_at(i)

extends Control
class_name AstraCardFace
var card: Dictionary = {}
var language = "ru"
var hostile = false
var font: Font = ThemeDB.fallback_font
var art: Texture2D
const W = 300.0
const H = 430.0
func _ready() -> void:
 var candidate = "res://assets3d/roles/portraits/%s.png" % card.art
 if not ResourceLoader.exists(candidate): candidate = "res://assets3d/tabletop/portraits/%s.png" % card.art
 if not ResourceLoader.exists(candidate): candidate = "res://assets3d/icons/%s.png" % card.art
 art = load(candidate)
 queue_redraw()
func line(text: String, point: Vector2, size_value: int, color: Color, width: float = 260) -> void:
 var fitted = size_value
 while font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted).x > width and fitted > 14: fitted -= 1
 draw_string(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,width,fitted,color)
func _draw() -> void:
 var ink = Color("e6edf0")
 var accent = AstraRoles.color(card)
 var face = Color("222124") if hostile else Color("15242d")
 draw_rect(Rect2(0,0,W,H),Color("050c12"))
 draw_rect(Rect2(7,7,W-14,H-14),face)
 for i in range(15):
  var y = 13+i*28
  draw_line(Vector2(10,y),Vector2(W-10,y+10),Color(0.2,0.2,0.15,0.07),1)
 draw_rect(Rect2(13,13,W-26,H-26),accent,false,2)
 draw_rect(Rect2(22,63,256,220),Color("111519") if hostile else Color("0a1720"))
 for i in range(10): draw_line(Vector2(23,75+i*22),Vector2(277,75+i*22),Color(accent,.04),1)
 if art != null: draw_texture_rect(art,Rect2(30,69,240,208),false)
 draw_rect(Rect2(22,63,256,220),accent,false,1)
 for corner in [Vector2(17,17),Vector2(283,17),Vector2(17,413),Vector2(283,413)]:
  draw_circle(corner,3,Color("8a8167")); draw_line(corner-Vector2(2,0),corner+Vector2(2,0),ink,1)
 line(AstraCards.word(card.name,language),Vector2(25,45),25,ink,226)
 draw_circle(Vector2(260,87),25,Color("ff9552") if hostile else Color("65e6f4"))
 line(("Ω" if card.id == "boss" else "!") if hostile else str(card.cost),Vector2(246,102),38,Color("102321"),45)
 if card.hp > 0:
  line("× " + str(card.attack),Vector2(26,328),39,AstraRoles.ATTACK,112)
  line("HP " + str(card.hp),Vector2(174,328),39,AstraRoles.HP,106)
 else: line(AstraWords.get_text("action",language),Vector2(26,327),29,ink)
 var description: String = AstraCards.description(card,language)
 var words = description.split(" ")
 var rows: Array[String] = [""]
 for word in words:
  if font.get_string_size(rows[-1]+" "+word,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x > 250: rows.append(word)
  else: rows[-1] = (rows[-1]+" "+word).strip_edges()
 for i in range(mini(2,rows.size())): line(rows[i],Vector2(25,356+i*20),17,ink)
 line(AstraWords.get_text("rarity%d" % int(card.get("rarity",0)),language).to_upper(),Vector2(25,407),15,accent,230)
 for i in range(int(card.get("upgrade",0))): draw_circle(Vector2(251+i*12,400),4,accent)

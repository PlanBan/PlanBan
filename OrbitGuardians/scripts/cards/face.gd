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
 var candidate = "res://assets3d/tabletop/portraits/%s.png" % card.art
 if not ResourceLoader.exists(candidate): candidate = "res://assets3d/icons/%s.png" % card.art
 art = load(candidate)
 queue_redraw()
func line(text: String, point: Vector2, size_value: int, color: Color, width: float = 260) -> void:
 var fitted = size_value
 while font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fitted).x > width and fitted > 14: fitted -= 1
 draw_string(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,width,fitted,color)
func _draw() -> void:
 var ink = Color("ece5d1") if hostile else Color("1c292b")
 var accent = Color("ed8559") if hostile else Color("307e77")
 var face = Color("252824") if hostile else Color("c3cabe")
 draw_rect(Rect2(0,0,W,H),Color("111a1a"))
 draw_rect(Rect2(7,7,W-14,H-14),face)
 for i in range(15):
  var y = 13+i*28
  draw_line(Vector2(10,y),Vector2(W-10,y+10),Color(0.2,0.2,0.15,0.07),1)
 draw_rect(Rect2(13,13,W-26,H-26),accent,false,2)
 draw_rect(Rect2(22,63,256,220),Color("111d1e") if hostile else Color("374643"))
 if art != null: draw_texture_rect(art,Rect2(30,69,240,208),false)
 draw_rect(Rect2(22,63,256,220),accent,false,1)
 for corner in [Vector2(17,17),Vector2(283,17),Vector2(17,413),Vector2(283,413)]:
  draw_circle(corner,3,Color("8a8167")); draw_line(corner-Vector2(2,0),corner+Vector2(2,0),ink,1)
 line(AstraCards.word(card.name,language),Vector2(25,45),25,ink,226)
 draw_circle(Vector2(260,87),25,Color("e5ba62") if hostile else Color("5fd4c3"))
 line(("Ω" if card.id == "boss" else "!") if hostile else str(card.cost),Vector2(246,102),38,Color("102321"),45)
 if card.hp > 0:
  line("× " + str(card.attack),Vector2(26,328),39,ink,112)
  line("♥ " + str(card.hp),Vector2(174,328),39,ink,106)
 else: line(AstraWords.get_text("action",language),Vector2(26,327),29,ink)
 var description: String = AstraCards.word(AstraCards.EFFECTS.get(card.effect,["","",""]),language)
 var words = description.split(" ")
 var rows: Array[String] = [""]
 for word in words:
  if font.get_string_size(rows[-1]+" "+word,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x > 250: rows.append(word)
  else: rows[-1] = (rows[-1]+" "+word).strip_edges()
 for i in range(mini(2,rows.size())): line(rows[i],Vector2(25,356+i*20),17,ink)
 line(AstraWords.get_text("rarity%d" % int(card.get("rarity",0)),language).to_upper(),Vector2(25,407),15,accent,230)
 for i in range(int(card.get("upgrade",0))): draw_circle(Vector2(251+i*12,400),4,accent)

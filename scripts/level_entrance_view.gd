extends Control
## A clipped graphite inscription, followed by a physical eraser sweep.
var game
var clip: Control
var lettering: Node2D
var handwriting: Font
var ui_font: Font
var title: String=""
var title_size: int=72
var title_width: float=0
var left: float=0
const INK=Color("302b28")
const PAPER=Color("f1e9d7")

func _ready() -> void:
 visible=false
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 handwriting=FontVariation.new()
 handwriting.base_font=load("res://assets/fonts/notes.ttf")
 handwriting.variation_opentype={"wght":600}
 ui_font=load("res://assets/fonts/ui.ttf")
 clip=Control.new()
 clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
 clip.clip_contents=true
 add_child(clip)
 lettering=Node2D.new()
 lettering.draw.connect(_draw_lettering)
 clip.add_child(lettering)

func _process(_dt: float) -> void:
 visible=game.campaign and game.mode=="level_intro" and not game.help_open
 if not visible: return
 title=game.run.level_name()
 title_size=72
 while handwriting.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x>1000 and title_size>28:
  title_size-=2
 title_width=handwriting.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x+12
 left=(1440-title_width)*0.5
 var state=game.run.entrance
 var erased: float=state.erasing()
 var written: float=state.writing()
 # Move the clipping window, then counter-move the text: erasure truly removes
 # graphite from left to right instead of sliding or fading the entire label.
 clip.rotation=note_angle()
 clip.position=note_center()+Vector2(-title_width*0.5+title_width*erased,-50).rotated(clip.rotation)
 clip.size=Vector2(maxf(0,title_width*(written-erased)),108)
 lettering.position=Vector2(-title_width*erased,0)
 modulate.a=1.0-clampf((erased-0.83)/0.17,0,1)
 lettering.queue_redraw()
 queue_redraw()

func note_center() -> Vector2:
 if game.reduced_motion: return Vector2(720,380)
 var t=clampf(game.run.entrance.elapsed/0.22,0,1)
 return Vector2(720,380-12*pow(1-t,3))

func note_angle() -> float:
 var t=clampf(game.run.entrance.elapsed/0.22,0,1)
 return -0.045+0.025*pow(1-t,3) if not game.reduced_motion else -0.045

func torn_outline(width: float) -> PackedVector2Array:
 var points=PackedVector2Array()
 var corners=[Vector2(-width/2,-110),Vector2(width/2,-110),Vector2(width/2,95),Vector2(-width/2,95)]
 for side in range(4):
  var a: Vector2=corners[side]
  var b: Vector2=corners[(side+1)%4]
  var normal=(b-a).normalized().orthogonal()
  var count=maxi(8,ceili(a.distance_to(b)/13))
  for i in range(count):
   var tear=sin(i*7.31+side*9.1)*2.4+cos(i*3.71+side)*1.3
   if i%13==6: tear+=5.5
   points.append(a.lerp(b,float(i)/count)+normal*tear)
 return points

func _draw_lettering() -> void:
 if game.mode!="level_intro": return
 var text_color=Color("555049") if game.run.entrance.config.style=="pencil" else INK
 lettering.draw_string(handwriting,Vector2(4,79),title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size,text_color)
 # A second faint impression gives the graphite a soft, imperfect edge.
 if game.run.entrance.config.style=="pencil":
  lettering.draw_string(handwriting,Vector2(4.7,79.3),title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size,Color(INK,0.12))

func _draw() -> void:
 if not visible or game.mode!="level_intro": return
 var state=game.run.entrance
 var written: float=state.writing()
 var erased: float=state.erasing()
 draw_rect(Rect2(0,0,1440,810),Color(PAPER,0.33))
 var width=maxf(760,title_width+160)
 var center=note_center()
 var angle=note_angle()
 var outline=torn_outline(width)
 draw_set_transform(center+Vector2(9,12),angle)
 draw_colored_polygon(outline,Color(INK,0.14))
 draw_set_transform(center+Vector2(3,4),angle)
 draw_colored_polygon(outline,Color(INK,0.1))
 draw_set_transform(center,angle)
 draw_colored_polygon(outline,Color("f8f0df"))
 # Tiny loose fibres and darker paper edges replace the heavy ink banner.
 for i in range(outline.size()):
  if i%3!=0: continue
  var point=outline[i]
  var outward=point.normalized()
  draw_line(point-outward*1.5,point+outward*(1.2+fposmod(i*1.7,2.2)),Color("d7c9b2"),0.8,true)
 # Sparse pencil grain, creases and a lightly ruled writing area.
 for i in range(65):
  var x=-width/2+20+fposmod(i*81.39,width-40)
  var y=-96+fposmod(i*39.71,175)
  draw_line(Vector2(x,y),Vector2(x+2.5,y-0.5),Color(INK,0.035),0.7,true)
 draw_line(Vector2(-width/2+31,53),Vector2(width/2-33,53),Color(INK,0.12),0.8,true)
 draw_polyline(PackedVector2Array([Vector2(-width/2+5,74),Vector2(-width/2+28,64),Vector2(-width/2+42,92)]),Color(INK,0.07),1,true)
 draw_line(Vector2(width/2-70,-108),Vector2(width/2-8,-71),Color(INK,0.065),1,true)
 var label=game.run.Texts.ui("livello_d_di_d") % [game.run.level_number(),game.run.content.groups.size()]
 var label_width=ui_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
 draw_string(ui_font,Vector2(width/2-label_width-32,-68),label,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(INK,0.6))
 draw_string(handwriting,Vector2(-width/2+30,-66),game.run.Texts.ui("level_entrance_master_note"),HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color(INK,0.58))
 draw_set_transform(Vector2.ZERO)
 if erased>0:
  var edge=left+title_width*erased
  # A small hand-drawn rubber follows the removal front; graphite crumbs trail it.
  if state.config.style=="pencil" and not game.reduced_motion:
   draw_set_transform(center+Vector2(edge-720,10+sin(erased*52)*9).rotated(angle),angle-0.23)
   draw_colored_polygon(PackedVector2Array([Vector2(-18,-19),Vector2(21,-19),Vector2(26,1),Vector2(-13,1)]),Color("d3c5af"))
   draw_rect(Rect2(-18,-19,39,20),Color(INK,0.6),false,1.5)
   draw_line(Vector2(-8,-18),Vector2(-3,0),Color(INK,0.4),1)
   draw_set_transform(Vector2.ZERO)
  for i in range(18):
   var x=edge-4-fposmod(i*19.37,75)
   draw_line(center+Vector2(x-720,33+sin(i*2.1)*11).rotated(angle),center+Vector2(x+2.5-720,34+sin(i*2.1)*11).rotated(angle),Color(INK,0.25),1)
 elif written<1 and state.config.style=="pencil" and not game.reduced_motion:
  var edge=left+title_width*written
  # A discreet pencil nib tracks the horizontal reveal, rather than a typewriter.
  var y=385+sin(written*83)*13
  draw_line(center+Vector2(edge+3-720,y-380).rotated(angle),center+Vector2(edge+29-720,y-39-380).rotated(angle),Color(INK,0.65),4,true)
  draw_line(center+Vector2(edge+1-720,y+4-380).rotated(angle),center+Vector2(edge+5-720,y-3-380).rotated(angle),INK,1.5,true)
 if state.elapsed>=0.25:
  var hint=game.run.Texts.ui("level_entrance_skip")
  var hint_width=ui_font.get_string_size(hint,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
  draw_string(ui_font,Vector2(720-hint_width/2,511),hint,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(INK,0.65))

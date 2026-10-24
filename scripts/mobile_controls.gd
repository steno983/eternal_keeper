extends Node2D
## Multitouch owns only its own action presses; gameplay keeps the InputMap contract.
const Texts=preload("res://scripts/text_data.gd")
var game
var enabled=false
var fingers={}
var stick_id=-1
var stick=Vector2.ZERO
var held={}
var last_mode=""
const STICK=Vector2(165,590)
const BUTTONS={"attack":Vector3(1310,605,65),"guard":Vector3(1155,620,50),"dodge":Vector3(1310,455,50),"party_super":Vector3(1155,470,50)}
const SPELLS=["special","ranged","spell_2","spell_3"]
func _ready():
 enabled=DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or "--mobile-preview" in OS.get_cmdline_user_args()
 z_index=100
func release_all():
 for action in held: Input.action_release(action)
 held.clear()
 fingers.clear()
 stick_id=-1
 stick=Vector2.ZERO
func set_action(action:String, pressed:bool):
 if pressed:
  if not held.has(action): Input.action_press(action)
  held[action]=true
 elif held.has(action):
  Input.action_release(action)
  held.erase(action)
func update_stick(pos:Vector2):
 stick=(pos-STICK).limit_length(78)
 set_action("move_left",stick.x < -22)
 set_action("move_right",stick.x > 22)
 set_action("lane_up",stick.y < -30)
 set_action("lane_down",stick.y > 30)
func skill_rect(slot:int)->Rect2:
 return Rect2(100+slot*310,714,300,94)
func _notification(what):
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
  release_all()
  if enabled and is_instance_valid(game) and game.mode in ["playing","level_intro","stage_clear"]:
   game.paused_mode=game.mode
   game.mode="paused"
func _process(_dt):
 if not enabled: return
 if game.mode!=last_mode or game.help_open:
  release_all()
  last_mode=game.mode
 queue_redraw()
func _input(event):
 if not enabled: return
 if event is InputEventScreenTouch:
  touch(event.index,event.position,event.pressed and not event.canceled)
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag:
  if event.index==stick_id: update_stick(event.position)
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  touch(-99,event.position,event.pressed)
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and stick_id==-99:
  update_stick(event.position)
  get_viewport().set_input_as_handled()
func touch(index:int,pos:Vector2,pressed:bool):
 if not pressed:
  var action=fingers.get(index,"")
  fingers.erase(index)
  if index==stick_id:
   stick_id=-1
   stick=Vector2.ZERO
   for key in ["move_left","move_right","lane_up","lane_down"]: set_action(key,false)
  elif not action.is_empty() and not fingers.values().has(action): set_action(action,false)
  return
 if game.help_open:
  game.help_open=false
  return
 if game.mode!="playing":
  release_all()
  if game.mode=="reward":
   for i in range(game.run.choices.size()):
    if game.reward_rect(i).has_point(pos): game.run.choose(i); return
   return
  if game.mode=="interlude": game.run.advance_interlude(); return
  var event=InputEventAction.new()
  event.action="begin"
  event.pressed=true
  game._unhandled_input(event)
  return
 if Rect2(26,150,108,72).has_point(pos):
  release_all()
  game.paused_mode="playing"
  game.mode="paused"
  return
 if pos.distance_to(STICK)<125 and stick_id<0:
  stick_id=index
  fingers[index]="stick"
  update_stick(pos)
  return
 var action=""
 for key in BUTTONS:
  var b:Vector3=BUTTONS[key]
  if pos.distance_to(Vector2(b.x,b.y))<=b.z: action=key; break
 for slot in range(4):
  if skill_rect(slot).has_point(pos): action=SPELLS[slot]
 if not action.is_empty():
  fingers[index]=action
  set_action(action,true)
func _draw():
 if not enabled or not is_instance_valid(game): return
 var ink=Color("302b28")
 var paper=Color("f1e9d7")
 var font=ThemeDB.fallback_font
 if game.mode!="playing":
  if game.mode not in ["reward","level_intro","stage_clear"]:
   draw_style_box(panel(),Rect2(1090,635,310,70))
   draw_string(font,Vector2(1110,680),Texts.ui("touch_continue"),HORIZONTAL_ALIGNMENT_LEFT,280,24,ink)
  return
 draw_style_box(panel(),Rect2(26,150,108,72))
 draw_string(font,Vector2(44,195),Texts.ui("touch_pause"),HORIZONTAL_ALIGNMENT_LEFT,94,22,ink)
 draw_circle(STICK,96,Color(paper,0.83))
 draw_arc(STICK,96,0,TAU,48,ink,3,true)
 for v in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:
  var tip=STICK+v*70
  draw_line(tip-v*20+v.orthogonal()*10,tip,ink,3,true)
  draw_line(tip-v*20-v.orthogonal()*10,tip,ink,3,true)
 draw_circle(STICK+stick,31,Color("785c3d"))
 for key in BUTTONS:
  var b:Vector3=BUTTONS[key]
  var center=Vector2(b.x,b.y)
  draw_circle(center,b.z,Color("d6b27a") if held.has(key) else Color(paper,0.9))
  draw_arc(center,b.z,0,TAU,40,ink,3,true)
  draw_string(font,center+Vector2(-b.z+5,8),Texts.ui("touch_"+key),HORIZONTAL_ALIGNMENT_CENTER,b.z*2-10,24 if key=="attack" else 21,ink)
 draw_rect(Rect2(0,710,1440,100),paper)
 for slot in range(4):
  var rect=skill_rect(slot)
  var progress=game.run.cooldown_progress(slot)
  var affordable=game.run.mana>=game.run.cost(slot)
  draw_style_box(panel(),rect.grow(-3))
  draw_rect(Rect2(rect.position+Vector2(4,rect.size.y*(1-progress)),Vector2(rect.size.x-8,(rect.size.y-4)*progress)),Color("d4d0c7") if not affordable else Color("d6b27a") if slot!=2 else Color("b2d0c7"))
  game.overlay._skill_icon_for_touch(self,Rect2(rect.position+Vector2(10,14),Vector2(60,60)),slot,progress if progress<1 or affordable else 0.0)
  draw_string(font,rect.position+Vector2(79,37),game.run.skill_name(slot),HORIZONTAL_ALIGNMENT_LEFT,215,22,ink)
  var label=Texts.ui("1f_s") % game.run.skill_cd[slot] if progress<1 else Texts.ui("d_mana") % int(game.run.cost(slot))
  draw_string(font,rect.position+Vector2(79,72),label,HORIZONTAL_ALIGNMENT_LEFT,215,24,ink)
func panel()->StyleBoxFlat:
 var style=StyleBoxFlat.new()
 style.bg_color=Color("f1e9d7")
 style.border_color=Color("302b28")
 style.set_border_width_all(2)
 style.set_corner_radius_all(8)
 return style

extends RefCounted
const Texts=preload("res://scripts/text_data.gd")
## Gameplay adaptation of the report's magical-cycle stabilization, not time travel.
var charge: Array[float]=[]
var pulse_serial: int=0
func reset(count: int) -> void:
 charge.clear()
 for i in range(count): charge.append(0.0)
 pulse_serial=0
func completed(rule: Dictionary) -> int:
 return charge.filter(func(value): return value>=float(rule.charge_seconds)).size()
func warning(rule: Dictionary,time: float) -> bool:
 return fposmod(time,float(rule.pulse_interval))>=float(rule.pulse_interval)-float(rule.pulse_warning)
func pulse_lane(rule: Dictionary,time: float) -> int:
 return int(floor(time/float(rule.pulse_interval)))%3
func tick(run,dt: float) -> void:
 var rule: Dictionary=run.current_rule().synchronization
 var game=run.game
 var serial=int(floor(run.room_time/float(rule.pulse_interval)))
 if serial>pulse_serial:
  var lane=(serial-1)%3
  if game.player.lane==lane:
   game.damage_player(float(rule.pulse_damage),1)
  game.effects.append({"kind":"ring","x":game.player.x,"y":game.LANES[lane]-5,"life":0.35,"max":0.35,"color":Color("a55b65")})
  pulse_serial=serial
 if not game.player.alive(): return
 for i in range(rule.sigils.size()):
  var sigil: Dictionary=rule.sigils[i]
  if charge[i]>=float(rule.charge_seconds): continue
  if game.player.lane==int(sigil.lane) and absf(game.player.y-game.LANES[int(sigil.lane)])<18 and absf(game.player.x-float(sigil.x))<=float(rule.radius):
   charge[i]=minf(float(rule.charge_seconds),charge[i]+dt)

func draw_ground(canvas,run) -> void:
 var game=run.game
 var rule: Dictionary=run.current_rule().synchronization
 var dangerous=warning(rule,run.room_time)
 if dangerous:
  var lane=pulse_lane(rule,run.room_time)
  var y: float=game.LANES[lane]
  var x: float=game.stage_left-game.camera_x
  canvas.draw_rect(Rect2(x,y-20,game.stage_right-game.stage_left,37),Color(0.65,0.25,0.3,0.12))
  for i in range(35):
   var mark=x+i*55
   canvas.draw_line(Vector2(mark,y-17),Vector2(mark+25,y+15),Color(0.65,0.25,0.3,0.48),2,true)
 for i in range(rule.sigils.size()):
  var sigil: Dictionary=rule.sigils[i]
  var center=Vector2(float(sigil.x)-game.camera_x,game.LANES[int(sigil.lane)]+3)
  var progress=charge[i]/float(rule.charge_seconds)
  var color=Color("3c7d7a") if progress>=1 else Color("a87938") if progress>0 else Color("655c72")
  var outline=PackedVector2Array()
  var filling=PackedVector2Array()
  for j in range(65):
   var angle=TAU*j/64
   var point=center+Vector2(cos(angle)*float(rule.radius),sin(angle)*26)
   outline.append(point)
   if float(j)/64<=progress: filling.append(point)
  canvas.draw_colored_polygon(outline,Color("f5eddc"))
  canvas.draw_polyline(outline,color,4,true)
  if filling.size()>1: canvas.draw_polyline(filling,color,5,true)
  canvas.draw_polyline(PackedVector2Array([center+Vector2(-28,0),center+Vector2(0,-10),center+Vector2(28,0),center+Vector2(0,10),center+Vector2(-28,0)]),color,1.5,true)
  canvas._center(center+Vector2(0,-8),str(i+1),24,color)
  # Paper label sits beside the zone, clear of the hero and spell aura.
  var label=center+Vector2(185,-35)
  canvas.draw_line(label+Vector2(-94,15),center+Vector2(90,0),Color(color,0.55),2,true)
  canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(-10,-43),center+Vector2(10,-43),center+Vector2(0,-29)]),color)
  canvas.draw_rect(Rect2(label-Vector2(94,27),Vector2(188,63)),Color("f5eddc"))
  canvas.draw_rect(Rect2(label-Vector2(94,27),Vector2(188,63)),color,false,2)
  var caption=Texts.ui("sync_done") if progress>=1 else Texts.ui("sync_stand_here")
  canvas._center(label,str(i+1)+" · "+caption,18,color)
  canvas.draw_rect(Rect2(label+Vector2(-78,12),Vector2(156,8)),Color(color,0.18))
  canvas.draw_rect(Rect2(label+Vector2(-78,12),Vector2(156*progress,8)),color)


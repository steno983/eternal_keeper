extends RefCounted
## Ink silhouettes and colored pencil accents. Rendering never mutates combat or RNG.
const Sprites=preload("res://scripts/magic_bank.gd")
const INK=Color("392c27")
const EMBER=Color("b94824")
const FIRE=Color("e18c2d")
const LIGHT=Color("ffe5a4")
const GOLD=Color("c39745")
const HEAL=Color("398071")

static func ellipse_line(p, pos: Vector2, radius: Vector2, col: Color, width: float=1.5, start: float=0, end: float=TAU) -> void:
 var points=PackedVector2Array()
 for i in range(65):
  var a=lerpf(start,end,i/64.0)
  points.append(pos+Vector2(cos(a),sin(a))*radius)
 p.draw_polyline(points,col,width,true)

static func glyph(p, pos: Vector2, size: float, col: Color, variant: int=0) -> void:
 var points=[Vector2(-0.5,0.7),Vector2(0,-0.8),Vector2(0.5,0.7)]
 if variant%3==1: points=[Vector2(-0.5,-0.6),Vector2(0.5,-0.6),Vector2(-0.4,0.6),Vector2(0.4,0.6)]
 if variant%3==2: points=[Vector2(0,-0.8),Vector2(-0.5,0),Vector2(0,0.7),Vector2(0.5,0),Vector2(0,-0.8)]
 var line=PackedVector2Array()
 for point in points: line.append(pos+point*size)
 p.draw_polyline(line,col,1.6,true)
 if variant%3==0: p.draw_line(pos+Vector2(-size*0.4,0.1*size),pos+Vector2(size*0.4,0.1*size),col,1.2,true)

static func book(p, pos: Vector2, size: float, col: Color) -> void:
 var points=PackedVector2Array([pos+Vector2(-size,-size*0.6),pos+Vector2(0,-size*0.4),pos+Vector2(size,-size*0.6),pos+Vector2(size,size*0.6),pos+Vector2(0,size*0.8),pos+Vector2(-size,size*0.6),pos+Vector2(-size,-size*0.6)])
 p.draw_polyline(points,Color(INK,col.a),3.8,true)
 p.draw_polyline(points,col,2.0,true)
 p.draw_line(pos+Vector2(0,-size*0.4),pos+Vector2(0,size*0.8),col,1.5,true)
 for side in [-1,1]:
  for i in range(2):
   p.draw_line(pos+Vector2(side*size*0.24,-size*0.08+i*size*0.35),pos+Vector2(side*size*0.78,-size*0.18+i*size*0.35),col,1.0,true)

static func flame(p, base: Vector2, width: float, height: float, phase: float, opacity: float=1.0, birth_age: float=-1.0) -> void:
 if opacity<0.015: return
 var image=Sprites.texture("flame",0.0 if p.game.reduced_motion else phase/6.0) if birth_age<0 else Sprites.growing("flame",birth_age,p.game.reduced_motion,fposmod((base.x+p.game.camera_x)*0.013,0.65))
 Sprites.stamp(p,image,base,Vector2(width*2,height),Vector2(0.5,0.9375),Color(1,1,1,opacity))

static func sigil(p, pos: Vector2, radius: float, opacity: float, healing: bool=false, phase: float=0.0, ash: bool=false) -> void:
 var col=HEAL if healing else EMBER
 p._ellipse(pos,Vector2(radius,29),Color(col,opacity*0.11))
 ellipse_line(p,pos,Vector2(radius,29),Color(INK,opacity*0.68),3.2)
 ellipse_line(p,pos,Vector2(radius-5,26),Color(col,opacity*0.95),2.6)
 ellipse_line(p,pos,Vector2(radius*0.76,19),Color(GOLD,opacity*0.8),1.5)
 for i in range(10):
  var angle=i*TAU/10.0
  var spot=pos+Vector2(cos(angle)*radius*0.87,sin(angle)*23)
  glyph(p,spot,5.5,Color(col,opacity*0.90),i)
 for i in range(6):
  var x=(i/5.0-0.5)*radius*1.6
  p.draw_line(pos+Vector2(x-9,-6),pos+Vector2(x+5,7),Color(col,opacity*0.25),1.2,true)
 if ash:
  for i in range(12):
   var x=sin(i*2.7)*radius
   p.draw_line(pos+Vector2(x,-14),pos+Vector2(x+11,-24),Color(INK,opacity*0.34),1.5,true)
 if healing: book(p,pos+Vector2(0,-2),11,Color(HEAL,opacity))
 else: glyph(p,pos+Vector2(0,-2),15,Color(col,opacity),2)

static func ground(p) -> void:
 for zone in p.game.run.zones:
  var elapsed: float=zone.max-zone.life
  var opacity=minf(1.0,zone.life/0.35)
  var pos=Vector2(zone.x-p.game.camera_x,p.game.LANES[zone.lane])
  sigil(p,pos,zone.radius,opacity,zone.healing,elapsed,zone.get("variant","")=="ash")
  # A fine inner clock reads remaining duration, rather than flashing the whole zone.
  ellipse_line(p,pos,Vector2(zone.radius+5,32),Color(GOLD,opacity*0.85),2,-PI/2,-PI/2+TAU*zone.life/zone.max)
 # Anticipation is attached to the actual pending action and disappears on cancel.
 var run=p.game.run
 if run.cast_slot==1 and p.game.player.action_active() and p.game.player.action==&"special" and p.game.player.action_elapsed<0.20:
  var x=clampf(p.game.player.x+p.game.player.facing*210,p.game.stage_left+30,p.game.stage_right-30)
  ellipse_line(p,Vector2(x-p.game.camera_x,p.game.LANES[p.game.player.lane]),Vector2(185 if run.mods[1]=="ash" else 190 if run.mods[1]=="eruption" else 135,29),Color(EMBER,0.75),1.5)

static func projectile(p, bolt: Dictionary) -> void:
 var pos=Vector2(bolt.x-p.game.camera_x,bolt.y)
 var direction=signf(bolt.vx)
 var elapsed: float=2.6-bolt.life
 for i in range(bolt.trail.size()-1):
  var strength=1.0-i/8.0
  p.draw_line(bolt.trail[i]-Vector2(p.game.camera_x,0),bolt.trail[i+1]-Vector2(p.game.camera_x,0),Color(GOLD,strength*0.50),6*strength,true)
 var size=Vector2(170,60) if bolt.spell=="pierce" else Vector2(134,112) if bolt.spell=="orb" else Vector2(142,78)
 Sprites.stamp(p,Sprites.texture("projectile",0.0 if p.game.reduced_motion else elapsed),pos,size,Vector2(0.922,0.5),Color.WHITE,direction)
 if bolt.spell=="pierce":
  p.draw_line(pos-Vector2(direction*126,0),pos-Vector2(direction*9,0),Color(LIGHT,0.9),2,true)

static func ongoing(p) -> void:
 for zone in p.game.run.zones:
  var elapsed: float=zone.max-zone.life
  var phase=elapsed*6 if not p.game.reduced_motion else 0.0
  var alpha=minf(1.0,zone.life/0.35)
  var base=Vector2(zone.x-p.game.camera_x,p.game.LANES[zone.lane])
  for i in range(5):
   var x=(i/4.0-0.5)*zone.radius*1.45
   var h=30+sin(i*3.7+phase)*5
   flame(p,base+Vector2(x,-3),35,115,phase+i,alpha*0.92,maxf(0,elapsed-i*0.025))
  if zone.healing:
   for i in range(3):
    var lift=18.0 if p.game.reduced_motion else fposmod(elapsed*21+i*19,62)
    var pos=base+Vector2((i-1)*zone.radius*0.48,-20-lift)
    p.draw_line(pos-Vector2(4,0),pos+Vector2(4,0),Color(HEAL,alpha*0.9),2,true)
    p.draw_line(pos-Vector2(0,4),pos+Vector2(0,4),Color(HEAL,alpha*0.9),2,true)
 var run=p.game.run
 if run.buff_time<=0: return
 var mod: String=run.mods[2]
 if mod=="aegis" and run.barrier<=0: return
 var alpha=minf(1.0,run.buff_time/0.4)
 var base=Vector2(p.game.player.x-p.game.camera_x,p.game.player.y)
 var col=HEAL if mod=="renewal" else GOLD
 var elapsed: float=run.buff_duration-run.buff_time
 var tint=Color(0.67,1.0,0.90,alpha*0.87) if mod=="renewal" else Color(0.90,0.97,1.0,alpha*0.90) if mod=="aegis" else Color(1,1,1,alpha*0.88)
 Sprites.stamp(p,Sprites.growing("aura",elapsed,p.game.reduced_motion),base,Vector2(252,310),Vector2(0.5,0.9375),tint)
 if elapsed>Sprites.BIRTH_DURATION:
  book(p,base+Vector2(0,-277),11,Color(col,alpha*0.9))
 if mod=="renewal":
  for i in range(3):
   var lift=30.0 if p.game.reduced_motion else fposmod(elapsed*25+i*40,120)
   var pos=base+Vector2((i-1)*38,-30-lift)
   p.draw_line(pos-Vector2(4,0),pos+Vector2(4,0),Color(HEAL,alpha),2,true)
   p.draw_line(pos-Vector2(0,4),pos+Vector2(0,4),Color(HEAL,alpha),2,true)

static func effect(p, fx: Dictionary) -> void:
 var pos=Vector2(fx.x-p.game.camera_x,fx.y)
 var remaining=clampf(fx.life/fx.max,0,1)
 var age: float=fx.max-fx.life
 var alpha=minf(1.0,fx.life/0.20)
 var progress=0.6 if p.game.reduced_motion else clampf(age/fx.max,0,1)
 match fx.kind:
  "spell_cast":
   if fx.serial!=p.game.player.action_serial: return
   var col=GOLD if fx.slot==2 else EMBER
   var r=20.0 if p.game.reduced_motion else 15+progress*23
   ellipse_line(p,pos,Vector2(r,r),Color(INK,remaining*0.7),3)
   ellipse_line(p,pos,Vector2(r-3,r-3),Color(col,remaining),2)
   for i in range(4):
    var angle=i*PI/2+0.6
    var axis=Vector2(cos(angle),sin(angle))
    p.draw_line(pos+axis*r,pos+axis*(r+8),Color(col,remaining),2,true)
  "fire_hit":
   var radius: float=fx.get("radius",36.0)
   var image=Sprites.texture("impact",age,8.0/fx.max)
   Sprites.stamp(p,image,pos,Vector2(maxf(85,radius*2),maxf(95,radius*1.65)),Vector2(0.5,0.5),Color(1,1,1,alpha))
  "eruption":
   sigil(p,pos,fx.radius,alpha,false,age)
   for i in range(7):
    var x=(i/6.0-0.5)*fx.radius*1.6
    var h=(90+55*sin(i*1.9+0.4))*(1.0 if p.game.reduced_motion else 0.75+sin(minf(age/0.6,1)*PI)*0.25)
    flame(p,pos+Vector2(x,0),49,210+sin(i*1.9)*25,i+age*4,alpha*0.92,maxf(0,age-i*0.014))
    p.draw_line(pos+Vector2(x,-3),pos+Vector2(x+18,12),Color(INK,alpha*0.6),1.5,true)
  "holy_wave":
   var direction: float=fx.facing
   var reach: float=fx.get("reach",620.0)
   p._ellipse(pos+Vector2(direction*reach*0.5,0),Vector2(reach*0.5,24),Color(EMBER,alpha*0.12))
   for i in range(7):
    var x=direction*(32+(reach-55)*i/6.0)
    var h=95+sin(i*1.6+0.4)*27
    flame(p,pos+Vector2(x,0),55,215+sin(i*1.6)*20,i+age*7,alpha*0.92,maxf(0,age-i*0.018))
    glyph(p,pos+Vector2(x,8),9,Color(GOLD,alpha),i)
   p.draw_line(pos+Vector2(direction*20,0),pos+Vector2(direction*reach,0),Color(INK,alpha*0.65),3,true)
   p.draw_line(pos+Vector2(direction*20,-2),pos+Vector2(direction*reach,-2),Color(FIRE,alpha*0.9),2,true)
  "nova":
   var radius: float=fx.radius
   for lane in range(3):
    ellipse_line(p,Vector2(pos.x,p.game.LANES[lane]),Vector2(radius,27),Color(GOLD,alpha*0.5),1.5)
   Sprites.stamp(p,Sprites.texture("impact",age,8.0/fx.max),pos+Vector2(0,-70),Vector2(radius*2,360),Vector2(0.5,0.5),Color(1,1,1,alpha*0.9))
  "ward_hit":
   # Hand-drawn aura flecks on contact; the persistent ward uses its own birth loop.
   var variant: String=fx.get("variant","")
   for i in range(6):
    var axis=Vector2.from_angle(-PI*0.8+i*PI/6)
    var point=pos+axis*(45+progress*35)
    p._splatter(point,4.5,Color(GOLD,alpha*0.75),i+3)
   if variant=="mirror":
    Sprites.stamp(p,Sprites.texture("impact",age,8.0/fx.max),pos,Vector2(170,145),Vector2(0.5,0.5),Color(1,0.95,0.8,alpha*0.75))

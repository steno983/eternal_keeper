extends RefCounted
## Code-native ink and metal bolt, independent of spell sprites and damage rules.
const INK=Color("302b28")
const PAPER=Color("fbf5e8")
const FLETCH=Color("b7654d")

static func projectile(p, bolt: Dictionary) -> void:
 var pos=Vector2(bolt.x-p.game.camera_x,bolt.y)
 var axis=Vector2(signf(bolt.vx),0)
 var normal=Vector2(0,1)
 # A short tapered wake remains legible against detailed pencil architecture.
 for i in range(bolt.trail.size()-1):
  var a: Vector2=bolt.trail[i]-Vector2(p.game.camera_x,0)
  var b: Vector2=bolt.trail[i+1]-Vector2(p.game.camera_x,0)
  var strength=1.0-float(i)/maxi(1,bolt.trail.size())
  p.draw_line(a,b,Color(INK,0.28*strength),5.5*strength,true)
  p.draw_line(a,b,Color(PAPER,0.85*strength),2.5*strength,true)
  p.draw_line(a-normal*1.7,b-normal*1.7,Color(FLETCH,0.5*strength),1,true)
 p.draw_line(pos-axis*34,pos+axis*3,INK,4,true)
 p.draw_line(pos-axis*32-normal*0.6,pos+axis*2-normal*0.6,PAPER,1.2,true)
 for side in [-1,1]:
  var fin=PackedVector2Array([pos-axis*34+normal*side*5,pos-axis*24+normal*side*5,pos-axis*18,pos-axis*28])
  p.draw_colored_polygon(fin,INK)
  p.draw_line(pos-axis*32+normal*side*3.7,pos-axis*24+normal*side*3.7,FLETCH,2.2,true)
 var head=PackedVector2Array([pos+axis*14,pos-axis*1+normal*5,pos+axis*2,pos-axis*1-normal*5])
 p.draw_colored_polygon(head,INK)
 p.draw_colored_polygon(PackedVector2Array([pos+axis*10,pos+axis*1-normal*2.6,pos+axis*3]),PAPER)

static func release(p, fx: Dictionary) -> void:
 var pos=Vector2(fx.x-p.game.camera_x,fx.y)
 var age: float=1-fx.life/fx.max
 var axis=Vector2(fx.facing,0)
 for i in range(5):
  var drift=Vector2(fx.facing*(5+i*2.5),float(i-2)*3)
  var center=pos+drift*age
  p.draw_line(center-axis*3,center+axis*2,Color(PAPER,(1-age)*0.85),3,true)
  p.draw_line(center-axis*2,center+axis*2,Color(INK,(1-age)*0.65),1,true)

extends Node2D
## Independent scenery planes. Actors and ability effects never inherit this material.
const PAPER=Color("f1e9d7")
const INK=Color("363636")
var game
var foreground_pass: bool=false
var textures: Dictionary={}
var shader_path: String=""

func texture(path: String) -> Texture2D:
 if not textures.has(path): textures[path]=load(path)
 return textures[path]

func _process(_dt: float) -> void:
 visible=game.campaign
 if visible: queue_redraw()

func rect(values: Array) -> Rect2:
 return Rect2(float(values[0]),float(values[1]),float(values[2]),float(values[3]))

func anchors(layer: Dictionary) -> Array:
 var result: Array=[]
 if not layer.has("repeat_step"): return layer.anchors
 var step: float=layer.repeat_step
 for anchor in layer.anchors:
  var first=floori((game.camera_x*float(layer.depth)-float(anchor))/step)-1
  for i in range(first,first+4): result.append(float(anchor)+i*step)
 return result

func _draw() -> void:
 if not game or not game.campaign: return
 var environment: Dictionary=game.run.content.environment(game.wave-1)
 if environment.is_empty(): return
 if shader_path!=environment.shader:
  shader_path=environment.shader
  var graphite=ShaderMaterial.new()
  graphite.shader=load(shader_path)
  material=graphite
 var zoom: float=1.0 if game.mode=="title" else game.WORLD_ZOOM
 var strength: float=0.0 if game.reduced_motion else game.trauma*game.trauma*30
 var shake=Vector2(sin(game.time*73),sin(game.time*91))*strength
 draw_set_transform(game.CAMERA_PIVOT*(1-zoom)+shake*zoom,0,Vector2.ONE*zoom)
 for layer in environment.layers:
  if bool(layer.get("foreground",false))!=foreground_pass: continue
  var art=texture(layer.texture)
  var shift=Vector2(-game.camera_x*float(layer.depth),0)
  var tint=Color(1,1,1,float(layer.get("alpha",1)))
  match layer.kind:
   "texture":
    var target=rect(layer.rect)
    target.position+=shift
    if layer.get("repeat_x",false):
     for i in range(-1,3):
      var tile=target
      tile.position.x+=i*target.size.x
      draw_texture_rect(art,tile,false,tint)
    else: draw_texture_rect(art,target,false,tint)
   "pillars":
    for anchor in anchors(layer):
     var target=rect(layer.rect)
     target.position+=Vector2(float(anchor),0)+shift
     draw_texture_rect_region(art,target,rect(layer.region),tint)
   "tiles":
    for tile in range(int(layer.tiles[0]),maxi(int(layer.tiles[1]),ceili(game.stage_right/float(layer.rect[2]))+2)):
     var target=rect(layer.rect)
     target.position+=Vector2(tile*target.size.x,0)+shift
     draw_texture_rect(art,target,false,tint)
   "arches":
    for anchor in anchors(layer):
     var x: float=float(anchor)+shift.x
     draw_texture_rect_region(art,Rect2(x-48,58,96,384),rect(layer.region),Color(1,1,1,0.34))
     var arch=PackedVector2Array()
     for i in range(49):
      var angle=PI+float(i)*PI/48
      arch.append(Vector2(x+430+cos(angle)*413,140+sin(angle)*120))
     draw_polyline(arch,Color(INK,0.24),3,true)
     var outer=PackedVector2Array()
     for point in arch: outer.append(point+Vector2(0,-13))
     draw_polyline(outer,Color(INK,0.15),1.2,true)

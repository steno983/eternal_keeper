extends RefCounted
## Eight authored drawings per sequence, sampled only from simulation time.
static var _bank: SpriteFrames
const BIRTH_DURATION=8.0/18.0
static func library() -> SpriteFrames:
 if _bank!=null: return _bank
 _bank=SpriteFrames.new()
 _bank.remove_animation(&"default")
 for key in ["aura","aura_birth","flame","flame_birth","projectile","impact"]:
  var texture: Texture2D=load("res://assets/magic/%s.png" % key)
  _bank.add_animation(key)
  _bank.set_animation_speed(key,18 if key.ends_with("birth") else 12)
  _bank.set_animation_loop(key,not key.ends_with("birth") and key!="impact")
  var size=Vector2(texture.get_size())/Vector2(4,2)
  for i in range(8):
   var frame=AtlasTexture.new()
   frame.atlas=texture
   frame.region=Rect2(Vector2(i%4,i/4)*size,size)
   _bank.add_frame(key,frame)
 return _bank
static func index(key: String, clock: float, fps: float=-1.0) -> int:
 var frames=library()
 var rate=frames.get_animation_speed(key) if fps<0 else fps
 var sample=maxi(0,int(clock*rate))
 return sample%8 if frames.get_animation_loop(key) else mini(7,sample)
static func texture(key: String, clock: float, fps: float=-1.0) -> Texture2D:
 return library().get_frame_texture(key,index(key,clock,fps))
static func growing(key: String, elapsed: float, reduced_motion: bool=false, loop_offset: float=0.0) -> Texture2D:
 if elapsed<BIRTH_DURATION: return texture(key+"_birth",maxf(0,elapsed))
 return texture(key,0.0 if reduced_motion else elapsed-BIRTH_DURATION+loop_offset)
static func stamp(p, image: Texture2D, pos: Vector2, size: Vector2, pivot: Vector2=Vector2(0.5,0.9375), tint: Color=Color.WHITE, facing: float=1.0) -> void:
 p._world_transform(pos+p.shake,0,Vector2(facing,1))
 p.draw_texture_rect(image,Rect2(-pivot*size,size),false,tint)
 p._world_transform(p.shake)

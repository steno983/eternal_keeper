extends SceneTree
var game
var failures: int=0
var checks: int=0
func _initialize() -> void: call_deferred("verify")
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error(label)
func capture(label: String) -> Image:
 game.archive_backdrop.queue_redraw()
 game.archive_foreground.queue_redraw()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var frame=root.get_texture().get_image()
 frame.save_png("res://artifacts/orologio-parallax-"+label+".png")
 return frame
func verify() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.start_game(true)
 game.run.prologue_seen=true
 game.run.intro_done=true
 game.run.before_seen[3]=true
 game.wave=3
 game.run.begin_room()
 game.run.finish_entrance()
 game.reduced_motion=true
 game.painter.visible=false
 game.overlay.visible=false
 game.actor_layer.visible=false
 game.archive_foreground.visible=false
 game.archive_foreground.set_process(false)
 var environment: Dictionary=game.run.content.environment(3)
 check(environment.layers.size()==4,"New scenery uses four independent planes")
 check(environment.layers.map(func(l): return l.depth)==[0.12,0.48,1.0,1.22],"Depth ratios distinguish background, architecture, floor and foreground")
 check(environment.layers.all(func(l): return l.texture.begins_with("res://assets/orologio/")),"All four new environment planes use newly generated art")
 game.camera_x=0
 var left=await capture("left")
 game.camera_x=300
 var right=await capture("right")
 var chroma_errors=0
 for y in range(15,left.get_height()-15,13):
  for x in range(15,left.get_width()-15,13):
   var c=left.get_pixel(x,y)
   if absf((c.r-c.g)-0.3077*(c.r-c.b))>0.012 or c.g>c.r+0.005 or c.b>c.g+0.005: chroma_errors+=1
 check(chroma_errors==0,"New catacombs remain graphite on parchment")
 var error: float=0
 var count: int=0
 var shift=300.0*game.WORLD_ZOOM*left.get_width()/1440.0
 for y in range(int(left.get_height()*0.65),int(left.get_height()*0.82),9):
  for x in range(30,left.get_width()-int(ceil(shift))-30,11):
   var a=left.get_pixel(x+int(floor(shift)),y).lerp(left.get_pixel(x+int(ceil(shift)),y),fposmod(shift,1))
   error+=absf(a.r-right.get_pixel(x,y).r)
   count+=1
 check(error/maxi(1,count)<0.03,"Actual floor pixels track the camera independently of distant scenery")
 game.camera_x=0
 game.archive_foreground.visible=true
 var foreground=await capture("foreground-left")
 var occluded=0
 for y in range(150,left.get_height()-100,11):
  for x in range(0,200,7):
   if absf(left.get_pixel(x,y).r-foreground.get_pixel(x,y).r)>0.03: occluded+=1
 check(occluded>20,"Transparent foreground pillar really occludes the scene at the near edge")
 game.archive_foreground.visible=false
 game.camera_x=4300
 var far=await capture("far-corridor")
 var textured=0
 var samples=0
 for y in range(int(far.get_height()*0.65),int(far.get_height()*0.82),9):
  for x in range(15,far.get_width()-15,13):
   if absf(far.get_pixel(x,y).r-0.9451)>0.04: textured+=1
   samples+=1
 check(textured>samples*0.3,"Ground remains textured beyond four thousand units of camera travel")
 print("OROLOGIO SCENERY: %d/%d passed; floor tracking error %.4f" % [checks-failures,checks,error/maxi(1,count)])
 left=null
 right=null
 foreground=null
 far=null
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

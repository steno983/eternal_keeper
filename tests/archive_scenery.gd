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
 game._process(0)
 game.painter.queue_redraw()
 game.overlay.queue_redraw()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var frame=root.get_texture().get_image()
 frame.save_png("res://artifacts/scenery-"+label+".png")
 return frame
func verify() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.start_game(true)
 game.run.finish_prologue()
 game.run.show_rewards()
 game.run.finish_entrance() # Skip presentation in this mechanics test.
 game.run.show_rewards()
 game.run.finish_entrance() # Skip presentation in this mechanics test.
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 game.run.finish_room()
 game.run.finish_stage_clear() # Presentation is covered independently.
 game.run.show_rewards() # Enter the real second room before presentation-only camera samples.
 game.run.finish_entrance() # Skip presentation in this mechanics test.
 game.player.x=900
 game.player.previous_x=900
 game.reduced_motion=true
 game.painter.visible=false
 game.actor_layer.visible=false
 game.overlay.visible=false
 game.archive_foreground.visible=false
 game.archive_foreground.set_process(false)
 game.camera_x=0
 var left=await capture("planes-left")
 game.camera_x=300
 var right=await capture("planes-right")
 var chroma_errors=0
 for y in range(15,left.get_height()-15,13):
  for x in range(15,left.get_width()-15,13):
   var c=left.get_pixel(x,y)
   # All shades must lie on the graphite-to-paper line, with no source teal/gold.
   if absf((c.r-c.g)-0.3077*(c.r-c.b))>0.012 or c.g>c.r+0.005 or c.b>c.g+0.005:
    chroma_errors+=1
 check(chroma_errors==0,"Entire scenery is monochrome graphite on paper")
 var error: float=0
 var samples: int=0
 # Ground must follow 100% camera motion, unlike the distant plate.
 var shift=300.0*game.WORLD_ZOOM*left.get_width()/1440.0
 for y in range(int(left.get_height()*0.65),int(left.get_height()*0.82),9):
  for x in range(30,left.get_width()-int(ceil(shift))-30,11):
   var a=left.get_pixel(x+int(floor(shift)),y).lerp(left.get_pixel(x+int(ceil(shift)),y),fposmod(shift,1))
   var b=right.get_pixel(x,y)
   error+=absf(a.r-b.r)
   samples+=1
 check(error/maxi(1,samples)<0.03,"Rendered floor tracks camera independently of distant scenery")
 var layers=game.run.content.environment(game.wave-1).layers
 check(layers[0].depth<layers[1].depth and layers[1].depth<layers[2].depth and layers[3].depth>layers[2].depth,"Four distinct depth planes loaded from environment JSON")
 check(game.actor_layer.material==null and game.overlay.material==null,"Heroes and spell effects are outside the graphite material")
 game.painter.visible=true
 game.actor_layer.visible=true
 game.overlay.visible=true
 game.archive_foreground.set_process(true)
 game.camera_x=0
 await capture("game-left")
 game.camera_x=300
 await capture("game-right")
 print("ARCHIVE SCENERY: %d/%d passed; floor sample error %.4f" % [checks-failures,checks,error/maxi(1,samples)])
 left=null
 right=null
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

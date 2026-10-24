extends SceneTree
var game
var checks=0
var failures=0
func _initialize(): call_deferred("verify")
func check(value,label):
 checks+=1
 if not value:
  failures+=1
  push_error(label)
func touch(index,pos,pressed):
 var e=InputEventScreenTouch.new()
 e.index=index
 e.position=pos
 e.pressed=pressed
 game.mobile_controls._input(e)
func capture(label):
 if DisplayServer.get_name()=="headless": return
 game._process(0)
 game.painter.queue_redraw()
 game.overlay.queue_redraw()
 game.mobile_controls.queue_redraw()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/mobile-"+label+".png")
func verify():
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 var ui=game.mobile_controls
 ui.enabled=true
 touch(0,Vector2(1200,670),true)
 check(game.mode=="selection","Touch opens selection")
 touch(0,Vector2(1200,670),false)
 touch(0,Vector2(1200,670),true)
 check(game.mode=="prologue","Touch starts the campaign")
 touch(0,Vector2(1200,670),false)
 touch(0,Vector2(1200,670),true)
 check(game.mode=="interlude","Touch continues the prologue")
 touch(0,Vector2(1200,670),false)
 var before:int=game.run.interlude_revealed
 touch(0,Vector2(1200,670),true)
 check(game.run.interlude_revealed==before+1,"One tap advances exactly one balloon")
 game.run.intro_done=true
 game.run.prologue_seen=true
 game.run.before_seen[0]=true
 game.wave=0
 game.run.begin_room()
 game.run.finish_entrance()
 ui._process(0)
 game.player.invincible=100
 await capture("combat")
 touch(0,Vector2(230,590),true)
 check(Input.is_action_pressed("move_right"),"Stick holds horizontal movement")
 var x:float=game.player.x
 game._read_input(0.1)
 check(game.player.x>x,"Stick moves the real player")
 touch(1,Vector2(1310,605),true)
 check(Input.is_action_pressed("attack") and Input.is_action_pressed("move_right"),"Movement and attack work simultaneously")
 game._read_input(0.016)
 check(game.player.action==&"attack","Touch triggers the real melee action")
 touch(1,Vector2(1310,605),false)
 check(not Input.is_action_pressed("attack") and Input.is_action_pressed("move_right"),"Releasing attack leaves movement held")
 touch(0,Vector2(230,590),false)
 check(not Input.is_action_pressed("move_right"),"Finger release stops movement")
 game.player.begin_action(&"",0)
 game.attack_cd=0
 touch(2,ui.skill_rect(0).get_center(),true)
 game._read_input(0.016)
 check(game.run.skill_cd[0]>0,"Touch casts a real spell and starts cooldown")
 touch(2,Vector2.ZERO,false)
 game.player.begin_action(&"",0)
 touch(3,Vector2(165,520),true)
 game._read_input(0.016)
 check(game.player.lane==0,"Stick vertical tilt changes lane")
 touch(3,Vector2.ZERO,false)
 touch(4,Vector2(1155,620),true)
 touch(5,Vector2(1155,620),true)
 touch(4,Vector2.ZERO,false)
 check(Input.is_action_pressed("guard"),"Two fingers on one button retain the remaining finger")
 touch(5,Vector2.ZERO,false)
 check(not Input.is_action_pressed("guard"),"Last finger releases shared button")
 touch(6,Vector2(230,590),true)
 touch(7,Vector2(60,180),true)
 check(game.mode=="paused" and ui.held.is_empty() and not Input.is_action_pressed("move_right"),"Pause clears all touch actions")
 touch(7,Vector2.ZERO,false)
 touch(8,Vector2(1200,670),true)
 check(game.mode=="playing","Touch resumes pause")
 ui._process(0)
 touch(8,Vector2.ZERO,false)
 touch(9,Vector2(230,590),true)
 ui._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(game.mode=="paused" and ui.held.is_empty(),"App switch pauses and releases movement")
 game.mode="playing"
 ui._process(0)
 game.run.prepare_reward()
 game.mode="reward"
 ui._process(0)
 var id:String=game.run.choices[1].id
 await capture("reward")
 touch(10,game.reward_rect(1).get_center(),true)
 check(game.run.taken.back().id==id,"Touch selects the intended reward")
 print("MOBILE INPUT: %d/%d passed" % [checks-failures,checks])
 ui.release_all()
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

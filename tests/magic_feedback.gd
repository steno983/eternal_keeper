extends SceneTree
const Bank=preload("res://scripts/magic_bank.gd")
var checks=0
var failures=0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error(label)
func run_checks() -> void:
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_game()
 game.set_physics_process(false)
 var run=game.run
 check(run.level==9,"Light cleric starts with the domain's full demo kit at level 9")
 check(run.skill_name(0)=="Dardo tracciante" and run.skill_name(1)=="Muro di fuoco" and run.skill_name(2)=="Scudo della fede" and run.skill_name(3)=="Colpo infuocato","Recognizable 2024 spell names")
 var base=run.cooldown_for(1)
 run.level=10
 check(run.cooldown_for(1)<base,"Gaining a level shortens recharge")
 run.mods[1]="sanctuary"
 check(run.cooldown_for(1)>base,"Stronger mutation has explicit recharge tradeoff")
 run.buff_time=3
 var blessed=run.cooldown_for(1)
 run.buff_time=0
 check(run.cooldown_for(1)>blessed,"Active faith ward reduces other spell recharge at cast time")
 check(run.cast(1),"Mutated spell casts")
 var total: float=run.skill_cd_total[1]
 check(total==run.skill_cd[1] and run.cooldown_progress(1)==0,"Grey meter starts empty using the actual cast cooldown")
 run.skill_cd[1]=total*0.5
 check(is_equal_approx(run.cooldown_progress(1),0.5),"Color fill reaches half at half recharge")
 run.skill_cd[1]=0
 check(run.cooldown_progress(1)==1,"Ready icon fully colored")
 game.start_game()
 check(run.level==9,"New run resets level")
 game.enemies.clear()
 run.finish_room()
 run.show_rewards()
 run.choose(0)
 check(run.level==10 and run.taken.size()==1,"Room reward actually gains one level")
 var frames=Bank.library()
 for key in ["aura","aura_birth","flame","flame_birth","projectile","impact"]:
  check(frames.get_frame_count(key)==8,"Eight authored drawings: "+key)
  for i in range(8):
   var image=frames.get_frame_texture(key,i).get_image()
   check(image!=null and image.get_format()==Image.FORMAT_RGBA8,"Alpha sprite available: %s %d" % [key,i])
  check(Bank.index(key,0)==0,"Animation begins at first drawing: "+key)
 for key in ["aura","flame"]:
  var early=Bank.growing(key,0.01)
  check(early==frames.get_frame_texture(key+"_birth",0),"Starts from a drawn ground puddle: "+key)
  check(Bank.growing(key,0.20)==frames.get_frame_texture(key+"_birth",3),"Authored rising middle frame: "+key)
  check(Bank.growing(key,Bank.BIRTH_DURATION+0.01)==frames.get_frame_texture(key,0),"Startup transitions into loop: "+key)
  check(Bank.growing(key,2.0,true)==frames.get_frame_texture(key,0),"Reduced motion holds the established aura/flame steady: "+key)
 var report=JSON.parse_string(FileAccess.get_file_as_string("res://assets/magic/report.json"))
 for key in ["aura_birth","flame_birth"]:
  check(report[key].heights[0]<report[key].heights[7]*0.35,"Startup art grows in height, not full-size opacity: "+key)
 for i in range(4):
  check(game.overlay.skill_icons[i]!=null and game.overlay.skill_icons_grey[i]!=null,"HUD, rewards and help share colored/grey icon pair")
 print("MAGIC FEEDBACK: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

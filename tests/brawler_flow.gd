extends SceneTree
var game
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("verify")
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error(label)
func verify() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.test_mode=true
 game.start_game(true)
 var run=game.run
 check(run.room_rules.filter(func(r): return r.type=="resistance").size()==1,"Only one of six stages is stationary")
 check(run.room_rules.filter(func(r): return r.type=="defense").is_empty(),"Campaign has no timed mobile defense stages")
 check(run.room_rules.all(func(r): return r.type=="resistance" or r.has("exit")),"All mobile stages have a physical end point")
 check(run.room_rules.filter(func(r): return r.type=="scrolling").all(func(r): return r.stage.right>=4200 and r.encounters.size()>=3),"Scrolling stages have multiple screens and distinct encounters")
 run.finish_prologue()
 run.show_rewards()
 run.show_rewards()
 run.finish_entrance()
 check(game.mode=="playing" and run.current_rule().type=="scrolling","First stage opens as a scrolling route")
 game._physics_process(90)
 check(not run.objective_complete() and game.mode=="playing" and game.enemies.is_empty(),"Waiting does not spawn the route or finish a mobile stage")
 for encounter in run.current_rule().encounters:
  game.enemies.clear()
  game.player.x=float(encounter.at_x)
  run.tick(0)
  check(run.road.active and not run.upcoming_entries().is_empty(),"Walking to a checkpoint starts readable entry warnings")
  check(game.enemies.is_empty(),"Checkpoint does not spawn attackers instantly")
  game.player.x=float(encounter.gate_x)+300
  run.tick(0.1)
  check(game.player.x==float(encounter.gate_x)+300,"Warning never clamps or teleports the player")
  run.tick(3)
  check(game.enemies.size()==encounter.entries.size(),"All finite members of the checkpoint are spawned")
  var edges=game.visible_world_bounds()
  check(game.enemies.all(func(e): return e.entering and (e.x<=edges.x-230 or e.x>=edges.y+230)),"Every whole sprite starts beyond the camera edges")
  for enemy in game.enemies:
   var start: float=enemy.x
   game._tick_enemy(enemy,0.1)
   check(absf(enemy.x-start)<=34.01 and enemy.moving and enemy.state==game.Fighter.State.APPROACH,"Arrival runs continuously without clamping or attacking offscreen")
  check(run.movement_limit()==game.stage_right,"Enemies do not impose an invisible road barrier")
  var count: int=game.enemies.size()
  run.tick(2)
  check(game.enemies.size()==count,"A checkpoint cannot duplicate its enemies")
  check(not run.objective_complete(),"A live checkpoint blocks completion")
  for enemy in game.enemies: enemy.hp=0
  run.tick(0)
  check(not run.road.active,"Defeating the group opens the passage immediately")
 game.player.x=game.stage_left+100
 check(run.road.finished(run) and not run.objective_complete(),"Clearing every encounter still requires reaching the exit")
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 var clock: float=run.room_time
 var hp: float=game.player.hp
 run.finish_room()
 check(game.mode=="stage_clear" and not game.wave_active,"Exit first shows the stage-clear message")
 check(run.story_page==1 and run.choices.is_empty(),"Clear message precedes dialogue and rewards")
 game._physics_process(0.5)
 check(run.room_time==clock and game.player.hp==hp and game.mode=="stage_clear","Combat is frozen while the message is readable")
 game.help_open=true
 game._physics_process(10)
 check(is_equal_approx(run.stage_clear_elapsed,0.5),"Help pauses the stage-clear transition")
 game.help_open=false
 game._physics_process(1.2)
 check(game.mode=="interlude" and run.story_page==2,"Clear message hands over to the correct comic")
 run.show_rewards()
 check(run.is_resistance() and run.resistance_duration()==25,"The single static hold retains its timer")
 run.objective_time=24.9
 check(not run.objective_complete(),"Static hold cannot complete before the countdown")
 run.tick(0.11)
 check(run.objective_complete(),"Static hold is the only timed completion")
 # Roles behave differently, beyond merely changing hit points.
 game.enemies.clear()
 var caster=game.Fighter.new()
 caster.id=900
 run.apply_role(caster,"caster")
 caster.x=game.player.x+400
 caster.lane=game.player.lane
 caster.y=game.player.y
 caster.timer=0
 game.enemies.append(caster)
 game._tick_enemy(caster,0)
 check(caster.kind=="caster" and caster.visual_index==3 and caster.state==game.Fighter.State.WINDUP,"New caster starts a long telegraphed cast")
 var target_x: float=caster.spell_target_x
 var target_lane: int=caster.spell_target_lane
 game.player.invincible=0
 game.player.x=target_x+200
 var before: float=game.player.hp
 game._enemy_contact(caster,-1)
 check(game.player.hp==before,"Moving out of the marked spell area avoids damage")
 game.player.x=target_x
 game.player.lane=target_lane
 game.player.y=game.LANES[target_lane]
 game._enemy_contact(caster,-1)
 check(game.player.hp==before-14,"Caster hits its captured target area")
 var brute=game.Fighter.new()
 run.apply_role(brute,"brute")
 brute.x=game.player.x+100
 brute.lane=1
 brute.y=game.LANES[1]
 game.player.lane=0
 game.player.y=game.LANES[0]
 game.player.invincible=0
 before=game.player.hp
 game._enemy_contact(brute,-1)
 check(game.player.hp==before-20 and brute.visual_index==2,"Brute has a distinct large silhouette and cleaves the adjacent lane")
 check(run.roles.runner.speed>run.roles.guard.speed and run.roles.brute.speed<run.roles.guard.speed,"Roles differ in movement and threat")
 var frames=load("res://assets/pencil/enemy_3.tres")
 check(frames.get_frame_count("run")==4 and frames.get_frame_count("attack")==4,"Caster uses new complete authored sprite frames")
 print("BRAWLER FLOW: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

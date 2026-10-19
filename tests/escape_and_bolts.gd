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
 game.run.show_rewards()
 game.run.finish_entrance() # Skip presentation in this mechanics test.
 game.run.objective_time=game.run.resistance_duration()
 game.run.finish_room()
 game.run.finish_stage_clear() # Presentation is covered independently.
 game.run.show_rewards()
 game.run.finish_entrance() # Skip presentation in this mechanics test.
 check(game.wave==3 and game.enemies.size()==2,"Escape starts with two guards")
 var safe: float=game.run.room_rules[2].spawn_min_distance
 check(game.enemies.all(func(e): return absf(e.x-game.player.x)>=safe),"Initial guards cannot spawn beside protagonist")
 for position in [70.0,220.0,600.0,784.0,785.0,1000.0,1400.0,1500.0]:
  game.enemies.clear()
  game.player.x=position
  for index in [3,4]: game.run.spawn_guard(index)
  check(game.enemies.all(func(e): return absf(e.x-game.player.x)>=safe),"Reinforcement keeps minimum distance at player x=%d" % position)
  check(game.enemies.all(func(e): return e.entering and (e.x<=game.visible_world_bounds().x-230 or e.x>=game.visible_world_bounds().y+230)),"Reinforcement starts entirely outside camera at x=%d" % position)
 game.enemies.clear()
 var shooter=game.Fighter.new()
 shooter.kind="archer"
 shooter.x=800
 for lane in range(3):
  for direction in [-1.0,1.0]:
   game.projectiles.clear()
   shooter.lane=lane
   shooter.y=game.LANES[lane]-8 # Also follows the actual body during lane interpolation.
   game._enemy_contact(shooter,direction)
   var bolt: Dictionary=game.projectiles[-1]
   # Atlas firing frame: source tip (453,207), foot pivot (256,400), body scale 0.8.
   var expected=Vector2(shooter.x+direction*(453-256)*0.8,shooter.y+(207-400)*0.8)
   check(Vector2(bolt.x,bolt.y).distance_to(expected)<1,"Bolt aligns to authored crossbow muzzle, lane=%d dir=%d" % [lane,direction])
   check(bolt.crossbow and bolt.hostile and bolt.damage==12 and absf(bolt.vx)==430,"Visible crossbow bolt retains combat stats")
 game.projectiles.clear()
 shooter.lane=1
 shooter.y=game.LANES[1]
 game._enemy_contact(shooter,1)
 var shot: Dictionary=game.projectiles[-1]
 game.player.x=shot.x+40
 game.player.lane=1
 game.player.y=game.LANES[1]
 game.player.hp=160
 game.player.invincible=0
 game.run.buff_time=0
 game._tick_projectiles(0.1)
 check(game.player.hp==148 and game.projectiles.is_empty(),"Raised projectile still hits and is consumed on its lane")
 game._enemy_contact(shooter,-1)
 game.player.lane=0
 game.player.y=game.LANES[0]
 game.player.x=game.projectiles[-1].x-40
 game.player.invincible=0
 game._tick_projectiles(0.1)
 check(game.player.hp==148,"Changing lane still avoids the raised bolt")
 print("ESCAPE AND BOLTS: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

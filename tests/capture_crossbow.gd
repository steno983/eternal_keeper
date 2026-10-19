extends SceneTree
var game
func _initialize() -> void: call_deferred("capture_all")
func capture(label: String) -> void:
 game._process(0)
 game.overlay.queue_redraw()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/crossbow-"+label+".png")
func capture_all() -> void:
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
 game.enemies.clear()
 game.wave_banner=0
 game.run.notice_time=0
 game.camera_x=100
 game.reduced_motion=true
 for direction in [-1,1]:
  game.enemies.clear()
  game.projectiles.clear()
  game.effects.clear()
  game.player.x=400 if direction<0 else 1000
  game.player.previous_x=game.player.x
  var enemy=game.Fighter.new()
  enemy.kind="archer"
  enemy.id=900+direction
  enemy.x=1000 if direction<0 else 450
  enemy.previous_x=enemy.x
  enemy.lane=1
  enemy.y=game.LANES[1]
  enemy.facing=direction
  enemy.state=game.Fighter.State.RECOVER
  enemy.timer=1.0
  enemy.begin_action(&"attack",0.52)
  enemy.action_elapsed=0.24
  game.enemies.append(enemy)
  game._enemy_contact(enemy,direction)
  var name="left" if direction<0 else "right"
  await capture(name+"-release")
  for i in range(12): game._tick_world(1.0/60)
  await capture(name+"-flight")
 print("CROSSBOW CAPTURES: mirrored release and flight captured")
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit()

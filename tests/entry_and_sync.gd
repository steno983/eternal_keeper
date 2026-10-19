extends SceneTree
var game
var failures=0
var checks=0
func _initialize(): call_deferred("verify")
func check(value,label):
 checks+=1
 if not value:
  failures+=1
  push_error(label)
func capture(label):
 if DisplayServer.get_name()=="headless": return
 game._process(0)
 game.painter.queue_redraw()
 game.overlay.queue_redraw()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/"+label+".png")
func verify():
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.test_mode=true
 game.start_game(true)
 game.run.prologue_seen=true
 game.run.intro_done=true
 game.run.before_seen[5]=true
 game.wave=5
 game.run.begin_room()
 game.run.finish_entrance()
 check(game.wave==6,"Last stage selected")
 game.enemies.clear()
 var rule=game.run.current_rule().synchronization
 game.player.x=950
 game.player.lane=0
 game.player.y=game.LANES[0]
 game.camera_x=410
 await capture("sync-zone-start")
 game.run.synchronization.tick(game.run,0.8)
 check(is_equal_approx(game.run.synchronization.charge[0],0.8),"Standing inside marked area charges sigil")
 await capture("sync-zone-charging")
 game.player.x=950+float(rule.radius)+1
 game.run.synchronization.tick(game.run,0.5)
 check(is_equal_approx(game.run.synchronization.charge[0],0.8),"Outside displayed radius does not charge")
 for position in [600.0,1800.0,3350.0]:
  game.player.x=position
  game.camera_x=clampf(position-540,game.stage_left-180,game.stage_right-1200)
  for side in [-1,1]:
   game.enemies.clear()
   game.run.spawn_guard(0,side)
   var enemy=game.enemies.back()
   var edges=game.visible_world_bounds()
   check(enemy.x+220<edges.x or enemy.x-220>edges.y,"Whole sprite starts offscreen")
   for i in range(120):
    var before: float=enemy.x
    game._tick_enemy(enemy,1.0/60)
    check(absf(enemy.x-before)<=340.0/60+0.01,"Entry has no position snap")
    if not enemy.entering: break
   check(not enemy.entering,"Both sides finish entry including end of stage")
 game.player.x=950
 game.player.lane=0
 game.player.y=game.LANES[0]
 game.camera_x=410
 game.enemies.clear()
 game.run.spawn_guard(0,1)
 var incoming=game.enemies.back()
 await capture("enemy-entry-offscreen")
 for i in range(65): game._tick_enemy(incoming,1.0/60)
 await capture("enemy-entry-running")
 print("ENTRY AND SYNC: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

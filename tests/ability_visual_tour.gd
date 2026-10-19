extends SceneTree
var game
var frames=0
func _initialize() -> void: call_deferred("tour")
func fresh(slot: int, variant: String) -> void:
 game.start_game()
 game.set_physics_process(false)
 game.test_mode=true
 game.muted=true
 game.wave_banner=0
 game.player.x=460
 game.player.previous_x=460
 game.player.invincible=0
 game.run.mods[slot]=variant
 for i in range(game.enemies.size()):
  var enemy=game.enemies[i]
  enemy.x=850+i*135
  enemy.previous_x=enemy.x
  enemy.lane=i
  enemy.y=game.LANES[i]
  enemy.timer=1000
  enemy.hp=1000
  enemy.max_hp=1000
func advance(duration: float) -> void:
 for i in range(ceili(duration*60)):
  game._physics_process(1.0/60)
  frames+=1
func capture(label: String) -> void:
 game._process(0)
 game.painter.queue_redraw()
 game.overlay.queue_redraw()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/ability-"+label+".png")
func tour() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 var groups=[["","orb","pierce","fan"],["","ash","sanctuary","eruption"],["","mirror","renewal","aegis"],["","judgment","inferno","nova"]]
 for slot in range(4):
  for variant in groups[slot]:
   fresh(slot,variant)
   assert(game.run.cast(slot))
   advance(0.43 if slot==0 else 0.54)
   await capture("%d-%s" % [slot,"base" if variant=="" else variant])
   if slot==0 and variant in ["orb","pierce"]:
    advance(0.28)
    await capture("%d-%s-hit" % [slot,variant])
   if slot==2:
    game.player.invincible=0
    game.damage_player(20,-1)
    advance(0.08)
    await capture("2-%s-hit" % ["base" if variant=="" else variant])
 fresh(1,"sanctuary")
 game.run.cast(1)
 advance(0.6)
 game.run.cast(2)
 advance(0.8)
 await capture("sigil-and-blessing")
 for slot in [1,2]:
  fresh(slot,"")
  game.run.cast(slot)
  advance(0.20)
  await capture("birth-%d-puddle" % slot)
  advance(0.15)
  await capture("birth-%d-rising" % slot)
  advance(0.38)
  await capture("birth-%d-full" % slot)
 fresh(3,"nova")
 game.reduced_motion=true
 game.run.cast(3)
 advance(0.45)
 await capture("nova-reduced")
 fresh(0,"")
 game.reduced_motion=false
 game.run.cast(0)
 game.change_lane(1)
 advance(0.1)
 assert(game.projectiles.is_empty())
 print("ABILITY VISUAL TOUR: 16 variants, impacts, combined effects, reduced motion and canceled cast rendered")
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit()

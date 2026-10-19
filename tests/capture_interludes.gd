extends SceneTree
var game
func _initialize() -> void: call_deferred("capture_all")
func capture(label: String) -> void:
 game._process(0)
 game.overlay.queue_redraw()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/"+label+".png")
func capture_all() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 for room in range(1,4):
  game.start_game()
  game.wave=room
  game.run.level=8+room
  game.enemies.clear()
  game.run.finish_room()
  await capture("comic-%d-first" % room)
  game.run.advance_interlude()
  game.run.advance_interlude()
  assert(game.run.interlude_revealed==3 and game.mode=="interlude")
  await capture("comic-%d-complete" % room)
  game.run.advance_interlude()
  await capture("camp-%d-reward" % room)
 # Exercise native skip and mouse routing separately from forced illustration captures.
 game.start_game()
 game.enemies.clear()
 game.run.finish_room()
 var event=InputEventKey.new()
 event.keycode=KEY_ESCAPE
 event.physical_keycode=KEY_ESCAPE
 event.pressed=true
 Input.parse_input_event(event)
 await process_frame
 await process_frame
 assert(game.mode=="reward")
 var mouse=InputEventMouseButton.new()
 mouse.button_index=MOUSE_BUTTON_LEFT
 mouse.pressed=true
 mouse.position=game.reward_rect(2).get_center()
 Input.parse_input_event(mouse)
 await process_frame
 await process_frame
 assert(game.mode=="playing" and game.run.taken.size()==1 and game.wave==2)
 print("INTERLUDE CAPTURES: three full pages, camp rewards, native Escape skip and mouse choice passed")
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit()

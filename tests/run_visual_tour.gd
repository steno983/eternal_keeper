extends SceneTree
var game
func _initialize() -> void: call_deferred("tour")
func tap(code: Key) -> void:
 game.set_physics_process(true)
 var e=InputEventKey.new()
 e.physical_keycode=code
 e.keycode=code
 e.pressed=true
 Input.parse_input_event(e)
 await create_timer(0.06).timeout
 e=InputEventKey.new()
 e.physical_keycode=code
 e.keycode=code
 e.pressed=false
 Input.parse_input_event(e)
 await process_frame
 game.set_physics_process(false)
func capture(label: String) -> void:
 game._process(0)
 game.painter.queue_redraw()
 game.overlay.queue_redraw()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/run-"+label+".png")
func tour() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 await capture("title")
 await tap(KEY_ENTER)
 assert(game.mode=="selection")
 await capture("selection")
 # Selection now leads into the campaign. This tour targets the retained bridge arena.
 await tap(KEY_ESCAPE)
 assert(game.mode=="title")
 await tap(KEY_B)
 assert(game.mode=="playing" and not game.campaign and game.player.hero==0)
 await capture("combat")
 await tap(KEY_K)
 assert(game.run.skill_cd[0]>0)
 game._physics_process(0.21)
 await capture("spell")
 game.player.begin_action(&"",0)
 await tap(KEY_I)
 game._physics_process(0.21)
 await capture("super")
 # Stage a cleared room to inspect the actual reward UI and input route.
 for e in game.enemies: game.damage_enemy(e,999,1,Color("b96b2b"))
 game._physics_process(0.1)
 game._physics_process(0.1)
 assert(game.mode=="interlude")
 await capture("comic")
 while game.mode=="interlude":
  await tap(KEY_ENTER)
 assert(game.mode=="reward")
 await capture("reward")
 await tap(KEY_1)
 assert(game.mode=="playing" and game.wave==2 and game.run.taken.size()==1)
 game.run.intesa=100
 await tap(KEY_V)
 assert(not game.run.assist.is_empty())
 game._physics_process(0.22)
 await capture("allies")
 await tap(KEY_ESCAPE)
 assert(game.mode=="paused")
 await capture("pause")
 await tap(KEY_F1)
 assert(game.help_open)
 await capture("help")
 print("RUN VISUAL TOUR: selection, spells, comic, camp reward, next room, trio, pause, help passed")
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit()

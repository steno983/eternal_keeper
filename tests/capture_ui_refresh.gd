extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func shot(game,name: String) -> void:
	game.painter.queue_redraw()
	game.overlay.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/ui-"+name+".png")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	await shot(game,"title")
	game.start_game()
	game.set_physics_process(false)
	game.player.x=590
	game.camera_x=80
	game.wave_banner=0
	game._process(0.0)
	await shot(game,"gameplay")
	game.player.hero=1
	game.player.hp=64
	game.cooldowns[1]=2.4
	game.combo=7
	game.combo_time=1.6
	game._process(0.0)
	await shot(game,"recharge")
	game.help_open=true
	await shot(game,"help")
	game.help_open=false
	game.mode="paused"
	await shot(game,"pause")
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	quit()

extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/layla-game-frames")
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	game.muted=true
	game.player.hero=1
	game.player.action=&""
	game.player.moving=true
	game.player.x=660.0
	game.player.y=game.LANES[1]
	game.wave_banner=0.0
	game.hero_banner=0.0
	for frame in range(42):
		game.player.travelled=231.0*frame/42.0
		game.time=frame/60.0
		game._process(0.0)
		game.painter.queue_redraw()
		game.overlay.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/layla-game-frames/%03d.png" % frame)
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	print("LAYLA GAME CAPTURE: 42 frames, complete approved cycle")
	quit()

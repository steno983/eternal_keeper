extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	game.special()
	for stage in [[0.05,"early"],[0.11,"middle"],[0.20,"base"],[0.34,"first-drops"],[0.55,"full"],[1.60,"exit"]]:
		game.super_banner.life=1.65-stage[0]
		game.overlay.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/ink-reveal-"+stage[1]+".png")
		var expected=675.0*clampf(stage[0]/0.16,0.0,1.0)
		assert(absf(game.overlay.banner_clip.size.x-expected)<0.1)
	game.reduced_motion=true
	game.super_banner.life=1.64
	game.overlay.queue_redraw()
	await process_frame
	await process_frame
	assert(game.overlay.banner_clip.size.x==675.0)
	game.mode="paused"
	game.overlay.queue_redraw()
	await process_frame
	await process_frame
	assert(not game.overlay.banner_clip.visible)
	print("INK REVEAL: progressive clip, reduced motion and pause passed")
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	quit()

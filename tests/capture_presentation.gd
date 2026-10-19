extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	game.wave_banner=0
	game.hero_banner=0
	game.enemies.clear()
	game.camera_x=100
	game.player.x=600
	game.player.y=game.LANES[1]
	game.player.moving=true
	game.player.travelled=30
	game.time=9.08
	for i in range(3):
		var enemy=game.Fighter.new()
		enemy.kind=["raider","archer","warden"][i]
		enemy.x=780+i*210
		enemy.y=game.LANES[i]
		enemy.lane=i
		enemy.facing=-1
		enemy.hp=100
		enemy.max_hp=100
		enemy.moving=true
		enemy.travelled=18
		game.enemies.append(enemy)
	game.effects.append({"kind":"impact","x":780.0,"y":405.0,"life":0.15,"max":0.24,"color":Color("efaa57"),"heavy":true,"seed":2.0})
	game._process(0.0)
	game.painter.queue_redraw()
	game.overlay.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/enemies-and-presentation.png")
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	quit()

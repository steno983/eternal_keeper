extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	game.enemies.clear()
	game.player.hero=1
	game.player.x=610
	game.player.y=560
	game.player.hp=110
	game.player.max_hp=110
	game.camera_x=80
	game.wave_banner=0
	game.attack()
	game.player.tick_visuals(0.36*0.24)
	for i in range(3):
		var enemy=game.Fighter.new()
		enemy.kind="archer" if i==2 else "raider"
		enemy.x=740+i*210
		enemy.lane=1 if i==0 else 0 if i==1 else 2
		enemy.y=game.LANES[enemy.lane]
		enemy.hp=100
		enemy.max_hp=100
		enemy.facing=-1
		game.enemies.append(enemy)
	game._resolve_actions()
	game.time=2.4
	game._process(0.0)
	game.painter.queue_redraw()
	game.overlay.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/pencil-gameplay.png")
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	quit()

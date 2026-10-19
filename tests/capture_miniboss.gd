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
	game.wave=2
	game.spawn_wave()
	game.wave_banner=0
	game.player.x=3090
	game.player.hero=2
	game.player.hp=game.health[2]
	game.player.max_hp=130
	game.player.lane=1
	game.player.y=game.LANES[1]
	game.camera_x=2540
	game.player.combo_step=2
	game.player.begin_action(&"attack",0.42)
	game.player.action_elapsed=0.42*0.34
	var boss=game.enemies[0]
	boss.x=3320
	boss.lane=0
	boss.y=game.LANES[0]
	boss.hp=boss.max_hp*0.45
	boss.facing=-1
	boss.attack_variant=1
	boss.state=game.Fighter.State.WINDUP
	boss.begin_action(&"windup",0.75)
	boss.action_elapsed=0.55
	game.enemies[1].x=3550
	game.enemies[2].x=3650
	game.time=4.0
	game.echo={"x":3130.0,"lane":0}
	game.echo_time=2
	game.echo_attack=0.16
	game._process(0.0)
	game.painter.queue_redraw()
	game.overlay.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/miniboss-combat.png")
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	quit()

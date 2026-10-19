extends SceneTree
const Fighter = preload("res://scripts/fighter.gd")
var game
var cast: Array = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/animation-v3-frames")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	game.muted = true
	game.wave_banner = 0.0
	game.wave_active = true
	game.enemies.clear()
	for i in range(6):
		var fighter = game.player if i == 0 else Fighter.new()
		fighter.kind = "hero" if i < 3 else ["raider", "archer", "warden"][i - 3]
		fighter.hero = i % 3
		fighter.x = 350.0 + (i % 3) * 370.0
		fighter.previous_x = fighter.x
		fighter.y = 485.0 if i < 3 else 690.0
		fighter.lane = 0 if i < 3 else 2
		fighter.facing = 1.0 if i < 3 else -1.0
		fighter.hp = game.HEROES[i].hp if i < 3 else 100.0
		fighter.max_hp = fighter.hp
		cast.append(fighter)
		if i != 0:
			game.enemies.append(fighter)
	for frame in range(330):
		game.time = frame / 60.0
		for i in range(cast.size()):
			var fighter = cast[i]
			fighter.tick_visuals(1.0 / 60.0)
			if frame < 50:
				fighter.moving = false
			elif frame < 170:
				fighter.moving = true
				fighter.travelled += (128.0 if i < 3 else 94.0) / 0.60 / 60.0
			elif frame < 270:
				fighter.moving = false
				if not fighter.action_active():
					fighter.begin_action(&"attack", game.ATTACK_LENGTH[i] if i < 3 else 0.54)
			else:
				fighter.moving = false
				if not fighter.action_active():
					fighter.begin_action(&"ranged", game.RANGED_LENGTH[i] if i < 3 else 0.54)
		game.painter.queue_redraw()
		game.overlay.queue_redraw()
		game._process(0.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/animation-v3-frames/%03d.png" % frame)
	print("ANIMATION CAPTURE: 330 native-rendered frames")
	game.shutdown_audio()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	quit()


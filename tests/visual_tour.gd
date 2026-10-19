extends SceneTree
var game
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func key(code: Key, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code, true)
	await create_timer(0.05).timeout
	key(code, false)
	await create_timer(0.05).timeout

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)
	else:
		print("INPUT OK: " + label)

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/" + label + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(0.35).timeout
	await capture("title")
	await tap(KEY_ENTER)
	check(game.mode == "playing", "Enter starts the encounter")
	key(KEY_D, true)
	await create_timer(0.65).timeout
	key(KEY_D, false)
	check(game.player.x > 450, "Movement advances the player and scrolls camera")
	await tap(KEY_K)
	await create_timer(0.22).timeout
	check(game.cooldowns[0] > 0, "Tholgrin casts holy fire via keyboard")
	await capture("tholgrin-fire")
	key(KEY_J, true)
	await create_timer(0.6).timeout
	key(KEY_J, false)
	await tap(KEY_2)
	check(game.player.hero == 1, "Hotkey changes to Layla")
	await tap(KEY_W)
	check(game.player.lane == 0, "W moves to the back plane")
	await tap(KEY_L)
	await tap(KEY_K)
	check(game.cooldowns[1] > 0, "Layla performs psionic dash")
	await capture("layla-dash")
	await tap(KEY_3)
	check(game.player.hero == 2, "Hotkey changes to Lupinor")
	await tap(KEY_S)
	await tap(KEY_K)
	await create_timer(0.22).timeout
	check(not game.echo.is_empty(), "Lupinor manifests an echo via keyboard")
	key(KEY_J, true)
	key(KEY_L, true)
	await create_timer(0.3).timeout
	await capture("lupinor-echo")
	key(KEY_J, false)
	key(KEY_L, false)
	await tap(KEY_SPACE)
	check(game.dash_cd > 0, "Space triggers dodge")
	await tap(KEY_ESCAPE)
	check(game.mode == "paused", "Escape opens pause")
	var x: float = game.player.x
	await create_timer(0.25).timeout
	check(is_equal_approx(game.player.x, x), "Simulation stays frozen during pause")
	await capture("pause")
	await tap(KEY_F1)
	check(game.help_open, "F1 opens the command manual")
	await capture("controls")
	await tap(KEY_ESCAPE)
	await tap(KEY_ESCAPE)
	check(game.mode == "playing" and not game.help_open, "Escape closes help then resumes")
	await tap(KEY_R)
	check(game.player.hero == 0 and game.kills == 0, "R restarts a clean encounter")
	print("VISUAL TOUR: failures=" + str(failures))
	game.shutdown_audio()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

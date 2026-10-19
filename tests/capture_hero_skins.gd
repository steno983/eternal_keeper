extends SceneTree
const HeroSkin=preload("res://scripts/hero_run_skin.gd")
const Fighter=preload("res://scripts/fighter.gd")
var figures: Array=[]
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if "--game" in OS.get_cmdline_user_args():
		await game_capture()
		return
	DirAccess.make_dir_recursive_absolute("res://artifacts/hero-skin-frames")
	RenderingServer.set_default_clear_color(Color("182832"))
	var canvas=Node2D.new()
	root.add_child(canvas)
	for hero in range(3):
		var label=Label.new()
		label.text=HeroSkin.PROFILES[hero].name
		label.position=Vector2(180+hero*430,150)
		label.add_theme_font_size_override("font_size",25)
		canvas.add_child(label)
		var figure=HeroSkin.new()
		figure.configure(hero)
		figure.position=Vector2(hero*430-30,160)
		figure.scale=Vector2.ONE*1.3
		canvas.add_child(figure)
		figures.append(figure)
	for frame in range(96):
		for figure in figures:
			figure.phase=frame/60.0/figure.cycle_period
			figure.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/hero-skin-frames/%03d.png" % frame)
	print("HERO SKIN CAPTURE: 96 frames at native 60 Hz")
	quit()

func game_capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/hero-game-frames")
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	game.enemies.clear()
	game.wave_banner=0.0
	game.hero_banner=0.0
	game.muted=true
	var actors: Array=[]
	for hero in range(3):
		var actor=game.player if hero==0 else Fighter.new()
		actor.hero=hero
		actor.kind="hero"
		actor.x=350.0+hero*380.0
		actor.y=game.LANES[1]
		actor.hp=game.HEROES[hero].hp
		actor.facing=1.0
		actor.moving=true
		actor.action=&""
		actors.append(actor)
		if hero!=0:
			game.enemies.append(actor)
	for frame in range(96):
		for actor in actors:
			actor.travelled=HeroSkin.PROFILES[actor.hero].speed*frame/60.0
		game.time=frame/60.0
		game._process(0.0)
		game.painter.queue_redraw()
		game.overlay.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/hero-game-frames/%03d.png" % frame)
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	print("HERO GAME CAPTURE: 96 frames / 60 Hz")
	quit()

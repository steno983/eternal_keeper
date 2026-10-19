extends SceneTree
const HeroKit=preload("res://scripts/hero_run_skin.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/hero-combat-frames")
	RenderingServer.set_default_clear_color(Color("182832"))
	var figures: Array=[]
	for hero in range(3):
		var figure=HeroKit.new()
		figure.configure(hero)
		figure.position=Vector2(hero*420-35,135)
		figure.scale=Vector2.ONE*1.4
		root.add_child(figure)
		figures.append(figure)
	for frame in range(132):
		for figure in figures:
			var t=frame/60.0
			var duration=[0.48,0.36,0.42][figure.hero]
			figure.animation_time=t
			var attack_time=t-0.20
			if attack_time>=0 and attack_time<duration*3:
				figure.action_clip=&"attack"
				figure.combo_step=int(attack_time/duration)
				figure.action_progress=fposmod(attack_time,duration)/duration
			elif t>1.8 and t<1.99:
				figure.action_clip=&"dodge"
				figure.action_progress=(t-1.8)/0.19
			else:
				figure.action_clip=&"idle"
			figure.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/hero-combat-frames/%03d.png" % frame)
	print("HERO COMBAT CAPTURE: three combos, idle and dodge at 60 Hz")
	quit()

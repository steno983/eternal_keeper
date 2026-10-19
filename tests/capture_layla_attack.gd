extends SceneTree
const HeroKit=preload("res://scripts/hero_run_skin.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/layla-attack-frames")
	RenderingServer.set_default_clear_color(Color("182832"))
	var figure=HeroKit.new()
	figure.configure(1)
	figure.position=Vector2(80,-80)
	figure.scale=Vector2.ONE*2.3
	root.add_child(figure)
	for frame in range(84):
		var t=frame/60.0-0.1
		figure.action_clip=&"attack" if t>=0 and t<1.08 else &"idle"
		figure.combo_step=clampi(int(t/0.36),0,2)
		figure.action_progress=fposmod(maxf(t,0),0.36)/0.36
		figure.animation_time=frame/60.0
		figure.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/layla-attack-frames/%03d.png" % frame)
	quit()

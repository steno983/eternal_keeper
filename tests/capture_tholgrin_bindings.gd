extends SceneTree
const HeroSkin=preload("res://scripts/hero_run_skin.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/tholgrin-bound-frames")
	RenderingServer.set_default_clear_color(Color("182832"))
	var figure=HeroSkin.new()
	figure.configure(0)
	figure.scale=Vector2.ONE*2.0
	root.add_child(figure)
	for frame in range(46):
		figure.phase=frame/46.0
		figure.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/tholgrin-bound-frames/%03d.png" % frame)
	print("THOLGRIN BINDING CAPTURE: complete cycle, 46 evenly spaced poses")
	quit()

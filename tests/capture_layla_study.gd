extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/layla-study-frames")
	var scene=load("res://scenes/animation_studio.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	for frame in range(84):
		scene.elapsed=frame/60.0
		scene._sync()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/layla-study-frames/%03d.png" % frame)
	print("LAYLA STUDY: 84 native frames / 60 Hz")
	quit()

extends SceneTree
const EnemyKit=preload("res://scripts/enemy_skin.gd")
const Fighter=preload("res://scripts/fighter.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/enemy-skin-frames")
	RenderingServer.set_default_clear_color(Color("182832"))
	var figures: Array=[]
	for index in range(3):
		var figure=EnemyKit.new()
		figure.configure(index)
		figure.position=Vector2(index*420-55,120)
		figure.scale=Vector2.ONE*1.4
		root.add_child(figure)
		figures.append(figure)
	for frame in range(96):
		for figure in figures:
			figure.phase=frame/96.0
			figure.motion_time=frame/60.0
			figure.clip=&"run" if frame<48 else &"windup" if frame<64 else &"attack"
			figure.progress=(frame-48)/16.0 if frame<64 else (frame-64)/32.0
			figure.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/enemy-skin-frames/%03d.png" % frame)
	print("ENEMY CAPTURE: run, windup, attack; 96 poses")
	quit()


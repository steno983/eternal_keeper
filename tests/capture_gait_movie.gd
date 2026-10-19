extends SceneTree
const Rig = preload("res://scripts/run_rig.gd")
const Bank = preload("res://scripts/animation_bank.gd")
var rigs: Array = []
var old: Array = []
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/gait-frames")
	RenderingServer.set_default_clear_color(Color("182833"))
	var canvas = Node2D.new()
	root.add_child(canvas)
	for hero in range(3):
		var previous = Sprite2D.new()
		previous.centered = false
		previous.position = Vector2(100+hero*400,0)
		canvas.add_child(previous)
		old.append(previous)
		var rig = Rig.new()
		rig.configure(hero)
		rig.position = Vector2(100+hero*400,350)
		canvas.add_child(rig)
		rigs.append(rig)
	for frame in range(62):
		for hero in range(3):
			rigs[hero].phase = frame / 60.0 / 0.52
			rigs[hero].queue_redraw()
			old[hero].texture = Bank.texture("hero_%d" % hero,&"run",frame/60.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/gait-frames/%03d.png" % frame)
	print("GAIT CAPTURE: 62 frames at 60 Hz, old above / rig below")
	quit()

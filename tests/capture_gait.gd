extends SceneTree
const Rig = preload("res://scripts/run_rig.gd")
var rigs: Array = []
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var canvas = Node2D.new()
	root.add_child(canvas)
	RenderingServer.set_default_clear_color(Color("182833"))
	for hero in range(3):
		for frame in range(4):
			var rig = Rig.new()
			rig.configure(hero)
			rig.phase = frame * 0.25
			rig.position = Vector2(frame*300+5, hero*220-5)
			rig.scale = Vector2.ONE * 0.7
			canvas.add_child(rig)
			rigs.append(rig)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/rig-gait-contact.png")
	quit()

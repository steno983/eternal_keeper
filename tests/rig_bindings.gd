extends SceneTree
const HeroSkin=preload("res://scripts/hero_run_skin.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for hero in range(3):
		var figure=HeroSkin.new()
		figure.configure(hero)
		root.add_child(figure)
		await process_frame
		var binding: Dictionary=figure.BINDINGS[hero]
		for part in ["upper_arm","forearm","thigh","shin"]:
			var anchors: Array=binding.upper if part=="upper_arm" else binding[part]
			var bitmap=figure.parts[part].get_image()
			for anchor: Vector2 in anchors:
				var point=Vector2i(anchor*Vector2(bitmap.get_size()))
				check(bitmap.get_pixelv(point).a>0.50,"Joint landmarks are inside painted material: %d/%s" % [hero,part])
		for phase in [0.0,0.125,0.25,0.375,0.5,0.625,0.75,0.875]:
			var data=figure.profile_pose(phase)
			for side in range(2):
				var torso_socket=figure.mapped_point("torso",binding.shoulders[side],binding.neck,binding.waist,data.neck,data.waist,binding.chest_width)
				check(torso_socket.distance_to(data.arms[side].shoulder)<0.001,"Arm follows the actual socket painted on the chest")
				var elbow=figure.mapped_point("upper_arm",binding.upper[1],binding.upper[0],binding.upper[1],data.arms[side].shoulder,data.arms[side].elbow)
				check(elbow.distance_to(data.arms[side].elbow)<0.001,"Painted elbow aligns with animated elbow")
				var knee=figure.mapped_point("thigh",binding.thigh[1],binding.thigh[0],binding.thigh[1],data.legs[side].hip,data.legs[side].knee)
				check(knee.distance_to(data.legs[side].knee)<0.001,"Painted kneecap aligns with the shin attachment")
		figure.queue_free()
		await process_frame
	print("RIG BINDINGS: %d/%d passed" % [checks-failures,checks])
	quit(0 if failures==0 else 1)

extends SceneTree
const Study=preload("res://scripts/layla_run_study.gd")
var failures: int=0
var checks: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(absf(Study.sample(Study.THIGH,0.0)-25.0)<0.001,"Sampling preserves the authored contact pose")
	check(absf(Study.sample(Study.THIGH,0.125)-40.0)<0.001,"Sampling preserves weight absorption")
	var first=Study.pose(0.0)
	var second=Study.pose(0.5)
	check(first.legs[0].knee.distance_to(second.legs[1].knee)<0.001,"Leg identity exchanges at the opposite contact")
	check(Study.pose(0.0).hip.y<Study.pose(0.125).hip.y,"The body drops to absorb contact")
	check(Study.pose(0.375).hip.y<Study.pose(0.125).hip.y,"Push-off lifts the body")
	check(Study.pose(0.125).shoulder.distance_to(Study.pose(0.375).shoulder)>10.0,"Torso participates in the stride")
	var max_penetration=0.0
	var max_stretch=0.0
	var flight_frames=0
	for frame in range(240):
		var data=Study.pose(frame/240.0)
		var airborne=true
		for leg: Dictionary in data.legs:
			max_stretch=maxf(max_stretch,absf(leg.hip.distance_to(leg.knee)-46.0))
			max_stretch=maxf(max_stretch,absf(leg.knee.distance_to(leg.ankle)-47.0))
			var bottom=-1000.0
			for vertex in [Vector2(-6,-5),Vector2(4,-5),Vector2(5,1),Vector2(17,5),Vector2(18,8),Vector2(14,10),Vector2(-7,8)]:
				bottom=maxf(bottom,leg.ankle.y+vertex.rotated(leg.foot).y)
			max_penetration=maxf(max_penetration,bottom-Study.FLOOR)
			airborne=airborne and bottom<Study.FLOOR-2.0
		if airborne:
			flight_frames+=1
	check(max_stretch<0.001,"No stretching of thighs or shins")
	check(max_penetration<2.0,"Soles do not penetrate the floor")
	check(flight_frames>0,"There are actual flight intervals")
	check(Study.pose(0.99999).legs[0].ankle.distance_to(first.legs[0].ankle)<0.02,"The last pose joins the first continuously")
	var scene=load("res://scenes/animation_studio.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.elapsed=0.2
	scene.step(1)
	check(not scene.playing and absf(scene.elapsed-(0.2+1.0/24))<0.001,"Frame stepping pauses playback")
	scene.toggle_play()
	check(scene.playing,"Playback resumes after scrubbing")
	print("LAYLA STUDY: %d/%d passed; max floor penetration %.3f px; flight samples %d/240" % [checks-failures,checks,max_penetration,flight_frames])
	scene.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

extends SceneTree
const HeroKit=preload("res://scripts/hero_run_skin.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var figure=HeroKit.new()
	figure.configure(1)
	root.add_child(figure)
	var stable=true
	var planted=true
	var closes=true
	for stage in range(3):
		figure.combo_step=stage
		figure.action_clip=&"attack"
		figure.action_progress=0
		var first=figure.combat_pose()
		for frame in range(65):
			figure.action_progress=frame/64.0
			var data=figure.combat_pose()
			for side in range(2):
				var arm: Dictionary=data.arms[side]
				var leg: Dictionary=data.legs[side]
				stable=stable and absf(arm.shoulder.distance_to(arm.elbow)-30.0)<0.002 and absf(arm.elbow.distance_to(arm.hand)-27.0)<0.002
				stable=stable and absf(leg.hip.distance_to(leg.knee)-46.0)<0.002 and absf(leg.knee.distance_to(leg.ankle)-47.0)<0.002
				planted=planted and leg.ankle.distance_to(first.legs[side].ankle)<0.001
		figure.action_progress=1
		var last=figure.combat_pose()
		closes=closes and first.hip.distance_to(last.hip)<0.001
		for side in range(2):
			closes=closes and first.arms[side].hand.distance_to(last.arms[side].hand)<0.001
	print("LAYLA ATTACK: stable limbs=%s, planted soles=%s, guard transitions=%s" % [stable,planted,closes])
	figure.queue_free()
	await process_frame
	quit(0 if stable and planted and closes else 1)

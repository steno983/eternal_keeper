extends SceneTree
const Rig = preload("res://scripts/run_rig.gd")
var failed: int = 0
var checks: int = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for hero in range(3):
		var cfg: Dictionary = Rig.CONFIG[hero]
		var hip: Vector2 = Vector2(198,209) if hero == 2 else cfg.hip
		check(Rig.foot_at(0.0,cfg.reach).x > 0.0 and Rig.foot_at(0.5,cfg.reach).x < 0.0, "Near leg exchanges front/back position")
		check(Rig.foot_at(0.25,cfg.reach).y > Rig.foot_at(0.75,cfg.reach).y, "Stance and lifted swing are distinct")
		check(Rig.foot_at(0.0,cfg.reach).distance_to(Rig.foot_at(1.0,cfg.reach)) < 0.001, "Closed gait has no reset jump")
		check(Rig.foot_at(0.45,cfg.reach).y < 294.0 and Rig.foot_at(0.95,cfg.reach).y < 294.0, "Run has a flight phase with both feet lifted")
		for n in range(120):
			var phase = n / 120.0
			var foot = Rig.foot_at(phase,cfg.reach) + Vector2(hip.x,0)
			var bobbed_hip = hip + Vector2(0,-2.5*cos(phase*TAU*2))
			var knee = Rig.knee_at(bobbed_hip,foot,cfg.lengths)
			check(absf(knee.distance_to(bobbed_hip)-cfg.lengths.x) < 0.02, "Thigh length stays constant")
			check(absf(knee.distance_to(foot)-cfg.lengths.y) < 0.02, "Shin length stays constant")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	game.player.action = &""
	game.player.moving = true
	game.player.travelled = 45.6
	game._process(0.0)
	var view = game.visuals[game.player]
	check(view.hero_skin.visible and not view.sprite.visible, "Hero locomotion displays the articulated rig")
	check(absf(view.hero_skin.phase-0.25)<0.001, "Rig follows actual travelled distance")
	game.player.facing = -1.0
	view.sync()
	check(view.hero_skin.scale.x<0.0, "Changing direction mirrors the complete gait")
	game.player.begin_action(&"attack",0.48)
	view.sync()
	check(not view.hero_skin.visible and view.sprite.visible, "Attack restores the existing sprite animation")
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	print("GAIT MOTION: %d/%d passed" % [checks-failed,checks])
	quit(0 if failed==0 else 1)


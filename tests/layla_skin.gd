extends SceneTree
const DressedLayla=preload("res://scripts/layla_run_skin.gd")
const Approved=preload("res://scripts/layla_run_study.gd")
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
	var dressed=DressedLayla.new()
	root.add_child(dressed)
	await process_frame
	check(dressed.parts.size()==12,"All painted parts load; no silhouette fallback")
	check(DressedLayla.PERIOD==Approved.PERIOD and DressedLayla.STRIDE==Approved.STRIDE,"Approved rhythm and stride are preserved")
	var scene=load("res://scenes/animation_studio.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.elapsed=0.23
	scene._sync()
	check(scene.figure is DressedLayla,"Studio displays the painted character")
	check(scene.figure.phase==scene.previous.phase,"Painted and approved figures stay synchronized")
	scene.queue_free()
	dressed.queue_free()
	await process_frame
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	game.player.hero=1
	game.player.action=&""
	game.player.moving=true
	game.player.travelled=Approved.STRIDE*0.25
	game._process(0.0)
	var view=game.visuals[game.player]
	check(view.hero_skin.visible  and not view.sprite.visible,"Gameplay selects the new Layla renderer")
	check(absf(view.hero_skin.phase-0.25)<0.001,"Gameplay uses the approved stride")
	game.player.facing=-1.0
	view.sync()
	check(view.hero_skin.scale.x<0.0,"All painted parts mirror together")
	game.player.begin_action(&"attack",0.36)
	view.sync()
	check(not view.hero_skin.visible and view.sprite.visible,"Attack switches back to the existing action frames")
	game.player.hero=2
	game.player.action=&""
	view.sync()
	check(view.hero_skin.visible and view.hero_skin.hero==2,"Switching hero hides Layla's painted rig")
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	print("LAYLA SKIN: %d/%d passed" % [checks-failures,checks])
	quit(0 if failures==0 else 1)


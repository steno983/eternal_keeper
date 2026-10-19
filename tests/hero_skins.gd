extends SceneTree
const HeroSkin=preload("res://scripts/hero_run_skin.gd")
const Approved=preload("res://scripts/layla_run_study.gd")
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
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	for hero in range(3):
		var figure=HeroSkin.new()
		figure.configure(hero)
		root.add_child(figure)
		await process_frame
		check(figure.parts.size()==12,"Every hero loads twelve painted parts: "+str(hero))
		check(figure.stride_length==figure.cycle_period*game.HEROES[hero].speed,"Cadence matches the character speed")
		var first=figure.profile_pose(0.0)
		var opposite=figure.profile_pose(0.5)
		check((first.legs[0].knee-first.legs[0].hip).distance_to(opposite.legs[1].knee-opposite.legs[1].hip)<0.001,"Legs alternate relative to their own hip sockets")
		check(figure.profile_pose(0.99999).legs[0].ankle.distance_to(first.legs[0].ankle)<0.03,"Each profile closes its gait smoothly")
		var length_scale: float=figure.PROFILES[hero].leg
		var stable=true
		for n in range(64):
			var data=figure.profile_pose(n/64.0)
			for leg: Dictionary in data.legs:
				stable=stable and absf(leg.hip.distance_to(leg.knee)-46.0*length_scale)<0.002
				stable=stable and absf(leg.knee.distance_to(leg.ankle)-47.0*length_scale)<0.002
		check(stable,"Each character retains its own limb proportions")
		game.player.hero=hero
		game.player.action=&""
		game.player.moving=true
		game.player.travelled=figure.stride_length*0.25
		game._process(0.0)
		var view=game.visuals[game.player]
		check(view.sprite.visible and view.key=="hero_"+str(hero),"Gameplay uses the complete pencil figure")
		check(view.sprite.animation==&"run" and view.sprite.frame==2,"Gameplay follows the selected hero's stride")
		game.player.facing=-1.0
		view.sync()
		check(view.sprite.flip_h,"Complete rig mirrors when turning")
		game.player.begin_action(&"attack",game.ATTACK_LENGTH[hero])
		view.sync()
		check(view.sprite.visible and view.sprite.animation==&"attack","Every hero retains its body during attacks")
		figure.queue_free()
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	var studio=load("res://scenes/animation_studio.tscn").instantiate()
	root.add_child(studio)
	await process_frame
	studio.set_process(false)
	for hero in range(3):
		studio.select_hero(hero)
		check(studio.figure.hero==hero and studio.previous.hero==hero,"Studio changes both views together")
		check(studio.figure.phase==studio.previous.phase,"Both views retain the same motion phase")
	studio.queue_free()
	await process_frame
	print("HERO SKINS: %d/%d passed" % [checks-failures,checks])
	quit(0 if failures==0 else 1)

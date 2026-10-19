extends SceneTree
const Bank=preload("res://scripts/pencil_bank.gd")
var checks=0
var failures=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	game.enemies.clear()
	for index in range(3):
		var actor=game.Fighter.new()
		actor.kind=["raider","archer","warden"][index]
		actor.x=800
		actor.y=560
		actor.hp=100
		game.enemies.append(actor)
		game._process(0.0)
		var view=game.visuals[actor]
		check(view.sprite.sprite_frames==Bank.library("enemy_"+str(index)),"Enemy retains its own pencil identity")
		for clip in [&"idle",&"run",&"windup",&"attack",&"hurt"]:
			actor.action=&"" if clip in [&"idle",&"run"] else clip
			actor.moving=clip==&"run"
			actor.action_length=0.54
			actor.action_elapsed=0.25
			view.sync()
			check(view.sprite.visible and view.sampled_clip==clip,"Enemy state selects a complete drawing")
		actor.facing=-1
		view.sync()
		check(view.sprite.flip_h,"Enemy turns without rearranging body parts")
		actor.hp=0
		actor.dead_time=0.6
		view.sync()
		check(view.sprite.modulate.a==0,"Death fades pencil figure")
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	print("ENEMY PENCIL SKINS: %d/%d passed" % [checks-failures,checks])
	quit(0 if failures==0 else 1)

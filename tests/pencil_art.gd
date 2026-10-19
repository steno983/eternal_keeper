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
	for family in ["hero","enemy"]:
		for index in range(3):
			var key=family+"_"+str(index)
			var frames=Bank.library(key)
			check(frames!=null,"Pencil family exists: "+key)
			check(frames.get_frame_count(&"run")==8,"Eight whole running drawings")
			for clip in [&"attack",&"attack_2",&"attack_3"]:
				check(frames.get_frame_count(clip)==4,"Complete attack key drawings")
				for frame in range(4):
					var texture=frames.get_frame_texture(clip,frame)
					check(texture.get_size()==Vector2(512,416),"Shared frame canvas prevents scale drift")
			var actor=game.player if family=="hero" else game.Fighter.new()
			actor.hero=index
			actor.kind="hero" if family=="hero" else ["raider","archer","warden"][index]
			actor.x=650
			actor.y=560
			actor.hp=100
			if family=="enemy":
				game.enemies.append(actor)
			game._process(0.0)
			var view=game.visuals[actor]
			check(view.sprite.sprite_frames==frames,"Gameplay selects the pencil family")
			for clip in [&"idle",&"run",&"attack",&"ranged",&"special",&"hurt",&"dodge"]:
				actor.action=&"" if clip in [&"idle",&"run"] else clip
				actor.moving=clip==&"run"
				actor.action_elapsed=0.1
				actor.action_length=0.5
				view.sync()
				check(view.visible and view.sprite.visible,"Every state stays in pencil rendering")
			actor.facing=-1
			view.sync()
			check(view.sprite.flip_h,"Whole body mirrors consistently")
			if family=="enemy":
				actor.hp=0
				actor.dead_time=0.6
				view.sync()
				check(view.sprite.modulate.a==0,"Death fades the same figure")
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	var studio=load("res://scenes/pencil_studio.tscn").instantiate()
	root.add_child(studio)
	await process_frame
	for index in range(6):
		studio.select(index)
		studio.choose(&"attack_2")
		studio.step(1)
		check(studio.selected==index and studio.paused,"Studio previews each family and can step")
	studio.queue_free()
	await process_frame
	print("PENCIL PRESENTATION: %d/%d passed" % [checks-failures,checks])
	quit(0 if failures==0 else 1)

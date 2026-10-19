extends SceneTree
const Fighter = preload("res://scripts/fighter.gd")
const Bank = preload("res://scripts/pencil_bank.gd")
var game
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func reset(hero: int = 0) -> void:
	game.start_game()
	game.set_physics_process(false)
	game.enemies.clear()
	game.player.hero = hero
	game.player.hp = game.HEROES[hero].hp
	game.player.max_hp = game.player.hp
	game.player.invincible = 0.0

func target(lane: int):
	var enemy = Fighter.new()
	enemy.x = game.player.x + 60
	enemy.previous_x = enemy.x
	enemy.y = game.LANES[lane]
	enemy.lane = lane
	enemy.kind = "raider"
	game.enemies.append(enemy)
	return enemy

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	for hero in range(3):
		reset(hero)
		var frames: SpriteFrames = Bank.library("hero_" + str(hero))
		check(frames != null and frames.get_frame_count(&"run") == 8, "Hero has eight whole-figure gait drawings " + str(hero))
		check(frames.get_frame_count(&"attack") == 4, "Hero has four complete attack key poses " + str(hero))
		var victim = target(1)
		game.attack()
		var duration: float = game.ATTACK_LENGTH[hero]
		var contact_phase: float = game.CONTACT_PHASE[hero]
		var contact_frame: int = 2
		game.player.tick_visuals(duration * contact_phase - 0.001)
		game._resolve_actions()
		check(victim.hp == 100, "Windup is harmless " + str(hero))
		game.player.tick_visuals(0.001)
		game._resolve_actions()
		check(victim.hp < 100, "Impact happens exactly on contact " + str(hero))
		var contact = Bank.sample(frames, &"attack", game.player.action_elapsed)
		check(int(contact.x) == contact_frame, "Contact uses the extended-weapon frame " + str(hero))
		var hp: float = victim.hp
		game._resolve_actions()
		check(victim.hp == hp, "Contact event fires once " + str(hero))
		game._process(0.0)
		var view = game.visuals[game.player]
		check(view.sprite.visible and view.sprite.animation==&"attack" and view.sprite.frame==contact_frame, "Complete pencil figure reaches the contact pose on the damage event " + str(hero))
		var x: float = game.player.x
		view.sync()
		check(game.player.x == x, "Presentation never moves the combat body " + str(hero))
	reset()
	game.attack()
	Input.action_press("move_right")
	var start_x: float = game.player.x
	game._read_input(0.016)
	check(game.player.x == start_x, "Attack startup stays committed")
	game.player.tick_visuals(game.ATTACK_LENGTH[0] * 0.75)
	game._read_input(0.016)
	check(game.player.x > start_x, "Movement returns during attack recovery")
	Input.action_release("move_right")
	reset()
	var victim = target(1)
	game.attack()
	game.dodge()
	game.player.tick_visuals(0.18)
	game._resolve_actions()
	check(victim.hp == 100 and game.pending_actions.is_empty(), "Dodge cancels the uncommitted swing")
	reset()
	victim = target(1)
	game.attack()
	game.switch_hero(1)
	game.player.tick_visuals(0.12)
	game._resolve_actions()
	check(victim.hp == 88, "Switch cancels the old swing and delivers only the incoming entry")
	reset(2)
	game.ranged()
	check(game.projectiles.is_empty(), "Crossbow does not fire before release")
	game.player.tick_visuals(game.RANGED_LENGTH[2] * 0.46)
	game._resolve_actions()
	check(game.projectiles.size() == 1, "Crossbow fires on the release frame")
	reset()
	game.player.moving = true
	game._tick_world(0.04)
	var clock: float = game.player.locomotion_time
	game.mode = "paused"
	game._physics_process(0.2)
	check(game.player.locomotion_time == clock, "Pause freezes the animation clock")
	game.mode = "playing"
	game.hit_stop = 0.1
	game._physics_process(0.02)
	check(game.player.locomotion_time == clock, "Hit-stop freezes the animation clock")
	for kind in ["hero", "enemy"]:
		for i in range(3):
			var frames: SpriteFrames = Bank.library(kind + "_" + str(i))
			for clip in frames.get_animation_names():
				check(Bank.length_of(frames, clip) > 0, "Positive clip duration")
				var end = Bank.sample(frames, clip, Bank.length_of(frames, clip) * 10)
				check(end.x >= 0 and end.x < frames.get_frame_count(clip), "Clip sampler stays within bounds")
	print("ANIMATION TIMING: %d passed / %d total" % [checks - failures, checks])
	game.shutdown_audio()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

extends SceneTree
var checks: int = 0
var failures: Array[String] = []
var game
const Fighter = preload("res://scripts/fighter.gd")

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("FAIL: " + label)

func fresh() -> void:
	game.start_game()
	game.set_physics_process(false)
	game.muted = true

func target(x: float, lane: int):
	var enemy = Fighter.new()
	enemy.kind = "raider"
	enemy.x = x
	enemy.lane = lane
	enemy.y = game.LANES[lane]
	enemy.hp = 100.0
	enemy.max_hp = 100.0
	game.enemies.append(enemy)
	return enemy

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	fresh()
	check(game.wave == 1 and game.living_enemies() == 5, "First encounter starts with five opponents")
	game.enemies.clear()
	var same = target(game.player.x + 65, 1)
	var other = target(game.player.x + 65, 0)
	game.attack()
	check(same.hp == 100, "Melee does not hit during anticipation")
	game.player.tick_visuals(0.17)
	game._resolve_actions()
	check(same.hp < 100 and other.hp == 100, "Melee can hit only its own plane")
	var old_hp: float = same.hp
	game.attack()
	check(same.hp == old_hp, "Attack recovery prevents repeated same-frame hits")
	game.player.hp = 73
	game.switch_hero(1)
	check(game.health[0] == 73 and game.player.hp == 110, "Swap stores outgoing health and restores incoming health")
	game.swap_cd = 0
	game.switch_hero(0)
	check(game.player.hp == 73, "Switching back never heals a damaged hero")
	game.special()
	var fx_count: int = game.effects.size()
	game.special()
	check(game.effects.size() == fx_count and game.cooldowns[0] > 0, "Special cooldown prevents repeat casting")
	game.player.lane_cooldown = 0
	game.player.lane = 0
	game.change_lane(-1)
	check(game.player.lane == 0, "Back plane cannot be exceeded")
	game.change_lane(1)
	check(game.player.lane == 1 and game.player.invincible > 0, "Lane transition grants a brief escape window")
	game.dodge()
	var hp: float = game.player.hp
	game.damage_player(90, -1)
	check(game.player.hp == hp, "Dodge protects against incoming damage")
	fresh()
	game.player.invincible = 0
	game.player.facing = 1
	game.blocking = true
	game.damage_player(20, -1)
	check(is_equal_approx(game.player.hp, 157.0), "Shield reduces attacks from the faced side")
	game.player.invincible = 0
	game.damage_player(20, 1)
	check(is_equal_approx(game.player.hp, 137.0), "Shield does not protect the back")
	fresh()
	game.enemies.clear()
	game.swap_cd = 0
	game.switch_hero(2)
	game.special()
	game.player.tick_visuals(0.21)
	game._resolve_actions()
	check(not game.echo.is_empty() and game.echo.lane != game.player.lane and game.projectiles.size() == 3, "Echo occupies another plane; crossbow volley covers all planes")
	var echo_target = target(game.echo.x + 80, game.echo.lane)
	game.attack_cd = 0
	game.player.tick_visuals(0.31)
	game.attack()
	game.player.tick_visuals(0.15)
	game._resolve_actions()
	check(echo_target.hp < 100, "Scimitar attack is replicated by the echo")
	game._tick_world(5.2)
	check(game.echo.is_empty(), "Echo expires and releases its state")
	fresh()
	game.enemies.clear()
	var ranged_target = target(game.player.x + 180, 1)
	game.shoot(game.player.x, 1, 1, false, 17, Color.CYAN)
	game._tick_projectiles(0.3)
	check(ranged_target.hp == 83, "Swept projectile collision prevents tunneling at large steps")
	fresh()
	var enemy = game.enemies[0]
	enemy.x = game.player.x + 50
	enemy.lane = game.player.lane
	enemy.y = game.player.y
	enemy.timer = 0
	game._tick_enemy(enemy, 0.02)
	check(enemy.state == Fighter.State.WINDUP, "Melee enemy warns before attacking")
	game._tick_enemy(enemy, 0.8)
	enemy.tick_visuals(0.26)
	game._resolve_actions()
	check(enemy.state == Fighter.State.RECOVER and game.player.hp < 160, "Enemy damages the player and enters recovery")
	fresh()
	game.player.invincible = 0
	game.damage_player(999, -1)
	check(game.health[0] == 0 and game.player.hero == 1 and game.mode == "playing", "Fallen hero automatically hands off to a surviving ally")
	game.player.invincible = 0
	game.damage_player(999, -1)
	game.player.invincible = 0
	game.damage_player(999, -1)
	check(game.mode == "defeat", "Exhausting all three heroes triggers defeat")
	fresh()
	for expected_wave in range(1, 4):
		check(game.wave == expected_wave, "Wave sequence " + str(expected_wave))
		for e in game.enemies:
			if e.alive():
				game.damage_enemy(e, 1000, 1, Color.WHITE)
		game._tick_world(0.6)
		if expected_wave < 3:
			check(game.mode == "playing" and not game.wave_active, "Cleared encounter unlocks exploration")
			game.player.x = 1750 if expected_wave == 1 else 3050
			game._tick_world(0.02)
	check(game.mode == "victory" and game.kills == 14, "Two encounters and the miniboss encounter complete the demo")
	fresh()
	Input.action_press("move_right")
	var start_x: float = game.player.x
	game._read_input(0.1)
	Input.action_release("move_right")
	check(game.player.x > start_x, "Bound movement input reaches the controller")
	var pause_event = InputEventAction.new()
	pause_event.action = "pause_demo"
	pause_event.pressed = true
	game._unhandled_input(pause_event)
	check(game.mode == "paused", "Pause input freezes gameplay")
	game._unhandled_input(pause_event)
	check(game.mode == "playing", "Pause input resumes gameplay")
	game.start_game()
	check(game.kills == 0 and game.player.hero == 0 and game.health == [160.0, 110.0, 130.0], "Restart restores the party and encounter state")
	print("COMBAT CHECKS: %d passed / %d total" % [checks - failures.size(), checks])
	game.shutdown_audio()
	await create_timer(0.12).timeout
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

extends Node2D
const Texts=preload("res://scripts/text_data.gd")
## Three-lane beat 'em up prototype. Fixed-step combat, independent presentation.
const RunRules=preload("res://scripts/pilgrim_run.gd")
const ArchiveRules=preload("res://scripts/archive_run.gd")
var campaign: bool=true
var run=ArchiveRules.new()
var reward_cursor: int=0
const Fighter = preload("res://scripts/fighter.gd")
const Painter = preload("res://scripts/pencil_painter.gd")
const ActorVisual = preload("res://scripts/pencil_actor.gd")
const CROSSBOW_MUZZLE=Vector2(158,-154)
const ArchiveScenery=preload("res://scripts/archive_scenery.gd")
var archive_backdrop: Node2D
var archive_foreground: Node2D
const LANES = [470.0, 560.0, 650.0]
var HEROES = [
	{"name": "", "role": "", "color": Color("b96b2b"), "hp": 160.0, "speed": 240.0, "damage": 23.0, "rate": 0.36, "cooldown": 5.5, "special": ""},
	{"name": "", "role": "", "color": Color("775398"), "hp": 110.0, "speed": 330.0, "damage": 15.0, "rate": 0.23, "cooldown": 4.0, "special": ""},
	{"name": "", "role": "", "color": Color("3c7d7a"), "hp": 130.0, "speed": 285.0, "damage": 19.0, "rate": 0.29, "cooldown": 6.0, "special": ""}
]
const ATTACK_LENGTH = [0.48, 0.36, 0.42]
const CONTACT_PHASE = [0.34, 0.24, 0.34]
const RANGED_LENGTH = [0.42, 0.30, 0.34]
var player = Fighter.new()
var enemies: Array = []
var projectiles: Array = []
var effects: Array = []
var health: Array = [160.0, 110.0, 130.0]
var cooldowns: Array = [0.0, 0.0, 0.0]
var mode: String = "title"
var paused_mode: String="playing"
var painter: Node2D
var time: float = 0.0
const WORLD_ZOOM = 1.24
const CAMERA_PIVOT = Vector2(600,480)
var camera_x: float = 0.0
var trauma: float = 0.0
var hit_stop: float = 0.0
var attack_cd: float = 0.0
var ranged_cd: float = 0.0
var dash_cd: float = 0.0
var dash_time: float = 0.0
var swap_cd: float = 0.0
var combo: int = 0
var combo_time: float = 0.0
var kills: int = 0
var wave: int = 0
var wave_active: bool = false
var wave_banner: float = 0.0
var stage_left: float = 70.0
var stage_right: float = 4120.0
var echo: Dictionary = {}
var echo_time: float = 0.0
var echo_attack: float = 0.0
var hero_banner: float = 0.0
var super_banner: Dictionary = {}
var hurt_flash: float = 0.0
var blocking: bool = false
var reduced_motion: bool = false
var muted: bool = false
var help_open: bool = false
var sound_players: Array[AudioStreamPlayer] = []
var ambience: AudioStreamPlayer
var sounds: Dictionary = {}
var rng = RandomNumberGenerator.new()
var enemy_serial: int = 0
var input_buffer: float = 0.0
var chain_timer: float = 0.0
var chain_step: int = -1
var relay_cd: float = 0.0
var relay_entry: bool = false
var encounter_time: float = 0.0
var test_mode: bool = false
var pending_actions: Array = []
var actor_layer: Node2D
var overlay: Node2D
var visuals: Dictionary = {}
var echo_visual: Node2D

func _exit_tree() -> void:
	shutdown_audio()

func shutdown_audio() -> void:
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null
	for voice in sound_players:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		shutdown_audio()
		await get_tree().create_timer(0.12).timeout
		get_tree().quit()

func _ready() -> void:
	get_tree().auto_accept_quit = false
	run.game=self
	rng.seed = 61409
	_setup_input()
	_setup_audio()
	archive_backdrop=ArchiveScenery.new()
	archive_backdrop.game=self
	archive_backdrop.name="GraphiteBackgroundPlanes"
	add_child(archive_backdrop)
	painter = Painter.new()
	painter.game = self
	add_child(painter)
	actor_layer = Node2D.new()
	actor_layer.name = "Fighters"
	actor_layer.y_sort_enabled = true
	add_child(actor_layer)
	archive_foreground=ArchiveScenery.new()
	archive_foreground.game=self
	archive_foreground.foreground_pass=true
	archive_foreground.name="GraphiteForegroundPlane"
	add_child(archive_foreground)
	overlay = Painter.new()
	overlay.game = self
	overlay.overlay_pass = true
	overlay.name = "EffectsAndHUD"
	add_child(overlay)
	_reset()
	if "--showcase" in OS.get_cmdline_user_args():
		start_game(true)
		test_mode=true
	if "--capture-title" in OS.get_cmdline_user_args() or "--showcase" in OS.get_cmdline_user_args():
		_capture_later()

func _capture_later() -> void:
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var label = "title" if mode == "title" else "gameplay"
	get_viewport().get_texture().get_image().save_png("res://artifacts/" + label + ".png")
	if "--quit-after-capture" in OS.get_cmdline_user_args():
		shutdown_audio()
		await get_tree().create_timer(0.12).timeout
		get_tree().quit()

func _bind(action: String, keys: Array, button: int = -1, axis: int = -1, axis_value: float = 0.0) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)
	for code in keys:
		var key = InputEventKey.new()
		key.physical_keycode = code
		InputMap.action_add_event(action, key)
	if button >= 0:
		var event = InputEventJoypadButton.new()
		event.button_index = button
		InputMap.action_add_event(action, event)
	if axis >= 0:
		var event = InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = axis_value
		InputMap.action_add_event(action, event)

func _setup_input() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT], JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_bind("move_right", [KEY_D, KEY_RIGHT], JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_bind("lane_up", [KEY_W, KEY_UP], JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_bind("lane_down", [KEY_S, KEY_DOWN], JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_bind("spell_2", [KEY_U], JOY_BUTTON_LEFT_SHOULDER)
	_bind("spell_3", [KEY_I], JOY_BUTTON_RIGHT_SHOULDER)
	_bind("party_super", [KEY_V], JOY_BUTTON_RIGHT_STICK)
	_bind("guard", [KEY_Q])
	_bind("attack", [KEY_J], JOY_BUTTON_X)
	_bind("special", [KEY_K], JOY_BUTTON_Y)
	_bind("ranged", [KEY_L], JOY_BUTTON_B)
	_bind("dodge", [KEY_SPACE, KEY_SHIFT], JOY_BUTTON_A)
	_bind("next_hero", [KEY_TAB, KEY_E], JOY_BUTTON_RIGHT_SHOULDER)
	_bind("previous_hero", [KEY_Q], JOY_BUTTON_LEFT_SHOULDER)
	_bind("hero_0", [KEY_1])
	_bind("hero_1", [KEY_2])
	_bind("hero_2", [KEY_3])
	_bind("begin", [KEY_ENTER], JOY_BUTTON_START)
	_bind("pause_demo", [KEY_ESCAPE, KEY_P], JOY_BUTTON_BACK)
	_bind("restart", [KEY_R])
	_bind("mute_demo", [KEY_M])
	_bind("help_demo", [KEY_F1])
	_bind("motion_demo", [KEY_F2])

func _setup_audio() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for key in ["hit", "slash", "fire", "switch", "hurt", "bolt"]:
		var path = "res://assets/audio/" + key + ".wav"
		if ResourceLoader.exists(path):
			sounds[key] = load(path)
	for i in range(10):
		var voice = AudioStreamPlayer.new()
		voice.volume_db = -14.0
		add_child(voice)
		sound_players.append(voice)
	if ResourceLoader.exists("res://assets/audio/ambience.wav"):
		ambience = AudioStreamPlayer.new()
		ambience.stream = load("res://assets/audio/ambience.wav")
		ambience.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		ambience.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		ambience.stream.loop_begin = 0
		ambience.stream.loop_end = 352800
		ambience.volume_db = -23.0
		add_child(ambience)
		ambience.play()

func sound(key: String) -> void:
	if muted or not sounds.has(key):
		return
	for voice in sound_players:
		if not voice.playing:
			voice.stream = sounds[key]
			voice.pitch_scale = rng.randf_range(0.94, 1.06)
			voice.play()
			return

func _reset() -> void:
	paused_mode="playing"
	Texts.reload()
	for i in range(3): HEROES[i].merge(Texts.table("abilita").heroes[i],true)
	if campaign:
		var campaign_config=run.content.read_json("res://data/campagna.json")
		run.mission_id=str(campaign_config.get("mission","archivio"))
	run.reset()
	enemy_serial=0
	player = Fighter.new()
	player.x = 350.0
	player.previous_x = player.x
	player.hp = 160.0
	player.max_hp = 160.0
	health = [160.0, 0.0, 0.0]
	cooldowns = [0.0, 0.0, 0.0]
	enemies.clear()
	projectiles.clear()
	effects.clear()
	super_banner.clear()
	echo.clear()
	echo_time = 0.0
	echo_attack = 0.0
	wave = 0
	wave_active = false
	wave_banner = 0.0
	combo = 0
	combo_time = 0.0
	kills = 0
	camera_x = 0.0
	attack_cd = 0.0
	ranged_cd = 0.0
	dash_cd = 0.0
	dash_time = 0.0
	swap_cd = 0.0
	trauma = 0.0
	hit_stop = 0.0
	stage_left = 70.0
	stage_right = 4120.0
	blocking = false
	help_open = false
	chain_timer=0.0
	chain_step=-1
	relay_cd=0.0
	relay_entry=false
	encounter_time=0.0
	input_buffer=0.0
	pending_actions.clear()
	if is_instance_valid(actor_layer):
		for child in actor_layer.get_children():
			child.queue_free()
	visuals.clear()
	echo_visual = null

func _process(_dt: float) -> void:
	if not is_instance_valid(actor_layer):
		return
	actor_layer.scale=Vector2.ONE*(1.0 if mode=="title" else WORLD_ZOOM)
	actor_layer.position=CAMERA_PIVOT*(1.0-actor_layer.scale.x)
	var actors: Array = enemies.duplicate()
	actors.append(player)
	for fighter in actors:
		if not visuals.has(fighter):
			var view = ActorVisual.new()
			view.actor = fighter
			view.game = self
			actor_layer.add_child(view)
			visuals[fighter] = view
		visuals[fighter].sync()
	for fighter in visuals.keys():
		if not actors.has(fighter):
			visuals[fighter].queue_free()
			visuals.erase(fighter)
	if not echo.is_empty():
		if not is_instance_valid(echo_visual):
			echo_visual = ActorVisual.new()
			echo_visual.actor = player
			echo_visual.game = self
			echo_visual.echo_view = true
			actor_layer.add_child(echo_visual)
		echo_visual.sync()
	elif is_instance_valid(echo_visual):
		echo_visual.visible = false

func start_game(archive: bool=false) -> void:
	if archive!=campaign:
		campaign=archive
		run=ArchiveRules.new() if campaign else RunRules.new()
		run.game=self
	_reset()
	if campaign and not run.content.errors.is_empty():
		mode="title"
		return
	mode = "playing"
	spawn_wave()

func hero_card_rect(index: int) -> Rect2:
	return Rect2(24+index*278,20,266,112)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_B and mode=="title":
		start_game(false)
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F3:
		get_tree().change_scene_to_file("res://scenes/pencil_studio.tscn")
		return
	if event.is_action_pressed("mute_demo"):
		muted=not muted
		if ambience: ambience.volume_db=-80 if muted else -23
	if event.is_action_pressed("motion_demo"): reduced_motion=not reduced_motion
	if event.is_action_pressed("restart") and mode not in ["title","selection"]:
		start_game(campaign)
		return
	if event.is_action_pressed("help_demo"): help_open=not help_open
	if help_open:
		if event.is_action_pressed("pause_demo"): help_open=false
		return
	if mode=="stage_clear":
		if event.is_action_pressed("pause_demo"):
			paused_mode="stage_clear"
			mode="paused"
		elif run.stage_clear_elapsed>=0.35 and (event.is_action_pressed("begin") or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)):
			run.finish_stage_clear()
		return
	if mode=="level_intro":
		if event.is_action_pressed("pause_demo"):
			paused_mode="level_intro"
			mode="paused"
		elif run.entrance.elapsed>=0.25 and (event.is_action_pressed("begin") or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)):
			run.finish_entrance()
		return
	if mode=="prologue":
		if event.is_action_pressed("pause_demo"):
			run.finish_prologue()
		elif event.is_action_pressed("dodge"):
			run.prologue_paused=not run.prologue_paused
		elif event.is_action_pressed("begin") or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT):
			run.finish_prologue()
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index==MOUSE_BUTTON_WHEEL_UP:
				run.prologue_elapsed=maxf(0,run.prologue_elapsed-2)
				run.prologue_finished=false
			elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN: run.prologue_elapsed+=2
		return
	if mode=="interlude":
		if event.is_action_pressed("pause_demo"):
			run.show_rewards()
		elif event.is_action_pressed("begin") or event.is_action_pressed("dodge"):
			run.advance_interlude()
		elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			run.advance_interlude()
		return
	if mode=="reward":
		if event.is_action_pressed("move_left"): reward_cursor=posmod(reward_cursor-1,run.choices.size())
		if event.is_action_pressed("move_right"): reward_cursor=posmod(reward_cursor+1,run.choices.size())
		for i in range(3):
			if event.is_action_pressed("hero_"+str(i)): run.choose(i)
		if event.is_action_pressed("begin"): run.choose(reward_cursor)
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			for i in range(run.choices.size()):
				if reward_rect(i).has_point(event.position): run.choose(i); break
		return
	if event.is_action_pressed("begin"):
		if mode=="title": mode="selection"
		elif mode=="selection": start_game(true)
		elif mode in ["victory","defeat"]: start_game(campaign)
		elif mode=="paused": mode=paused_mode
	elif event.is_action_pressed("pause_demo"):
		if mode=="selection": mode="title"
		elif mode=="playing":
			paused_mode="playing"
			mode="paused"
		elif mode=="paused": mode=paused_mode
		elif mode in ["victory","defeat"]: mode="title"
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var pos=event.position
		if mode=="selection" and Rect2(90,620,340,64).has_point(pos): start_game(true)
		elif mode in ["title","victory","defeat"] and Rect2(88,535,320,64).has_point(pos):
			if mode=="title": mode="selection"
			else: start_game(campaign)
		elif mode=="paused" and Rect2(550,460,340,64).has_point(pos): mode=paused_mode

func reward_rect(index: int) -> Rect2:
	return Rect2(66+index*438,400,412,320)

func _physics_process(dt: float) -> void:
	time += dt
	trauma = maxf(0.0, trauma - dt * 2.2)
	hurt_flash = maxf(0.0, hurt_flash - dt)
	if painter:
		painter.queue_redraw()
	if overlay:
		overlay.queue_redraw()
	if mode=="stage_clear" and not help_open:
		run.tick_stage_clear(dt)
		return
	if mode=="level_intro" and not help_open:
		run.tick_entrance(dt)
		return
	if mode=="prologue" and not help_open:
		if Input.is_action_pressed("lane_up"):
			run.prologue_elapsed=maxf(0,run.prologue_elapsed-dt*3)
			run.prologue_finished=false
		elif Input.is_action_pressed("lane_down") and run.prologue_paused:
			run.prologue_elapsed+=dt*5
		else:
			run.tick_prologue(dt*(5 if Input.is_action_pressed("lane_down") else 1))
	if mode=="interlude" and not help_open:
		run.tick_interlude(dt)
	if mode != "playing" or help_open:
		return
	if not test_mode:
		_read_input(dt)
	if hit_stop > 0.0:
		hit_stop -= dt
		return
	_tick_world(dt)

func _read_input(dt: float) -> void:
	if horizontal_locked():
		var direction=Input.get_axis("move_left","move_right")
		if absf(direction)>0.1 and not player.action_active() and dash_time<=0:
			player.facing=signf(direction)
	if Input.is_action_just_pressed("lane_up"):
		change_lane(-1)
	if Input.is_action_just_pressed("lane_down"):
		change_lane(1)
	if Input.is_action_just_pressed("dodge"):
		dodge()
	if Input.is_action_just_pressed("special"):
		special()
	if Input.is_action_just_pressed("ranged"): run.cast(1)
	if Input.is_action_just_pressed("spell_2"): run.cast(2)
	if Input.is_action_just_pressed("spell_3"): run.cast(3)
	if Input.is_action_just_pressed("party_super"): run.call_allies()
	blocking=Input.is_action_pressed("guard") and dash_time<=0 and not player.action_active()
	if Input.is_action_just_pressed("attack"):
		input_buffer = 0.18
	input_buffer = maxf(0.0, input_buffer - dt)
	if Input.is_action_pressed("attack") or input_buffer > 0.0:
		if attack():
			input_buffer = 0.0
	var axis = Input.get_axis("move_left", "move_right")
	player.moving = absf(axis) > 0.1 and dash_time <= 0.0 and not horizontal_locked()
	if player.moving:
		if player.attack_time <= 0.0:
			player.facing = signf(axis)
		var speed: float = HEROES[player.hero].speed
		if blocking:
			speed *= 0.4
		if player.attack_time > 0.0:
			# Commit through contact; return control smoothly during recovery.
			var phase = player.action_elapsed / maxf(player.action_length, 0.001)
			var recovery = clampf((phase - 0.42) / 0.45, 0.0, 1.0)
			speed *= recovery * recovery * (3.0 - 2.0 * recovery)
		player.x += axis * speed * dt

func horizontal_locked() -> bool:
	return campaign and run.is_resistance()

func _tick_world(dt: float) -> void:
	encounter_time+=dt
	run.tick(dt)
	chain_timer=maxf(0.0,chain_timer-dt)
	relay_cd=maxf(0.0,relay_cd-dt)
	attack_cd = maxf(0.0, attack_cd - dt)
	ranged_cd = maxf(0.0, ranged_cd - dt)
	dash_cd = maxf(0.0, dash_cd - dt)
	swap_cd = maxf(0.0, swap_cd - dt)
	hero_banner = maxf(0.0, hero_banner - dt)
	if not super_banner.is_empty():
		super_banner.life = maxf(0.0, super_banner.life - dt)
		if super_banner.life <= 0.0:
			super_banner.clear()
	wave_banner = maxf(0.0, wave_banner - dt)
	combo_time = maxf(0.0, combo_time - dt)
	if combo_time == 0.0:
		combo = 0
	for i in range(3):
		cooldowns[i] = maxf(0.0, cooldowns[i] - dt)
	if dash_time > 0.0:
		dash_time -= dt
		if not horizontal_locked(): player.x += player.facing * 760.0 * dt
		if int(time * 60.0) % 3 == 0:
			effects.append({"kind": "ghost", "x": player.x, "y": player.y, "hero": player.hero, "life": 0.22, "max": 0.22, "facing": player.facing})
	if horizontal_locked():
		player.x=run.horizontal_anchor()
		player.previous_x=player.x
		player.knockback=0
		player.moving=false
	player.tick_visuals(dt)
	player.x = clampf(player.x, run.movement_left() if campaign else stage_left, run.movement_limit() if campaign else stage_right)
	player.y = move_toward(player.y, LANES[player.lane], 750.0 * dt)
	for enemy in enemies:
		enemy.tick_visuals(dt)
		if enemy.alive():
			_tick_enemy(enemy, dt)
	_resolve_actions()
	enemies = enemies.filter(func(e): return e.dead_time < 0.55)
	_tick_projectiles(dt)
	for fx in effects:
		fx.life -= dt
		if fx.kind == "spark":
			fx.x += fx.vx * dt
			fx.y += fx.vy * dt
			fx.vy += 350.0 * dt
	effects = effects.filter(func(fx): return fx.life > 0.0)
	echo_time = maxf(0.0, echo_time - dt)
	echo_attack = maxf(0.0, echo_attack - dt)
	if echo_time <= 0.0:
		echo.clear()
	if wave_active and (run.objective_complete() if campaign else living_enemies()==0):
		run.finish_room()
		reward_cursor=0
		return
	if horizontal_locked():
		camera_x=run.resistance_camera()
	else:
		var target = clampf(player.x - 540.0, stage_left - 180.0, stage_right - 1200.0)
		camera_x = lerpf(camera_x, target, 1.0 - exp(-4.5 * dt))

func living_enemies() -> int:
	var count = 0
	for enemy in enemies:
		if enemy.alive():
			count += 1
	return count

func spawn_wave() -> void:
	run.begin_room()

func change_lane(direction: int) -> void:
	if player.lane_cooldown > 0.0:
		return
	var next = clampi(player.lane + direction, 0, 2)
	if next == player.lane:
		return
	player.lane = next
	if player.action_active():
		player.begin_action(&"dodge", 0.18)
	player.lane_cooldown = 0.22
	player.invincible = maxf(player.invincible, 0.14)
	burst(player.x, player.y - 5.0, HEROES[player.hero].color, 5)

func cycle_hero(direction: int) -> void:
	for offset in range(1, 4):
		var candidate = posmod(player.hero + direction * offset, 3)
		if health[candidate] > 0.0:
			switch_hero(candidate)
			return

func switch_hero(index: int) -> void:
	return # The protagonist is fixed for this run.

func dodge() -> void:
	if dash_cd > 0.0:
		return
	dash_cd = 0.85
	dash_time = 0.19
	player.invincible = 0.3
	player.begin_action(&"dodge", 0.19)
	sound("slash")

func attack() -> bool:
	var chain_cancel=player.action==&"attack" and player.action_elapsed>=player.action_length*0.82
	if dash_time>0 or not player.alive() or (player.action_active() and not chain_cancel) or (attack_cd>0 and not chain_cancel):
		return false
	chain_step=posmod(chain_step+1,3) if chain_timer>0 else 0
	player.combo_step=chain_step
	chain_timer=1.05
	var duration: float = ATTACK_LENGTH[player.hero]
	attack_cd = duration
	player.begin_action(&"attack", duration)
	_schedule("melee", player, duration * CONTACT_PHASE[player.hero])
	return true

func _schedule(kind: String, owner, contact: float) -> void:
	pending_actions.append({"kind": kind, "owner": owner, "serial": owner.action_serial,
		"hero": owner.hero, "contact": contact, "direction": owner.facing, "relay": relay_entry if kind=="entry" else false})

func _resolve_actions() -> void:
	for event in pending_actions.duplicate():
		var owner = event.owner
		if not owner.alive() or owner.action_serial != event.serial:
			pending_actions.erase(event)
			continue
		if owner.action_elapsed + 0.000001 < event.contact:
			continue
		pending_actions.erase(event)
		match event.kind:
			"run_spell":
				run.contact()
			"melee":
				_melee_contact(event.direction)
			"entry":
				_entry_contact(event.direction,event.relay)
			"ranged":
				var col: Color = HEROES[player.hero].color
				shoot(player.x + event.direction * 45.0, player.lane, event.direction, false, 17.0, col)
				sound("bolt")
			"special":
				_special_contact()
			"enemy":
				_enemy_contact(owner, event.direction)

func _entry_contact(direction: float, relay: bool) -> void:
	var color: Color=HEROES[player.hero].color
	if relay:
		text_effect(player.x,player.y-125,Texts.ui("relais")+HEROES[player.hero].name,color)
		match player.hero:
			0:
				player.invincible=maxf(player.invincible,0.5)
			1:
				player.x=clampf(player.x+direction*65,stage_left,stage_right)
			2:
				echo={"x":player.x+direction*95,"lane":posmod(player.lane+1,3)}
				echo_time=2.0
	strike(player.x,player.lane,direction,145.0 if relay else 110.0,20.0 if relay else 12.0,color,relay and player.hero==0)
	effects.append({"kind":"slash","x":player.x+direction*45,"y":player.y-63,"life":0.22,"max":0.22,"color":color,"facing":direction,"large":relay})

func _melee_contact(direction: float) -> void:
	var finisher = player.combo_step==2
	var reach: float = [132.0,135.0,166.0][player.hero] if finisher else [110.0,120.0,145.0][player.hero]
	var damage: float = HEROES[player.hero].damage * (1.65 if finisher else 1.0)
	var color: Color = HEROES[player.hero].color
	var before=combo
	strike(player.x, player.lane, direction, reach, damage, color, finisher)
	if combo>before: run.mana=minf(100,run.mana+10)
	effects.append({"kind": "slash", "x": player.x + direction * 45.0, "y": player.y - 63.0, "life": 0.16, "max": 0.16, "color": color, "facing": direction, "large": finisher})
	if not echo.is_empty() and player.hero == 2:
		echo_attack = 0.25
		strike(echo.x, echo.lane, player.facing, 180.0, damage * 0.8, Color("8ae7ff"), false)
		effects.append({"kind": "slash", "x": echo.x + player.facing * 40.0, "y": LANES[echo.lane] - 63.0, "life": 0.22, "max": 0.22, "color": Color("8ae7ff"), "facing": player.facing, "large": false})
	sound("slash")

func strike(origin: float, lane: int, facing: float, reach: float, damage: float, color: Color, heavy: bool) -> void:
	for enemy in enemies:
		if not enemy.alive() or enemy.lane != lane:
			continue
		var distance: float = (enemy.x - origin) * facing
		if distance >= -35.0 and distance <= reach:
			damage_enemy(enemy, damage, facing, color, heavy)

func damage_enemy(enemy, amount: float, direction: float, color: Color, heavy: bool = false, periodic: bool=false) -> void:
	if not enemy.alive():
		return
	run.intesa=minf(100,run.intesa+minf(enemy.hp,amount)*0.11) if not run.assist_damage else run.intesa
	enemy.hp = maxf(0.0, enemy.hp - amount)
	if periodic:
		text_effect(enemy.x,enemy.y-115,str(int(amount)),color)
		if enemy.hp<=0:
			enemy.state=Fighter.State.DEAD
			kills+=1
		return
	enemy.flash = 0.13
	enemy.knockback = direction * (250.0 if heavy else 125.0)
	enemy.poise_hits=enemy.poise_hits+1 if enemy.poise_time>0 else 1
	enemy.poise_time=0.85
	var stagger=enemy.kind!="warden" or enemy.stagger_guard<=0 and (heavy or enemy.poise_hits>=3)
	if stagger:
		enemy.state = Fighter.State.STUN
		enemy.begin_action(&"hurt", 0.22)
		enemy.timer = 0.55 if enemy.kind=="warden" else 0.42 if heavy else 0.24
		enemy.poise_hits=0
		if enemy.kind=="warden":
			enemy.stagger_guard=2.4
	if enemy.kind=="warden":
		enemy.knockback=direction*(90.0 if stagger else 25.0)
	combo += 1
	combo_time = 2.6
	trauma = minf(0.5, trauma + (0.2 if heavy else 0.08))
	hit_stop = 0.025 if heavy else 0.0
	burst(enemy.x, enemy.y - 65.0, color, 22 if heavy else 13)
	effects.append({"kind":"impact","x":enemy.x,"y":enemy.y-65.0,"life":0.24,"max":0.24,"color":color,"heavy":heavy,"seed":float(combo)})
	text_effect(enemy.x, enemy.y - 115.0, str(int(amount)), color)
	sound("hit")
	if enemy.hp <= 0.0:
		enemy.state = Fighter.State.DEAD
		kills += 1
		burst(enemy.x, enemy.y - 50.0, Color("b4cbd3"), 13)

func ranged() -> void:
	if ranged_cd > 0.0 or dash_time > 0.0 or player.action_active():
		return
	ranged_cd = 0.46 if player.hero == 2 else 0.55
	player.begin_action(&"ranged", RANGED_LENGTH[player.hero])
	_schedule("ranged", player, RANGED_LENGTH[player.hero] * 0.46)

func special() -> void:
	run.cast(0)

func _special_contact() -> void:
	var col: Color = HEROES[player.hero].color
	match player.hero:
		0:
			for i in range(8):
				var fx_x: float = player.x + player.facing * (40.0 + i * 68.0)
				effects.append({"kind": "flame", "x": fx_x, "y": player.y, "life": 0.75 + i * 0.045, "max": 1.15, "color": col, "seed": float(i)})
				burst(fx_x, player.y - 32, Color("ffd477"), 5)
			strike(player.x, player.lane, player.facing, 590.0, 52.0, col, true)
			trauma = 0.48
			sound("fire")
		1:
			var old_x: float = player.x
			player.x = clampf(player.x + player.facing * 320.0, stage_left, stage_right)
			for enemy in enemies:
				if enemy.alive() and enemy.lane == player.lane and enemy.x >= minf(old_x, player.x) - 45 and enemy.x <= maxf(old_x, player.x) + 45:
					damage_enemy(enemy, 46.0, player.facing, col, true)
			for i in range(8):
				effects.append({"kind": "ghost", "x": lerpf(old_x, player.x, float(i) / 8.0), "y": player.y, "hero": 1, "life": 0.35 + i * 0.03, "max": 0.6, "facing": player.facing})
			sound("switch")
		2:
			manifest_echo()
	# The screen-space ink banner announces the move at cast time.

func manifest_echo() -> void:
	var other = (player.lane + 1) % 3
	echo = {"x": player.x + player.facing * 100.0, "lane": other}
	echo_time = 5.0
	burst(echo.x, LANES[other] - 65.0, Color("3c7d7a"), 22)
	for l in range(3):
		shoot(player.x, l, player.facing, false, 30.0, Color("3c7d7a"))
	sound("switch")

func shoot(x: float, lane: int, facing: float, hostile: bool, damage: float, color: Color) -> void:
	projectiles.append({"x": x, "y": LANES[lane] - 62.0, "lane": lane, "vx": facing * (430.0 if hostile else 850.0), "hostile": hostile, "damage": damage, "color": color, "life": 2.6, "trail": []})

func _tick_projectiles(dt: float) -> void:
	for bolt in projectiles:
		bolt.life -= dt
		bolt.trail.push_front(Vector2(bolt.x, bolt.y))
		if bolt.trail.size() > (14 if bolt.get("crossbow",false) else 8):
			bolt.trail.pop_back()
		var old_x: float = bolt.x
		bolt.x += bolt.vx * dt
		if bolt.hostile:
			if player.lane == bolt.lane and absf(player.y - LANES[player.lane]) < 25 and _crosses(old_x, bolt.x, player.x, 24.0):
				damage_player(bolt.damage, signf(bolt.vx))
				bolt.life = 0.0
		else:
			for enemy in enemies:
				if enemy.alive() and enemy.lane==bolt.lane and not enemy.id in bolt.get("hit_ids",[]) and _crosses(old_x,bolt.x,enemy.x,28.0):
					damage_enemy(enemy,bolt.damage,signf(bolt.vx),bolt.color)
					run.projectile_hit(bolt,enemy)
					if bolt.life<=0: break
	projectiles = projectiles.filter(func(b): return b.life > 0.0)

func _crosses(a: float, b: float, target: float, radius: float) -> bool:
	return target >= minf(a, b) - radius and target <= maxf(a, b) + radius

func visible_world_bounds() -> Vector2:
	var offset=CAMERA_PIVOT.x*(1-WORLD_ZOOM)
	return Vector2(camera_x-offset/WORLD_ZOOM,camera_x+(1440-offset)/WORLD_ZOOM)

func begin_enemy_entry(enemy, side: int) -> void:
	var edges=visible_world_bounds()
	enemy.entry_side=side if side!=0 else (1 if enemy.x>=player.x else -1)
	enemy.x=maxf(edges.y+230,player.x+440) if enemy.entry_side>0 else minf(edges.x-230,player.x-440)
	enemy.previous_x=enemy.x
	enemy.entering=true
	enemy.facing=-enemy.entry_side
	enemy.timer=0

func _tick_enemy(enemy, dt: float) -> void:
	if enemy.entering:
		var entry_edges=visible_world_bounds()
		var target=clampf(player.x+enemy.entry_side*300,maxf(stage_left+20,entry_edges.x+150),minf(stage_right-20,entry_edges.y-150))
		enemy.facing=signf(target-enemy.x)
		enemy.x=move_toward(enemy.x,target,340*dt)
		enemy.moving=true
		var edges=visible_world_bounds()
		if enemy.x>=maxf(edges.x+120,stage_left+20) and enemy.x<=minf(edges.y-120,stage_right-20):
			enemy.entering=false
			enemy.entry_lane_time=maxf(enemy.entry_lane_time,0.8)
		return
	enemy.timer -= dt
	enemy.entry_lane_time=maxf(0,enemy.entry_lane_time-dt)
	enemy.poise_time=maxf(0,enemy.poise_time-dt)
	enemy.stagger_guard=maxf(0,enemy.stagger_guard-dt)
	enemy.moving = false
	enemy.y = move_toward(enemy.y, LANES[enemy.lane], dt * 350.0)
	var dx: float = player.x - enemy.x
	if enemy.state == Fighter.State.APPROACH or (enemy.state == Fighter.State.RECOVER and not enemy.action_active()):
		enemy.facing = 1.0 if dx >= 0.0 else -1.0
	match enemy.state:
		Fighter.State.STUN:
			if enemy.timer <= 0.0:
				enemy.state = Fighter.State.APPROACH
				enemy.timer = 0.12
		Fighter.State.APPROACH:
			if enemy.timer > 0.0:
				return
			if enemy.lane != player.lane and enemy.lane_cooldown <= 0.0 and enemy.entry_lane_time<=0:
				enemy.lane += 1 if player.lane > enemy.lane else -1
				enemy.lane_cooldown = 1.35 + float(enemy.id % 3) * 0.3
			var reach = 570.0 if enemy.kind=="caster" else 125.0 if enemy.archetype=="brute" else 390.0 if enemy.kind == "archer" else 100.0 if enemy.kind=="warden" else 80.0
			if enemy.kind in ["archer","caster"] and absf(dx)<(300 if enemy.kind=="caster" else 210):
				var bounds=enemy_bounds()
				var retreat=clampf(enemy.x-enemy.facing*dt*80*(enemy.slow_factor if enemy.slow_time>0 else 1.0),bounds.x,bounds.y)
				if absf(retreat-enemy.x)>0.1:
					enemy.x=retreat
					enemy.moving=true
					return
			if absf(dx) > reach:
				var speed = 86.0 if enemy.kind == "warden" else 105.0 + float(enemy.id % 3) * 9.0
				if enemy.move_speed>0: speed=enemy.move_speed
				enemy.x += enemy.facing * dt * speed * (enemy.slow_factor if enemy.slow_time>0 else 1.0)
				enemy.moving = true
			elif enemy.lane == player.lane and absf(enemy.y - player.y) < 25.0:
				var committed=0
				for other in enemies:
					if other!=enemy and other.alive() and (other.state==Fighter.State.WINDUP or other.action==&"attack" and other.action_active()):
						committed+=1
				if committed>=2:
					enemy.timer=0.15+float(enemy.id%3)*0.08
					return
				enemy.state = Fighter.State.WINDUP
				enemy.timer = (0.75 if enemy.hp<enemy.max_hp*0.5 else 1.05) if enemy.kind == "warden" else 0.7
				if enemy.windup_duration>0: enemy.timer=enemy.windup_duration
				if enemy.kind=="warden":
					enemy.attack_variant=posmod(enemy.attack_variant+1,2)
				if enemy.kind=="caster":
					enemy.spell_target_x=player.x
					enemy.spell_target_lane=player.lane
				enemy.begin_action(&"windup", enemy.timer)
		Fighter.State.WINDUP:
			if enemy.timer <= 0.0:
				enemy.begin_action(&"attack", 0.52 if enemy.kind == "archer" else 0.54)
				_schedule("enemy", enemy, 0.24 if enemy.kind == "archer" else 0.25)
				enemy.state = Fighter.State.RECOVER
				enemy.timer = 1.8 if enemy.kind=="caster" else 1.4 if enemy.archetype=="brute" else 1.05 + float(enemy.id % 3) * 0.15
		Fighter.State.RECOVER:
			if enemy.timer <= 0.0:
				enemy.state = Fighter.State.APPROACH
	var bounds=enemy_bounds()
	enemy.x = clampf(enemy.x,bounds.x,bounds.y)

func enemy_bounds() -> Vector2:
	return Vector2(stage_left+10,stage_right-10)

func _enemy_contact(enemy, direction: float) -> void:
	if enemy.kind=="caster":
		if player.lane==enemy.spell_target_lane and absf(player.x-enemy.spell_target_x)<110 and absf(player.y-LANES[player.lane])<25:
			damage_player(14,direction)
		effects.append({"kind":"impact","x":enemy.spell_target_x,"y":LANES[enemy.spell_target_lane]-45,"life":0.42,"max":0.42,"color":Color("8c64a6"),"heavy":true,"seed":float(enemy.id)})
		effects.append({"kind":"ring","x":enemy.spell_target_x,"y":LANES[enemy.spell_target_lane],"life":0.5,"max":0.5,"color":Color("8c64a6")})
	elif enemy.archetype=="brute":
		if absi(player.lane-enemy.lane)<=1 and absf(player.x-enemy.x)<165 and (player.x-enemy.x)*direction>=-20:
			damage_player(20,direction)
		effects.append({"kind":"slash","x":enemy.x+direction*60,"y":enemy.y-65,"life":0.24,"max":0.24,"color":Color("ad7753"),"facing":direction,"large":true})
	elif enemy.kind == "archer":
		var muzzle=Vector2(enemy.x+direction*CROSSBOW_MUZZLE.x,enemy.y+CROSSBOW_MUZZLE.y)
		shoot(muzzle.x, enemy.lane, direction, true, 12.0, Color("b7654d"))
		projectiles[-1].y=muzzle.y
		projectiles[-1].crossbow=true
		effects.append({"kind":"crossbow_release","x":muzzle.x,"y":muzzle.y,"facing":direction,"life":0.16,"max":0.16})
	elif (enemy.lane == player.lane or enemy.kind=="warden" and enemy.attack_variant==1 and absi(enemy.lane-player.lane)==1) and absf(player.x - enemy.x) < (155.0 if enemy.kind=="warden" else 115.0) and (player.x - enemy.x) * direction >= -20.0 and absf(enemy.y - player.y) < (120.0 if enemy.kind=="warden" and enemy.attack_variant==1 else 32.0):
		damage_player(24.0 if enemy.kind == "warden" else 13.0, direction)
		effects.append({"kind": "slash", "x": enemy.x + direction * 30, "y": enemy.y - 60,
			"life": 0.16, "max": 0.16, "color": Color("ec6975"), "facing": direction, "large": enemy.kind == "warden"})
	if enemy.kind=="warden" and enemy.attack_variant==1:
		for lane in range(3):
			if absi(enemy.lane-lane)<=1:
				effects.append({"kind":"ring","x":enemy.x+direction*85,"y":LANES[lane]-5,"life":0.35,"max":0.35,"color":Color("ec6975")})

func damage_player(amount: float, direction: float) -> void:
	if player.invincible > 0.0 or mode != "playing":
		return
	if blocking and direction != player.facing:
		amount *= 0.15
		burst(player.x + player.facing * 30, player.y - 60, Color("efc885"), 10)
		text_effect(player.x, player.y - 130, "PARATA", Color("efc885"))
	else:
		player.knockback = direction * 170.0
		player.begin_action(&"hurt", 0.22)
		player.flash = 0.2
		hurt_flash = 0.18
		combo = 0
	amount=run.mitigate(amount)
	run.intesa=minf(100,run.intesa+amount*0.25)
	player.hp = maxf(0.0, player.hp - amount)
	health[player.hero] = player.hp
	player.invincible = 0.65
	trauma = 0.27
	sound("hurt")
	if player.hp <= 0.0:
		mode="defeat"
		super_banner.clear()

func burst(x: float, y: float, color: Color, count: int) -> void:
	for i in range(count):
		var velocity = Vector2.from_angle(rng.randf_range(-PI, PI)) * rng.randf_range(55.0, 250.0)
		var life = rng.randf_range(0.2, 0.65)
		effects.append({"kind": "spark", "x": x, "y": y, "vx": velocity.x, "vy": velocity.y - 70.0, "life": life, "max": life, "color": color, "size": rng.randf_range(1.5, 4.0)})

func text_effect(x: float, y: float, label: String, color: Color) -> void:
	effects.append({"kind": "text", "x": x, "y": y, "text": label, "life": 0.9, "max": 0.9, "color": color})

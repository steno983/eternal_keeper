extends Node2D
## A real AnimatedSprite2D, sampled from the simulation clock so pause, hit-stop,
## animation contact frames and gameplay never drift apart.
const Bank = preload("res://scripts/animation_bank.gd")
const EnemySkin = preload("res://scripts/enemy_skin.gd")
const HeroSkin = preload("res://scripts/hero_run_skin.gd")
var actor
var game: Node2D
var sprite: AnimatedSprite2D
var echo_view: bool = false
var key: String = ""
var sampled_clip: StringName = &"idle"
var enemy_skin: Node2D
var hero_skin: Node2D

func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.centered = true
	sprite.offset = Vector2(0, -146)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.speed_scale = 0.0
	add_child(sprite)
	hero_skin = HeroSkin.new()
	add_child(hero_skin)
	hero_skin.visible = false
	enemy_skin=EnemySkin.new()
	add_child(enemy_skin)
	enemy_skin.visible=false

func sync() -> void:
	if actor == null or not is_instance_valid(game):
		return
	var is_hero: bool = actor.kind == "hero"
	var index: int = actor.hero if is_hero else (0 if actor.kind == "raider" else 1 if actor.kind == "archer" else 2)
	if echo_view:
		index = 2
	var next_key = ("hero_" if is_hero else "enemy_") + str(index)
	if next_key != key:
		key = next_key
		sprite.sprite_frames = Bank.library(key)
		if is_hero:
			hero_skin.configure(index)
		else:
			enemy_skin.configure(index)
	if sprite.sprite_frames == null:
		visible = false
		return
	visible = game.mode != "title" and (not echo_view or not game.echo.is_empty())
	if not visible:
		return
	var x: float = game.echo.x if echo_view else actor.x
	var y: float = game.LANES[game.echo.lane] if echo_view else actor.y
	var strength: float = 0.0 if game.reduced_motion else game.trauma * game.trauma * 30.0
	var shake = Vector2(sin(game.time * 73.0), sin(game.time * 91.0)) * strength
	position = Vector2(x - game.camera_x, y) + shake
	var clip: StringName = &"idle"
	var clock: float = actor.locomotion_time
	if actor.action_active():
		clip = actor.action
		if sprite.sprite_frames.has_animation(clip):
			clock = actor.action_elapsed / actor.action_length * Bank.length_of(sprite.sprite_frames, clip)
	elif is_hero and game.blocking and actor.hero == 0:
		clip = &"guard"
	elif actor.moving and not echo_view:
		clip = &"run"
		var stride = [128.0, 158.0, 152.0][index] if is_hero else [94.0, 90.0, 102.0][index]
		clock = actor.travelled / stride * Bank.length_of(sprite.sprite_frames, clip)
	if echo_view and actor.hero != 2:
		clip = &"idle"
		clock = game.time
	if not sprite.sprite_frames.has_animation(clip):
		clip = &"idle"
	sampled_clip = clip
	if sprite.animation != clip:
		sprite.play(clip)
	var frame_point = Bank.sample(sprite.sprite_frames, clip, clock)
	sprite.set_frame_and_progress(int(frame_point.x), frame_point.y)
	sprite.flip_h = actor.facing < 0 if is_hero else actor.facing > 0
	# 384x320 transparent canvases retain a fixed hip anchor and baseline.
	var body_scale = 0.70 if is_hero else 0.76
	if not is_hero and index == 2:
		body_scale = 0.87
	sprite.scale = Vector2.ONE * body_scale
	var rig_running: bool = is_hero and hero_skin.parts.size()==12 and actor.alive()
	hero_skin.visible = rig_running
	var painted_enemy: bool = not is_hero and enemy_skin.parts.size()==9
	enemy_skin.visible=painted_enemy
	sprite.visible = not rig_running and not painted_enemy
	if rig_running:
		var direction: float = actor.facing
		hero_skin.scale = Vector2(body_scale * direction, body_scale)
		hero_skin.position = Vector2(-192.0 * body_scale * direction,-HeroSkin.FLOOR*body_scale)
		hero_skin.phase = actor.travelled / hero_skin.stride_length
		hero_skin.action_clip=clip
		hero_skin.action_progress=clampf(actor.action_elapsed/maxf(actor.action_length,0.001),0,1)
		hero_skin.animation_time=actor.locomotion_time
		hero_skin.combo_step=actor.combo_step
		if echo_view:
			hero_skin.action_clip=&"attack" if game.echo_attack>0 else &"idle"
			hero_skin.action_progress=game.CONTACT_PHASE[2]+(1.0-game.echo_attack/0.25)*(1.0-game.CONTACT_PHASE[2]) if game.echo_attack>0 else 0.0
		hero_skin.queue_redraw()
	if painted_enemy:
		enemy_skin.scale=Vector2(body_scale*actor.facing,body_scale)
		enemy_skin.position=Vector2(-192.0*body_scale*actor.facing,-EnemySkin.FLOOR*body_scale)
		enemy_skin.phase=actor.travelled/enemy_skin.stride_length
		enemy_skin.clip=clip
		enemy_skin.progress=clampf(actor.action_elapsed/maxf(actor.action_length,0.001),0,1)
		enemy_skin.attack_style=actor.attack_variant
		enemy_skin.motion_time=actor.locomotion_time
		enemy_skin.queue_redraw()
	sprite.rotation = 0.0
	sprite.position = Vector2.ZERO
	sprite.modulate = Color.WHITE
	if actor.flash > 0:
		sprite.modulate = Color(1.9, 1.35, 1.35)
	if is_hero and actor.invincible > 0 and actor.flash <= 0 and not echo_view:
		sprite.modulate.a = 0.8 + sin(game.time * 42) * 0.15
	if clip == &"hurt":
		sprite.rotation = -actor.facing * 0.09 * sin(actor.action_elapsed / actor.action_length * PI)
	if not actor.alive():
		var t = clampf(actor.dead_time / 0.55, 0, 1)
		sprite.rotation = actor.facing * t * t * 1.25
		sprite.position.y = t * 30
		sprite.modulate.a *= 1.0 - t
	if echo_view:
		sprite.modulate = Color(0.36, 0.8, 1.0, 0.40 * minf(1.0, game.echo_time))
	if painted_enemy:
		enemy_skin.modulate=sprite.modulate
		if not actor.alive():
			var t=clampf(actor.dead_time/0.55,0,1)
			enemy_skin.rotation=actor.facing*t*t*1.25
			enemy_skin.position.y+=t*30
		else:
			enemy_skin.rotation=0.0
	if rig_running:
		hero_skin.modulate = sprite.modulate
	queue_redraw()

func _draw() -> void:
	if actor == null or not visible:
		return
	var color = Color(0.01, 0.02, 0.03, 0.35)
	var shadow_width = 37.0
	if echo_view:
		color = Color(0.4, 0.85, 1.0, 0.13)
	var points = PackedVector2Array()
	for i in range(32):
		points.append(Vector2(cos(i * TAU / 32) * shadow_width, sin(i * TAU / 32) * 8 + 3))
	draw_colored_polygon(points, color)
	if actor.kind == "hero":
		if not echo_view:
			var accent: Color = game.HEROES[actor.hero].color
			draw_arc(Vector2(0, -154), 5, 0, TAU, 20, accent, 1.2, true)
			if game.blocking:
				var angle = 0 if actor.facing > 0 else PI
				draw_arc(Vector2(actor.facing * 23, -60), 48, angle - 1.3, angle + 1.3, 24, Color(accent, 0.35), 2, true)
	else:
		if actor.alive():
			var bar_y = -188.0 if actor.kind == "warden" else -151.0
			draw_rect(Rect2(-25, bar_y, 50, 3), Color("15232d"))
			draw_rect(Rect2(-25, bar_y, 50.0 * actor.hp / actor.max_hp, 3), Color("cb8792"))
			if actor.kind=="warden" and actor.state==game.Fighter.State.WINDUP:
				var charge=clampf(actor.action_elapsed/maxf(actor.action_length,0.01),0,1)
				for lane in range(3):
					if lane==actor.lane or actor.attack_variant==1 and absi(lane-actor.lane)<=1:
						var offset=game.LANES[lane]-actor.y
						var rect=Rect2(0 if actor.facing>0 else -160,offset-15,160,30)
						draw_rect(rect,Color(0.95,0.18,0.24,0.08+charge*0.16))
						draw_rect(rect,Color(1.0,0.40,0.40,0.65),false,1.5)
			if actor.state == game.Fighter.State.WINDUP:
				draw_string(ThemeDB.fallback_font, Vector2(-4, bar_y - 8), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f3a3a5"))
				var points2 = PackedVector2Array()
				for i in range(32):
					points2.append(Vector2(cos(i * TAU / 32) * 44, sin(i * TAU / 32) * 9 + 3))
				draw_colored_polygon(points2, Color(0.95, 0.2, 0.3, 0.12))

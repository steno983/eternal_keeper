extends Node2D
const Bank = preload("res://scripts/animation_bank.gd")
var overlay_pass: bool = false
var drawing_world: bool = true
## Presentation-only canvas. World simulation stays at fixed coordinates.
var game: Node2D
var background: Texture2D
var portraits: Array[Texture2D] = []
var floor_art: Texture2D
var serif: Font
var font: Font
var shake: Vector2 = Vector2.ZERO
const INK = Color("0c151d")
const GOLD = Color("d6b77c")
const IVORY = Color("eee6d5")
const MUTED = Color("98aeb5")
const TEAL = Color("75b9be")

func _ready() -> void:
	background = load("res://assets/art/abbey.png")
	if ResourceLoader.exists("res://assets/art/bridge-floor.png"):
		floor_art = load("res://assets/art/bridge-floor.png")
	for hero in ["tholgrin", "layla", "lupinor"]:
		portraits.append(load("res://assets/%s_skin/head.png" % hero))
	serif = load("res://assets/fonts/title.ttf")
	font = load("res://assets/fonts/ui.ttf")

func _draw() -> void:
	if not game:
		return
	var strength: float = 0.0 if game.reduced_motion else game.trauma * game.trauma * 30.0
	shake = Vector2(sin(game.time * 73.0), sin(game.time * 91.0)) * strength
	drawing_world=true
	_world_transform(shake)
	if not overlay_pass:
		_environment()
		return
	if game.mode == "title":
		_title_party()
	else:
		_world()
	_foreground()
	drawing_world=false
	draw_set_transform(Vector2.ZERO)
	_vignette()
	if game.mode == "title":
		_title()
	else:
		_hud()
		if game.mode == "paused":
			_pause()
		elif game.mode in ["victory", "defeat"]:
			_ending()
	if game.help_open:
		_help()

func _world_transform(origin: Vector2, angle: float=0.0, local_scale: Vector2=Vector2.ONE) -> void:
	var zoom=1.0 if game.mode=="title" or not drawing_world else game.WORLD_ZOOM
	draw_set_transform(game.CAMERA_PIVOT*(1.0-zoom)+origin*zoom,angle,local_scale*zoom)

func _text(pos: Vector2, value: String, size: int = 16, color: Color = IVORY, title: bool = false) -> void:
	draw_string(serif if title else font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _center(pos: Vector2, value: String, size: int, color: Color = IVORY, title: bool = false) -> void:
	var f: Font = serif if title else font
	var width = f.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(f, pos - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _tracked(pos: Vector2, value: String, size: int, color: Color, spacing: float = 3.0) -> void:
	var cursor = pos
	for letter in value:
		draw_string(font, cursor, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
		cursor.x += font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + spacing

func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _ellipse(pos: Vector2, radius: Vector2, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(40):
		points.append(pos + Vector2(cos(float(i) / 40 * TAU), sin(float(i) / 40 * TAU)) * radius)
	draw_colored_polygon(points, color)

func _glow(pos: Vector2, radius: float, color: Color, opacity: float = 0.2) -> void:
	for i in range(7, 0, -1):
		var c = color
		c.a = opacity * float(8 - i) / 50.0
		draw_circle(pos, radius * float(i) / 7.0, c)

func _environment() -> void:
	draw_rect(Rect2(0, 0, 1440, 810), INK)
	if background:
		draw_texture_rect(background, Rect2(-30.0 - game.camera_x * 0.105, -42, 1810, 1080), false, Color(0.83, 0.94, 1.0))
	_sky_layers()
	# Mid-distance broken stone arches move more quickly than the abbey.
	for i in range(-1, 12):
		var x = i * 510.0 - game.camera_x * 0.42
		if x < -350 or x > 1640:
			continue
		var top = 335.0 + sin(i * 2.8) * 42.0
		var stone = Color(0.065, 0.13, 0.17, 0.6)
		draw_rect(Rect2(x, top, 29, 420 - top), stone)
		draw_rect(Rect2(x + 240, top - 35, 34, 455 - top), stone)
		# Worn voussoirs rather than a smooth geometrical arch.
		for block in range(9 if i % 2 == 0 else 13):
			var start = PI + float(block) / 15.0 * PI + 0.014
			var end = PI + float(block + 1) / 15.0 * PI - 0.014
			var center = Vector2(x + 137, top + 22)
			draw_arc(center, 120 + sin(block * 7.0) * 2, start, end, 4, stone.lightened(sin(block * 3.0) * 0.04), 23, true)
			draw_arc(center, 108, start, end, 4, Color(0.22, 0.33, 0.37, 0.35), 1.2, true)
		_poly([Vector2(x - 12, top), Vector2(x + 15, top - 40), Vector2(x + 43, top)], stone)
		for r in range(4):
			draw_line(Vector2(x, top + 24 + r * 30), Vector2(x + 29, top + 24 + r * 30), Color("29424b"), 1)
	# Mist drifts independently, in three thin bands.
	for layer in range(3):
		for i in range(9):
			var x = fposmod(i * 240.0 - game.camera_x * (0.19 + layer * 0.14) + game.time * (4 + layer * 3), 1990.0) - 270.0
			_ellipse(Vector2(x, 350 + layer * 27 + sin(i * 3.2) * 12), Vector2(220, 28), Color(0.44, 0.65, 0.69, 0.025))
	# Rear balustrade.
	draw_rect(Rect2(0, 398, 1440, 20), Color("15262d"))
	draw_line(Vector2(0, 399), Vector2(1440, 399), Color("5b7376"), 2)
	for i in range(-1, 55):
		var x = i * 90.0 - fposmod(game.camera_x * 0.87, 90.0)
		draw_rect(Rect2(x, 357, 13, 42), Color("192c33"))
		draw_rect(Rect2(x - 3, 353, 19, 5), Color("3b5358"))
	# Stone bridge / three depth planes.
	_poly([Vector2(0, 417), Vector2(1440, 417), Vector2(1440, 745), Vector2(0, 745)], Color("28363a"))
	for row in range(12):
		var y = 417.0 + row * 27.5
		var shade = Color("334347") if row % 2 == 0 else Color("2f3e42")
		draw_rect(Rect2(0, y, 1440, 26.5), shade)
		draw_line(Vector2(0, y + 1), Vector2(1440, y + 1), Color(0.39, 0.49, 0.50, 0.16), 1)
		for col in range(-1, 16):
			var x = col * 126.0 + (63.0 if row % 2 else 0.0) - fposmod(game.camera_x, 126.0)
			draw_line(Vector2(x, y + 2), Vector2(x - 5, y + 25), Color("1e2d33"), 1)
			var n = absf(sin(float(row * 73 + col * 39)))
			if n > 0.7:
				draw_line(Vector2(x + 21, y + 8), Vector2(x + 47 + n * 30, y + 10), Color(0.5, 0.58, 0.57, 0.09), 1)
	if floor_art:
		for tile in range(4):
			var x = tile * 1536.0 - game.camera_x
			if x > 1440 or x < -1536:
				continue
			var mirrored = tile % 2 == 1
			_world_transform(Vector2(x + (1536 if mirrored else 0), 418) + shake, 0, Vector2(-1 if mirrored else 1, 1))
			draw_texture_rect(floor_art, Rect2(0, 0, 1536, 304), false, Color(0.62, 0.77, 0.80))
			_world_transform(shake)
		draw_polygon(PackedVector2Array([Vector2(0, 418), Vector2(1440, 418), Vector2(1440, 722), Vector2(0, 722)]), PackedColorArray([Color(0.02, 0.05, 0.06, 0.42), Color(0.02, 0.05, 0.06, 0.42), Color(0.02, 0.05, 0.06, 0.02), Color(0.02, 0.05, 0.06, 0.02)]))
	for lane in range(3):
		var y: float = game.LANES[lane]
		var active: bool = lane == game.player.lane and game.mode != "title"
		if active:
			draw_rect(Rect2(0, y - 63, 1440, 70), Color(0.3, 0.63, 0.69, 0.025))
		var col = Color(0.43, 0.72, 0.74, 0.25 if active else 0.07)
		draw_line(Vector2(0, y + 6), Vector2(1440, y + 6), col, 1)
		for i in range(18):
			var x = i * 130.0 - fposmod(game.camera_x, 130.0)
			draw_line(Vector2(x, y + 6), Vector2(x + 22, y + 6), Color(0.7, 0.8, 0.75, 0.22 if active else 0.08), 2)
	# Scattered gravel on the bridge is deterministic, not frame-random.
	for i in range(130):
		var world_x = fposmod(i * 173.17, 4300.0)
		var x = world_x - game.camera_x
		if x < -10 or x > 1450:
			continue
		var y = 430 + fposmod(i * 89.3, 280.0)
		var size = 1.5 + fposmod(i * 3.3, 3.0)
		_poly([Vector2(x, y), Vector2(x + size, y - size), Vector2(x + size * 2.3, y + 1), Vector2(x + 1, y + size)], Color("1d2b30"))
	# Back-row braziers, attached to world space.
	for i in range(6):
		var x = 110.0 + i * 800.0 - game.camera_x
		if x > -100 and x < 1540:
			_brazier(Vector2(x, 425), 0.78, i)
	# Soft lighting pools on the paving.
	for i in range(6):
		var x = 110 + i * 800.0 - game.camera_x
		_ellipse(Vector2(x, 454), Vector2(100, 28), Color(0.92, 0.49, 0.16, 0.035))

func _brazier(pos: Vector2, size: float, seed_value: int) -> void:
	_world_transform(pos + shake, 0, Vector2.ONE * size)
	_glow(Vector2(0, -90), 125, Color("ff8f32"), 0.65)
	draw_rect(Rect2(-6, -66, 12, 66), Color("111d25"))
	draw_rect(Rect2(-15, -5, 30, 6), Color("15222a"))
	_poly([Vector2(-23, -84), Vector2(23, -84), Vector2(15, -65), Vector2(-15, -65)], Color("1a2026"))
	draw_line(Vector2(-24, -84), Vector2(24, -84), Color("a27545"), 3)
	for f in range(5):
		var phase = game.time * 7 + f * 1.7 + seed_value
		var h = 27.0 + sin(phase) * 11.0
		var x = (f - 2) * 6.0
		_poly([Vector2(x - 9, -85), Vector2(x - 5, -99), Vector2(x + sin(phase) * 8, -88 - h), Vector2(x + 5, -98), Vector2(x + 11, -85)], Color("e87528") if f % 2 else Color("ffd080"))
	_world_transform(shake)

func _foreground() -> void:
	draw_rect(Rect2(0, 722, 1440, 88), Color("101c24"))
	draw_rect(Rect2(0, 722, 1440, 6), Color("536164"))
	draw_rect(Rect2(0, 729, 1440, 9), Color("26373d"))
	for i in range(-1, 26):
		var x = i * 190.0 - fposmod(game.camera_x * 1.16, 190.0)
		draw_line(Vector2(x, 741), Vector2(x, 810), Color("24353d"), 2)
		_poly([Vector2(x + 84, 748), Vector2(x + 96, 765), Vector2(x + 84, 782), Vector2(x + 72, 765)], Color("30434a"))
	# Near camera embers / dust, faster parallax.
	for i in range(44):
		var x = fposmod(i * 127.81 - game.camera_x * 1.3 + sin(game.time * 0.4 + i) * 28, 1500.0) - 30
		var y = fposmod(i * 71.7 - game.time * (12 + i % 6), 740.0)
		var col = Color(0.98, 0.68, 0.32, 0.16 + sin(game.time + i) * 0.12)
		draw_circle(Vector2(x, y), 1.0 if i % 3 else 2.0, col)

func _world() -> void:
	# Native AnimatedSprite2D fighters are drawn in the y-sorted middle layer.
	if not game.echo.is_empty():
		var ep = Vector2(game.echo.x - game.camera_x, game.LANES[game.echo.lane])
		_center(ep - Vector2(0, 173), "ECO", 10, Color("82d6df"))
	for fx in game.effects:
		if fx.kind == "ghost":
			_hero(Vector2(fx.x - game.camera_x, fx.y), fx.hero, 3, fx.facing, 0, Color(0.55, 0.8, 1.0, fx.life / fx.max * 0.19), 1.0)
	for bolt in game.projectiles:
		var pos = Vector2(bolt.x - game.camera_x, bolt.y)
		var direction = signf(bolt.vx)
		for i in range(bolt.trail.size() - 1):
			var a: Vector2 = bolt.trail[i] - Vector2(game.camera_x, 0)
			var b: Vector2 = bolt.trail[i + 1] - Vector2(game.camera_x, 0)
			draw_line(a, b, Color(bolt.color, 0.4 * (1.0 - float(i) / 8)), 3, true)
		_glow(pos, 24, bolt.color, 0.4)
		draw_line(pos - Vector2(direction * 21, 0), pos + Vector2(direction * 8, 0), bolt.color, 3, true)
		_poly([pos + Vector2(direction * 12, 0), pos + Vector2(-direction * 3, -4), pos + Vector2(-direction * 3, 4)], IVORY)
	for fx in game.effects:
		_effect(fx)
	if game.mode == "playing" and not game.wave_active:
		var x = 1270.0 + sin(game.time * 4) * 7
		_tracked(Vector2(x - 50, 335), "AVANTI", 12, GOLD, 2)
		draw_polyline(PackedVector2Array([Vector2(x + 30, 348), Vector2(x + 42, 358), Vector2(x + 30, 368)]), GOLD, 2, true)

func _hero(pos: Vector2, hero: int, pose: int, facing: float, _hop: float, tint: Color, factor: float) -> void:
	var key = "hero_" + str(hero)
	var clip: StringName = &"attack" if pose == 3 else &"idle"
	var library = Bank.library(key)
	if library == null:
		return
	var clock = Bank.length_of(library, &"attack") * 0.35 if pose == 3 else game.time
	var texture: Texture2D = Bank.texture(key, clip, clock)
	var size = 0.70 * factor
	_world_transform(pos + shake, 0.0, Vector2(facing, 1))
	draw_texture_rect(texture, Rect2(-192 * size, -306 * size, 384 * size, 320 * size), false, tint)
	_world_transform(shake)

func _effect(fx: Dictionary) -> void:
	var pos = Vector2(fx.x - game.camera_x, fx.y)
	var ratio: float = clampf(fx.life / fx.max, 0, 1)
	match fx.kind:
		"impact":
			var expansion=1.0-ratio
			var radius=(49.0 if fx.heavy else 30.0)*expansion+5.0
			_glow(pos,radius*1.8,fx.color,ratio*0.8)
			draw_arc(pos,radius,0,TAU,36,Color(fx.color,ratio*0.75),1.5,true)
			for ray in range(8):
				var angle=ray*TAU/8.0+fx.seed*0.73
				var axis=Vector2(cos(angle),sin(angle))
				draw_line(pos+axis*radius*0.25,pos+axis*radius,Color(IVORY,ratio),maxf(0.5,ratio*3),true)
		"spark":
			var tail = Vector2(fx.vx, fx.vy).normalized() * (fx.size * 3)
			draw_line(pos, pos - tail, Color(fx.color, ratio), fx.size * ratio, true)
		"text":
			pos.y -= (1.0 - ratio) * 42
			_center(pos + Vector2(1, 2), fx.text, 21 if fx.text.length() < 4 else 15, Color(0.02, 0.03, 0.05, ratio))
			_center(pos, fx.text, 21 if fx.text.length() < 4 else 15, Color(fx.color, ratio))
		"ring":
			var radius = 100.0 * (1.0 - ratio) + 10
			draw_arc(pos, radius, 0, TAU, 48, Color(fx.color, ratio * 0.65), 2, true)
		"slash":
			var radius = 100.0 if fx.large else 76.0
			var angle = 0.0 if fx.facing > 0 else PI
			var progress = (1 - ratio) * 1.3
			_glow(pos + Vector2(fx.facing * 35, 0), radius, fx.color, 0.3 * ratio)
			var ribbon=PackedVector2Array()
			for edge in [0,1]:
				for step in range(25):
					var t=float(step if edge==0 else 24-step)/24.0
					var theta=angle-1.25+progress+t*1.9
					var thickness=sin(t*PI)*11.0*ratio
					var r=radius-(thickness if edge==1 else 0.0)
					ribbon.append(pos+Vector2(cos(theta),sin(theta))*r)
			draw_colored_polygon(ribbon,Color(fx.color,ratio*0.30))
			for ring in range(3):
				draw_arc(pos, radius - ring * 4, angle - 1.25 + progress, angle + 0.65 + progress * 0.35, 20, Color(fx.color, ratio * (0.65 - ring * 0.14)), 2.5, true)
			draw_arc(pos, radius, angle - 0.95 + progress, angle + 0.55 + progress * 0.35, 20, Color(IVORY, ratio * 0.9), 2, true)
		"flame":
			var intensity = sin(clampf((fx.max - fx.life) / fx.max, 0, 1) * PI)
			var h = 125 * intensity + 15
			_glow(pos - Vector2(0, h * 0.5), h, Color("ff962b"), 1.2 * ratio)
			_ellipse(pos, Vector2(43, 10), Color(1.0, 0.5, 0.12, 0.24 * ratio))
			for i in range(3):
				var base = pos + Vector2((i - 1) * 19, 0)
				var phase = game.time * 13 + i * 3 + fx.seed
				var height = h * (0.76 + sin(phase * 0.5) * 0.2)
				_flame(base, 23, height, phase, Color(0.93, 0.3, 0.055, ratio * 0.68))
				_flame(base, 15, height * 0.88, phase + 0.7, Color(1.0, 0.66, 0.20, ratio * 0.88))
				_flame(base, 7, height * 0.55, phase + 1.2, Color(1.0, 0.94, 0.68, ratio * 0.95))

func _flame(base: Vector2, width: float, height: float, phase: float, color: Color) -> void:
	var points = PackedVector2Array()
	for side in [-1, 1]:
		for step in range(19):
			var t = float(step if side == -1 else 18 - step) / 18.0
			var center = sin(t * 4.8 - phase) * width * t * 0.85
			var radius = width * pow(1.0 - t, 0.72) * (0.78 + 0.22 * sin(t * 13 + phase))
			points.append(base + Vector2(center + side * radius, -t * height))
	draw_colored_polygon(points, color)

func _title_party() -> void:
	var positions = [Vector2(830, 585), Vector2(1030, 608), Vector2(1240, 585)]
	for i in range(3):
		var pos: Vector2 = positions[i]
		var col: Color = game.HEROES[i].color
		_glow(pos - Vector2(0, 65), 140, col, 0.22)
		_ellipse(pos + Vector2(0, 2), Vector2(65, 13), Color(0.01, 0.02, 0.03, 0.5))
		_hero(pos, i, 0, 1, sin(game.time * 2 + i) * 2, Color.WHITE, 1.45)
		_center(pos + Vector2(0, 43), game.HEROES[i].name, 19, IVORY, true)
		_center(pos + Vector2(0, 65), ["FUOCO SACRO", "LAME PSIONICHE", "ACCIAIO & OMBRA"][i], 10, col)
		_ellipse(pos + Vector2(0, 7), Vector2(49, 9), Color(col, 0.12))

func _vignette() -> void:
	for i in range(18):
		var alpha = 0.018 * (1.0 - float(i) / 18)
		draw_rect(Rect2(i * 7, 0, 7, 810), Color(0.015, 0.025, 0.04, alpha * 5))
		draw_rect(Rect2(1440 - i * 7 - 7, 0, 7, 810), Color(0.015, 0.025, 0.04, alpha * 5))
		draw_rect(Rect2(0, i * 4, 1440, 4), Color(0.015, 0.025, 0.04, alpha * 5))
		draw_rect(Rect2(0, 810 - i * 5 - 5, 1440, 5), Color(0.015, 0.025, 0.04, alpha * 5))
	if game.hurt_flash > 0 and not game.reduced_motion:
		draw_rect(Rect2(0, 0, 1440, 810), Color(0.65, 0.08, 0.12, game.hurt_flash * 0.6))

func _button(rect: Rect2, text: String, hint: String) -> void:
	var hover = rect.has_point(get_global_mouse_position())
	draw_rect(rect, Color("d3b47a") if hover else Color("b99a64"))
	draw_rect(rect.grow(-5), Color(0.08, 0.1, 0.12, 0.04), false, 1)
	_text(rect.position + Vector2(22, 40), text, 16, INK)
	_text(rect.position + Vector2(rect.size.x - 72, 40), hint, 12, Color("344047"))

func _title() -> void:
	# A directional scrim retains the landscape while giving the title contrast.
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1050, 0), Vector2(1050, 735), Vector2(0, 735)]), PackedColorArray([Color(0.025, 0.05, 0.07, 0.82), Color(0.025, 0.05, 0.07, 0), Color(0.025, 0.05, 0.07, 0), Color(0.025, 0.05, 0.07, 0.82)]))
	_tracked(Vector2(90, 83), "UN RACCONTO A TRE VOCI", 12, GOLD, 3.0)
	draw_line(Vector2(90, 112), Vector2(151, 112), GOLD, 1)
	_text(Vector2(84, 258), "Ceneri", 110, IVORY, true)
	_text(Vector2(89, 356), "& Echi", 110, IVORY, true)
	_tracked(Vector2(94, 405), "IL PONTE DELLE BRACI", 14, GOLD, 3.6)
	_text(Vector2(93, 463), "Scegli un eroe. Elimina i nemici. Avanza.", 22, Color("c6d1d1"))
	_text(Vector2(93, 493), "Puoi cambiare personaggio in qualsiasi momento.", 18, MUTED)
	_button(Rect2(90, 535, 320, 64), "GIOCA", "INVIO")
	_text(Vector2(93, 636), "A / D  Muovi     W / S  Cambia corsia", 19, MUTED)
	_text(Vector2(93, 662), "J  Attacca     K  Abilità     SPAZIO  Schiva", 19, MUTED)
	_text(Vector2(93, 688), "1 / 2 / 3  Scegli eroe     F1  Tutti i comandi", 19, MUTED)
	draw_line(Vector2(90, 746), Vector2(1350, 746), Color(0.75, 0.66, 0.45, 0.27), 1)
	_tracked(Vector2(93, 775), "DEMO GIOCABILE", 11, GOLD, 2)
	_text(Vector2(285, 775), "Scenario di prova · Ispirato al vostro gruppo", 12, MUTED)
	_text(Vector2(1078, 775), "F1  COMANDI    M  AUDIO", 12, MUTED)
	_tracked(Vector2(1120, 68), "CENERI / 001", 10, Color("afc6c8"), 2)

func _panel(rect: Rect2, border: Color=Color("40505b")) -> void:
	draw_rect(rect,Color("101c27"))
	draw_rect(rect,border,false,1.0)

func _keycap(pos: Vector2, key_label: String, width: float=36.0) -> void:
	draw_rect(Rect2(pos,Vector2(width,30)),Color("293c4b"))
	draw_rect(Rect2(pos,Vector2(width,30)),Color("61747e"),false,1)
	_center(pos+Vector2(width*0.5,21),key_label,16,IVORY)

func _hud() -> void:
	for i in range(3):
		_hero_card(i)
	var col: Color=game.HEROES[game.player.hero].color
	_panel(Rect2(1040,20,376,104))
	_text(Vector2(1060,45),"OBIETTIVO",13,GOLD)
	_text(Vector2(1060,75),"Elimina i nemici" if game.living_enemies()>0 else "Avanza lungo il ponte →",23,IVORY)
	_text(Vector2(1060,104),"%d rimasti   ·   Ondata %d / 3" % [game.living_enemies(),game.wave],17,MUTED)
	if game.combo>1 and game.combo_time>0:
		_panel(Rect2(874,20,146,104),Color(col,0.65))
		_center(Vector2(947,64),"%d" % game.combo,34,col,true)
		_center(Vector2(947,92),"COLPI IN SERIE",12,IVORY)
		draw_rect(Rect2(890,108,114*game.combo_time/2.6,3),col)
	var boss=null
	for enemy in game.enemies:
		if enemy.kind=="warden" and enemy.alive():
			boss=enemy
			break
	if boss!=null:
		_panel(Rect2(490,147,610,67),Color("9c555e"))
		_text(Vector2(506,171),"IL CUSTODE DEL PONTE"+(" · FURIA" if boss.hp<boss.max_hp*0.5 else ""),18,IVORY,true)
		draw_rect(Rect2(506,182,578,10),Color("35252e"))
		draw_rect(Rect2(506,182,578*boss.hp/boss.max_hp,10),Color("c26b73"))
		if boss.state==game.Fighter.State.WINDUP:
			_panel(Rect2(24,149,440,66),Color("9c555e"))
			_text(Vector2(40,176),"SPAZZATA" if boss.attack_variant==1 else "FENDENTE",18,Color("ffb4a7"))
			_text(Vector2(40,201),"Allontanati o schiva" if boss.attack_variant==1 else "Cambia corsia o para",18,IVORY)
	elif game.wave_banner>0:
		var alpha=minf(1.0,game.wave_banner)
		_center(Vector2(720,179),["Il ponte delle braci","L’avanzata delle ombre","Il custode del ponte"][maxi(0,game.wave-1)],25,Color(IVORY,alpha),true)
	if game.combo>0 and game.combo_time>0 and game.relay_cd<=0 and game.player.action==&"attack" and game.player.action_elapsed>=game.player.action_length*game.CONTACT_PHASE[game.player.hero]:
		_center(Vector2(720,685),"TAB / 1 / 2 / 3  ·  Cambia ora per un ingresso speciale",18,col)
	# Actions remain named and visible, including the actual special cooldown.
	draw_rect(Rect2(0,714,1440,96),Color("0b141e"))
	draw_line(Vector2(24,714),Vector2(1416,714),Color("50616b"),1)
	_keycap(Vector2(24,733),"A / D",70)
	_text(Vector2(105,754),"Muovi",19,IVORY)
	_text(Vector2(24,789),"W / S   Corsia %d / 3" % [game.player.lane+1],17,MUTED)
	var special_ready=game.cooldowns[game.player.hero]<=0
	var commands=[
		["J","Attacco",("Colpo %d / 3" % [game.player.combo_step+1]) if game.player.action==&"attack" and game.player.action_active() else ["Mazza sacra","Lame psioniche","Scimitarra"][game.player.hero],true],
		["K",["Fuoco sacro","Passo psionico","Manifesta eco"][game.player.hero],"PRONTA" if special_ready else "Ricarica: %.1f s" % game.cooldowns[game.player.hero],special_ready],
		["L",["Scudo","Lama a distanza","Balestra"][game.player.hero],"Tieni premuto" if game.player.hero==0 else "Attacco a distanza",true],
		["SPAZIO","Schivata","Evita i colpi",game.dash_cd<=0]
	]
	for i in range(4):
		var x=270.0+i*230
		var cmd=commands[i]
		_panel(Rect2(x,728,218,68),Color(col,0.65) if i==1 and special_ready else Color("344754"))
		var wide=72.0 if i==3 else 30.0
		_keycap(Vector2(x+10,740),cmd[0],wide)
		var label_x=x+wide+21
		_text(Vector2(label_x,754),cmd[1],16,IVORY if cmd[3] else MUTED)
		_text(Vector2(label_x,779),cmd[2],12,col if i==1 and special_ready else MUTED)
		if i==1 and not special_ready:
			var fill=1.0-game.cooldowns[game.player.hero]/game.HEROES[game.player.hero].cooldown
			draw_rect(Rect2(x+1,792,216*clampf(fill,0,1),3),col)
	_text(Vector2(1215,751),"TAB  Cambia eroe",15,IVORY)
	_text(Vector2(1215,780),"ESC Pausa · F1 Aiuto",14,MUTED)

func _hero_card(i: int) -> void:
	var rect: Rect2=game.hero_card_rect(i)
	var active=game.player.hero==i
	var data: Dictionary=game.HEROES[i]
	var hp: float=game.player.hp if active else game.health[i]
	var alive=hp>0
	var col: Color=data.color
	_panel(rect,col if active else Color("3e505d"))
	if active:
		draw_rect(Rect2(rect.position,Vector2(rect.size.x,4)),col)
	var left=rect.position.x
	var portrait=portraits[i]
	var size=Vector2(portrait.get_size())
	size*=minf(62.0/size.x,72.0/size.y)
	draw_texture_rect(portrait,Rect2(Vector2(left+12+(62-size.x)*0.5,43),size),false,Color.WHITE if alive else Color("525863"))
	_text(Vector2(left+86,47),data.name.capitalize(),22,IVORY if alive else MUTED,true)
	_text(Vector2(left+86,70),"IN CAMPO" if active else ("ESAUSTO" if not alive else "%d  ·  SCEGLI" % [i+1]),13,col if active else MUTED)
	draw_rect(Rect2(left+86,82,164,9),Color("2c3a45"))
	draw_rect(Rect2(left+86,82,164*clampf(hp/data.hp,0,1),9),col if alive else MUTED)
	_text(Vector2(left+86,113),"Salute  %d / %d" % [ceili(hp),int(data.hp)],16,IVORY)
	if active:
		_keycap(Vector2(left+224,33),str(i+1),28)

func _pause() -> void:
	draw_rect(Rect2(0, 0, 1440, 810), Color(0.02, 0.04, 0.06, 0.82))
	_center(Vector2(720, 310), "PAUSA", 42, IVORY, true)
	_center(Vector2(720, 357), "La partita è ferma. Riprendi quando vuoi.", 18, MUTED)
	_button(Rect2(550, 460, 340, 64), "RIPRENDI", "INVIO")
	_center(Vector2(720, 576), "F1  Comandi e abilità     R  Ricomincia     M  Audio", 18, MUTED)
	_center(Vector2(720, 610), "F2  Movimento ridotto: " + ("attivo" if game.reduced_motion else "disattivo"), 13, MUTED)

func _ending() -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1100, 0), Vector2(1100, 810), Vector2(0, 810)]), PackedColorArray([Color(0.025, 0.05, 0.07, 0.95), Color(0.025, 0.05, 0.07, 0), Color(0.025, 0.05, 0.07, 0), Color(0.025, 0.05, 0.07, 0.95)]))
	var won: bool = game.mode == "victory"
	_tracked(Vector2(92, 205), "PROVA COMPLETATA" if won else "IL FUOCO SI AFFIEVOLISCE", 12, GOLD, 3)
	_text(Vector2(86, 310), "Il ponte è vostro." if won else "Nessuno resta solo.", 58, IVORY, true)
	_text(Vector2(92, 369), "Tre voci, una vittoria." if won else "Riprova alternando eroi, corsie e schivate.", 21, MUTED)
	_text(Vector2(92, 425), "%d avversari sconfitti  ·  %d:%02d di battaglia" % [game.kills,int(game.encounter_time)/60,int(game.encounter_time)%60], 17, GOLD)
	_button(Rect2(90, 535, 320, 64), "TORNA NELLA MISCHIA", "INVIO")
	_text(Vector2(92, 646), "Questa è solo la prima scintilla della vostra avventura.", 15, MUTED)

func _help() -> void:
	draw_rect(Rect2(0,0,1440,810),Color(0.025,0.045,0.065,0.98))
	_text(Vector2(72,76),"Comandi e abilità",40,IVORY,true)
	_text(Vector2(72,113),"Muoviti tra le tre corsie e cambia eroe quando ti serve.",20,MUTED)
	_text(Vector2(72,176),"TASTIERA",15,GOLD)
	var rows=[
		["A / D","Muovi a sinistra e a destra"],
		["W / S","Cambia corsia: lontana, centrale, vicina"],
		["J","Combo di 3 colpi · tieni premuto"],
		["K","Usa l’abilità dell’eroe attivo"],
		["L","Usa scudo o attacco a distanza"],
		["SPAZIO","Schiva il colpo"],
		["1 / 2 / 3","Cambia dopo un colpo: ingresso speciale"],
		["TAB","Passa all’eroe successivo"]
	]
	for i in range(rows.size()):
		var y=202+i*46
		_keycap(Vector2(72,y),rows[i][0],100)
		_text(Vector2(192,y+22),rows[i][1],18,IVORY)
	_text(Vector2(790,176),"LE ABILITÀ DEI TRE EROI",15,GOLD)
	var descriptions=[
		["K  Fuoco sacro: fiamme sulla corsia.","L  Tieni lo scudo rivolto verso il colpo."],
		["K  Passo psionico: attraversa e colpisci.","L  Lancia una lama psionica a distanza."],
		["K  Manifesta un’eco su un’altra corsia.","J  L’eco replica gli attacchi. L  Balestra."]
	]
	for i in range(3):
		var y=202+i*123
		var col: Color=game.HEROES[i].color
		_panel(Rect2(790,y,576,110),Color(col,0.5))
		_text(Vector2(812,y+29),game.HEROES[i].name.capitalize(),23,col,true)
		_text(Vector2(812,y+60),descriptions[i][0],18,IVORY)
		_text(Vector2(812,y+88),descriptions[i][1],17,MUTED)
	_text(Vector2(72,628),"GAMEPAD",15,GOLD)
	_text(Vector2(72,665),"Stick / croce: movimento    X: attacco    Y: abilità    B: secondaria    A: schivata    LB / RB: cambia eroe",18,IVORY)
	_text(Vector2(72,710),"Un ! sopra un nemico anticipa il suo attacco: cambia corsia, para o schiva.",19,GOLD)
	draw_line(Vector2(72,741),Vector2(1366,741),Color("40505b"),1)
	_text(Vector2(72,778),"ESC / F1  Chiudi",18,IVORY)
	_text(Vector2(720,778),"M  Audio     F2  Movimento ridotto     R  Ricomincia",17,MUTED)

func _sky_layers() -> void:
	for layer in range(2):
		for i in range(7):
			var x=fposmod(i*310.0-game.camera_x*(0.045+layer*0.10)+game.time*(5.0+layer*7),2100.0)-330.0
			var y=110.0+layer*92.0+sin(i*2.4)*44.0
			_ellipse(Vector2(x,y),Vector2(210,18+layer*8),Color(0.46,0.64,0.71,0.035))
	for i in range(14):
		var x=fposmod(i*173.0-game.camera_x*0.25,2200.0)-250.0
		var top=366.0-sin(i*3.7)*12.0
		_poly([Vector2(x-9,405),Vector2(x-7,top),Vector2(x,top-18),Vector2(x+7,top),Vector2(x+9,405)],Color(0.08,0.17,0.21,0.28))
	for i in range(8):
		var x=fposmod(250+i*28+game.time*18.0-game.camera_x*0.08,1850.0)-180.0
		var y=155.0+sin(i*1.9)*17.0
		var flap=sin(game.time*5.0+i)*4.0
		draw_polyline(PackedVector2Array([Vector2(x-6,y-flap),Vector2(x,y),Vector2(x+6,y-flap)]),Color(0.04,0.10,0.15,0.65),1.4,true)
	var storm=fposmod(game.time,13.0)
	if not game.reduced_motion and storm>9.0 and storm<9.16:
		var alpha=sin((storm-9.0)/0.16*PI)*0.6
		var x=1050.0-game.camera_x*0.035
		draw_polyline(PackedVector2Array([Vector2(x,60),Vector2(x-23,100),Vector2(x-8,103),Vector2(x-38,155),Vector2(x-20,149),Vector2(x-55,207)]),Color(0.72,0.88,1.0,alpha),2.1,true)

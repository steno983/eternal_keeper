extends Node2D
const Texts=preload("res://scripts/text_data.gd")
const AbilityInk=preload("res://scripts/ability_ink.gd")
const CrossbowInk=preload("res://scripts/crossbow_ink.gd")
const Bank = preload("res://scripts/pencil_bank.gd")
var overlay_pass: bool = false
var drawing_world: bool = true
var banner_only: bool = false
var banner_clip: Control
var banner_art: Node2D
## Presentation-only canvas. World simulation stays at fixed coordinates.
var game: Node2D
var background: Texture2D
var portraits: Array[Texture2D] = []
var skill_icons: Array[Texture2D]=[]
var skill_icons_grey: Array[Texture2D]=[]
var archive_panels: Dictionary={}
var inn_art: Texture2D
var intro_clip: Control
var intro_body: RichTextLabel
var intro_signature: String=""
var camp_art: Texture2D
var comic_art: Array[Texture2D]=[]
var comic_panels: Array=[]
var balloon_style: StyleBoxFlat
var ruin_art: Texture2D
var rail_art: Texture2D
var brazier_art: Texture2D
const PAPER = Color("f1e9d7")
var floor_art: Texture2D
var notes: Font
var serif: Font
var font: Font
var shake: Vector2 = Vector2.ZERO
const INK = Color("302b28")
const GOLD = Color("785c3d")
const IVORY = Color("302b28")
const MUTED = Color("6e665b")
const TEAL = Color("3b7472")

func _ready() -> void:
	if banner_only:
		return
	background=load("res://assets/pencil/landscape.png")
	floor_art=load("res://assets/pencil/floor.png")
	ruin_art=load("res://assets/pencil/ruin.png")
	rail_art=load("res://assets/pencil/rail.png")
	brazier_art=load("res://assets/pencil/brazier.png")
	for i in range(3):
		portraits.append(load("res://assets/pencil/hero_%d-portrait.png" % i))
	for i in range(4):
		skill_icons.append(load("res://assets/magic/icon-%d.png" % i))
		skill_icons_grey.append(load("res://assets/magic/icon-%d-grey.png" % i))
	serif=load("res://assets/fonts/black-chancery.ttf")
	var handwriting=FontVariation.new()
	handwriting.base_font=load("res://assets/fonts/notes.ttf")
	handwriting.variation_opentype={"wght":600}
	notes=handwriting
	font=load("res://assets/fonts/ui.ttf")
	if overlay_pass:
		var entrance_view=load("res://scripts/level_entrance_view.gd").new()
		entrance_view.game=game
		add_child(entrance_view)
		camp_art=load("res://assets/interludes/bridge-camp.png")
		for i in range(3):
			comic_art.append(load("res://assets/interludes/bridge-comic-%d.png" % [i+1]))
			var panels: Array[Texture2D]=[]
			for j in range(3): panels.append(load("res://assets/interludes/bridge-comic-%d-panel-%d.png" % [i+1,j+1]))
			comic_panels.append(panels)
		intro_clip=Control.new()
		intro_clip.position=Vector2(170,152)
		intro_clip.size=Vector2(1100,535)
		intro_clip.clip_contents=true
		intro_clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
		intro_clip.visible=false
		add_child(intro_clip)
		intro_body=RichTextLabel.new()
		intro_body.position=Vector2(35,40)
		intro_body.size=Vector2(1030,100)
		intro_body.fit_content=true
		intro_body.scroll_active=false
		intro_body.bbcode_enabled=false
		intro_body.mouse_filter=Control.MOUSE_FILTER_IGNORE
		intro_body.add_theme_font_override("normal_font",notes)
		intro_body.add_theme_font_size_override("normal_font_size",34)
		intro_body.add_theme_color_override("default_color",INK)
		intro_body.add_theme_constant_override("line_separation",10)
		intro_clip.add_child(intro_body)
		var fade=Gradient.new()
		fade.colors=PackedColorArray([PAPER,Color(PAPER,0)])
		var fade_texture=GradientTexture2D.new()
		fade_texture.gradient=fade
		fade_texture.fill_from=Vector2(0,0)
		fade_texture.fill_to=Vector2(0,1)
		for bottom in [false,true]:
			var veil=TextureRect.new()
			veil.texture=fade_texture
			veil.position=Vector2(0,491 if bottom else 0)
			veil.size=Vector2(1100,44)
			veil.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			veil.flip_v=bottom
			veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
			intro_clip.add_child(veil)
		balloon_style=StyleBoxFlat.new()
		balloon_style.bg_color=Color("fbf5e8")
		balloon_style.border_color=INK
		balloon_style.set_border_width_all(2)
		balloon_style.set_corner_radius_all(22)
		balloon_style.shadow_color=Color(INK,0.15)
		balloon_style.shadow_size=4
		balloon_style.shadow_offset=Vector2(2,3)
		banner_clip=Control.new()
		banner_clip.clip_contents=true
		banner_clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
		banner_clip.position=Vector2(12,574)
		banner_clip.rotation=deg_to_rad(-4.0)
		add_child(banner_clip)
		banner_art=get_script().new()
		banner_art.banner_only=true
		banner_art.game=game
		banner_art.font=font
		banner_art.serif=serif
		banner_art.notes=notes
		banner_art.position=Vector2(57,45)
		banner_clip.add_child(banner_art)


func _draw() -> void:
	if banner_only:
		_super_banner_art()
		return
	if not game:
		return
	if overlay_pass and is_instance_valid(intro_clip):
		intro_clip.visible=game.mode=="prologue" and not game.help_open
	if overlay_pass and game.mode=="prologue":
		drawing_world=false
		draw_set_transform(Vector2.ZERO)
		_prologue()
		if game.help_open: _help()
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
		if game.mode=="selection":
			_selection()
		elif game.mode!="level_intro":
			_hud()
			_super_banner()
		if game.mode=="stage_clear":
			_stage_clear()
		if game.mode=="interlude":
			_comic()
		elif game.mode=="reward":
			_rewards()
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

func _note(pos: Vector2, value: String, size: int=22, color: Color=MUTED) -> void:
	draw_string(notes,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

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

func _glow(pos: Vector2, radius: float, color: Color, opacity: float=0.2) -> void:
	for i in range(5):
		var x=-radius*0.4+i*radius*0.2
		draw_line(pos+Vector2(x,-radius*0.3),pos+Vector2(x-radius*0.25,radius*0.25),Color(color,minf(0.20,opacity*0.12)),0.9,true)

func _environment() -> void:
	if game.campaign:
		_archive_environment()
		return
	draw_rect(Rect2(-300,-300,2100,1400),PAPER)
	# All layers remain separate; paper never moves with the drawings.
	if background:
		var height=1800.0*background.get_height()/background.get_width()
		for tile in range(2):
			var x=-250.0+tile*1800-game.camera_x*0.11
			draw_texture_rect(background,Rect2(x,-130,1800,height),false,Color(1,1,1,0.50))
	for i in range(-1,8):
		var x=i*620.0-game.camera_x*0.42
		if x> -400 and x<1700:
			draw_texture_rect(ruin_art,Rect2(x,178,290,248),false,Color(1,1,1,0.48))
	for i in range(-1,12):
		var x=i*380.0-game.camera_x*0.77
		if x>-380 and x<1600:
			draw_texture_rect(rail_art,Rect2(x,348,340,76),false,Color(1,1,1,0.70))
	for i in range(-1,5):
		var x=i*1024.0-game.camera_x
		draw_texture_rect(floor_art,Rect2(x,418,1024,320),false)
	for lane in range(3):
		var y: float=game.LANES[lane]
		var active=game.mode!="title" and game.player.lane==lane
		for i in range(-1,20):
			var x=i*90.0-fposmod(game.camera_x,90.0)
			draw_line(Vector2(x,y+7),Vector2(x+24,y+7),Color(0.32,0.28,0.24,0.26 if active else 0.09),1,true)
	for i in range(6):
		var x=110.0+i*800-game.camera_x
		if x>-100 and x<1600:
			draw_texture_rect(brazier_art,Rect2(x-34,307,68,120),false)
	_pencil_sky()
	if game.mode not in ["title","selection"]:
		AbilityInk.ground(self)

func _foreground() -> void:
	if game.campaign: return
	for i in range(-1,9):
		var x=i*520.0-game.camera_x*1.15
		if x>-400 and x<1700:
			draw_texture_rect(rail_art,Rect2(x,722,430,100),false)
	for i in range(18):
		var x=fposmod(i*127.8-game.camera_x*1.25+sin(game.time*0.4+i)*22,1520)-40
		var y=fposmod(i*71.7-game.time*(5+i%4),740)
		draw_line(Vector2(x,y),Vector2(x+2,y-3),Color(0.25,0.21,0.17,0.12),1,true)

func _pencil_sky() -> void:
	for i in range(8):
		var x=fposmod(250+i*28+game.time*15-game.camera_x*0.06,1850)-180
		var y=190+sin(i*1.9)*17
		var flap=sin(game.time*5+i)*3
		draw_polyline(PackedVector2Array([Vector2(x-5,y-flap),Vector2(x,y),Vector2(x+5,y-flap)]),Color(0.25,0.23,0.21,0.35),1,true)
	var storm=fposmod(game.time,13.0)
	if not game.reduced_motion and storm>9.0 and storm<9.18:
		var x=1050-game.camera_x*0.035
		draw_polyline(PackedVector2Array([Vector2(x,105),Vector2(x-22,133),Vector2(x-9,135),Vector2(x-38,176)]),Color(0.34,0.31,0.28,0.5),1.3,true)

func _world() -> void:
	# Native AnimatedSprite2D fighters are drawn in the y-sorted middle layer.
	if not game.echo.is_empty():
		var ep = Vector2(game.echo.x - game.camera_x, game.LANES[game.echo.lane])
		_center(ep - Vector2(0, 173), Texts.ui("eco"), 10, Color("82d6df"))
	for fx in game.effects:
		if fx.kind=="ally":
			var elapsed: float=fx.max-fx.life
			var alpha=minf(1.0,elapsed/0.07)*minf(1.0,fx.life/0.15)
			var offset=0.0 if game.reduced_motion else -fx.facing*55*pow(1.0-clampf(elapsed/0.18,0,1),2)
			_hero(Vector2(fx.x-game.camera_x+offset,fx.y),fx.hero,3,fx.facing,0,Color(1,1,1,alpha),1.14)
		if fx.kind == "ghost":
			_hero(Vector2(fx.x - game.camera_x, fx.y), fx.hero, 3, fx.facing, 0, Color(0.55, 0.8, 1.0, fx.life / fx.max * 0.19), 1.0)
	for bolt in game.projectiles:
		if bolt.get("crossbow",false):
			CrossbowInk.projectile(self,bolt)
			continue
		if bolt.has("spell"):
			AbilityInk.projectile(self,bolt)
			continue
		var pos = Vector2(bolt.x - game.camera_x, bolt.y)
		var direction = signf(bolt.vx)
		for i in range(bolt.trail.size() - 1):
			var a: Vector2 = bolt.trail[i] - Vector2(game.camera_x, 0)
			var b: Vector2 = bolt.trail[i + 1] - Vector2(game.camera_x, 0)
			draw_line(a, b, Color(bolt.color, 0.4 * (1.0 - float(i) / 8)), 3, true)
		_glow(pos, 24, bolt.color, 0.4)
		draw_line(pos - Vector2(direction * 21, 0), pos + Vector2(direction * 8, 0), bolt.color, 3, true)
		_poly([pos + Vector2(direction * 12, 0), pos + Vector2(-direction * 3, -4), pos + Vector2(-direction * 3, 4)], IVORY)
	_run_zones()
	for fx in game.effects:
		_effect(fx)
	if game.mode == "playing" and not game.wave_active:
		var x = 1270.0 + sin(game.time * 4) * 7
		_tracked(Vector2(x - 50, 335), Texts.ui("avanti"), 12, GOLD, 2)
		draw_polyline(PackedVector2Array([Vector2(x + 30, 348), Vector2(x + 42, 358), Vector2(x + 30, 368)]), GOLD, 2, true)

func _run_zones() -> void:
	AbilityInk.ongoing(self)

func _hero(pos: Vector2, hero: int, pose: int, facing: float, _hop: float, tint: Color, factor: float) -> void:
	var key = "hero_" + str(hero)
	var clip: StringName = &"attack" if pose == 3 else &"idle"
	var library = Bank.library(key)
	if library == null:
		return
	var clock = Bank.length_of(library, &"attack") * 0.35 if pose == 3 else (game.run.room_time if game.campaign and game.mode!="title" else game.time)
	var texture: Texture2D = Bank.texture(key, clip, clock)
	var size = 0.70 * factor
	_world_transform(pos + shake, 0.0, Vector2(facing, 1))
	draw_texture_rect(texture, Rect2(-256 * size, -400 * size, 512 * size, 416 * size), false, tint)
	_world_transform(shake)

func _effect(fx: Dictionary) -> void:
	var pos = Vector2(fx.x - game.camera_x, fx.y)
	var ratio: float = clampf(fx.life / fx.max, 0, 1)
	match fx.kind:
		"crossbow_release":
			CrossbowInk.release(self,fx)
		"spell_cast","fire_hit","eruption","holy_wave","nova","ward_hit":
			AbilityInk.effect(self,fx)
		"impact":
			var expansion=1.0-ratio
			var radius=(49.0 if fx.heavy else 30.0)*expansion+5.0
			if fx.heavy:
				var spread=1.0 if game.reduced_motion else 0.7+(1.0-ratio)*0.6
				_splatter(pos,20.0*spread,Color(INK,ratio*0.85),fx.seed)
				_splatter(pos+Vector2(13,-9),11.0*spread,Color(fx.color,ratio*0.8),fx.seed+2)
			_glow(pos,radius*1.8,fx.color,ratio*0.8)
			draw_arc(pos,radius,0,TAU,36,Color(fx.color,ratio*0.75),1.5,true)
			for ray in range(8):
				var angle=ray*TAU/8.0+fx.seed*0.73
				var axis=Vector2(cos(angle),sin(angle))
				draw_line(pos+axis*radius*0.25,pos+axis*radius,Color(IVORY,ratio),maxf(0.5,ratio*3),true)
		"ink":
			var spread=1.0 if game.reduced_motion else 0.8+(1.0-ratio)*0.45
			_splatter(pos,28*spread,Color(INK,ratio*0.6),fx.seed)
			_splatter(pos+Vector2(18,-10),15*spread,Color(fx.color,ratio*0.75),fx.seed+1)
		"spark":
			var tail = Vector2(fx.vx, fx.vy).normalized() * (fx.size * 3)
			draw_line(pos, pos - tail, Color(fx.color, ratio), fx.size * ratio, true)
		"text":
			pos.y -= (1.0 - ratio) * 42
			_center(pos + Vector2(1, 2), fx.text, 21 if fx.text.length() < 4 else 15, Color(0.96,0.93,0.86,ratio))
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
				for step in range(25 if edge==0 else 23):
					var t=float(step if edge==0 else 23-step)/24.0
					var theta=angle-1.25+progress+t*1.9
					var thickness=sin(t*PI)*11.0*ratio
					var r=radius-(thickness if edge==1 else 0.0)
					ribbon.append(pos+Vector2(cos(theta),sin(theta))*r)
			if ratio>0.03:
				draw_colored_polygon(ribbon,Color(fx.color,ratio*0.30))
			for ring in range(3):
				draw_arc(pos, radius - ring * 4, angle - 1.25 + progress, angle + 0.65 + progress * 0.35, 20, Color(fx.color, ratio * (0.65 - ring * 0.14)), 2.5, true)
			draw_arc(pos, radius, angle - 0.95 + progress, angle + 0.55 + progress * 0.35, 20, Color(IVORY, ratio * 0.9), 2, true)
		"flame":
			AbilityInk.flame(self,pos,48,190,fx.seed+(fx.max-fx.life)*6,ratio,maxf(0,fx.max-fx.life))

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
		_ellipse(pos + Vector2(0, 2), Vector2(65, 13), Color(0.25,0.21,0.17,0.08))
		_hero(pos, i, 0, 1, sin(game.time * 2 + i) * 2, Color.WHITE, 1.45)
		_center(pos + Vector2(0, 43), game.HEROES[i].name.capitalize(), 19, IVORY, true)
		_center(pos + Vector2(0, 65), [Texts.ui("fuoco_sacro"), Texts.ui("lame_psioniche"), Texts.ui("acciaio_ombra")][i], 10, col)
		_ellipse(pos + Vector2(0, 7), Vector2(49, 9), Color(col, 0.12))

func _vignette() -> void:
	for i in range(18):
		var alpha = 0.004 * (1.0 - float(i) / 18)
		draw_rect(Rect2(i * 7, 0, 7, 810), Color(0.015, 0.025, 0.04, alpha * 5))
		draw_rect(Rect2(1440 - i * 7 - 7, 0, 7, 810), Color(0.015, 0.025, 0.04, alpha * 5))
		draw_rect(Rect2(0, i * 4, 1440, 4), Color(0.015, 0.025, 0.04, alpha * 5))
		draw_rect(Rect2(0, 810 - i * 5 - 5, 1440, 5), Color(0.015, 0.025, 0.04, alpha * 5))
	# Broken edge marks frame the page without covering the combat area.
	for side in [0,1]:
		var x=0.0 if side==0 else 1440.0
		var direction=1.0 if side==0 else -1.0
		_poly([Vector2(x,0),Vector2(x+direction*136,0),Vector2(x+direction*62,8),Vector2(x+direction*74,13),Vector2(x+direction*16,20),Vector2(x+direction*8,96)],INK)
		_splatter(Vector2(x+direction*5,142+side*35),9,Color(INK,0.8),side+3)
		_poly([Vector2(x,810),Vector2(x+direction*92,810),Vector2(x+direction*35,801),Vector2(x+direction*43,795),Vector2(x+direction*8,784),Vector2(x,738)],INK)
	if game.hurt_flash > 0 and not game.reduced_motion:
		draw_rect(Rect2(0, 0, 1440, 810), Color(0.65, 0.08, 0.12, game.hurt_flash * 0.6))

func _button(rect: Rect2, text: String, hint: String) -> void:
	var hover = rect.has_point(get_global_mouse_position())
	_brush(Rect2(rect.position+Vector2(4,5),rect.size),Color("9f5843"),3,4)
	_brush(rect,Color("49382e") if hover else INK,3,4)
	_splatter(rect.position+Vector2(4,rect.size.y-6),12,INK,4)
	_text(rect.position + Vector2(22, 40), text, 16, PAPER)
	_text(rect.position + Vector2(rect.size.x - 72, 40), hint, 12, PAPER)

func _title() -> void:
	# A directional scrim retains the landscape while giving the title contrast.
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1050, 0), Vector2(1050, 735), Vector2(0, 735)]), PackedColorArray([Color(0.95, 0.92, 0.85, 0.82), Color(0.95, 0.92, 0.85, 0), Color(0.95, 0.92, 0.85, 0), Color(0.95, 0.92, 0.85, 0.82)]))
	_tracked(Vector2(90, 83), Texts.ui("un_racconto_a_tre_voci"), 12, GOLD, 3.0)
	draw_line(Vector2(90, 112), Vector2(151, 112), GOLD, 1)
	_text(Vector2(84, 258), Texts.ui("ceneri"), 110, IVORY, true)
	_text(Vector2(89, 356), Texts.ui("echi"), 110, IVORY, true)
	_tracked(Vector2(94, 405), Texts.ui("la_fuga_dallarchivio"), 14, GOLD, 3.6)
	_note(Vector2(93, 463), Texts.ui("quattro_anni_perduti_una_via_per_uscire"), 28, Color("4a4339"))
	_note(Vector2(93, 493), Texts.ui("il_primo_capitolo_della_vostra_avventura"), 24, MUTED)
	_button(Rect2(90, 535, 320, 64), Texts.ui("scegli_eroe"), Texts.ui("invio"))
	_text(Vector2(93, 636), Texts.ui("a_d_muovi_w_s_cambia_corsia"), 19, MUTED)
	_text(Vector2(93, 662), Texts.ui("j_mazza_k_l_u_i_magie_spazio_schiva"), 19, MUTED)
	_text(Vector2(93, 688), Texts.ui("v_richiama_gli_alleati_f1_tutti_i_comandi"), 19, MUTED)
	draw_rect(Rect2(0,738,1440,72),PAPER)
	draw_line(Vector2(90, 746), Vector2(1350, 746), Color(0.75, 0.66, 0.45, 0.27), 1)
	_tracked(Vector2(93, 775), Texts.ui("demo_giocabile"), 11, GOLD, 2)
	_text(Vector2(285, 775), Texts.ui("capitolo_1_b_arena_del_ponte"), 12, MUTED)
	_text(Vector2(1078, 775), Texts.ui("f1_comandi_m_audio"), 12, MUTED)
	_tracked(Vector2(1120, 68), Texts.ui("ceneri_001"), 10, Color("6c6254"), 2)

# Deterministic brush silhouettes: texture stays fixed while the UI is idle.
func _brush(rect: Rect2, color: Color, seed: float=1.0, roughness: float=3.0) -> void:
	if rect.size.x<=10 or rect.size.y<=roughness*2: return
	var points=PackedVector2Array()
	for side in range(2):
		for i in range(25):
			var t=float(i if side==0 else 24-i)/24.0
			var grain=sin(t*91.0+seed)*0.6+sin(t*173.0+seed*2.3)*0.4
			var x=rect.position.x+t*rect.size.x
			var y=rect.position.y+(0.0 if side==0 else rect.size.y)
			x+=(-5.0 if side==0 else 5.0)*(1.0-t)
			y+=grain*roughness+(1.0-t)*(-2.0 if side==0 else 3.0)
			points.append(Vector2(x,y))
	draw_colored_polygon(points,color)

func _splatter(pos: Vector2, radius: float, color: Color, seed: float) -> void:
	var points=PackedVector2Array()
	for i in range(32):
		var angle=float(i)*TAU/32.0
		var r=radius*(0.65+0.18*sin(i*2.7+seed)+0.16*sin(i*4.1-seed))
		points.append(pos+Vector2(cos(angle),sin(angle))*r)
	draw_colored_polygon(points,color)
	for i in range(20):
		var angle=i*2.399+seed
		var axis=Vector2(cos(angle),sin(angle))
		var distance=radius*(1.25+float(i%5)*0.41)
		var dot=maxf(0.65,radius*(0.045+float(i%4)*0.035))
		var center=pos+axis*distance
		draw_circle(center,dot,color,true,-1.0,true)
		# Some drops retain a short tapered tail; most stay detached from the pool.
		if i%4==0:
			var normal=Vector2(-axis.y,axis.x)*dot*0.65
			_poly([center+normal,center-normal,center-axis*dot*3.5],color)

func _panel(rect: Rect2, border: Color=Color("9c8e7c")) -> void:
	var seed=rect.position.x*0.13+rect.position.y*0.37
	_brush(Rect2(rect.position+Vector2(-2,2),rect.size+Vector2(5,3)),INK,seed,3.0)
	_brush(rect,Color("f4eddf"),seed,1.7)
	_brush(Rect2(rect.position+Vector2(2,-1),Vector2(rect.size.x-4,3)),border,seed,1.6)
	# Spatter is confined to the outer edge, clear of portraits and text.
	_splatter(rect.position+Vector2(1,rect.size.y-4),3.7,INK,seed)
	_splatter(rect.end+Vector2(-2,-3),3.0,INK,seed+2)

func _keycap(pos: Vector2, key_label: String, width: float=36.0) -> void:
	_poly([pos+Vector2(-2,2),pos+Vector2(width+3,-2),pos+Vector2(width,29),pos+Vector2(1,32)],INK)
	_center(pos+Vector2(width*0.5,21),key_label,16,PAPER)

func _hud() -> void:
	var run=game.run
	var col: Color=game.HEROES[0].color
	_panel(Rect2(24,20,294,112),col)
	draw_texture_rect(portraits[0],Rect2(39,39,51,72),false)
	_text(Vector2(107,49),Texts.ui("tholgrin"),26,INK,true)
	_text(Vector2(107,74),Texts.ui("salute_d_d") % [ceili(game.player.hp),int(game.player.max_hp)],16)
	draw_rect(Rect2(107,84,192,8),Color("d7cdb9"))
	draw_rect(Rect2(107,84,192*game.player.hp/game.player.max_hp,8),col)
	_note(Vector2(107,117),Texts.ui("luce_livello_d") % run.level,20)
	_panel(Rect2(338,20,270,112))
	_text(Vector2(357,47),Texts.ui("mana_d_100") % int(run.mana),16)
	draw_rect(Rect2(357,59,232,8),Color("d7cdb9"))
	draw_rect(Rect2(357,59,232*run.mana/100,8),TEAL)
	_note(Vector2(357,92),Texts.ui("la_mazza_recupera_10_mana"),20)
	if run.taken.is_empty(): _note(Vector2(357,116),Texts.ui("rigenera_anche_nel_tempo"),19)
	else: _text(Vector2(357,116),run.path_summary(),14,TEAL)
	_panel(Rect2(628,20,392,112))
	var ready=run.intesa>=60
	_text(Vector2(648,47),Texts.ui("intesa_d_100") % int(run.intesa),16)
	draw_rect(Rect2(648,59,350,8),Color("d7cdb9"))
	draw_rect(Rect2(648,59,350*run.intesa/100,8),Color("775398"))
	draw_line(Vector2(858,56),Vector2(858,71),INK,1.5)
	_note(Vector2(648,92),Texts.ui("v_tre_voci_pronte") if run.intesa>=100 else Texts.ui("v_layla_pronta_attendi_100_per_il_trio") if ready else Texts.ui("60_layla_100_layla_e_lupinor"),20)
	_note(Vector2(648,116),Texts.ui("si_carica_infliggendo_e_subendo_danni"),19)
	_panel(Rect2(1040,20,376,112))
	_text(Vector2(1060,47),Texts.ui("resistance_header") % [run.stage_number(),run.current_level().stages.size()] if game.horizontal_locked() else Texts.ui("livello_stage") % [run.level_number(),run.stage_number(),run.current_level().stages.size()] if game.campaign else Texts.ui("boss_finale") if game.wave==4 else Texts.ui("stanza_d_3") % game.wave,14,GOLD)
	_text(Vector2(1060,76),run.NAMES[clampi(game.wave-1,0,run.NAMES.size()-1)] if game.campaign else run.ROOM_NAMES[maxi(0,game.wave-1)],23,INK,true)
	var boss=null
	for enemy in game.enemies:
		if enemy.kind=="warden" and enemy.alive(): boss=enemy
	if boss!=null:
		draw_rect(Rect2(1060,89,336,8),Color("ded2c4"))
		draw_rect(Rect2(1060,89,336*boss.hp/boss.max_hp,8),Color("9b5c60"))
		_text(Vector2(1060,119),Texts.ui("custode_d_d") % [ceili(boss.hp),int(boss.max_hp)],14)
	else:
		_note(Vector2(1060,110),run.objective_label() if game.campaign else Texts.ui("d_avversari_rimasti") % game.living_enemies(),22)
	if game.campaign and game.wave>0:
		var rule=run.current_rule()
		var progress: float=0
		if rule.type in ["defense","resistance"]: progress=run.objective_time/float(rule.duration)
		elif rule.type=="synchronization": progress=float(run.synchronization.completed(rule.synchronization))/rule.synchronization.sigils.size()
		elif rule.type in ["escape","scrolling"]: progress=clampf((game.player.x-float(rule.stage.player_x))/maxf(1,float(rule.exit.x)-float(rule.stage.player_x)),0,1)
		draw_rect(Rect2(1060,121,336,4),Color("d7cdb9"))
		draw_rect(Rect2(1060,121,336*progress,4),TEAL)
	if game.campaign and game.wave>0 and run.current_rule().type=="scrolling":
		if run.road.active:
			_panel(Rect2(470,148,500,55),GOLD)
			_center(Vector2(720,183),Texts.ui("road_stop"),23,INK,true)
		else: _center(Vector2(720,180),Texts.ui("road_go"),23,TEAL,true)
		_entry_warnings()
	elif game.campaign and game.wave>0 and run.current_rule().type=="synchronization":
		_synchronization_hud()
	elif game.horizontal_locked():
		_resistance_hud()
	elif boss!=null and boss.state==game.Fighter.State.WINDUP:
		_panel(Rect2(24,149,410,66),Color("9c555e"))
		_text(Vector2(40,176),Texts.ui("spazzata") if boss.attack_variant==1 else Texts.ui("fendente"),18,Color("984d3d"))
		_note(Vector2(40,202),Texts.ui("schiva_o_cambia_corsia"),22,INK)
	elif game.wave_banner>0 and not game.campaign:
		if game.campaign: _panel(Rect2(407,145,626,53),GOLD)
		_center(Vector2(720,180),run.NAMES[clampi(game.wave-1,0,run.NAMES.size()-1)] if game.campaign else run.ROOM_NAMES[maxi(0,game.wave-1)],29,INK,true)
	if run.notice_time>0:
		if game.campaign: _brush(Rect2(300,663,840,33),PAPER,8,3)
		_center(Vector2(720,686),run.notice,19,INK)
	elif run.buff_time>0:
		_center(Vector2(720,686),Texts.ui("s_1f_s_s") % [run.skill_name(2),run.buff_time,Texts.ui("scudo_d") % int(run.barrier) if run.barrier>0 else ""],18,GOLD)
	draw_rect(Rect2(0,714,1440,96),PAPER)
	_brush(Rect2(0,710,1440,5),INK,9,3)
	_text(Vector2(24,743),Texts.ui("resistance_controls_short") if game.horizontal_locked() else Texts.ui("a_d_muovi_w_s_corsia"),14)
	_text(Vector2(24,768),Texts.ui("j_mazza_q_scudo"),14)
	_text(Vector2(24,793),Texts.ui("spazio_schiva_f1_aiuto"),13)
	for i in range(4):
		_skill_card(i)
	_text(Vector2(1276,752),Texts.ui("v_intesa"),15)
	_text(Vector2(1276,779),Texts.ui("esc_pausa"),13)

func _skill_icon(rect: Rect2, slot: int, progress: float=1.0) -> void:
	draw_texture_rect(skill_icons_grey[slot],rect,false)
	if progress<=0: return
	var texture=skill_icons[slot]
	var full=Vector2(texture.get_size())
	var amount=clampf(progress,0,1)
	draw_texture_rect_region(texture,Rect2(rect.position+Vector2(0,rect.size.y*(1-amount)),Vector2(rect.size.x,rect.size.y*amount)),Rect2(Vector2(0,full.y*(1-amount)),Vector2(full.x,full.y*amount)))

func _skill_card(slot: int) -> void:
	var run=game.run
	var x=270+slot*248
	var rect=Rect2(x,729,234,67)
	var cooling=run.skill_cd[slot]>0
	var available=not cooling and run.mana>=run.cost(slot)
	var color: Color=[Color("d1a74e"),Color("c35e31"),Color("588d85"),Color("cb8b35")][slot]
	_panel(rect,color if available else Color("8d8982"))
	var inner=rect.grow(-4)
	draw_rect(inner,Color("d7d4ce"))
	var progress=run.cooldown_progress(slot)
	# The whole grey card fills vertically with its spell's color as time returns.
	if progress>0:
		var height=inner.size.y*progress
		draw_rect(Rect2(inner.position+Vector2(0,inner.size.y-height),Vector2(inner.size.x,height)),Color("f1e9d7").lerp(color,0.25 if available or cooling else 0.07))
	_skill_icon(Rect2(x+8,737,47,47),slot,progress if cooling else 1.0 if available else 0.0)
	draw_rect(Rect2(x+8,772,20,18),INK)
	_center(Vector2(x+18,786),run.KEYS[slot],13,PAPER)
	var label=run.skill_name(slot)
	var size=18
	while serif.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>165 and size>14: size-=1
	_text(Vector2(x+61,753),label,size,Color("65635f") if cooling else INK,true)
	var status=Texts.ui("1f_s") % run.skill_cd[slot] if cooling else Texts.ui("pronta_d_mana") % int(run.cost(slot)) if available else Texts.ui("mana_insufficiente")
	if not run.mutation_name(slot).is_empty():
		_text(Vector2(x+61,766),run.mutation_name(slot),11,color)
	_text(Vector2(x+61,784),status,19 if cooling else 13,INK if cooling or available else MUTED)
	draw_rect(Rect2(x+4,791,226*progress,3),color if cooling or available else MUTED)

func _hero_card(i: int) -> void:
	var rect: Rect2=game.hero_card_rect(i)
	var active=game.player.hero==i
	var data: Dictionary=game.HEROES[i]
	var hp: float=game.player.hp if active else game.health[i]
	var alive=hp>0
	var col: Color=data.color
	_panel(rect,col if active else Color("a89b89"))
	if active:
		_brush(Rect2(rect.position+Vector2(1,1),Vector2(rect.size.x-2,6)),INK,4+i,2)
		_splatter(rect.position+Vector2(9,7),7,col,4+i)
	var left=rect.position.x
	var portrait=portraits[i]
	var size=Vector2(portrait.get_size())
	size*=minf(62.0/size.x,72.0/size.y)
	draw_texture_rect(portrait,Rect2(Vector2(left+12+(62-size.x)*0.5,43),size),false,Color.WHITE if alive else Color("525863"))
	_text(Vector2(left+86,47),data.name.capitalize(),22,IVORY if alive else MUTED,true)
	_note(Vector2(left+86,70),Texts.ui("in_campo") if active else (Texts.ui("esausto") if not alive else Texts.ui("d_scegli") % [i+1]),19,col if active else MUTED)
	draw_rect(Rect2(left+86,82,164,9),Color("d7cdb9"))
	draw_rect(Rect2(left+86,82,164*clampf(hp/data.hp,0,1),9),col if alive else MUTED)
	var filled=164*clampf(hp/data.hp,0,1)
	for mark in range(0,int(filled),6):
		draw_line(Vector2(left+86+mark,83),Vector2(left+86+minf(mark+5,filled),90),Color(0.20,0.16,0.12,0.28),0.8,true)
	_text(Vector2(left+86,113),Texts.ui("salute_d_d") % [ceili(hp),int(data.hp)],16,IVORY)
	if active:
		_keycap(Vector2(left+224,33),str(i+1),28)

func _super_banner() -> void:
	if not is_instance_valid(banner_clip):
		return
	banner_clip.visible=not game.super_banner.is_empty() and not game.help_open and game.mode=="playing"
	if not banner_clip.visible:
		return
	var banner: Dictionary=game.super_banner
	var elapsed: float=banner.max-banner.life
	# A real horizontal wipe clips both ink and lettering, with no entry fade.
	var reveal=1.0 if game.reduced_motion else clampf(elapsed/0.16,0.0,1.0)
	banner_clip.size=Vector2(675.0*reveal,151)
	banner_art.queue_redraw()

func _super_banner_art() -> void:
	if game.super_banner.is_empty():
		return
	var banner: Dictionary=game.super_banner
	var hero: Dictionary=game.HEROES[banner.hero]
	var opacity=clampf(banner.life/0.22,0.0,1.0)
	var accent=Color(hero.color,opacity)
	var black=Color(INK,opacity)
	# Uneven pooled ink, lobes and detached droplets replace the rectangular card.
	_ink_pool(Vector2(250,39),Vector2(267,39),accent,6)
	_ink_pool(Vector2(245,30),Vector2(267,40),black,4)
	_splatter(Vector2(18,30),35,black,8)
	_splatter(Vector2(476,29),28,black,5)
	_splatter(Vector2(505,39),18,black,11)
	_late_ink_drops(banner.max-banner.life,black,accent)
	_brush(Rect2(22,6,57,3),accent,3,1.4)
	_text(Vector2(91,16),hero.name+Texts.ui("super"),12,Color(PAPER,opacity))
	var move_name: String=banner.get("name",hero.special.to_lower().capitalize())
	var title_size=36
	while serif.get_string_size(move_name,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x>460.0 and title_size>24:
		title_size-=1
	_text(Vector2(43,49),move_name,title_size,Color(PAPER,opacity),true)

func _late_ink_drops(elapsed: float, ink: Color, accent: Color) -> void:
	# Two small after-splashes land beside the lettering, after the wipe finishes.
	for i in range(18):
		var delay=0.24+float(i/9)*0.17+float(i%9)*0.009
		if elapsed<delay:
			continue
		var settle=1.0 if game.reduced_motion else clampf((elapsed-delay)/0.065,0.0,1.0)
		var x=56.0+fposmod(i*97.7,418.0)
		var upper=i%2==0
		var target=Vector2(x,-17.0-float(i%3)*5 if upper else 77.0+float(i%3)*6)
		var direction=Vector2(0.35 if i%3==0 else -0.2,-1 if upper else 1).normalized()
		var center=target-direction*8.0*pow(1.0-settle,2.0)
		var radius=(1.2+float(i%4)*0.65)*(0.4+0.6*settle)
		var col=accent if i%5==0 else ink
		draw_circle(center,radius,col,true,-1.0,true)
		if i%4==0:
			var normal=Vector2(-direction.y,direction.x)*radius*0.6
			_poly([center+normal,center-normal,center-direction*radius*2.7],col)

func _ink_pool(pos: Vector2, size: Vector2, color: Color, seed: float) -> void:
	var points=PackedVector2Array()
	for i in range(120):
		var angle=i*TAU/120.0
		var ripple=1.0+0.045*sin(i*1.7+seed)+0.055*sin(i*0.71-seed)
		points.append(pos+Vector2(cos(angle),sin(angle))*size*ripple)
	draw_colored_polygon(points,color)

func _pause() -> void:
	draw_rect(Rect2(0, 0, 1440, 810), Color(0.95,0.92,0.85,0.92))
	_center(Vector2(720, 310), Texts.ui("pausa"), 42, IVORY, true)
	_center(Vector2(720, 357), Texts.ui("la_partita_e_ferma_riprendi_quando_vuoi"), 18, MUTED)
	_button(Rect2(550, 460, 340, 64), Texts.ui("riprendi"), Texts.ui("invio"))
	_center(Vector2(720, 576), Texts.ui("f1_comandi_e_abilita_r_ricomincia_m_audio"), 18, MUTED)
	_center(Vector2(720, 610), Texts.ui("f2_movimento_ridotto") + (Texts.ui("attivo") if game.reduced_motion else Texts.ui("disattivo")), 13, MUTED)

func _ending() -> void:
	if game.campaign and game.mode=="victory":
		_archive_ending()
		return
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1100, 0), Vector2(1100, 810), Vector2(0, 810)]), PackedColorArray([Color(0.95, 0.92, 0.85, 0.95), Color(0.95, 0.92, 0.85, 0), Color(0.95, 0.92, 0.85, 0), Color(0.95, 0.92, 0.85, 0.95)]))
	var won: bool = game.mode == "victory"
	_tracked(Vector2(92, 205), Texts.ui("prova_completata") if won else Texts.ui("il_fuoco_si_affievolisce"), 12, GOLD, 3)
	_text(Vector2(86, 310), (Texts.ui("al_sicuro_per_ora") if game.campaign else Texts.ui("il_ponte_e_vostro")) if won else Texts.ui("nessuno_resta_solo"), 58, IVORY, true)
	_text(Vector2(92, 369), (Texts.ui("i_rapporti_sono_salvi_la_prima_pista_lorologio_di_thultanthar") if game.campaign else Texts.ui("tre_voci_una_vittoria_la_run_e_completa")) if won else Texts.ui("una_nuova_run_nuove_benedizioni_riprova"), 21, MUTED)
	_text(Vector2(92, 425), Texts.ui("d_avversari_sconfitti_d_02d_di_battaglia") % [game.kills,int(game.encounter_time)/60,int(game.encounter_time)%60], 17, GOLD)
	_button(Rect2(90, 535, 320, 64), Texts.ui("nuova_run"), Texts.ui("invio"))
	_text(Vector2(92, 646), Texts.ui("la_ricostruzione_delle_missioni_sara_il_prossimo_capitolo") if game.campaign else Texts.ui("questa_e_solo_la_prima_scintilla_della_vostra_avventura"), 15, MUTED)

func _help() -> void:
	draw_rect(Rect2(0,0,1440,810),Color("f1e9d7"))
	_text(Vector2(72,76),Texts.ui("il_grimorio_di_tholgrin"),40,INK,true)
	_note(Vector2(72,114),Texts.ui("resisti_copri_layla_e_raggiungi_luscita_i_dialoghi_avanzano_solo_con_il_tuo_comando") if game.campaign else Texts.ui("tre_stanze_tre_benedizioni_poi_il_custode_una_sola_vita_per_run"),26)
	var rows=[
		[Texts.ui("a_d"),Texts.ui("resistance_turn") if game.horizontal_locked() else Texts.ui("muovi")],[Texts.ui("w_s"),Texts.ui("cambia_corsia")],["J",Texts.ui("mazza_recupera_10_mana_se_colpisce")],
		["Q",Texts.ui("tieni_lo_scudo_verso_il_nemico")],[Texts.ui("spazio"),Texts.ui("schiva_e_attraversa_il_pericolo")],
		["V",Texts.ui("intesa_60_richiama_layla_100_il_trio")],[Texts.ui("1_2_3"),Texts.ui("scegli_una_benedizione_alla_locanda") if game.campaign else Texts.ui("scegli_una_benedizione_tra_le_stanze")]]
	for i in range(rows.size()):
		var y=176+i*57
		_keycap(Vector2(72,y),rows[i][0],100)
		_text(Vector2(192,y+22),rows[i][1],18)
	for i in range(4):
		var y=170+i*108
		_panel(Rect2(760,y,606,99))
		_skill_icon(Rect2(778,y+14,44,44),i)
		draw_rect(Rect2(778,y+52,18,16),INK)
		_center(Vector2(787,y+65),game.run.KEYS[i],12,PAPER)
		_text(Vector2(837,y+29),game.run.skill_name(i),25,GOLD,true)
		draw_multiline_string(notes,Vector2(837,y+59),game.run.skill_description(i),HORIZONTAL_ALIGNMENT_LEFT,510,19,2,INK)
	_note(Vector2(72,652),Texts.ui("le_benedizioni_trasformano_le_magie_per_questa_run_alla_sconfitta_si_ricomincia"),26,INK)
	_text(Vector2(72,696),Texts.ui("gamepad_stick_croce_muove_x_mazza_y_b_lb_rb_magie_a_schiva_r3_intesa"),17)
	_text(Vector2(72,731),Texts.ui("ricompense_sinistra_destra_e_start_conferma_back_pausa"),16)
	_text(Vector2(72,778),Texts.ui("esc_f1_chiudi_m_audio_f2_movimento_ridotto_r_nuova_run"),17)

func _selection() -> void:
	draw_rect(Rect2(0,0,1440,810),PAPER)
	_text(Vector2(72,85),Texts.ui("scegli_chi_guidera_il_gruppo"),44,INK,true)
	_note(Vector2(72,127),Texts.ui("un_protagonista_per_tutta_la_run_gli_amici_restano_al_tuo_fianco"),27)
	for i in range(3):
		var y=175+i*137
		_panel(Rect2(72,y,596,117),game.HEROES[i].color if i==0 else MUTED)
		draw_texture_rect(portraits[i],Rect2(91,y+17,48,71),false)
		_text(Vector2(157,y+34),game.HEROES[i].name.capitalize(),28,INK,true)
		_note(Vector2(157,y+63),[Texts.ui("magie_a_distanza_protezione_e_fuoco_radiante"),Texts.ui("lame_veloci_furtivita_e_attacchi_psionici"),Texts.ui("scimitarra_posizionamento_ed_eco")][i],22)
		_text(Vector2(157,y+95),Texts.ui("pronto_prototipo_giocabile") if i==0 else Texts.ui("in_sviluppo_presente_come_alleato"),15,GOLD if i==0 else MUTED)
	_hero(Vector2(1010,597),0,0,1,0,Color.WHITE,1.65)
	_text(Vector2(795,660),Texts.ui("tholgrin_livello_9"),38,INK,true)
	_note(Vector2(795,698),Texts.ui("dominio_della_luce_quattro_magie_pronte"),26)
	_button(Rect2(90,620,340,64),Texts.ui("parti_con_tholgrin"),Texts.ui("invio"))
	_note(Vector2(90,725),Texts.ui("archivio_passaggio_segreto_fuga_locanda"),25,INK)
	_text(Vector2(90,773),Texts.ui("esc_torna_al_titolo"),16)

func _art_cover(texture: Texture2D, rect: Rect2, focus: Vector2=Vector2(0.5,0.5)) -> void:
	var source=Vector2(texture.get_size())
	var scale_factor=maxf(rect.size.x/source.x,rect.size.y/source.y)
	var visible=rect.size/scale_factor
	var offset=(source-visible)*focus
	draw_texture_rect_region(texture,rect,Rect2(offset,visible))

func _comic() -> void:
	if game.campaign:
		_archive_comic()
		return
	draw_rect(Rect2(0,0,1440,810),PAPER)
	var page=game.run.Story.page(game.wave)
	_text(Vector2(42,70),game.run.Story.TITLES[game.wave-1],42,INK,true)
	_note(Vector2(44,111),Texts.ui("sul_ponte_delle_braci_dopo_la_stanza_d") % game.wave,24)
	for i in range(3):
		var panel=Rect2(40+i*466,146,428,561)
		_art_cover(comic_panels[game.wave-1][i],panel,Vector2(0.5,0.42))
		draw_rect(panel,INK,false,2.0)
		if i>=game.run.interlude_revealed:
			draw_rect(panel,Color(PAPER,0.38))
		else:
			var beat: Dictionary=page[i]
			_balloon(Rect2(panel.position+Vector2(14,386),Vector2(400,155)),beat.hero,beat.text,game.run.Story.TAILS[game.wave-1][i])
	var complete=game.run.interlude_revealed>=3
	_note(Vector2(44,752),Texts.ui("il_fuoco_e_pronto_scegliamo_come_proseguire") if complete else Texts.ui("il_gruppo_si_concede_un_respiro"),25,INK)
	_text(Vector2(44,790),Texts.ui("invio_spazio_clic_accampamento") if complete else Texts.ui("invio_spazio_clic_prossima_battuta"),16)
	_text(Vector2(1050,790),Texts.ui("esc_salta_il_dialogo"),16,MUTED)

func _balloon(rect: Rect2, hero: int, dialogue: String, tail_x: float, speaker: String="") -> void:
	var tail=PackedVector2Array([rect.position+Vector2(tail_x-16,4),rect.position+Vector2(tail_x,-26),rect.position+Vector2(tail_x+16,4)])
	draw_colored_polygon(tail,Color("fbf5e8"))
	draw_polyline(tail,INK,2,true)
	draw_style_box(balloon_style,rect)
	_text(rect.position+Vector2(19,32),game.HEROES[hero].name.capitalize() if speaker.is_empty() else speaker,24,game.HEROES[hero].color if speaker.is_empty() else GOLD,true)
	draw_multiline_string(notes,rect.position+Vector2(19,65),dialogue,HORIZONTAL_ALIGNMENT_LEFT,362,25,3,INK)

func _rewards() -> void:
	_art_cover(_mission_texture(game.run.content.mission.presentation.reward_background) if game.campaign else camp_art,Rect2(0,0,1440,810),Vector2(0.5,0.48))
	# Text stays on paper; the entire camp remains visible above the cards.
	draw_rect(Rect2(0,0,1440,145),Color(PAPER,0.92))
	_text(Vector2(66,57),Texts.ui("tra_le_pagine_dimenticate") if game.campaign else Texts.ui("al_calore_delle_braci"),39,INK,true)
	_note(Vector2(66,96),Texts.ui("build_header"),26,INK)
	_text(Vector2(66,128),Texts.ui("livello_d_d_riposo_20_salute_30_mana_intesa_d_100") % [game.run.level,game.run.level+1,int(game.run.intesa)],16,MUTED)
	_brush(Rect2(66,354,1288,34),PAPER,6,2)
	_text(Vector2(85,378),Texts.ui("build_current").format({"build":game.run.path_summary()}),19,INK)
	for i in range(game.run.choices.size()):
		var item: Dictionary=game.run.choices[i]
		var rect: Rect2=game.reward_rect(i)
		var active=i==game.reward_cursor or rect.has_point(get_global_mouse_position())
		var path=game.run.path_data(item.path)
		var rank: int=game.run.path_rank(item.path)
		var accent=Color(path.color)
		_panel(rect,accent if active else MUTED)
		_text(rect.position+Vector2(20,25),Texts.ui("build_rank").format({"name":path.name,"rank":mini(2,rank+1)}),18,accent)
		var tag=Texts.ui("build_new") if rank==0 else Texts.ui("build_deepen") if rank==1 else Texts.ui("build_max")
		_text(rect.position+Vector2(190,25),tag,12,accent)
		if active: _brush(Rect2(rect.position,Vector2(rect.size.x,5)),INK,2,2)
		_skill_icon(Rect2(rect.position+Vector2(20,39),Vector2(54,54)),item.slot)
		draw_rect(Rect2(rect.position+Vector2(19,77),Vector2(20,18)),INK)
		_center(rect.position+Vector2(29,91),str(i+1),13,PAPER)
		_text(rect.position+Vector2(88,64),Texts.ui("s_s") % [game.run.KEYS[item.slot],game.run.BASE_NAMES[item.slot]],15,GOLD)
		var size=29
		while serif.get_string_size(item.name,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>302 and size>19: size-=1
		_text(rect.position+Vector2(88,106),item.name,size,INK,true)
		var desc_size=23
		while notes.get_string_size(item.desc,HORIZONTAL_ALIGNMENT_LEFT,-1,desc_size).x>700 and desc_size>19: desc_size-=1
		draw_multiline_string(notes,rect.position+Vector2(20,141),item.desc,HORIZONTAL_ALIGNMENT_LEFT,370,desc_size,2,INK)
		draw_multiline_string(font,rect.position+Vector2(20,193),item.detail,HORIZONTAL_ALIGNMENT_LEFT,370,15,2,MUTED)
		_text(rect.position+Vector2(20,246),Texts.ui("ricarica_2f_2f_s") % [game.run.cooldown_for(item.slot,"current",-1,false),game.run.cooldown_for(item.slot,item.id,game.run.level+1,false)],14,GOLD)
		draw_line(rect.position+Vector2(20,257),rect.position+Vector2(390,257),Color(accent,0.4),1)
		draw_multiline_string(font,rect.position+Vector2(20,280),game.run.path_trait(item.path,mini(2,rank+1)),HORIZONTAL_ALIGNMENT_LEFT,370,15,2,accent)
	draw_rect(Rect2(0,737,1440,73),Color(PAPER,0.96))
	_text(Vector2(66,765),Texts.ui("1_2_3_oppure_clic_sulla_carta_gamepad_sinistra_destra_e_start"),17)
	var next_label=Texts.ui("il_custode_del_ponte") if game.wave==3 else Texts.ui("stanza_d") % [game.wave+1]
	_note(Vector2(66,795),Texts.ui("una_scelta_per_il_cammino_conclude_questo_primo_capitolo") if game.campaign else Texts.ui("una_scelta_per_questa_run_prossima_tappa")+next_label,22)

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



func _archive_environment() -> void:
	# Graphite architecture and ground are independent nodes behind this actor pass.
	for lane in range(3):
		var y: float=game.LANES[lane]
		for i in range(floori(game.camera_x/90)-2,floori(game.camera_x/90)+22):
			var x=i*90.0-game.camera_x
			draw_line(Vector2(x,y+7),Vector2(x+24,y+7),Color(INK,0.18 if game.player.lane==lane else 0.07),1,true)
	if game.mode in ["playing","paused"]:
		AbilityInk.ground(self)
		if game.run.current_rule().type=="synchronization": game.run.synchronization.draw_ground(self,game.run)
		if game.run.current_rule().allies.visible:
			_hero(Vector2(1120-game.camera_x,470),1,0,-1,0,Color.WHITE,0.85)
			_brush(Rect2(1051-game.camera_x,283,164,30),PAPER,4,3)
			_note(Vector2(1060-game.camera_x,306),Texts.ui(game.run.current_rule().allies.get("label","layla_uscita")),20,Color("775398"))
			_hero(Vector2(400-game.camera_x,470),2,0,-1,0,Color(0.45,0.75,0.73,0.38),0.85)
			_brush(Rect2(330-game.camera_x,277,173,30),PAPER,5,3)
			_note(Vector2(338-game.camera_x,300),Texts.ui("eco_di_lupinor"),20,TEAL)
		elif game.run.current_rule().type in ["escape","scrolling","synchronization"]:
			_brush(Rect2(float(game.run.current_rule().exit.x)-40-game.camera_x,501,174,44),PAPER,6,5)
			_text(Vector2(float(game.run.current_rule().exit.x)-27-game.camera_x,529),Texts.ui("uscita"),19,TEAL)
	for i in range(18):
		var x=fposmod(i*127.8-game.camera_x*0.6,1700)-100
		var y=fposmod(i*71.7-game.time*3,640)
		draw_circle(Vector2(x,y),0.8,Color(INK,0.12))

func _archive_comic() -> void:
	var run=game.run
	var chapter=run.Chapter
	var index: int=run.story_page
	draw_rect(Rect2(0,0,1440,810),PAPER)
	_text(Vector2(42,70),chapter.TITLES[index],42,INK,true)
	_note(Vector2(44,111),chapter.SUBTITLES[index],24)
	for i in range(3):
		var panel=Rect2(40+i*466,146,428,561)
		_art_cover(_mission_texture(run.content.mission.presentation.comics[chapter.ART[index]][i]),panel,Vector2(0.5,0.08))
		draw_rect(panel,INK,false,2)
		if i>=run.interlude_revealed: draw_rect(panel,Color(PAPER,0.38))
		else:
			var beat: Dictionary=chapter.BEATS[index][i]
			_balloon(Rect2(panel.position+Vector2(14,386),Vector2(400,155)),beat.hero,beat.text,180,beat.get("name",""))
	_note(Vector2(44,752),Texts.ui("leggi_al_tuo_ritmo_la_fuga_aspetta_il_tuo_comando"),25,INK)
	_text(Vector2(44,790),Texts.ui("invio_spazio_clic")+(Texts.ui("continua") if run.interlude_revealed==3 else Texts.ui("prossima_battuta")),16)
	_text(Vector2(1050,790),Texts.ui("esc_salta_questa_pagina"),16,MUTED)

func _archive_ending() -> void:
	_art_cover(_mission_texture(game.run.content.mission.presentation.ending_background),Rect2(0,0,1440,810),Vector2(0.5,0.48))
	draw_rect(Rect2(0,0,1440,145),Color(PAPER,0.96))
	_text(Vector2(66,61),Texts.ui("run_completed"),43,INK,true)
	_note(Vector2(66,108),Texts.ui("run_completed_subtitle"),27,INK)
	_panel(Rect2(40,490,1360,263),GOLD)
	_button(Rect2(90,535,320,64),Texts.ui("ripeti_il_capitolo"),Texts.ui("invio"))
	_text(Vector2(90,641),Texts.ui("d_avversari_sconfitti_d_02d_di_battaglia_2") % [game.kills,int(game.encounter_time)/60,int(game.encounter_time)%60],16,MUTED)
	_text(Vector2(90,680),Texts.ui("tholgrin_livello_d") % game.run.level,23,GOLD,true)
	_text(Vector2(470,531),Texts.ui("run_build_heading"),29,INK,true)
	for i in range(game.run.taken.size()):
		var item: Dictionary=game.run.taken[i]
		_skill_icon(Rect2(470,548+i*51,37,37),int(item.slot))
		_note(Vector2(523,573+i*51),game.run.skill_name(int(item.slot))+" · "+item.name,25,INK)
	draw_multiline_string(notes,Vector2(470,695),Texts.ui("run_completed_note"),HORIZONTAL_ALIGNMENT_LEFT,840,23,2,MUTED)

	draw_rect(Rect2(0,766,1440,44),PAPER)
	_text(Vector2(66,795),Texts.ui("esc_torna_al_titolo_b_dal_titolo_prova_del_ponte"),16,INK)


func _prologue() -> void:
	var run=game.run
	var intro: Dictionary=run.Chapter.data.intro
	draw_rect(Rect2(0,0,1440,810),PAPER)
	_splatter(Vector2(25,50),100,Color(INK,0.09),8)
	_splatter(Vector2(1410,738),130,Color(INK,0.08),5)
	_tracked(Vector2(205,43),intro.kicker.to_upper(),13,GOLD,2)
	_text(Vector2(202,103),intro.title,43,INK,true)
	_brush(Rect2(205,128,1030,3),INK,3,1)
	_brush(Rect2(205,714,1030,3),INK,5,1)

	var content: String="\n\n".join(intro.paragraphs)
	if intro_signature!=content:
		intro_signature=content
		intro_body.text=content
		intro_body.position.y=40
		_note(Vector2(205,753),Texts.ui("intro_reading"),26,INK)
		_text(Vector2(205,790),Texts.ui("intro_controls"),15,MUTED)
		return
	var height: float=intro_body.get_content_height()
	var distance=maxf(0,40+height-(intro_clip.size.y-80))
	var duration=distance/30.0
	run.prologue_elapsed=minf(run.prologue_elapsed,duration)
	run.prologue_finished=run.prologue_elapsed>=duration
	intro_body.position.y=40-run.prologue_elapsed*30
	var status=Texts.ui("intro_continue") if run.prologue_finished else Texts.ui("intro_paused") if run.prologue_paused else Texts.ui("intro_reading")
	_note(Vector2(205,753),status,26,INK)
	_text(Vector2(205,790),Texts.ui("intro_controls"),15,MUTED)


func _resistance_hud() -> void:
	var run=game.run
	var remaining: int=ceili(run.resistance_remaining())
	var accent=Color("9c555e") if remaining<=5 else TEAL
	_panel(Rect2(380,145,680,124),accent)
	_text(Vector2(402,181),Texts.ui("resistance_title"),28,INK,true)
	_text(Vector2(927,182),Texts.ui("resistance_timer") % [remaining/60,remaining%60],32,accent)
	draw_rect(Rect2(402,195,636,12),Color("d7cdb9"))
	draw_rect(Rect2(402,195,636*(1-run.resistance_remaining()/run.resistance_duration()),12),accent)
	_text(Vector2(402,232),Texts.ui("resistance_waves") % [run.reinforcement,run.room_rules[game.wave-1].waves.size(),run.resistance_wave_name()],16,INK)
	_note(Vector2(402,257),Texts.ui("resistance_instructions"),20,MUTED)

	_entry_warnings()

func _entry_warnings() -> void:
	var run=game.run
	var warning: float=run.room_rules[game.wave-1].warning_time
	for entry in run.upcoming_entries():
		var from_left: bool=entry.side<0
		var y: float=game.CAMERA_PIVOT.y*(1-game.WORLD_ZOOM)+game.LANES[entry.lane]*game.WORLD_ZOOM-62
		var rect=Rect2(24 if from_left else 1226,y,190,60)
		var accent: Color={"guard":TEAL,"runner":Color("9c555e"),"archer":Color("775398"),"brute":Color("ad7753"),"caster":Color("8c64a6")}.get(entry.archetype,TEAL)
		_panel(rect,accent)
		var side=Texts.ui("entry_left") if from_left else Texts.ui("entry_right")
		var lane=Texts.ui(["entry_lane_high","entry_lane_middle","entry_lane_low"][entry.lane])
		_text(rect.position+Vector2(10,18),Texts.ui("entry_position") % [side,lane],11,accent)
		_text(rect.position+Vector2(31,43),Texts.ui("entry_"+entry.archetype),19,INK,true)
		_text(rect.position+Vector2(138,43),Texts.ui("entry_countdown") % maxf(0,entry.at+warning-run.room_time),13,accent)
		var point=rect.position+Vector2(16,37)
		var direction=1 if from_left else -1
		draw_polyline(PackedVector2Array([point+Vector2(-direction*6,-7),point+Vector2(direction*3,0),point+Vector2(-direction*6,7)]),accent,2,true)
		draw_rect(Rect2(rect.position+Vector2(5,54),Vector2(180*clampf((run.room_time-entry.at)/warning,0,1),3)),accent)

func _mission_texture(path: String) -> Texture2D:
	if not archive_panels.has(path): archive_panels[path]=load(path)
	return archive_panels[path]

func _synchronization_hud() -> void:
	var run=game.run
	var rule: Dictionary=run.current_rule().synchronization
	var danger=run.synchronization.warning(rule,run.room_time)
	_panel(Rect2(380,145,680,94),Color("a55b65") if danger else TEAL)
	_text(Vector2(402,168),Texts.ui("sync_header"),23,INK,true)
	_note(Vector2(402,190),Texts.ui("sync_instruction"),18,INK)
	var nearest=-1
	var distance=INF
	for i in range(rule.sigils.size()):
		if run.synchronization.charge[i]>=float(rule.charge_seconds): continue
		var delta=absf(game.player.x-float(rule.sigils[i].x))
		if delta<distance:
			distance=delta
			nearest=i
	if nearest>=0:
		var sigil: Dictionary=rule.sigils[nearest]
		var ratio: float=run.synchronization.charge[nearest]/float(rule.charge_seconds)
		var direction="sync_here" if distance<=float(rule.radius) else "sync_right" if float(sigil.x)>game.player.x else "sync_left"
		if distance<=float(rule.radius) and (game.player.lane!=int(sigil.lane) or absf(game.player.y-game.LANES[int(sigil.lane)])>=18): direction="sync_align"
		var hint=Texts.ui("sync_target").format({"n":nearest+1,"lane":Texts.ui("sync_lane_%d" % int(sigil.lane)),"direction":Texts.ui(direction)})
		_text(Vector2(402,211),hint,18,TEAL)
		draw_rect(Rect2(402,220,400,10),Color(TEAL,0.15))
		draw_rect(Rect2(402,220,400*ratio,10),TEAL)
		_text(Vector2(820,231),Texts.ui("sync_charging").format({"percent":int(ratio*100)}),17,INK)
	if danger: _text(Vector2(402,260),Texts.ui("sync_pulse_warning"),15,Color("9c4a56"))

func _stage_clear() -> void:
	var t=game.run.stage_clear_elapsed
	var reveal=1-pow(1-clampf(t/0.2,0,1),3)
	var x=280-35*(1-reveal)
	draw_rect(Rect2(0,0,1440,810),Color(PAPER,0.2))
	_brush(Rect2(x,302,880*reveal,146),INK,71,8)
	if t>0.14:
		_center(Vector2(720,362),Texts.ui("stage_clear_title"),40,PAPER,true)
		_center(Vector2(720,406),game.run.NAMES[game.wave-1],29,PAPER)
		_note(Vector2(515,487),Texts.ui("stage_clear_hint"),26,INK)

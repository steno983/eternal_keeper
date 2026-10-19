extends Node2D
## Whole-figure pencil animation. Only simulation clocks determine the pose.
const Bank=preload("res://scripts/pencil_bank.gd")
var actor
var game: Node2D
var sprite: AnimatedSprite2D
var echo_view=false
var key=""
var sampled_clip: StringName=&"idle"
func _ready() -> void:
	sprite=AnimatedSprite2D.new()
	sprite.name="PencilSprite"
	sprite.offset=Vector2(0,-192)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.speed_scale=0
	add_child(sprite)
func sync() -> void:
	if actor==null or not is_instance_valid(game):
		return
	var hero: bool=actor.kind=="hero"
	var index: int=actor.hero if hero else 0 if actor.kind=="raider" else 1 if actor.kind=="archer" else 2
	if not hero and actor.visual_index>=0: index=actor.visual_index
	if echo_view:
		index=2
	var next_key=("hero_" if hero else "enemy_")+str(index)
	if key!=next_key:
		key=next_key
		sprite.sprite_frames=Bank.library(key)
	visible=game.mode!="title" and sprite.sprite_frames!=null and (not echo_view or not game.echo.is_empty())
	if not visible:
		return
	var x: float=game.echo.x if echo_view else actor.x
	var y: float=game.LANES[game.echo.lane] if echo_view else actor.y
	var strength=0.0 if game.reduced_motion else game.trauma*game.trauma*30
	position=Vector2(x-game.camera_x,y)+Vector2(sin(game.time*73),sin(game.time*91))*strength
	var clip: StringName=&"idle"
	var clock: float=actor.locomotion_time
	var progress=actor.action_elapsed/maxf(actor.action_length,0.001)
	if actor.action_active():
		clip=actor.action
		clock=progress*Bank.length_of(sprite.sprite_frames,clip)
	elif hero and game.blocking and actor.hero==0:
		clip=&"guard"
	elif actor.moving and not echo_view:
		clip=&"run"
		var stride=[182.4,231.0,233.7][index] if hero else [102.0,108.0,99.76,108.0][index]
		clock=actor.travelled/stride*Bank.length_of(sprite.sprite_frames,clip)
	sampled_clip=clip
	if clip==&"attack" and hero:
		clip=[&"attack",&"attack_2",&"attack_3"][posmod(actor.combo_step,3)]
		clock=progress*Bank.length_of(sprite.sprite_frames,clip)
	if not hero and ((actor.kind=="warden" and actor.attack_variant==1) or actor.archetype=="brute"):
		if clip==&"attack":
			clip=&"attack_2"
			clock=progress*Bank.length_of(sprite.sprite_frames,clip)
		elif clip==&"windup":
			clip=&"attack_2"
			clock=progress*(0.25/0.54)*0.95*Bank.length_of(sprite.sprite_frames,clip)
	if echo_view:
		clip=&"idle"
		clock=actor.locomotion_time
		if game.echo_attack>0:
			clip=[&"attack",&"attack_2",&"attack_3"][posmod(actor.combo_step,3)]
			clock=(game.CONTACT_PHASE[2]+(1-game.echo_attack/0.25)*(1-game.CONTACT_PHASE[2]))*Bank.length_of(sprite.sprite_frames,clip)
	if not sprite.sprite_frames.has_animation(clip):
		clip=&"idle"
	if sprite.animation!=clip:
		sprite.play(clip)
	var point=Bank.sample(sprite.sprite_frames,clip,clock)
	sprite.set_frame_and_progress(int(point.x),point.y)
	sprite.flip_h=actor.facing<0
	sprite.scale=Vector2.ONE*(0.84 if not hero and index==2 else 0.80)
	sprite.rotation=0
	sprite.position=Vector2.ZERO
	sprite.modulate=Color.WHITE
	if actor.flash>0:
		sprite.modulate=Color(1.15,0.80,0.72)
	if hero and actor.invincible>0 and actor.flash<=0 and not echo_view:
		sprite.modulate.a=0.85+sin(game.time*42)*0.10
	if not actor.alive():
		var t=clampf(actor.dead_time/0.55,0,1)
		sprite.rotation=actor.facing*t*t*1.25
		sprite.position.y=t*30
		sprite.modulate.a*=1-t
	if echo_view:
		sprite.modulate=Color(0.55,0.80,0.77,0.45*minf(1.0,game.echo_time))
	queue_redraw()

func _draw() -> void:
	if actor == null or not visible:
		return
	var color = Color(0.25,0.22,0.17,0.08)
	var shadow_width = 37.0
	if echo_view:
		color = Color(0.20,0.50,0.48,0.08)
	var points = PackedVector2Array()
	for i in range(32):
		points.append(Vector2(cos(i * TAU / 32) * shadow_width, sin(i * TAU / 32) * 8 + 3))
	draw_colored_polygon(points, color)
	if actor.kind == "hero":
		if not echo_view:
			var accent: Color = game.HEROES[actor.hero].color
			draw_arc(Vector2(0,-183 if actor.hero==0 else -234),4,0,TAU,16,accent,1.0,true)
			if game.blocking:
				var angle = 0 if actor.facing > 0 else PI
				draw_arc(Vector2(actor.facing * 23, -60), 48, angle - 1.3, angle + 1.3, 24, Color(accent, 0.35), 2, true)
	else:
		if actor.alive():
			if actor.burn_time>0:
				for i in range(3):
					var phase=0.0 if game.reduced_motion else fposmod(actor.phase+i*1.7,3.0)
					var base=Vector2(-16+i*16,-16-phase*5)
					draw_polyline(PackedVector2Array([base+Vector2(-4,0),base+Vector2(0,-12),base+Vector2(4,0)]),Color("b94824"),2,true)
			if actor.slow_time>0:
				draw_arc(Vector2(0,0),30,0,TAU,24,Color("65618f"),2,true)
				for side in [-1,1]: draw_line(Vector2(side*30,-7),Vector2(side*30,7),Color("65618f"),3,true)
			var bar_y = -280.0 if actor.kind == "warden" or actor.archetype=="brute" else -250.0 if actor.kind=="caster" else -218.0 if actor.kind=="archer" else -212.0
			draw_rect(Rect2(-25, bar_y, 50, 3), Color("d6cbb9"))
			draw_rect(Rect2(-25, bar_y, 50.0 * actor.hp / actor.max_hp, 3), Color("9b5c60"))
			if actor.kind=="warden" and actor.state==game.Fighter.State.WINDUP:
				var charge=clampf(actor.action_elapsed/maxf(actor.action_length,0.01),0,1)
				for lane in range(3):
					if lane==actor.lane or actor.attack_variant==1 and absi(lane-actor.lane)<=1:
						var offset=game.LANES[lane]-actor.y
						var rect=Rect2(0 if actor.facing>0 else -160,offset-15,160,30)
						draw_rect(rect,Color(0.95,0.18,0.24,0.08+charge*0.16))
						draw_rect(rect,Color(1.0,0.40,0.40,0.65),false,1.5)
			if actor.kind=="caster" and (actor.state==game.Fighter.State.WINDUP or actor.action==&"attack" and actor.action_active() and actor.action_elapsed<0.25):
				var target=Vector2(actor.spell_target_x-actor.x,game.LANES[actor.spell_target_lane]-actor.y)
				var ring=PackedVector2Array()
				for i in range(49): ring.append(target+Vector2(cos(i*TAU/48)*110,sin(i*TAU/48)*18))
				draw_colored_polygon(ring,Color(0.5,0.25,0.65,0.18))
				draw_polyline(ring,Color("8c64a6"),2,true)
				draw_line(target+Vector2(-25,-8),target+Vector2(25,8),Color("8c64a6"),2,true)
				draw_line(target+Vector2(-25,8),target+Vector2(25,-8),Color("8c64a6"),2,true)
			if actor.archetype=="brute":
				draw_rect(Rect2(-7,bar_y-20,14,10),Color("ad7753"),false,2)
				if actor.state==game.Fighter.State.WINDUP:
					for lane in range(3):
						if absi(lane-actor.lane)<=1:
							var y=game.LANES[lane]-actor.y
							draw_rect(Rect2(0 if actor.facing>0 else -165,y-13,165,26),Color(0.7,0.3,0.2,0.13))
			if actor.archetype=="runner":
				for mark in range(2):
					var cx=-8+mark*12
					draw_polyline(PackedVector2Array([Vector2(cx-4,bar_y-18),Vector2(cx+3,bar_y-13),Vector2(cx-4,bar_y-8)]),Color("9c555e"),1.8,true)
			if actor.state == game.Fighter.State.WINDUP:
				draw_string(ThemeDB.fallback_font, Vector2(-4, bar_y - 8), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("a1493a"))
				var points2 = PackedVector2Array()
				for i in range(32):
					points2.append(Vector2(cos(i * TAU / 32) * 44, sin(i * TAU / 32) * 9 + 3))
				draw_colored_polygon(points2, Color(0.95, 0.2, 0.3, 0.12))

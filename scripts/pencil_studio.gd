extends Node2D
const Bank=preload("res://scripts/pencil_bank.gd")
const KEYS=["hero_0","hero_1","hero_2","enemy_0","enemy_1","enemy_2"]
const NAMES=["Tholgrin","Layla","Lupinor","Predone","Balestriere","Custode"]
const CLIPS=[&"idle",&"run",&"attack",&"attack_2",&"attack_3",&"ranged"]
var selected=1
var clip: StringName=&"attack"
var clock=0.0
var speed=1.0
var paused=false
var title_font: Font
func _ready() -> void:
	title_font=load("res://assets/fonts/title.ttf")
	for i in range(6):
		button(NAMES[i],Rect2(24+i*234,82,220,42),select.bind(i))
	for i in range(CLIPS.size()):
		button(["Guardia","Corsa","Attacco 1","Attacco 2","Attacco 3","Distanza"][i],Rect2(24+i*190,665,178,42),choose.bind(CLIPS[i]))
	button("Pausa / riprendi",Rect2(24,733,225,42),toggle_pause)
	button("Velocità 1× / ½×",Rect2(265,733,225,42),toggle_speed)
	button("← Fotogramma",Rect2(506,733,200,42),step.bind(-1))
	button("Fotogramma →",Rect2(722,733,200,42),step.bind(1))
	button("Torna al gioco · ESC",Rect2(1120,733,296,42),back)
func button(label: String,rect: Rect2,action: Callable) -> void:
	var node=Button.new()
	node.text=label
	node.position=rect.position
	node.size=rect.size
	node.add_theme_font_size_override("font_size",17)
	node.add_theme_color_override("font_color",Color("302b28"))
	node.add_theme_color_override("font_hover_color",Color("302b28"))
	node.add_theme_color_override("font_pressed_color",Color("302b28"))
	var style=StyleBoxFlat.new()
	style.bg_color=Color("eee5d3")
	style.border_color=Color("8d7b63")
	style.set_border_width_all(1)
	node.add_theme_stylebox_override("normal",style)
	var hover=style.duplicate()
	hover.bg_color=Color("dfd0b6")
	node.add_theme_stylebox_override("hover",hover)
	node.add_theme_stylebox_override("pressed",hover)
	node.pressed.connect(action)
	add_child(node)
func select(index: int) -> void:
	selected=index
	clock=0
func choose(value: StringName) -> void:
	clip=value
	clock=0
func toggle_pause() -> void:
	paused=not paused
func toggle_speed() -> void:
	speed=0.5 if speed==1 else 1.0
func step(direction: int) -> void:
	paused=true
	var frames=Bank.library(KEYS[selected])
	clock+=direction*Bank.length_of(frames,clip)/frames.get_frame_count(clip)
func back() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back()
func _process(dt: float) -> void:
	if not paused:
		clock+=dt*speed
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(0,0,1440,810),Color("f1e9d7"))
	if title_font==null:
		return
	draw_string(title_font,Vector2(24,49),"Taccuino delle animazioni",HORIZONTAL_ALIGNMENT_LEFT,-1,31,Color("302b28"))
	var frames=Bank.library(KEYS[selected])
	if frames==null:
		return
	var length=Bank.length_of(frames,clip)
	var time=fposmod(clock,length)
	var texture=Bank.texture(KEYS[selected],clip,time)
	draw_line(Vector2(280,607),Vector2(1160,607),Color("9e907c"),1,true)
	draw_texture_rect(texture,Rect2(720-256*1.2,607-400*1.2,512*1.2,416*1.2),false)
	var point=Bank.sample(frames,clip,time)
	draw_string(ThemeDB.fallback_font,Vector2(24,635),"%s · %s · fotogramma %d / %d · %.1f×" % [NAMES[selected],clip,int(point.x)+1,frames.get_frame_count(clip),speed],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("5e5548"))

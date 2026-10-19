extends Node2D
const Study = preload("res://scripts/layla_run_study.gd")
const LaylaSkin = preload("res://scripts/layla_run_skin.gd")
var figure: Node2D
var previous: Node2D
var elapsed: float = 0.0
var playing: bool = true
var playback: float = 1.0
var show_previous: bool = true
var phase_label: Label
var scrub: HSlider
var play_button: Button
var frame_label: Label
var syncing: bool = false
var selected_hero: int = 1
var character_label: Label

func label(text: String, at: Vector2, size: int, color: Color = Color("e6ddd2")) -> Label:
	var node = Label.new()
	node.text=text
	node.position=at
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	add_child(node)
	return node

func button(text: String, at: Vector2, action: Callable, width: float = 130.0) -> Button:
	var node = Button.new()
	node.text=text
	node.position=at
	node.size=Vector2(width,42)
	node.pressed.connect(action)
	add_child(node)
	return node

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("15242d"))
	label("CENERI & ECHI / STUDIO DELLA CORSA",Vector2(60,35),30)
	label("Confronta movimento e aspetto dei tre eroi",Vector2(62,79),18,Color("9aafb8"))
	button("1 · Tholgrin",Vector2(60,110),func(): select_hero(0),170)
	button("2 · Layla",Vector2(240,110),func(): select_hero(1),170)
	button("3 · Lupinor",Vector2(420,110),func(): select_hero(2),170)
	label("SAGOMA DEL MOVIMENTO",Vector2(225,169),18,Color("b1999b"))
	character_label=label("LAYLA / ASPETTO DEL PERSONAGGIO",Vector2(790,169),18,Color("beaddd"))
	previous=LaylaSkin.new()
	previous.monochrome=true
	previous.position=Vector2(38,211)
	previous.scale=Vector2.ONE*1.3
	add_child(previous)
	figure=LaylaSkin.new()
	figure.position=Vector2(650,211)
	figure.scale=Vector2.ONE*1.3
	add_child(figure)
	label("Stesse pose e stessa cadenza",Vector2(205,632),16,Color("9aafb8"))
	phase_label=label("",Vector2(810,632),18,Color("c8b9df"))
	play_button=button("Pausa",Vector2(60,694),toggle_play)
	button("−1 fotogramma",Vector2(200,694),func(): step(-1),160)
	button("+1 fotogramma",Vector2(370,694),func(): step(1),160)
	button("¼ velocità",Vector2(580,694),func(): playback=0.25)
	button("½ velocità",Vector2(720,694),func(): playback=0.5)
	button("Velocità reale",Vector2(860,694),func(): playback=1.0,150)
	button("Torna al gioco",Vector2(1180,694),func(): get_tree().change_scene_to_file("res://scenes/main.tscn"),190)
	scrub=HSlider.new()
	scrub.position=Vector2(60,760)
	scrub.size=Vector2(950,20)
	scrub.max_value=1.0
	scrub.step=0.001
	scrub.value_changed.connect(func(value):
		if not syncing:
			playing=false
			elapsed=value*figure.cycle_period
	)
	add_child(scrub)
	frame_label=label("",Vector2(1040,754),16,Color("9aafb8"))
	_sync()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--hero="):
			select_hero(clampi(argument.trim_prefix("--hero=").to_int(),0,2))

func toggle_play() -> void:
	playing=not playing

func select_hero(index: int) -> void:
	var old_phase=elapsed/figure.cycle_period
	selected_hero=index
	figure.configure(index)
	previous.configure(index)
	elapsed=old_phase*figure.cycle_period
	character_label.text=figure.PROFILES[index].name+" / ASPETTO DEL PERSONAGGIO"
	_sync()

func step(direction: int) -> void:
	playing=false
	elapsed=fposmod(elapsed+direction/24.0,figure.cycle_period)
	_sync()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	match event.keycode:
		KEY_SPACE: toggle_play()
		KEY_LEFT: step(-1)
		KEY_RIGHT: step(1)
		KEY_B: figure.bones=not figure.bones
		KEY_S: figure.monochrome=not figure.monochrome
		KEY_1: select_hero(0)
		KEY_2: select_hero(1)
		KEY_3: select_hero(2)
		KEY_ESCAPE: get_tree().change_scene_to_file("res://scenes/main.tscn")

func _process(dt: float) -> void:
	if playing:
		elapsed+=dt*playback
	_sync()

func _sync() -> void:
	if figure==null:
		return
	figure.phase=elapsed/figure.cycle_period
	previous.phase=figure.phase
	figure.queue_redraw()
	previous.queue_redraw()
	var p=fposmod(figure.phase,0.5)*2.0
	phase_label.text=["CONTATTO / PREPARAZIONE","ASSORBIMENTO DEL PESO","PASSAGGIO SOTTO IL BACINO","SPINTA / SOSPENSIONE"][int(p*4.0)]
	syncing=true
	scrub.value=fposmod(figure.phase,1.0)
	syncing=false
	play_button.text="Pausa" if playing else "Riprendi"
	frame_label.text="%.2f×  ·  B: ossa  ·  S: sagoma" % playback
	queue_redraw()

func _draw() -> void:
	for x in [85,700]:
		draw_line(Vector2(x,605),Vector2(x+560,605),Color("53616a"),1.5,true)
	# Fixed ground makes weight absorption and foot contact easy to inspect.
	for i in range(8):
		var x=710+i*70
		draw_line(Vector2(x,609),Vector2(x-8,617),Color("354852"),1.0,true)

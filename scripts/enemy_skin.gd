extends "res://scripts/hero_run_skin.gd"
## Painted enemy kits, animated from simulation time through every combat state.
const ENEMY_NAMES = ["raider", "archer", "warden"]
const SLOTS = ["head","torso","pelvis","upper_arm","forearm","weapon","thigh","shin","boot"]
const ENEMY_PROFILES = [
	{"leg":0.92,"torso":64.0,"width":1.0,"head":Vector2(36,47),"pelvis":Vector2(43,32),"boot":Vector2(31,21),"weapon":Vector2(102,35),"period":0.96,"stride":102.0},
	{"leg":0.88,"torso":61.0,"width":0.95,"head":Vector2(38,44),"pelvis":Vector2(40,32),"boot":Vector2(30,21),"weapon":Vector2(87,43),"period":1.0,"stride":108.0},
	{"leg":0.95,"torso":70.0,"width":1.28,"head":Vector2(39,52),"pelvis":Vector2(55,39),"boot":Vector2(39,25),"weapon":Vector2(128,65),"period":1.16,"stride":99.76}
]
var attack_style: int=0
var enemy_index: int=0
var clip: StringName=&"idle"
var progress: float=0.0
var motion_time: float=0.0
var weapon_angle: float=0.0
func configure(index: int) -> void:
	enemy_index=clampi(index,0,2)
	parts.clear()
	var cfg: Dictionary=ENEMY_PROFILES[enemy_index]
	cycle_period=cfg.period
	stride_length=cfg.stride
	for slot in SLOTS:
		var path="res://assets/%s_skin/%s.png" % [ENEMY_NAMES[enemy_index],slot]
		if ResourceLoader.exists(path):
			parts[slot]=load(path)
	queue_redraw()
func _ready() -> void:
	configure(enemy_index)
func enemy_pose() -> Dictionary:
	var cfg: Dictionary=ENEMY_PROFILES[enemy_index]
	var hip=Vector2(192,220)
	var legs: Array=[]
	var running=clip==&"run"
	for side in range(2):
		var p=phase+side*0.5
		var thigh_angle=sample([22.0,27.0,4.0,-18.0,-24.0,-12.0,18.0,37.0],p) if running else (14.0 if side==0 else -16.0)
		var shin_angle=sample([15.0,0.0,-10.0,-20.0,-57.0,-76.0,-50.0,8.0],p) if running else (3.0 if side==0 else -9.0)
		var socket=hip+Vector2(-5 if side==0 else 5,0)
		var knee=socket+direction(thigh_angle)*46.0*cfg.leg
		var ankle=knee+direction(shin_angle)*47.0*cfg.leg
		legs.append({"hip":socket,"knee":knee,"ankle":ankle,"foot":deg_to_rad(sample([-3.0,0.0,5.0,16.0,25.0,35.0,18.0,0.0],p)) if running else 0.0})
	var sole=-INF
	for leg: Dictionary in legs:
		sole=maxf(sole,leg.ankle.y+Vector2(12,cfg.boot.y*0.6).rotated(leg.foot).y)
	var shift=Vector2(0,FLOOR-sole)
	hip+=shift
	for leg: Dictionary in legs:
		for joint in ["hip","knee","ankle"]:
			leg[joint]+=shift
	var breath=sin(motion_time*2.8)*0.7 if not running else 0.0
	var lean=12.0 if running else 7.0
	if clip==&"hurt":
		lean=-12.0*sin(progress*PI)
	var shoulder=hip-direction(-lean)*cfg.torso+Vector2(0,breath)
	var neck=shoulder+Vector2(0,-5)
	var waist=hip+Vector2(0,-9)
	var arms: Array=[]
	weapon_angle=-0.25
	for side in range(2):
		var socket=mapped_point("torso",Vector2(0.18 if side==0 else 0.82,0.20),Vector2(0.5,0.10),Vector2(0.5,0.87),neck,waist,cfg.width)
		var upper_angle=12.0 if side==0 else -12.0
		var lower_angle=75.0 if side==0 else 58.0
		if running:
			upper_angle+=sample(ARM,phase+side*0.5)*0.20
		if enemy_index==1:
			upper_angle=28.0 if side==0 else 42.0
			lower_angle=88.0 if side==0 else 64.0
			weapon_angle=0.0
		if clip==&"windup":
			upper_angle=lerpf(upper_angle,-60.0,progress)
			lower_angle=lerpf(lower_angle,130.0,progress)
			weapon_angle=lerpf(weapon_angle,-1.25,progress)
		if enemy_index==1 and clip==&"windup":
			upper_angle=28.0 if side==0 else 42.0
			lower_angle=74.0 if side==0 else 64.0
		if clip==&"attack":
			# Contact matches arena events (.25/.54 melee, .24/.52 ranged).
			var impact=0.24/0.52 if enemy_index==1 else 0.25/0.54
			var strike=smoothstep(0.10,impact,progress)
			var recover=smoothstep(0.65,1.0,progress)
			upper_angle=lerpf(lerpf(-60.0,65.0,strike),12.0,recover)
			lower_angle=lerpf(lerpf(130.0,65.0,strike),75.0,recover)
			weapon_angle=lerpf(lerpf(-1.25,0.30,strike),-0.25,recover)
			if enemy_index==1:
				upper_angle=28.0
				lower_angle=74.0-8.0*sin(strike*PI)*(1.0-recover)
				weapon_angle=0.0
		if enemy_index==2 and attack_style==1 and clip==&"attack":
			lower_angle+=25.0*sin(progress*PI)
		var elbow=socket+direction(upper_angle)*29.0
		var hand=elbow+direction(lower_angle)*26.0
		arms.append({"shoulder":socket,"elbow":elbow,"hand":hand})
	return {"hip":hip,"neck":neck,"waist":waist,"legs":legs,"arms":arms}
func paint_arm(item: Dictionary,tint: Color) -> void:
	bound_piece("upper_arm",Vector2(0.50,0.15),Vector2(0.50,0.87),item.shoulder,item.elbow,tint)
	bound_piece("forearm",Vector2(0.50,0.13),Vector2(0.50,0.90),item.elbow,item.hand,tint)
func _draw() -> void:
	if parts.size()!=9:
		return
	var cfg: Dictionary=ENEMY_PROFILES[enemy_index]
	var data=enemy_pose()
	var far=Color(0.70,0.74,0.80)
	paint_arm(data.arms[1],far)
	for side in [1,0]:
		var leg: Dictionary=data.legs[side]
		var tint=far if side==1 else Color.WHITE
		bound_piece("thigh",Vector2(0.5,0.12),Vector2(0.5,0.88),leg.hip,leg.knee,tint,Rect2(0,0,1,1),cfg.width)
		bound_piece("shin",Vector2(0.5,0.12),Vector2(0.5,0.89),leg.knee,leg.ankle,tint,Rect2(0,0,1,1),cfg.width)
		anchored_piece("boot",Vector2(0.3,0.25),leg.ankle,cfg.boot,leg.foot,tint)
	bound_piece("torso",Vector2(0.5,0.10),Vector2(0.5,0.87),data.neck,data.waist,Color.WHITE,Rect2(0,0,1,1),cfg.width)
	anchored_piece("pelvis",Vector2(0.5,0.22),data.waist,cfg.pelvis)
	anchored_piece("head",Vector2(0.50,0.72),data.neck,cfg.head)
	paint_arm(data.arms[0],Color.WHITE)
	var wrists=[Vector2(0.05,0.69),Vector2(0.06,0.50),Vector2(0.04,0.36)]
	var knuckles=[Vector2(0.18,0.77),Vector2(0.27,0.62),Vector2(0.21,0.42)]
	var grip_axis=(knuckles[enemy_index]-wrists[enemy_index])*cfg.weapon
	var grip_angle=(data.arms[0].hand-data.arms[0].elbow).angle()-grip_axis.angle()
	anchored_piece("weapon",wrists[enemy_index],data.arms[0].hand,cfg.weapon,grip_angle)

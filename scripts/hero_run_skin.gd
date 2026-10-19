extends "res://scripts/layla_run_study.gd"
## Approved angular cycle, with explicit painted joint landmarks for each kit.
const PART_NAMES = ["head","torso","pelvis","ponytail","upper_arm","forearm","hand_blade","cape","thigh","shin","boot","scarf"]
const DWARF_THIGH = [20.0,30.0,0.0,-22.0,-24.0,-10.0,22.0,38.0]
const DWARF_SHIN = [20.0,-3.0,-12.0,-18.0,-65.0,-82.0,-62.0,5.0]
const DWARF_FOOT = [-4.0,0.0,5.0,18.0,27.0,35.0,18.0,0.0]
const BINDINGS = [
	{"neck":Vector2(0.59,0.10),"waist":Vector2(0.54,0.61),"chest_width":1.0,"shoulders":[Vector2(0.18,0.27),Vector2(0.88,0.24)],"head_anchor":Vector2(0.53,0.53),"head_size":Vector2(52,68),"pelvis_size":Vector2(62,45),"upper":[Vector2(0.64,0.23),Vector2(0.37,0.72)],"upper_clip":0.79,"upper_width":1.0,"forearm":[Vector2(0.55,0.13),Vector2(0.50,0.89)],"thigh":[Vector2(0.55,0.12),Vector2(0.53,0.80)],"leg_width":1.65,"shin":[Vector2(0.52,0.13),Vector2(0.50,0.88)]},
	{"neck":Vector2(0.44,0.06),"waist":Vector2(0.55,0.72),"chest_width":0.90,"shoulders":[Vector2(0.12,0.24),Vector2(0.84,0.22)],"head_anchor":Vector2(0.53,0.92),"head_size":Vector2(31,31),"pelvis_size":Vector2(42,30),"upper":[Vector2(0.52,0.18),Vector2(0.55,0.90)],"upper_clip":1.0,"upper_width":1.0,"forearm":[Vector2(0.50,0.11),Vector2(0.53,0.90)],"thigh":[Vector2(0.52,0.22),Vector2(0.52,0.86)],"leg_width":0.90,"shin":[Vector2(0.50,0.13),Vector2(0.50,0.91)]},
	{"neck":Vector2(0.58,0.09),"waist":Vector2(0.53,0.66),"chest_width":0.65,"shoulders":[Vector2(0.16,0.26),Vector2(0.86,0.25)],"head_anchor":Vector2(0.55,0.87),"head_size":Vector2(37,45),"pelvis_size":Vector2(43,31),"upper":[Vector2(0.60,0.22),Vector2(0.45,0.70)],"upper_clip":0.78,"upper_width":0.70,"forearm":[Vector2(0.51,0.12),Vector2(0.52,0.90)],"thigh":[Vector2(0.52,0.10),Vector2(0.51,0.86)],"leg_width":0.68,"shin":[Vector2(0.51,0.10),Vector2(0.52,0.88)]}
]
var action_clip: StringName = &"run"
var action_progress: float = 0.0
var animation_time: float = 0.0
var combo_step: int = 0
var parts: Dictionary = {}
var hero: int = 1
var cycle_period: float = 0.70
var stride_length: float = 231.0
const PROFILES = [
	{"folder":"tholgrin_skin","name":"THOLGRIN","period":0.76,"speed":240.0,"leg":0.68,"torso_scale":0.88,"arm_scale":0.85,"thigh":29.0,"shin":23.0,"upper_arm":22.0,"forearm":18.0,"torso":Vector2(56,73),"pelvis":Vector2(48,30),"head":Vector2(49,62),"hair":Vector2.ZERO,"cape":Vector2(78,59),"boot":Vector2(40,24),"main_hand":Vector2(62,32)},
	{"folder":"layla_skin","name":"LAYLA","period":0.70,"speed":330.0,"leg":1.0,"torso_scale":1.0,"arm_scale":1.0,"thigh":20.0,"shin":15.0,"upper_arm":13.0,"forearm":11.0,"torso":Vector2(36,78),"pelvis":Vector2(32,25),"head":Vector2(37,45),"hair":Vector2(47,16),"cape":Vector2(59,42),"boot":Vector2(27,18),"main_hand":Vector2(40,16)},
	{"folder":"lupinor_skin","name":"LUPINOR","period":0.82,"speed":285.0,"leg":1.04,"torso_scale":1.04,"arm_scale":1.04,"thigh":20.0,"shin":16.0,"upper_arm":15.0,"forearm":13.0,"torso":Vector2(40,81),"pelvis":Vector2(34,26),"head":Vector2(37,45),"hair":Vector2(68,24),"cape":Vector2(74,57),"boot":Vector2(28,19),"main_hand":Vector2(80,29)}
]

func _ready() -> void:
	configure(hero)

func configure(index: int) -> void:
	hero=clampi(index,0,2)
	parts.clear()
	cycle_period=PROFILES[hero].period
	stride_length=cycle_period*PROFILES[hero].speed
	for part in PART_NAMES:
		var file_name: String=part
		if hero==0:
			file_name={"ponytail":"shield","hand_blade":"mace_hand","scarf":"shield_hand"}.get(part,part)
		elif hero==2:
			file_name={"ponytail":"hair","hand_blade":"scimitar_hand","scarf":"crossbow_hand"}.get(part,part)
		var path="res://assets/%s/%s.png" % [PROFILES[hero].folder,file_name]
		if ResourceLoader.exists(path):
			parts[part]=load(path)
	queue_redraw()

func profile_pose(cycle: float) -> Dictionary:
	var data=pose(cycle)
	if hero==1:
		return bind_pose(data)
	var cfg: Dictionary=PROFILES[hero]
	var original_hip: Vector2=data.hip
	var original_shoulder: Vector2=data.shoulder
	var floor_origin=Vector2(192,FLOOR)
	var boot_offset: float=cfg.boot.y-7.0-9.0*cfg.leg
	var target_floor=floor_origin-Vector2(0,boot_offset)
	data.hip=target_floor+(original_hip-floor_origin)*cfg.leg
	data.shoulder=data.hip+(original_shoulder-original_hip)*cfg.torso_scale
	data.neck=data.shoulder+Vector2(3,-9)
	data.head=data.neck+Vector2(5,-14)
	for leg: Dictionary in data.legs:
		for joint in ["hip","knee","ankle"]:
			leg[joint]=target_floor+(leg[joint]-floor_origin)*cfg.leg
	if hero==0:
		# Armoured dwarf: compact recovery, broad boots, no pointed ballet toes.
		var lowest_sole=-INF
		for side in range(2):
			var leg: Dictionary=data.legs[side]
			var p=cycle+side*0.5
			leg.hip=data.hip
			leg.knee=leg.hip+direction(sample(DWARF_THIGH,p))*46.0*cfg.leg
			leg.ankle=leg.knee+direction(sample(DWARF_SHIN,p))*47.0*cfg.leg
			leg.foot=deg_to_rad(sample(DWARF_FOOT,p))
			var sole=leg.ankle.y+Vector2(16,14).rotated(leg.foot).y
			lowest_sole=maxf(lowest_sole,sole)
		# Move the complete skeleton to the supporting sole, preserving bone lengths.
		var shift=Vector2(0,FLOOR-lowest_sole)
		for joint in ["hip","shoulder","neck","head"]:
			data[joint]+=shift
		for leg: Dictionary in data.legs:
			for joint in ["hip","knee","ankle"]:
				leg[joint]+=shift
	for side in range(2):
		var arm_data: Dictionary=data.arms[side]
		var p=cycle+side*0.5
		var swing=0.35 if hero==0 else 0.65
		arm_data.shoulder=data.shoulder+Vector2((-8 if side==0 else 8) if hero==0 else 0,0)
		arm_data.elbow=arm_data.shoulder+direction(sample(ARM,p)*swing)*30.0*cfg.arm_scale
		var forearm_angle=65.0+sample(FOREARM,p)*0.20 if hero==0 else 40.0+sample(FOREARM,p)*0.35
		if side==1:
			forearm_angle=85.0
		arm_data.hand=arm_data.elbow+direction(forearm_angle)*27.0*cfg.arm_scale
	return bind_pose(data)

func combat_pose() -> Dictionary:
	if hero==1 and action_clip in [&"idle",&"attack"]:
		return layla_dual_pose()
	if action_clip==&"run":
		return profile_pose(phase)
	var cfg: Dictionary=PROFILES[hero]
	var binding: Dictionary=BINDINGS[hero]
	var data=profile_pose(0.12)
	var hip: Vector2=data.hip
	var lowest=-INF
	for side in range(2):
		var leg: Dictionary=data.legs[side]
		leg.hip=hip+Vector2((-7 if side==0 else 7) if hero==0 else (-3 if side==0 else 3),0)
		leg.knee=leg.hip+direction(18.0 if side==0 else -22.0)*46.0*cfg.leg
		leg.ankle=leg.knee+direction(-2.0 if side==0 else -9.0)*47.0*cfg.leg
		leg.foot=0.0
		lowest=maxf(lowest,leg.ankle.y+cfg.boot.y*0.60)
	var shift=Vector2(0,FLOOR-lowest)
	for joint in ["hip","shoulder","neck","head","waist"]:
		data[joint]+=shift
	for leg: Dictionary in data.legs:
		for joint in ["hip","knee","ankle"]:
			leg[joint]+=shift
	var t=clampf(action_progress,0,1)
	var impact=[0.34,0.24,0.34][hero]
	var strike=smoothstep(maxf(0.0,impact-0.13),impact,t)
	var recover=smoothstep(0.57,1.0,t)
	var attack_action=action_clip==&"attack"
	var lean=10.0
	if attack_action:
		lean+=sin(t*PI)*([6.0,12.0,9.0][hero])
	elif action_clip==&"dodge":
		lean+=sin(t*PI)*25.0
	elif action_clip==&"hurt":
		lean=-12.0*sin(t*PI)
	data.lean=lean
	data.shoulder=data.hip-direction(-lean)*65.0*cfg.torso_scale
	data.neck=data.shoulder+Vector2(3,-9+sin(animation_time*3.0)*0.5)
	data.head=data.neck+Vector2(5,-14)
	for side in range(2):
		var arm_data: Dictionary=data.arms[side]
		arm_data.shoulder=mapped_point("torso",binding.shoulders[side],binding.neck,binding.waist,data.neck,data.waist,binding.chest_width)
		var upper=10.0 if side==0 else -5.0
		var lower=85.0 if side==0 else 60.0
		if attack_action and (side==0 or hero==1):
			var style=posmod(combo_step+(side if hero==1 else 0),3)
			var prepare=smoothstep(0.0,maxf(0.04,impact-0.13),t)
			var wind_upper=lerpf(upper,[-50.0,30.0,-95.0][style],prepare)
			var wind_lower=lerpf(lower,[140.0,35.0,155.0][style],prepare)
			var hit_upper=[65.0,82.0,60.0][style]
			var hit_lower=[62.0,120.0,42.0][style]
			upper=lerpf(lerpf(wind_upper,hit_upper,strike),upper,recover)
			lower=lerpf(lerpf(wind_lower,hit_lower,strike),lower,recover)
		elif action_clip==&"special":
			upper=lerpf(10.0,-45.0,sin(t*PI))
			lower=lerpf(85.0,145.0,sin(t*PI))
		elif action_clip==&"ranged":
			upper=35.0
			lower=92.0+sin(t*PI)*8.0
		elif action_clip==&"guard" and side==1:
			upper=45.0
			lower=115.0
		elif action_clip==&"dodge":
			upper=-35.0
			lower=55.0
		arm_data.elbow=arm_data.shoulder+direction(upper)*30.0*cfg.arm_scale
		arm_data.hand=arm_data.elbow+direction(lower)*27.0*cfg.arm_scale
	return data

static func hinge_joint(root: Vector2, tip: Vector2, first: float, second: float, bend: float=1.0) -> Vector2:
	var delta=tip-root
	var distance=clampf(delta.length(),absf(first-second)+0.01,first+second-0.01)
	var axis=delta.normalized()
	var along=(first*first-second*second+distance*distance)/(2.0*distance)
	var height=sqrt(maxf(0.0,first*first-along*along))
	return root+axis*along+Vector2(-axis.y,axis.x)*height*bend

static func action_key(keys: Array, t: float) -> Vector2:
	var times=[0.0,0.11,0.24,0.43,0.72,1.0]
	for i in range(times.size()-1):
		if t<=times[i+1]:
			return keys[i].lerp(keys[i+1],smoothstep(times[i],times[i+1],t))
	return keys[-1]

func layla_dual_pose() -> Dictionary:
	# Each strike has ONE leading blade. The second hand stays in a compact guard.
	# Both feet remain planted; pelvis and knees carry the weight transfer.
	var attacking=action_clip==&"attack"
	var t=clampf(action_progress,0,1) if attacking else 0.0
	var stage=posmod(combo_step,3) if attacking else 0
	var drive=action_key([Vector2.ZERO,Vector2(-3,2),Vector2(14,6),Vector2(12,5),Vector2(4,2),Vector2.ZERO],t)
	var hip=Vector2(192,205)+drive
	var lean=10.0+drive.x*0.55
	var shoulder=hip-direction(-lean)*65.0
	var neck=shoulder+Vector2(3,-9)
	var waist=hip+Vector2(0,-14)
	var legs: Array=[]
	for side in range(2):
		var socket=layla_hip_socket(waist,side)
		var ankle=Vector2(218 if side==0 else 172,FLOOR-10.8)
		var knee=hinge_joint(socket,ankle,46.0,47.0,-1.0)
		legs.append({"hip":socket,"knee":knee,"ankle":ankle,"foot":0.0})
	var guard_near=Vector2(27,27)
	var guard_far=Vector2(27,18)
	var near=guard_near
	var far=guard_far
	if attacking:
		match stage:
			0:
				near=action_key([guard_near,Vector2(13,26),Vector2(56,-3),Vector2(50,-2),Vector2(32,17),guard_near],t)
				far=action_key([guard_far,Vector2(24,16),Vector2(23,20),Vector2(24,19),guard_far,guard_far],t)
			1:
				far=action_key([guard_far,Vector2(14,6),Vector2(53,-15),Vector2(48,-8),Vector2(31,13),guard_far],t)
				near=action_key([guard_near,Vector2(24,29),Vector2(21,32),Vector2(23,31),guard_near,guard_near],t)
			2:
				near=action_key([guard_near,Vector2(12,-23),Vector2(52,12),Vector2(44,23),Vector2(29,24),guard_near],t)
				far=action_key([guard_far,Vector2(12,27),Vector2(8,33),Vector2(11,30),guard_far,guard_far],t)
	var arms: Array=[]
	var binding: Dictionary=BINDINGS[1]
	for side in range(2):
		var socket=mapped_point("torso",binding.shoulders[side],binding.neck,binding.waist,neck,waist,binding.chest_width)
		var hand=socket+(near if side==0 else far)
		var elbow=hinge_joint(socket,hand,30.0,27.0)
		arms.append({"shoulder":socket,"elbow":elbow,"hand":hand})
	return {"hip":hip,"shoulder":shoulder,"neck":neck,"head":neck+Vector2(5,-14),"waist":waist,"lean":lean,"legs":legs,"arms":arms}

func draw_grip(item: Dictionary,tint: Color=Color.WHITE) -> void:
	var cfg: Dictionary=PROFILES[hero]
	var wrist=[Vector2(0.10,0.24),Vector2(0.06,0.48),Vector2(0.08,0.30)][hero]
	var knuckle=[Vector2(0.23,0.53),Vector2(0.26,0.50),Vector2(0.18,0.38)][hero]
	var size=Vector2(70,30) if hero==0 else cfg.main_hand
	var axis=(knuckle-wrist)*size
	var angle=(item.hand-item.elbow).angle()-axis.angle()
	anchored_piece("hand_blade",wrist,item.hand,size,angle,tint)

func layla_hip_socket(waist: Vector2, side: int) -> Vector2:
	var socket_uv=Vector2(0.78 if side==0 else 0.23,0.82)
	return waist+(socket_uv-Vector2(0.50,0.23))*BINDINGS[1].pelvis_size

func bind_pose(data: Dictionary) -> Dictionary:
	if not parts.has("torso"):
		return data
	var binding: Dictionary=BINDINGS[hero]
	var collar: Vector2=data.neck
	var waist: Vector2=data.hip+Vector2(0,-14 if hero==1 else -10)
	for side in range(2):
		var socket=mapped_point("torso",binding.shoulders[side],binding.neck,binding.waist,collar,waist,binding.chest_width)
		var shift=socket-data.arms[side].shoulder
		for joint in ["shoulder","elbow","hand"]:
			data.arms[side][joint]+=shift
		var leg_shift=layla_hip_socket(waist,side)-data.legs[side].hip if hero==1 else Vector2((-7 if side==0 else 7) if hero==0 else (-3 if side==0 else 3),0)
		for joint in ["hip","knee","ankle"]:
			data.legs[side][joint]+=leg_shift
	data["waist"]=waist
	return data

func image(part: String, rect: Rect2, tint: Color=Color.WHITE) -> void:
	if parts.has(part):
		draw_texture_rect(parts[part],rect,false,tint)

func mapped_point(part: String, point: Vector2, source_a: Vector2, source_b: Vector2, target_a: Vector2, target_b: Vector2, width_scale: float=1.0) -> Vector2:
	var size: Vector2=parts[part].get_size()
	var source=(source_b-source_a)*size
	var target=target_b-target_a
	var local=(point-source_a)*size
	var source_axis=source.normalized()
	var source_side=Vector2(-source_axis.y,source_axis.x)
	var target_axis=target.normalized()
	var target_side=Vector2(-target_axis.y,target_axis.x)
	var scale_factor=target.length()/source.length()
	return target_a+target_axis*local.dot(source_axis)*scale_factor+target_side*local.dot(source_side)*scale_factor*width_scale

func bound_piece(part: String, source_a: Vector2, source_b: Vector2, target_a: Vector2, target_b: Vector2, tint: Color=Color.WHITE, region: Rect2=Rect2(0,0,1,1), width_scale: float=1.0) -> void:
	var uvs=PackedVector2Array([region.position,region.position+Vector2(region.size.x,0),region.end,region.position+Vector2(0,region.size.y)])
	var vertices=PackedVector2Array()
	for uv in uvs:
		vertices.append(mapped_point(part,uv,source_a,source_b,target_a,target_b,width_scale))
	draw_polygon(vertices,PackedColorArray([tint]),uvs,parts[part])

func anchored_piece(part: String, anchor: Vector2, target: Vector2, size: Vector2, angle: float=0.0, tint: Color=Color.WHITE) -> void:
	draw_set_transform(target,angle)
	image(part,Rect2(-anchor*size,size),tint)
	draw_set_transform(Vector2.ZERO)

func bound_arm(item: Dictionary,tint: Color) -> void:
	# Shoulder-to-elbow artwork is diagonal and extends past the elbow.
	# Its wrist section is excluded instead of being drawn as another joint.
	var binding: Dictionary=BINDINGS[hero]
	bound_piece("upper_arm",binding.upper[0],binding.upper[1],item.shoulder,item.elbow,tint,Rect2(0,0,1,binding.upper_clip),binding.upper_width)
	bound_piece("forearm",binding.forearm[0],binding.forearm[1],item.elbow,item.hand,tint)

func draw_bound_character(data: Dictionary) -> void:
	var cfg: Dictionary=PROFILES[hero]
	var binding: Dictionary=BINDINGS[hero]
	var far=Color(0.72,0.74,0.80)
	var collar: Vector2=data.neck
	var waist: Vector2=data.waist
	var neck_uv: Vector2=binding.neck
	var waist_uv: Vector2=binding.waist
	var arms: Array=data.arms
	anchored_piece("cape",Vector2(0.95,0.15),arms[0].shoulder,cfg.cape,sin((phase-0.1)*TAU*2)*0.025)
	bound_arm(arms[1],far)
	if hero==1:
		anchored_piece("pelvis",Vector2(0.50,0.23),waist,binding.pelvis_size)
	for side in [1,0]:
		var leg: Dictionary=data.legs[side]
		var hip: Vector2=leg.hip
		var knee: Vector2=leg.knee
		var ankle: Vector2=leg.ankle
		var tint=far if side==1 else Color.WHITE
		bound_piece("thigh",binding.thigh[0],binding.thigh[1],hip,knee,tint,Rect2(0,0.17,1,0.83) if hero==1 else Rect2(0,0,1,1),binding.leg_width)
		bound_piece("shin",binding.shin[0],binding.shin[1],knee,ankle,tint,Rect2(0,0,1,1),binding.leg_width)
		anchored_piece("boot",Vector2(0.30,0.25),ankle,cfg.boot,leg.foot,tint)
	# Only the chest is drawn; the source's duplicated belt/tassets are clipped.
	bound_piece("torso",neck_uv,waist_uv,collar,waist,Color.WHITE,Rect2(0,0,1,binding.waist.y+0.06),binding.chest_width)
	if hero!=1:
		anchored_piece("pelvis",Vector2(0.50,0.23),waist,binding.pelvis_size,(data.hip-data.shoulder).angle()-PI*0.5)
	# A beard is not a neck anchor. Bind the hidden neck under the jaw to collar.
	if hero!=0:
		anchored_piece("ponytail",Vector2(0.95,0.3),collar+(Vector2(-10,-22) if hero==1 else Vector2(-9,-25)),cfg.hair,sin((phase-0.12)*TAU*2)*0.045)
	anchored_piece("head",binding.head_anchor,collar,binding.head_size,deg_to_rad(data.lean*0.15))
	if hero==0:
		anchored_piece("scarf",Vector2(0.45,0.35),arms[1].hand,Vector2(20,18),0,far)
		anchored_piece("ponytail",Vector2(0.45,0.50),arms[1].hand,Vector2(46,64),0,far)
	elif hero==2:
		anchored_piece("scarf",Vector2(0.30,0.52),arms[1].hand,Vector2(39,24),0,far)
	else:
		if action_clip!=&"run":
			draw_grip(arms[1],far)
		else:
			anchored_piece("hand_blade",Vector2(0.2,0.5),arms[1].hand,cfg.main_hand,0,far)
	bound_arm(arms[0],Color.WHITE)
	if action_clip!=&"run":
		draw_grip(arms[0])
	elif hero==0:
		# The source wrist is above/behind the fist, not at its centre.
		# Continue the forearm through that painted wrist into the knuckles.
		var wrist_uv=Vector2(0.10,0.24)
		var knuckle_uv=Vector2(0.23,0.53)
		var hand_size=Vector2(70,30)
		var grip_axis=(knuckle_uv-wrist_uv)*hand_size
		var wrist_angle=(arms[0].hand-arms[0].elbow).angle()-grip_axis.angle()
		anchored_piece("hand_blade",wrist_uv,arms[0].hand,hand_size,wrist_angle)
	else:
		anchored_piece("hand_blade",Vector2(0.22,0.53),arms[0].hand,cfg.main_hand)
	if bones:
		for arm_data: Dictionary in arms:
			draw_polyline(PackedVector2Array([arm_data.shoulder,arm_data.elbow,arm_data.hand]),Color.CYAN,1.4,true)

func profile_silhouette(data: Dictionary) -> void:
	var cfg: Dictionary=PROFILES[hero]
	var color=Color("e9e0d2")
	for side in [1,0]:
		var leg: Dictionary=data.legs[side]
		limb(leg.hip,leg.knee,cfg.thigh*0.8,color)
		limb(leg.knee,leg.ankle,cfg.shin*0.8,color)
		boot(leg,color)
		arm(data.arms[side],color)
	limb(data.hip,data.shoulder,cfg.torso.x*0.7,color)
	limb(data.shoulder,data.neck,9,color)
	draw_circle(data.head,cfg.head.x*0.37,color)

func _draw() -> void:
	var data=combat_pose()
	if parts.size()<11 or monochrome:
		if hero==1:
			super._draw()
		else:
			profile_silhouette(data)
		return
	draw_bound_character(data)

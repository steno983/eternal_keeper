extends Node2D
## Pose-authored full-body blocking. Angles are degrees from the downward axis.
## Contact, absorption, passing and push-off were blocked before interpolation.
const PERIOD = 0.70
const STRIDE = 231.0
const FLOOR = 303.0
const THIGH = [25.0,40.0,-5.0,-25.0,-30.0,-10.0,35.0,60.0]
const SHIN = [25.0,-5.0,-15.0,-15.0,-90.0,-115.0,-100.0,5.0]
const FOOT = [-10.0,0.0,10.0,42.0,65.0,95.0,60.0,5.0]
const HIP_Y = [206.0,212.0,200.5,198.0,206.0,212.0,200.5,198.0]
const LEAN = [12.0,17.0,20.0,13.0,12.0,17.0,20.0,13.0]
const ARM = [-45.0,-25.0,0.0,35.0,45.0,25.0,0.0,-35.0]
const FOREARM = [0.0,20.0,50.0,100.0,120.0,110.0,80.0,25.0]
var phase: float = 0.0
var bones: bool = false
var monochrome: bool = false

static func sample(keys: Array, cycle: float) -> float:
	var cursor = fposmod(cycle,1.0)*8.0
	var i = int(cursor)
	return interpolate_key(float(keys[posmod(i-1,8)]),float(keys[i]),float(keys[(i+1)%8]),float(keys[(i+2)%8]),cursor-i)

static func interpolate_key(before: float, current: float, after: float, next: float, t: float) -> float:
	return 0.5*((2.0*current)+(-before+after)*t+(2.0*before-5.0*current+4.0*after-next)*t*t+(-before+3.0*current-3.0*after+next)*t*t*t)

static func direction(angle: float) -> Vector2:
	return Vector2(sin(deg_to_rad(angle)),cos(deg_to_rad(angle)))

static func pose(cycle: float) -> Dictionary:
	var hip = Vector2(192.0,sample(HIP_Y,cycle))
	var legs: Array = []
	for side in range(2):
		var p = cycle+side*0.5
		var knee = hip+direction(sample(THIGH,p))*46.0
		var ankle = knee+direction(sample(SHIN,p))*47.0
		legs.append({"hip":hip,"knee":knee,"ankle":ankle,"foot":deg_to_rad(sample(FOOT,p))})
	# Keep the supporting sole on the floor through weight absorption/passing.
	# Small vertical correction moves the WHOLE body, never stretches a limb.
	for side in range(2):
		var p = fposmod(cycle+side*0.5,1.0)
		var weight = smoothstep(0.07,0.12,p)*(1.0-smoothstep(0.28,0.34,p))
		if weight>0.0:
			var leg: Dictionary = legs[side]
			var sole = leg.ankle.y+Vector2(15,9).rotated(leg.foot).y
			var shift = Vector2(0,(FLOOR-sole)*weight)
			hip += shift
			for item: Dictionary in legs:
				for joint in ["hip","knee","ankle"]:
					item[joint] += shift
	var lean = sample(LEAN,cycle)
	var shoulder = hip-direction(-lean)*65.0
	var neck = shoulder+Vector2(3,-9)
	var arms: Array = []
	for side in range(2):
		var p = cycle+side*0.5
		var elbow = shoulder+direction(sample(ARM,p))*30.0
		var hand = elbow+direction(sample(FOREARM,p))*27.0
		arms.append({"shoulder":shoulder,"elbow":elbow,"hand":hand})
	return {"hip":hip,"shoulder":shoulder,"neck":neck,"head":neck+Vector2(5,-14),"legs":legs,"arms":arms,"lean":lean}

func limb(a: Vector2,b: Vector2,width: float,color: Color) -> void:
	draw_line(a,b,color,width,true)
	draw_circle(a,width*0.5,color)
	draw_circle(b,width*0.5,color)

func boot(leg: Dictionary, color: Color) -> void:
	var points = PackedVector2Array()
	for point in [Vector2(-6,-5),Vector2(4,-5),Vector2(5,1),Vector2(17,5),Vector2(18,8),Vector2(14,10),Vector2(-7,8)]:
		points.append(leg.ankle+point.rotated(leg.foot))
	draw_colored_polygon(points,color)

func arm(item: Dictionary,color: Color) -> void:
	limb(item.shoulder,item.elbow,9.0,color)
	limb(item.elbow,item.hand,7.5,color)
	var blade = PackedVector2Array([item.hand+Vector2(2,-3),item.hand+Vector2(22,-11),item.hand+Vector2(11,0),item.hand+Vector2(3,3)])
	draw_colored_polygon(blade,Color("bd9ce8") if not monochrome else color)

func _draw() -> void:
	var data = pose(phase)
	var near = Color("e9e0d2")
	var far = Color("877a9c") if not monochrome else near
	var hip: Vector2 = data.hip
	var shoulder: Vector2 = data.shoulder
	arm(data.arms[1],far)
	for side in [1,0]:
		var leg: Dictionary = data.legs[side]
		var color = far if side==1 else near
		limb(leg.hip,leg.knee,15.0,color)
		limb(leg.knee,leg.ankle,10.5,color)
		boot(leg,color)
	# Torso, pelvis and neck are part of the motion, not a stationary cutout.
	var axis = (shoulder-hip).normalized()
	var across = Vector2(-axis.y,axis.x)
	var torso = PackedVector2Array([hip-across*10,hip+axis*23-across*9,shoulder-across*15,shoulder+across*13,hip+axis*23+across*10,hip+across*12])
	draw_colored_polygon(torso,near)
	limb(hip-across*5,hip+across*5,19,near)
	limb(shoulder,data.neck,9,near)
	var head: Vector2 = data.head
	var face = PackedVector2Array()
	for point in [Vector2(-9,-13),Vector2(6,-15),Vector2(12,-8),Vector2(12,-3),Vector2(17,1),Vector2(11,3),Vector2(10,11),Vector2(1,14),Vector2(-8,9),Vector2(-12,-2)]:
		face.append(head+point.rotated(deg_to_rad(data.lean*0.2)))
	draw_colored_polygon(face,near)
	# A delayed ponytail makes head motion readable without hiding the hips.
	var tie = head+Vector2(-9,-9)
	var tail = PackedVector2Array([tie,tie+Vector2(-20,-4),tie+Vector2(-43,2+sin((phase-0.12)*TAU*2)*3),tie+Vector2(-55,12),tie+Vector2(-31,10),tie+Vector2(-10,3)])
	draw_colored_polygon(tail,near)
	arm(data.arms[0],near)
	if bones:
		for side in range(2):
			var leg: Dictionary = data.legs[side]
			draw_polyline(PackedVector2Array([leg.hip,leg.knee,leg.ankle]),Color.CYAN if side==0 else Color.MAGENTA,1.5,true)
			var item: Dictionary = data.arms[side]
			draw_polyline(PackedVector2Array([item.shoulder,item.elbow,item.hand]),Color("e69663"),1.5,true)
		draw_line(hip,shoulder,Color("e69663"),1.5,true)

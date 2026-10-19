extends Node2D
## Native textured cutout animation. Both legs follow the same closed gait,
## exactly half a cycle apart; camera depth is fixed, anatomical identity is not.
const CONFIG = [
	{"hip": Vector2(204, 239), "knee": Vector2(151, 265), "ankle": Vector2(120, 291),
	"upper": [Vector2(177,235),Vector2(214,242),Vector2(174,267),Vector2(150,279),Vector2(132,266),Vector2(139,252)],
	"lower": [Vector2(139,253),Vector2(170,271),Vector2(139,284),Vector2(143,296),Vector2(130,305),Vector2(110,305),Vector2(107,289),Vector2(113,275)],
	"body": [Vector2(0,0),Vector2(384,0),Vector2(384,244),Vector2(250,244),Vector2(225,233),Vector2(215,263),Vector2(197,287),Vector2(178,290),Vector2(164,280),Vector2(169,241),Vector2(145,237),Vector2(122,248),Vector2(108,260),Vector2(0,267)],
	"weapon": [], "lengths": Vector2(40,43), "reach": 37.0},
	{"hip": Vector2(199,214), "knee": Vector2(173,244), "ankle": Vector2(134,284),
	"upper": [Vector2(185,202),Vector2(212,209),Vector2(208,222),Vector2(189,248),Vector2(171,257),Vector2(155,246),Vector2(168,227)],
	"lower": [Vector2(159,236),Vector2(186,249),Vector2(163,273),Vector2(146,285),Vector2(149,295),Vector2(156,299),Vector2(149,306),Vector2(125,306),Vector2(116,296),Vector2(121,280),Vector2(141,257)],
	"body": [Vector2(0,0),Vector2(384,0),Vector2(384,200),Vector2(254,200),Vector2(242,197),Vector2(226,196),Vector2(210,200),Vector2(192,205),Vector2(183,220),Vector2(156,237),Vector2(0,250)],
	"weapon": [Vector2(247,193),Vector2(268,213),Vector2(305,235),Vector2(296,245),Vector2(268,230),Vector2(246,213)],
	"lengths": Vector2(44,53), "reach": 45.0},
	{"hip": Vector2(246,254), "knee": Vector2(246,276), "ankle": Vector2(248,284),
	"upper": [Vector2(236,253),Vector2(254,253),Vector2(257,270),Vector2(254,279),Vector2(239,279),Vector2(235,265)],
	"lower": [Vector2(235,247),Vector2(253,245),Vector2(255,276),Vector2(268,280),Vector2(278,285),Vector2(280,295),Vector2(262,301),Vector2(242,300),Vector2(235,289),Vector2(237,275)],
	"body": [Vector2(0,0),Vector2(384,0),Vector2(384,194),Vector2(260,194),Vector2(242,194),Vector2(223,191),Vector2(203,196),Vector2(184,213),Vector2(163,225),Vector2(150,221),Vector2(142,228),Vector2(130,220),Vector2(111,231),Vector2(0,240)],
	"weapon": [Vector2(141,191),Vector2(156,190),Vector2(186,211),Vector2(224,229),Vector2(263,237),Vector2(266,246),Vector2(227,246),Vector2(190,231),Vector2(158,211)],
	"lengths": Vector2(51,60), "reach": 43.5}
]
var hero: int = 0
var phase: float = 0.0
var texture: Texture2D
var debug_bones: bool = false

func configure(index: int) -> void:
	hero = index
	texture = load("res://assets/animation_v2/hero_%d-atlas.png" % hero)

static func foot_at(cycle: float, reach: float) -> Vector2:
	var p = fposmod(cycle, 1.0)
	# Shorter stance than half a cycle gives two genuine airborne intervals.
	if p < 0.4:
		return Vector2(lerpf(reach, -reach, p / 0.4), 294.0)
	var swing = (p - 0.4) / 0.6
	return Vector2(lerpf(-reach, reach, swing), 294.0 - sin(swing * PI) * 48.0)

static func knee_at(hip: Vector2, foot: Vector2, lengths: Vector2) -> Vector2:
	var delta = foot - hip
	var distance = clampf(delta.length(), 0.01, lengths.x + lengths.y - 0.01)
	var axis = delta.normalized()
	var along = (lengths.x * lengths.x - lengths.y * lengths.y + distance * distance) / (2.0 * distance)
	var height = sqrt(maxf(0.0, lengths.x * lengths.x - along * along))
	return hip + axis * along + Vector2(axis.y, -axis.x) * height

func piece(points: Array, from: Vector2, to: Vector2, rest_from: Vector2, rest_to: Vector2, tint: Color) -> void:
	var rest = rest_to - rest_from
	var target = to - from
	var ratio = target.length() / rest.length()
	var rest_axis = rest.normalized()
	var rest_side = Vector2(-rest_axis.y, rest_axis.x)
	var target_axis = target.normalized()
	var target_side = Vector2(-target_axis.y, target_axis.x)
	var vertices = PackedVector2Array()
	var uvs = PackedVector2Array()
	for point: Vector2 in points:
		var local = point - rest_from
		vertices.append(from + target_axis * local.dot(rest_axis) * ratio + target_side * local.dot(rest_side))
		uvs.append((point + Vector2(0,320)) / Vector2(texture.get_size()))
	draw_polygon(vertices, PackedColorArray([tint]), uvs, texture)

func patch(points: Array, offset: Vector2) -> void:
	if points.is_empty():
		return
	var vertices = PackedVector2Array()
	var uvs = PackedVector2Array()
	for point: Vector2 in points:
		vertices.append(point + offset)
		uvs.append((point + Vector2(0,320)) / Vector2(texture.get_size()))
	draw_polygon(vertices, PackedColorArray([Color.WHITE]), uvs, texture)

func _draw() -> void:
	if texture == null:
		return
	var cfg: Dictionary = CONFIG[hero]
	var bob = Vector2(0, -2.5 * cos(phase * TAU * 2.0))
	var hip: Vector2 = (Vector2(198,209) if hero == 2 else cfg.hip) + bob
	for side in [1,0]:
		var foot = foot_at(phase + side * 0.5, cfg.reach)
		foot.x += hip.x
		var knee = knee_at(hip, foot, cfg.lengths)
		var tint = Color(0.66,0.70,0.76) if side == 1 else Color.WHITE
		var rest_knee: Vector2 = Vector2(244,250) if hero == 2 else cfg.knee
		piece(cfg.lower, knee, foot, rest_knee, cfg.ankle, tint)
		piece(cfg.upper, hip, knee, cfg.hip, cfg.knee, tint)
		if debug_bones:
			draw_polyline(PackedVector2Array([hip,knee,foot]), Color.MAGENTA if side == 1 else Color.CYAN, 2.0, true)
	patch(cfg.body, bob)
	patch(cfg.weapon, bob)

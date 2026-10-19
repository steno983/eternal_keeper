extends RefCounted
## Native SpriteFrames resources are editable in Godot's animation dock.
static var libraries: Dictionary = {}
static var durations: Dictionary = {}

static func library(key: String) -> SpriteFrames:
	if not libraries.has(key):
		var path = "res://assets/animation_v3/%s.tres" % key
		if ResourceLoader.exists(path):
			libraries[key] = load(path)
		else:
			return null
	return libraries[key]

static func length_of(frames: SpriteFrames, clip: StringName) -> float:
	var key = str(frames.get_instance_id()) + String(clip)
	if not durations.has(key):
		var seconds = 0.0
		for i in range(frames.get_frame_count(clip)):
			seconds += frames.get_frame_duration(clip, i) / frames.get_animation_speed(clip)
		durations[key] = seconds
	return durations[key]

static func sample(frames: SpriteFrames, clip: StringName, clock: float) -> Vector2:
	var total = length_of(frames, clip)
	var cursor = fposmod(clock, total) if frames.get_animation_loop(clip) else clampf(clock, 0, total - 0.00001)
	# Text resources round durations to microseconds. Resolve shared boundaries
	# consistently with the fixed-step contact-event clock.
	cursor += 0.000001
	for i in range(frames.get_frame_count(clip)):
		var duration = frames.get_frame_duration(clip, i) / frames.get_animation_speed(clip)
		if cursor < duration:
			return Vector2(i, cursor / duration)
		cursor -= duration
	return Vector2(frames.get_frame_count(clip) - 1, 1.0)

static func texture(key: String, clip: StringName, clock: float) -> Texture2D:
	var frames = library(key)
	if frames == null:
		return null
	var sample_point = sample(frames, clip, clock)
	return frames.get_frame_texture(clip, int(sample_point.x))

extends RefCounted
## Simulation data. Rendering never changes these combat coordinates.
enum State { APPROACH, WINDUP, RECOVER, STUN, DEAD }
var x: float = 0.0
var y: float = 560.0
var lane: int = 1
var facing: float = 1.0
var hp: float = 100.0
var max_hp: float = 100.0
var combo_step: int = 0
var attack_variant: int = 0
var stagger_guard: float = 0.0
var poise_hits: int = 0
var poise_time: float = 0.0
var kind: String = "hero"
var archetype: String = ""
var move_speed: float = 0.0
var windup_duration: float = 0.0
var burn_time: float=0
var burn_tick: float=0
var slow_time: float=0
var slow_factor: float=1
var entering: bool=false
var entry_side: int=1
var entry_lane_time: float = 0.0
var visual_index: int=-1
var spell_target_x: float=0
var spell_target_lane: int=1
var hero: int = 0
var state: State = State.APPROACH
var timer: float = 0.0
var attack_time: float = 0.0
var flash: float = 0.0
var invincible: float = 0.0
var moving: bool = false
var phase: float = 0.0
var knockback: float = 0.0
var lane_cooldown: float = 0.0
var dead_time: float = 0.0
var id: int = 0
var action: StringName = &""
var action_elapsed: float = 0.0
var action_length: float = 0.0
var action_serial: int = 0
var locomotion_time: float = 0.0
var travelled: float = 0.0
var previous_x: float = 0.0

func begin_action(clip: StringName, duration: float) -> void:
	action = clip
	action_elapsed = 0.0
	action_length = duration
	action_serial += 1
	attack_time = duration if clip in [&"attack", &"ranged", &"special"] else 0.0

func action_active() -> bool:
	return action != &"" and action_elapsed < action_length

func alive() -> bool:
	return hp > 0.0

func tick_visuals(dt: float) -> void:
	locomotion_time += dt
	if action_active():
		action_elapsed = minf(action_length, action_elapsed + dt)
	else:
		action = &""
	travelled += absf(x - previous_x)
	previous_x = x
	attack_time = maxf(0.0, attack_time - dt)
	flash = maxf(0.0, flash - dt)
	invincible = maxf(0.0, invincible - dt)
	lane_cooldown = maxf(0.0, lane_cooldown - dt)
	phase += dt * (11.0 if moving else 2.3)
	x += knockback * dt
	knockback = move_toward(knockback, 0.0, 1100.0 * dt)
	if not alive():
		dead_time += dt

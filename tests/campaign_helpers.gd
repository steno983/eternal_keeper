extends RefCounted
## Objective setup for focused unit tests; full playthrough never uses these shortcuts.
static func prepare_exit(game) -> void:
 var run=game.run
 var rule=run.current_rule()
 if rule.type=="scrolling":
  run.road.index=rule.encounters.size()
  run.road.active=false
 elif rule.type=="resistance": run.objective_time=run.resistance_duration()
 elif rule.type=="defense": run.objective_time=float(rule.duration)
 elif rule.type=="synchronization":
  for i in range(run.synchronization.charge.size()): run.synchronization.charge[i]=float(rule.synchronization.charge_seconds)
 if rule.has("exit"):
  game.player.x=float(rule.exit.x)
  game.player.lane=maxi(0,int(rule.exit.lane))
  game.player.y=game.LANES[game.player.lane]
 elif rule.type=="combat": game.enemies.clear()
static func complete(game) -> void:
 prepare_exit(game)
 game.run.finish_room()
 game.run.finish_stage_clear()

extends RefCounted
## Advance-triggered encounters: no survival timer can finish a scrolling stage.
var index: int=0
var active: bool=false
var entries: Array=[]
var spawned: Dictionary={}
var actors: Array=[]
func reset() -> void:
 index=0
 active=false
 entries.clear()
 spawned.clear()
 actors.clear()
func gate(run) -> float:
 return run.game.stage_right
func left(run) -> float:
 return run.game.stage_left
func finished(run) -> bool:
 return not active and index>=run.current_rule().encounters.size()
func upcoming(run) -> Array:
 if not active or run.game.mode!="playing": return []
 return entries.filter(func(e): return not spawned.has(e.id) and run.room_time>=e.at and run.room_time<e.at+float(run.current_rule().warning_time))
func tick(run) -> void:
 var game=run.game
 var rule=run.current_rule()
 if not active and index<rule.encounters.size() and game.player.x>=float(rule.encounters[index].at_x):
  active=true
  entries.clear()
  spawned.clear()
  actors.clear()
  for source in rule.encounters[index].entries:
   var entry: Dictionary=source.duplicate(true)
   entry.id=entries.size()
   entry.at=run.room_time+float(source.offset)
   entry.lane=int(source.lane)
   entry.side=int(source.side)
   entries.append(entry)
 if not active: return
 for entry in entries:
  if spawned.has(entry.id) or run.room_time<entry.at+float(rule.warning_time): continue
  run.spawn_guard(int(entry.id),int(entry.side))
  var enemy=game.enemies.back()
  run.apply_role(enemy,entry.archetype)
  enemy.lane=int(entry.lane)
  enemy.y=game.LANES[enemy.lane]
  enemy.facing=-int(entry.side)
  enemy.entry_lane_time=1.4
  actors.append(enemy)
  spawned[entry.id]=true
 if spawned.size()==entries.size() and actors.all(func(e): return not e.alive()):
  active=false
  index+=1
  entries.clear()
  actors.clear()

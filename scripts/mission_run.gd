extends "res://scripts/pilgrim_run.gd"
## Campaign slice. Narrative facts follow session 1–2; encounter timing is adaptation.
var mission_id: String="archivio"
var content=preload("res://scripts/mission_data.gd").new()
var page_queue: Array=[]
var page_action: String="room"
var reward_prepared: bool=false
var before_seen: Dictionary={}
var entrance=preload("res://scripts/level_entrance.gd").new()
var synchronization=preload("res://scripts/synchronization.gd").new()
var road=preload("res://scripts/scroll_stage.gd").new()
var stage_clear_elapsed: float=0
var roles: Dictionary={}
var Chapter=preload("res://scripts/archive_story.gd").new()
var prologue_seen: bool=false
var prologue_elapsed: float=0.0
var prologue_paused: bool=false
var prologue_finished: bool=false
var story_page: int=0
var intro_done: bool=false
var objective_time: float=0.0
var room_time: float=0.0
var reinforcement: int=0
var echo_pulse: float=0.0
var NAMES: Array=[]
var room_rules: Array=[]
var resistance_entries: Array=[]
var spawned_entries: Dictionary={}

func reset() -> void:
 super.reset()
 if not content.load_mission(mission_id):
  game.mode="title"
  return
 Chapter.reload(content.mission.texts)
 room_rules=content.levels
 roles=content.enemy_roles
 road.reset()
 stage_clear_elapsed=0
 NAMES=[]
 for rule in room_rules: NAMES.append(Chapter.data.rooms.stages[rule.text_id].name)
 before_seen.clear()
 entrance.elapsed=0
 page_queue.clear()
 reward_prepared=false
 prologue_seen=false
 prologue_elapsed=0
 prologue_paused=false
 prologue_finished=false
 story_page=0
 intro_done=false
 objective_time=0
 room_time=0
 reinforcement=0
 echo_pulse=0
 synchronization.reset(0)
 resistance_entries.clear()
 spawned_entries.clear()

func open_page(index: int) -> void:
 story_page=index
 interlude_revealed=1
 interlude_elapsed=0
 game.mode="interlude"
 game.wave_active=false
 game.pending_actions.clear()
 game.projectiles.clear()
 game.super_banner.clear()
 assist.clear()
 zones.clear()

func current_rule() -> Dictionary:
 return room_rules[clampi(game.wave-1,0,room_rules.size()-1)]

func current_level() -> Dictionary:
 return content.groups[int(current_rule().level_index)]

func level_name() -> String:
 return Chapter.data.levels[current_level().text_id].name

func level_number() -> int:
 return int(current_rule().level_index)+1

func stage_number() -> int:
 return int(current_rule().stage_index)+1

func spawn_encounter() -> void:
 pass # The campaign owns encounter data; base bridge generation is not used.

func present_pages(ids: Array,action: String) -> void:
 page_queue=ids.duplicate()
 page_action=action
 next_page()

func next_page() -> void:
 if not page_queue.is_empty():
  var id: String=page_queue.pop_front()
  for i in range(Chapter.data.pages.size()):
   if Chapter.data.pages[i].id==id:
    open_page(i)
    return
  push_error("Intermezzo non trovato: "+id)
  game.mode="title"
  return
 if page_action=="reward":
  interlude_revealed=3
  game.reward_cursor=0
  game.mode="reward"
 elif page_action=="victory": game.mode="victory"
 else: begin_room()

func begin_room() -> void:
 if not prologue_seen and content.mission.get("prologue",false):
  game.mode="prologue"
  game.wave_active=false
  return
 if not intro_done:
  intro_done=true
  present_pages(content.mission.get("interludes_before",[]),"room")
  return
 if game.wave>=room_rules.size():
  game.mode=content.mission.ending
  return
 var next: Dictionary=room_rules[game.wave]
 if not next.interludes.before.is_empty() and not before_seen.has(game.wave):
  var pages: Array=next.interludes.before.duplicate()
  before_seen[game.wave]=true
  present_pages(pages,"room")
  return
 super.begin_room()
 game.enemies.clear()
 var rule=current_rule()
 game.stage_left=float(rule.stage.left)
 game.stage_right=float(rule.stage.right)
 game.player.x=float(rule.stage.player_x)
 reward_prepared=false
 game.player.previous_x=game.player.x
 game.player.moving=false
 room_time=0
 objective_time=0
 reinforcement=0
 echo_pulse=0
 if rule.type=="synchronization": synchronization.reset(rule.synchronization.sigils.size())
 road.reset()
 stage_clear_elapsed=0
 if is_resistance():
  game.player.x=horizontal_anchor()
  game.player.previous_x=game.player.x
  game.camera_x=resistance_camera()
 entrance.begin(content.mission.get("entrance",{}),current_level().get("entrance",{}))
 game.wave_banner=0
 if rule.level_start and entrance.enabled():
  game.mode="level_intro"
  game.wave_active=false
 else: activate_level()
 notice=Chapter.data.rooms.stages[rule.text_id].notice
 notice_time=4
 if rule.level_start and not taken.is_empty():
  var item: Dictionary=taken.back()
  notice=Texts.ui("upgrade_carried") % [skill_name(int(item.slot)),item.name]
  notice_time=6.5

func tick_entrance(dt: float) -> void:
 if game.mode!="level_intro": return
 entrance.elapsed+=dt
 if entrance.elapsed>=entrance.duration(): finish_entrance()

func finish_entrance() -> void:
 if game.mode!="level_intro": return
 activate_level()

func activate_level() -> void:
 game.mode="playing"
 game.wave_active=true
 game.player.invincible=0.8
 if is_resistance(): prepare_resistance()
 else:
  for i in range(int(current_rule().initial_enemies)):
   spawn_guard(i)
   if current_rule().has("initial_roles"): apply_role(game.enemies.back(),current_rule().initial_roles[i%current_rule().initial_roles.size()])

func is_resistance() -> bool:
 return game.wave>0 and game.wave<=room_rules.size() and current_rule().type=="resistance"

func horizontal_anchor() -> float:
 return float(current_rule().anchor_x)

func resistance_camera() -> float:
 return horizontal_anchor()-(720.0-game.CAMERA_PIVOT.x*(1.0-game.WORLD_ZOOM))/game.WORLD_ZOOM

func resistance_duration() -> float:
 return float(current_rule().duration)

func resistance_remaining() -> float:
 return maxf(0,resistance_duration()-objective_time)

func prepare_resistance() -> void:
 resistance_entries.clear()
 spawned_entries.clear()
 var rule: Dictionary=current_rule()
 for wave_index in range(rule.waves.size()):
  for source in rule.waves[wave_index].entries:
   var entry: Dictionary=source.duplicate(true)
   entry.id=resistance_entries.size()
   entry.wave=wave_index
   entry.at=float(rule.waves[wave_index].at)+float(source.offset)
   entry.lane=int(source.lane)
   entry.side=int(source.side)
   resistance_entries.append(entry)
 tick_resistance_entries()

func upcoming_entries() -> Array:
 if current_rule().type=="scrolling": return road.upcoming(self)
 var entries: Array=[]
 if not is_resistance() or game.mode!="playing": return entries
 var warning: float=current_rule().warning_time
 for entry in resistance_entries:
  if not spawned_entries.has(entry.id) and room_time>=entry.at and room_time<entry.at+warning:
   entries.append(entry)
 return entries

func apply_role(enemy,role: String) -> void:
 var stats: Dictionary=roles[role]
 enemy.archetype=role
 enemy.kind=stats.kind
 enemy.max_hp=float(stats.hp)
 enemy.hp=enemy.max_hp
 enemy.move_speed=float(stats.speed)
 enemy.windup_duration=float(stats.windup)
 enemy.visual_index=int(stats.visual)

func movement_limit() -> float:
 return road.gate(self) if current_rule().type=="scrolling" else game.stage_right
func movement_left() -> float:
 return road.left(self) if current_rule().type=="scrolling" else game.stage_left

func resistance_wave_name() -> String:
 var wave=current_rule().waves[maxi(0,reinforcement-1)]
 return Chapter.data.rooms.wave_names[wave.id]

func tick_resistance_entries() -> void:
 var rule: Dictionary=current_rule()
 for i in range(rule.waves.size()):
  if room_time>=float(rule.waves[i].at): reinforcement=i+1
 for entry in resistance_entries:
  if spawned_entries.has(entry.id) or room_time<entry.at+float(rule.warning_time): continue
  spawn_guard(int(entry.id),int(entry.side))
  var enemy=game.enemies[-1]
  var stats: Dictionary=rule.archetypes[entry.archetype]
  enemy.archetype=entry.archetype
  enemy.kind=stats.kind
  enemy.visual_index=int(stats.get("visual",roles.get(entry.archetype,{}).get("visual",-1)))
  enemy.max_hp=float(stats.hp)
  enemy.hp=enemy.max_hp
  enemy.move_speed=float(stats.speed)
  enemy.windup_duration=float(stats.windup)
  enemy.entry_lane_time=float(rule.get("entry_lane_hold",2.4))
  enemy.timer=0.25
  enemy.lane=entry.lane
  enemy.y=game.LANES[enemy.lane]
  spawned_entries[entry.id]=true

func spawn_guard(index: int, side: int=0) -> void:
 var enemy=game.Fighter.new()
 enemy.id=game.enemy_serial
 game.enemy_serial+=1
 enemy.kind="archer" if index%3==2 else "raider"
 enemy.max_hp=38 if enemy.kind=="archer" else 48
 enemy.hp=enemy.max_hp
 enemy.x=1430 if side>0 else 180+index%2*100
 if current_rule().type=="escape": enemy.x=escape_spawn_x(index)
 enemy.previous_x=enemy.x
 enemy.lane=index%3
 var rule=current_rule()
 if rule.has("spawn_points"):
  var point: Dictionary=rule.spawn_points[index%rule.spawn_points.size()]
  enemy.x=float(point.x)
  enemy.lane=int(point.lane)
  if absf(enemy.x-game.player.x)<float(rule.spawn_safe_distance):
   for candidate in rule.spawn_points:
    if absf(float(candidate.x)-game.player.x)>absf(enemy.x-game.player.x):
     enemy.x=float(candidate.x)
     enemy.lane=int(candidate.lane)
   if absf(enemy.x-game.player.x)<float(rule.spawn_safe_distance):
    var left: float=game.stage_left+80
    var right: float=game.stage_right-80
    enemy.x=left if absf(left-game.player.x)>absf(right-game.player.x) else right
  enemy.previous_x=enemy.x
 enemy.y=game.LANES[enemy.lane]
 enemy.timer=0.8+index*0.15
 enemy.facing=-1 if side>0 else 1
 if rule.has("spawn_points"): enemy.facing=signf(game.player.x-enemy.x)
 if current_rule().type=="escape": enemy.facing=signf(game.player.x-enemy.x)
 game.begin_enemy_entry(enemy,side)
 game.enemies.append(enemy)

func escape_spawn_x(index: int) -> float:
 var rule: Dictionary=current_rule()
 var left: float=game.stage_left+float(rule.spawn_margin)
 var right: float=game.stage_right-float(rule.spawn_margin)
 var enter_from_right=game.player.x<(left+right)*0.5
 var x: float=right-float(index%2)*float(rule.spawn_spacing) if enter_from_right else left+float(index%2)*float(rule.spawn_spacing)
 if absf(x-game.player.x)<float(rule.spawn_min_distance):
  x=right if absf(right-game.player.x)>absf(left-game.player.x) else left
 return x

func tick(dt: float) -> void:
 super.tick(dt)
 room_time+=dt
 if current_rule().type=="scrolling": road.tick(self)
 if current_rule().type=="synchronization": synchronization.tick(self,dt)
 echo_pulse-=dt
 if is_resistance():
  objective_time=minf(resistance_duration(),objective_time+dt)
  tick_resistance_entries()
 elif current_rule().type=="defense":
  objective_time=minf(float(current_rule().duration),objective_time+dt)
 # Limited reinforcements keep pressure without requiring an endless slaughter.
 var reinforcements: Dictionary=current_rule().reinforcements
 if not is_resistance() and reinforcement<int(reinforcements.count) and room_time>=float(reinforcements.interval)*(reinforcement+1) and game.living_enemies()<int(reinforcements.max_alive):
  spawn_guard(3+reinforcement)
  reinforcement+=1
 var allies: Dictionary=current_rule().allies
 if allies.echo_enabled and echo_pulse<=0:
  echo_pulse=float(allies.echo_interval)
  for enemy in game.enemies:
   if enemy.alive() and enemy.x<float(allies.echo_max_x):
    assist_damage=true
    game.damage_enemy(enemy,float(allies.echo_damage),1,game.HEROES[2].color,false)
    assist_damage=false
    game.effects.append({"kind":"ally","hero":2,"x":enemy.x-55,"y":enemy.y,"facing":1,"life":0.36,"max":0.36})
    break

func objective_complete() -> bool:
 if not game.player.alive() or game.mode!="playing": return false
 if is_resistance(): return objective_time>=resistance_duration()
 var rule=current_rule()
 if rule.type=="defense": return objective_time>=float(rule.duration)
 if rule.type=="combat": return game.living_enemies()==0
 if rule.type=="scrolling" and not road.finished(self): return false
 if rule.type=="synchronization" and synchronization.completed(rule.synchronization)<rule.synchronization.sigils.size(): return false
 var exit: Dictionary=rule.exit
 return game.player.x>=float(exit.x) and (int(exit.lane)<0 or game.player.lane==int(exit.lane) and absf(game.player.y-game.LANES[int(exit.lane)])<float(exit.tolerance))

func objective_label() -> String:
 var copy=Chapter.data.rooms
 if is_resistance(): return copy.resistance_progress % ceili(resistance_remaining())
 if current_rule().type=="defense": return copy.hold_progress % int(objective_time/float(current_rule().duration)*100)
 if current_rule().type=="combat": return Texts.ui("d_avversari_rimasti") % game.living_enemies()
 if current_rule().type=="scrolling":
  return Texts.ui("road_fight") % game.living_enemies() if road.active else Texts.ui("road_advance") % [mini(road.index+1,current_rule().encounters.size()),current_rule().encounters.size()]
 if current_rule().type=="synchronization":
  if synchronization.completed(current_rule().synchronization)==current_rule().synchronization.sigils.size(): return Texts.ui("road_exit_open")
  return Texts.ui("sync_objective") % [synchronization.completed(current_rule().synchronization),current_rule().synchronization.sigils.size()]
 return copy.exit

func tick_prologue(dt: float) -> void:
 if game.mode=="prologue" and not prologue_paused and not prologue_finished:
  prologue_elapsed+=dt

func finish_prologue() -> void:
 if game.mode!="prologue": return
 prologue_seen=true
 intro_done=true
 present_pages(content.mission.get("interludes_before",[]),"room")

func finish_room() -> void:
 if not objective_complete(): return
 game.wave_active=false
 game.mode="stage_clear"
 stage_clear_elapsed=0
 game.pending_actions.clear()
 game.projectiles.clear()
 game.super_banner.clear()
 assist.clear()
 zones.clear()
 game.player.moving=false

func tick_stage_clear(dt: float) -> void:
 if game.mode!="stage_clear": return
 stage_clear_elapsed+=dt
 if stage_clear_elapsed>=1.65: finish_stage_clear()

func finish_stage_clear() -> void:
 if game.mode!="stage_clear": return
 game.mode="interlude"
 var rule=current_rule()
 var reward: Dictionary=rule.reward
 var action="room" if game.wave<room_rules.size() else content.mission.ending
 if reward.type=="skill_upgrade":
  if not reward_prepared:
   prepare_reward(float(reward.heal),float(reward.mana),int(reward.choices))
   reward_prepared=true
  action="reward"
 present_pages(rule.interludes.after,action)

func advance_interlude() -> void:
 if game.mode!="interlude": return
 if interlude_revealed<Chapter.BEATS[story_page].size():
  interlude_revealed+=1
 else: show_rewards()

func show_rewards() -> void:
 if game.mode!="interlude": return
 next_page()

func choose(index: int) -> void:
 if game.mode!="reward" or index<0 or index>=choices.size(): return
 var upgrade: Dictionary=choices[index]
 mods[upgrade.slot]=upgrade.id
 taken.append(upgrade)
 level+=1
 choices.clear()
 if game.wave>=room_rules.size(): game.mode=content.mission.ending
 else: begin_room()

extends SceneTree
var game
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("verify")
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error(label)
func reward_boundary(upgrade: Dictionary) -> void:
 game.start_game(true)
 var run=game.run
 run.prologue_seen=true
 run.intro_done=true
 game.wave=2
 run.begin_room()
 game.player.x=float(run.current_rule().exit.x)
 game.player.lane=1
 game.player.y=game.LANES[1]
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 run.show_rewards()
 check(game.mode=="reward","First level reaches the real inn reward")
 run.choices[0]=upgrade.duplicate(true)
 run.choose(0)
 check(game.mode=="interlude" and run.Chapter.data.pages[run.story_page].id=="orologio_rapporto","Reward leads into the new report comic")
 run.show_rewards()
 check(game.mode=="level_intro" and run.level_number()==2,"Second level gets its own title")
 run.finish_entrance()
func verify() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 var upgrades=game.run.UPGRADES.duplicate(true)
 for upgrade in upgrades:
  reward_boundary(upgrade)
  var run=game.run
  var slot: int=upgrade.slot
  check(run.mods[slot]==upgrade.id and run.taken.size()==1 and run.level==10,"Chosen transformation survives entry: "+upgrade.id)
  check(game.enemies.all(func(e): return absf(e.x-game.player.x)>=440),"New descent spawns enemies away from player")
  game.enemies.clear()
  var enemy=game.Fighter.new()
  enemy.id=game.enemy_serial
  game.enemy_serial+=1
  enemy.max_hp=300
  enemy.hp=300
  enemy.x=game.player.x+210
  enemy.previous_x=enemy.x
  enemy.lane=game.player.lane
  enemy.y=game.LANES[enemy.lane]
  game.enemies.append(enemy)
  var expected_cd=run.cooldown_for(slot)
  check(run.cast(slot),"Transformed skill can actually be cast in the second level: "+upgrade.id)
  check(is_equal_approx(run.skill_cd_total[slot],expected_cd),"Cooldown uses retained mutation and gained level: "+upgrade.id)
  game.player.tick_visuals(0.21)
  game._resolve_actions()
  match upgrade.id:
   "orb": check(game.projectiles[0].spell=="orb","Explosive bolt retains its collision behavior")
   "pierce": check(game.projectiles[0].pierces==3,"Piercing bolt retains three targets")
   "fan": check(game.projectiles.size()==3 and run.cost(0)==12,"Scorching rays retain three lanes and cost")
   "ash": check(run.zones[0].radius==185 and run.zones[0].life==5,"Ash field retains enlarged radius and duration")
   "sanctuary": check(run.zones[0].healing,"Sanctuary retains healing zone")
   "eruption": check(enemy.hp==225 and run.zones.is_empty(),"Eruption replaces zone with 75 damage")
   "mirror":
    var hp: float=enemy.hp
    enemy.x=game.player.x+30
    run.mitigate(10)
    check(enemy.hp==hp-20,"Ward retaliates after level transition")
   "renewal":
    game.player.hp=100
    run.tick(0.5)
    check(game.player.hp==102,"Renewal still heals after transition")
   "aegis": check(run.barrier==57 and run.buff_time==8,"Aegis retains shield and duration")
   "judgment": check(game.effects.filter(func(f): return f.kind=="holy_wave").size()==3,"Judgment still strikes three lanes")
   "inferno": check(run.zones.size()==3,"Inferno still leaves three fire zones")
   "nova": check(enemy.hp==230 and game.effects.any(func(f): return f.kind=="nova"),"Nova still replaces directional wave")
  # Complete the stage through its objective, then enter the real resistance.
  game.enemies.clear()
  preload("res://tests/campaign_helpers.gd").prepare_exit(game)
  run.finish_room()
  run.finish_stage_clear() # Presentation is covered independently.
  if game.mode=="interlude": run.show_rewards()
  check(game.mode=="playing" and run.stage_number()==2 and run.mods[slot]==upgrade.id,"Mutation survives the second level's internal stage transition: "+upgrade.id)
  check(run.taken.size()==1 and run.choices.is_empty(),"No extra reward or build reset between stages")
  check(run.path_rank(upgrade.path)==1,"Chosen route benefit survives stage transition: "+upgrade.id)
 # Synchronization: real charge, warning, damage, persistence and final reward.
 var run=game.run
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 if game.mode=="interlude": run.show_rewards()
 check(run.current_rule().type=="synchronization" and game.mode=="playing","Third stage uses the new synchronization objective")
 var rule: Dictionary=run.current_rule().synchronization
 check(not run.objective_complete(),"Eliminating enemies cannot skip the sigils")
 for sigil in rule.sigils:
  game.player.x=float(sigil.x)
  game.player.lane=int(sigil.lane)
  game.player.y=game.LANES[game.player.lane]
  run.synchronization.tick(run,float(rule.charge_seconds))
 check(run.synchronization.completed(rule)==3 and not run.objective_complete(),"Sigils unlock the exit without ending the road automatically")
 game.player.x=float(run.current_rule().exit.x)
 game.player.lane=maxi(0,int(run.current_rule().exit.lane))
 game.player.y=game.LANES[game.player.lane]
 check(run.objective_complete(),"Reaching the final exit completes the chamber")
 var hp: float=game.player.hp
 game.player.invincible=0
 game.player.lane=0
 run.room_time=float(rule.pulse_interval)
 run.synchronization.tick(run,0)
 check(game.player.hp==hp-float(rule.pulse_damage),"Telegraphed pulse damages only its lane")
 run.synchronization.tick(run,0)
 check(game.player.hp==hp-float(rule.pulse_damage),"Same pulse cannot hit twice")
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 run.show_rewards()
 check(game.mode=="reward" and run.choices.all(func(u): return run.mods[u.slot]==""),"Second reward excludes the already transformed slot")
 run.choose(0)
 check(game.mode=="victory" and run.taken.size()==2 and run.level==11,"Both choices survive into the final build")
 game.start_game(true)
 check(game.run.taken.is_empty() and game.run.mods==["","","",""] and game.run.level==9,"Only starting a fresh run clears the build")
 print("SECOND LEVEL SKILLS: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

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
func verify() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.start_game(true)
 game.run.finish_prologue()
 game.run.show_rewards()
 game.run.finish_entrance() # Skip presentation in this mechanics test.
 game.run.show_rewards()
 game.run.finish_entrance() # Skip presentation in this mechanics test.
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 game.run.finish_room()
 game.run.finish_stage_clear() # Presentation is covered independently.
 game.run.show_rewards()
 game.run.finish_entrance() # Skip presentation in this mechanics test.
 var run=game.run
 run.echo_pulse=1000 # Isolate the entry scheduler from ally damage in this unit test.
 check(game.wave==2 and run.resistance_entries.size()==10,"Second room schedules ten enemies in four patterns")
 check(game.enemies.is_empty(),"No unannounced instant spawn at room entry")
 var cues: Array=run.upcoming_entries()
 check(cues.size()==1 and cues[0].side==-1 and cues[0].lane==1,"First warning identifies left middle lane")
 run.tick(0.9)
 check(run.upcoming_entries().size()==2 and game.enemies.is_empty(),"Right-side warning is staggered before either guard arrives")
 var time: float=run.room_time
 game.mode="paused"
 game._physics_process(3)
 check(run.room_time==time and game.enemies.is_empty(),"Pause cannot consume warnings or spawn enemies")
 game.mode="playing"
 game.help_open=true
 game._physics_process(3)
 check(run.room_time==time,"Help freezes the entry clock")
 game.help_open=false
 run.tick(0.31)
 check(game.enemies.size()==1 and game.enemies[0].x<game.player.x,"Left guard arrives after its full prewarning")
 check(run.upcoming_entries().size()==1 and run.upcoming_entries()[0].side==1,"Right warning remains until its own deadline")
 var guard=game.enemies[0]
 game.player.lane=0
 game._tick_enemy(guard,0.5)
 check(guard.lane==1,"Enemy respects the announced lane during entry")
 for step in range(40): game._tick_enemy(guard,0.1)
 check(guard.lane==0,"Enemy may react to player lane once entry commitment ends")
 run.tick(0.8)
 check(game.enemies.size()==2,"Second guard enters at its staggered deadline")
 run.tick(0)
 check(game.enemies.size()==2,"A repeated tick never duplicates an entry")
 run.room_time=6.1
 run.tick(0)
 cues=run.upcoming_entries()
 check(run.reinforcement==2 and cues.size()==1 and cues[0].archetype=="archer" and cues[0].side==1 and cues[0].lane==0,"Second pattern announces an upper-right crossbow")
 # Resolve all authored deadlines without simulating combat; the full playthrough tests balance.
 var warning: float=run.room_rules[1].warning_time
 for entry in run.resistance_entries:
  run.room_time=maxf(run.room_time,entry.at+warning+0.001)
  run.tick(0)
 check(game.enemies.size()==10 and run.spawned_entries.size()==10,"Every planned entry spawns exactly once")
 check(game.enemies.filter(func(e): return e.archetype=="guard").size()==3,"Three ordinary guards and one brute")
 check(game.enemies.filter(func(e): return e.archetype=="runner").size()==3,"Three fast assaulters")
 check(game.enemies.filter(func(e): return e.archetype=="archer").size()==3,"Three crossbowmen")
 var runner=game.enemies.filter(func(e): return e.archetype=="runner")[0]
 var archer=game.enemies.filter(func(e): return e.archetype=="archer")[0]
 check(runner.move_speed>guard.move_speed and runner.max_hp<guard.max_hp,"Assaulters are faster and more fragile than guards")
 check(archer.kind=="archer" and archer.windup_duration>=guard.windup_duration,"Crossbowman retains ranged behavior and readable windup")
 check(run.resistance_entries.filter(func(e): return e.side<0).size()==5 and run.resistance_entries.filter(func(e): return e.side>0).size()==5,"Overall pressure is balanced across both directions")
 check(run.reinforcement==4 and run.resistance_wave_name()==run.Chapter.data.rooms.wave_names.last_push,"HUD reaches the correct final pattern name")
 run.open_page(3)
 check(run.upcoming_entries().is_empty(),"Entry signals disappear during narrative scenes")
 game.start_game(true)
 check(game.run.resistance_entries.is_empty() and game.run.spawned_entries.is_empty(),"Restart discards all queued entries")
 print("RESISTANCE WAVES: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

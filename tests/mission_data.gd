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
 var loader=load("res://scripts/mission_data.gd").new()
 check(loader.load_mission("archivio"),"Real manifest resolves all levels, text, comics and assets")
 check(loader.levels.map(func(r): return r.id)==["archivio_scale","archivio_passaggio","archivio_fuga","orologio_discesa","orologio_sigillo","orologio_camera"],"Manifest determines room order")
 check(loader.environment(1).layers[0].texture=="res://assets/archive/door.png","Level selects its environment by stable ID")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.start_game(true)
 var run=game.run
 # Rearrange and expand the loaded definitions: no stage-number logic may leak in.
 var escape: Dictionary=run.room_rules[2].duplicate(true)
 var defense: Dictionary=run.room_rules[0].duplicate(true)
 escape.interludes={"before":["pagina_4"],"after":[]}
 escape.reward.type="none"
 escape.stage.player_x=600
 escape.exit.x=1200
 defense.interludes={"before":[],"after":[]}
 defense.type="defense"
 defense.duration=2
 defense.allies.echo_enabled=false
 defense.reward.type="skill_upgrade"
 defense.reward.heal=7
 defense.reward.mana=9
 var combat: Dictionary=defense.duplicate(true)
 combat.type="combat"
 combat.reward.type="none"
 combat.initial_enemies=1
 combat.reinforcements.count=0
 run.room_rules.assign([escape,defense,combat,defense.duplicate(true),combat.duplicate(true)])
 run.NAMES.assign(["a","b","c","d","e"])
 run.intro_done=true
 run.prologue_seen=true
 run.begin_room()
 check(game.mode=="interlude" and run.story_page==3 and game.wave==0,"Per-level before comic uses its ID before spawning the room")
 run.show_rewards()
 run.finish_entrance() # Test mission progression independently of presentation.
 check(game.mode=="playing" and game.wave==1 and game.player.x==600,"Escape can be the first room and honors configured start")
 check(not run.objective_complete(),"Escape is not accidentally treated as room-one defense")
 game.player.x=1200
 check(run.objective_complete(),"Configured exit position completes escape")
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 run.finish_entrance() # Test mission progression independently of presentation.
 check(game.wave==2 and game.mode=="playing" and run.current_rule().type=="defense","Empty after list advances directly into a different room type")
 game.player.hp=100
 run.mana=50
 run.objective_time=2
 check(run.objective_complete(),"Defense duration comes from data regardless of ordinal")
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 run.finish_entrance() # Test mission progression independently of presentation.
 check(game.mode=="reward" and run.choices.size()==3,"Intermediate reward works without a comic")
 check(game.player.hp==107 and run.mana==59,"Reward restoration uses configured amounts")
 run.choose(0)
 run.finish_entrance() # Test mission progression independently of presentation.
 check(game.wave==3 and game.mode=="playing" and run.current_rule().type=="combat","Upgrade continues the mission instead of ending it")
 check(not run.objective_complete(),"Combat requires actual enemies to be defeated")
 game.enemies.clear()
 check(run.objective_complete(),"Combat room completes after enemies are gone")
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 run.finish_entrance() # Test mission progression independently of presentation.
 run.objective_time=2
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 run.finish_entrance() # Test mission progression independently of presentation.
 run.choose(0)
 run.finish_entrance() # Test mission progression independently of presentation.
 check(game.wave==5 and game.mode=="playing","A fifth room is supported without legacy bridge array limits")
 game.enemies.clear()
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 run.finish_entrance() # Test mission progression independently of presentation.
 check(game.mode=="victory","Last room can conclude without reward or interlude")
 game.start_game(true)
 check(game.run.room_rules.size()==6 and game.run.room_rules[0].id=="archivio_scale","Restart rereads manifests and restores their original order")
 check(game.run.before_seen.is_empty(),"Restart clears per-room interlude state")
 print("MISSION DATA: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

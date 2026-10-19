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
 var run=game.run
 check(run.content.groups.size()==2 and run.room_rules.size()==6,"Mission contains two real levels of three stages")
 check(run.room_rules.map(func(s): return s.level_index)==[0,0,0,1,1,1],"Stage grouping is read from both level files")
 check(run.room_rules.map(func(s): return s.level_start)==[true,false,false,true,false,false],"Only first stage of each level opens with a title")
 check(run.room_rules.map(func(s): return s.reward.type)==["none","none","skill_upgrade","none","none","skill_upgrade"],"Each reward belongs to its level's final stage")
 run.finish_prologue()
 run.show_rewards()
 run.show_rewards()
 check(game.mode=="level_intro" and run.level_name()=="La fuga dall’archivio" and run.level_number()==1,"Opening uses the level name, not the first stage name")
 run.finish_entrance()
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 run.show_rewards()
 check(game.wave==2 and game.mode=="playing" and run.level_number()==1 and run.stage_number()==2,"Second stage proceeds immediately inside the same level")
 check(run.choices.is_empty(),"No reward between stages")
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 run.show_rewards()
 check(game.wave==3 and game.mode=="playing" and run.level_number()==1,"Third stage also has no title pause")
 game.player.x=float(run.current_rule().exit.x)
 game.player.lane=1
 game.player.y=game.LANES[1]
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 check(game.mode=="interlude" and run.choices.size()==3,"Final stage prepares one reward after the level's narrative closure")
 run.show_rewards()
 check(game.mode=="reward","Level ends at the upgrade choice")
 run.choose(0)
 check(game.mode=="interlude","Second level opens with the report comic")
 run.show_rewards()
 check(game.mode=="level_intro" and game.wave==4 and run.level_number()==2,"Next level title begins only after choosing the upgrade")
 check(game.enemies.is_empty() and run.room_time==0,"Next level opening retains combat freeze")
 run.finish_entrance()
 game.enemies.clear()
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 if game.mode=="interlude": run.show_rewards()
 check(game.mode=="playing" and run.level_number()==2 and run.stage_number()==2,"Second level stages continue without repeating the title")
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 if game.mode=="interlude": run.show_rewards()
 check(run.current_rule().type=="synchronization","Final stage uses synchronization")
 for sigil in run.current_rule().synchronization.sigils:
  game.player.x=float(sigil.x)
  game.player.lane=int(sigil.lane)
  game.player.y=game.LANES[game.player.lane]
  run.synchronization.tick(run,2)
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 run.finish_room()
 run.finish_stage_clear() # Presentation is covered independently.
 run.show_rewards()
 run.choose(0)
 check(game.mode=="victory" and run.taken.size()==2,"Second reward concludes the real two-level mission")
 game.start_game(true)
 check(run.content.groups.size()==2 and run.room_rules.size()==6,"Restart reloads real level/stage boundaries")
 print("LEVEL GROUPS: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

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
func tap(code: Key) -> void:
 var event=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=true
 game._unhandled_input(event)
func enter() -> void:
 game.start_game(true)
 game.run.finish_prologue()
 game.run.show_rewards()
 game.run.show_rewards()
func verify() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 enter()
 var run=game.run
 check(game.mode=="level_intro" and not game.wave_active,"Every room opens in a distinct presentation phase")
 check(game.enemies.is_empty() and game.wave==1,"Enemies are not spawned during the title")
 tap(KEY_ENTER)
 check(game.mode=="level_intro","Input that closed a comic cannot instantly dismiss the title")
 var x: float=game.player.x
 var hp: float=game.player.hp
 game.run.skill_cd[0]=3
 game._physics_process(0.4)
 check(run.room_time==0 and run.objective_time==0 and game.encounter_time==0,"Combat and objective clocks stay at zero")
 check(game.player.x==x and game.player.hp==hp and run.skill_cd[0]==3,"Player state and cooldowns do not advance")
 check(game.enemies.is_empty() and game.pending_actions.is_empty(),"Opening cannot trigger enemy actions")
 check(run.entrance.writing()>0 and run.entrance.writing()<1 and run.entrance.erasing()==0,"Horizontal writing precedes erasure")
 game.help_open=true
 game._physics_process(5)
 check(is_equal_approx(run.entrance.elapsed,0.4),"Help freezes the presentation clock")
 game.help_open=false
 tap(KEY_ESCAPE)
 check(game.mode=="paused" and game.paused_mode=="level_intro","Opening can be paused")
 game._physics_process(5)
 check(is_equal_approx(run.entrance.elapsed,0.4),"Pause freezes writing and combat")
 tap(KEY_ENTER)
 check(game.mode=="level_intro","Resume returns to the opening, not straight to combat")
 game._physics_process(1.35)
 check(run.entrance.erasing()>0 and run.entrance.erasing()<1,"A distinct erasure phase follows the readable hold")
 game._physics_process(0.3)
 check(game.mode=="playing" and game.wave_active and game.enemies.is_empty(),"Completion activates the scrolling stage before its first encounter")
 check(run.room_time==0 and game.encounter_time==0,"Finishing frame does not also advance combat")
 run.finish_entrance()
 check(game.enemies.is_empty(),"Repeated completion cannot spawn early enemies")
 enter()
 game._physics_process(0.3)
 tap(KEY_ENTER)
 check(game.mode=="playing" and game.run.room_time==0,"Enter skips the presentation without simulating elapsed combat")
 # The second stage belongs to the same level: no repeated opening.
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 run.finish_room()
 run.finish_stage_clear()
 run.show_rewards()
 check(game.mode=="playing" and game.wave==2 and game.enemies.is_empty(),"Next stage in the same level starts without repeating the title")
 check(run.resistance_entries.size()==10,"Resistance scheduling starts normally at the next stage")
 run.finish_entrance()
 check(run.resistance_entries.size()==10 and run.upcoming_entries().size()==1 and run.room_time==0,"Entry warnings start at time zero after opening")
 enter()
 run.current_level().entrance={"style":"none"}
 run.prologue_seen=true
 run.intro_done=true
 game.wave=0
 run.begin_room()
 check(game.mode=="playing","Per-level override can disable opening for a custom sequence")
 var clock=load("res://scripts/level_entrance.gd").new()
 clock.begin({"style":"pencil","hold":0.85},{"style":"ink","hold":1.2})
 check(clock.config.style=="ink" and clock.config.hold==1.2 and clock.config.write==0.65,"Overrides merge with mission-wide timings")
 print("LEVEL ENTRANCE: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

extends SceneTree
var game
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error(label)
func forward_page() -> void:
 for i in range(3): game.run.advance_interlude()
 game.run.finish_entrance() # Presentation has separate timing/freeze coverage.
func run_checks() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.start_game(true)
 check(game.mode=="prologue" and game.wave==0,"Campaign starts with a scrolling introduction")
 game._physics_process(2)
 check(game.run.prologue_elapsed==2 and game.encounter_time==0,"Introduction scrolls while combat stays frozen")
 game.run.prologue_paused=true
 game._physics_process(2)
 check(game.run.prologue_elapsed==2,"Reading pause freezes the scroll")
 game.run.prologue_paused=false
 game.help_open=true
 game._physics_process(2)
 check(game.run.prologue_elapsed==2,"Help freezes the introduction")
 game.help_open=false
 var restart=InputEventKey.new()
 restart.physical_keycode=KEY_R
 restart.keycode=KEY_R
 restart.pressed=true
 game._unhandled_input(restart)
 check(game.mode=="prologue" and game.run.prologue_elapsed==0,"R restarts and reloads copy even during introduction")
 game.run.finish_prologue()
 check(game.mode=="interlude" and game.wave==0 and game.run.story_page==0,"Introduction leads into Corvin’s comic")
 game._physics_process(30)
 check(game.run.interlude_revealed==1,"Intro never auto advances")
 check(game.encounter_time==0,"No combat clock during intro")
 forward_page()
 check(game.mode=="interlude" and game.run.story_page==1,"Second intro page reveals Daleal and date")
 forward_page()
 check(game.mode=="playing" and game.wave==1,"Manual dialogue starts archive defense")
 game.enemies.clear()
 game._tick_world(0.01)
 check(game.mode=="playing","Killing all enemies cannot skip archive objective")
 game.mode="paused"
 var progress: float=game.run.objective_time
 game._physics_process(8)
 check(game.run.objective_time==progress,"Pause freezes objective progress")
 game.mode="playing"
 game.help_open=true
 game._physics_process(8)
 check(game.run.objective_time==progress,"Help freezes objective progress")
 game.help_open=false
 preload("res://tests/campaign_helpers.gd").prepare_exit(game)
 game.run.finish_room()
 game.run.finish_stage_clear()
 check(game.mode=="interlude" and game.run.story_page==2,"Defense ends in exit discovery dialogue")
 check(game.run.choices.is_empty(),"No reward while pursued")
 forward_page()
 check(game.wave==2 and game.mode=="playing" and game.horizontal_locked(),"Second encounter is stationary resistance")
 check(game.enemies.is_empty() and game.run.upcoming_entries().size()==1,"First entry is warned before an enemy spawns")
 game.run.tick(2.1)
 check(game.enemies.any(func(e): return e.x<game.player.x) and game.enemies.any(func(e): return e.x>game.player.x),"First wave enters from both sides after warning")
 var anchor: float=game.player.x
 var camera: float=game.camera_x
 game.enemies.clear()
 Input.action_press("move_left")
 game._read_input(0.1)
 Input.action_release("move_left")
 game._tick_world(0.1)
 check(game.player.facing==-1 and game.player.x==anchor and not game.player.moving,"A turns left without walking")
 Input.action_press("move_right")
 game._read_input(0.1)
 Input.action_release("move_right")
 check(game.player.facing==1 and game.player.x==anchor,"D turns right without walking")
 game.dodge()
 game._tick_world(0.05)
 check(game.player.x==anchor and game.player.invincible>0,"Dodge keeps invulnerability without horizontal displacement")
 game.player.knockback=170
 game._tick_world(0.05)
 check(game.player.x==anchor and game.camera_x==camera,"Knockback does not move the anchor or camera")
 game.change_lane(1)
 game._tick_world(0.1)
 check(game.player.lane==2 and game.player.x==anchor,"Lane changes remain available")
 check(game.mode=="playing" and game.run.objective_time>0,"Clearing enemies does not end resistance; timer advances")
 var before: float=game.run.objective_time
 game.mode="paused"
 game._physics_process(2)
 check(game.run.objective_time==before,"Pause freezes resistance countdown")
 game.mode="playing"
 game.help_open=true
 game._physics_process(2)
 check(game.run.objective_time==before,"Help freezes resistance countdown")
 game.help_open=false
 game.run.room_time=6
 game.run.tick(0.01)
 check(game.run.reinforcement==2 and game.enemies.is_empty() and not game.run.upcoming_entries().is_empty(),"Next wave warns before spawning")
 game.run.tick(2.5)
 check(game.enemies.size()==2,"Second wave spawns its staggered pair")
 check(game.enemies.any(func(e): return e.x<anchor) and game.enemies.any(func(e): return e.x>anchor),"Reinforcements arrive from both sides")
 game.enemies.clear()
 game.run.spawn_guard(0,1)
 game.enemies[-1].x=1120
 game.enemies[-1].lane=0
 before=game.run.objective_time
 game.run.tick(1)
 check(game.run.objective_time>before,"Enemy near Layla cannot stall the survival timer")
 game.run.objective_time=game.run.resistance_duration()-0.1
 check(not game.run.objective_complete(),"Resistance cannot finish before timer reaches zero")
 game.run.tick(0.1)
 check(game.run.objective_complete(),"Surviving to zero completes objective even with enemies alive")
 game.run.finish_room()
 game.run.finish_stage_clear()
 forward_page()
 check(game.wave==3 and game.mode=="playing","Open door leads into escape corridor")
 game.enemies.clear()
 game._tick_world(0.01)
 check(game.mode=="playing","Corridor does not require killing everyone")
 game.player.x=float(game.run.current_rule().exit.x)
 game.player.lane=0
 check(not game.run.objective_complete(),"Exit requires marked middle lane")
 game.player.lane=1
 game.player.y=game.LANES[1]
 game._tick_world(0.01)
 game.run.finish_stage_clear()
 check(game.mode=="interlude" and game.run.story_page==4,"Escape reaches inn and reports")
 check(game.run.choices.size()==3,"One reward prepared at safe rest")
 var hp: float=game.player.hp
 var mana: float=game.run.mana
 game.run.choose(0)
 check(game.run.taken.is_empty(),"No clicking rewards through dialogue")
 forward_page()
 check(game.mode=="reward","Inn dialogue precedes ability selection")
 game.run.show_rewards()
 check(game.player.hp==hp and game.run.mana==mana,"Rest applies once")
 game.run.choose(0)
 check(game.mode=="interlude" and game.run.level==10 and game.run.taken.size()==1,"Choice carries the upgrade into the second level report")
 game.start_game(true)
 check(game.wave==0 and game.mode=="prologue" and not game.run.prologue_seen and not game.run.intro_done and game.run.taken.is_empty(),"Restart resets entire chapter")
 print("ARCHIVE CHAPTER: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

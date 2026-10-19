extends SceneTree
var game
var failures=0
var checks=0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error(label)
func run_checks() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_game()
 game.set_physics_process(false)
 for room in range(1,4):
  game.player.hp=90
  game.run.mana=40
  game.run.intesa=63
  game.enemies.clear()
  game._tick_world(0.01)
  check(game.mode=="interlude","Clear room enters comic")
  check(game.run.interlude_revealed==1,"First balloon appears on entry")
  check(game.run.choices.size()==3,"Rewards prepared behind the comic")
  var hp: float=game.player.hp
  var mana: float=game.run.mana
  var before_time: float=game.encounter_time
  game.run.choose(0)
  check(game.mode=="interlude" and game.run.taken.size()==room-1,"Cannot select a buff through the comic")
  game._physics_process(0.5)
  check(game.run.interlude_revealed==1,"Balloon timing does not reveal everything at once")
  check(game.encounter_time==before_time and game.player.hp==hp and game.run.mana==mana,"Comic freezes combat, cooldowns and resource regen")
  game.help_open=true
  var comic_clock: float=game.run.interlude_elapsed
  game._physics_process(2)
  check(game.run.interlude_elapsed==comic_clock,"Help freezes dialogue reveal too")
  game.help_open=false
  game._physics_process(30.0)
  check(game.run.interlude_revealed==1,"Waiting never advances a balloon")
  game.run.advance_interlude()
  check(game.run.interlude_revealed==2,"Second balloon appears only after input")
  game.run.advance_interlude()
  check(game.run.interlude_revealed==3 and game.mode=="interlude","Manual input reveals final balloon before rewards")
  game.run.advance_interlude()
  check(game.mode=="reward","Completed sequence opens the camp")
  game.run.show_rewards()
  check(game.player.hp==hp and game.run.mana==mana and game.run.intesa==63,"Entering camp does not apply rest twice")
  check(game.overlay.camp_art!=null and game.overlay.comic_art[room-1]!=null,"Illustrated bridge assets exist for every interlude")
  game.run.choose(room%3)
  check(game.mode=="playing" and game.wave==room+1,"Choice starts the next encounter")
 # Skip path still requires a reward choice and retains run state.
 game.start_game()
 game.enemies.clear()
 game._tick_world(0.01)
 game.run.show_rewards()
 check(game.mode=="reward" and game.wave==1 and game.run.taken.is_empty(),"Skip goes to camp, not straight into next room")
 game.start_game()
 check(game.run.interlude_revealed==0 and game.run.interlude_elapsed==0,"Restart resets comic sequence")
 print("INTERLUDE FLOW: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

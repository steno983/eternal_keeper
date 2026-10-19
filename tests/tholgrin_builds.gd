extends SceneTree
var game
var checks=0
var failures=0
func _initialize(): call_deferred("verify")
func check(value,label):
 checks+=1
 if not value:
  failures+=1
  push_error(label)
func fresh():
 game.start_game(true)
 game.run.prologue_seen=true
 game.run.intro_done=true
 game.run.before_seen[0]=true
 game.wave=0
 game.run.begin_room()
 game.run.finish_entrance()
 game.enemies.clear()
 game.pending_actions.clear()
func take(id):
 var item=game.run.UPGRADES.filter(func(u): return u.id==id)[0]
 game.run.choices=[item]
 game.mode="reward"
 game.run.choose(0)
 # Test the chosen passive without waiting for an entire chapter.
 game.mode="playing"
 game.enemies.clear()
 game.player.begin_action(&"",0)
func enemy():
 var e=game.Fighter.new()
 e.kind="raider"
 e.id=900
 e.hp=300
 e.max_hp=300
 e.x=game.player.x+100
 e.lane=game.player.lane
 e.y=game.player.y
 e.previous_x=e.x
 game.enemies.append(e)
 return e
func capture(label):
 if DisplayServer.get_name()=="headless": return
 game._process(0)
 game.painter.queue_redraw()
 game.overlay.queue_redraw()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/build-"+label+".png")
func verify():
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.test_mode=true
 fresh()
 for seed in range(30):
  game.rng.seed=seed
  game.run.prepare_reward()
  check(game.run.choices.map(func(c): return c.path)==["fire","ward","control"],"Every first reward offers all three routes")
  check(game.run.choices.all(func(c): return game.run.mods[c.slot]==""),"Only available skill slots offered")
 await capture("before-choice")
 game.mode="reward"
 await capture("reward-first")
 fresh()
 take("orb")
 check(game.run.path_rank("fire")==1,"First choice activates Braci immediately")
 var e=enemy()
 game.run.apply_spell_traits(e)
 check(e.burn_time==2,"Braci burns for two seconds")
 var combo=game.combo
 game.run.tick(1)
 check(e.hp==297 and game.combo==combo and e.state==game.Fighter.State.APPROACH,"Burn damages without stun or combo farming")
 game.run.tick(1)
 check(e.hp==294 and e.burn_time==0,"Burn deals exactly six damage then expires")
 take("eruption")
 check(game.run.path_rank("fire")==2,"A coherent second choice strengthens the route")
 e=enemy()
 game.run.apply_spell_traits(e)
 check(e.burn_time==4,"Deep Braci doubles burn duration")
 game.run.prepare_reward()
 check(game.run.choices.any(func(c): return c.path=="fire" and c.id=="inferno"),"Continuation stays available on unmodified skills")
 game.mode="reward"
 await capture("reward-continuation")
 fresh()
 take("aegis")
 game.run.cast_slot=2
 game.run.contact()
 check(game.run.barrier==57,"Custode adds twelve barrier to Aegis")
 check(game.run.mitigate(60)==3 and game.run.barrier==0,"Barrier conserves incoming damage on depletion")
 fresh()
 take("sanctuary")
 game.run.cast_slot=2
 game.run.contact()
 check(game.run.barrier==12,"Custode also augments the base ward")
 check(is_equal_approx(game.run.mitigate(20),5.2),"Barrier absorbs before base ward mitigation")
 take("renewal")
 game.run.cast_slot=2
 game.run.contact()
 check(game.run.barrier==24,"Second Custode choice doubles bonus absorption")
 fresh()
 take("ash")
 e=enemy()
 game.run.apply_spell_traits(e)
 check(e.slow_time==1.5 and is_equal_approx(e.slow_factor,0.65),"Sigilli applies a timed 35 percent slow")
 e.x=game.player.x+400
 e.timer=0
 var before: float=e.x
 game._tick_enemy(e,0.1)
 check(is_equal_approx(before-e.x,105*0.65*0.1),"Slow changes actual enemy movement")
 game.run.tick(1.5)
 check(e.slow_time==0,"Slow expires with combat time")
 take("pierce")
 e=enemy()
 game.run.apply_spell_traits(e)
 check(e.slow_time==2.5 and e.slow_factor==0.5,"Second Sigilli choice gives 50 percent for 2.5 seconds")
 fresh()
 take("orb")
 take("ash")
 e=enemy()
 game.run.apply_spell_traits(e)
 check(e.burn_time==2 and e.slow_time==1.5,"Hybrid builds keep both first-rank benefits")
 game.mode="paused"
 game._physics_process(10)
 check(e.burn_time==2 and e.slow_time==1.5,"Pause freezes both statuses")
 game.mode="playing"
 game.run.tick(0.2)
 await capture("hybrid-combat")
 fresh()
 take("orb")
 e=enemy()
 game.run.cast_slot=0
 game.run.contact()
 game._tick_projectiles(0.2)
 check(e.hp<300 and e.burn_time==2,"Real projectile hit applies Braci")
 game.enemies.clear()
 e=enemy()
 game.run.cast_slot=3
 game.run.contact()
 check(e.hp==250 and e.burn_time==2,"Directional holy wave applies Braci")
 game.enemies.clear()
 e=enemy()
 game.run.cast_slot=1
 game.run.contact()
 game.run.tick(0.01)
 check(e.burn_time==2,"Persistent zone pulses apply Braci")
 e.hp=3
 var kills=game.kills
 game.run.tick(1)
 check(e.hp==0 and game.kills==kills+1 and e.state==game.Fighter.State.DEAD,"Burn death is credited exactly once")
 game.run.tick(1)
 check(game.kills==kills+1,"Expired burn cannot kill twice")
 fresh()
 take("fan")
 e=enemy()
 game.run.cast_slot=0
 game.run.contact()
 game._tick_projectiles(0.2)
 check(e.slow_time==1.5,"Real ray hit applies Sigilli")
 fresh()
 check(game.run.taken.is_empty() and game.run.path_rank("fire")==0 and game.run.path_rank("control")==0,"New run clears all route progress")
 print("THOLGRIN BUILDS: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

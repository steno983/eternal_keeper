extends SceneTree
var game
func _initialize() -> void: call_deferred("play")
func capture(label: String) -> void:
 if DisplayServer.get_name()=="headless": return
 game._process(0)
 game.painter.queue_redraw()
 game.overlay.queue_redraw()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/archive-"+label+".png")
func tap(code: Key) -> void:
 var key=InputEventKey.new()
 key.keycode=code
 key.physical_keycode=code
 key.pressed=true
 Input.parse_input_event(key)
 await process_frame
 key=InputEventKey.new()
 key.keycode=code
 key.physical_keycode=code
 key.pressed=false
 Input.parse_input_event(key)
 await process_frame
func play() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.test_mode=true
 game.muted=true
 print("ARCHIVE BOT initialized display=",DisplayServer.get_name())
 await capture("title")
 await tap(KEY_ENTER)
 assert(game.mode=="selection")
 await capture("selection")
 await tap(KEY_ENTER)
 assert(game.mode=="prologue" and game.campaign)
 await capture("prologue-start")
 game._physics_process(8)
 await capture("prologue-middle")
 await tap(KEY_SPACE)
 assert(game.run.prologue_paused)
 var clock: float=game.run.prologue_elapsed
 game._physics_process(2)
 assert(game.run.prologue_elapsed==clock)
 await tap(KEY_SPACE)
 game._physics_process(100)
 await capture("prologue-end")
 assert(game.mode=="prologue" and game.run.prologue_finished)
 await tap(KEY_ENTER)
 assert(game.mode=="interlude" and game.run.story_page==0)
 var reward_attempts=0
 var frames=0
 var seen={}
 var entrances_seen={}
 var carried_slot: int=-1
 var carried_id: String=""
 var mutation_casts: int=0
 while game.mode in ["playing","interlude","reward","level_intro","stage_clear"] and frames<42000:
  if game.mode=="stage_clear":
   game._physics_process(0.45)
   await capture("clear-%d" % game.wave)
   assert(game.mode=="stage_clear")
   game._physics_process(1.3)
   continue
  if game.mode=="level_intro":
   var level: int=game.run.level_number()
   assert(not entrances_seen.has(level),"A level title cannot repeat at each stage")
   entrances_seen[level]=true
   game._physics_process(0.43)
   await capture("entrance-%d-writing" % game.wave)
   game._physics_process(0.8)
   await capture("entrance-%d-hold" % game.wave)
   game._physics_process(0.52)
   await capture("entrance-%d-erasing" % game.wave)
   game._physics_process(0.3)
   assert(game.mode=="playing" and game.run.room_time==0)
   continue
  if game.mode=="interlude":
   var page: int=game.run.story_page
   print("ARCHIVE BOT page=",page," revealed=",game.run.interlude_revealed)
   if game.run.interlude_revealed==1:
    # Native key input, rather than calling reveal, validates actual controls.
    for i in range(2):
     var key=InputEventKey.new()
     key.keycode=KEY_ENTER
     key.physical_keycode=KEY_ENTER
     key.pressed=true
     Input.parse_input_event(key)
     await process_frame
     key=InputEventKey.new()
     key.keycode=KEY_ENTER
     key.physical_keycode=KEY_ENTER
     key.pressed=false
     Input.parse_input_event(key)
     await process_frame
    assert(game.run.interlude_revealed==3)
    await capture("comic-%d" % page)
   game.run.advance_interlude()
   continue
  if game.mode=="reward":
   reward_attempts+=1
   if reward_attempts>3:
    push_error("Native reward click did not complete chapter")
    break
   await capture("inn-reward")
   var choice: int=0
   if game.run.taken.is_empty():
    for i in range(game.run.choices.size()):
     if game.run.choices[i].slot==0: choice=i
    carried_slot=int(game.run.choices[choice].slot)
    carried_id=game.run.choices[choice].id
   if DisplayServer.get_name()=="headless":
    game.run.choose(choice)
    continue
   var mouse=InputEventMouseButton.new()
   mouse.button_index=MOUSE_BUTTON_LEFT
   mouse.pressed=true
   mouse.position=game.reward_rect(choice).get_center()
   Input.parse_input_event(mouse)
   await process_frame
   continue
  if game.run.room_time>2 and not seen.has(game.wave):
   seen[game.wave]=true
   await capture("room-%d" % game.wave)
  if game.run.is_resistance():
   for cue in [[0.1,"first"],[6.1,"crossfire"],[12.1,"runners"],[17.1,"last"]]:
    if game.run.room_time>=cue[0] and not seen.has(cue[1]):
     seen[cue[1]]=true
     await capture("entry-"+cue[1])
  if game.run.is_resistance() and game.run.resistance_remaining()<=5 and not seen.has("last_seconds"):
   seen["last_seconds"]=true
   await capture("resistance-last-seconds")
  if game.wave==3 and game.run.room_time>=0.05 and not seen.has("escape_entry"):
   seen["escape_entry"]=true
   await capture("escape-entry")
  if game.run.level_number()==2:
   assert(game.run.mods[carried_slot]==carried_id)
  for enemy in game.enemies:
   if enemy.alive() and enemy.state==game.Fighter.State.WINDUP and enemy.archetype in ["brute","caster"] and not seen.has("role_"+enemy.archetype):
    seen["role_"+enemy.archetype]=true
    await capture("role-"+enemy.archetype)
  if game.run.current_rule().type=="scrolling" and game.run.road.active and game.living_enemies()>0 and not seen.has("checkpoint_"+str(game.wave)):
   seen["checkpoint_"+str(game.wave)]=true
   await capture("checkpoint-"+str(game.wave))
  if game.run.current_rule().type=="synchronization":
   var cfg: Dictionary=game.run.current_rule().synchronization
   var target=null
   for i in range(cfg.sigils.size()):
    if game.run.synchronization.charge[i]<float(cfg.charge_seconds):
     target=cfg.sigils[i]
     break
   if target==null:
    target=game.run.current_rule().exit.duplicate()
    target.lane=maxi(0,int(target.lane))
   if target!=null:
    var lane: int=target.lane
    if game.run.synchronization.warning(cfg,game.run.room_time) and lane==game.run.synchronization.pulse_lane(cfg,game.run.room_time): lane=(lane+1)%3
    if game.player.lane!=lane: game.change_lane(signi(lane-game.player.lane))
    game.player.moving=true
    if not game.player.action_active(): game.player.x=move_toward(game.player.x,float(target.x),240.0/60)
   if not game.player.action_active():
    if game.run.skill_cd[2]<=0: game.run.cast(2)
    elif game.run.skill_cd[3]<=0: game.run.cast(3)
  elif game.wave==3:
   if game.player.lane!=1: game.change_lane(signi(1-game.player.lane))
   game.player.facing=1
   game.player.moving=true
   if not game.player.action_active(): game.player.x+=240.0/60
   if game.dash_cd<=0: game.dodge()
  else:
   var closest=null
   var best=INF
   for enemy in game.enemies:
    if enemy.alive():
     var score=absf(enemy.x-game.player.x)+absf(enemy.lane-game.player.lane)*100
     if score<best: closest=enemy; best=score
   if closest==null and game.run.current_rule().type=="scrolling" and not game.run.road.active:
    game.player.facing=1
    game.player.moving=true
    if game.dash_time<=0 and not game.player.action_active(): game.player.x+=240.0/60
   if closest!=null and game.hit_stop<=0:
    var dx: float=closest.x-game.player.x
    if closest.lane!=game.player.lane: game.change_lane(signi(closest.lane-game.player.lane))
    if absf(dx)>8: game.player.facing=signf(dx)
    if not game.player.action_active() and game.dash_time<=0:
     if game.run.level_number()==2 and game.run.skill_cd[carried_slot]<=0 and game.run.mana>=game.run.cost(carried_slot):
      if game.run.cast(carried_slot): mutation_casts+=1
     elif game.run.intesa>=60: game.run.call_allies()
     elif game.run.skill_cd[2]<=0 and (game.player.hp<125 or game.run.mana<35): game.run.cast(2)
     elif game.run.skill_cd[3]<=0 and absf(dx)<550: game.run.cast(3)
     elif game.run.skill_cd[1]<=0 and absf(dx)<350: game.run.cast(1)
     elif absf(dx)<115 and game.run.mana<45: game.attack()
     elif absf(dx)<750: game.run.cast(0)
     if absf(dx)>400 or game.run.mana<12 and absf(dx)>85: game.player.x+=signf(dx)*240.0/60
     elif absf(dx)<160 and game.run.mana>=12: game.player.x-=signf(dx)*240.0/60
    if game.run.is_resistance(): game.player.x=game.run.horizontal_anchor()
   
  game._physics_process(1.0/60)
  frames+=1
  if frames%300==0:
   print("ARCHIVE BOT room=",game.wave," progress=",game.run.objective_time," hp=",game.player.hp)
   await process_frame
 print("ARCHIVE PLAYTHROUGH: mode=%s room=%d hp=%.0f kills=%d combat=%.1fs upgrades=%d" % [game.mode,game.wave,game.player.hp,game.kills,frames/60.0,game.run.taken.size()])
 await capture("ending")
 var passed=game.mode=="victory" and game.run.taken.size()==2 and mutation_casts>0 and entrances_seen.size()==game.run.content.groups.size()
 await tap(KEY_ESCAPE)
 passed=passed and game.mode=="title"
 await tap(KEY_B)
 passed=passed and game.mode=="playing" and not game.campaign
 print("CARRIED MUTATION: %s cast %d times in level two" % [carried_id,mutation_casts])
 print("ARCHIVE NATIVE INPUT: title, selection, manual balloons, reward click, return and bridge shortcut passed=",passed)
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(0 if passed else 1)

extends SceneTree
var game
func _initialize() -> void: call_deferred("run_bot")
func run_bot() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 var failures=0
 for trial in range(3):
  game.start_game()
  game.rng.seed=120+trial
  game.set_physics_process(false)
  game.test_mode=true
  game.muted=true
  var frames=0
  var calls=0
  while game.mode in ["playing","interlude","reward"] and frames<21600:
   if game.mode=="interlude":
    game.run.advance_interlude()
    continue
   if game.mode=="reward":
    game.run.choose(trial%3)
    continue
   var closest=null
   var best=INF
   for e in game.enemies:
    if e.alive():
     var score=absf(e.x-game.player.x)+absf(e.lane-game.player.lane)*100
     if score<best: closest=e; best=score
   if closest!=null and game.hit_stop<=0:
    var dx: float=closest.x-game.player.x
    if closest.lane!=game.player.lane: game.change_lane(signi(closest.lane-game.player.lane))
    if absf(dx)>8: game.player.facing=signf(dx)
    var danger=false
    for e in game.enemies:
     if e.alive() and e.state==game.Fighter.State.WINDUP and e.action_elapsed>e.action_length*0.60 and absf(e.x-game.player.x)<225 and abs(e.lane-game.player.lane)<=1:
      danger=true
    if danger and game.dash_cd<=0:
     game.player.facing=-signf(dx)
     game.dodge()
    if not game.player.action_active() and game.dash_time<=0:
     if game.run.intesa>=100 and best<600:
      if game.run.call_allies(): calls+=1
     elif game.run.skill_cd[2]<=0 and (game.player.hp<125 or game.run.mana<38): game.run.cast(2)
     elif game.run.skill_cd[3]<=0 and absf(dx)<550: game.run.cast(3)
     elif game.run.skill_cd[1]<=0 and absf(dx)<350: game.run.cast(1)
     elif absf(dx)<115 and game.run.mana<45: game.attack()
     elif absf(dx)<750 and closest.lane==game.player.lane: game.run.cast(0)
     if absf(dx)>400 or game.run.mana<12 and absf(dx)>85:
      game.player.x+=signf(dx)*240.0/60.0
      game.player.moving=true
     elif absf(dx)<175 and game.run.mana>=12:
      game.player.x-=signf(dx)*240.0/60.0
      game.player.moving=true
     else: game.player.moving=false
   game._physics_process(1.0/60)
   frames+=1
   if frames%300==0: await process_frame
  print("RUN BOT seed=%d mode=%s room=%d kills=%d hp=%.0f time=%.1f allies=%d upgrades=%s" % [120+trial,game.mode,game.wave,game.kills,game.player.hp,frames/60.0,calls,str(game.run.mods)])
  if game.mode!="victory" or game.run.taken.size()!=3: failures+=1
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

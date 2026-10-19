extends SceneTree
var game
var checks=0
var failures=0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, label: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error(label)
func fresh() -> void:
 game.start_game()
 game.set_physics_process(false)
 game.test_mode=true
 game.muted=true
 game.enemies.clear()
func enemy(x: float, lane: int, hp: float=300):
 var e=game.Fighter.new()
 e.id=game.enemy_serial
 game.enemy_serial+=1
 e.x=x
 e.previous_x=x
 e.lane=lane
 e.y=game.LANES[lane]
 e.hp=hp
 e.max_hp=hp
 game.enemies.append(e)
 return e
func cast(slot: int) -> void:
 check(game.run.cast(slot),"Skill %d accepted" % slot)
 game.player.tick_visuals(0.21)
 game._resolve_actions()
func run_checks() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 fresh()
 check(game.wave==1 and game.player.hero==0,"Run starts with Tholgrin")
 game.switch_hero(1)
 check(game.player.hero==0,"Protagonist stays fixed")
 game.run.mana=0
 var e=enemy(game.player.x+60,1)
 game.attack()
 game.player.tick_visuals(0.17)
 game._resolve_actions()
 check(game.run.mana==10 and e.hp<300,"Melee restores mana on contact")
 fresh()
 game.run.mana=0
 check(not game.run.cast(0) and game.run.skill_cd[0]==0,"Insufficient mana does not consume cooldown")
 fresh()
 cast(0)
 check(game.projectiles.size()==1 and game.run.mana==92,"Bolt cost and spawn")
 check(not game.run.cast(0),"Cooldown/recovery prevents spam")
 fresh()
 game.run.mods[0]="orb"
 e=enemy(410,1)
 var neighbor=enemy(450,1)
 cast(0)
 game._tick_projectiles(0.1)
 check(e.hp==276 and neighbor.hp==282,"Orb damages primary and nearby target")
 fresh()
 game.run.mods[0]="pierce"
 e=enemy(360,1)
 var second=enemy(390,1)
 var third=enemy(420,1)
 cast(0)
 game._tick_projectiles(0.1)
 game._tick_projectiles(0.01)
 check(e.hp==266 and second.hp==266 and third.hp==266,"Piercing bolt hits three unique targets once")
 fresh()
 game.run.mods[0]="fan"
 cast(0)
 check(game.projectiles.size()==3 and game.run.mana==88,"Fan changes lanes and cost")
 fresh()
 e=enemy(510,1)
 cast(1)
 game.run.tick(0.1)
 check(game.run.zones.size()==1 and e.hp==289,"Sigil pulses damage")
 fresh()
 game.run.mods[1]="ash"
 cast(1)
 check(game.run.zones[0].radius==185 and game.run.zones[0].life==5,"Ash changes radius and lifetime")
 fresh()
 game.run.mods[1]="sanctuary"
 game.player.hp=100
 cast(1)
 game.player.x=510
 game.run.tick(0.5)
 check(game.player.hp==104,"Sanctuary heals inside zone")
 fresh()
 game.run.mods[1]="eruption"
 e=enemy(510,1)
 cast(1)
 check(e.hp==225 and game.run.zones.is_empty(),"Eruption replaces persistent zone with burst")
 fresh()
 cast(2)
 check(is_equal_approx(game.run.mitigate(20),13),"Blessing reduces damage by 35 percent")
 fresh()
 game.run.mods[2]="aegis"
 cast(2)
 check(game.run.mitigate(30)==0 and game.run.barrier==15,"Aegis absorbs first hit")
 check(game.run.mitigate(30)==15 and game.run.barrier==0,"Aegis depletion passes remaining damage")
 fresh()
 game.run.mods[2]="renewal"
 game.player.hp=100
 cast(2)
 game.run.tick(1)
 check(game.player.hp==104,"Renewal heals over time")
 fresh()
 game.run.mods[2]="mirror"
 e=enemy(360,1)
 cast(2)
 game.run.mitigate(20)
 check(e.hp==280,"Mirror retaliates")
 for modification in ["","judgment","inferno","nova"]:
  fresh()
  game.run.mods[3]=modification
  e=enemy(400,1)
  var other_lane=enemy(400,0)
  cast(3)
  check(e.hp<300,"Super deals damage: "+modification)
  check((other_lane.hp<300)==(modification in ["judgment","nova"]),"Super lane behavior: "+modification)
  if modification=="inferno": check(game.run.zones.size()==3,"Inferno leaves three zones")
 fresh()
 game.run.intesa=59
 check(not game.run.call_allies(),"Ally attack requires charge")
 for charge in [60.0,100.0]:
  fresh()
  game.run.intesa=charge
  e=enemy(500,1)
  var other_lane=enemy(500,0)
  check(game.run.call_allies(),"Ally attack activates")
  game.run.tick_allies(0.7)
  check(game.run.intesa==0,"Allies cannot refill their own gauge")
  check(e.hp==135 if charge==100 else e.hp==220,"Combined attack damage")
  check((other_lane.hp<300)==(charge==100),"Trio covers all lanes; duo covers current lane")
 fresh()
 game.run.intesa=45
 for room in range(1,4):
  game.enemies.clear()
  game._tick_world(0.01)
  check(game.mode=="interlude","A comic precedes every reward")
  game.run.show_rewards()
  check(game.mode=="reward" and game.run.choices.size()==3,"Room offers three rewards")
  var choices=game.run.choices
  check(choices[0].id!=choices[1].id and choices[1].id!=choices[2].id and choices[0].id!=choices[2].id,"Reward choices are distinct")
  var elapsed: float=game.encounter_time
  game._physics_process(1)
  check(game.encounter_time==elapsed,"Reward screen freezes combat")
  game.run.choose(0)
  check(game.mode=="playing" and game.wave==room+1,"Reward starts next room")
  check(game.run.taken.size()==room and game.run.intesa==45,"Build and Intesa persist")
 check(game.enemies.any(func(e): return e.kind=="warden"),"Boss only after three rewards")
 game.enemies.clear()
 game._tick_world(0.01)
 check(game.mode=="victory","Boss clear completes run")
 fresh()
 game.player.hp=5
 game.player.invincible=0
 game.damage_player(50,1)
 check(game.mode=="defeat" and game.player.hero==0,"Single life: no automatic party swap")
 game.start_game()
 check(game.run.taken.is_empty() and game.run.intesa==0 and game.run.mana==100 and game.player.hp==160,"Restart resets build, resources and health")
 print("RUN RULES: %d/%d passed" % [checks-failures,checks])
 game.shutdown_audio()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)

extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func fresh(hero: int=0) -> void:
	game.start_game()
	game.set_physics_process(false)
	game.enemies.clear()
	game.player.hero=hero
	game.player.hp=game.HEROES[hero].hp
	game.player.max_hp=game.player.hp
func target(kind: String="raider"):
	var enemy=game.Fighter.new()
	enemy.kind=kind
	enemy.x=game.player.x+70
	enemy.y=game.player.y
	enemy.lane=game.player.lane
	enemy.hp=1000
	enemy.max_hp=1000
	game.enemies.append(enemy)
	return enemy
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	for hero in range(3):
		fresh(hero)
		var enemy=target()
		for step in range(3):
			check(game.attack(),"Combo attack accepted")
			check(game.player.combo_step==step,"Combo progresses independently of hit count")
			game.player.tick_visuals(game.ATTACK_LENGTH[hero]*0.83)
			game._resolve_actions()
			if step==2:
				check(enemy.knockback==250,"Third strike is a heavy finisher")
		check(enemy.hp<1000-game.HEROES[hero].damage*3,"Finisher deals additional damage")
		game.player.action=&""
		game.attack_cd=0
		game.chain_timer=0
		game.attack()
		check(game.player.combo_step==0,"Expired combo restarts at first strike")
	for incoming in range(3):
		fresh((incoming+1)%3)
		var enemy=target()
		game.attack()
		game.player.tick_visuals(game.ATTACK_LENGTH[game.player.hero]*game.CONTACT_PHASE[game.player.hero])
		game._resolve_actions()
		game.switch_hero(incoming)
		check(game.relay_entry and game.relay_cd>0,"Successful hit opens relay entry")
		game.player.tick_visuals(0.12)
		game._resolve_actions()
		check(enemy.hp<970,"Incoming relay hits once with enhanced damage")
		if incoming==0:
			check(game.player.invincible>=0.5 and enemy.state==game.Fighter.State.STUN,"Cleric relay guards and staggers")
		elif incoming==1:
			check(game.player.x>220,"Rogue relay advances into the fight")
		else:
			check(not game.echo.is_empty() and game.echo_time==2,"Knight relay manifests a short echo")
	fresh()
	var boss=target("warden")
	boss.state=game.Fighter.State.WINDUP
	boss.begin_action(&"windup",1.05)
	game.damage_enemy(boss,10,1,Color.WHITE)
	check(boss.state==game.Fighter.State.WINDUP,"Boss withstands one light hit")
	game.damage_enemy(boss,10,1,Color.WHITE,true)
	check(boss.state==game.Fighter.State.STUN,"Heavy finisher interrupts boss")
	boss.state=game.Fighter.State.WINDUP
	boss.begin_action(&"windup",1.05)
	game.damage_enemy(boss,10,1,Color.WHITE,true)
	check(boss.state==game.Fighter.State.WINDUP,"Boss cannot be stun-locked immediately after stagger")
	fresh()
	boss=target("warden")
	boss.facing=-1
	boss.attack_variant=1
	boss.lane=0
	boss.y=game.LANES[0]
	var hp=game.player.hp
	game._enemy_contact(boss,-1)
	check(game.player.hp<hp,"Boss sweep reaches announced adjacent lane")
	game.player.invincible=0.3
	hp=game.player.hp
	game._enemy_contact(boss,-1)
	check(game.player.hp==hp,"Dodge avoids boss sweep")
	fresh()
	for i in range(3):
		var enemy=target()
		enemy.timer=0
		game._tick_enemy(enemy,0.02)
	var committing=0
	for enemy in game.enemies:
		if enemy.state==game.Fighter.State.WINDUP:
			committing+=1
	check(committing==2,"At most two enemies commit simultaneously")
	fresh()
	var archer=target("archer")
	archer.x=game.stage_left+11
	game.player.x=archer.x+40
	archer.timer=0
	game._tick_enemy(archer,0.5)
	check(archer.x>=game.stage_left,"Retreating archer remains inside arena")
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	print("COMBAT DEPTH: %d/%d passed" % [checks-failures,checks])
	quit(0 if failures==0 else 1)

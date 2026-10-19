extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hero="):
			game.player.hero=clampi(int(arg.trim_prefix("--hero=")),0,2)
			game.player.hp=game.HEROES[game.player.hero].hp
			game.player.max_hp=game.player.hp
	game.test_mode=true
	game.muted=true
	var dt=1.0/60.0
	var frames=0
	var dodges=0
	var switches=0
	while game.mode=="playing" and frames<18000:
		if game.hit_stop<=0:
			if game.player.hp<40 and game.swap_cd<=0:
				var best=game.player.hero
				for i in range(3):
					if game.health[i]>game.health[best]:
						best=i
				if best!=game.player.hero:
					game.switch_hero(best)
					switches+=1
			var closest=null
			var distance=INF
			for enemy in game.enemies:
				if enemy.alive():
					var score=absf(enemy.x-game.player.x)+absf(enemy.lane-game.player.lane)*80
					if score<distance:
						distance=score
						closest=enemy
			if closest!=null:
				if closest.lane!=game.player.lane:
					game.change_lane(signi(closest.lane-game.player.lane))
				var dx=closest.x-game.player.x
				game.player.facing=signf(dx) if absf(dx)>4 else game.player.facing
				if absf(dx)>90 and game.dash_time<=0 and not game.player.action_active():
					game.player.x+=signf(dx)*game.HEROES[game.player.hero].speed*dt
					game.player.moving=true
				else:
					game.player.moving=false
				if closest.state==game.Fighter.State.WINDUP and closest.action_elapsed>closest.action_length*0.65 and absf(dx)<180 and game.dash_cd<=0:
					game.dodge()
					dodges+=1
				if game.cooldowns[game.player.hero]<=0 and absf(dx)<300 and not game.player.action_active():
					game.special()
				if absf(dx)<125:
					game.attack()
			else:
				game.player.x+=game.HEROES[game.player.hero].speed*dt
		game._physics_process(dt)
		frames+=1
		if frames%120==0:
			await process_frame
	print("PLAYTHROUGH: mode=%s time=%.1fs wave=%d kills=%d dodges=%d swaps=%d hp=%s" % [game.mode,frames/60.0,game.wave,game.kills,dodges,switches,str(game.health)])
	var success=game.mode=="victory" and game.kills==14
	game.shutdown_audio()
	game.queue_free()
	await process_frame
	quit(0 if success else 1)

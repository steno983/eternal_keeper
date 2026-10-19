extends RefCounted
## One life, three reward rooms and a final boss. All clocks advance with combat.
const Texts=preload("res://scripts/text_data.gd")
var Story=preload("res://scripts/interlude_story.gd").new()
var interlude_revealed: int=0
var interlude_elapsed: float=0.0
var game
var intesa: float=0.0
var assist: Dictionary={}
var assist_damage: bool=false
var mana: float=100.0
var skill_cd: Array[float]=[0.0,0.0,0.0,0.0]
var skill_cd_total: Array[float]=[0.65,5.0,9.0,10.0]
var level: int=9
var mods: Array[String]=["","","",""]
var choices: Array=[]
var taken: Array=[]
var zones: Array=[]
var buff_time: float=0.0
var buff_duration: float=0.0
var barrier: float=0.0
var cast_slot: int=-1
var notice: String=""
var notice_time: float=0.0
var seed_value: int=0
var ROOM_NAMES: Array=[]
const DART_HEIGHT=125.0
const KEYS=["K","L","U","I"]
var BASE_NAMES: Array=[]
const COSTS=[8.0,24.0,18.0,36.0]
const COOLDOWNS=[0.65,5.0,9.0,10.0]
var UPGRADES: Array=[]

func reset() -> void:
 var text_data=Texts.table("abilita")
 ROOM_NAMES=text_data.bridge_rooms
 BASE_NAMES=text_data.spell_names
 UPGRADES=text_data.upgrades.duplicate(true)
 for item in UPGRADES: item.slot=int(item.slot)
 Story.reload()
 interlude_revealed=0
 interlude_elapsed=0.0
 intesa=0.0
 assist.clear()
 assist_damage=false
 mana=100.0
 level=9
 skill_cd.assign([0.0,0.0,0.0,0.0])
 skill_cd_total.assign(COOLDOWNS)
 mods.assign(["","","",""])
 taken.clear()
 choices.clear()
 zones.clear()
 buff_time=0.0
 buff_duration=0.0
 barrier=0.0
 cast_slot=-1
 notice=""
 notice_time=0.0
 seed_value=randi_range(1000,999999)
 game.rng.seed=seed_value

# Official spell names remain visible; run mutations are listed separately.
func skill_name(slot: int) -> String:
 return Texts.ui("raggio_rovente") if slot==0 and mods[0]=="fan" else BASE_NAMES[slot]

func mutation_name(slot: int) -> String:
 for upgrade in UPGRADES:
  if upgrade.id==mods[slot]: return upgrade.name
 return ""

func path_rank(path: String) -> int:
 return mini(2,taken.filter(func(item): return item.get("path","")==path).size())

func path_data(path: String) -> Dictionary:
 return Texts.table("abilita").build_paths[path]

func path_trait(path: String, rank: int) -> String:
 var data=path_data(path)
 var values={}
 for key in ["duration","barrier","slow"]:
  if data.has(key):
   var value=float(data[key][clampi(rank-1,0,1)])
   values[key]=str(int(value)) if is_equal_approx(value,float(int(value))) else str(value)
 return data.trait.format(values)

func path_summary() -> String:
 var labels=[]
 for path in ["fire","ward","control"]:
  var rank=path_rank(path)
  if rank>0: labels.append(path_data(path).name+" "+str(rank)+"/2")
 return Texts.ui("build_none") if labels.is_empty() else " · ".join(labels)

func apply_spell_traits(enemy) -> void:
 if not enemy.alive() or enemy.entering: return
 var fire=path_rank("fire")
 if fire>0:
  enemy.burn_time=float(path_data("fire").duration[fire-1])
  if enemy.burn_tick<=0: enemy.burn_tick=1.0
 var control=path_rank("control")
 if control>0:
  enemy.slow_time=float(path_data("control").duration[control-1])
  enemy.slow_factor=1.0-float(path_data("control").slow[control-1])/100.0

func spell_strike(origin: float, lane: int, facing: float, reach: float, amount: float, color: Color) -> void:
 for enemy in game.enemies:
  if enemy.alive() and enemy.lane==lane and (enemy.x-origin)*facing>=-35 and (enemy.x-origin)*facing<=reach:
   game.damage_enemy(enemy,amount,facing,color,true)
   apply_spell_traits(enemy)

func cooldown_for(slot: int, variant: String="current", at_level: int=-1, with_blessing: bool=true) -> float:
 var chosen=mods[slot] if variant=="current" else variant
 var lv=level if at_level<0 else at_level
 var multiplier={"orb":1.35,"pierce":1.20,"fan":1.50,"ash":1.15,"sanctuary":1.25,"eruption":1.35,"mirror":1.10,"renewal":1.15,"aegis":1.25,"judgment":1.35,"inferno":1.25,"nova":1.40}.get(chosen,1.0)
 var blessing=0.88 if with_blessing and slot!=2 and buff_time>0 and mods[2]!="aegis" else 1.0
 return maxf(0.3,COOLDOWNS[slot]*maxf(0.55,1.0-(lv-9)*0.06)*multiplier*blessing)

func cooldown_progress(slot: int) -> float:
 if skill_cd[slot]<=0: return 1.0
 return clampf(1.0-skill_cd[slot]/maxf(skill_cd_total[slot],0.001),0.0,1.0)

func skill_description(slot: int) -> String:
 var description: String=Texts.table("abilita").spell_descriptions[slot]
 for upgrade in UPGRADES:
  if upgrade.id==mods[slot]: description=upgrade.name+": "+upgrade.desc
 return description+Texts.ui("d_mana_2f_s") % [int(cost(slot)),cooldown_for(slot)]

func cost(slot: int) -> float:
 return 12.0 if slot==0 and mods[0]=="fan" else COSTS[slot]

func skill_hint(slot: int) -> String:
 if skill_cd[slot]>0: return Texts.ui("1f_s") % skill_cd[slot]
 return Texts.ui("d_mana") % int(cost(slot))

func cast(slot: int) -> bool:
 if game.mode!="playing" or not game.player.alive() or game.dash_time>0 or game.player.action_active(): return false
 if skill_cd[slot]>0: return false
 if mana<cost(slot):
  notice=Texts.ui("mana_insufficiente_la_mazza_ne_recupera_10")
  notice_time=1.4
  return false
 mana-=cost(slot)
 skill_cd_total[slot]=cooldown_for(slot)
 skill_cd[slot]=skill_cd_total[slot]
 cast_slot=slot
 var duration=0.32 if slot==0 else 0.50
 game.player.begin_action(&"ranged" if slot==0 else &"special",duration)
 game._schedule("run_spell",game.player,0.12 if slot==0 else 0.20)
 game.effects.append({"kind":"spell_cast","slot":slot,"serial":game.player.action_serial,"x":game.player.x+game.player.facing*42,"y":game.player.y-(DART_HEIGHT if slot==0 else 83.0),"life":0.23,"max":0.23})
 if slot==3:
  game.super_banner={"hero":0,"life":1.65,"max":1.65,"name":skill_name(3)}
 game.sound("bolt" if slot==0 else "fire" if slot in [1,3] else "switch")
 return true

func contact() -> void:
 var p=game.player
 var col: Color=game.HEROES[0].color
 match cast_slot:
  0:
   var lanes=[0,1,2] if mods[0]=="fan" else [p.lane]
   for lane in lanes:
    game.shoot(p.x+p.facing*45,lane,p.facing,false,34.0 if mods[0]=="pierce" else 20.0 if mods[0]=="fan" else 24.0,col)
    var bolt: Dictionary=game.projectiles.back()
    bolt["y"]=game.LANES[lane]-DART_HEIGHT
    bolt["spell"]=mods[0]
    bolt["pierces"]=3 if mods[0]=="pierce" else 1
    bolt["hit_ids"]=[]
  1:
   var x=clampf(p.x+p.facing*210,game.stage_left+30,game.stage_right-30)
   if mods[1]=="eruption":
    area_damage(x,p.lane,190,75,true)
    game.effects.append({"kind":"eruption","x":x,"y":game.LANES[p.lane],"life":0.75,"max":0.75,"radius":190.0})
   else:
    add_zone(x,p.lane,185 if mods[1]=="ash" else 135,5.0 if mods[1]=="ash" else 3.0,mods[1]=="sanctuary",mods[1])
  2:
   buff_time=8.0 if mods[2]=="aegis" else 5.0
   buff_duration=buff_time
   barrier=(45.0 if mods[2]=="aegis" else 0.0)+(float(path_data("ward").barrier[path_rank("ward")-1]) if path_rank("ward")>0 else 0.0)
   game.effects.append({"kind":"ward_hit","x":p.x,"y":p.y-85,"life":0.4,"max":0.4,"radius":12.0,"variant":mods[2]})
  3:
   if mods[3]=="nova":
    for lane in range(3): area_damage(p.x,lane,320,70,true)
    game.effects.append({"kind":"nova","x":p.x,"y":game.LANES[p.lane],"life":0.85,"max":0.85,"radius":320.0})
   else:
    for lane in ([0,1,2] if mods[3]=="judgment" else [p.lane]):
     spell_strike(p.x,lane,p.facing,620,45 if mods[3]=="judgment" else 50,col)
     game.effects.append({"kind":"holy_wave","x":p.x,"y":game.LANES[lane],"facing":p.facing,"reach":620.0,"life":0.85,"max":0.85})
    if mods[3]=="inferno":
     for i in range(3): add_zone(clampf(p.x+p.facing*(100+i*170),game.stage_left,game.stage_right),p.lane,105,4.0,false,"inferno")
   game.trauma=0.35
 cast_slot=-1

func area_damage(x: float, lane: int, radius: float, amount: float, heavy: bool=false) -> void:
 for enemy in game.enemies:
  if enemy.alive() and enemy.lane==lane and absf(enemy.x-x)<=radius:
   game.damage_enemy(enemy,amount,signf(enemy.x-x),game.HEROES[0].color,heavy)
   apply_spell_traits(enemy)

func add_zone(x: float, lane: int, radius: float, duration: float, healing: bool, variant: String="") -> void:
 zones.append({"x":x,"lane":lane,"radius":radius,"life":duration,"max":duration,"pulse":0.0,"healing":healing,"variant":variant})

func projectile_hit(bolt: Dictionary, enemy) -> void:
 if bolt.has("spell"): apply_spell_traits(enemy)
 if bolt.has("spell"):
  game.effects.append({"kind":"fire_hit","x":enemy.x,"y":enemy.y-65,"life":0.32,"max":0.32,"radius":115.0 if bolt.spell=="orb" else 32.0})
 if bolt.has("hit_ids"):
  bolt.hit_ids.append(enemy.id)
 if bolt.get("spell","")=="orb":
  for other in game.enemies:
   if other!=enemy and other.alive() and other.lane==enemy.lane and absf(other.x-enemy.x)<115:
    game.damage_enemy(other,18,signf(bolt.vx),bolt.color,true)
    apply_spell_traits(other)
  game.effects.append({"kind":"impact","x":enemy.x,"y":enemy.y-65,"life":0.3,"max":0.3,"color":bolt.color,"heavy":true,"seed":7.0})
 bolt["pierces"]=bolt.get("pierces",1)-1
 if bolt.pierces<=0: bolt.life=0.0

func tick(dt: float) -> void:
 tick_allies(dt)
 for enemy in game.enemies:
  if not enemy.alive(): continue
  enemy.slow_time=maxf(0,enemy.slow_time-dt)
  var burning_dt=minf(dt,enemy.burn_time)
  enemy.burn_time=maxf(0,enemy.burn_time-dt)
  if burning_dt>0:
   enemy.burn_tick-=burning_dt
   while enemy.burn_tick<=0 and enemy.alive():
    enemy.burn_tick+=1.0
    game.damage_enemy(enemy,3,0,Color("b94824"),false,true)
 notice_time=maxf(0,notice_time-dt)
 for i in range(4): skill_cd[i]=maxf(0,skill_cd[i]-dt)
 mana=minf(100,mana+dt*(11.0 if buff_time>0 and mods[2]!="aegis" else 5.0))
 if buff_time>0:
  if mods[2]=="renewal": game.player.hp=minf(game.player.max_hp,game.player.hp+4*minf(dt,buff_time))
  buff_time=maxf(0,buff_time-dt)
  if buff_time<=0: barrier=0.0
 for zone in zones:
  var active_dt=minf(dt,zone.life)
  zone.life-=dt
  zone.pulse-=dt
  if zone.pulse<=0:
   zone.pulse+=0.5
   area_damage(zone.x,zone.lane,zone.radius,11)
  if zone.healing and game.player.lane==zone.lane and absf(game.player.x-zone.x)<=zone.radius:
   game.player.hp=minf(game.player.max_hp,game.player.hp+8*active_dt)
 zones=zones.filter(func(zone): return zone.life>0)
 game.health[0]=game.player.hp

func mitigate(amount: float) -> float:
 if buff_time<=0: return amount
 if mods[2]!="aegis" or barrier>0:
  game.effects.append({"kind":"ward_hit","x":game.player.x,"y":game.player.y-85,"life":0.32,"max":0.32,"radius":100.0 if mods[2]=="mirror" else 20.0,"variant":mods[2]})
 var absorbed=minf(barrier,amount)
 barrier-=absorbed
 amount-=absorbed
 if mods[2]=="aegis": return amount
 if mods[2]=="mirror":
  for lane in range(3): area_damage(game.player.x,lane,180,20)
 return amount*0.65

func finish_room() -> void:
 game.wave_active=false
 game.pending_actions.clear()
 game.projectiles.clear()
 assist.clear()
 zones.clear()
 game.super_banner.clear()
 if game.wave==4:
  game.mode="victory"
  return
 game.mode="interlude"
 interlude_revealed=1
 interlude_elapsed=0.0
 prepare_reward()

func prepare_reward(heal: float=20,restore_mana: float=30,choice_count: int=3) -> void:
 game.player.hp=minf(game.player.max_hp,game.player.hp+heal)
 game.health[0]=game.player.hp
 mana=minf(100,mana+restore_mana)
 choices.clear()
 var pool=UPGRADES.filter(func(upgrade): return mods[upgrade.slot]=="")
 # Offer a real route choice, including a continuation of the current route.
 for path in ["fire","ward","control"]:
  var candidates=pool.filter(func(upgrade): return upgrade.path==path)
  if not candidates.is_empty() and choices.size()<choice_count:
   choices.append(candidates[game.rng.randi_range(0,candidates.size()-1)])
 while choices.size()<choice_count:
  var remaining=pool.filter(func(upgrade): return not choices.has(upgrade))
  if remaining.is_empty(): break
  choices.append(remaining[game.rng.randi_range(0,remaining.size()-1)])

func tick_interlude(dt: float) -> void:
 if game.mode!="interlude": return
 interlude_elapsed+=dt
 # Speech balloons advance exclusively through advance_interlude().

func advance_interlude() -> void:
 if game.mode!="interlude": return
 if interlude_revealed<Story.page(game.wave).size():
  interlude_revealed+=1
 else:
  show_rewards()

func show_rewards() -> void:
 if game.mode!="interlude": return
 interlude_revealed=3
 game.reward_cursor=0
 game.mode="reward"

func choose(index: int) -> void:
 if game.mode!="reward" or index<0 or index>=choices.size(): return
 var upgrade: Dictionary=choices[index]
 mods[upgrade.slot]=upgrade.id
 taken.append(upgrade)
 level+=1
 choices.clear()
 begin_room()

func begin_room() -> void:
 game.wave+=1
 game.wave_active=true
 game.wave_banner=2.5
 game.mode="playing"
 game.enemies.clear()
 game.pending_actions.clear()
 game.projectiles.clear()
 game.effects.clear()
 zones.clear()
 skill_cd.assign([0.0,0.0,0.0,0.0])
 cast_slot=-1
 buff_time=0.0
 buff_duration=0.0
 barrier=0.0
 game.combo=0
 game.combo_time=0
 game.stage_left=70.0
 game.stage_right=1420.0
 game.player.x=300
 game.player.previous_x=300
 game.player.lane=1
 game.player.y=game.LANES[1]
 game.player.facing=1
 game.player.begin_action(&"",0)
 game.player.knockback=0
 game.player.invincible=0.8
 game.dash_time=0
 game.dash_cd=0
 game.attack_cd=0
 game.input_buffer=0
 game.camera_x=0
 spawn_encounter()

func spawn_encounter() -> void:
 var count=[3,4,5,3][game.wave-1]
 for i in range(count):
  var enemy=game.Fighter.new()
  enemy.id=game.enemy_serial
  game.enemy_serial+=1
  enemy.kind="warden" if game.wave==4 and i==0 else "archer" if (i+game.wave)%3==0 else "raider"
  enemy.max_hp=360.0 if enemy.kind=="warden" else 42.0+game.wave*8 if enemy.kind=="archer" else 50.0+game.wave*8
  enemy.hp=enemy.max_hp
  enemy.x=780+(i%3)*155
  enemy.previous_x=enemy.x
  enemy.lane=(i+game.wave-1)%3
  enemy.y=game.LANES[enemy.lane]
  enemy.timer=0.8+i*0.20
  enemy.phase=i*1.9
  enemy.facing=-1
  game.enemies.append(enemy)

func call_allies() -> bool:
 if game.mode!="playing" or intesa<60 or not assist.is_empty() or game.player.action_active() or game.dash_time>0: return false
 var level=2 if intesa>=100 else 1
 intesa=0.0
 assist={"elapsed":0.0,"level":level,"layla":false,"lupinor":false,"fire":false,"x":game.player.x,"lane":game.player.lane,"facing":game.player.facing}
 game.player.begin_action(&"special",0.8)
 game.player.invincible=1.0
 game.super_banner={"hero":0,"life":1.65,"max":1.65,"name":Texts.ui("patto_delle_tre_voci") if level==2 else Texts.ui("lame_e_braci")}
 game.effects.append({"kind":"ally","hero":1,"x":clampf(game.player.x+game.player.facing*170,game.stage_left+80,game.stage_right-80),"y":game.player.y,"facing":game.player.facing,"life":0.85,"max":0.85})
 if level==2:
  game.effects.append({"kind":"ally","hero":2,"x":clampf(game.player.x+game.player.facing*300,game.stage_left+80,game.stage_right-80),"y":game.LANES[posmod(game.player.lane+1,3)],"facing":game.player.facing,"life":1.05,"max":1.05})
 game.sound("switch")
 return true

func tick_allies(dt: float) -> void:
 if assist.is_empty(): return
 assist.elapsed+=dt
 assist_damage=true
 if assist.elapsed>=0.18 and not assist.layla:
  assist.layla=true
  for lane in ([0,1,2] if assist.level==2 else [assist.lane]):
   game.strike(assist.x,lane,assist.facing,850,45,game.HEROES[1].color,true)
   game.effects.append({"kind":"slash","x":assist.x+assist.facing*250,"y":game.LANES[lane]-65,"life":0.3,"max":0.3,"color":game.HEROES[1].color,"facing":assist.facing,"large":true})
 if assist.level==2 and assist.elapsed>=0.40 and not assist.lupinor:
  assist.lupinor=true
  for lane in range(3):
   game.strike(assist.x,lane,assist.facing,850,55,game.HEROES[2].color,true)
   game.effects.append({"kind":"ally","hero":2,"x":clampf(assist.x+assist.facing*390,game.stage_left+80,game.stage_right-80),"y":game.LANES[lane],"facing":assist.facing,"life":0.4,"max":0.4})
 if assist.elapsed>=0.62 and not assist.fire:
  assist.fire=true
  var col: Color=game.HEROES[0].color
  for lane in ([0,1,2] if assist.level==2 else [assist.lane]):
   game.strike(assist.x,lane,assist.facing,850,65 if assist.level==2 else 35,col,true)
   for i in range(5):
    game.effects.append({"kind":"flame","x":assist.x+assist.facing*(70+i*130),"y":game.LANES[lane],"life":0.65,"max":0.65,"color":col,"seed":float(i)})
  game.sound("fire")
 assist_damage=false
 if assist.elapsed>1.1: assist.clear()

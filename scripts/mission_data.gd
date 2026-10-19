extends RefCounted
## Fresh data on each run; stable IDs, order belongs exclusively to the mission.
var mission: Dictionary={}
var levels: Array=[] # Flattened stage sequence, retained for runtime compatibility.
var groups: Array=[]
var environments: Dictionary={}
var errors: Array[String]=[]
var enemy_roles: Dictionary={}

func read_json(path: String) -> Dictionary:
 if not FileAccess.file_exists(path):
  errors.append("File mancante: "+path)
  return {}
 var parser=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary:
  errors.append("JSON non valido %s, riga %d: %s" % [path,parser.get_error_line(),parser.get_error_message()])
  return {}
 return parser.data

func load_mission(id: String) -> bool:
 errors.clear()
 levels.clear()
 environments.clear()
 mission=read_json("res://data/missioni/%s.json" % id)
 enemy_roles=read_json("res://data/nemici/archetipi.json").get("roles",{})
 groups.clear()
 for level_id in mission.get("levels",[]):
  var group=read_json("res://data/livelli/%s.json" % level_id)
  require_fields(group,["schema_version","id","text_id","stages","interludes","reward"],"livello "+str(level_id))
  if not errors.is_empty(): continue
  if group.stages.is_empty():
   errors.append("Livello senza stage: "+str(level_id))
   continue
  groups.append(group)
  for i in range(group.stages.size()):
   var stage_id: String=group.stages[i]
   var stage=read_json("res://data/stage/%s.json" % stage_id)
   if stage.is_empty(): continue
   if stage.has("reward") or stage.has("entrance"): errors.append("Stage %s: reward/entrance appartengono al livello" % stage_id)
   if stage.get("type","") not in ["resistance","escape","synchronization","scrolling"]:
    errors.append("Tipo di stage non supportato: "+str(stage.get("type")))
   stage.level_index=groups.size()-1
   stage.stage_index=i
   stage.level_start=i==0
   stage.level_end=i==group.stages.size()-1
   stage.reward=group.reward.duplicate(true) if stage.level_end else {"type":"none","choices":3,"heal":0,"mana":0}
   if stage.has("interludes"):
    if stage.level_start: stage.interludes.before=group.interludes.get("before",[])+stage.interludes.get("before",[])
    if stage.level_end: stage.interludes.after=stage.interludes.get("after",[])+group.interludes.get("after",[])
   levels.append(stage)
   var environment_id: String=stage.get("environment","")
   if not environments.has(environment_id):
    environments[environment_id]=read_json("res://data/ambienti/%s.json" % environment_id)
 if levels.is_empty(): errors.append("La missione non contiene livelli validi: "+id)
 validate_references()
 for message in errors: push_error(message)
 return errors.is_empty()

func require_fields(data: Dictionary,fields: Array,where: String) -> void:
 for key in fields:
  if not data.has(key): errors.append("%s: campo mancante '%s'" % [where,key])

func validate_entrance(config: Dictionary,where: String) -> void:
 if config.get("style","pencil") not in ["pencil","ink","none"]: errors.append(where+": stile di apertura non supportato")
 for field in ["write","hold","erase"]:
  if config.has(field):
   var value=config[field]
   if not (value is float or value is int) or value<0 or (field!="hold" and value==0): errors.append(where+": durata non valida per "+field)

func validate_references() -> void:
 require_fields(mission,["schema_version","id","texts","levels","prologue","interludes_before","ending","presentation"],"missione")
 if not errors.is_empty(): return
 if mission.schema_version!=1: errors.append("Versione missione non supportata")
 if mission.ending!="victory": errors.append("Conclusione non supportata: "+str(mission.ending))
 validate_entrance(mission.get("entrance",{}),"missione.entrance")
 var copy=read_json("res://data/testi/%s.json" % mission.texts)
 var pages: Dictionary={}
 for page in copy.get("pages",[]): pages[page.id]=page
 var all_pages: Array=mission.interludes_before.duplicate()
 var presentation: Dictionary=mission.presentation
 require_fields(presentation,["reward_background","ending_background","comics"],"missione.presentation")
 if not errors.is_empty(): return
 var assets: Array=[presentation.reward_background,presentation.ending_background]
 for page in pages.values():
  if not presentation.comics.has(page.art) or presentation.comics[page.art].size()!=3:
   errors.append("Illustrazioni mancanti (servono 3 pannelli): "+str(page.art))
  else: assets.append_array(presentation.comics[page.art])
 for group in groups:
  validate_entrance(group.get("entrance",{}),"livello "+str(group.id)+".entrance")
  if not copy.get("levels",{}).has(group.text_id): errors.append("Titolo livello mancante: "+str(group.text_id))
 var upgrade_count: int=0
 for level in levels:
  var where="livello "+str(level.get("id","?"))
  require_fields(level,["schema_version","id","type","environment","text_id","stage","interludes","reward","initial_enemies","reinforcements","allies"],where)
  if not errors.is_empty(): continue
  if level.schema_version!=1: errors.append(where+": versione non supportata")

  require_fields(level.stage,["left","right","player_x"],where+".stage")
  require_fields(level.interludes,["before","after"],where+".interludes")
  require_fields(level.reward,["type","choices","heal","mana"],where+".reward")
  require_fields(level.reinforcements,["count","interval","max_alive"],where+".reinforcements")
  require_fields(level.allies,["visible","echo_enabled","echo_interval","echo_damage","echo_max_x"],where+".allies")
  if level.type in ["defense","resistance"]: require_fields(level,["duration"],where)
  if level.type=="resistance": require_fields(level,["anchor_x","warning_time","spawn_distance","entry_lane_hold","archetypes","waves"],where)
  if level.type=="synchronization": require_fields(level,["synchronization"],where)
  if level.type=="scrolling":
   require_fields(level,["exit","encounters","warning_time","spawn_distance"],where)
   for encounter in level.get("encounters",[]):
    for entry in encounter.get("entries",[]):
     if not enemy_roles.has(entry.get("archetype","")): errors.append(where+": ruolo nemico inesistente")
  if level.type=="escape": require_fields(level,["exit","spawn_margin","spawn_spacing","spawn_min_distance"],where)
  if not errors.is_empty(): continue
  if level.type=="synchronization":
   require_fields(level.synchronization,["sigils","charge_seconds","radius","pulse_interval","pulse_warning","pulse_damage"],where+".synchronization")
   if not errors.is_empty(): continue
  if level.reward.type=="skill_upgrade": upgrade_count+=1
  if not copy.get("rooms",{}).get("stages",{}).has(level.text_id): errors.append(where+": text_id inesistente: "+str(level.text_id))
  all_pages.append_array(level.interludes.before)
  all_pages.append_array(level.interludes.after)
  var environment_data: Dictionary=environments.get(level.environment,{})
  require_fields(environment_data,["schema_version","id","shader","layers"],"ambiente "+str(level.environment))
  if not errors.is_empty(): continue
  assets.append(environment_data.shader)
  for layer in environment_data.layers:
   require_fields(layer,["kind","texture","depth"],"ambiente "+str(level.environment))
   if layer.has("texture"): assets.append(layer.texture)
 for page in all_pages:
  if not pages.has(page): errors.append("Intermezzo inesistente: "+str(page))
 for path in assets:
  if not ResourceLoader.exists(path): errors.append("Risorsa mancante: "+str(path))
 if upgrade_count>4: errors.append("Sono supportate al massimo quattro trasformazioni per missione")

func environment(index: int) -> Dictionary:
 if levels.is_empty(): return {}
 return environments.get(levels[clampi(index,0,levels.size()-1)].environment,{})

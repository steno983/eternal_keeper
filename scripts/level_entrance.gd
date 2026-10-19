extends RefCounted
## Presentation clock, independent of combat, enemy scheduling and skill cooldowns.
var elapsed: float=0
var config: Dictionary={"style":"pencil","write":0.65,"hold":0.85,"erase":0.5}
func begin(defaults: Dictionary,overrides: Dictionary) -> void:
 config={"style":"pencil","write":0.65,"hold":0.85,"erase":0.5}
 config.merge(defaults,true)
 config.merge(overrides,true)
 elapsed=0
func duration() -> float:
 return float(config.write)+float(config.hold)+float(config.erase)
func enabled() -> bool:
 return config.style!="none"
func writing() -> float:
 return clampf(elapsed/float(config.write),0,1)
func erasing() -> float:
 return clampf((elapsed-float(config.write)-float(config.hold))/float(config.erase),0,1)

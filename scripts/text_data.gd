extends RefCounted
## Editable UTF-8 JSON is the source of campaign copy.
static var cache: Dictionary={}
static func reload() -> void:
 cache.clear()
static func table(name: String) -> Dictionary:
 if cache.has(name): return cache[name]
 var path="res://data/testi/%s.json" % name
 var parser=JSON.new()
 var error=parser.parse(FileAccess.get_file_as_string(path))
 if error!=OK or not parser.data is Dictionary:
  push_error("Invalid text JSON %s at line %d: %s" % [path,parser.get_error_line(),parser.get_error_message()])
  return {}
 cache[name]=parser.data
 return cache[name]
static func ui(key: String) -> String:
 var data=table("interfaccia")
 if not data.has(key):
  push_error("Missing interface text: "+key)
  return "["+key+"]"
 return str(data[key])

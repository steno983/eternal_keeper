extends RefCounted
## Compatibility view: all copy lives in capitolo_01.json.
const Texts=preload("res://scripts/text_data.gd")
var data: Dictionary={}
var TITLES: Array=[]
var SUBTITLES: Array=[]
var ART: Array=[]
var BEATS: Array=[]
func reload(text_id: String="capitolo_01") -> void:
 data=Texts.table(text_id)
 TITLES.clear()
 SUBTITLES.clear()
 ART.clear()
 BEATS.clear()
 for page in data.pages:
  TITLES.append(page.title)
  SUBTITLES.append(page.subtitle)
  ART.append(page.art)
  BEATS.append(page.beats)

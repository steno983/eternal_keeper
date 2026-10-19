extends RefCounted
const Texts=preload("res://scripts/text_data.gd")
var TITLES: Array=[]
var TAILS: Array=[]
var BEATS: Array=[]
func reload() -> void:
 var data=Texts.table("ponte")
 TITLES=data.titles
 TAILS=data.tails
 BEATS=data.beats
func page(room: int) -> Array:
 return BEATS[clampi(room-1,0,BEATS.size()-1)]

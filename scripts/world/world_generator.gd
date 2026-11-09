extends Node
var biomes: Array = [{"id":"forest","name":"Лес","danger":1,"glyph":"♣"},{"id":"plains","name":"Равнины","danger":1,"glyph":"⌁"},{"id":"desert","name":"Пустыня","danger":2,"glyph":"☼"},{"id":"swamp","name":"Болото","danger":3,"glyph":"≈"},{"id":"mountains","name":"Горы","danger":3,"glyph":"▲"},{"id":"wastes","name":"Пустоши","danger":4,"glyph":"✦"},{"id":"arcane","name":"Магические земли","danger":5,"glyph":"✧"}]
var poi_types: Array = [{"id":"camp","name":"Лагерь разбойников","action":"combat","glyph":"⚔"},{"id":"cache","name":"Старый тайник","action":"loot","glyph":"◆"},{"id":"shrine","name":"Древнее святилище","action":"shrine","glyph":"✧"},{"id":"trader","name":"Странствующий торговец","action":"trade","glyph":"$"},{"id":"ruins","name":"Забытые руины","action":"combat","glyph":"▣"}]
func _ready() -> void:
	biomes = _load_catalog("res://data/world/biomes.json",biomes)
	poi_types = _load_catalog("res://data/world/poi_types.json",poi_types)
func _load_catalog(path: String,fallback: Array) -> Array:
	if not FileAccess.file_exists(path): return fallback
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Array and not parsed.is_empty() else fallback
func _rng_for(x: int,y: int,salt: int=0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash("%d|%d|%d|%d" % [Game.world_seed,x,y,salt]))
	return rng
func get_chunk(x: int,y: int) -> Dictionary:
	var rng := _rng_for(x,y)
	var biome: Dictionary = biomes[rng.randi_range(0,biomes.size()-1)]
	var prng := _rng_for(x,y,17)
	var poi: Dictionary = {}
	if prng.randf() < 0.72:
		var template: Dictionary = poi_types[prng.randi_range(0,poi_types.size()-1)]
		poi = {"id":"poi_%d_%d_%d" % [Game.world_seed,x,y],"name":template.name,"action":template.action,"glyph":template.glyph,"danger":int(biome.danger)+prng.randi_range(0,2),"description":_description(template.id,biome.name),"reward":20+int(biome.danger)*12+prng.randi_range(0,25)}
	return {"x":x,"y":y,"biome":biome,"poi":poi,"key":Game.chunk_key(x,y)}
func _description(kind: String,biome: String) -> String:
	match kind:
		"camp": return "Следы костров и дозорные. В %s замечена враждебная группа." % biome
		"cache": return "Под слоем земли обнаружены следы старого тайника."
		"shrine": return "Забытое место силы, окружённое странным свечением."
		"trader": return "Путник предлагает обмен припасами и снаряжением."
		_: return "Каменные руины хранят опасности древней цивилизации."
func get_nearby(cx: int,cy: int,radius: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for y in range(cy-radius,cy+radius+1):
		for x in range(cx-radius,cx+radius+1):
			result.append(get_chunk(x,y))
	return result

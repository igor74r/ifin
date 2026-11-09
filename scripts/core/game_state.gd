extends Node
const SAVE_VERSION := 1
var world_seed: int = 741902
var player := {"name":"Странник","level":1,"xp":0,"xp_next":150,"hp":100,"hp_max":100,"mana":40,"mana_max":40,"strength":8,"agility":8,"vitality":8,"intellect":6,"gold":35,"stat_points":0,"chunk_x":0,"chunk_y":0}
var discovered_chunks: Dictionary = {}
var poi_states: Dictionary = {}
var journal: Array[Dictionary] = []
var active_combat: Dictionary = {}
var defeated_poi: Dictionary = {}
var statistics := {"kills":0,"discoveries":0,"gold_earned":0,"steps":0}
var settings := {"journal_limit":250}
func _ready() -> void:
	reveal_around_player()
func chunk_key(x: int, y: int) -> String:
	return "%d,%d" % [x,y]
func reveal_around_player() -> void:
	for y in range(player.chunk_y - 1, player.chunk_y + 2):
		for x in range(player.chunk_x - 1, player.chunk_x + 2):
			var key := chunk_key(x,y)
			if not discovered_chunks.has(key):
				discovered_chunks[key] = true
				statistics.discoveries += 1
func add_journal(category: String, message: String) -> void:
	journal.append({"time":Time.get_datetime_string_from_system(),"category":category,"message":message})
	while journal.size() > int(settings.journal_limit):
		journal.pop_front()
	Events.journal_event.emit(category,message)
func gain_xp(amount: int) -> void:
	if amount <= 0: return
	player.xp += amount
	add_journal("Опыт","Получено опыта: %d." % amount)
	while player.xp >= player.xp_next:
		player.xp -= player.xp_next
		player.level += 1
		player.stat_points += 2
		player.hp_max += 8
		player.mana_max += 3
		player.hp = player.hp_max
		player.mana = player.mana_max
		player.xp_next = int(150.0 * pow(float(player.level),1.35) + 35.0 * player.level)
		add_journal("Развитие","Новый уровень: %d. Получено 2 очка характеристик." % player.level)
	Events.state_changed.emit()
func serialize() -> Dictionary:
	return {"version":SAVE_VERSION,"world_seed":world_seed,"player":player.duplicate(true),"discovered_chunks":discovered_chunks.duplicate(true),"poi_states":poi_states.duplicate(true),"journal":journal.duplicate(true),"active_combat":active_combat.duplicate(true),"defeated_poi":defeated_poi.duplicate(true),"statistics":statistics.duplicate(true),"inventory":Inventory.serialize(),"quests":Quests.serialize()}
func apply_save(data: Dictionary) -> bool:
	if int(data.get("version",-1)) != SAVE_VERSION: return false
	var loaded_player: Variant = data.get("player",null)
	if not (loaded_player is Dictionary): return false
	for required_key in ["level","xp","xp_next","hp","hp_max","mana","mana_max","strength","agility","vitality","intellect","gold","chunk_x","chunk_y"]:
		if not loaded_player.has(required_key): return false
	for dictionary_key in ["discovered_chunks","poi_states","active_combat","defeated_poi","statistics","inventory","quests"]:
		if not (data.get(dictionary_key,{}) is Dictionary): return false
	if not (data.get("journal",[]) is Array): return false
	player = loaded_player.duplicate(true)
	player.level = maxi(1,int(player.level))
	player.xp = maxi(0,int(player.xp))
	player.xp_next = maxi(1,int(player.xp_next))
	player.hp_max = maxi(1,int(player.hp_max))
	player.hp = clampi(int(player.hp),0,int(player.hp_max))
	player.mana_max = maxi(0,int(player.mana_max))
	player.mana = clampi(int(player.mana),0,int(player.mana_max))
	player.gold = maxi(0,int(player.gold))
	player.stat_points = maxi(0,int(player.get("stat_points",0)))
	world_seed = int(data.get("world_seed",world_seed))
	discovered_chunks = data.get("discovered_chunks",{})
	poi_states = data.get("poi_states",{})
	active_combat = data.get("active_combat",{})
	journal.clear()
	for entry in data.get("journal",[]):
		if entry is Dictionary: journal.append(entry)
	defeated_poi = data.get("defeated_poi",{})
	statistics = data.get("statistics",statistics)
	Inventory.apply_save(data.get("inventory",{}))
	Quests.apply_save(data.get("quests",{}))
	Events.state_changed.emit()
	return true

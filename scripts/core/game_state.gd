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
	if int(data.get("version", -1)) != SAVE_VERSION:
		return false
	var loaded_player: Variant = data.get("player", null)
	if not (loaded_player is Dictionary):
		return false
	for required_key in ["level", "xp", "xp_next", "hp", "hp_max", "mana", "mana_max", "strength", "agility", "vitality", "intellect", "gold", "chunk_x", "chunk_y"]:
		if not loaded_player.has(required_key):
			return false
	for dictionary_key in ["discovered_chunks", "poi_states", "active_combat", "defeated_poi", "statistics", "inventory", "quests"]:
		if not (data.get(dictionary_key, {}) is Dictionary):
			return false
	if not (data.get("journal", []) is Array):
		return false

	player = loaded_player.duplicate(true)
	player.name = str(player.get("name", "Странник")).substr(0, 40)
	player.level = clampi(int(player.level), 1, 1000000)
	player.xp = clampi(int(player.xp), 0, 1000000000)
	player.xp_next = clampi(int(player.xp_next), 1, 1000000000)
	player.hp_max = clampi(int(player.hp_max), 1, 1000000)
	player.hp = clampi(int(player.hp), 0, int(player.hp_max))
	player.mana_max = clampi(int(player.mana_max), 0, 1000000)
	player.mana = clampi(int(player.mana), 0, int(player.mana_max))
	player.gold = clampi(int(player.gold), 0, 1000000000)
	player.stat_points = clampi(int(player.get("stat_points", 0)), 0, 1000000)
	for stat in ["strength", "agility", "vitality", "intellect"]:
		player[stat] = clampi(int(player[stat]), 0, 1000000)
	player.chunk_x = clampi(int(player.chunk_x), -1000000000, 1000000000)
	player.chunk_y = clampi(int(player.chunk_y), -1000000000, 1000000000)

	world_seed = int(data.get("world_seed", world_seed))
	discovered_chunks.clear()
	for key in data.discovered_chunks:
		if data.discovered_chunks[key] == true and discovered_chunks.size() < 100000:
			discovered_chunks[str(key)] = true
	poi_states.clear()
	for key in data.poi_states:
		var state := str(data.poi_states[key])
		if state in ["scouted", "completed", "bypassed"]:
			poi_states[str(key)] = state
	defeated_poi.clear()
	for key in data.defeated_poi:
		if data.defeated_poi[key] == true:
			defeated_poi[str(key)] = true

	active_combat.clear()
	var loaded_combat: Dictionary = data.active_combat
	if loaded_combat.get("active", false) and str(loaded_combat.get("poi_id", "")).is_empty() == false:
		var enemy_hp := clampi(int(loaded_combat.get("enemy_hp", 0)), 1, 1000000)
		active_combat = {
			"active": true,
			"poi_id": str(loaded_combat.get("poi_id", "")),
			"enemy_name": str(loaded_combat.get("enemy_name", "Противник")).substr(0, 80),
			"enemy_hp": enemy_hp,
			"enemy_hp_max": clampi(int(loaded_combat.get("enemy_hp_max", enemy_hp)), enemy_hp, 1000000),
			"enemy_attack": clampi(int(loaded_combat.get("enemy_attack", 1)), 1, 100000),
			"round": clampi(int(loaded_combat.get("round", 1)), 1, 1000000),
			"reward": clampi(int(loaded_combat.get("reward", 0)), 0, 1000000000)
		}

	journal.clear()
	for entry in data.get("journal", []):
		if entry is Dictionary and journal.size() < int(settings.journal_limit):
			journal.append({
				"time": str(entry.get("time", "")).substr(0, 40),
				"category": str(entry.get("category", "")).substr(0, 40),
				"message": str(entry.get("message", "")).substr(0, 1000)
			})
	statistics = {"kills": 0, "discoveries": discovered_chunks.size(), "gold_earned": 0, "steps": 0}
	var loaded_statistics: Dictionary = data.statistics
	for stat_key in statistics:
		statistics[stat_key] = clampi(int(loaded_statistics.get(stat_key, statistics[stat_key])), 0, 1000000000)
	Inventory.apply_save(data.inventory)
	Quests.apply_save(data.quests)
	Events.state_changed.emit()
	Events.combat_changed.emit(active_combat.get("active", false))
	return true

extends Node

var items: Array[Dictionary] = []
var equipped: Dictionary = {}

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/items.json"))
	if parsed is Array and not parsed.is_empty():
		items.clear()
		for entry in parsed:
			if entry is Dictionary:
				var clean := _sanitize_item(entry)
				if not clean.is_empty():
					items.append(clean)

func _sanitize_item(source: Dictionary) -> Dictionary:
	var item_id := str(source.get("id", "")).strip_edges()
	var item_name := str(source.get("name", "")).strip_edges()
	var kind := str(source.get("kind", "")).strip_edges()
	var count := int(source.get("count", 0))
	var value := int(source.get("value", 0))
	if item_id.is_empty() or item_name.is_empty() or kind.is_empty() or count <= 0 or value < 0:
		return {}
	return {
		"id": item_id,
		"name": item_name,
		"kind": kind,
		"count": count,
		"value": value,
		"slot": str(source.get("slot", "")),
		"damage_bonus": maxi(0, int(source.get("damage_bonus", 0))),
		"defense_bonus": maxi(0, int(source.get("defense_bonus", 0)))
	}

func find_item(id: String) -> Dictionary:
	for item in items:
		if str(item.get("id", "")) == id:
			return item
	return {}

func add_item(id: String, item_name: String, kind: String, count: int, value: int) -> bool:
	if id.strip_edges().is_empty() or item_name.strip_edges().is_empty() or kind.strip_edges().is_empty() or count <= 0 or value < 0:
		return false
	for item in items:
		if str(item.get("id", "")) == id and str(item.get("kind", "")) != "weapon" and str(item.get("kind", "")) != "armor":
			item.count = int(item.get("count", 0)) + count
			Events.publish("Добыча", "Получено: %s ×%d." % [item_name, count])
			return true
	items.append({"id": id, "name": item_name, "kind": kind, "count": count, "value": value, "slot": "", "damage_bonus": 0, "defense_bonus": 0})
	Events.publish("Добыча", "Получен предмет: %s ×%d." % [item_name, count])
	return true

func consume(id: String, count: int = 1) -> bool:
	if count <= 0:
		return false
	for i in range(items.size()):
		if str(items[i].get("id", "")) == id and int(items[i].get("count", 0)) >= count:
			items[i].count = int(items[i].count) - count
			if int(items[i].count) == 0:
				items.remove_at(i)
			return true
	return false

func equip_item(id: String) -> Dictionary:
	var item := find_item(id)
	if item.is_empty():
		return {"ok": false, "message": "Предмет не найден."}
	var slot := str(item.get("slot", ""))
	if slot.is_empty() or str(item.get("kind", "")) not in ["weapon", "armor"]:
		return {"ok": false, "message": "Этот предмет нельзя экипировать."}
	var previous_id := str(equipped.get(slot, ""))
	equipped[slot] = id
	Events.publish("Экипировка", "Экипирован предмет: %s." % item.name)
	return {"ok": true, "message": "Экипировано: %s." % item.name, "replaced": previous_id}

func unequip_slot(slot: String) -> bool:
	if not equipped.has(slot):
		return false
	equipped.erase(slot)
	Events.publish("Экипировка", "Снято снаряжение: %s." % slot)
	return true

func get_equipment_bonus(field: String) -> int:
	var total := 0
	for id in equipped.values():
		var item := find_item(str(id))
		if not item.is_empty():
			total += maxi(0, int(item.get(field, 0)))
	return total

func use_potion() -> String:
	if not consume("potion_small"):
		return "В инвентаре нет малого зелья."
	var restored := mini(35, int(Game.player.hp_max) - int(Game.player.hp))
	Game.player.hp += restored
	Events.publish("Предметы", "Использовано зелье: восстановлено здоровья %d." % restored)
	return "Восстановлено здоровья: %d." % restored

func serialize() -> Dictionary:
	return {"items": items.duplicate(true), "equipped": equipped.duplicate(true)}

func apply_save(data: Dictionary) -> void:
	var loaded: Variant = data.get("items", null)
	if loaded is Array:
		items.clear()
		for entry in loaded:
			if entry is Dictionary:
				var clean := _sanitize_item(entry)
				if not clean.is_empty():
					items.append(clean)
	var loaded_equipped: Variant = data.get("equipped", {})
	equipped.clear()
	if loaded_equipped is Dictionary:
		for slot_value in loaded_equipped:
			var slot := str(slot_value)
			var id := str(loaded_equipped[slot_value])
			var item := find_item(id)
			if not item.is_empty() and str(item.get("slot", "")) == slot and str(item.get("kind", "")) in ["weapon", "armor"]:
				equipped[slot] = id

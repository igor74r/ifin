extends Node
var items: Array[Dictionary] = [{"id":"potion_small","name":"Малое зелье","kind":"consumable","count":2,"value":12},{"id":"iron_sword","name":"Железный меч","kind":"weapon","count":1,"value":28},{"id":"herb","name":"Лесная трава","kind":"material","count":3,"value":4}]
func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/items.json"))
	if parsed is Array and not parsed.is_empty():
		items.clear()
		for entry in parsed:
			if entry is Dictionary: items.append(entry)
func add_item(id: String,name: String,kind: String,count: int,value: int) -> bool:
	if id.is_empty() or count <= 0: return false
	for item in items:
		if item.id == id and kind != "weapon":
			item.count += count
			Events.publish("Добыча","Получено: %s ×%d." % [name,count])
			return true
	items.append({"id":id,"name":name,"kind":kind,"count":count,"value":value})
	Events.publish("Добыча","Получен предмет: %s ×%d." % [name,count])
	return true
func consume(id: String,count: int=1) -> bool:
	for i in range(items.size()):
		if items[i].id == id and int(items[i].count) >= count and count > 0:
			items[i].count -= count
			if items[i].count == 0: items.remove_at(i)
			return true
	return false
func use_potion() -> String:
	if not consume("potion_small"): return "В инвентаре нет малого зелья."
	var restored := mini(35,int(Game.player.hp_max)-int(Game.player.hp))
	Game.player.hp += restored
	Events.publish("Предметы","Использовано зелье: восстановлено здоровья %d." % restored)
	return "Восстановлено здоровья: %d." % restored
func serialize() -> Dictionary:
	return {"items":items.duplicate(true)}
func apply_save(data: Dictionary) -> void:
	var loaded: Variant = data.get("items",null)
	if loaded is Array:
		items.clear()
		for entry in loaded:
			if entry is Dictionary: items.append(entry)

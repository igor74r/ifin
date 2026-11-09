extends SceneTree
## Run with: godot --headless --path . -s res://tests/smoke_test.gd
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var chunk_a: Dictionary = WorldGen.get_chunk(12, -8)
	var chunk_b: Dictionary = WorldGen.get_chunk(12, -8)
	if chunk_a != chunk_b:
		errors.append("Chunk generation is not deterministic.")
	if chunk_a.get("key", "") != "12,-8":
		errors.append("Negative chunk key failed.")
	if WorldGen.biomes.size() < 5:
		errors.append("World biome catalog was not loaded.")
	if WorldGen.poi_types.size() < 3:
		errors.append("POI catalog was not loaded.")

	if not Inventory.add_item("test_stack", "Тестовый ресурс", "material", 2, 1):
		errors.append("Inventory add failed.")
	if Inventory.consume("missing_item", 1):
		errors.append("Missing item was consumed.")
	if Inventory.consume("test_stack", 0):
		errors.append("Zero-count consumption was accepted.")
	if Inventory.add_item("invalid", "Некорректный предмет", "material", -1, 1):
		errors.append("Negative item count was accepted.")

	var equip_result := Inventory.equip_item("iron_sword")
	if not equip_result.get("ok", false):
		errors.append("Starter weapon could not be equipped.")
	if Inventory.get_equipment_bonus("damage_bonus") != 5:
		errors.append("Weapon damage bonus was not applied.")
	if not Inventory.unequip_slot("weapon"):
		errors.append("Equipped weapon could not be removed.")
	if Inventory.get_equipment_bonus("damage_bonus") != 0:
		errors.append("Weapon bonus remained after unequip.")
	Inventory.equip_item("iron_sword")
	Inventory.equip_item("leather_armor")
	if Inventory.get_equipment_bonus("defense_bonus") != 2:
		errors.append("Armor defense bonus was not applied.")

	var snapshot: Dictionary = Game.serialize()
	var original_gold: int = Game.player.gold
	Game.player.gold += 99
	if not Game.apply_save(snapshot):
		errors.append("Valid save snapshot was rejected.")
	if int(Game.player.gold) != original_gold:
		errors.append("Save round-trip did not restore player data.")
	if not snapshot.has("player") or not snapshot.has("inventory") or not snapshot.has("quests"):
		errors.append("Save payload incomplete.")
	if Inventory.get_equipment_bonus("damage_bonus") != 5 or Inventory.get_equipment_bonus("defense_bonus") != 2:
		errors.append("Equipment state did not survive save round-trip.")

	var malformed := snapshot.duplicate(true)
	var malformed_items: Array = malformed.inventory.items.duplicate(true)
	malformed_items.append({"id":"bad","name":"Bad","kind":"material","count":-50,"value":-1})
	malformed.inventory.items = malformed_items
	if not Game.apply_save(malformed):
		errors.append("Save with a malformed optional inventory entry was rejected.")
	if Inventory.find_item("bad").size() > 0:
		errors.append("Malformed inventory entry was loaded.")

	var poi := {"id":"test_combat_poi","name":"Тестовый противник","danger":1,"reward":10}
	var encounter := Combat.start_encounter(poi)
	if not encounter.get("ok", false):
		errors.append("Combat encounter did not start.")
	else:
		var mana_before: int = Game.player.mana
		var enemy_hp_before: int = int(Game.active_combat.enemy_hp)
		var ability_result := Combat.use_power_strike()
		if not ability_result.get("ok", false):
			errors.append("Power strike failed despite sufficient mana.")
		if Game.player.mana != mana_before - 10:
			errors.append("Power strike mana cost was not applied.")
		if Game.active_combat.get("active", false) and int(Game.active_combat.enemy_hp) >= enemy_hp_before:
			errors.append("Power strike did not damage the enemy.")
		var hp_before: int = Game.player.hp
		var defense_result := Combat.defend()
		if not defense_result.get("ok", false):
			errors.append("Defend action failed.")
		if Game.player.hp >= hp_before:
			errors.append("Defend action did not resolve an enemy turn.")
		var flee_result := Combat.flee()
		if not flee_result.get("ok", false):
			errors.append("Flee action failed.")
	if Game.active_combat.get("active", false):
		errors.append("Combat state remained active after fleeing.")

	if errors.is_empty():
		print("SMOKE TESTS PASSED")
	else:
		for error_text in errors:
			push_error(error_text)
	quit(0 if errors.is_empty() else 1)

extends SceneTree
## Run with: godot --headless --path . -s res://tests/smoke_test.gd
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var errors: Array[String] = []
	var chunk_a: Dictionary = WorldGen.get_chunk(12,-8)
	var chunk_b: Dictionary = WorldGen.get_chunk(12,-8)
	if chunk_a != chunk_b: errors.append("Chunk generation is not deterministic.")
	if chunk_a.get("key","") != "12,-8": errors.append("Negative chunk key failed.")
	if WorldGen.biomes.size() < 5: errors.append("World biome catalog was not loaded.")
	if WorldGen.poi_types.size() < 3: errors.append("POI catalog was not loaded.")
	var before_count := Inventory.items.size()
	if not Inventory.add_item("test_stack","Тестовый ресурс","material",2,1): errors.append("Inventory add failed.")
	if Inventory.items.size() < before_count: errors.append("Inventory size invalid.")
	if Inventory.consume("missing_item",1): errors.append("Missing item was consumed.")
	if Inventory.consume("test_stack",0): errors.append("Zero-count consumption was accepted.")
	var snapshot: Dictionary = Game.serialize()
	var original_gold: int = Game.player.gold
	Game.player.gold += 99
	if not Game.apply_save(snapshot): errors.append("Valid save snapshot was rejected.")
	if int(Game.player.gold) != original_gold: errors.append("Save round-trip did not restore player data.")
	if not snapshot.has("player") or not snapshot.has("inventory") or not snapshot.has("quests"): errors.append("Save payload incomplete.")
	if errors.is_empty():
		print("SMOKE TESTS PASSED")
	else:
		for error_text in errors: push_error(error_text)
	quit(0 if errors.is_empty() else 1)

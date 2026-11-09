extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var errors: Array[String] = []
	if WorldGen.get_chunk(12,-8) != WorldGen.get_chunk(12,-8): errors.append("Chunk generation is not deterministic.")
	if WorldGen.get_chunk(12,-8).key != "12,-8": errors.append("Negative chunk key failed.")
	var count := Inventory.items.size()
	if not Inventory.add_item("test_stack","Тестовый ресурс","material",2,1): errors.append("Inventory add failed.")
	if Inventory.items.size() < count: errors.append("Inventory size invalid.")
	if Inventory.consume("missing_item"): errors.append("Missing item was consumed.")
	var payload := Game.serialize()
	if not payload.has("player") or not payload.has("inventory"): errors.append("Save payload incomplete.")
	if errors.is_empty(): print("SMOKE TESTS PASSED")
	else:
		for e in errors: push_error(e)
	quit(0 if errors.is_empty() else 1)

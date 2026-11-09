extends Node
signal journal_event(category: String, message: String)
signal state_changed
signal poi_changed(poi_id: String)
signal player_moved(chunk_x: int, chunk_y: int)
signal combat_changed(active: bool)
signal quest_changed
func publish(category: String, message: String) -> void:
	journal_event.emit(category, message)
	state_changed.emit()

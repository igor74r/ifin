extends Node
var quests: Array[Dictionary] = [{"id":"first_hunt","title":"Первая охота","description":"Победите одного противника в любой точке мира.","target":1,"progress":0,"status":"active","reward_xp":60,"reward_gold":25,"claimed":false}]
func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests/quests.json"))
	if parsed is Array and not parsed.is_empty():
		quests.clear()
		for entry in parsed:
			if entry is Dictionary: quests.append(entry)
func on_enemy_defeated() -> void:
	for q in quests:
		if q.id == "first_hunt" and q.status == "active":
			q.progress = mini(int(q.target),int(q.progress)+1)
			if q.progress >= q.target:
				q.status = "completed"
				_claim_reward(q)
				Events.publish("Квест","Задание выполнено: %s." % q.title)
			else: Events.publish("Квест","Прогресс: %d/%d." % [q.progress,q.target])
	Events.quest_changed.emit()
func _claim_reward(q: Dictionary) -> void:
	if q.claimed: return
	q.claimed = true
	Game.player.gold += int(q.reward_gold)
	Game.statistics.gold_earned += int(q.reward_gold)
	Game.gain_xp(int(q.reward_xp))
func serialize() -> Dictionary:
	return {"quests":quests}
func apply_save(data: Dictionary) -> void:
	var loaded: Variant = data.get("quests",null)
	if loaded is Array: quests = loaded

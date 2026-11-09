extends Node

func start_encounter(poi: Dictionary) -> Dictionary:
	if Game.active_combat.get("active", false):
		return {"ok": false, "message": "Бой уже идёт."}
	var poi_id := str(poi.get("id", ""))
	if poi_id.is_empty() or Game.defeated_poi.has(poi_id):
		return {"ok": false, "message": "Здесь больше нет противников."}
	var danger := maxi(1, int(poi.get("danger", 1)))
	var hp := 35 + danger * 13 + int(Game.player.level) * 5
	Game.active_combat = {
		"active": true,
		"poi_id": poi_id,
		"enemy_name": str(poi.get("enemy_name", "Разбойник-разведчик")),
		"enemy_hp": hp,
		"enemy_hp_max": hp,
		"enemy_attack": 5 + danger * 2,
		"round": 1,
		"reward": maxi(0, int(poi.get("reward", 0)))
	}
	Events.combat_changed.emit(true)
	Events.publish("Бой", "Начался бой: %s. Здоровье противника: %d." % [str(poi.get("name", "Противник")), hp])
	return {"ok": true, "message": "Противник готов к бою."}

func player_attack() -> Dictionary:
	if not Game.active_combat.get("active", false):
		return {"ok": false, "message": "Сейчас нет активного боя."}
	var combat: Dictionary = Game.active_combat
	var damage := maxi(1, int(Game.player.strength) * 2 + int(Game.player.level) - 3 + Inventory.get_equipment_bonus("damage_bonus"))
	combat.enemy_hp = maxi(0, int(combat.enemy_hp) - damage)
	Events.publish("Бой", "Вы наносите %d урона." % damage)
	if int(combat.enemy_hp) <= 0:
		return _win()
	Game.active_combat = combat
	return _enemy_turn(1.0, "Противник ранен. Его здоровье: %d." % int(combat.enemy_hp))

func use_power_strike() -> Dictionary:
	if not Game.active_combat.get("active", false):
		return {"ok": false, "message": "Сейчас нет активного боя."}
	var mana_cost := 10
	if int(Game.player.mana) < mana_cost:
		return {"ok": false, "message": "Недостаточно маны для силового удара."}
	Game.player.mana -= mana_cost
	var combat: Dictionary = Game.active_combat
	var base_damage := maxi(1, int(Game.player.strength) * 2 + int(Game.player.level) - 3 + Inventory.get_equipment_bonus("damage_bonus"))
	var damage := base_damage * 2 + int(Game.player.intellect)
	combat.enemy_hp = maxi(0, int(combat.enemy_hp) - damage)
	Events.publish("Способность", "Силовой удар наносит %d урона. Потрачено %d маны." % [damage, mana_cost])
	if int(combat.enemy_hp) <= 0:
		return _win()
	Game.active_combat = combat
	return _enemy_turn(1.0, "Силовой удар пробил защиту противника. Его здоровье: %d." % int(combat.enemy_hp))

func defend() -> Dictionary:
	if not Game.active_combat.get("active", false):
		return {"ok": false, "message": "Сейчас нет активного боя."}
	return _enemy_turn(0.35, "Вы выдержали удар и приготовились к следующему раунду.")

func _enemy_turn(damage_scale: float, message: String) -> Dictionary:
	var combat: Dictionary = Game.active_combat
	var armor := Inventory.get_equipment_bonus("defense_bonus")
	var raw_damage := int(ceil(float(int(combat.get("enemy_attack", 1))) * damage_scale))
	var incoming := maxi(1, raw_damage - armor - int(Game.player.vitality) / 5)
	Game.player.hp = maxi(0, int(Game.player.hp) - incoming)
	combat.round = int(combat.get("round", 1)) + 1
	Events.publish("Бой", "Противник наносит вам %d урона." % incoming)
	if int(Game.player.hp) <= 0:
		Game.player.hp = maxi(1, int(Game.player.hp_max) / 2)
		Game.active_combat = {}
		Events.combat_changed.emit(false)
		Events.publish("Поражение", "Вы потерпели поражение и восстановились у ближайшего убежища.")
		return {"ok": false, "message": "Поражение. Вы восстановились до половины здоровья."}
	Game.active_combat = combat
	Events.state_changed.emit()
	return {"ok": true, "message": message}

func _win() -> Dictionary:
	var combat: Dictionary = Game.active_combat
	var poi_id := str(combat.get("poi_id", ""))
	if poi_id.is_empty() or Game.defeated_poi.has(poi_id):
		Game.active_combat = {}
		Events.combat_changed.emit(false)
		return {"ok": false, "message": "Награда за эту точку уже получена."}
	Game.defeated_poi[poi_id] = true
	Game.poi_states[poi_id] = "completed"
	var reward := maxi(0, int(combat.get("reward", 0)))
	Game.statistics.kills = int(Game.statistics.get("kills", 0)) + 1
	Game.player.gold = int(Game.player.gold) + reward
	Game.statistics.gold_earned = int(Game.statistics.get("gold_earned", 0)) + reward
	Inventory.add_item("monster_essence", "Эссенция монстра", "material", 1, 9)
	Game.gain_xp(45 + reward)
	Quests.on_enemy_defeated()
	Game.add_journal("Победа", "Противник побеждён. Получено %d золота." % reward)
	Game.active_combat = {}
	Events.combat_changed.emit(false)
	Events.state_changed.emit()
	return {"ok": true, "message": "Победа! Получены золото и опыт."}

func flee() -> Dictionary:
	if not Game.active_combat.get("active", false):
		return {"ok": false, "message": "Сейчас нет активного боя."}
	Game.active_combat = {}
	Events.combat_changed.emit(false)
	Events.publish("Бой", "Вы отступили. Награда не получена.")
	return {"ok": true, "message": "Вы отступили."}

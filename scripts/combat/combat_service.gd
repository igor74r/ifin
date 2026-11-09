extends Node
func start_encounter(poi: Dictionary) -> Dictionary:
	if Game.active_combat.get("active",false): return {"ok":false,"message":"Бой уже идёт."}
	if Game.defeated_poi.has(poi.id): return {"ok":false,"message":"Здесь больше нет противников."}
	var hp := 35 + int(poi.danger)*13 + Game.player.level*5
	Game.active_combat = {"active":true,"poi_id":poi.id,"enemy_name":"Разбойник-разведчик","enemy_hp":hp,"enemy_hp_max":hp,"enemy_attack":5+int(poi.danger)*2,"round":1,"reward":int(poi.reward)}
	Events.combat_changed.emit(true)
	Events.publish("Бой","Начался бой: %s. Здоровье противника: %d." % [poi.name,hp])
	return {"ok":true,"message":"Противник готов к бою."}
func player_attack() -> Dictionary:
	if not Game.active_combat.get("active",false): return {"ok":false,"message":"Сейчас нет активного боя."}
	var c: Dictionary = Game.active_combat
	var damage := maxi(1,int(Game.player.strength)*2+int(Game.player.level)-3)
	c.enemy_hp = maxi(0,int(c.enemy_hp)-damage)
	Events.publish("Бой","Вы наносите %d урона." % damage)
	if int(c.enemy_hp) <= 0: return _win()
	var incoming := maxi(1,int(c.enemy_attack)-int(Game.player.vitality)/3)
	Game.player.hp = maxi(0,int(Game.player.hp)-incoming)
	Events.publish("Бой","Противник наносит вам %d урона." % incoming)
	c.round = int(c.round)+1
	if int(Game.player.hp) <= 0:
		Game.player.hp = maxi(1,int(Game.player.hp_max)/2)
		Game.active_combat = {}
		Events.combat_changed.emit(false)
		return {"ok":false,"message":"Поражение. Вы отступили и восстановились до половины здоровья."}
	Game.active_combat = c
	Events.state_changed.emit()
	return {"ok":true,"message":"Противник ранен. Его здоровье: %d." % c.enemy_hp}
func defend() -> Dictionary:
	if not Game.active_combat.get("active",false): return {"ok":false,"message":"Сейчас нет активного боя."}
	var c: Dictionary = Game.active_combat
	var damage := maxi(1,int(c.enemy_attack)/3)
	Game.player.hp = maxi(1,int(Game.player.hp)-damage)
	c.round = int(c.round)+1
	Game.active_combat = c
	Events.publish("Бой","Защита снижает урон до %d." % damage)
	return {"ok":true,"message":"Вы обороняетесь."}
func _win() -> Dictionary:
	var c: Dictionary = Game.active_combat
	Game.defeated_poi[c.poi_id] = true
	Game.statistics.kills += 1
	Game.player.gold += int(c.reward)
	Game.statistics.gold_earned += int(c.reward)
	Inventory.add_item("monster_essence","Эссенция монстра","material",1,9)
	Game.gain_xp(45+int(c.reward))
	Quests.on_enemy_defeated()
	Game.add_journal("Победа","Противник побеждён. Получено %d золота." % int(c.reward))
	Game.active_combat = {}
	Events.combat_changed.emit(false)
	return {"ok":true,"message":"Победа! Получены золото и опыт."}
func flee() -> Dictionary:
	if not Game.active_combat.get("active",false): return {"ok":false,"message":"Сейчас нет активного боя."}
	Game.active_combat = {}
	Events.combat_changed.emit(false)
	Events.publish("Бой","Вы отступили. Награда не получена.")
	return {"ok":true,"message":"Вы отступили."}

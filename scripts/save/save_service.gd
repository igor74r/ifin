extends Node
const SAVE_PATH := "user://infinite_world_save.json"
const BACKUP_PATH := "user://infinite_world_save.backup.json"
func save_game() -> bool:
	var temp_path := SAVE_PATH+".tmp"
	var save_abs := ProjectSettings.globalize_path(SAVE_PATH)
	var temp_abs := ProjectSettings.globalize_path(temp_path)
	var backup_abs := ProjectSettings.globalize_path(BACKUP_PATH)
	var f := FileAccess.open(temp_path,FileAccess.WRITE)
	if f == null: Events.publish("Сохранение","Не удалось создать временный файл."); return false
	f.store_string(JSON.stringify(Game.serialize()))
	f.flush()
	f.close()
	if FileAccess.file_exists(SAVE_PATH):
		var backup_error := DirAccess.copy_absolute(save_abs,backup_abs)
		if backup_error != OK:
			Events.publish("Сохранение","Не удалось создать резервную копию; основное сохранение оставлено без изменений.")
			return false
		var remove_error := DirAccess.remove_absolute(save_abs)
		if remove_error != OK:
			Events.publish("Сохранение","Не удалось заменить старое сохранение.")
			return false
	var err := DirAccess.rename_absolute(temp_abs,save_abs)
	if err != OK: Events.publish("Сохранение","Ошибка записи: %s." % error_string(err)); return false
	Events.publish("Сохранение","Игра сохранена.")
	return true
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(BACKUP_PATH): return _load_path(BACKUP_PATH)
		return false
	if _load_path(SAVE_PATH): Events.publish("Сохранение","Сохранение загружено."); return true
	if FileAccess.file_exists(BACKUP_PATH) and _load_path(BACKUP_PATH):
		Events.publish("Сохранение","Загружена резервная копия."); return true
	Events.publish("Ошибка","Не удалось прочитать сохранение.")
	return false
func _load_path(path: String) -> bool:
	var f := FileAccess.open(path,FileAccess.READ)
	if f == null: return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary: return false
	return Game.apply_save(parsed)

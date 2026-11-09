extends Node
const SAVE_PATH := "user://infinite_world_save.json"
const BACKUP_PATH := "user://infinite_world_save.backup.json"
func save_game() -> bool:
	var f := FileAccess.open(SAVE_PATH+".tmp",FileAccess.WRITE)
	if f == null: Events.publish("Сохранение","Не удалось создать временный файл."); return false
	f.store_string(JSON.stringify(Game.serialize()))
	f.flush()
	f.close()
	if FileAccess.file_exists(SAVE_PATH): DirAccess.copy_absolute(SAVE_PATH,BACKUP_PATH)
	var err := DirAccess.rename_absolute(SAVE_PATH+".tmp",SAVE_PATH)
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

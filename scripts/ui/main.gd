extends Control
const MapScript = preload("res://scripts/ui/world_map.gd")
var map_view: WorldMapView
var journal_box: RichTextLabel
var status_label: Label
var detail_box: VBoxContainer
var active_tab := "Герой"
var selected_chunk: Dictionary = {}

func _ready() -> void:
	_build_interface()
	Events.journal_event.connect(_on_journal_event)
	Events.state_changed.connect(_refresh_status)
	Events.quest_changed.connect(_refresh_detail)
	Events.combat_changed.connect(_on_combat_changed)
	if Saves.load_game():
		_refresh_all()
	else:
		Game.add_journal("Мир","Вы просыпаетесь на окраине неизвестных земель. Мир ждёт исследования.")
		Game.add_journal("Подсказка","Выберите соседнюю клетку карты. Точки интереса открывают действия.")
	_refresh_all()

func _build_interface() -> void:
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation",8)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var left := PanelContainer.new()
	left.custom_minimum_size.x = 190
	left.add_theme_stylebox_override("panel",_panel_style("#151f2a"))
	root.add_child(left)
	var nav := VBoxContainer.new()
	nav.add_theme_constant_override("separation",6)
	left.add_child(nav)
	var logo := Label.new()
	logo.text = "INFINITE WORLD"
	logo.add_theme_font_size_override("font_size",19)
	logo.add_theme_color_override("font_color",Color("#f0c879"))
	nav.add_child(logo)
	var tagline := Label.new()
	tagline.text = "ПАНЕЛЬ ПУТЕШЕСТВЕННИКА"
	tagline.add_theme_font_size_override("font_size",9)
	tagline.add_theme_color_override("font_color",Color("#8da2b5"))
	nav.add_child(tagline)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nav.add_child(status_label)
	nav.add_child(HSeparator.new())
	for tab in ["Герой","Характеристики","Инвентарь","Квесты","Способности","Настройки"]:
		var button := Button.new()
		button.text = tab
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_open_tab.bind(tab))
		nav.add_child(button)
	var save_button := Button.new()
	save_button.text = "Сохранить игру"
	save_button.pressed.connect(_save_pressed)
	nav.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "Загрузить игру"
	load_button.pressed.connect(_load_pressed)
	nav.add_child(load_button)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var map_header := HBoxContainer.new()
	center.add_child(map_header)
	var map_title := Label.new()
	map_title.text = "КАРТА НЕИЗВЕДАННЫХ ЗЕМЕЛЬ"
	map_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_title.add_theme_color_override("font_color",Color("#f0c879"))
	map_header.add_child(map_title)
	var recenter := Button.new()
	recenter.text = "К герою"
	recenter.pressed.connect(_recenter_map)
	map_header.add_child(recenter)
	map_view = MapScript.new()
	map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_view.cell_selected.connect(_on_map_cell_selected)
	center.add_child(map_view)
	var legend := Label.new()
	legend.text = "Колесо — масштаб · Перетаскивание — обзор · Клик — путешествие / POI"
	legend.add_theme_font_size_override("font_size",10)
	legend.add_theme_color_override("font_color",Color("#8da2b5"))
	center.add_child(legend)
	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size.y = 190
	detail_panel.add_theme_stylebox_override("panel",_panel_style("#151f2a"))
	center.add_child(detail_panel)
	detail_box = VBoxContainer.new()
	detail_box.add_theme_constant_override("separation",4)
	detail_panel.add_child(detail_box)

	var right := PanelContainer.new()
	right.custom_minimum_size.x = 260
	right.add_theme_stylebox_override("panel",_panel_style("#151f2a"))
	root.add_child(right)
	var journal_col := VBoxContainer.new()
	right.add_child(journal_col)
	var journal_title := Label.new()
	journal_title.text = "ЖУРНАЛ СОБЫТИЙ"
	journal_title.add_theme_color_override("font_color",Color("#f0c879"))
	journal_col.add_child(journal_title)
	journal_box = RichTextLabel.new()
	journal_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_box.scroll_following = true
	journal_box.bbcode_enabled = true
	journal_col.add_child(journal_box)
	var note := Label.new()
	note.text = "История сохраняется вместе с миром."
	note.add_theme_font_size_override("font_size",9)
	note.add_theme_color_override("font_color",Color("#8da2b5"))
	journal_col.add_child(note)

func _panel_style(color: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color)
	style.border_color = Color("#2b3a49")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _open_tab(tab: String) -> void:
	active_tab = tab
	_refresh_detail()

func _refresh_detail() -> void:
	if detail_box == null: return
	for child in detail_box.get_children(): child.queue_free()
	var heading := Label.new()
	heading.text = active_tab.to_upper()
	heading.add_theme_color_override("font_color",Color("#f0c879"))
	detail_box.add_child(heading)
	match active_tab:
		"Герой":
			_add_text("Имя: %s · Уровень %d" % [Game.player.name,Game.player.level])
			_add_text("Опыт: %d / %d" % [Game.player.xp,Game.player.xp_next])
			_add_text("Здоровье: %d/%d · Мана: %d/%d" % [Game.player.hp,Game.player.hp_max,Game.player.mana,Game.player.mana_max])
			_add_text("Золото: %d · Координаты: %d, %d" % [Game.player.gold,Game.player.chunk_x,Game.player.chunk_y])
			if Game.player.stat_points > 0:
				_add_action("Усилить силу (+1)",_spend_strength)
		"Характеристики":
			for stat in ["strength","agility","vitality","intellect"]:
				_add_text("%s: %d" % [stat,Game.player[stat]])
			_add_text("Очки развития: %d" % Game.player.stat_points)
			_add_text("Урон базовой атаки: %d" % maxi(1,int(Game.player.strength)*2+int(Game.player.level)-3))
		"Инвентарь":
			for item in Inventory.items:
				var row := HBoxContainer.new()
				var label := Label.new()
				label.text = "%s ×%d" % [item.name,item.count]
				label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(label)
				if item.id == "potion_small":
					var use := Button.new()
					use.text = "Использовать"
					use.pressed.connect(_use_potion)
					row.add_child(use)
				detail_box.add_child(row)
		"Квесты":
			for quest in Quests.quests:
				_add_text("%s — %s (%d/%d)" % [quest.title,quest.status,quest.progress,quest.target])
				_add_text(quest.description)
		"Способности":
			_add_text("Удар: сила ×2 + уровень.")
			_add_text("Защита: снижает входящий урон до трети.")
			_add_action("Использовать малое зелье",_use_potion)
		"Настройки":
			_add_text("Seed мира: %d" % Game.world_seed)
			_add_text("Одиночный офлайн-режим. Сохранение хранится локально.")
			_add_action("Сохранить сейчас",_save_pressed)
	if Game.active_combat.get("active",false):
		_show_combat_controls()

func _add_text(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(label)

func _add_action(text_value: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.pressed.connect(action)
	detail_box.add_child(button)

func _on_map_cell_selected(x: int,y: int) -> void:
	var chunk := WorldGen.get_chunk(x,y)
	var distance := absi(x-int(Game.player.chunk_x))+absi(y-int(Game.player.chunk_y))
	if distance > 1:
		_show_message("Сначала исследуйте соседние территории.")
		return
	if distance == 1:
		Game.player.chunk_x = x
		Game.player.chunk_y = y
		Game.statistics.steps += 1
		Game.reveal_around_player()
		Game.add_journal("Путешествие","Вы прибыли в чанк %d, %d — %s." % [x,y,chunk.biome.name])
		Events.player_moved.emit(x,y)
	selected_chunk = chunk
	_refresh_all()
	_show_poi(chunk)

func _show_poi(chunk: Dictionary) -> void:
	for child in detail_box.get_children(): child.queue_free()
	var title := Label.new()
	title.text = "ТОЧКА ИНТЕРЕСА"
	title.add_theme_color_override("font_color",Color("#f0c879"))
	detail_box.add_child(title)
	var poi: Dictionary = chunk.poi
	if poi.is_empty():
		_add_text("В этой области пока не обнаружено заметных объектов.")
		return
	_add_text("%s · опасность %d" % [poi.name,poi.danger])
	_add_text(poi.description)
	if Game.defeated_poi.has(poi.id) or Game.poi_states.get(poi.id,false):
		_add_text("Эта точка уже исследована.")
		return
	match poi.action:
		"combat":
			_add_action("Разведать",_scout.bind(poi,chunk))
			_add_action("Атаковать",_start_combat.bind(poi))
			_add_action("Обойти",_bypass.bind(poi,chunk))
		"loot": _add_action("Открыть тайник",_claim_cache.bind(poi,chunk))
		"shrine": _add_action("Использовать святилище",_use_shrine.bind(poi,chunk))
		"trade": _add_action("Купить зелье (12 золота)",_buy_potion.bind(poi,chunk))

func _scout(poi: Dictionary,chunk: Dictionary) -> void:
	Game.poi_states[poi.id] = true
	Game.add_journal("Разведка","Вы изучили расположение противника.")
	_show_poi(chunk)

func _bypass(poi: Dictionary,chunk: Dictionary) -> void:
	Game.poi_states[poi.id] = true
	Game.add_journal("Исследование","Вы обошли опасное место стороной.")
	_show_poi(chunk)

func _start_combat(poi: Dictionary) -> void:
	var result: Dictionary = Combat.start_encounter(poi)
	_show_message(result.message)
	_refresh_all()

func _claim_cache(poi: Dictionary,chunk: Dictionary) -> void:
	var gold := int(poi.reward)
	Game.player.gold += gold
	Game.statistics.gold_earned += gold
	Inventory.add_item("herb","Лесная трава","material",2,4)
	Game.poi_states[poi.id] = true
	Game.add_journal("Находка","В тайнике найдено %d золота и материалы." % gold)
	Game.gain_xp(20)
	_refresh_all()
	_show_poi(chunk)

func _use_shrine(poi: Dictionary,chunk: Dictionary) -> void:
	Game.player.hp = Game.player.hp_max
	Game.player.mana = Game.player.mana_max
	Game.poi_states[poi.id] = true
	Game.gain_xp(25)
	Game.add_journal("Святилище","Алтарь восстановил силы и даровал опыт.")
	_refresh_all()
	_show_poi(chunk)

func _buy_potion(poi: Dictionary,chunk: Dictionary) -> void:
	if int(Game.player.gold) < 12:
		_show_message("Недостаточно золота.")
		return
	Game.player.gold -= 12
	Inventory.add_item("potion_small","Малое зелье","consumable",1,12)
	Game.poi_states[poi.id] = true
	Game.add_journal("Торговля","Куплено малое зелье за 12 золота.")
	_refresh_all()
	_show_poi(chunk)

func _show_combat_controls() -> void:
	for child in detail_box.get_children(): child.queue_free()
	_add_text("БОЙ: %s · здоровье %d/%d" % [Game.active_combat.get("enemy_name","Враг"),Game.active_combat.get("enemy_hp",0),Game.active_combat.get("enemy_hp_max",0)])
	_add_action("Атаковать",_combat_attack)
	_add_action("Защищаться",_combat_defend)
	_add_action("Отступить",_combat_flee)

func _combat_attack() -> void:
	var result: Dictionary = Combat.player_attack()
	_show_message(result.message)
	_refresh_all()

func _combat_defend() -> void:
	var result: Dictionary = Combat.defend()
	_show_message(result.message)
	_refresh_all()

func _combat_flee() -> void:
	var result: Dictionary = Combat.flee()
	_show_message(result.message)
	_refresh_all()

func _spend_strength() -> void:
	if Game.player.stat_points <= 0: return
	Game.player.strength += 1
	Game.player.stat_points -= 1
	Game.add_journal("Развитие","Сила увеличена.")
	_refresh_all()

func _use_potion() -> void:
	_show_message(Inventory.use_potion())
	_refresh_all()

func _show_message(message: String) -> void:
	Game.add_journal("Система",message)

func _save_pressed() -> void:
	Saves.save_game()

func _load_pressed() -> void:
	if not Saves.load_game(): _show_message("Сохранение не найдено или повреждено.")
	_refresh_all()

func _recenter_map() -> void:
	map_view.offset = Vector2.ZERO
	map_view.queue_redraw()

func _on_journal_event(_category: String,_message: String) -> void:
	_refresh_journal()
	_refresh_status()

func _on_combat_changed(active: bool) -> void:
	if active: _show_combat_controls()
	else: _refresh_detail()
	_refresh_all()

func _refresh_status() -> void:
	if status_label == null: return
	status_label.text = "УР. %d\n❤ %d/%d\n✦ %d/%d\n◈ %d золота\nОчки: %d" % [Game.player.level,Game.player.hp,Game.player.hp_max,Game.player.mana,Game.player.mana_max,Game.player.gold,Game.player.stat_points]
	if map_view != null:
		map_view.set_world(WorldGen.get_nearby(Game.player.chunk_x,Game.player.chunk_y,4),Game.player.chunk_x,Game.player.chunk_y)

func _refresh_journal() -> void:
	if journal_box == null: return
	journal_box.clear()
	for entry in Game.journal:
		journal_box.append_text("[color=#8da2b5]%s[/color] [color=#f0c879]%s[/color]\n%s\n\n" % [str(entry.get("time","")),str(entry.get("category","")),str(entry.get("message",""))])

func _refresh_all() -> void:
	_refresh_status()
	_refresh_journal()
	if Game.active_combat.get("active",false): _show_combat_controls()
	else: _refresh_detail()

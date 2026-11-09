extends Control
class_name WorldMapView
signal cell_selected(x: int,y: int)
var chunks: Array[Dictionary] = []
var center_x := 0
var center_y := 0
var cell_size := 82.0
var offset := Vector2.ZERO
var drag_origin := Vector2.ZERO
var press_position := Vector2.ZERO
var dragging := false
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(500,400)
func set_world(data: Array[Dictionary],px: int,py: int) -> void:
	chunks = data
	center_x = px
	center_y = py
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#101923"))
	var origin := size/2.0+offset
	for c in chunks:
		var dx := int(c.x)-center_x
		var dy := int(c.y)-center_y
		var rect := Rect2(origin+Vector2(dx*cell_size,dy*cell_size)-Vector2(cell_size/2,cell_size/2),Vector2(cell_size-4,cell_size-4))
		var color := _biome_color(str(c.biome.id))
		if not Game.discovered_chunks.has(c.key): color = Color("#080d13")
		draw_rect(rect,color)
		draw_rect(rect,Color("#34495a"),false,1.0)
		if Game.discovered_chunks.has(c.key):
			draw_string(ThemeDB.fallback_font,rect.position+Vector2(5,20),str(c.biome.name),HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-8,10,Color("#e6edf3"))
			if not c.poi.is_empty():
				var done := Game.defeated_poi.has(c.poi.id) or bool(Game.poi_states.get(c.poi.id,false))
				draw_string(ThemeDB.fallback_font,rect.position+Vector2(25,52),"✓" if done else str(c.poi.glyph),HORIZONTAL_ALIGNMENT_LEFT,24,20,Color("#ffffff"))
		if dx == 0 and dy == 0: draw_rect(rect.grow(2),Color("#f4c76b"),false,3)
	draw_circle(origin,5,Color.WHITE)
	draw_string(ThemeDB.fallback_font,origin+Vector2(10,-8),"Вы",HORIZONTAL_ALIGNMENT_LEFT,35,12,Color.WHITE)
func _biome_color(id: String) -> Color:
	match id:
		"forest": return Color("#244d3b")
		"plains": return Color("#52683d")
		"desert": return Color("#9b7843")
		"swamp": return Color("#405348")
		"mountains": return Color("#59616b")
		"wastes": return Color("#67534c")
		"arcane": return Color("#51446f")
		_: return Color("#293746")
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed: cell_size = minf(120,cell_size*1.12); queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed: cell_size = maxf(48,cell_size/1.12); queue_redraw()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed: dragging = true; drag_origin = event.position-offset
			else:
				if dragging and (event.position-(drag_origin+offset)).length() < 7:
					var local := event.position-(size/2.0+offset)
					cell_selected.emit(center_x+roundi(local.x/cell_size),center_y+roundi(local.y/cell_size))
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		offset = event.position-drag_origin
		queue_redraw()

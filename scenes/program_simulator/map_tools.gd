class_name MapTools extends PanelContainer

const icon_show = preload("res://assets/images/icons/show.png")
const icon_hide = preload("res://assets/images/icons/hide.png")

@export var map_view: MapView
@export var info_label: Label
@export var cursor_preview: CursorPreview

@onready var main_container: MarginContainer = $MainContainer
@onready var toggle_button: Button = $ToggleButton
@onready var pen_size_label: Label = $MainContainer/VBoxContainer/HBoxContainer/PenSizeLabel
@onready var pen_type: OptionButton = $MainContainer/VBoxContainer/HBoxContainer2/PenType
@onready var pen_active: CheckButton = $MainContainer/VBoxContainer/PenActive

var is_drawing: bool = false
var info_label_enabled: bool = false

func _ready() -> void:
	toggle_button.tooltip_text = tr("program_simulator.map_tools.tooltip.show")
	main_container.hide()
	
	if is_instance_valid(cursor_preview) and is_instance_valid(map_view):
		cursor_preview.map_view = map_view
	
	if is_instance_valid(map_view):
		var viewport_container = map_view.get_parent().get_parent() as SubViewportContainer
		if viewport_container:
			viewport_container.gui_input.connect(on_map_gui_input)

func on_map_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if info_label_enabled and is_instance_valid(map_view):
			var tile_map = map_view.tile_map
			var mouse_world_pos = map_view.get_global_mouse_position()
			var local_pos = tile_map.to_local(mouse_world_pos)
			var map_pos = tile_map.local_to_map(local_pos)
			var pointed_material = map_view.get_material_at(map_pos)
			
			print_material_info(pointed_material)

		if is_drawing and pen_active.button_pressed:
			draw_on_map()

	elif event is InputEventMouseButton:
		if not pen_active.button_pressed: 
			is_drawing = false
			return
			
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_drawing = event.pressed
			if is_drawing:
				draw_on_map()

func draw_on_map() -> void:
	if not is_instance_valid(map_view) or not is_instance_valid(cursor_preview): return
	
	var tile_map = map_view.tile_map
	var mouse_world_pos = map_view.get_global_mouse_position()
	var local_pos = tile_map.to_local(mouse_world_pos)
	var map_pos = tile_map.local_to_map(local_pos)
	
	map_view.paint_at(Vector2(map_pos), cursor_preview.brush_steps, pen_type.selected as MapView.MaterialType)

func print_material_info(pointed_material: MapView.MaterialType) -> void:
	if not info_label_enabled: return
	
	match pointed_material:
		MapView.MaterialType.VOID: info_label.text = tr("map.material_type.void")
		MapView.MaterialType.SOFT_ROCK: info_label.text = tr("map.material_type.soft_rock")
		MapView.MaterialType.HARD_ROCK: info_label.text = tr("map.material_type.hard_rock")
		MapView.MaterialType.BEDROCK: info_label.text = tr("map.material_type.bedrock")
		MapView.MaterialType.GOLD: info_label.text = tr("map.material_type.gold")
		MapView.MaterialType.ROBOT: info_label.text = tr("map.material_type.robot")

func get_texture_mouse_position(local_mouse_pos: Vector2) -> Vector2i:
	if not map_view or not map_view.texture:
		return Vector2i(-1, -1)

	var texture_size = Vector2(map_view.MAP_SIZE)
	var control_size = map_view.size
	var scale_x = control_size.x / texture_size.x
	var scale_y = control_size.y / texture_size.y
	var final_scale = min(scale_x, scale_y)
	var drawn_size = texture_size * final_scale
	var offset_x = (control_size.x - drawn_size.x) / 2.0
	var offset_y = (control_size.y - drawn_size.y) / 2.0
	var pos_on_drawn_rect = local_mouse_pos - Vector2(offset_x, offset_y)
	var texture_pos = pos_on_drawn_rect / final_scale
	
	return Vector2i(texture_pos)

func on_toggle_button_pressed() -> void:
	if main_container.visible:
		main_container.hide()
		toggle_button.icon = icon_show
		toggle_button.tooltip_text = tr("program_simulator.map_tools.tooltip.show")
	else:
		main_container.show()
		toggle_button.icon = icon_hide
		toggle_button.tooltip_text = tr("program_simulator.map_tools.tooltip.hide")

func on_pen_size_slider_value_changed(value: float) -> void:
	pen_size_label.text = str(int(value))
	
	cursor_preview.set_size(int(value))

func on_clear_button_pressed() -> void:
	if not is_instance_valid(map_view): return
	
	map_view.clear_map()

func on_random_button_pressed() -> void:
	if not is_instance_valid(map_view): return
	
	map_view.generate_world()

func on_fill_button_pressed() -> void:
	map_view.clear_map(pen_type.selected as MapView.MaterialType)

func enable_info_label() -> void:
	info_label_enabled = true

func disable_info_label() -> void:
	info_label_enabled = false
	info_label.text = ""

func on_mouse_entered() -> void:
	cursor_preview.toggle(false)

func on_mouse_exited() -> void:
	cursor_preview.toggle(pen_active.button_pressed)

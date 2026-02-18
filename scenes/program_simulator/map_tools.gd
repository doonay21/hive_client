class_name MapTools extends PanelContainer

const icon_show = preload("res://assets/images/icons/show.png")
const icon_hide = preload("res://assets/images/icons/hide.png")

@export var map: Map
@export var info_label: Label

@onready var main_container: MarginContainer = $MainContainer
@onready var toggle_button: Button = $ToggleButton
@onready var pen_size_label: Label = $MainContainer/VBoxContainer/HBoxContainer/PenSizeLabel
@onready var pen_type: OptionButton = $MainContainer/VBoxContainer/HBoxContainer2/PenType
@onready var cursor_preview: CursorPreview = $CursorPreview
@onready var pen_active: CheckButton = $MainContainer/VBoxContainer/PenActive

var brush_clicked: bool = false
var info_label_enabled: bool = false

func _ready() -> void:
	toggle_button.tooltip_text = tr("program_simulator.map_tools.tooltip.show")
	main_container.hide()
	
	var map_container: Control = map.get_parent()
	map_container.gui_input.connect(on_map_gui_input)

func on_map_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var img_pos_i = get_texture_mouse_position(event.position)
		var img_pos = Vector2(img_pos_i)
		
		print_material_info(map.get_material_at(img_pos_i))
		
		if not pen_active.button_pressed: return
		
		var is_drawing = false
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				is_drawing = true
		elif event is InputEventMouseMotion:
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
				is_drawing = true

		if is_drawing:
			if img_pos_i.x >= 0 and img_pos_i.x < map.MAP_SIZE.x and img_pos_i.y >= 0 and img_pos_i.y < map.MAP_SIZE.y:
				map.paint_at(img_pos, cursor_preview.brush_steps, pen_type.selected as Map.MaterialType)

func print_material_info(pointed_material: Map.MaterialType) -> void:
	if not info_label_enabled: return
	
	match pointed_material:
		Map.MaterialType.VOID: info_label.text = tr("map.material_type.void")
		Map.MaterialType.SOFT_ROCK: info_label.text = tr("map.material_type.soft_rock")
		Map.MaterialType.HARD_ROCK: info_label.text = tr("map.material_type.hard_rock")
		Map.MaterialType.BEDROCK: info_label.text = tr("map.material_type.bedrock")
		Map.MaterialType.GOLD: info_label.text = tr("map.material_type.gold")
		Map.MaterialType.ROBOT: info_label.text = tr("map.material_type.robot")

func get_texture_mouse_position(local_mouse_pos: Vector2) -> Vector2i:
	if not map or not map.texture:
		return Vector2i(-1, -1)

	var texture_size = Vector2(map.MAP_SIZE)
	var control_size = map.size
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
	if not is_instance_valid(map): return
	
	map.clear_map()

func on_random_button_pressed() -> void:
	if not is_instance_valid(map): return
	
	map.generate_world()

func on_fill_button_pressed() -> void:
	map.clear_map(pen_type.selected as Map.MaterialType)

func enable_info_label() -> void:
	info_label_enabled = true

func disable_info_label() -> void:
	info_label_enabled = false
	info_label.text = ""

func on_mouse_entered() -> void:
	cursor_preview.toggle(false)

func on_mouse_exited() -> void:
	cursor_preview.toggle(pen_active.button_pressed)

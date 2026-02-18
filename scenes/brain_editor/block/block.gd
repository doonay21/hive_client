class_name Block extends Control

signal edit_requested(uuid: String)
signal context_menu_requested(uuid: String, global_pos: Vector2)

@export var block_data: BlockData
@export var is_toolbox_source: bool = false

@onready var background_container: Control = %BackgroundContainer
@onready var background: TextureRect = %Background
@onready var icon: TextureRect = %Icon
@onready var display_name_label: Label = %DisplayName
@onready var icon_big: TextureRect = %IconBig
@onready var value_drag: Label = %ValueDrag
@onready var labels: Control = $Labels
@onready var label_nodes: Array[Label] = [ $Labels/Top, $Labels/Right, $Labels/Bottom, $Labels/Left ]
@onready var port_sprites: Array[TextureRect] = [ %PortTop, %PortRight, %PortBottom, %PortLeft ]

var custom_block_uuid: String = ""
var rotation_index: int = 0
var rotation_tween: Tween
var target_rotation: float = 0.0
var labels_tween: Tween

static func parse_save_to_program_data(save_data: Dictionary) -> Dictionary:
	return BlockSerializer.parse_save_to_program_data(save_data)

func _ready() -> void:
	if block_data:
		load_data()
		
		target_rotation = rotation_index * 90.0
		background_container.rotation_degrees = target_rotation
		update_visuals()
	
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)
	
	labels.modulate.a = 0.0
	labels.visible = false
	
	Events.custom_block_changed.connect(on_events_custom_block_changed)

func initialize(data: Dictionary) -> void:
	block_data = data["resource"]
	
	if "rotation_index" in data:
		rotation_index = data["rotation_index"]
	
	if "custom_block_uuid" in data:
		custom_block_uuid = data["custom_block_uuid"]
	
	load_data()
	
	if value_drag and "stored_value" in data:
		value_drag.set_editor_value(data["stored_value"])
		
	target_rotation = rotation_index * 90.0
	background_container.rotation_degrees = target_rotation
	update_visuals()

func load_data() -> void:
	BlockVisuals.load_data(self)

func update_visuals() -> void:
	BlockVisuals.update_visuals(self)

func get_save_data() -> Dictionary:
	return BlockSerializer.get_save_data(self)

func get_program_data() -> Dictionary:
	return BlockSerializer.get_program_data(self)

func load_save_data(saved_data: Dictionary) -> void:
	BlockSerializer.load_save_data(self, saved_data)
	
	load_data()
	
	if "stored_value" in saved_data and value_drag and value_drag.visible and "value" in value_drag:
		value_drag.set_editor_value(saved_data["stored_value"])
		
	target_rotation = rotation_index * 90.0
	background_container.rotation_degrees = target_rotation
	update_visuals()

func _get_drag_data(at_position: Vector2) -> Variant:
	if not block_data: return null
	
	var preview = create_drag_preview(at_position)
	set_drag_preview(preview)

	var drag_info = {
		"resource": block_data,
		"node_ref": self,
		"is_source": is_toolbox_source,
		"grab_offset": at_position,
		"rotation_index": rotation_index,
		"custom_block_uuid": custom_block_uuid
	}
	
	if value_drag and value_drag.visible:
		drag_info["stored_value"] = value_drag.value
	
	if not is_toolbox_source:
		visible = false
		
	return drag_info

func create_drag_preview(at_position: Vector2) -> Control:
	var preview = self.duplicate()
	preview.script = null
	preview.process_mode = Node.PROCESS_MODE_DISABLED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if value_drag:
		var preview_val = preview.find_child("ValueDrag", true, false)
		if preview_val:
			preview_val.script = null
			preview_val.text = value_drag.text
			preview_val.horizontal_alignment = value_drag.horizontal_alignment
	
	var preview_bg = preview.get_node_or_null("BackgroundContainer")
	if preview_bg:
		preview_bg.rotation_degrees = rotation_index * 90
	
	var start_scale = Vector2.ONE
	var target_scale = Vector2(1.1, 1.1)
	preview.scale = start_scale
	preview.position = -at_position * start_scale
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(preview, "scale", target_scale, 0.15)
	tween.tween_property(preview, "position", -at_position * target_scale, 0.15)
	
	var control_wrapper = Control.new()
	control_wrapper.add_child(preview)
	control_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control_wrapper

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		if not is_drag_successful() and not is_toolbox_source:
			visible = true

func _gui_input(event: InputEvent) -> void:
	if is_toolbox_source:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
				if not custom_block_uuid.is_empty():
					edit_requested.emit(custom_block_uuid)
					accept_event()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				if not custom_block_uuid.is_empty():
					context_menu_requested.emit(custom_block_uuid, get_global_mouse_position())
					accept_event()
		return

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				rotate_counter_clockwise()
				accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				rotate_clockwise()
				accept_event()
			MOUSE_BUTTON_MIDDLE:
				delete_block_animated()
				accept_event()

func rotate_clockwise():
	rotation_index = (rotation_index + 1) % 4
	target_rotation += 90.0
	BlockVisuals.animate_rotation(self)
	BlockVisuals.animate_labels_change(self)

func rotate_counter_clockwise():
	rotation_index = (rotation_index - 1 + 4) % 4
	target_rotation -= 90.0
	BlockVisuals.animate_rotation(self)
	BlockVisuals.animate_labels_change(self)

func delete_block_animated():
	mouse_filter = Control.MOUSE_FILTER_IGNORE 
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)

func on_mouse_entered() -> void:
	if is_toolbox_source:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		BlockVisuals.animate_labels(self, 1.0)
	
	if not custom_block_uuid.is_empty():
		var description = block_data.info_text if block_data else ""
		var edit_hint = tr("brain_editor.custom_blocks.double_click")
		var final_text = ""
		
		if description.is_empty():
			final_text = edit_hint
		else:
			final_text = "%s (%s)" % [description, edit_hint]
			
		Events.info_text_requested.emit(final_text)
	elif block_data and not block_data.info_text.is_empty():
		Events.info_text_requested.emit(block_data.info_text)

func on_mouse_exited() -> void:
	if not is_toolbox_source:
		BlockVisuals.animate_labels(self, 0.0)
	
	Events.info_text_hide_requested.emit()

func on_events_custom_block_changed(uuid: String, new_ports: Array) -> void:
	if uuid != custom_block_uuid: return
	
	if block_data:
		var typed_ports: Array[BlockData.Port] = []
		for p in new_ports:
			typed_ports.append(p as BlockData.Port)
			
		block_data.ports = typed_ports
		
		update_visuals()
		BlockVisuals.update_labels_text(self)

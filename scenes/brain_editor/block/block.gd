class_name Block extends Control

signal edit_requested(uuid: String)
signal context_menu_requested(uuid: String, global_pos: Vector2)

const BLOCK_RESOURCE_PREFIX = "res://scenes/brain_editor/blocks/"
const TEX_NONE = preload("res://assets/images/brain_editor/conn_none.png")
const TEX_IN = preload("res://assets/images/brain_editor/conn_in.png")
const TEX_OUT = preload("res://assets/images/brain_editor/conn_out.png")
const TEX_MISSING = preload("res://assets/images/brain_editor/block_icons/missing.png")

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
	var program_data: Dictionary = {}

	if "rotation_index" in save_data:
		program_data["rot"] = save_data["rotation_index"]
	else:
		program_data["rot"] = 0

	if "stored_value" in save_data:
		program_data["val"] = save_data["stored_value"]

	if "custom_block_uuid" in save_data and not save_data["custom_block_uuid"].is_empty():
		program_data["op"] = BlockData.Op.CUSTOM
		program_data["uuid"] = save_data["custom_block_uuid"]
		return program_data

	if "resource" in save_data and not save_data["resource"].is_empty():
		var resource_path = BLOCK_RESOURCE_PREFIX.path_join(save_data["resource"])
		
		if ResourceLoader.exists(resource_path):
			var block_res = load(resource_path)
			if block_res is BlockData:
				program_data["op"] = block_res.op
	
	if not "op" in program_data:
		return {}

	return program_data

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
	if not block_data: return

	match block_data.display:
		BlockData.Display.ICON_TEXT:
			icon.texture = block_data.icon
			display_name_label.text = block_data.display_name
			icon.visible = true
			display_name_label.visible = true
			icon_big.visible = false
			value_drag.visible = false
		BlockData.Display.BIG_ICON:
			icon_big.texture = block_data.icon
			icon.visible = false
			display_name_label.visible = false
			value_drag.visible = false
			icon_big.visible = true
		BlockData.Display.ICON_VALUE_DRAG:
			icon.texture = block_data.icon
			icon.visible = true
			display_name_label.visible = false
			value_drag.visible = true
			icon_big.visible = false
	
	background_container.modulate = block_data.get_style_color()
	
	if value_drag:
		value_drag.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_toolbox_source else Control.MOUSE_FILTER_STOP
		
		value_drag.setup(
			block_data.value_mode,
			block_data.custom_min,
			block_data.custom_max,
			block_data.value_strings 
		)

	update_labels_text()

func update_visuals() -> void:
	if not block_data: return
	
	for i in range(4):
		var port_def = block_data.ports[i]
		var sprite = port_sprites[i]
		
		match port_def:
			BlockData.Port.NONE:
				sprite.texture = TEX_NONE
			BlockData.Port.INPUT:
				sprite.texture = TEX_IN
			BlockData.Port.OUTPUT:
				sprite.texture = TEX_OUT

func get_save_data() -> Dictionary:
	var save_data: Dictionary = {
		"resource": "",
		"rotation_index": rotation_index,
		"custom_block_uuid": custom_block_uuid
	}
	
	if block_data and custom_block_uuid.is_empty() and not block_data.resource_path.is_empty():
		save_data["resource"] = block_data.resource_path.trim_prefix(BLOCK_RESOURCE_PREFIX)
	
	if value_drag and value_drag.visible and "value" in value_drag:
		save_data["stored_value"] = value_drag.value
	
	return save_data

func get_program_data() -> Dictionary:
	var save_data = get_save_data()
	
	return Block.parse_save_to_program_data(save_data)

func load_save_data(saved_data: Dictionary) -> void:
	if "custom_block_uuid" in saved_data and not saved_data["custom_block_uuid"].is_empty():
		custom_block_uuid = saved_data["custom_block_uuid"]
		
		var block_model = BlockModel.where("uuid", custom_block_uuid)
		
		if block_model:
			block_data = CustomBlockData.new(
				block_model.name,
				block_model.ports,
				block_model.description
			)
		else:
			create_missing_block_visuals()
	elif "resource" in saved_data and not saved_data["resource"].is_empty():
		var resource_path = BLOCK_RESOURCE_PREFIX.path_join(saved_data["resource"])
		
		if ResourceLoader.exists(resource_path):
			block_data = load(resource_path)

	if "rotation_index" in saved_data:
		rotation_index = saved_data["rotation_index"]

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
	animate_rotation()
	animate_labels_change()

func rotate_counter_clockwise():
	rotation_index = (rotation_index - 1 + 4) % 4
	target_rotation -= 90.0
	animate_rotation()
	animate_labels_change()

func animate_rotation():
	if rotation_tween: rotation_tween.kill()
	
	rotation_tween = create_tween()
	rotation_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	rotation_tween.tween_property(background_container, "rotation_degrees", target_rotation, 0.2)

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
		animate_labels(1.0)
	
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
		animate_labels(0.0)
	
	Events.info_text_hide_requested.emit()

func animate_labels(target_alpha: float) -> void:
	if labels_tween: labels_tween.kill()
	
	labels_tween = create_tween()
	labels_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if target_alpha > 0.0:
		labels.visible = true
		
	labels_tween.tween_property(labels, "modulate:a", target_alpha, 0.2)
	
	if target_alpha == 0.0:
		labels_tween.tween_callback(labels.hide)

func update_labels_text() -> void:
	if not block_data: return

	for i in range(4):
		var label: Label = label_nodes[i]
		if label:
			var data_index = (i - rotation_index + 4) % 4
			label.text = block_data.port_labels[data_index]

func animate_labels_change() -> void:
	if not labels.visible or labels.modulate.a == 0.0:
		update_labels_text()
		return

	if labels_tween: labels_tween.kill()
	labels_tween = create_tween()
	labels_tween.tween_property(labels, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	labels_tween.tween_callback(update_labels_text)
	labels_tween.tween_property(labels, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func on_events_custom_block_changed(uuid: String, new_ports: Array) -> void:
	if uuid != custom_block_uuid: return
	
	if block_data:
		var typed_ports: Array[BlockData.Port] = []
		for p in new_ports:
			typed_ports.append(p as BlockData.Port)
			
		block_data.ports = typed_ports
		
		update_visuals()
		update_labels_text()

func create_missing_block_visuals() -> void:
	block_data = CustomBlockData.new(
		tr("brain_editor.new_program.missing.title"), 
		[BlockData.Port.NONE, BlockData.Port.NONE, BlockData.Port.NONE, BlockData.Port.NONE]
	)
	
	block_data.style = BlockData.Style.CUSTOM
	block_data.info_text = tr("brain_editor.new_program.missing.nf").format({ "uuid": custom_block_uuid })
	
	background_container.modulate = Color(1.0, 0.2, 0.2, 1.0) 
	
	block_data.icon = TEX_MISSING

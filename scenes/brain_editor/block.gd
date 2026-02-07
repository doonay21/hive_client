class_name Block extends Control

const TEX_NONE = preload("res://assets/images/brain_editor/conn_none.png")
const TEX_IN = preload("res://assets/images/brain_editor/conn_in.png")
const TEX_OUT = preload("res://assets/images/brain_editor/conn_out.png")

@export var block_data: BlockData
@export var is_toolbox_source: bool = false

@onready var background_container: Control = %BackgroundContainer
@onready var background: TextureRect = %Background
@onready var icon: TextureRect = %Icon
@onready var display_name_label: Label = %DisplayName
@onready var icon_big: TextureRect = %IconBig
@onready var value_drag: Label = %ValueDrag
@onready var labels: Control = $Labels

@onready var port_sprites: Array[TextureRect] = [
	%PortTop,
	%PortRight,
	%PortBottom,
	%PortLeft
]

var rotation_index: int = 0
var rotation_tween: Tween
var target_rotation: float = 0.0
var labels_tween: Tween

func _ready() -> void:
	if block_data:
		load_data()
		
		target_rotation = rotation_index * 90.0
		background_container.rotation_degrees = target_rotation
		update_visuals()
	
	if not is_toolbox_source:
		mouse_entered.connect(on_mouse_entered)
		mouse_exited.connect(on_mouse_exited)
	
	labels.modulate.a = 0.0
	labels.visible = false

func initialize(data: Dictionary) -> void:
	block_data = data["resource"]
	
	if "rotation_index" in data:
		rotation_index = data["rotation_index"]
	
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
	
	for i in range(4):
		var label: Label = labels.get_child(i)
		
		if label:
			label.text = block_data.port_labels[i]

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

func _get_drag_data(at_position: Vector2) -> Variant:
	if not block_data: return null
	
	var preview = create_drag_preview(at_position)
	set_drag_preview(preview)

	var drag_info = {
		"resource": block_data,
		"node_ref": self,
		"is_source": is_toolbox_source,
		"grab_offset": at_position,
		"rotation_index": rotation_index
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
	if is_toolbox_source: return

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				rotate_counter_clockwise()
				accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				rotate_clockwise()
				accept_event()
			MOUSE_BUTTON_RIGHT:
				delete_block_animated()
				accept_event()

func rotate_clockwise():
	rotation_index = (rotation_index + 1) % 4
	target_rotation += 90.0
	animate_rotation()

func rotate_counter_clockwise():
	rotation_index = (rotation_index - 1 + 4) % 4
	target_rotation -= 90.0
	animate_rotation()

func animate_rotation():
	if rotation_tween: rotation_tween.kill()
	
	rotation_tween = create_tween()
	rotation_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	rotation_tween.tween_property(background_container, "rotation_degrees", target_rotation, 0.2)

func get_port_at_side(side: int) -> int:
	if not block_data: return BlockData.Port.NONE
	var original_index = (side - rotation_index + 4) % 4
	return block_data.ports[original_index]

func delete_block_animated():
	mouse_filter = Control.MOUSE_FILTER_IGNORE 
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)

func on_mouse_entered() -> void:
	animate_labels(1.0)

func on_mouse_exited() -> void:
	animate_labels(0.0)

func animate_labels(target_alpha: float) -> void:
	if labels_tween: labels_tween.kill()
	
	labels_tween = create_tween()
	labels_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if target_alpha > 0.0:
		labels.visible = true
		
	labels_tween.tween_property(labels, "modulate:a", target_alpha, 0.2)
	
	if target_alpha == 0.0:
		labels_tween.tween_callback(labels.hide)

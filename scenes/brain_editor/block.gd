class_name Block extends Control

const TEX_NONE = preload("res://assets/images/brain_editor/conn_none.png")
const TEX_IN = preload("res://assets/images/brain_editor/conn_in.png")
const TEX_OUT = preload("res://assets/images/brain_editor/conn_out.png")

@export var block_data: BlockData
@export var is_toolbox_source: bool = false

@onready var background_container: Control = %BackgroundContainer
@onready var background: TextureRect = %Background
@onready var icon: TextureRect = %Icon
@onready var display_name: Label = %DisplayName
@onready var icon_big: TextureRect = %IconBig

@onready var port_sprites = [
	%PortTop,
	%PortRight,
	%PortBottom,
	%PortLeft
]

var rotation_index: int = 0
var rotation_tween: Tween
var target_rotation: float = 0.0

func _ready():
	if block_data:
		load_data()
		
		target_rotation = rotation_index * 90.0
		
		update_visuals()

func load_data():
	if block_data.display == BlockData.Display.ICON_TEXT:
		icon.texture = block_data.icon
		display_name.text = block_data.display_name
	else:
		icon_big.texture = block_data.icon
		display_name.text = ""
		icon.visible = false
		display_name.visible = false
	
	background_container.modulate = block_data.get_style_color()

func _get_drag_data(at_position: Vector2) -> Variant:
	if not block_data: return
	
	var preview = self.duplicate()
	preview.script = null
	preview.process_mode = Node.PROCESS_MODE_DISABLED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var preview_bg = preview.get_node("BackgroundContainer")
	if preview_bg:
		preview_bg.rotation_degrees = rotation_index * 90
	
	var start_scale = Vector2.ONE
	var target_scale = Vector2(1.1, 1.1)
	var start_pos = -at_position * start_scale
	var target_pos = -at_position * target_scale
	
	preview.scale = start_scale
	preview.position = start_pos
	
	var control = Control.new()
	control.add_child(preview)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(control)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(preview, "scale", target_scale, 0.15)
	tween.tween_property(preview, "position", target_pos, 0.15)

	var drag_info = {
		"resource": block_data,
		"node_ref": self,
		"is_source": is_toolbox_source,
		"grab_offset": at_position,
		"rotation_index": rotation_index
	}
	
	if not is_toolbox_source:
		visible = false
		
	return drag_info

func update_visuals():
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

func rotate_clockwise():
	rotation_index = (rotation_index + 1) % 4
	
	target_rotation += 90.0
	animate_rotation()

func rotate_counter_clockwise():
	rotation_index = (rotation_index - 1 + 4) % 4
	
	target_rotation -= 90.0
	animate_rotation()

func get_port_at_side(side: int) -> int:
	if not block_data: return BlockData.Port.NONE
	
	var original_index = (side - rotation_index + 4) % 4
	
	return block_data.ports[original_index]

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			if not is_toolbox_source:
				visible = true

func _gui_input(event: InputEvent) -> void:
	if is_toolbox_source: return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			rotate_counter_clockwise()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			rotate_clockwise()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			accept_event()
			delete_block_animated()

func animate_rotation():
	if rotation_tween: rotation_tween.kill()
	
	rotation_tween = create_tween()
	rotation_tween.set_trans(Tween.TRANS_QUART) 
	rotation_tween.set_ease(Tween.EASE_OUT)
	
	rotation_tween.tween_property(background_container, "rotation_degrees", target_rotation, 0.2)

func delete_block_animated():
	mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)

extends Control

@export var block_data: BlockData

@onready var background: TextureRect = %Background
@onready var icon: TextureRect = %Icon
@onready var display_name: Label = %DisplayName

func _ready():
	if block_data:
		load_data()

func load_data():
	icon.texture = block_data.icon
	display_name.text = block_data.display_name
	self_modulate = block_data.base_color

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not block_data: return
	
	var preview = self.duplicate()
	preview.script = null
	preview.process_mode = Node.PROCESS_MODE_DISABLED
	
	var control = Control.new()
	control.add_child(preview)
	preview.position = -0.5 * preview.custom_minimum_size
	set_drag_preview(control)
	
	return block_data

extends NinePatchRect

@export var block_data: BlockData 

@onready var icon: TextureRect = %Icon
@onready var display_name: Label = %DisplayName
@onready var arrow_top: TextureRect = %ArrowTop
@onready var arrow_right: TextureRect = %ArrowRight
@onready var arrow_bottom: TextureRect = %ArrowBottom
@onready var arrow_left: TextureRect = %ArrowLeft

func _ready():
	if block_data:
		icon.texture = block_data.icon
		display_name.text = block_data.display_name
		
		self_modulate = block_data.base_color
		tooltip_text = block_data.display_name
		
		set_arrows()

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

func set_arrows() -> void:
	arrow_top.visible = block_data.arrow_top != BlockData.ArrowStyle.Hidden
	arrow_top.flip_v = block_data.arrow_top == BlockData.ArrowStyle.In
	arrow_right.visible = block_data.arrow_right != BlockData.ArrowStyle.Hidden
	arrow_right.flip_h = block_data.arrow_right == BlockData.ArrowStyle.In
	arrow_bottom.visible = block_data.arrow_bottom != BlockData.ArrowStyle.Hidden
	arrow_bottom.flip_v = block_data.arrow_bottom == BlockData.ArrowStyle.Out
	arrow_left.visible = block_data.arrow_left != BlockData.ArrowStyle.Hidden
	arrow_left.flip_h = block_data.arrow_left == BlockData.ArrowStyle.Out

class_name CustomBlockData extends BlockData

var custom_block_id: int = -1

func _init(p_id: int, p_name: String, p_ports: Array[Port]) -> void:
	custom_block_id = p_id
	display_name = p_name
	display = Display.ICON_TEXT
	style = Style.CUSTOM
	ports = p_ports
	icon = preload("res://assets/images/brain_editor/block_icons/custom_block.png")

class_name CustomBlockData extends BlockData

func _init(p_name: String, p_ports: Array) -> void:
	display_name = p_name
	display = Display.ICON_TEXT
	style = Style.CUSTOM
	ports = p_ports
	icon = preload("res://assets/images/brain_editor/block_icons/custom_block.png")

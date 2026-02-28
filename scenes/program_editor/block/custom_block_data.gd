class_name CustomBlockData extends BlockData

func _init(p_name: String, p_ports: Array, p_description: String = "") -> void:
	display_name = p_name
	display = Display.ICON_TEXT
	style = Style.CUSTOM
	ports = p_ports
	info_text = p_description
	icon = preload("res://assets/images/program_editor/block_icons/custom_block.png")
	op = BlockData.Op.CUSTOM

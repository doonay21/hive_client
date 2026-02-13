class_name CustomBlocks extends VBoxContainer

signal add_new_block

func on_new_block_button_pressed() -> void:
	add_new_block.emit()

extends Control

signal add_new_block

func on_rich_text_label_meta_clicked(meta: Variant) -> void:
	if meta == "add_new_block":
		add_new_block.emit()

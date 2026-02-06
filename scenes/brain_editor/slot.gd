class_name Slot extends MarginContainer

const BLOCK_SCENE = preload("res://scenes/brain_editor/block.tscn") 

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var has_data = typeof(data) == TYPE_DICTIONARY and data.has("resource")
	return has_data and not has_block()

func has_block() -> bool:
	for child in get_children():
		if child is Block:
			return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var new_block = BLOCK_SCENE.instantiate()
	new_block.block_data = data["resource"]
	new_block.is_toolbox_source = false 
	add_child(new_block)
	
	if "rotation_index" in data:
		new_block.rotation_index = data["rotation_index"]
		new_block.target_rotation = new_block.rotation_index * 90.0
		new_block.background_container.rotation_degrees = new_block.rotation_index * 90
	
	if "grab_offset" in data:
		new_block.position = at_position - data["grab_offset"]
	else:
		new_block.position = at_position - (new_block.custom_minimum_size / 2)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(new_block, "position", Vector2.ZERO, 0.2)
	
	new_block.scale = Vector2(1.1, 1.1) 
	tween.parallel().tween_property(new_block, "scale", Vector2.ONE, 0.2)
	tween.finished.connect(func(): new_block.set_anchors_preset(Control.PRESET_FULL_RECT))
	
	if not data["is_source"]:
		data["node_ref"].queue_free()

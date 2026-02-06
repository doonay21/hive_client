class_name Slot extends MarginContainer

const BLOCK_SCENE = preload("res://scenes/brain_editor/block.tscn") 

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("resource") and not has_block()

func has_block() -> bool:
	for child in get_children():
		if child is Block and not child.is_queued_for_deletion():
			return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var new_block: Block = BLOCK_SCENE.instantiate()
	new_block.is_toolbox_source = false
	add_child(new_block)
	
	new_block.initialize(data)
	
	if "grab_offset" in data:
		new_block.position = at_position - data["grab_offset"]
	else:
		new_block.position = at_position - (new_block.custom_minimum_size / 2)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(new_block, "position", Vector2.ZERO, 0.2)
	
	new_block.scale = Vector2(1.1, 1.1) 
	tween.parallel().tween_property(new_block, "scale", Vector2.ONE, 0.2)
	tween.finished.connect(func(): new_block.set_anchors_preset(Control.PRESET_FULL_RECT))
	
	if not data.get("is_source", false):
		var old_node = data.get("node_ref")
		if is_instance_valid(old_node):
			old_node.queue_free()

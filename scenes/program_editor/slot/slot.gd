class_name Slot extends MarginContainer

const BLOCK_SCENE = preload("res://scenes/program_editor/block/block.tscn")
const COLOR_DEFAULT = Color("ffffff05")
const COLOR_HIGHLIGHT = Color("ffffff1a")

@onready var background: TextureRect = $TextureRect

var program_grid: ProgramGrid
var highlight_tween: Tween

func _ready() -> void:
	mouse_exited.connect(reset_visuals)
	
	if background:
		background.self_modulate = COLOR_DEFAULT

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or has_block() or not data.has("resource"):
		return false
	
	animate_highlight()
	
	return true

func has_block() -> bool:
	for child in get_children():
		if child is Block and not child.is_queued_for_deletion():
			return true
	return false

func get_block() -> Block:
	for child in get_children():
		if child is Block and not child.is_queued_for_deletion():
			return child
	return null

func _drop_data(at_position: Vector2, data: Variant) -> void:
	reset_visuals()
	
	var is_custom_target = program_grid.is_block
	var is_custom_data = not data.get("custom_block_uuid", "").is_empty()
	
	if is_custom_target and is_custom_data:
		AlertSystem.show_alert(tr("alert_error"), tr("program_editor.custom_blocks.inception_alert"), Alert.MessageType.ERROR)
		return
		
	var new_block: Block = BLOCK_SCENE.instantiate()
	new_block.is_toolbox_source = false
	add_child(new_block)
	
	new_block.initialize(data)
	
	var center_offset = (size - new_block.custom_minimum_size) / 2.0
	
	if "grab_offset" in data:
		new_block.position = at_position - data["grab_offset"]
	else:
		new_block.position = at_position - (new_block.custom_minimum_size / 2)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(new_block, "position", center_offset, 0.2)
	
	new_block.scale = Vector2(1.1, 1.1) 
	tween.parallel().tween_property(new_block, "scale", Vector2.ONE, 0.2)
	tween.finished.connect(func(): new_block.set_anchors_preset(Control.PRESET_CENTER))
	
	if not data.get("is_source", false):
		var old_node = data.get("node_ref")
		if is_instance_valid(old_node):
			old_node.queue_free()

func animate_highlight() -> void:
	if background.self_modulate == COLOR_HIGHLIGHT: return
	if highlight_tween and highlight_tween.is_running() and background.self_modulate.a > 0.8: return
	
	if highlight_tween: highlight_tween.kill()
	highlight_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	highlight_tween.tween_property(background, "self_modulate", COLOR_HIGHLIGHT, 0.1)

func reset_visuals() -> void:
	if highlight_tween: highlight_tween.kill()
	highlight_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	highlight_tween.tween_property(background, "self_modulate", COLOR_DEFAULT, 0.2)

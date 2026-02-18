class_name BlockVisuals extends RefCounted

const TEX_NONE = preload("res://assets/images/brain_editor/conn_none.png")
const TEX_IN = preload("res://assets/images/brain_editor/conn_in.png")
const TEX_OUT = preload("res://assets/images/brain_editor/conn_out.png")
const TEX_MISSING = preload("res://assets/images/brain_editor/block_icons/missing.png")

static func load_data(block: Block) -> void:
	if not block.block_data: return

	match block.block_data.display:
		BlockData.Display.ICON_TEXT:
			block.icon.texture = block.block_data.icon
			block.display_name_label.text = block.block_data.display_name
			block.icon.visible = true
			block.display_name_label.visible = true
			block.icon_big.visible = false
			block.value_drag.visible = false
		BlockData.Display.BIG_ICON:
			block.icon_big.texture = block.block_data.icon
			block.icon.visible = false
			block.display_name_label.visible = false
			block.value_drag.visible = false
			block.icon_big.visible = true
		BlockData.Display.ICON_VALUE_DRAG:
			block.icon.texture = block.block_data.icon
			block.icon.visible = true
			block.display_name_label.visible = false
			block.value_drag.visible = true
			block.icon_big.visible = false
	
	block.background_container.modulate = block.block_data.get_style_color()
	
	if block.value_drag:
		block.value_drag.mouse_filter = Control.MOUSE_FILTER_IGNORE if block.is_toolbox_source else Control.MOUSE_FILTER_STOP
		
		block.value_drag.setup(
			block.block_data.value_mode,
			block.block_data.custom_min,
			block.block_data.custom_max,
			block.block_data.value_strings 
		)

	update_labels_text(block)

static func update_visuals(block: Block) -> void:
	if not block.block_data: return
	
	for i in range(4):
		var port_def = block.block_data.ports[i]
		var sprite = block.port_sprites[i]
		
		match port_def:
			BlockData.Port.NONE:
				sprite.texture = TEX_NONE
			BlockData.Port.INPUT:
				sprite.texture = TEX_IN
			BlockData.Port.OUTPUT:
				sprite.texture = TEX_OUT

static func update_labels_text(block: Block) -> void:
	if not block.block_data: return

	for i in range(4):
		var label: Label = block.label_nodes[i]
		if label:
			var data_index = (i - block.rotation_index + 4) % 4
			label.text = block.block_data.port_labels[data_index]

static func create_missing_block_visuals(block: Block) -> void:
	block.block_data = CustomBlockData.new(
		TranslationServer.translate("brain_editor.new_program.missing.title"), 
		[BlockData.Port.NONE, BlockData.Port.NONE, BlockData.Port.NONE, BlockData.Port.NONE]
	)
	
	block.block_data.style = BlockData.Style.CUSTOM
	block.block_data.info_text = TranslationServer.translate("brain_editor.new_program.missing.nf").format({ "uuid": block.custom_block_uuid })
	
	block.background_container.modulate = Color(1.0, 0.2, 0.2, 1.0) 
	
	block.block_data.icon = TEX_MISSING

static func animate_labels(block: Block, target_alpha: float) -> void:
	if block.labels_tween: block.labels_tween.kill()
	
	block.labels_tween = block.create_tween()
	block.labels_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if target_alpha > 0.0:
		block.labels.visible = true
		
	block.labels_tween.tween_property(block.labels, "modulate:a", target_alpha, 0.2)
	
	if target_alpha == 0.0:
		block.labels_tween.tween_callback(block.labels.hide)

static func animate_rotation(block: Block) -> void:
	if block.rotation_tween: block.rotation_tween.kill()
	
	block.rotation_tween = block.create_tween()
	block.rotation_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	block.rotation_tween.tween_property(block.background_container, "rotation_degrees", block.target_rotation, 0.2)

static func animate_labels_change(block: Block) -> void:
	if not block.labels.visible or block.labels.modulate.a == 0.0:
		update_labels_text(block)
		return

	if block.labels_tween: block.labels_tween.kill()
	block.labels_tween = block.create_tween()
	block.labels_tween.tween_property(block.labels, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	block.labels_tween.tween_callback(func(): update_labels_text(block))
	block.labels_tween.tween_property(block.labels, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

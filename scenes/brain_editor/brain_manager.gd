class_name BrainManager extends Node

const SAVE_PATH: String = "user://brain.tres"
const BLOCK_SCENE = preload("res://scenes/brain_editor/block/block.tscn")

static func save_brain(brain_editor: BrainEditor) -> void:
	var brain: Brain = Brain.new()
	brain.size = brain_editor.size
	brain.edge_ports_active = brain_editor.edge_ports_active
	
	var grid_container: GridContainer = brain_editor.grid_container
	
	var children = grid_container.get_children()
	var cols = grid_container.columns
	
	for i in range(children.size()):
		var child = children[i]
		@warning_ignore("integer_division")
		var coords = Vector2i(i % cols, i / cols)
		
		if child is Slot and child.has_block():
			var block: Block = null
			for sub_child in child.get_children():
				if sub_child is Block and not sub_child.is_queued_for_deletion():
					block = sub_child
					break
			
			if block:
				var data: Dictionary = {
					"resource": block.block_data,
					"rotation_index": block.rotation_index
				}
				
				if block.value_drag and block.value_drag.visible:
					if "value" in block.value_drag:
						data["stored_value"] = block.value_drag.value
				
				brain.blocks[coords] = data
	
	var error = ResourceSaver.save(brain, SAVE_PATH)
	if error != OK:
		push_error("Nie udało się zapisać układu: ", error)
	else:
		print("Układ zapisany do: ", SAVE_PATH)

static func load_brain(brain_editor: BrainEditor) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		push_error("Plik nie istnieje: ", SAVE_PATH)
		brain_editor.initialize_grid()
		return
		
	var brain = load(SAVE_PATH) as Brain
	
	if not brain:
		push_error("Niepoprawny format pliku zapisu.")
		brain_editor.initialize_grid()
		return
	
	var grid_container: GridContainer = brain_editor.grid_container
	
	brain_editor.size = brain.size
	brain_editor.edge_ports_active = brain.edge_ports_active
	brain_editor.initialize_grid()
	
	var children = grid_container.get_children()
	var cols = grid_container.columns
	
	for coords in brain.blocks:
		var index = coords.y * cols + coords.x
		if index < children.size():
			var slot = children[index]
			if slot is Slot:
				var data = brain.blocks[coords]
				spawn_block_in_slot(slot, data)

static func spawn_block_in_slot(slot: Slot, data: Dictionary) -> void:
	var new_block: Block = BLOCK_SCENE.instantiate()
	new_block.is_toolbox_source = false
	slot.add_child(new_block)
	
	new_block.initialize(data)
	
	new_block.position = Vector2.ZERO
	new_block.set_anchors_preset(Control.PRESET_CENTER)

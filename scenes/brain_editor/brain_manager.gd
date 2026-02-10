class_name BrainManager extends Node

const SAVE_PATH: String = "user://brain.tres"
const BLOCK_SCENE = preload("res://scenes/brain_editor/block/block.tscn")

static func save_brain(brain_editor: BrainEditor) -> void:
	var brain_grid: BrainGrid = brain_editor.main_brain_grid
	
	var brain: Brain = Brain.new()
	brain.program_uid = brain_editor.program_uid
	brain.size = brain_grid.matrix_size
	brain.in_nested_view = brain_grid.in_nested_view
	
	var brain_grid_data: Dictionary = {
		"uuid": brain_grid.grid_uid,
		"grid": get_block_data(brain_grid)
	}
	
	brain.brain_grids.append(brain_grid_data)
	
	var error = ResourceSaver.save(brain, SAVE_PATH)
	if error != OK:
		push_error("Nie udało się zapisać układu: ", error)
	else:
		print("Układ zapisany do: ", SAVE_PATH)

static func get_block_data(brain_grid: BrainGrid) -> Dictionary[Vector2i, Dictionary]:
	var block_data: Dictionary[Vector2i, Dictionary] = {}
	var children = brain_grid.grid_container.get_children()
	var cols = brain_grid.grid_container.columns
	
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
				
				block_data[coords] = data
	
	return block_data

static func load_brain(brain_editor: BrainEditor) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("Plik nie istnieje: ", SAVE_PATH)
		brain_editor.main_brain_grid.initialize()
		return
		
	var brain = load(SAVE_PATH) as Brain
	
	if not brain:
		push_error("Niepoprawny format pliku zapisu.")
		brain_editor.main_brain_grid.initialize()
		return
	
	brain_editor.program_uid = brain.program_uid
	
	load_brain_grid(brain_editor.main_brain_grid, brain, 0)

static func load_brain_grid(brain_grid: BrainGrid, brain: Brain, brain_grid_index: int) -> void:
	brain_grid.matrix_size = brain.size
	brain_grid.in_nested_view = brain.in_nested_view
	brain_grid.initialize()
	
	var children = brain_grid.grid_container.get_children()
	var cols = brain_grid.grid_container.columns
	
	var brain_grid_data: Dictionary = brain.brain_grids[brain_grid_index]
	brain_grid.grid_uid = brain_grid_data["uuid"]
	
	for coords in brain_grid_data["grid"]:
		var index = coords.y * cols + coords.x
		if index < children.size():
			var slot = children[index]
			if slot is Slot:
				var data = brain_grid_data["grid"][coords]
				spawn_block_in_slot(slot, data)

static func spawn_block_in_slot(slot: Slot, data: Dictionary) -> void:
	var new_block: Block = BLOCK_SCENE.instantiate()
	new_block.is_toolbox_source = false
	slot.add_child(new_block)
	
	new_block.initialize(data)
	
	new_block.position = Vector2.ZERO
	new_block.set_anchors_preset(Control.PRESET_CENTER)

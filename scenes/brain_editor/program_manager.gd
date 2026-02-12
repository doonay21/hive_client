class_name ProgramManager extends Node

static func load_program(brain_editor: BrainEditor) -> void:
	var program: ProgramModel = ProgramModel.get_by_id(brain_editor.program_id)
	
	print(program.grid)
	
	brain_editor.program_grid.matrix_size = program.size
	brain_editor.program_grid.initialize()

static func save_program(brain_editor: BrainEditor) -> void:
	var program: ProgramModel = ProgramModel.get_by_id(brain_editor.program_id)
	
	if not program:
		program = ProgramModel.new({ "name": brain_editor.program_name })
		program.save()
	
	program.name = brain_editor.program_name
	
	var program_grid: ProgramGrid = brain_editor.tabs.get_child(0)
	var grid: Dictionary = get_block_data(program_grid)
	program.grid = grid
	program.save()

static func get_block_data(program_grid: ProgramGrid) -> Dictionary[Vector2i, Dictionary]:
	var block_data: Dictionary[Vector2i, Dictionary] = {}
	var children = program_grid.grid_container.get_children()
	var cols = program_grid.grid_container.columns
	
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

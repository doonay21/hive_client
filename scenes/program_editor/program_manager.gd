class_name ProgramManager extends Node

const BLOCK_SCENE = preload("res://scenes/program_editor/block/block.tscn")

static func load_program(program_editor: BrainEditor) -> void:
	var program: ProgramModel = ProgramModel.get_by_id(program_editor.program_id)
	
	program_editor.program_grid.matrix_size = program.size
	program_editor.program_grid.initialize()
	program_editor.program_id = program.id
	program_editor.program_name = program.name
	
	if program.grid.size() != 0:
		var program_grid: ProgramGrid = program_editor.tabs.get_child(0)
		program_grid.label.text = TranslationServer.translate("program_editor.main")
		
		load_grid_save_data(program_grid, program.grid)
	
	load_custom_blocks(program_editor)

static func load_custom_blocks(program_editor: BrainEditor) -> void:
	var custom_blocks: Array[BlockModel] = BlockModel.all()
	
	for custom_block in custom_blocks:
		program_editor.custom_blocks.add_block_to_sidebar(custom_block)

static func save_program(program_editor: BrainEditor) -> bool:
	var program: ProgramModel = ProgramModel.get_by_id(program_editor.program_id)
	var success: bool = true
	
	if not program:
		program = ProgramModel.new({ "name": program_editor.program_name })
		if not program.save(): return false
		program_editor.program_id = program.id
	
	for i in range(program_editor.tabs.get_child_count()):
		var tab = program_editor.tabs.get_child(i)
		
		if tab is ProgramGrid:
			if tab.is_block and not save_custom_block_tab(tab):
				success = false
			elif tab == program_editor.program_grid:
				program.name = program_editor.program_name
				program.grid = tab.get_grid()
				if not program.save(): success = false

	return success

static func save_custom_block_tab(grid: ProgramGrid) -> bool:
	var block_model = BlockModel.where("uuid", grid.custom_block_uuid)
	
	if block_model:
		block_model.grid = grid.get_grid()
		block_model.ports = grid.get_ports_state()
		return block_model.save()
	
	return false

static func load_grid_save_data(program_grid: ProgramGrid, grid_data: Array) -> void:
	var children = program_grid.grid_container.get_children()
	
	for i in range(children.size()):
		var slot = children[i]
		var data: Dictionary = grid_data[i]
		
		if data.is_empty(): continue
		
		if slot is Slot:
			var new_block: Block = BLOCK_SCENE.instantiate()
			new_block.is_toolbox_source = false
			slot.add_child(new_block)
			
			new_block.load_save_data(data)

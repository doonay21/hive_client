class_name ProgramManager extends Node

const BLOCK_SCENE = preload("res://scenes/brain_editor/block/block.tscn")

static func load_program(brain_editor: BrainEditor) -> void:
	var program: ProgramModel = ProgramModel.get_by_id(brain_editor.program_id)
	
	brain_editor.program_grid.matrix_size = program.size
	brain_editor.program_grid.initialize()
	brain_editor.program_id = program.id
	brain_editor.program_name = program.name
	
	if program.grid.size() != 0:
		var program_grid: ProgramGrid = brain_editor.tabs.get_child(0)
		program_grid.label.text = "\"%s\"" % TranslationServer.translate("BE_PROGRAM_GRID_DEFAULT_LABEL")
		
		load_grid_save_data(program_grid, program.grid)
	
	load_custom_blocks(brain_editor)

static func load_custom_blocks(brain_editor: BrainEditor) -> void:
	var custom_blocks: Array[BlockModel] = BlockModel.all()
	
	for custom_block in custom_blocks:
		brain_editor.custom_blocks.add_block_to_sidebar(custom_block)

static func save_program(brain_editor: BrainEditor) -> void:
	var program: ProgramModel = ProgramModel.get_by_id(brain_editor.program_id)
	
	if not program:
		program = ProgramModel.new({ "name": brain_editor.program_name })
		program.save()
		brain_editor.program_id = program.id
	
	for i in range(brain_editor.tabs.get_child_count()):
		var tab = brain_editor.tabs.get_child(i)
		if tab is ProgramGrid:
			if tab.is_block:
				save_custom_block_tab(tab)
			elif tab == brain_editor.program_grid:
				program.name = brain_editor.program_name
				program.grid = tab.get_grid()
				program.save()

static func save_custom_block_tab(grid: ProgramGrid) -> void:
	var block_model = BlockModel.where("uuid", grid.custom_block_uuid)
	
	if block_model:
		block_model.grid = grid.get_grid()
		block_model.ports = grid.get_ports_state()
		block_model.save()

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

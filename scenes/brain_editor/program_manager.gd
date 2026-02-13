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

static func save_program(brain_editor: BrainEditor) -> void:
	var program: ProgramModel = ProgramModel.get_by_id(brain_editor.program_id)
	
	if not program:
		program = ProgramModel.new({ "name": brain_editor.program_name })
		program.save()
	
	program.name = brain_editor.program_name
	
	var program_grid: ProgramGrid = brain_editor.tabs.get_child(0)
	
	program.grid = program_grid.get_grid()
	program.save()

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

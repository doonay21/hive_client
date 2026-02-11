class_name ProgramManager extends Node

static func load_program(brain_editor: BrainEditor) -> void:
	var program: ProgramModel = ProgramModel.get_by_id(brain_editor.program_id)
	var program_girds: Array = ProgramGridModel.get_all_by_program_id(program.id)
	
	var counter: int = 0
	
	for program_gird: ProgramGridModel in program_girds:
		if program_gird.is_block:
			brain_editor.create_new_tab(program_gird.name)
		else:
			brain_editor.tabs.set_tab_title(0, program_gird.name)
		
		load_blocks(brain_editor, counter, program_gird)

static func save_program(brain_editor: BrainEditor) -> void:
	var program: ProgramModel = update_program_name(brain_editor)
	var program_girds: Array = ProgramGridModel.get_all_by_program_id(program.id)
	
	for program_gird: ProgramGridModel in program_girds:
		update_program_grid(program_gird)

static func load_blocks(brain_editor: BrainEditor, grid_id: int,  program_gird: ProgramGridModel) -> void:
	brain_editor.program_grids[grid_id].matrix_size = program_gird.size
	brain_editor.program_grids[grid_id].in_nested_view = program_gird.is_block
	brain_editor.program_grids[grid_id].initialize()

static func update_program_name(brain_editor: BrainEditor) -> ProgramModel:
	var program: ProgramModel = ProgramModel.get_by_id(brain_editor.program_id)
	
	if program:
		program.name = brain_editor.program_name
		program.save()
	else:
		ProgramModel.create_with_default_grid(brain_editor.program_name)
	
	return program

static func update_program_grid(program_gird: ProgramGridModel) -> void:
	pass

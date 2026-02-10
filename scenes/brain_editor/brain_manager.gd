class_name BrainManager extends Node

const SAVE_PATH: String = "user://brain.tres"
const BLOCK_SCENE = preload("res://scenes/brain_editor/block/block.tscn")

static func save_program(brain_editor: BrainEditor) -> void:
	var program: SaveProgram = SaveProgram.new()
	program.uuid = brain_editor.program_uuid
	
	var main_folder: String = "user://programs/%s/" % brain_editor.program_uuid
	var program_path: String = main_folder.path_join("program.tres")
	
	ensure_dirs(main_folder)
	
	for i in range(brain_editor.tabs.get_child_count()):
		var tab_title: String = brain_editor.tabs.get_tab_title(i)
		var program_grid: ProgramGrid = brain_editor.tabs.get_child(i)
		
		save_brain(main_folder, program, tab_title, program_grid)
	
	ResourceSaver.save(program, program_path)

static func save_brain(main_folder: String, program: SaveProgram, tab_title: String, program_grid: ProgramGrid) -> void:
	program.brains.append(program_grid.grid_uid)
	
	var brain: SaveBrain = SaveBrain.new()
	brain.name = tab_title
	brain.uuid = program_grid.grid_uid
	brain.size = program_grid.matrix_size
	brain.grid = get_block_data(program_grid)
	brain.in_nested_view = program_grid.in_nested_view
	
	var brain_path: String = main_folder.path_join("%s.tres" % program_grid.grid_uid)
	
	ResourceSaver.save(brain, brain_path)

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

static func load_program(brain_editor: BrainEditor) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("Plik nie istnieje: ", SAVE_PATH)
		brain_editor.main_program_grid.initialize()
		return
		
	var program = load(SAVE_PATH) as SaveProgram
	
	if not program:
		push_error("Niepoprawny format pliku zapisu.")
		brain_editor.main_program_grid.initialize()
		return
	
	brain_editor.program_uuid = program.uuid
	
	load_brain_grid(brain_editor.main_program_grid, program, 0)

static func load_brain_grid(program_grid: ProgramGrid, program: SaveProgram, program_grid_index: int) -> void:
	var brain_grid_data: Dictionary = program.brains[program_grid_index]
	program_grid.grid_uid = brain_grid_data["uuid"]
	program_grid.matrix_size = brain_grid_data["size"]
	program_grid.in_nested_view = brain_grid_data["in_nested_view"]
	
	program_grid.initialize()
	
	var children = program_grid.grid_container.get_children()
	var cols = program_grid.grid_container.columns
	
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

static func ensure_dirs(path: String) -> void:
	var directory = path.get_base_dir()
	
	if not DirAccess.dir_exists_absolute(directory):
		var error = DirAccess.make_dir_recursive_absolute(directory)
		if error != OK:
			print("Błąd podczas tworzenia folderu: ", error)
			return

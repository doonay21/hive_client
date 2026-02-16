class_name BrainEditor extends Control

const BRAIN_GRID_SCENE: PackedScene = preload("res://scenes/brain_editor/program_grid/program_grid.tscn")

@onready var program_grid: ProgramGrid = %ProgramGrid
@onready var clear_program_grid_dialog: ConfirmationDialog = $ClearProgramGridDialog
@onready var tabs: TabContainer = %BrainEditorTabs
@onready var program_name_label: Label = %ProgramNameLabel
@onready var custom_blocks: CustomBlocks = %CustomBlocks
@onready var close_tab_confirm_dialog: ConfirmationDialog = $CloseTabConfirmDialog

var program_id: int = -1
var program_name: String = tr("brain_editor.new_program.def_name")
var tab_to_close_index: int = -1

func _ready() -> void:
	if program_id != -1:
		ProgramManager.load_program(self)
	
	program_name_label.text = tr("brain_editor.program_label").format({ "program_name": program_name })
	
	var tab_bar = tabs.get_tab_bar()
	tab_bar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
	tab_bar.tab_close_pressed.connect(on_tab_close_pressed)
	
	close_tab_confirm_dialog.confirmed.connect(on_close_tab_confirmed)

func on_button_save_pressed() -> void:
	if ProgramManager.save_program(self):
		AlertSystem.show_alert(tr("alert_sucess"), tr("brain_editor.saved"), Alert.MessageType.SUCCESS)
	else:
		AlertSystem.show_alert(tr("alert_error"), tr("brain_editor.save_error"), Alert.MessageType.ERROR)

func on_button_clear_pressed() -> void:
	clear_program_grid_dialog.reset_size()
	clear_program_grid_dialog.popup_centered()

func on_custom_block_updated(uuid: String, new_name: String, new_desc: String) -> void:
	for i in range(tabs.get_child_count()):
		var child = tabs.get_child(i)
		if child is ProgramGrid and child.custom_block_uuid == uuid:
			tabs.set_tab_title(i, new_name)
			child.set_description(new_desc)

func on_clear_brain_grid_dialog_confirmed() -> void:
	var active_tab = tabs.get_current_tab_control()

	if active_tab is ProgramGrid:
		active_tab.clear()

func create_new_tab(block_model: BlockModel) -> void:
	for i in range(tabs.get_child_count()):
		var child = tabs.get_child(i)
		if child is ProgramGrid and child.custom_block_uuid == block_model.uuid:
			tabs.current_tab = i
			return

	var grid: ProgramGrid = BRAIN_GRID_SCENE.instantiate()
	grid.matrix_size = ProgramGrid.MatrixSize._5x5
	grid.is_block = true
	grid.custom_block_uuid = block_model.uuid
	tabs.add_child(grid)
	
	grid.initialize()
	
	grid.set_description(block_model.description)
	
	grid.edge_port_top.change_type(block_model.ports[0])
	grid.edge_port_right.change_type(block_model.ports[1])
	grid.edge_port_bottom.change_type(block_model.ports[2])
	grid.edge_port_left.change_type(block_model.ports[3])
	
	if not block_model.grid.is_empty():
		ProgramManager.load_grid_save_data(grid, block_model.grid)
	
	var index = tabs.get_child_count() - 1
	tabs.set_tab_title(index, block_model.name)
	tabs.current_tab = index

func close_tab_by_uuid(uuid: String) -> void:
	for i in range(tabs.get_child_count()):
		var child = tabs.get_child(i)
		if child is ProgramGrid and child.custom_block_uuid == uuid:
			child.queue_free()
			return

func on_tab_close_pressed(tab_idx: int) -> void:
	if tab_idx == 0:
		AlertSystem.show_alert(tr("alert_warning"), tr("brain_editor.close.warning"), Alert.MessageType.WARNING)
		return

	tab_to_close_index = tab_idx
	close_tab_confirm_dialog.popup_centered()

func on_close_tab_confirmed() -> void:
	if tab_to_close_index == -1: return
	
	var tab_to_close = tabs.get_child(tab_to_close_index)
	
	if tabs.current_tab == tab_to_close_index:
		tabs.current_tab = tab_to_close_index - 1
		
	tab_to_close.queue_free()
	tab_to_close_index = -1

func get_program_data() -> Dictionary:
	var program_data: Dictionary = {
		"grid": {},
		"size": 2,
		"custom_blocks": {}
	}
	
	var program_grid_data: Array = program_grid.get_program_data()
	program_data["grid"] = program_grid_data
	program_data["size"] = program_grid.matrix_size
	
	var custom_blocks_used: Dictionary = {}
	for data: Dictionary in program_grid_data:
		if data.is_empty(): continue
		if data.get("op") == BlockData.Op.CUSTOM:
			custom_blocks_used[data["uuid"]] = true
	
	for uuid: String in custom_blocks_used.keys():
		var custom_block_data: Dictionary = try_get_data_from_tab(uuid)
		
		if custom_block_data.is_empty():
			custom_block_data = get_data_from_db(uuid)
		
		if not custom_block_data.is_empty():
			program_data["custom_blocks"][uuid] = custom_block_data
	
	return program_data

func try_get_data_from_tab(uuid: String) -> Dictionary:
	for i in range(tabs.get_child_count()):
		var child = tabs.get_child(i)
		
		if child is ProgramGrid and child.custom_block_uuid == uuid:
			return {
				"grid": child.get_program_data(),
				"size": child.matrix_size,
				"ports": child.get_ports_state()
			}

	return {}

func get_data_from_db(uuid: String) -> Dictionary:
	var block_model = BlockModel.where("uuid", uuid)
	
	if not block_model:
		return {}

	var converted_grid_data: Array = []
	
	for saved_slot_data: Dictionary in block_model.grid:
		if saved_slot_data.is_empty():
			converted_grid_data.append({})
			continue
			
		var program_logic = Block.parse_save_to_program_data(saved_slot_data)
		converted_grid_data.append(program_logic)
	
	return {
		"grid": converted_grid_data,
		"size": block_model.size,
		"ports": block_model.ports
	}

func is_block_used_in_open_tabs(uuid: String) -> bool:
	for i in range(tabs.get_child_count()):
		var tab = tabs.get_child(i)
		
		if tab is ProgramGrid:
			if tab.has_custom_block_usage(uuid):
				return true
				
	return false

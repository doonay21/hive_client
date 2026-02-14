class_name BrainEditor extends Control

const BRAIN_GRID_SCENE: PackedScene = preload("res://scenes/brain_editor/program_grid/program_grid.tscn")

@onready var program_grid: ProgramGrid = %ProgramGrid
@onready var clear_program_grid_dialog: ConfirmationDialog = $ClearProgramGridDialog
@onready var tabs: TabContainer = %BrainEditorTabs
@onready var program_name_label: Label = %ProgramNameLabel
@onready var custom_blocks: CustomBlocks = %CustomBlocks

var program_id: int = -1
var program_name: String = tr("BE_DEFAULT_PROGRAM_NAME")

func _ready() -> void:
	if program_id != -1:
		ProgramManager.load_program(self)
	
	program_name_label.text = tr("BE_PROGRAM_LABEL").format({ "program_name": program_name })

func on_button_save_pressed() -> void:
	ProgramManager.save_program(self)
	AlertSystem.show_alert(tr("ALERT_SUCCESS"), tr("BE_SAVED_ALERT"), Alert.MessageType.SUCCESS)

func on_button_clear_pressed() -> void:
	clear_program_grid_dialog.reset_size()
	clear_program_grid_dialog.popup_centered()

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
	
	grid.edge_port_top.change_type(block_model.ports[0])
	grid.edge_port_right.change_type(block_model.ports[1])
	grid.edge_port_bottom.change_type(block_model.ports[2])
	grid.edge_port_left.change_type(block_model.ports[3])
	
	if not block_model.grid.is_empty():
		ProgramManager.load_grid_save_data(grid, block_model.grid)
	
	var index = tabs.get_child_count() - 1
	tabs.set_tab_title(index, block_model.name)
	tabs.current_tab = index

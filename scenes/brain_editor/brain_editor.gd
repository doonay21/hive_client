class_name BrainEditor extends CanvasLayer

const BRAIN_GRID_SCENE: PackedScene = preload("res://scenes/brain_editor/program_grid/program_grid.tscn")

@onready var main_program_grid: ProgramGrid = %ProgramGrid
@onready var new_block_dialog: ConfirmationDialog = $NewBlockDialog
@onready var clear_program_grid_dialog: ConfirmationDialog = $ClearProgramGridDialog
@onready var tabs: TabContainer = %BrainEditorTabs
@onready var program_uuid_label: Label = %ProgramUUIDLabel

var program_id: int = -1
var program_name: String = tr("BE_DEFAULT_PRORGAM_NAME")
var program_grids: Array[ProgramGrid] = []

var program_uuid: String = "":
	set(value):
		program_uuid = value
		program_uuid_label.text = tr("BE_PROGRAM_UUID").format({ "program_uuid": program_uuid })

func _ready() -> void:
	program_uuid = UUID.v4()
	
	program_grids.append(main_program_grid)
	
	ProgramManager.load_program(self)
	#BrainManager.load_program(self)

func on_button_save_pressed() -> void:
	pass
	#BrainManager.save_program(self)

func on_button_clear_pressed() -> void:
	clear_program_grid_dialog.reset_size()
	clear_program_grid_dialog.popup_centered()

func on_clear_brain_grid_dialog_confirmed() -> void:
	var active_tab: CenterContainer = tabs.get_current_tab_control()

	if active_tab:
		var program_grid: ProgramGrid = active_tab.get_child(0)
		
		if program_grid:
			program_grid.clear()

func on_custom_blocks_add_new_block() -> void:
	new_block_dialog.popup_centered()

func on_new_block_dialog_create_new_block(block_name: String) -> void:
	create_new_tab(block_name)

func create_new_tab(tab_name: String) -> void:
	var program_grid: ProgramGrid = BRAIN_GRID_SCENE.instantiate()
	program_grid.matrix_size = ProgramGrid.MatrixSize._5x5
	program_grid.in_nested_view = true
	tabs.add_child(program_grid)
	program_grids.append(program_grid)
	
	program_grid.initialize()
	
	var index = tabs.get_child_count() - 1
	tabs.set_tab_title(index, tab_name)
	tabs.current_tab = index

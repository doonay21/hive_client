class_name BrainEditor extends CanvasLayer

const BRAIN_GRID_SCENE: PackedScene = preload("res://scenes/brain_editor/brain_grid/brain_grid.tscn")

@onready var main_brain_grid: BrainGrid = %BrainGrid
@onready var new_block_dialog: ConfirmationDialog = $NewBlockDialog
@onready var clear_brain_grid_dialog: ConfirmationDialog = $ClearBrainGridDialog
@onready var tabs: TabContainer = %BrainEditorTabs
@onready var program_uid_label: Label = %ProgramUIDLabel

var program_uid: String = UUID.v4()

func _ready() -> void:
	program_uid_label.text = tr("BE_PROGRAM_UID").format({ "program_uid": program_uid })
	BrainManager.load_brain(self)

func on_button_save_pressed() -> void:
	BrainManager.save_brain(self)

func on_button_clear_pressed() -> void:
	clear_brain_grid_dialog.reset_size()
	clear_brain_grid_dialog.popup_centered()

func on_clear_brain_grid_dialog_confirmed() -> void:
	var active_tab: CenterContainer = tabs.get_current_tab_control()

	if active_tab:
		var brain_grid: BrainGrid = active_tab.get_child(0)
		
		if brain_grid:
			brain_grid.clear()

func on_custom_blocks_add_new_block() -> void:
	new_block_dialog.popup_centered()

func on_new_block_dialog_create_new_block(block_name: String) -> void:
	create_new_tab(block_name)

func create_new_tab(tab_name: String) -> void:
	var brain_grid: BrainGrid = BRAIN_GRID_SCENE.instantiate()
	brain_grid.matrix_size = BrainGrid.MatrixSize._5x5
	brain_grid.in_nested_view = true
	tabs.add_child(brain_grid)
	
	brain_grid.initialize()
	
	var index = tabs.get_child_count() - 1
	tabs.set_tab_title(index, tab_name)
	tabs.current_tab = index

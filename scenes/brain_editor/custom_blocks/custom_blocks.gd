class_name CustomBlocks extends VBoxContainer

const BLOCK_SCENE = preload("res://scenes/brain_editor/block/block.tscn")

@export var brain_editor: BrainEditor

@onready var new_block_dialog: ConfirmationDialog = $NewBlockDialog
@onready var grid: GridContainer = $Grid

func on_new_block_button_pressed() -> void:
	new_block_dialog.popup_centered()

func on_new_block_dialog_create_new_block(block_name: String) -> void:
	var block_model: BlockModel = save_block_to_db(block_name)
	add_block_to_sidebar(block_model)
	
	brain_editor.create_new_tab(block_model)

func save_block_to_db(block_name: String) -> BlockModel:
	var new_block_model = BlockModel.new({
		"name": block_name,
		"size": ProgramGrid.MatrixSize._5x5,
		"grid": {}
	})
	
	return new_block_model if new_block_model.save() else null

func add_block_to_sidebar(block_model: BlockModel) -> void:
	var new_block_ui: Block = BLOCK_SCENE.instantiate()
	new_block_ui.is_toolbox_source = true
	new_block_ui.custom_block_uuid = block_model.uuid
	
	var initial_ports: Array[BlockData.Port] = [
		BlockData.Port.NONE, 
		BlockData.Port.NONE, 
		BlockData.Port.NONE, 
		BlockData.Port.NONE
	]
	
	var custom_data = CustomBlockData.new(
		block_model.id,
		block_model.name,
		initial_ports
	)
	
	new_block_ui.block_data = custom_data
	
	grid.add_child(new_block_ui)
	
	new_block_ui.update_visuals()
	new_block_ui.load_data()

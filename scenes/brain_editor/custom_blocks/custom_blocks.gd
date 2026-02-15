class_name CustomBlocks extends VBoxContainer

const BLOCK_SCENE = preload("res://scenes/brain_editor/block/block.tscn")

@export var brain_editor: BrainEditor

@onready var new_block_window: NewBlockWindow = $NewBlockWindow
@onready var grid: GridContainer = $Grid
@onready var context_menu: PopupMenu = $PopupMenu
@onready var delete_confirm_dialog: ConfirmationDialog = $DeleteConfirmDialog

var context_block_uuid: String = ""

func _ready() -> void:
	context_menu.id_pressed.connect(on_context_menu_item_pressed)
	new_block_window.edit_existing_block.connect(on_block_details_edited)
	delete_confirm_dialog.confirmed.connect(on_delete_confirmed)
	
func on_new_block_button_pressed() -> void:
	new_block_window.open_form()

func on_new_block_window_create_new_block(block_name: String, block_description: String) -> void:
	var block_model: BlockModel = save_block_to_db(block_name, block_description)
	
	if block_model:
		add_block_to_sidebar(block_model)
		brain_editor.create_new_tab(block_model)
		AlertSystem.show_alert(tr("alert_sucess"), tr("brain_editor.custom_blocks.created"), Alert.MessageType.SUCCESS)
	else:
		AlertSystem.show_alert(tr("alert_error"), tr("brain_editor.custom_blocks.create_error"), Alert.MessageType.ERROR)

func save_block_to_db(block_name: String, block_description: String) -> BlockModel:
	var new_block_model = BlockModel.new({
		"name": block_name,
		"description": block_description,
		"size": ProgramGrid.MatrixSize._5x5,
		"grid": [],
		"ports": [0, 0, 0, 0]
	})
	
	return new_block_model if new_block_model.save() else null

func add_block_to_sidebar(block_model: BlockModel) -> void:
	var new_block_ui: Block = BLOCK_SCENE.instantiate()
	new_block_ui.is_toolbox_source = true
	new_block_ui.custom_block_uuid = block_model.uuid

	var custom_data = CustomBlockData.new(
		block_model.name,
		block_model.ports,
		block_model.description
	)
	
	new_block_ui.block_data = custom_data
	new_block_ui.edit_requested.connect(on_block_edit_requested)
	new_block_ui.context_menu_requested.connect(on_block_context_menu_requested)
	
	grid.add_child(new_block_ui)
	
	new_block_ui.update_visuals()
	new_block_ui.load_data()

func on_block_edit_requested(uuid: String) -> void:
	var block_model = BlockModel.where("uuid", uuid)
	
	if block_model:
		brain_editor.create_new_tab(block_model)

func on_block_context_menu_requested(uuid: String, pos: Vector2) -> void:
	context_block_uuid = uuid
	
	context_menu.position = Vector2i(pos)
	context_menu.reset_size()
	context_menu.popup()

func on_context_menu_item_pressed(id: int) -> void:
	if context_block_uuid.is_empty(): return
	
	match id:
		0: # Edit logic
			on_block_edit_requested(context_block_uuid)
		1:# Edit Details
			var block_model = BlockModel.where("uuid", context_block_uuid)
			if block_model:
				new_block_window.open_form(block_model.name, block_model.description, context_block_uuid)
		2: # Delete
			attempt_delete_block()

func attempt_delete_block() -> void:
	var block_model = BlockModel.where("uuid", context_block_uuid)
	if not block_model: return

	var usages = BlockDependencyScanner.find_usages(context_block_uuid)
	
	if not usages.is_empty():
		var message = tr("brain_editor.custom_blocks.used.error").format({ "name": block_model.name }) + "\n\n"
		
		var limit = 5
		for i in range(min(limit, usages.size())):
			message += "- " + usages[i] + "\n"
			
		if usages.size() > limit:
			var remaining = usages.size() - limit
			message += tr("brain_editor.custom_blocks.used.and_more").format({ "count": remaining })
			
		AlertSystem.show_alert(tr("alert_error"), message, Alert.MessageType.ERROR)
		return

	delete_confirm_dialog.reset_size()
	delete_confirm_dialog.popup_centered()

func on_block_details_edited(uuid: String, new_name: String, new_desc: String) -> void:
	var block_model = BlockModel.where("uuid", uuid)
	if not block_model: return
	
	block_model.name = new_name
	block_model.description = new_desc
	
	if block_model.save():
		update_sidebar_block_visuals(uuid, new_name, new_desc)
		brain_editor.on_custom_block_updated(uuid, new_name, new_desc)
		AlertSystem.show_alert(tr("alert_sucess"), tr("brain_editor.updated"), Alert.MessageType.SUCCESS)

func update_sidebar_block_visuals(uuid: String, new_name: String, new_desc: String) -> void:
	for child in grid.get_children():
		if child is Block and child.custom_block_uuid == uuid:
			child.block_data.display_name = new_name
			child.block_data.info_text = new_desc
			child.load_data()
			return

func on_delete_confirmed() -> void:
	if context_block_uuid.is_empty(): return
	
	var block_model = BlockModel.where("uuid", context_block_uuid)
	if not block_model: return

	BlockModel.delete_by_id(block_model.id)
	
	for child in grid.get_children():
		if child is Block and child.custom_block_uuid == context_block_uuid:
			child.queue_free()
			break
			
	brain_editor.close_tab_by_uuid(context_block_uuid)
	
	AlertSystem.show_alert(tr("alert_sucess"), tr("brain_editor.custom_blocks.delete.alert"), Alert.MessageType.SUCCESS)
	context_block_uuid = ""

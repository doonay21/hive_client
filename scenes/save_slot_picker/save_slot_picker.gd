class_name SaveSlotPicker extends CanvasLayer

const brain_editor_scene: PackedScene = preload("res://scenes/brain_editor/brain_editor.tscn")

@onready var program_list: ItemList = %ProgramList
@onready var new_program_dialog: ConfirmationDialog = $NewProgramDialog

var programs: Dictionary = {}

func _ready() -> void:
	load_programs()

func load_programs() -> void:
	program_list.clear()
	
	var programs_db: Array[ProgramModel] = ProgramModel.all()
	var counter: int = 0
	
	for program in programs_db:
		program_list.add_item(program.name)
		programs[counter] = program.id
		
		counter += 1

func on_button_new_pressed() -> void:
	new_program_dialog.reset_size()
	new_program_dialog.popup_centered()

func on_button_load_pressed() -> void:
	var selected_indices = program_list.get_selected_items()
	
	if selected_indices.size() > 0:
		var index: int = selected_indices[0]
		var program_name: String = program_list.get_item_text(index)
		
		open_program(programs[index], program_name)

func on_new_program_dialog_create_new_program(program_name: String) -> void:
	var program: ProgramModel = ProgramModel.new({ "name": program_name })
	program.save()

	load_programs()
	
	var index: int = program_list.item_count - 1
	open_program(programs[index], program_name)

func open_program(program_id: int, program_name: String) -> void:
	var brain_editor = brain_editor_scene.instantiate()
	brain_editor.program_id = program_id
	brain_editor.program_name = program_name
	
	get_tree().root.add_child(brain_editor)
	get_tree().current_scene = brain_editor
	queue_free()

func on_program_list_item_activated(index: int) -> void:
	var program_name: String = program_list.get_item_text(index)
	
	open_program(programs[index], program_name)

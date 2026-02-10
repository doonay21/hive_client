class_name SaveSlotPicker extends CanvasLayer

@onready var program_list: ItemList = %ProgramList
@onready var new_program_dialog: ConfirmationDialog = $NewProgramDialog

func _ready() -> void:
	load_programs()

func load_programs() -> void:
	program_list.clear()
	
	var programs: Array[ProgramModel] = ProgramModel.all()
	
	for program in programs:
		program_list.add_item(program.name)

func on_button_new_pressed() -> void:
	new_program_dialog.reset_size()
	new_program_dialog.popup_centered()

func on_button_load_pressed() -> void:
	var selected_indices = program_list.get_selected_items()
	
	if selected_indices.size() > 0:
		var index = selected_indices[0]
		var text = program_list.get_item_text(index)

		var program: ProgramModel = ProgramModel.where("name", text)
		print(program)

func on_new_program_dialog_create_new_program(program_name: String) -> void:
	var program: ProgramModel = ProgramModel.new({ "name": program_name })
	program.save()

	print(program.id)

	load_programs()

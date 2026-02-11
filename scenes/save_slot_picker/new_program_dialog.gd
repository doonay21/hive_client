extends ConfirmationDialog

signal create_new_program(program_name: String)

@onready var program_name: LineEdit = $ProgramName
@onready var ok_button = get_ok_button()

var regex = RegEx.new()

func _ready():
	regex.compile("^[a-zA-Z0-9][a-zA-Z0-9 ]{1,63}$")
	program_name.max_length = 32
	ok_button.disabled = true

func submit() -> void:
	create_new_program.emit(program_name.text)
	program_name.text = ""

func on_canceled() -> void:
	program_name.text = ""

func on_confirmed() -> void:
	submit()

func on_block_name_text_changed(new_text: String) -> void:
	var is_valid = regex.search(new_text) != null
	ok_button.disabled = not is_valid

func on_about_to_popup() -> void:
	program_name.text = ""

func on_visibility_changed() -> void:
	if visible: program_name.grab_focus()

func on_block_name_text_submitted(new_text: String) -> void:
	if regex.search(new_text) == null: return
	
	submit()
	hide()

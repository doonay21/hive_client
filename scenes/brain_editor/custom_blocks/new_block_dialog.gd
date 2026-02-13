extends ConfirmationDialog

signal create_new_block(block_name: String)

@onready var block_name: LineEdit = $BlockName
@onready var ok_button = get_ok_button()

var regex = RegEx.new()

func _ready():
	regex.compile("^[a-zA-Z][a-zA-Z0-9_]{2,7}$")
	block_name.max_length = 8
	ok_button.disabled = true

func submit() -> void:
	create_new_block.emit(block_name.text)
	block_name.text = ""

func on_canceled() -> void:
	block_name.text = ""

func on_confirmed() -> void:
	submit()

func on_block_name_text_changed(new_text: String) -> void:
	var is_valid = regex.search(new_text) != null
	ok_button.disabled = not is_valid

func on_about_to_popup() -> void:
	block_name.text = ""
	ok_button.disabled = true

func on_visibility_changed() -> void:
	if visible: block_name.grab_focus()

func on_block_name_text_submitted(_new_text: String) -> void:
	submit()
	hide()

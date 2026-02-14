class_name NewBlockWindow extends Window

signal create_new_block(block_name: String, block_description: String)

@onready var name_input: LineEdit = $Panel/MarginContainer/VBoxContainer/NameInput
@onready var description_input: TextEdit = $Panel/MarginContainer/VBoxContainer/DescriptionInput
@onready var save_button: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ButtonSave
@onready var cancel_button: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ButtonCancel

var name_regex = RegEx.new()
var description_regex = RegEx.new()

func _ready() -> void:
	name_regex.compile("^[a-zA-Z][a-zA-Z0-9_]{0,7}$")
	name_input.max_length = 8
	
	description_regex.compile("^[^\\p{C}]*$")
	
	close_requested.connect(on_close_requested)
	save_button.pressed.connect(on_save_button_pressed)
	cancel_button.pressed.connect(on_close_requested)

func open_form(name_p: String = "", description_p: String = "") -> void:
	name_input.text = name_p
	description_input.text = description_p
	
	popup_centered()

func on_save_button_pressed() -> void:
	var name_text: String = name_input.text.strip_edges()
	var description_text: String = description_input.text.strip_edges()
	
	if name_text.is_empty():
		AlertSystem.show_alert(tr("ALERT_ERROR"), tr("BE_NEW_PROGRAM_NAME_REQUIRED"), Alert.MessageType.ERROR)
		return
	
	if description_text.is_empty():
		AlertSystem.show_alert(tr("ALERT_ERROR"), tr("BE_NEW_PROGRAM_DESCRIPTION_REQUIRED"), Alert.MessageType.ERROR)
		return
	
	if name_regex.search(name_text) == null:
		AlertSystem.show_alert(tr("ALERT_ERROR"), tr("BE_NEW_PROGRAM_NAME_REGEX"), Alert.MessageType.ERROR)
		return
	
	if description_text.length() > 150:
		AlertSystem.show_alert(tr("ALERT_ERROR"), tr("BE_NEW_PROGRAM_DESC_TOO_LONG"), Alert.MessageType.ERROR)
		return
	
	if description_regex.search(description_text) == null:
		AlertSystem.show_alert(tr("ALERT_ERROR"), tr("BE_NEW_PROGRAM_DESC_INVALID_CHARS"), Alert.MessageType.ERROR)
		return
	
	if not name_unique(name_text):
		AlertSystem.show_alert(tr("ALERT_ERROR"), tr("BE_NEW_PROGRAM_NAME_NOT_UNIQUE"), Alert.MessageType.ERROR)
		return
	
	create_new_block.emit(name_text, description_text)
	hide()

func on_close_requested() -> void:
	hide()

func name_unique(name_to_check: String) -> bool:
	if BlockModel.exists("name", name_to_check):
		return false
	
	return true

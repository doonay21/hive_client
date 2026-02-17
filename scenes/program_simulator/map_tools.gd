class_name MapTools extends PanelContainer

const icon_show = preload("res://assets/images/icons/show.png")
const icon_hide = preload("res://assets/images/icons/hide.png")

@export var map: Map

@onready var main_container: MarginContainer = $MainContainer
@onready var toggle_button: Button = $ToggleButton
@onready var pen_size_label: Label = $MainContainer/VBoxContainer/HBoxContainer/PenSizeLabel
@onready var pen_type: OptionButton = $MainContainer/VBoxContainer/HBoxContainer2/PenType

var active: bool = false

func _ready() -> void:
	toggle_button.tooltip_text = tr("program_simulator.map_tools.tooltip.show")
	main_container.hide()

func on_toggle_button_pressed() -> void:
	if main_container.visible:
		main_container.hide()
		toggle_button.icon = icon_show
		toggle_button.tooltip_text = tr("program_simulator.map_tools.tooltip.show")
	else:
		main_container.show()
		toggle_button.icon = icon_hide
		toggle_button.tooltip_text = tr("program_simulator.map_tools.tooltip.hide")

func on_pen_active_toggled(toggled_on: bool) -> void:
	active = toggled_on

func on_pen_type_item_selected(index: int) -> void:
	pass

func on_pen_size_slider_value_changed(value: float) -> void:
	pen_size_label.text = str(int(value))

func on_clear_button_pressed() -> void:
	if not is_instance_valid(map): return
	
	map.clear_map()

func on_random_button_pressed() -> void:
	if not is_instance_valid(map): return
	
	map.generate_world()

func on_fill_button_pressed() -> void:
	map.clear_map(pen_type.selected as Map.MaterialType)

class_name ProgramVisualizerTools extends PanelContainer

const icon_show = preload("res://assets/images/icons/show.png")
const icon_hide = preload("res://assets/images/icons/hide.png")

@export var program_visualizer: ProgramVisualizer

@onready var main_container: MarginContainer = $MainContainer
@onready var toggle_button: Button = $ToggleButton
@onready var node_margin_label: Label = $MainContainer/VBoxContainer/HBoxContainer/NodeMarginLabel
@onready var node_size_label: Label = $MainContainer/VBoxContainer/HBoxContainer2/NodeSizeLabel

func _ready() -> void:
	toggle_button.tooltip_text = tr("program_simulator.program_visualizer_tools.tooltip.show")
	main_container.hide()
	
func on_toggle_button_pressed() -> void:
	if main_container.visible:
		main_container.hide()
		toggle_button.icon = icon_show
		toggle_button.tooltip_text = tr("program_simulator.program_visualizer_tools.tooltip.show")
	else:
		main_container.show()
		toggle_button.icon = icon_hide
		toggle_button.tooltip_text = tr("program_simulator.program_visualizer_tools.tooltip.hide")

func on_node_margin_slider_value_changed(value: float) -> void:
	node_margin_label.text = str(int(value))
	program_visualizer.node_margin = value

func on_node_size_slider_value_changed(value: float) -> void:
	node_size_label.text = str(int(value))
	program_visualizer.node_size = value

func on_hide_empty_nodes_toggled(toggled_on: bool) -> void:
	program_visualizer.toggle_empty_nodes(toggled_on)

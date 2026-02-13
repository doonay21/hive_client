class_name ProgramGrid extends VBoxContainer

enum MatrixSize {
	_3x3,
	_5x5,
	_7x7,
	_9x9
}

const slot_scene: PackedScene = preload("res://scenes/brain_editor/slot/slot.tscn")
const edge_port_scene: PackedScene = preload("res://scenes/brain_editor/edge_port/edge_port.tscn")

@export var matrix_size: MatrixSize = MatrixSize._5x5
@export var is_block: bool = false

@onready var label: Label = $MarginContainer/Label
@onready var grid_container: GridContainer = %GridContainer
@onready var edge_port_top_container: Control = %EdgePortTopContainer
@onready var edge_port_top: Control = %EdgePortTop
@onready var edge_port_right_container: Control = %EdgePortRightContainer
@onready var edge_port_right: Control = %EdgePortRight
@onready var edge_port_bottom_container: Control = %EdgePortBottomContainer
@onready var edge_port_bottom: Control = %EdgePortBottom
@onready var edge_port_left_container: Control = %EdgePortLeftContainer
@onready var edge_port_left: Control = %EdgePortLeft

var custom_block_uuid: String = ""
var context_menu: PopupMenu
var current_selected_node: Control

func initialize() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	var internal_dim: int = 5
	
	match matrix_size:
		MatrixSize._3x3: internal_dim = 3
		MatrixSize._5x5: internal_dim = 5
		MatrixSize._7x7: internal_dim = 7
		MatrixSize._9x9: internal_dim = 9

	grid_container.columns = internal_dim

	for y in range(internal_dim):
		for x in range(internal_dim):
			var node: Control
			node = slot_scene.instantiate()
			node.name = "Node_%d_%d" % [x, y]
			grid_container.add_child(node)

	if is_block:
		edge_port_top.gui_input.connect(on_node_gui_input.bind(edge_port_top))
		edge_port_top_container.show()
		edge_port_right.gui_input.connect(on_node_gui_input.bind(edge_port_right))
		edge_port_right_container.show()
		edge_port_bottom.gui_input.connect(on_node_gui_input.bind(edge_port_bottom))
		edge_port_bottom_container.show()
		edge_port_left.gui_input.connect(on_node_gui_input.bind(edge_port_left))
		edge_port_left_container.show()

	setup_context_menu()

func clear() -> void:
	var children = grid_container.get_children()
	
	for i in range(children.size()):
		var child = children[i]
		
		if child is Slot and child.has_block():
			var block: Block = null
			for sub_child in child.get_children():
				if sub_child is Block and not sub_child.is_queued_for_deletion():
					block = sub_child
					break
			
			if block:
				block.queue_free()

func matrix_size_total() -> int:
	match matrix_size:
		MatrixSize._3x3: return 9
		MatrixSize._5x5: return 25
		MatrixSize._7x7: return 49
		MatrixSize._9x9: return 81
		_: return 49

func setup_context_menu() -> void:
	context_menu = PopupMenu.new()
	add_child(context_menu)
	
	context_menu.add_separator("BE_EDGE_PORT_POPUP_MENU")
	context_menu.add_item("BE_EDGE_PORT_NONE", 0)
	context_menu.add_item("BE_EDGE_PORT_INPUT", 1)
	context_menu.add_item("BE_EDGE_PORT_OUTPUT", 2)
	
	context_menu.id_pressed.connect(on_context_menu_id_pressed)

func on_node_gui_input(event: InputEvent, node: Control) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) and event.pressed:
			current_selected_node = node
			context_menu.position = Vector2(get_viewport().get_mouse_position())
			context_menu.popup()

func on_context_menu_id_pressed(id: int) -> void:
	if not is_instance_valid(current_selected_node):
		return

	match id:
		0: current_selected_node.change_type(EdgePort.Port.NONE)
		1: current_selected_node.change_type(EdgePort.Port.INPUT)
		2: current_selected_node.change_type(EdgePort.Port.OUTPUT)
	
	notify_custom_block_changed()

func notify_custom_block_changed() -> void:
	if not is_block or custom_block_uuid.is_empty(): return
	
	var new_ports = [
		map_edge_to_block_port(edge_port_top.port_type),
		map_edge_to_block_port(edge_port_right.port_type),
		map_edge_to_block_port(edge_port_bottom.port_type),
		map_edge_to_block_port(edge_port_left.port_type)
	]
	
	Events.custom_block_changed.emit(custom_block_uuid, new_ports)

func map_edge_to_block_port(edge_type: EdgePort.Port) -> BlockData.Port:
	match edge_type:
		EdgePort.Port.INPUT: return BlockData.Port.INPUT
		EdgePort.Port.OUTPUT: return BlockData.Port.OUTPUT
		_: return BlockData.Port.NONE

func get_grid() -> Array:
	var block_data: Array = []
	block_data.resize(matrix_size_total())
	block_data.fill({})
	
	var children = grid_container.get_children()
	
	for i in range(children.size()):
		var slot = children[i]
		var child_save_data = {}
		
		if slot is Slot and slot.has_block():
			var block: Block = slot.get_block()
			child_save_data = block.get_save_data()
		
		block_data[i] = child_save_data
	
	return block_data

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

	var total_dim: int = internal_dim + 2 if is_block else internal_dim
	
	grid_container.columns = total_dim

	@warning_ignore("integer_division")
	var center_index: int = total_dim / 2

	for y in range(total_dim):
		for x in range(total_dim):
			var node: Control
			var is_port_node: bool = false

			if not is_block:
				node = slot_scene.instantiate()
			else:
				var is_edge: bool = (x == 0 or x == total_dim - 1 or y == 0 or y == total_dim - 1)
				
				if is_edge:
					var is_horizontal_center: bool = (x == center_index and (y == 0 or y == total_dim - 1))
					var is_vertical_center: bool = (y == center_index and (x == 0 or x == total_dim - 1))
					
					if is_horizontal_center or is_vertical_center:
						node = edge_port_scene.instantiate()
						node.port_type = EdgePort.Port.NONE
						is_port_node = true
						
						if y == 0:
							node.direction = EdgePort.Direction.DOWN
						elif y == total_dim - 1:
							node.direction = EdgePort.Direction.UP
						elif x == 0:
							node.direction = EdgePort.Direction.RIGHT
						elif x == total_dim - 1:
							node.direction = EdgePort.Direction.LEFT
					else:
						node = Control.new()
						node.custom_minimum_size = Vector2(84, 84)
				else:
					node = slot_scene.instantiate()
			
			node.name = "Node_%d_%d" % [x, y]
			grid_container.add_child(node)
			
			if is_port_node:
				node.gui_input.connect(on_node_gui_input.bind(node))

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
		0: current_selected_node.port_type = EdgePort.Port.NONE
		1: current_selected_node.port_type = EdgePort.Port.INPUT
		2: current_selected_node.port_type = EdgePort.Port.OUTPUT

	if current_selected_node.has_method("update_visuals"):
		current_selected_node.update_visuals()

func get_grid() -> Dictionary:
	return {}

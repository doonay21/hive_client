class_name ProgramGrid extends VBoxContainer

enum MatrixSize {
	_3x3,
	_5x5,
	_7x7,
	_9x9
}

const slot_scene: PackedScene = preload("res://scenes/brain_editor/slot/slot.tscn")

@export var matrix_size: MatrixSize = MatrixSize._5x5
@export var is_block: bool = false

@onready var label_container: MarginContainer = $LabelContainer
@onready var label: Label = $LabelContainer/Label
@onready var grid_container: GridContainer = %GridContainer
@onready var edge_port_top_container: Control = %EdgePortTopContainer
@onready var edge_port_top: Control = %EdgePortTop
@onready var edge_port_right_container: Control = %EdgePortRightContainer
@onready var edge_port_right: Control = %EdgePortRight
@onready var edge_port_bottom_container: Control = %EdgePortBottomContainer
@onready var edge_port_bottom: Control = %EdgePortBottom
@onready var edge_port_left_container: Control = %EdgePortLeftContainer
@onready var edge_port_left: Control = %EdgePortLeft
@onready var context_menu: PopupMenu = $PopupMenu

var custom_block_uuid: String = ""
var current_selected_node: Control

static func size_to_dimension(matrix_size_p: int) -> int:
	match matrix_size_p:
		MatrixSize._3x3: return 3
		MatrixSize._5x5: return 5
		MatrixSize._7x7: return 7
		MatrixSize._9x9: return 9
	return 5

func initialize() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	var internal_dim: int = get_dimension()

	grid_container.columns = internal_dim

	for y in range(internal_dim):
		for x in range(internal_dim):
			var node: Control
			node = slot_scene.instantiate()
			node.name = "Node_%d_%d" % [x, y]
			node.program_grid = self
			grid_container.add_child(node)

	if is_block:
		label_container.show()
		
		edge_port_top.gui_input.connect(on_node_gui_input.bind(edge_port_top))
		edge_port_top_container.show()
		edge_port_right.gui_input.connect(on_node_gui_input.bind(edge_port_right))
		edge_port_right_container.show()
		edge_port_bottom.gui_input.connect(on_node_gui_input.bind(edge_port_bottom))
		edge_port_bottom_container.show()
		edge_port_left.gui_input.connect(on_node_gui_input.bind(edge_port_left))
		edge_port_left_container.show()

func set_description(text: String) -> void:
	label.text = text

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

func get_dimension() -> int:
	return size_to_dimension(matrix_size)

func matrix_size_total() -> int:
	var d = get_dimension()
	return d * d

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
		BlockData.Port.NONE: current_selected_node.change_type(BlockData.Port.NONE)
		BlockData.Port.INPUT: current_selected_node.change_type(BlockData.Port.INPUT)
		BlockData.Port.OUTPUT: current_selected_node.change_type(BlockData.Port.OUTPUT)
	
	notify_custom_block_changed()

func notify_custom_block_changed() -> void:
	if not is_block or custom_block_uuid.is_empty(): return
	
	var new_ports = [
		edge_port_top.port_type,
		edge_port_right.port_type,
		edge_port_bottom.port_type,
		edge_port_left.port_type
	]
	
	Events.custom_block_changed.emit(custom_block_uuid, new_ports)

func get_grid() -> Array:
	var block_data: Array = []
	block_data.resize(matrix_size_total())
	block_data.fill({})
	
	var children = grid_container.get_children()
	
	for i in range(children.size()):
		var slot: Slot = children[i]
		var child_save_data = {}
		
		if slot.has_block():
			var block: Block = slot.get_block()
			child_save_data = block.get_save_data()
		
		block_data[i] = child_save_data
	
	return block_data

func has_custom_block_usage(target_uuid: String) -> bool:
	var children = grid_container.get_children()
	
	for child in children:
		if child is Slot and child.has_block():
			var block: Block = child.get_block()
			
			if block and block.custom_block_uuid == target_uuid:
				return true
				
	return false

func get_ports_state() -> Array:
	if not is_block: return []
	
	return [
		edge_port_top.port_type,
		edge_port_right.port_type,
		edge_port_bottom.port_type,
		edge_port_left.port_type
	]

func get_program_data() -> Array:
	var children = grid_container.get_children()
	var data: Array = []
	
	for i in range(children.size()):
		var slot: Slot = children[i]
		var block_program_data = {}
		
		if slot.has_block():
			var block: Block = slot.get_block()
			
			if block:
				block_program_data = block.get_program_data()
		
		data.append(block_program_data)
	
	return data

extends Control

@onready var graph_edit: GraphEdit = $VBoxContainer/GraphEdit
@onready var context_menu = $VBoxContainer/GraphEdit/ContextMenu
@onready var button_save: Button = $VBoxContainer/Panel/MarginContainer/HBoxContainer/ButtonSave

var node_templates: Dictionary = {
	0: preload("res://scenes/brain_editor/nodes/constant.tscn"),
	1: preload("res://scenes/brain_editor/nodes/gate.tscn"),
	2: preload("res://scenes/brain_editor/nodes/not.tscn"),
	3: preload("res://scenes/brain_editor/nodes/comparator.tscn"),
	4: preload("res://scenes/brain_editor/nodes/memory.tscn"),
	5: preload("res://scenes/brain_editor/nodes/buffer.tscn"),
	6: preload("res://scenes/brain_editor/nodes/edge_detector.tscn")
}

var mouse_click_position: Vector2 = Vector2.ZERO

var id_counter: int = 1000

func _ready() -> void:
	context_menu.add_item("Constant", 0)
	context_menu.add_item("Gate", 1)
	context_menu.add_item("Not", 2)
	context_menu.add_item("Comparator", 3)
	context_menu.add_item("Memory", 4)
	context_menu.add_item("Buffer", 5)
	context_menu.add_item("Edge Detector", 6)
	
	graph_edit.popup_request.connect(on_graph_edit_popup_request)
	context_menu.id_pressed.connect(on_context_menu_id_pressed)
	
	graph_edit.connection_request.connect(on_graph_edit_connection_request)
	graph_edit.disconnection_request.connect(on_graph_edit_disconnection_request)
	
	button_save.pressed.connect(on_button_save_pressed)
	
func on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

func on_graph_edit_popup_request(at_position: Vector2):
	mouse_click_position = at_position
	context_menu.position = get_global_mouse_position()
	context_menu.popup()

func on_context_menu_id_pressed(id: int):
	var new_node: GraphNode = node_templates[id].instantiate()
	new_node.id = id_counter
	id_counter += 1
	
	if new_node:
		graph_edit.add_child(new_node)
		
		new_node.position_offset = (mouse_click_position + graph_edit.scroll_offset) / graph_edit.zoom

func on_button_save_pressed() -> void:
	var signals: PackedFloat32Array = []
	
	var raw_connections = graph_edit.get_connection_list()
	
	var json = JSON.stringify(raw_connections, " ")
	
	print(json)

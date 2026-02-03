extends Control

@onready var graph_edit: GraphEdit = $GraphEdit
@onready var context_menu = $GraphEdit/ContextMenu

var node_templates: Dictionary = {
	0: preload("res://scenes/brain_editor/nodes/not.tscn")
}

var mouse_click_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	context_menu.add_item("Not", 0)
	
	graph_edit.popup_request.connect(on_graph_edit_popup_request)
	context_menu.id_pressed.connect(on_context_menu_id_pressed)
	
	graph_edit.connection_request.connect(on_graph_edit_connection_request)
	graph_edit.disconnection_request.connect(on_graph_edit_disconnection_request)
	
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
	
	if new_node:
		graph_edit.add_child(new_node)
		
		new_node.position_offset = (mouse_click_position + graph_edit.scroll_offset) / graph_edit.zoom

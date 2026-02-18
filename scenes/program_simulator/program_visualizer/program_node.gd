class_name ProgramNode extends Node2D

const ORIGINAL_SIZE: float = 44.0

@onready var background: Sprite2D = $Background
@onready var icon: Sprite2D = $Background/Icon
@onready var ports: Array[Node2D] = [ $PortTop, $PortRight, $PortBottom, $PortLeft ]

var target_scale: Vector2 = Vector2(1.0, 1.0)
var empty: bool = true
var logical_ports: Array = [0, 0, 0, 0]

var target_size: float = 44.0:
	set(value):
		target_size = value
		
		var temp_scale: float = value / ORIGINAL_SIZE
		target_scale = Vector2(temp_scale, temp_scale)

var target_position: Vector2 = Vector2.ZERO

func _process(_delta: float) -> void:
	position = position.lerp(target_position, 0.3)
	background.scale = background.scale.lerp(target_scale, 0.3)

func set_node(data: Dictionary) -> void:
	empty = false
	background.self_modulate.a = 0.5
	
	for port in ports:
		port.material.set_shader_parameter("alpha", 0.5)
	
	var op = data.get("op", BlockData.Op.NONE)
	var block_res: BlockData
	
	if op == BlockData.Op.CUSTOM and "uuid" in data:
		block_res = BlockLibrary.get_custom_block_data(data["uuid"])
	else:
		block_res = BlockLibrary.get_data_for_op(op)
	
	if not block_res:
		icon.texture = preload("res://assets/images/brain_editor/block_icons/missing.png")
		return

	icon.texture = block_res.icon
	
	var icon_size: Vector2 = icon.texture.get_size()
	icon.scale = Vector2(40.0, 40.0) / icon_size
	
	var map_rotation = data.get("map", [0, 1, 2, 3])
	
	for i in range(4):
		var original_port_idx = map_rotation[i] 
		var port_type = block_res.ports[original_port_idx]
		
		logical_ports[i] = port_type
		update_port_visual(i, port_type)

func update_port_visual(side_index: int, type: BlockData.Port) -> void:
	var sprite = ports[side_index]
	sprite.visible = type == BlockData.Port.OUTPUT

func update_ports(node_size: float, node_margin: float) -> void:
	var half_size: float = node_size / 2.0
	
	ports[0].points[0] = Vector2(0.0, -half_size)
	ports[0].points[1] = Vector2(0.0, -half_size - node_margin)
	ports[1].points[0] = Vector2(half_size, 0.0)
	ports[1].points[1] = Vector2(half_size + node_margin, 0.0)
	ports[2].points[0] = Vector2(0.0, half_size)
	ports[2].points[1] = Vector2(0.0, half_size + node_margin)
	ports[3].points[0] = Vector2(-half_size, 0.0)
	ports[3].points[1] = Vector2(-half_size - node_margin, 0.0)

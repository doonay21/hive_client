class_name ProgramVisualizer extends Node2D

const NODE_SCENE: PackedScene = preload("res://scenes/program_simulator/program_visualizer/program_node.tscn")

var grid: Dictionary[Vector2i, ProgramNode] = {}
var column_count: int = 7
var grid_total_size: Vector2 = Vector2.ZERO
var grid_half_size: Vector2 = Vector2.ZERO

var program_data: Dictionary = {}

var node_margin: float = 20.0:
	set(value):
		node_margin = value
		recalculate_grid()

var node_size: float = 44.0:
	set(value):
		node_size = value
		recalculate_grid()

func start(program_data_p: Dictionary) -> void:
	program_data = program_data_p
	column_count = ProgramGrid.size_to_dimension(program_data["size"])
	grid_total_size = Vector2(column_count, column_count) * (node_margin + node_size)
	grid_half_size = grid_total_size / 2.0
	
	create_grid()
	calculate_connections()
	recalculate_grid(true)

func toggle_empty_nodes(toggled_on: bool) -> void:
	for y in range(column_count):
		for x in range(column_count):
			var node: ProgramNode = grid[Vector2i(x, y)]
			node.visible = !toggled_on or not node.empty

func create_grid() -> void:
	var counter: int = 0
	
	for y in range(column_count):
		for x in range(column_count):
			var node: ProgramNode = NODE_SCENE.instantiate()
			add_child(node)
			
			if not program_data["grid"][counter].is_empty():
				node.set_node(program_data["grid"][counter])
			
			grid[Vector2i(x, y)] = node
	
			counter += 1

func recalculate_grid(force_position: bool = false) -> void:
	grid_total_size = Vector2(column_count, column_count) * (node_margin + node_size)
	grid_half_size = grid_total_size / 2.0
	
	var target_margin: float = node_size + node_margin
	
	for y in range(column_count):
		for x in range(column_count):
			var node: ProgramNode = grid[Vector2i(x, y)]
			
			node.target_size = node_size
			node.target_position = Vector2(x * target_margin, y * target_margin) - grid_half_size
			node.update_ports(node_size, node_margin)
			
			if force_position:
				node.position = node.target_position

func calculate_connections() -> void:
	var directions = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	
	for y in range(column_count):
		for x in range(column_count):
			var pos = Vector2i(x, y)
			if not grid.has(pos): continue
			
			var node: ProgramNode = grid[pos]
			if node.empty: continue
			
			var active_connections: Array[bool] = [false, false, false, false]
			
			for i in range(4):
				if node.logical_ports[i] != BlockData.Port.OUTPUT:
					continue
				
				var neighbor_pos = pos + directions[i]
				
				if grid.has(neighbor_pos):
					var neighbor: ProgramNode = grid[neighbor_pos]
					
					if not neighbor.empty:
						var opposite_side = (i + 2) % 4
						
						if neighbor.logical_ports[opposite_side] == BlockData.Port.INPUT:
							active_connections[i] = true
			
			node.update_connections_visibility(active_connections)

class_name ProgramVisualizer extends Node2D

const NODE_SCENE: PackedScene = preload("res://scenes/program_simulator/program_visualizer/program_node.tscn")
const NODE_SIZE: float = 24.0

var program_data: Dictionary = {}
var grid: Dictionary[Vector2i, ProgramNode] = {}

var column_count: int = 7
var grid_total_size: Vector2 = Vector2.ZERO
var grid_half_size: Vector2 = Vector2.ZERO

var node_margin: float = 20.0:
	set(value):
		node_margin = value
		recalculate_grid()

func start(brain_editor: BrainEditor) -> void:
	program_data = brain_editor.get_program_data()
	column_count = ProgramGrid.size_to_dimension(program_data["size"])
	grid_total_size = Vector2(column_count, column_count) * node_margin
	grid_half_size = grid_total_size / 2.0
	
	create_grid()
	recalculate_grid()
	
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

func recalculate_grid() -> void:
	grid_total_size = Vector2(column_count, column_count) * node_margin
	grid_half_size = grid_total_size / 2.0
	
	var target_margin: float = NODE_SIZE + node_margin
	
	for y in range(column_count):
		for x in range(column_count):
			var node: ProgramNode = grid[Vector2i(x, y)]
			
			node.target_position = Vector2(x * target_margin, y * target_margin) - grid_half_size

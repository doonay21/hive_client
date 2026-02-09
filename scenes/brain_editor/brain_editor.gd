class_name BrainEditor extends CanvasLayer

enum Size {
	_3x3,
	_5x5,
	_7x7,
	_9x9
}

@export var size: Size = Size._5x5

@onready var grid_container: GridContainer = %GridContainer

const slot_scene: PackedScene = preload("res://scenes/brain_editor/slot/slot.tscn")

func _ready() -> void:
	initialize_grid()

func initialize_grid() -> void:
	var columns: int = 5
	
	match size:
		Size._3x3: columns = 3
		Size._5x5: columns = 5
		Size._7x7: columns = 7
		Size._9x9: columns = 9

	grid_container.columns = columns

	for i in range(columns * columns):
		var slot: Control = slot_scene.instantiate()
		slot.name = "Slot%s" % i
		grid_container.add_child(slot)

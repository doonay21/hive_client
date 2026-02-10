class_name SaveBrain extends Resource

@export var name: String
@export var uuid: String
@export var size: ProgramGrid.MatrixSize
@export var grid: Dictionary[Vector2i, Dictionary]
@export var in_nested_view: bool

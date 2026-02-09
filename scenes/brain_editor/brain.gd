class_name Brain extends Resource

@export var size: BrainGrid.MatrixSize
@export var in_nested_view: bool
@export var blocks: Dictionary[Vector2i, Dictionary] = {}

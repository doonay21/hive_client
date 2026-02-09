class_name Brain extends Resource

@export var size: BrainEditor.Size
@export var edge_ports_active: bool
@export var blocks: Dictionary[Vector2i, Dictionary] = {}

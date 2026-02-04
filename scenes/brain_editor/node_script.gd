extends GraphNode

enum NodeType {
	InSightFront,
	InSightLeft,
	InSightRight,
	OutGo,
	OutTurnLeft,
	OutTurnRight,
	Buffer,
	Comarator,
	Constant,
	EdgeDetector,
	Gate,
	Memory,
	Not
}

@export var node_type: NodeType
@export var id: int = 0

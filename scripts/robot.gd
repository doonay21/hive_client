class_name Robot extends RefCounted

enum Direction { UP, RIGHT, DOWN, LEFT }

var map: Map
var direction: Direction = Direction.UP
var position: Vector2i = Vector2i.ZERO

const VISION_RANGE: int = 10

func get_direction_vector(dir: Direction) -> Vector2i:
	match dir:
		Direction.UP: return Vector2i(0, -1)
		Direction.RIGHT: return Vector2i(1, 0)
		Direction.DOWN: return Vector2i(0, 1)
		Direction.LEFT: return Vector2i(-1, 0)
	return Vector2i.ZERO

func turn_left() -> void:
	direction = posmod(direction - 1, 4) as Direction

func turn_right() -> void:
	direction = (direction + 1) % 4 as Direction

func is_pixel_free(target_pos: Vector2i) -> bool:
	if map == null: return false
	
	var material = map.get_material_at(target_pos)
	return material == Map.MaterialType.VOID

func move_forward() -> bool:
	var next_pos = position + get_direction_vector(direction)
	
	if is_pixel_free(next_pos):
		position = next_pos
		return true
	
	return false

func raycast(dir: Direction) -> float:
	var vec = get_direction_vector(dir)
	
	for distance in range(1, VISION_RANGE + 1):
		var check_pos = position + (vec * distance)
		
		if not is_pixel_free(check_pos):
			return 1.0 - (float(distance - 1) / float(VISION_RANGE))
			
	return 0.0 

func sense_forward() -> float:
	return raycast(direction)

func sense_left() -> float:
	var left_dir = posmod(direction - 1, 4) as Direction
	return raycast(left_dir)

func sense_right() -> float:
	var right_dir = (direction + 1) % 4 as Direction
	return raycast(right_dir)

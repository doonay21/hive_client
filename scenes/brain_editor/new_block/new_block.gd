@tool
class_name NewBlock extends Control

enum Side { TOP, RIGHT, BOTTOM, LEFT }

const DEPTH_NONE = 0.0
const DEPTH_NORMAL = 5.0
const DEPTH_CONNECTED = 7.0

@export_group("Port Configuration")
@export var top_type: BlockData.Port = BlockData.Port.NONE: set = set_top
@export var right_type: BlockData.Port = BlockData.Port.NONE: set = set_right
@export var bottom_type: BlockData.Port = BlockData.Port.NONE: set = set_bottom
@export var left_type: BlockData.Port = BlockData.Port.NONE: set = set_left

@onready var background: Polygon2D = %Background
@onready var border: Line2D = %Border

var offsets = {
	Side.TOP: 0.0,
	Side.RIGHT: 0.0,
	Side.BOTTOM: 0.0,
	Side.LEFT: 0.0
}

var connections = {
	Side.TOP: false,
	Side.RIGHT: false,
	Side.BOTTOM: false,
	Side.LEFT: false
}

func _ready():
	ensure_geometry()
	update_shape_visuals()

func ensure_geometry():
	var pts = PackedVector2Array()
	pts.resize(16)
	
	border.points = pts
	background.polygon = pts

func update_shape_visuals():
	if not is_instance_valid(border) or not is_instance_valid(background):
		return

	var w = size.x
	var h = size.y
	var hw = border.width / 2.0 
	var min_x = hw
	var max_x = w - hw
	var min_y = hw
	var max_y = h - hw
	var t = offsets[Side.TOP]
	var r = offsets[Side.RIGHT]
	var b = offsets[Side.BOTTOM]
	var l = offsets[Side.LEFT]

	var pts = border.points
	if pts.size() != 16: 
		pts.resize(16)
	
	pts[0] = Vector2(min_x, min_y)
	pts[1] = Vector2(w * 0.33, min_y)
	pts[2] = Vector2(w * 0.5, min_y + t)
	pts[3] = Vector2(w * 0.66, min_y)
	
	pts[4] = Vector2(max_x, min_y)
	pts[5] = Vector2(max_x, h * 0.33)
	pts[6] = Vector2(max_x + r, h * 0.5)
	pts[7] = Vector2(max_x, h * 0.66)
	
	pts[8] = Vector2(max_x, max_y)
	pts[9] = Vector2(w * 0.66, max_y)
	pts[10] = Vector2(w * 0.5, max_y + b)
	pts[11] = Vector2(w * 0.33, max_y)
	
	pts[12] = Vector2(min_x, max_y)
	pts[13] = Vector2(min_x, h * 0.66)
	pts[14] = Vector2(min_x + l, h * 0.5)
	pts[15] = Vector2(min_x, h * 0.33)

	border.points = pts
	
	var poly_pts = pts.duplicate()
	poly_pts.append(pts[0]) 
	background.polygon = pts

func animate_port(side: Side, target_depth: float, connection_anim: bool = false):
	var tween = create_tween()
	
	if connection_anim:
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.set_ease(Tween.EASE_OUT)
	else:
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_method(func(val): 
		offsets[side] = val
		update_shape_visuals(),
		offsets[side],
		target_depth,
		0.4 if connection_anim else 0.25
	)

func get_target_offset(side: Side, type: BlockData.Port) -> float:
	var is_conn = connections[side]
	var depth = DEPTH_CONNECTED if is_conn else DEPTH_NORMAL
	
	match type:
		BlockData.Port.NONE: return 0.0
		BlockData.Port.INPUT:
			match side:
				Side.TOP: return depth
				Side.BOTTOM: return -depth
				Side.RIGHT: return -depth
				Side.LEFT: return depth
		BlockData.Port.OUTPUT:
			match side:
				Side.TOP: return -depth
				Side.BOTTOM: return depth
				Side.RIGHT: return depth
				Side.LEFT: return -depth
	return 0.0

func update_side(side: int, new_type: BlockData.Port):
	var target = get_target_offset(side, new_type)
	animate_port(side, target)

func set_connected(side: int, is_conn: bool):
	connections[side] = is_conn
	var current_type = BlockData.Port.NONE
	
	match side:
		Side.TOP: current_type = top_type
		Side.RIGHT: current_type = right_type
		Side.BOTTOM: current_type = bottom_type
		Side.LEFT: current_type = left_type
		
	var target = get_target_offset(side, current_type)
	animate_port(side, target, true)

func set_top(val): top_type = val; update_side(Side.TOP, val)
func set_right(val): right_type = val; update_side(Side.RIGHT, val)
func set_bottom(val): bottom_type = val; update_side(Side.BOTTOM, val)
func set_left(val): left_type = val; update_side(Side.LEFT, val)

@tool
class_name NewBlock extends Control

enum Side { TOP, RIGHT, BOTTOM, LEFT }

@export_group("Port Configuration")
@export var top_type: BlockData.Port = BlockData.Port.NONE: set = set_top
@export var right_type: BlockData.Port = BlockData.Port.NONE: set = set_right
@export var bottom_type: BlockData.Port = BlockData.Port.NONE: set = set_bottom
@export var left_type: BlockData.Port = BlockData.Port.NONE: set = set_left

@export_group("Port Depths (Height)")
@export var depth_normal: float = 3.0: set = set_depth_normal
@export var depth_connected: float = 7.0: set = set_depth_connected

@export_group("Port Geometry")
@export_range(0.1, 1.0) var port_base_width: float = 0.34: set = set_base_width
@export_range(0.0, 1.0) var port_tip_width: float = 0.15: set = set_tip_width

@onready var background: Polygon2D = %Background
@onready var border: Line2D = %Border

var left_margin: float = 0.33
var right_margin: float = 0.66

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
	pts.resize(20)
	
	border.points = pts
	background.polygon = pts

func update_shape_visuals():
	if not is_instance_valid(border) or not is_instance_valid(background):
		return

	var w = size.x
	var h = size.y
	var bw = border.width / 2.0 # Pobieramy grubość linii
	var hw = bw / 2.0 
	var min_x = hw
	var max_x = w - hw
	var min_y = hw
	var max_y = h - hw
	
	var t = offsets[Side.TOP]
	var r = offsets[Side.RIGHT]
	var b = offsets[Side.BOTTOM]
	var l = offsets[Side.LEFT]

	var pts = border.points
	if pts.size() != 20: 
		pts.resize(20)

	# Funkcja pomocnicza obliczająca punkty dla portu z uwzględnieniem grubości linii
	var get_coords = func(type: BlockData.Port, length: float) -> Dictionary:
		var adjust = 0.0
		if type == BlockData.Port.INPUT:
			adjust = bw # Otwór (IN) musi być szerszy, by pomieścić wypustkę
		elif type == BlockData.Port.OUTPUT:
			adjust = -bw # Wypustka (OUT) musi być węższa
			
		var center = length / 2.0
		var base_half = ((length * port_base_width) + adjust) / 2.0
		var tip_half = ((length * port_tip_width) + adjust) / 2.0
		
		return {
			"base_l": center - base_half,
			"base_r": center + base_half,
			"tip_l": center - tip_half,
			"tip_r": center + tip_half
		}

	# TOP (od lewej do prawej)
	var top_c = get_coords.call(top_type, w)
	pts[0] = Vector2(min_x, min_y)
	pts[1] = Vector2(top_c.base_l, min_y)
	pts[2] = Vector2(top_c.tip_l, min_y + t)
	pts[3] = Vector2(top_c.tip_r, min_y + t)
	pts[4] = Vector2(top_c.base_r, min_y)
	
	# RIGHT (z góry na dół)
	var right_c = get_coords.call(right_type, h)
	pts[5] = Vector2(max_x, min_y)
	pts[6] = Vector2(max_x, right_c.base_l)
	pts[7] = Vector2(max_x + r, right_c.tip_l)
	pts[8] = Vector2(max_x + r, right_c.tip_r)
	pts[9] = Vector2(max_x, right_c.base_r)
	
	# BOTTOM (od prawej do lewej - odwracamy kolejność L/R dla logiki rysowania)
	var bottom_c = get_coords.call(bottom_type, w)
	pts[10] = Vector2(max_x, max_y)
	pts[11] = Vector2(bottom_c.base_r, max_y)
	pts[12] = Vector2(bottom_c.tip_r, max_y + b)
	pts[13] = Vector2(bottom_c.tip_l, max_y + b)
	pts[14] = Vector2(bottom_c.base_l, max_y)
	
	# LEFT (z dołu do góry - odwracamy kolejność L/R dla logiki rysowania)
	var left_c = get_coords.call(left_type, h)
	pts[15] = Vector2(min_x, max_y)
	pts[16] = Vector2(min_x, left_c.base_r)
	pts[17] = Vector2(min_x + l, left_c.tip_r)
	pts[18] = Vector2(min_x + l, left_c.tip_l)
	pts[19] = Vector2(min_x, left_c.base_l)

	border.points = pts
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
	var depth = depth_connected if is_conn else depth_normal # ZMIANA TUTAJ
	
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

func update_all() -> void:
	update_side(Side.TOP, top_type)
	update_side(Side.RIGHT, right_type)
	update_side(Side.BOTTOM, bottom_type)
	update_side(Side.LEFT, left_type)

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

func set_depth_normal(val): depth_normal = val; update_all()
func set_depth_connected(val): depth_connected = val; update_all()
func set_base_width(val): port_base_width = val; update_all()
func set_tip_width(val): port_tip_width = val; update_all()

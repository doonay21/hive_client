extends Line2D

const BOX_SIZE: float = 80.0
const TRIANGLE_BASE: float = 28.0
const TRIANGLE_HEIGHT: float = 6.0
const CORNER_RADIUS: float = 10.0
const CORNER_RESOLUTION: int = 8

var top_h: float = 0.0
var right_h: float = 0.0
var bottom_h: float = 0.0
var left_h: float = 0.0

func _ready() -> void:
	closed = true 
	update_shape()

func update_shape() -> void:
	var pts := PackedVector2Array()
	var offset = width / 2.0 
	var min_pos = offset
	var max_pos = BOX_SIZE - offset
	var max_possible_radius = (BOX_SIZE - width) / 2.0
	var r = clamp(CORNER_RADIUS, 0.0, max_possible_radius)

	var add_arc = func(center: Vector2, start_angle: float, end_angle: float):
		for i in range(CORNER_RESOLUTION):
			var t = float(i) / float(CORNER_RESOLUTION - 1)
			var angle = lerp(start_angle, end_angle, t)
			pts.append(center + Vector2(cos(angle), sin(angle)) * r)

	var process_edge = func(start_p: Vector2, end_p: Vector2, out_dir: Vector2, current_h: float):
		var edge_vec = end_p - start_p
		var edge_len = edge_vec.length()
		var edge_dir = edge_vec.normalized()
		var tri_center = edge_len * 0.5
		var half_base = TRIANGLE_BASE / 2.0

		if tri_center - half_base > 0 and tri_center + half_base < edge_len:
			var t1 = start_p + edge_dir * (tri_center - half_base)
			var t2 = start_p + edge_dir * tri_center + out_dir * current_h
			var t3 = start_p + edge_dir * (tri_center + half_base)

			pts.append(t1)
			pts.append(t2)
			pts.append(t3)

	var c_tl = Vector2(min_pos + r, min_pos + r)
	var c_tr = Vector2(max_pos - r, min_pos + r)
	var c_br = Vector2(max_pos - r, max_pos - r)
	var c_bl = Vector2(min_pos + r, max_pos - r)

	add_arc.call(c_tl, PI, PI * 1.5)
	process_edge.call(Vector2(min_pos + r, min_pos), Vector2(max_pos - r, min_pos), Vector2(0, -1), top_h)
	add_arc.call(c_tr, -PI/2.0, 0.0)
	process_edge.call(Vector2(max_pos, min_pos + r), Vector2(max_pos, max_pos - r), Vector2(1, 0), right_h)
	add_arc.call(c_br, 0.0, PI/2.0)
	process_edge.call(Vector2(max_pos - r, max_pos), Vector2(min_pos + r, max_pos), Vector2(0, 1), bottom_h)
	add_arc.call(c_bl, PI/2.0, PI)
	process_edge.call(Vector2(min_pos, max_pos - r), Vector2(min_pos, min_pos + r), Vector2(-1, 0), left_h)

	self.points = pts

@tool
class_name NewBlock extends Control

@export var top_shape: BlockData.Port = BlockData.Port.NONE:
	set(value):
		top_shape = value
		animate_block()

@export var right_shape: BlockData.Port = BlockData.Port.NONE:
	set(value):
		right_shape = value
		animate_block()

@export var bottom_shape: BlockData.Port = BlockData.Port.NONE:
	set(value):
		bottom_shape = value
		animate_block()

@export var left_shape: BlockData.Port = BlockData.Port.NONE:
	set(value):
		left_shape = value
		animate_block()

@onready var background: Polygon2D = $BackgroundContainer/Background
@onready var border: Line2D = $BackgroundContainer/Border

var tween: Tween

func _ready() -> void:
	if not is_node_ready():
		return
	
	snap_to_target()

func get_target_height(port: BlockData.Port) -> float:
	if not is_node_ready(): 
		return 0.0
	match port:
		BlockData.Port.NONE: return 0.0
		BlockData.Port.INPUT: return -border.TRIANGLE_HEIGHT
		BlockData.Port.OUTPUT: return border.TRIANGLE_HEIGHT
	return 0.0

func snap_to_target() -> void:
	if not is_node_ready(): return
	border.top_h = get_target_height(top_shape)
	border.right_h = get_target_height(right_shape)
	border.bottom_h = get_target_height(bottom_shape)
	border.left_h = get_target_height(left_shape)
	update_visuals(1.0)

func animate_block() -> void:
	if not is_node_ready():
		return
		
	if tween and tween.is_valid():
		tween.kill()
		
	tween = create_tween().set_parallel(true)
	
	animate_single_edge("top_h", border.top_h, get_target_height(top_shape))
	animate_single_edge("right_h", border.right_h, get_target_height(right_shape))
	animate_single_edge("bottom_h", border.bottom_h, get_target_height(bottom_shape))
	animate_single_edge("left_h", border.left_h, get_target_height(left_shape))
	
	tween.tween_method(update_visuals, 0.0, 1.0, 0.6)

func animate_single_edge(prop_name: String, current_val: float, target_val: float) -> void:
	var diff = target_val - current_val
	if abs(diff) < 0.01:
		return

	var pull_back_val = current_val - (diff * 0.35)
	var pull_time = 0.12
	
	tween.tween_property(border, prop_name, pull_back_val, pull_time) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
		
	var snap_time = 0.35
	tween.tween_property(border, prop_name, target_val, snap_time) \
		.set_trans(Tween.TRANS_SPRING) \
		.set_ease(Tween.EASE_OUT) \
		.set_delay(pull_time)

func update_visuals(_dummy_value: float) -> void:
	border.update_shape()
	background.polygon = border.points

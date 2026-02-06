class_name ValueDrag extends Label

const PIXELS_PER_STEP: float = 20.0
const STEP: float = 0.05
const STEP_PRECISE: float = 0.01

var value: float = 1.0
var dragging: bool = false
var drag_accumulator: float = 0.0
var drag_start_position: Vector2 = Vector2.ZERO

func _ready():
	update_label()
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag()
			else:
				end_drag()

	if event is InputEventMouseMotion and dragging:
		handle_drag(event)

func start_drag():
	dragging = true
	drag_accumulator = 0.0
	drag_start_position = get_viewport().get_mouse_position()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func end_drag():
	dragging = false
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.warp_mouse(drag_start_position)

func handle_drag(event):
	var step = STEP
	if Input.is_key_pressed(KEY_SHIFT):
		step = STEP_PRECISE

	drag_accumulator -= event.relative.y
	
	if abs(drag_accumulator) >= PIXELS_PER_STEP:
		var steps_taken = int(drag_accumulator / PIXELS_PER_STEP)
		
		value += steps_taken * step
		value = clamp(value, 0.00, 1.00)
		value = snapped(value, step)
		
		update_label()
		
		drag_accumulator -= steps_taken * PIXELS_PER_STEP

func update_label():
	text = "%.2f" % value

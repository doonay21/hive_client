class_name CursorPreview extends Node2D

var pixel_size: int = 4
var brush_steps: int = 1
var active: bool = false

func _process(_delta: float) -> void:
	if not active: return

	global_position = (get_global_mouse_position() / pixel_size).floor() * pixel_size

func toggle(toggled_on: bool) -> void:
	active = toggled_on
	
	queue_redraw()

func set_size(size: int) -> void:
	brush_steps = clamp(size, 1, 10)
	
	queue_redraw()

func _draw() -> void:
	if not active: return
	
	for x in range(-brush_steps, brush_steps + 1):
		for y in range(-brush_steps, brush_steps + 1):
			if Vector2(x, y).length() <= brush_steps - 0.5:
				var rect = Rect2(
					Vector2(x, y) * pixel_size, 
					Vector2(pixel_size, pixel_size)
				)
				
				draw_rect(rect, Color(1, 1, 1, 0.6))

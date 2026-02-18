extends Camera2D

@export var zoom_speed: float = 0.1
@export var zoom_min: float = 0.1
@export var zoom_max: float = 5.0
@export var zoom_smoothness: float = 10.0

var target_zoom: float = 1.0

func _ready():
	target_zoom = zoom.x

func _process(delta: float) -> void:
	zoom.x = lerp(zoom.x, target_zoom, zoom_smoothness * delta)
	zoom.y = lerp(zoom.y, target_zoom, zoom_smoothness * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			position -= event.relative / zoom.x

	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_zoom += zoom_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_zoom -= zoom_speed
				
			target_zoom = clamp(target_zoom, zoom_min, zoom_max)

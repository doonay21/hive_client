extends Camera2D

@export var zoom_speed: float = 0.1
@export var zoom_min: float = 0.05
@export var zoom_max: float = 5.0
@export var zoom_smoothness: float = 10.0

var target_zoom: float = 1.0
var target_position: Vector2

func _ready():
	target_zoom = zoom.x
	target_position = position

func _process(delta: float) -> void:
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), zoom_smoothness * delta)
	position = position.lerp(target_position, zoom_smoothness * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			target_position -= event.relative / zoom.x

	if event is InputEventMouseButton:
		if event.is_pressed():
			var old_zoom = target_zoom
			
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_zoom += zoom_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_zoom -= zoom_speed
				
			target_zoom = clamp(target_zoom, zoom_min, zoom_max)
			
			if target_zoom != old_zoom:
				var screen_offset = get_local_mouse_position() * zoom.x
				var shift = (screen_offset / old_zoom) - (screen_offset / target_zoom)
				
				target_position += shift

func fit_to_bounds(map_pixel_size: Vector2, viewport_size: Vector2, margin_factor: float = 0.95) -> void:
	target_position = map_pixel_size / 2.0
	position = target_position
	
	var zoom_x = viewport_size.x / map_pixel_size.x
	var zoom_y = viewport_size.y / map_pixel_size.y
	var calculated_zoom = min(zoom_x, zoom_y) * margin_factor
	
	target_zoom = clamp(calculated_zoom, zoom_min, zoom_max)
	zoom = Vector2(target_zoom, target_zoom)

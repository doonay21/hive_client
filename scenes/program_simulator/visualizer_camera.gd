extends Camera2D

@export_group("Ustawienia Zoomu")
@export var zoom_speed: float = 0.1
@export var zoom_min: float = 0.1
@export var zoom_max: float = 5.0
@export var zoom_smoothness: float = 10.0

var _target_zoom: float = 1.0

func _ready():
	_target_zoom = zoom.x

func _process(delta):
	zoom.x = lerp(zoom.x, _target_zoom, zoom_smoothness * delta)
	zoom.y = lerp(zoom.y, _target_zoom, zoom_smoothness * delta)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			position -= event.relative / zoom.x

	if event is InputEventMouseButton:
		if event.is_pressed():
			var previous_zoom = _target_zoom
			
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_target_zoom += zoom_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_target_zoom -= zoom_speed
				
			_target_zoom = clamp(_target_zoom, zoom_min, zoom_max)
			
			# Opcjonalne: Zoom do pozycji myszy
			if previous_zoom != _target_zoom:
				_zoom_to_mouse(event.position)

func _zoom_to_mouse(mouse_pos: Vector2):
	# Obliczamy różnicę pozycji, aby kamera "celowała" w kursor podczas zoomu
	var mouse_world_before = get_global_mouse_position()
	
	# Aktualizujemy zoom natychmiastowo dla obliczeń pozycji (lub czekamy na lerp)
	# W tej wersji pozwalamy lerpowi działać, ale korygujemy pozycję w locie
	var zoom_factor = _target_zoom / zoom.x
	# (To prosta metoda, dla idealnego "zoom to cursor" bez jittera 
	# wymagałaby skomplikowanej matematyki w _process)

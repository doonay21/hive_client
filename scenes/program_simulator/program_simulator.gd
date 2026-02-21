class_name ProgramSimulator extends Window

@onready var map_tools: MapTools = %MapTools
@onready var program_visualizer: ProgramVisualizer = %ProgramVisualizer
@onready var map_view: MapView = %MapView
@onready var map_camera: Camera2D = %MapCamera
@onready var sub_viewport: SubViewport = %SubViewport

var brain_editor: BrainEditor
var program_data: Dictionary = {}
var interpreter: ProgramInterpreter

func _ready() -> void:
	popup_centered_ratio(0.9)
	
	get_tree().root.size_changed.connect(on_root_size_changed)
	
	program_data = brain_editor.get_program_data()
	program_visualizer.start(program_data)
	
	interpreter = ProgramInterpreter.new(program_data)
	
	call_deferred("center_and_fit_map")

func center_and_fit_map() -> void:
	if not is_instance_valid(map_view) or not is_instance_valid(map_camera) or not is_instance_valid(sub_viewport):
		return
		
	var tile_size: Vector2i = map_view.tile_map.tile_set.tile_size
	var map_pixel_size = Vector2(map_view.MAP_SIZE.x * tile_size.x, map_view.MAP_SIZE.y * tile_size.y)
	var vp_size = Vector2(sub_viewport.size)
	
	map_camera.fit_to_bounds(map_pixel_size, vp_size)

func tick() -> void:
	interpreter.tick()

func on_close_requested() -> void:
	queue_free()

func on_root_size_changed():
	var new_root_size = get_tree().root.size
	self.max_size = new_root_size
	# Opcjonalnie: odkomentuj poniższą linię, jeśli mapa ma się wyśrodkować również 
	# przy każdym ręcznym przeskalowaniu okna z symulatorem.
	# call_deferred("center_and_fit_map")

func on_map_container_mouse_entered() -> void:
	map_tools.enable_info_label()

func on_map_container_mouse_exited() -> void:
	map_tools.disable_info_label()

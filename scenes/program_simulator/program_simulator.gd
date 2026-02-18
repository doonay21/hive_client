class_name ProgramSimulator extends Window

@onready var map: Map = %Map
@onready var map_tools: MapTools = %MapTools
@onready var program_visualizer: ProgramVisualizer = %ProgramVisualizer

var brain_editor: BrainEditor

func _ready() -> void:
	popup_centered_ratio(0.9)
	
	get_tree().root.size_changed.connect(on_root_size_changed)
	
	program_visualizer.start(brain_editor)

func on_close_requested() -> void:
	queue_free()

func on_root_size_changed():
	var new_root_size = get_tree().root.size
	
	self.max_size = new_root_size

func on_map_container_mouse_entered() -> void:
	map_tools.enable_info_label()

func on_map_container_mouse_exited() -> void:
	map_tools.disable_info_label()

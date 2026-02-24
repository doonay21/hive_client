class_name ProgramSimulator extends Window

const robot_scene: PackedScene = preload("res://scenes/robot/robot.tscn")

@onready var map_tools: MapTools = %MapTools
@onready var program_visualizer: ProgramVisualizer = %ProgramVisualizer
@onready var map_view: MapView = %MapView
@onready var map_camera: Camera2D = %MapCamera
@onready var sub_viewport: SubViewport = %SubViewport
@onready var robots_container: Node2D = %Robots
@onready var label_time: Label = $HSplitContainer/SystemContainer/VSplitContainer/PanelContainer2/TabContainer/Control/VBoxContainer/HBoxContainer/LHSTime

var brain_editor: BrainEditor
var program_data: Dictionary = {}

var robots: Array = []
var robot_id_counter: int = 0

var radio_messages_current: Array[Dictionary] = []
var radio_messages_next: Array[Dictionary] = []

var tick_timer: Timer

func _ready() -> void:
	popup_centered_ratio(0.9)
	
	get_tree().root.size_changed.connect(on_root_size_changed)
	
	program_data = brain_editor.get_program_data()
	program_visualizer.start(program_data)
	
	call_deferred("center_and_fit_map")
	
	map_view.map_generated.connect(on_map_view_map_generated)
	
	spawn_robot()
	
	tick_timer = Timer.new()
	tick_timer.wait_time = 0.5
	tick_timer.timeout.connect(on_tick_timer_timeout)
	
	add_child(tick_timer)

func spawn_robot() -> void:
	var spawn_pos = map_view.get_random_empty_spawn_point()
	
	if spawn_pos != Vector2i(-1, -1):
		var robot: Robot = robot_scene.instantiate()
		robots_container.add_child(robot)
		
		robot.setup(self, map_view, spawn_pos, program_data, robot_id_counter)
		robots.append(robot)
		
		robot_id_counter += 1

func center_and_fit_map() -> void:
	if not is_instance_valid(map_view) or not is_instance_valid(map_camera) or not is_instance_valid(sub_viewport):
		return
		
	var tile_size: Vector2i = map_view.tile_map.tile_set.tile_size
	var map_pixel_size = Vector2(map_view.MAP_SIZE.x * tile_size.x, map_view.MAP_SIZE.y * tile_size.y)
	var vp_size = Vector2(sub_viewport.size)
	
	map_camera.fit_to_bounds(map_pixel_size, vp_size)

func tick() -> void:
	process_radio_tick()
	
	for robot in robots:
		robot.tick()

func process_radio_tick() -> void:
	radio_messages_current = radio_messages_next.duplicate()
	radio_messages_next.clear()

func queue_radio_message(sender_id: int, slot: int, value: float, priority: int) -> void:
	if value <= 0.001: return
	
	radio_messages_next.append({
		"sender_id": sender_id,
		"slot": slot,
		"value": value,
		"priority": priority
	})

func get_radio_signals_for_robot(receiver_id: int) -> Array[float]:
	var results: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var best_priorities: Array[int] = [-1, -1, -1, -1]
	
	for msg in radio_messages_current:
		if msg.sender_id == receiver_id: continue
		
		var slot = msg.slot
		var prio = msg.priority
		var val = msg.value
		
		if prio > best_priorities[slot]:
			best_priorities[slot] = prio
			results[slot] = val
		elif prio == best_priorities[slot]:
			results[slot] = max(results[slot], val)
			
	return results

func on_close_requested() -> void:
	queue_free()

func on_root_size_changed():
	var new_root_size = get_tree().root.size
	self.max_size = new_root_size

func on_map_container_mouse_entered() -> void:
	map_tools.enable_info_label()

func on_map_container_mouse_exited() -> void:
	map_tools.disable_info_label()

func on_map_view_map_generated() -> void:
	for robot in robots:
		robot.queue_free()
	
	robots.clear()
	
	spawn_robot()

func on_tick_timer_timeout() -> void:
	tick()

func on_b_step_pressed() -> void:
	tick()

func on_b_start_pressed() -> void:
	tick_timer.start()

func on_b_stop_pressed() -> void:
	tick_timer.stop()

func on_hs_time_value_changed(value: float) -> void:
	tick_timer.wait_time = 1.0 / value
	label_time.text = "%s Hz" % str(int(value))

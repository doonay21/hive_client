class_name TestButton extends TextureRect

const program_simulator_scene: PackedScene = preload("res://scenes/program_simulator/program_simulator.tscn")

@export var brain_editor: BrainEditor

var fade_tween: Tween
var mouse_is_over: bool = false
var program_simulator_instance: ProgramSimulator

func on_mouse_entered() -> void:
	mouse_is_over = true
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	Events.info_text_requested.emit(tr("brain_editor.test.info"))

func on_mouse_exited() -> void:
	mouse_is_over = false
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(self, "modulate:a", 0.361, 0.3)
	
	Events.info_text_hide_requested.emit()

func on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and mouse_is_over:
		open_simulator()

func open_simulator() -> void:
	if is_instance_valid(program_simulator_instance): return
	
	program_simulator_instance = program_simulator_scene.instantiate()
	program_simulator_instance.brain_editor = brain_editor
	brain_editor.add_child(program_simulator_instance)

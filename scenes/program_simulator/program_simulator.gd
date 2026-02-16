class_name ProgramSimulator extends Window

var brain_editor: BrainEditor

func _ready() -> void:
	#var program_data: Dictionary = brain_editor.get_program_data()
	#print(program_data)
	
	popup_centered_ratio(0.9)
	
	get_tree().root.size_changed.connect(on_root_size_changed)

func on_close_requested() -> void:
	queue_free()

func on_root_size_changed():
	var new_root_size = get_tree().root.size
	
	self.max_size = new_root_size

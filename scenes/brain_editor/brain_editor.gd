class_name BrainEditor extends CanvasLayer

@onready var brain_grid: BrainGrid = %BrainGrid
@onready var new_block_dialog = $NewBlockDialog

func _ready() -> void:
	BrainManager.load_brain(self)

func on_button_save_pressed() -> void:
	BrainManager.save_brain(self)

func on_button_clear_pressed() -> void:
	brain_grid.clear()

func on_custom_blocks_add_new_block() -> void:
	new_block_dialog.popup_centered()

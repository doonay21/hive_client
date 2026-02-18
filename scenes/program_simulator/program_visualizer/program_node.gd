class_name ProgramNode extends Node2D

@onready var background: Sprite2D = $Background
@onready var icon: Sprite2D = $Background/Icon

var target_position: Vector2 = Vector2.ZERO

func set_node(data: Dictionary) -> void:
	print(data)
	background.self_modulate.a = 0.5
	#icon.texture = texture

func _process(_delta: float) -> void:
	position = position.lerp(target_position, 0.3)

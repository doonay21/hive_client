extends Control

@onready var label: Label = $ColorRect/CenterContainer/Label

func _ready() -> void:
	OnlineManager.connection_established.connect(on_nakama_connection_established)
	OnlineManager.connection_error.connect(on_nakama_connection_error)
	
	OnlineManager.establish_connection()

func on_nakama_connection_established(_user_id: String) -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func on_nakama_connection_error(error_message: String) -> void:
	label.text = error_message

extends CanvasLayer

const ALERT_SCENE = preload("res://scenes/alert_system/alert.tscn")

@onready var container = $ScreenPadding/AlertContainer

func show_alert(title: String, message: String, message_type: Alert.MessageType = Alert.MessageType.INFO):
	var new_alert = ALERT_SCENE.instantiate()
	container.add_child(new_alert)
	new_alert.setup(title, message, message_type)
	container.move_child(new_alert, 0)

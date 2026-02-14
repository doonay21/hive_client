class_name Alert extends MarginContainer

enum MessageType {
	INFO,
	SUCCESS,
	WARNING,
	ERROR
}

const BACKGROUND_COLORS: Dictionary = {
	MessageType.INFO: Color("2196F3"),
	MessageType.SUCCESS: Color("4CAF50"),
	MessageType.WARNING: Color("FF9800"),
	MessageType.ERROR: Color("F44336")
}

const TEXT_COLORS: Dictionary = {
	MessageType.INFO: Color("E3F2FD"),
	MessageType.SUCCESS: Color("E8F5E9"),
	MessageType.WARNING: Color("FFF3E0"),
	MessageType.ERROR: Color("FFEBEE")
}

const ICONS: Dictionary = {
	MessageType.INFO: preload("res://assets/images/icons/info.png"),
	MessageType.SUCCESS: preload("res://assets/images/icons/success.png"),
	MessageType.WARNING: preload("res://assets/images/icons/warning.png"),
	MessageType.ERROR: preload("res://assets/images/icons/error.png")
}

@onready var background: PanelContainer = $Background
@onready var title_label: Label = $Background/InnerPadding/ContentLayout/TextLayout/Title
@onready var message_label: Label = $Background/InnerPadding/ContentLayout/TextLayout/Message
@onready var icon_rect: TextureRect = $Background/InnerPadding/ContentLayout/Icon

var duration: float = 3.0

func setup(title: String, text: String, message_type: MessageType = MessageType.INFO) -> void:
	title_label.text = title
	message_label.text = text
	icon_rect.texture = ICONS[message_type]
	background.self_modulate = BACKGROUND_COLORS[message_type]
	title_label.self_modulate = TEXT_COLORS[message_type]
	message_label.self_modulate = TEXT_COLORS[message_type]

func _ready() -> void:
	modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	get_tree().create_timer(duration).timeout.connect(close_alert)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close_alert()

func close_alert() -> void:
	if is_queued_for_deletion(): return
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.finished.connect(queue_free)

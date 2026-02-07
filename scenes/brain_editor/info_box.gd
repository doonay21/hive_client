extends RichTextLabel

var fade_tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	hide()
	
	Events.info_text_requested.connect(on_show_info)
	Events.info_text_hide_requested.connect(on_hide_info)

func on_show_info(message: String) -> void:
	if message.is_empty():
		return
	
	text = message
	show()
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.3)

func on_hide_info() -> void:
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	fade_tween.tween_callback(func(): 
		hide()
		text = ""
	)

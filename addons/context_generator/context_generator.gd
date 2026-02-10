@tool
extends EditorPlugin

const MainPanel = preload("res://addons/context_generator/generator_view.gd")

var main_panel_instance

func _enter_tree():
	main_panel_instance = MainPanel.new()
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)

func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()

func _has_main_screen():
	return true

func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible

func _get_plugin_name():
	return "LLM Context"

func _get_plugin_icon():
	return EditorInterface.get_base_control().get_theme_icon("Script", "EditorIcons")

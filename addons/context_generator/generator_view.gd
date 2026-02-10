@tool
extends Control

var ignored_folders: PackedStringArray = ["addons", ".godot", "translations", ".git", ".import", "lfs", "assets"]
const PROMPT_SUFFIX = "\n\nPrzeanalizuj skrupulatnie powyższe pliki."

const EXT_TEXT = ["gd", "json"]
const EXT_SCENE = ["tscn"]

var tree: Tree
var info_label: Label
var refresh_btn: Button
var copy_btn: Button
var token_regex: RegEx

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var margin_container = MarginContainer.new()
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	add_child(margin_container)

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_container.add_child(main_vbox)
	
	var header = HBoxContainer.new()
	main_vbox.add_child(header)
	
	refresh_btn = Button.new()
	refresh_btn.text = " 🔄 Odśwież "
	refresh_btn.pressed.connect(_on_refresh_pressed)
	header.add_child(refresh_btn)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	copy_btn = Button.new()
	copy_btn.text = " 📋 Generuj PROMPT "
	copy_btn.add_theme_color_override("font_color", get_theme_color("success_color", "Editor"))
	copy_btn.pressed.connect(_on_copy_pressed)
	header.add_child(copy_btn)
	
	info_label = Label.new()
	info_label.text = "Zaznacz pliki do analizy."
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_vbox.add_child(info_label)
	
	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.hide_root = true
	tree.columns = 1
	tree.set_column_expand(0, true)
	tree.item_edited.connect(_on_item_edited)
	main_vbox.add_child(tree)
	
	_populate_tree()
	
	token_regex = RegEx.new()
	token_regex.compile("\\w+|[^\\w\\s]")

func _estimate_tokens(text: String) -> int:
	if text.is_empty():
		return 0
		
	if text.length() > 500000:
		return int(text.length() / 3.5)
		
	var matches = token_regex.search_all(text)
	return matches.size()

func _on_refresh_pressed():
	_populate_tree()
	info_label.text = "Lista plików odświeżona."

func _populate_tree():
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "res://")
	_scan_dir_recursive("res://", root)

func _scan_dir_recursive(path: String, parent_item: TreeItem):
	var dir = DirAccess.open(path)
	if not dir: return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	var folders_list = []
	var files_list = []
	
	while file_name != "":
		if not file_name.begins_with("."):
			if dir.current_is_dir():
				if not file_name in ignored_folders:
					folders_list.append(file_name)
			else:
				var ext = file_name.get_extension()
				if ext in EXT_TEXT or ext in EXT_SCENE:
					files_list.append(file_name)
		file_name = dir.get_next()
	
	folders_list.sort()
	files_list.sort()
	
	var icon_folder = EditorInterface.get_editor_theme().get_icon("Folder", "EditorIcons")
	var icon_script = EditorInterface.get_editor_theme().get_icon("Script", "EditorIcons")
	var icon_scene = EditorInterface.get_editor_theme().get_icon("PackedScene", "EditorIcons")
	var icon_text = EditorInterface.get_editor_theme().get_icon("TextFile", "EditorIcons")

	for folder in folders_list:
		_create_item(parent_item, folder, path.path_join(folder), true, icon_folder)

	for file in files_list:
		var ext = file.get_extension()
		var icon = icon_text
		
		if ext == "gd":
			icon = icon_script
		elif ext == "tscn":
			icon = icon_scene
			
		_create_item(parent_item, file, path.path_join(file), false, icon)

func _create_item(parent: TreeItem, text: String, full_path: String, is_folder: bool, icon: Texture2D):
	var item = tree.create_item(parent)
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	item.set_editable(0, true)
	item.set_text(0, text)
	item.set_metadata(0, full_path)
	item.set_icon(0, icon)
	item.set_checked(0, false)
	
	if is_folder:
		item.set_collapsed(true)
		_scan_dir_recursive(full_path, item)

func _on_item_edited():
	var item = tree.get_selected()
	if item:
		var is_checked = item.is_checked(0)
		_set_checks_recursive(item, is_checked)

func _set_checks_recursive(item: TreeItem, checked: bool):
	item.set_checked(0, checked)
	for child in item.get_children():
		_set_checks_recursive(child, checked)

func _on_copy_pressed():
	info_label.text = "Generowanie..."
	await get_tree().process_frame
	
	var autoloads = _get_autoload_settings()
	var engine_version = Engine.get_version_info()
	var version_str = "Godot %s.%s.%s" % [engine_version.major, engine_version.minor, engine_version.patch]
	
	var results: Array[String] = ["%s:" % version_str]
	
	var root = tree.get_root()
	var selected_files: PackedStringArray = []
	_collect_checked_files(root, selected_files)
	
	if selected_files.is_empty():
		info_label.text = "⚠️ Nie zaznaczono żadnych plików!"
		return

	for file_path in selected_files:
		var ext = file_path.get_extension()
		
		if ext in EXT_TEXT:
			_process_script(file_path, autoloads, results)
		elif ext in EXT_SCENE:
			_process_scene_safe(file_path, results)
			
	var final_string = "\n\n".join(results) + PROMPT_SUFFIX
	var token_count = _estimate_tokens(final_string)
	var char_count = final_string.length()
	
	DisplayServer.clipboard_set(final_string)
	var token_str = String.num_int64(token_count) 
	
	var info_color = Color(0.6, 1.0, 0.6)
	if token_count > 32000: info_color = Color(1.0, 0.8, 0.4)
	if token_count > 120000: info_color = Color(1.0, 0.4, 0.4)
	
	info_label.add_theme_color_override("font_color", info_color)
	info_label.text = "✅ Skopiowano! ~%s tokenów (%d znaków)." % [token_str, char_count]

func _collect_checked_files(item: TreeItem, list: PackedStringArray):
	for child in item.get_children():
		if child.is_checked(0):
			var path = child.get_metadata(0)
			var ext = path.get_extension()
			if ext in EXT_TEXT or ext in EXT_SCENE:
				list.append(path)
		_collect_checked_files(child, list)

func _process_script(path: String, autoloads: Dictionary, results: Array[String]):
	var info = path
	if path in autoloads:
		info += " (Autoload: %s)" % autoloads[path]
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var block = []
		block.append("--- Plik: %s" % info)
		block.append(content)
		block.append("--- Koniec pliku: %s" % path)
		results.append("\n".join(block))

func _process_scene_safe(path: String, results: Array[String]):
	var scene = load(path)
	if not scene or not (scene is PackedScene):
		return

	var instance = scene.instantiate()
	if not instance:
		return

	var tree_lines: Array[String] = []
	
	_scan_node_recursive(instance, 0, tree_lines)
	
	instance.queue_free()
	
	var block = []
	block.append('--- Plik: "%s"' % path)       # Tutaj używamy ścieżki
	block.append("\n".join(tree_lines))         # Tutaj wstawiamy zawartość drzewa
	block.append("--- Koniec pliku: %s" % path) # Spójne zakończenie
	results.append("\n".join(block))

func _scan_node_recursive(node: Node, depth: int, lines: Array[String]):
	var indent = "\t".repeat(depth)
	var node_type = node.get_class()
	
	var line = "%s- %s (%s)" % [indent, node.name, node_type]
	
	var script_res = node.get_script()
	if script_res:
		line += " [skrypt: %s]" % script_res.resource_path.get_file()
	
	if node.scene_file_path and depth > 0:
		if node.scene_file_path != node.owner.scene_file_path if node.owner else true:
			line += " [instancja: %s]" % node.scene_file_path.get_file()

	lines.append(line)

	for child in node.get_children():
		_scan_node_recursive(child, depth + 1, lines)

func _get_autoload_settings() -> Dictionary:
	var autoload_map = {}
	var props = ProjectSettings.get_property_list()
	for prop in props:
		if prop.name.begins_with("autoload/"):
			var path = ProjectSettings.get_setting(prop.name)
			path = path.trim_prefix("*")
			autoload_map[path] = true
	return autoload_map

class_name YAMLLoader extends Node

const DEFAULT_TRANSLATION_PATH = "res://translations/"

func _ready() -> void:
	load_all_translations()

func load_all_translations(scan_path: String = DEFAULT_TRANSLATION_PATH) -> void:
	var dir = DirAccess.open(scan_path)
	
	if not dir:
		printerr("YAMLLoader: Nie można otworzyć katalogu: ", scan_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
			
		var full_path = scan_path.path_join(file_name)

		if dir.current_is_dir():
			if not file_name.begins_with("."): 
				load_all_translations(full_path)
		else:
			if (file_name.ends_with(".yml") or file_name.ends_with(".yaml")) and not file_name.ends_with(".import"):
				process_translation_file(scan_path, file_name)
		
		file_name = dir.get_next()

func process_translation_file(dir_path: String, file_name: String) -> void:
	var locale = extract_locale(file_name)
	
	if locale.is_empty():
		push_warning("YAMLLoader: Pominięto '%s'. Nie wykryto kodu języka." % file_name) 
		return

	var full_path = dir_path.path_join(file_name)
	register_yaml_translation(full_path, locale)

func extract_locale(file_name: String) -> String:
	var base = file_name.get_basename()
	var extension = base.get_extension()
	
	if not extension.is_empty():
		return extension
		
	if base.length() == 2 or base.length() == 5:
		return base
		
	return ""

func register_yaml_translation(path: String, locale: String) -> void:
	var data: Dictionary = YAMLParser.load_translations(path)
	
	if data.is_empty():
		return

	var translation_res = Translation.new()
	translation_res.locale = locale
	
	for key in data:
		translation_res.add_message(key, str(data[key]))
		
	TranslationServer.add_translation(translation_res)

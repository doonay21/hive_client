class_name YAMLParser extends RefCounted

static func load_translations(path: String) -> Dictionary:
	var result: Dictionary = {}
	
	if not FileAccess.file_exists(path):
		printerr("YAMLParser: File not found: ", path)
		return result

	var file = FileAccess.open(path, FileAccess.READ)
	var key_stack: Array[String] = []
	var indent_stack: Array[int] = [] 
	
	while file.get_position() < file.get_length():
		var raw_line = file.get_line()
		
		if raw_line.strip_edges().is_empty() or raw_line.strip_edges().begins_with("#"):
			continue
			
		var current_indent = _calculate_indent(raw_line)
		var clean_line = raw_line.strip_edges()
		
		while not indent_stack.is_empty() and current_indent <= indent_stack.back():
			indent_stack.pop_back()
			key_stack.pop_back()
			
		var parts = clean_line.split(":", true, 1)
		var key = parts[0].strip_edges()
		var value_str = ""
		
		if parts.size() > 1:
			value_str = parts[1].strip_edges()
			
		var final_value = _parse_value(value_str)
		
		if final_value == null:
			key_stack.push_back(key)
			indent_stack.push_back(current_indent)
		else:
			var full_key = key
			if not key_stack.is_empty():
				full_key = ".".join(key_stack) + "." + key
			
			result[full_key] = final_value
			
	return result

static func _calculate_indent(line: String) -> int:
	var expanded_line = line.replace("\t", "    ")
	return expanded_line.length() - expanded_line.strip_edges(true, false).length()

static func _parse_value(val: String) -> Variant:
	if val.is_empty():
		return null
	
	if val.begins_with('"') and val.ends_with('"'):
		return val.substr(1, val.length() - 2).c_unescape()
	
	if val.begins_with("'") and val.ends_with("'"):
		return val.substr(1, val.length() - 2)
		
	return val

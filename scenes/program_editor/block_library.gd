class_name BlockLibrary extends Node

static var op_cache: Dictionary = {}
static var initialized: bool = false

const BLOCKS_PATH = "res://scenes/program_editor/blocks/"

static func get_data_for_op(op: BlockData.Op) -> BlockData:
	if not initialized:
		initialize()
	
	return op_cache.get(op, null)

static func initialize() -> void:
	scan_recursive(BLOCKS_PATH)
	initialized = true

static func scan_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				scan_recursive(path.path_join(file_name))
			else:
				try_load_resource(path, file_name)
			
			file_name = dir.get_next()
	else:
		push_warning("BlockLibrary: Nie można otworzyć ścieżki: " + path)

static func try_load_resource(path: String, file_name: String) -> void:
	var clean_name = file_name.trim_suffix(".remap")
	
	if clean_name.ends_with(".tres") or clean_name.ends_with(".res"):
		var full_path = path.path_join(clean_name)
		
		if ResourceLoader.exists(full_path):
			var resource = load(full_path)
			if resource is BlockData:
				if resource.op != BlockData.Op.NONE:
					op_cache[resource.op] = resource
				else:
					pass

static func get_custom_block_data(uuid: String) -> BlockData:
	var model = BlockModel.where("uuid", uuid)
	if not model:
		return null
		
	var data = CustomBlockData.new(model.name, model.ports, model.description)
	return data

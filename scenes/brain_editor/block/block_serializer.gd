class_name BlockSerializer extends RefCounted

const BLOCK_RESOURCE_PREFIX = "res://scenes/brain_editor/blocks/"

static func parse_save_to_program_data(save_data: Dictionary) -> Dictionary:
	var program_data: Dictionary = {}
	var rot_index = 0
	
	if "rotation_index" in save_data:
		rot_index = save_data["rotation_index"]

	program_data["map"] = calculate_rotation_map(rot_index)

	if "stored_value" in save_data:
		program_data["val"] = save_data["stored_value"]

	if "custom_block_uuid" in save_data and not save_data["custom_block_uuid"].is_empty():
		program_data["op"] = BlockData.Op.CUSTOM
		program_data["uuid"] = save_data["custom_block_uuid"]
		return program_data

	if "resource" in save_data and not save_data["resource"].is_empty():
		var resource_path = BLOCK_RESOURCE_PREFIX.path_join(save_data["resource"])
		
		if ResourceLoader.exists(resource_path):
			var block_res = load(resource_path)
			if block_res is BlockData:
				program_data["op"] = block_res.op
	
	if not "op" in program_data:
		return {}

	return program_data

static func calculate_rotation_map(rot_idx: int) -> Array:
	var map: Array = [0, 0, 0, 0]
	for physical_side in range(4):
		var logical_index = (physical_side - rot_idx + 4) % 4
		map[physical_side] = logical_index
	return map

static func get_save_data(block: Block) -> Dictionary:
	var save_data: Dictionary = {
		"resource": "",
		"rotation_index": block.rotation_index,
		"custom_block_uuid": block.custom_block_uuid
	}
	
	if block.block_data and block.custom_block_uuid.is_empty() and not block.block_data.resource_path.is_empty():
		save_data["resource"] = block.block_data.resource_path.trim_prefix(BLOCK_RESOURCE_PREFIX)
	
	if block.value_drag and block.value_drag.visible and "value" in block.value_drag:
		save_data["stored_value"] = block.value_drag.value
	
	return save_data

static func get_program_data(block: Block) -> Dictionary:
	var save_data = get_save_data(block)
	var data = parse_save_to_program_data(save_data)
	
	if block.block_data:
		data["op"] = block.block_data.op
		if block.block_data is CustomBlockData:
			data["uuid"] = block.custom_block_uuid

	return data

static func load_save_data(block: Block, saved_data: Dictionary) -> void:
	if "custom_block_uuid" in saved_data and not saved_data["custom_block_uuid"].is_empty():
		block.custom_block_uuid = saved_data["custom_block_uuid"]
		
		var block_model = BlockModel.where("uuid", block.custom_block_uuid)
		
		if block_model:
			block.block_data = CustomBlockData.new(
				block_model.name,
				block_model.ports,
				block_model.description
			)
		else:
			BlockVisuals.create_missing_block_visuals(block)
			
	elif "resource" in saved_data and not saved_data["resource"].is_empty():
		var resource_path = BLOCK_RESOURCE_PREFIX.path_join(saved_data["resource"])
		
		if ResourceLoader.exists(resource_path):
			block.block_data = load(resource_path)

	if "rotation_index" in saved_data:
		block.rotation_index = saved_data["rotation_index"]

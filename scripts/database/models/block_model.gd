class_name BlockModel extends BaseModel

const TABLE = "blocks"

var uuid: String = UUID.v4()
var name: String = ""
var description: String = ""
var size: ProgramGrid.MatrixSize = ProgramGrid.MatrixSize._7x7
var grid: Array = []
var ports: Array = [BlockData.Port.NONE, BlockData.Port.NONE, BlockData.Port.NONE, BlockData.Port.NONE]

func _init(data: Dictionary = {}):
	if not data.is_empty():
		from_dict(data)

func get_table_name() -> String:
	return TABLE

func to_dict() -> Dictionary:
	return {
		"uuid": uuid,
		"name": name,
		"description": description,
		"size": size,
		"grid": var_to_bytes(grid),
		"ports": var_to_bytes(ports)
	}

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	uuid = data.get("uuid", UUID.v4())
	name = data.get("name", tr("BE_DEFAULT_PROGRAM_NAME"))
	description = data.get("description", tr("BE_DEFAULT_PROGRAM_DESCRIPTION"))
	size = data.get("size", ProgramGrid.MatrixSize._7x7)
	
	var raw_blob = data.get("grid")
	
	if raw_blob is PackedByteArray:
		grid = bytes_to_var(raw_blob)
	else:
		grid = []
	
	var raw_ports = data.get("ports")
	if raw_ports is PackedByteArray:
		ports = bytes_to_var(raw_ports)
	else:
		ports = [BlockData.Port.NONE, BlockData.Port.NONE, BlockData.Port.NONE, BlockData.Port.NONE]

static func get_by_id(target_id: int) -> BlockModel:
	var data = BaseModel.fetch_one_by_id(TABLE, target_id)
	if data:
		return BlockModel.new(data)
	return null

static func where(column: String, value: Variant) -> BlockModel:
	var data = BaseModel.fetch_one_where(TABLE, column, value)
	if data:
		return BlockModel.new(data)
	return null

static func exists(arg1: Variant, arg2: Variant = null) -> bool:
	if arg2 == null and arg1 is int:
		return BaseModel.sql_exists(TABLE, "id", arg1)
	elif arg1 is String:
		return BaseModel.sql_exists(TABLE, arg1, arg2)
		
	assert(false, "BlockModel.exists: Nieprawidłowe argumenty")
	
	return false

static func all() -> Array[BlockModel]:
	var raw_data = BaseModel.fetch_all(TABLE)
	var result: Array[BlockModel] = []
	
	for row in raw_data:
		result.append(BlockModel.new(row))
		
	return result

static func delete_by_id(target_id: int) -> void:
	BaseModel.delete_by_id_helper(TABLE, target_id)

static func get_schema() -> Dictionary:
	return {
		"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
		"uuid": { "data_type": "text", "not_null": true, "unique": true },
		"name": { "data_type": "text", "not_null": true, "unique": true },
		"description": { "data_type": "text" },
		"size": { "data_type": "int", "not_null": true },
		"grid": { "data_type": "blob" },
		"ports": { "data_type": "blob" }
	}

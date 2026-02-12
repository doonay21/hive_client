class_name BlockModel extends BaseModel

const TABLE = "blocks"

var uuid: String = UUID.v4()
var name: String = ""
var size: ProgramGrid.MatrixSize = ProgramGrid.MatrixSize._7x7
var grid: Dictionary = {}

func _init(data: Dictionary = {}):
	if not data.is_empty():
		from_dict(data)

func get_table_name() -> String:
	return TABLE

func to_dict() -> Dictionary:
	return {
		"uuid": uuid,
		"name": name,
		"size": size,
		"grid": var_to_bytes(grid)
	}

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	uuid = data.get("uuid", UUID.v4())
	name = data.get("name", tr("BE_DEFAULT_PRORGAM_NAME"))
	size = data.get("size", ProgramGrid.MatrixSize._7x7)
	
	var raw_blob = data.get("grid")
	
	if raw_blob is PackedByteArray:
		grid = bytes_to_var(raw_blob)
	else:
		grid = {}

static func get_by_id(target_id: int) -> ProgramModel:
	var data = BaseModel.fetch_one_by_id(TABLE, target_id)
	if data:
		return ProgramModel.new(data)
	return null

static func where(column: String, value: Variant) -> ProgramModel:
	var data = BaseModel.fetch_one_where(TABLE, column, value)
	if data:
		return ProgramModel.new(data)
	return null

static func all() -> Array[ProgramModel]:
	var raw_data = BaseModel.fetch_all(TABLE)
	var result: Array[ProgramModel] = []
	
	for row in raw_data:
		result.append(ProgramModel.new(row))
		
	return result

static func delete_by_id(target_id: int) -> void:
	BaseModel.delete_by_id_helper(TABLE, target_id)

static func get_schema() -> Dictionary:
	return {
		"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
		"uuid": { "data_type": "text", "not_null": true, "unique": true },
		"name": { "data_type": "text", "not_null": true, "unique": true },
		"size": { "data_type": "int", "not_null": true },
		"grid": { "data_type": "blob" }
	}

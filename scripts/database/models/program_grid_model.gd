class_name ProgramGridModel extends BaseModel

const TABLE = "program_grids"

var program_id: int = -1
var name: String = ""
var size: ProgramGrid.MatrixSize = ProgramGrid.MatrixSize._7x7
var is_block: bool = false
var blocks: Array = []

func _init(data: Dictionary = {}):
	if not data.is_empty():
		from_dict(data)

func get_table_name() -> String:
	return TABLE

func to_dict() -> Dictionary:
	return {
		"program_id": program_id,
		"name": name,
		"size": size,
		"is_block": is_block,
		"blocks": JSON.stringify(blocks)
	}

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	
	program_id = int(data.get("program_id", -1))
	name = data.get("name", tr("BE_MAIN_BRAIN_GRID"))
	size = data.get("size", ProgramGrid.MatrixSize._7x7)
	is_block = bool(data.get("is_block", false))
	
	var raw_blocks = data.get("blocks", "")
	
	if raw_blocks is String and raw_blocks != "":
		blocks = JSON.parse_string(raw_blocks)
	else:
		blocks = []

static func get_by_id(target_id: int) -> ProgramGridModel:
	var data = BaseModel.fetch_one_by_id(TABLE, target_id)
	if data:
		return ProgramGridModel.new(data)
	return null

static func where(column: String, value: Variant) -> ProgramGridModel:
	var data = BaseModel.fetch_one_where(TABLE, column, value)
	if data:
		return ProgramGridModel.new(data)
	return null

static func all() -> Array[ProgramGridModel]:
	var raw_data = BaseModel.fetch_all(TABLE)
	var result: Array[ProgramGridModel] = []
	
	for row in raw_data:
		result.append(ProgramGridModel.new(row))
		
	return result

static func delete_by_id(target_id: int) -> void:
	BaseModel.delete_by_id_helper(TABLE, target_id)

static func get_all_by_program_id(p_id: int) -> Array[ProgramGridModel]:
	var db = DatabaseManager.db
	db.query_with_bindings("SELECT * FROM " + TABLE + " WHERE program_id = ? ORDER BY id", [p_id])
	var result: Array[ProgramGridModel] = []
	for row in db.query_result:
		result.append(ProgramGridModel.new(row))
	return result

static func get_schema() -> Dictionary:
	return {
		"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
		"program_id": { "data_type": "int", "not_null": true },
		"name": { "data_type": "text", "not_null": true },
		"size": { "data_type": "int", "not_null": true, "default": ProgramGrid.MatrixSize._7x7 },
		"is_block": { "data_type": "bool", "not_null": true, "default": false },
		"blocks": { "data_type": "text" }
	}

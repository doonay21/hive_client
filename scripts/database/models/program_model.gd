class_name ProgramModel extends BaseModel

const TABLE = "programs"

var name: String = ""

func _init(data: Dictionary = {}):
	if not data.is_empty():
		from_dict(data)

func get_table_name() -> String:
	return TABLE

func to_dict() -> Dictionary:
	return { "name": name }

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	name = data.get("name", "Unknown")

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

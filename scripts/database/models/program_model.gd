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
	name = data.get("name", tr("BE_DEFAULT_PRORGAM_NAME"))

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

static func create_with_default_grid(program_name: String) -> ProgramModel:
	var db = DatabaseManager.db
	db.query("BEGIN TRANSACTION")
	
	var new_program = ProgramModel.new()
	new_program.name = program_name
	
	if not new_program.save():
		db.query("ROLLBACK")
		push_error("Nie udało się zapisać programu: " + program_name)
		return null
	
	var default_grid = ProgramGridModel.new()
	default_grid.program_id = new_program.id
	default_grid.name = TranslationServer.translate("BE_MAIN_BRAIN_GRID")
	default_grid.size = ProgramGrid.MatrixSize._7x7 
	default_grid.is_block = false
	
	var blocks: Array = []
	blocks.resize(ProgramGrid.matrix_size_total(default_grid.size))
	
	for i in range(blocks.size()):
		blocks[i] = {}
	
	default_grid.blocks = blocks
	
	if not default_grid.save():
		db.query("ROLLBACK")
		push_error("Nie udało się zapisać domyślnego grida dla programu ID: " + str(new_program.id))
		return null
	
	db.query("COMMIT")
	
	return new_program

static func delete_by_id(target_id: int) -> void:
	BaseModel.delete_by_id_helper(TABLE, target_id)

static func get_schema() -> Dictionary:
	return {
		"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
		"name": { "data_type": "text", "not_null": true, "unique": true }
	}

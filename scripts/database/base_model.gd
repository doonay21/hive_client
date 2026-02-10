class_name BaseModel extends RefCounted

var id: int = -1

func get_table_name() -> String:
	push_error("BaseModel: _get_table_name() not implemented")
	return ""

func to_dict() -> Dictionary:
	push_error("BaseModel: _to_dict() not implemented")
	return {}

func from_dict(data: Dictionary) -> void:
	id = data.get("id", -1)

func save() -> bool:
	var db = DatabaseManager.db
	var table = get_table_name()
	var data = to_dict()
	
	if id == -1:
		data.erase("id") 
		var success = db.insert_row(table, data)
		if success:
			id = db.last_insert_rowid
		return success
	else:
		data.erase("id") 
		var condition = "id = " + str(id)
		return db.update_rows(table, condition, data)

func delete() -> void:
	if id != -1:
		BaseModel.delete_by_id_helper(get_table_name(), id)
		id = -1

static func delete_by_id_helper(table_name: String, target_id: int) -> void:
	var db = DatabaseManager.db
	var query = "DELETE FROM " + table_name + " WHERE id = ?"
	db.query_with_bindings(query, [target_id])

static func fetch_one_by_id(table_name: String, target_id: int):
	var db = DatabaseManager.db
	var query = "SELECT * FROM " + table_name + " WHERE id = ?"
	db.query_with_bindings(query, [target_id])
	
	if db.query_result.is_empty():
		return null
	return db.query_result[0]

static func fetch_one_where(table_name: String, column: String, value: Variant):
	var db = DatabaseManager.db
	var query = "SELECT * FROM " + table_name + " WHERE " + column + " = ?"
	db.query_with_bindings(query, [value])
	
	if db.query_result.is_empty():
		return null
	return db.query_result[0]

static func fetch_all(table_name: String) -> Array:
	var db = DatabaseManager.db
	db.query("SELECT * FROM " + table_name)
	return db.query_result

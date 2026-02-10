extends Node

var db: SQLite = SQLite.new()
const DB_NAME = "user://data.db"

func _ready():
	db.path = DB_NAME
	db.verbosity_level = SQLite.VERBOSE
	db.open_db()
	
	create_tables()

func create_tables():
	var programs = {
		"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
		"name": { "data_type": "text", "not_null": true, "unique": true }
	}
	
	db.create_table("programs", programs)

	var program_grids = {
		"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
		"program_id": { "data_type": "int", "not_null": true },
		"name": { "data_type": "text", "not_null": true },
		"size": { "data_type": "int", "not_null": true, "default": ProgramGrid.MatrixSize._7x7 },
		"is_block": { "data_type": "bool", "not_null": true, "default": false },
		"blocks": { "data_type": "text" }
	}
	
	db.create_table("program_grids", program_grids)

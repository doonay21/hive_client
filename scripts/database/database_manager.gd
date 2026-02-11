extends Node

var db: SQLite = SQLite.new()
const DB_PATH = "user://data.db"

var registered_models: Array = [
	ProgramModel,
	ProgramGridModel
]

func _ready():
	db.path = DB_PATH
	db.verbosity_level = SQLite.VERBOSE
	db.open_db()
	
	create_tables()

func create_tables():
	for model_class in registered_models:
		if "TABLE" in model_class:
			var table_name = model_class.TABLE
			var schema = model_class.get_schema()
			
			if not schema.is_empty():
				db.create_table(table_name, schema)
			else:
				assert(false, "DatabaseManager: Model dla tabeli '%s' ma pusty schemat." % table_name)
		else:
			assert(false, "DatabaseManager: Zarejestrowana klasa modelu nie posiada stałej TABLE.")

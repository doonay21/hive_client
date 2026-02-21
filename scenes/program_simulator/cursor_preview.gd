class_name CursorPreview extends Node2D

var brush_steps: int = 1
var active: bool = false
var map_view: MapView # Przekazywane przez MapTools w _ready()

func _process(_delta: float) -> void:
	if not active or not is_instance_valid(map_view): return
	
	var tile_map = map_view.tile_map
	var mouse_pos = get_global_mouse_position()
	
	# Obliczamy, nad którym kafelkiem znajduje się mysz
	var local_pos = tile_map.to_local(mouse_pos)
	var map_pos = tile_map.local_to_map(local_pos)
	
	# W Godot 4 map_to_local zwraca idealny środek kafelka w przestrzeni lokalnej.
	# Ustawiamy pozycję globalną kursora dokładnie na środku tego kafelka.
	global_position = tile_map.to_global(tile_map.map_to_local(map_pos))

func toggle(toggled_on: bool) -> void:
	active = toggled_on
	queue_redraw()

func set_size(size: int) -> void:
	brush_steps = clamp(size, 1, 10)
	queue_redraw()

func _draw() -> void:
	if not active or not is_instance_valid(map_view): return
	
	var tile_size = map_view.tile_map.tile_set.tile_size
	var radius_sq: float = (brush_steps - 0.5) ** 2
	
	# Skoro global_position węzła to środek kafelka, 
	# prostokąty rysujemy z przesunięciem o połowę rozmiaru w lewo i w górę.
	var offset = -Vector2(tile_size) / 2.0
	
	for x in range(-brush_steps, brush_steps + 1):
		for y in range(-brush_steps, brush_steps + 1):
			if (x * x + y * y) <= radius_sq:
				# Rozstawiamy kafelki kursora uwzględniając ich prawdziwy rozmiar
				var rect_pos = Vector2(x, y) * Vector2(tile_size) + offset
				var rect = Rect2(rect_pos, Vector2(tile_size))
				
				draw_rect(rect, Color(1.0, 1.0, 1.0, 0.6))

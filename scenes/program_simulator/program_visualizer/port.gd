extends Line2D

@onready var area: Area2D = $Area2D
@onready var area_shape: CollisionShape2D = $Area2D/CollisionShape2D

func _ready() -> void:
	area.mouse_entered.connect(on_area_mouse_entered)
	area.mouse_exited.connect(on_area_mouse_exited)

func set_line(a: Vector2, b: Vector2) -> void:
	points[0] = a
	points[1] = b
	
	update_collision_shape(a, b)

func update_collision_shape(a: Vector2, b: Vector2) -> void:
	var length = a.distance_to(b)
	var thickness = width + 4.0 
	
	area_shape.shape.size = Vector2(length, thickness)
	area_shape.position = (a + b) / 2.0
	area_shape.rotation = a.angle_to_point(b)

func set_alpha(alpha: float) -> void:
	material.set_shader_parameter("alpha", alpha)

func on_area_mouse_entered() -> void:
	print(1)

func on_area_mouse_exited() -> void:
	print(0)

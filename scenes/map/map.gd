extends TextureRect

const MAP_SIZE: Vector2i = Vector2i(200, 200)

var image: Image
var texture_ref: ImageTexture

var texture_dirty: bool = false

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	focus_mode = Control.FOCUS_CLICK
	
	image = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGBA8)
	texture_ref = ImageTexture.create_from_image(image)
	texture = texture_ref
	
	generate_world()

func _process(_delta: float) -> void:
	if texture_dirty:
		texture_ref.set_image(image)
		texture_dirty = false

func generate_world() -> void:
	for x in range(MAP_SIZE.x):
		for y in range(MAP_SIZE.y):
			image.set_pixel(x, y, Color.WHITE)
	
	texture_dirty = true

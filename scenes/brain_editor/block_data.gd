class_name BlockData extends Resource

enum ArrowStyle {
	Hidden,
	In,
	Out
}

@export_group("Display")
@export var display_name: String = "Block"
@export var icon: Texture2D
@export var base_color: Color = Color.WHITE

@export_group("Arrows")
@export var arrow_top: ArrowStyle = ArrowStyle.Hidden
@export var arrow_right: ArrowStyle = ArrowStyle.Hidden
@export var arrow_bottom: ArrowStyle = ArrowStyle.Hidden
@export var arrow_left: ArrowStyle = ArrowStyle.Hidden

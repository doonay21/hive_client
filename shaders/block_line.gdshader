shader_type canvas_item;

uniform vec4 inner_color : source_color = vec4(1.0, 0.8, 0.0, 1.0);
uniform vec4 outer_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float split : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	float mask = step(split, UV.y);
	
	COLOR = mix(inner_color, outer_color, mask);
}
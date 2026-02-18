shader_type canvas_item;

uniform float speed = 1.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 new_uv = UV;
    
    new_uv.x -= TIME * speed;
    
    vec4 tex_color = texture(TEXTURE, new_uv);
    tex_color.a *= alpha;
    
    COLOR = tex_color;
}
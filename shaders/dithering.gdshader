shader_type canvas_item;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float dither = (rand(UV + TIME) - 0.5) * (1.0 / 128.0);
    COLOR = col + dither;
}
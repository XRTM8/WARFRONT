shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.55;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.38;
uniform vec4 vignette_color : source_color = vec4(0.04, 0.05, 0.03, 1.0);

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 coord = (uv - 0.5) * 2.0;
    float dist = dot(coord, coord);
    float vig = smoothstep(0.4, 1.35, dist * vignette_intensity);
    COLOR = vec4(vignette_color.rgb, vig * vignette_opacity);
}

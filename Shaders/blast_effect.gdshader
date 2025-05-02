shader_type canvas_item;

uniform float radius = 600.0;
uniform float thickness = 0.35;
uniform float progress = 0.0;
uniform float distortion_strength = 0.05;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    vec2 screen_uv = SCREEN_UV;
    vec4 screen_color = texture(screen_texture, screen_uv);

    vec2 uv_center = vec2(0.5);
    float dist = distance(UV, uv_center);

	float ring_thickness = radius * thickness * (1.1 - progress);
    vec2 resolution = vec2(textureSize(screen_texture, 0));
    float outer = radius / resolution.x * progress;
    float inner = outer - ring_thickness / resolution.x;

    float ring_outer = smoothstep(outer, outer - 0.005, dist);
    float ring_inner = smoothstep(inner, inner + 0.05, dist);
    float ring = ring_outer * ring_inner;

    vec2 offset = normalize(UV - uv_center) * distortion_strength * ring;
    vec4 distorted_color = texture(screen_texture, screen_uv + offset);

    // Apply chromatic aberration by offsetting R, G, B channels differently
    vec2 chroma_offset = offset * 0.75; // scale strength for R/G/B separation
    float r = texture(screen_texture, screen_uv + chroma_offset * 1.2).r;
    float g = texture(screen_texture, screen_uv + chroma_offset * 0.8).g;
    float b = texture(screen_texture, screen_uv).b;
    distorted_color.rgb = vec3(r, g, b);

    COLOR = mix(screen_color, distorted_color, ring);
	// COLOR.rgb = vec3(ring);
}
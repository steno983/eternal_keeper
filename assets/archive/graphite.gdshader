shader_type canvas_item;
render_mode unshaded;

// Scenery only: generated source hues can never leak into the paper stage.
void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float luminance = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	float tone = pow(clamp((luminance - 0.08) / 0.86, 0.0, 1.0), 0.78);
	vec3 paper = vec3(0.9451, 0.9137, 0.8431);
	vec3 graphite = vec3(0.16);
	COLOR = vec4(mix(graphite, paper, tone), source.a);
}

shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(0.25, 0.95, 0.48, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.78;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 shaded_tint = tint_color.rgb * (0.58 + luminance * 0.62);
	vec3 final_color = mix(source.rgb, shaded_tint, tint_strength);
	COLOR = vec4(final_color, source.a);
}
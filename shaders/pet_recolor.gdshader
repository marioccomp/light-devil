shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(0.4, 0.8, 1.0, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float alpha = tex.a;
	float max_c = max(max(tex.r, tex.g), tex.b);
	float min_c = min(min(tex.r, tex.g), tex.b);
	float saturation = max_c - min_c;
	float luminance = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

	float tint_mask = smoothstep(0.08, 0.35, saturation) * smoothstep(0.05, 0.25, luminance);
	vec3 recolored = target_color.rgb * max_c;
	vec3 tinted_rgb = mix(tex.rgb, recolored, tint_strength * tint_mask);

	float preserve_highlights = smoothstep(0.72, 0.95, luminance) * (1.0 - smoothstep(0.02, 0.14, saturation));
	float preserve_shadows = 1.0 - smoothstep(0.05, 0.16, luminance);
	float preserve_mask = max(preserve_highlights, preserve_shadows);
	vec3 final_rgb = mix(tinted_rgb, tex.rgb, preserve_mask);

	COLOR = vec4(final_rgb, alpha);
}

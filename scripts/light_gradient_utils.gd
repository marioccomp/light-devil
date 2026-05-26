class_name LightGradientUtils
extends RefCounted


static func build_radial_texture(
	base_tint: Color,
	texture_size: Vector2i = Vector2i(256, 256),
	core_color: Color = Color(1.0, 0.97, 0.9, 1.0),
	core_stop: float = 0.0,
	mid_stop: float = 0.3,
	outer_stop: float = 0.78,
	mid_alpha: float = 0.42
) -> Texture2D:
	var gradient: Gradient = Gradient.new()
	var mid_color: Color = Color(base_tint.r, base_tint.g, base_tint.b, clampf(mid_alpha, 0.0, 1.0))
	var outer_color: Color = Color(base_tint.r, base_tint.g, base_tint.b, 0.0)

	gradient.offsets = PackedFloat32Array([
		clampf(core_stop, 0.0, 1.0),
		clampf(mid_stop, 0.0, 1.0),
		clampf(outer_stop, 0.0, 1.0),
		1.0,
	])
	gradient.colors = PackedColorArray([
		core_color,
		mid_color,
		outer_color,
		Color(0.0, 0.0, 0.0, 0.0),
	])

	var width: int = maxi(texture_size.x, 1)
	var height: int = maxi(texture_size.y, 1)
	var image: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2((width - 1) * 0.5, (height - 1) * 0.5)
	var radius: float = maxf(minf(width, height) * 0.5, 1.0)

	for y in range(height):
		for x in range(width):
			var point: Vector2 = Vector2(x, y)
			var distance_from_center: float = point.distance_to(center)
			var t: float = clampf(distance_from_center / radius, 0.0, 1.0)
			var pixel_color: Color = gradient.sample(t)
			image.set_pixel(x, y, pixel_color)

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	return texture

extends Node2D

const PET_RECOLOR_SHADER: Shader = preload("res://shaders/pet_recolor.gdshader")

@export var offset_when_player_faces_right := Vector2(-45, -42)
@export var offset_when_player_faces_left := Vector2(45, -42)

@export var follow_speed := 8.0
@export var bob_amount := 5.0
@export var bob_speed := 4.5

@export var light_energy := 2.45
@export var use_generated_gradient_texture := true
@export var use_native_light_texture_size := true
@export var light_texture_scale_override := 1.0
@export var light_radius_pixels := 226.0
@export var light_flicker_strength := 0.12
@export var light_flicker_speed := 3.2

@export var light_color := Color(0.57254905, 0.88235295, 1.0, 1.0)
@export var color_a := Color(0.145, 0.8, 1.0, 1.0)
@export var color_b := Color(0.916, 0.512, 0.165, 1.0)
@export var color_cycle_speed := 1.2

@export var gradient_texture_size := Vector2i(400, 400)
@export var gradient_core_color := Color(1.0, 0.98, 0.92, 1.0)

@export_range(0.0, 1.0, 0.01) var gradient_core_stop := 0.0
@export_range(0.0, 1.0, 0.01) var gradient_mid_stop := 0.28
@export_range(0.0, 1.0, 0.01) var gradient_outer_stop := 0.74
@export_range(0.0, 1.0, 0.01) var gradient_mid_alpha := 0.4

@export_group("Light Power Gameplay")
@export_range(0.0, 1.0, 0.01) var light_power := 1.0
@export_range(0.0, 1.0, 0.01) var weak_light_energy_multiplier := 0.25
@export_range(0.0, 1.0, 0.01) var weak_light_radius_multiplier := 0.45
@export var weak_light_color := Color(0.22, 0.38, 0.62, 1.0)

@onready var pet_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pet_light: PointLight2D = $PointLight2D

var player: CharacterBody2D


func _ready() -> void:
	top_level = true
	player = get_parent() as CharacterBody2D

	if pet_sprite != null:
		_ensure_recolor_material()
		pet_sprite.play("float")

	if pet_light != null:
		if use_generated_gradient_texture:
			pet_light.texture = LightGradientUtils.build_radial_texture(
				Color.WHITE,
				gradient_texture_size,
				gradient_core_color,
				gradient_core_stop,
				gradient_mid_stop,
				gradient_outer_stop,
				gradient_mid_alpha
			)

		pet_light.enabled = true
		pet_light.offset = Vector2.ZERO
		pet_light.energy = light_energy
		pet_light.texture_scale = _get_light_texture_scale()
		pet_light.color = _get_animated_light_color(Time.get_ticks_msec() / 1000.0)

	if player != null:
		global_position = player.global_position + offset_when_player_faces_left

	_apply_pet_color(_get_animated_light_color(Time.get_ticks_msec() / 1000.0))


func _process(delta: float) -> void:
	if player == null:
		return

	var player_sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	var offset: Vector2 = offset_when_player_faces_left

	if player_sprite != null and player_sprite.flip_h:
		offset = offset_when_player_faces_right

	var time: float = Time.get_ticks_msec() / 1000.0
	var base_light_color: Color = _get_animated_light_color(time)
	var powered_light_color: Color = weak_light_color.lerp(base_light_color, light_power)

	var floating: Vector2 = Vector2(0.0, sin(time * bob_speed) * bob_amount)

	var target_position: Vector2 = player.global_position + offset + floating

	global_position = global_position.lerp(
		target_position,
		minf(follow_speed * delta, 1.0)
	)

	if pet_light != null:
		var flicker: float = 1.0 + sin(time * light_flicker_speed) * light_flicker_strength
		flicker += sin(time * (light_flicker_speed * 1.91)) * (light_flicker_strength * 0.5)

		var energy_multiplier: float = lerpf(weak_light_energy_multiplier, 1.0, light_power)
		var radius_multiplier: float = lerpf(weak_light_radius_multiplier, 1.0, light_power)

		pet_light.energy = maxf(light_energy * energy_multiplier * flicker, 0.0)
		pet_light.texture_scale = _get_light_texture_scale() * radius_multiplier * (1.0 + (flicker - 1.0) * 0.08)
		pet_light.color = powered_light_color

	_apply_pet_color(powered_light_color)


func set_light_power(value: float) -> void:
	light_power = clampf(value, 0.0, 1.0)


func get_light_power() -> float:
	return light_power


func drain_light(amount: float, minimum_power: float = 0.0) -> void:
	set_light_power(maxf(light_power - amount, minimum_power))


func recharge_light(amount: float = 1.0) -> void:
	set_light_power(light_power + amount)


func is_light_strong(threshold: float = 0.65) -> bool:
	return light_power >= threshold


func _get_light_texture_scale() -> float:
	if use_native_light_texture_size:
		return maxf(light_texture_scale_override, 0.001)

	if pet_light == null or pet_light.texture == null:
		return 1.0

	var texture_size: Vector2 = pet_light.texture.get_size()
	var texture_diameter: float = maxf(texture_size.x, texture_size.y)

	if texture_diameter <= 0.0:
		return 1.0

	return (light_radius_pixels * 2.0) / texture_diameter


func _get_animated_light_color(time: float) -> Color:
	var color_mix: float = (sin(time * color_cycle_speed) + 1.0) * 0.5

	if use_generated_gradient_texture:
		return color_a.lerp(color_b, color_mix)

	return light_color


func _ensure_recolor_material() -> void:
	if pet_sprite == null:
		return

	var existing_material: ShaderMaterial = pet_sprite.material as ShaderMaterial

	if existing_material != null and existing_material.shader == PET_RECOLOR_SHADER:
		return

	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = PET_RECOLOR_SHADER
	pet_sprite.material = shader_material


func _apply_pet_color(target_color: Color) -> void:
	if pet_sprite == null:
		return

	var shader_material: ShaderMaterial = pet_sprite.material as ShaderMaterial

	if shader_material == null:
		return

	shader_material.set_shader_parameter("target_color", target_color)

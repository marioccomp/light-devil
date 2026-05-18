extends Node2D

@export var offset_when_player_faces_right := Vector2(-45, -42)
@export var offset_when_player_faces_left := Vector2(45, -42)

@export var follow_speed := 8.0
@export var bob_amount := 5.0
@export var bob_speed := 4.5
@export var light_energy := 2.45
@export var use_native_light_texture_size := true
@export var light_texture_scale_override := 1.0
@export var light_radius_pixels := 226.0
@export var light_flicker_strength := 0.12
@export var light_flicker_speed := 3.2
@export var light_color := Color(0.57254905, 0.88235295, 1.0, 1.0)

@onready var pet_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pet_light: PointLight2D = $PointLight2D

var player: CharacterBody2D


func _ready() -> void:
	top_level = true
	player = get_parent() as CharacterBody2D

	if pet_sprite != null:
		pet_sprite.play("float")

	if pet_light != null:
		pet_light.enabled = true
		pet_light.offset = Vector2.ZERO
		pet_light.energy = light_energy
		pet_light.texture_scale = _get_light_texture_scale()
		pet_light.color = light_color

	if player != null:
		global_position = player.global_position + offset_when_player_faces_left


func _process(delta: float) -> void:
	if player == null:
		return

	var player_sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	var offset: Vector2 = offset_when_player_faces_left

	if player_sprite != null and player_sprite.flip_h:
		offset = offset_when_player_faces_right

	var time: float = Time.get_ticks_msec() / 1000.0
	var floating: Vector2 = Vector2(0.0, sin(time * bob_speed) * bob_amount)

	var target_position: Vector2 = player.global_position + offset + floating

	global_position = global_position.lerp(
		target_position,
		minf(follow_speed * delta, 1.0)
	)

	if pet_light != null:
		var flicker: float = 1.0 + sin(time * light_flicker_speed) * light_flicker_strength
		flicker += sin(time * (light_flicker_speed * 1.91)) * (light_flicker_strength * 0.5)
		pet_light.energy = maxf(light_energy * flicker, 0.0)
		pet_light.texture_scale = _get_light_texture_scale() * (1.0 + (flicker - 1.0) * 0.08)
		pet_light.color = light_color


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

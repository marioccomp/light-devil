extends Node2D

@export var bob_amount: float = 3.0
@export var bob_speed: float = 2.4

@export var rune_pulse_amount: float = 0.06
@export var rune_pulse_speed: float = 2.8

@export var glow_scale_amount: float = 0.18
@export var glow_speed: float = 2.1

@export_range(0.0, 1.0, 0.01) var glow_alpha_min: float = 0.12
@export_range(0.0, 1.0, 0.01) var glow_alpha_max: float = 0.28

@onready var rune_sprite: Sprite2D = get_node_or_null("RuneSprite") as Sprite2D
@onready var glow_sprite: Sprite2D = get_node_or_null("Glow") as Sprite2D
@onready var rune_light: PointLight2D = get_node_or_null("RuneLight") as PointLight2D

var start_position: Vector2 = Vector2.ZERO
var rune_base_scale: Vector2 = Vector2.ONE
var glow_base_scale: Vector2 = Vector2.ONE
var base_light_energy: float = 1.0


func _ready() -> void:
	start_position = position

	if rune_sprite != null:
		rune_base_scale = rune_sprite.scale

	if glow_sprite != null:
		glow_base_scale = glow_sprite.scale

	if rune_light != null:
		base_light_energy = rune_light.energy


func _process(_delta: float) -> void:
	var time: float = Time.get_ticks_msec() / 1000.0

	position = start_position + Vector2(
		0.0,
		sin(time * bob_speed) * bob_amount
	)

	var rune_pulse: float = 1.0 + sin(time * rune_pulse_speed) * rune_pulse_amount

	if rune_sprite != null:
		rune_sprite.scale = rune_base_scale * rune_pulse

	var glow_t: float = (sin(time * glow_speed) + 1.0) * 0.5

	if glow_sprite != null:
		glow_sprite.scale = glow_base_scale * (1.0 + sin(time * glow_speed) * glow_scale_amount)

		var color: Color = glow_sprite.modulate
		color.a = lerpf(glow_alpha_min, glow_alpha_max, glow_t)
		glow_sprite.modulate = color

	if rune_light != null:
		rune_light.energy = base_light_energy * lerpf(0.75, 1.25, glow_t)

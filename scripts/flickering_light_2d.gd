extends PointLight2D

@export var use_generated_gradient_texture := true
@export var gradient_tint := Color(1.0, 0.8352941, 0.54509807, 1.0)
@export var gradient_texture_size := Vector2i(16, 16)
@export var gradient_core_color := Color(1.0, 0.96, 0.86, 1.0)
@export_range(0.0, 1.0, 0.01) var gradient_core_stop := 0.0
@export_range(0.0, 1.0, 0.01) var gradient_mid_stop := 0.28
@export_range(0.0, 1.0, 0.01) var gradient_outer_stop := 0.82
@export_range(0.0, 1.0, 0.01) var gradient_mid_alpha := 0.5

@export var base_energy := 1.8
@export var base_texture_scale := 18.0
@export var flicker_strength := 0.08
@export var flicker_speed := 2.6
@export var scale_pulse_strength := 0.08

var _phase: float = 0.0


func _ready() -> void:
	_phase = randf() * TAU

	if use_generated_gradient_texture:
		texture = LightGradientUtils.build_radial_texture(
			gradient_tint,
			gradient_texture_size,
			gradient_core_color,
			gradient_core_stop,
			gradient_mid_stop,
			gradient_outer_stop,
			gradient_mid_alpha
		)

	enabled = true
	color = _get_modulate_color()
	energy = base_energy
	texture_scale = base_texture_scale


func _process(_delta: float) -> void:
	var time: float = (Time.get_ticks_msec() / 1000.0) + _phase
	var flicker: float = 1.0 + sin(time * flicker_speed) * flicker_strength
	flicker += sin(time * (flicker_speed * 1.83)) * (flicker_strength * 0.45)

	energy = maxf(base_energy * flicker, 0.0)
	texture_scale = maxf(
		base_texture_scale * (1.0 + (flicker - 1.0) * scale_pulse_strength),
		0.001
	)


func _get_modulate_color() -> Color:
	return Color.WHITE if use_generated_gradient_texture else gradient_tint

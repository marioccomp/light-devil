extends Camera2D

var default_zoom: Vector2
var default_position: Vector2

var shake_time_left := 0.0
var shake_strength := 0.0

var zoom_tween: Tween = null
var intro_tween: Tween = null

func _ready() -> void:
	default_zoom = zoom
	default_position = position

	add_to_group("game_camera")
	randomize()

func _process(delta: float) -> void:
	if shake_time_left > 0.0:
		shake_time_left -= delta

		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		offset = Vector2.ZERO

func shake(duration: float = 0.18, strength: float = 8.0) -> void:
	shake_time_left = duration
	shake_strength = strength

func pulse_zoom(target_zoom: Vector2 = Vector2(1.55, 1.55), zoom_in_time: float = 0.08, zoom_out_time: float = 0.18) -> void:
	if zoom_tween != null:
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.tween_property(self, "zoom", target_zoom, zoom_in_time)
	zoom_tween.tween_property(self, "zoom", default_zoom, zoom_out_time)

func zoom_out_temporarily(target_zoom: Vector2 = Vector2(1.05, 1.05), hold_time: float = 0.45) -> void:
	if zoom_tween != null:
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.tween_property(self, "zoom", target_zoom, 0.18)
	zoom_tween.tween_interval(hold_time)
	zoom_tween.tween_property(self, "zoom", default_zoom, 0.25)

func play_intro_pan(target_global_position: Vector2) -> void:
	if intro_tween != null:
		intro_tween.kill()

	reset_camera()

	var start_global_position := global_position

	# Mantém a altura inicial da câmera.
	# A câmera só passeia no eixo X.
	var fixed_target_position := Vector2(
		target_global_position.x,
		start_global_position.y
	)

	intro_tween = create_tween()

	intro_tween.tween_interval(0.25)

	intro_tween.tween_property(
		self,
		"global_position",
		fixed_target_position,
		1.15
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	intro_tween.tween_interval(0.35)

	intro_tween.tween_property(
		self,
		"global_position",
		start_global_position,
		1.15
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await intro_tween.finished

	position = default_position
	offset = Vector2.ZERO
	zoom = default_zoom

func reset_camera() -> void:
	if zoom_tween != null:
		zoom_tween.kill()

	zoom = default_zoom
	offset = Vector2.ZERO
	shake_time_left = 0.0
	shake_strength = 0.0

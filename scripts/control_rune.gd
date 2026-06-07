extends Area2D

@export var invert_controls: bool = true
@export var one_shot: bool = true
@export var death_hint_window_seconds: float = 7.0

@export var effect_time: float = 0.12
@export var fade_after_use: bool = true

@export var push_player_pixels: float = 0.0
@export var push_direction: Vector2 = Vector2.RIGHT

@onready var visual: Node2D = get_node_or_null("Visual") as Node2D

var used := false
var busy := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if busy:
		return

	if used and one_shot:
		return

	if not body.has_method("set_controls_inverted"):
		return

	busy = true
	used = true

	# Troca o controle imediatamente, sem travar o jogador.
	body.set_controls_inverted(invert_controls)
	
	if invert_controls:
		var hint_until_msec := Time.get_ticks_msec() + int(death_hint_window_seconds * 1000.0)
		get_tree().set_meta("control_rune_tip_until_msec", hint_until_msec)
	else:
		if get_tree().has_meta("control_rune_tip_until_msec"):
			get_tree().remove_meta("control_rune_tip_until_msec")

	# Pequeno empurrão opcional. Recomendo deixar 0.
	if push_player_pixels > 0.0:
		body.global_position += push_direction.normalized() * push_player_pixels

	var camera := get_tree().get_first_node_in_group("game_camera")

	if camera != null:
		if camera.has_method("pulse_zoom"):
			camera.pulse_zoom(Vector2(1.25, 1.25), 0.05, 0.10)

		if camera.has_method("shake"):
			camera.shake(0.06, 2.0)

	await _play_activation_effect()

	if visual != null and one_shot and fade_after_use:
		visual.modulate.a = 0.38

	busy = false


func _play_activation_effect() -> void:
	if visual == null:
		await get_tree().create_timer(effect_time).timeout
		return

	var original_scale: Vector2 = visual.scale

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		visual,
		"scale",
		original_scale * 1.22,
		effect_time * 0.5
	)

	tween.tween_property(
		visual,
		"modulate:a",
		1.0,
		effect_time * 0.5
	)

	await tween.finished

	var tween_back := create_tween()
	tween_back.tween_property(
		visual,
		"scale",
		original_scale,
		effect_time * 0.5
	)

	await tween_back.finished

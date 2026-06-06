extends Area2D

@export var invert_controls: bool = true
@export var one_shot: bool = true
@export var lock_time: float = 0.18
@export var push_player_pixels: float = 55.0
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

	if body.has_method("lock_movement"):
		body.lock_movement()

	if body is CharacterBody2D:
		body.velocity = Vector2.ZERO

	var camera := get_tree().get_first_node_in_group("game_camera")
	if camera != null:
		if camera.has_method("pulse_zoom"):
			camera.pulse_zoom(Vector2(1.45, 1.45), 0.07, 0.16)

		if camera.has_method("shake"):
			camera.shake(0.10, 3.0)

	await _play_activation_effect()

	body.set_controls_inverted(invert_controls)

	body.global_position += push_direction.normalized() * push_player_pixels

	await get_tree().create_timer(lock_time).timeout

	if body.has_method("unlock_movement"):
		body.unlock_movement()

	if visual != null and one_shot:
		visual.modulate.a = 0.45

	busy = false


func _play_activation_effect() -> void:
	if visual == null:
		await get_tree().create_timer(0.12).timeout
		return

	var original_scale: Vector2 = visual.scale
	var tween: Tween = create_tween()

	tween.tween_property(visual, "scale", original_scale * 1.35, 0.08)
	tween.tween_property(visual, "scale", original_scale, 0.10)

	await tween.finished

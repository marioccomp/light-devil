extends Area2D

@export var target_marker_path: NodePath

@export var invert_gravity_on_exit: bool = true
@export var invert_controls_on_exit: bool = true
@export var one_shot: bool = true

@export var pull_time: float = 0.22
@export var disappear_time: float = 0.12
@export var exit_lock_time: float = 0.18

@onready var target_marker: Node2D = get_node_or_null(target_marker_path) as Node2D
@onready var visual: Node2D = get_node_or_null("Visual") as Node2D
@onready var portal_light: PointLight2D = get_node_or_null("PortalLight") as PointLight2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

var busy := false
var used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if visual != null:
		visual.rotation += delta * 1.4


func _on_body_entered(body: Node2D) -> void:
	if busy:
		return

	if used and one_shot:
		return

	if body.name != "Player":
		return

	if target_marker == null:
		print("Portal sem Target Marker configurado.")
		return

	busy = true
	used = true

	if one_shot and collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	if body.has_method("lock_movement"):
		body.lock_movement()

	if body is CharacterBody2D:
		body.velocity = Vector2.ZERO

	var camera := get_tree().get_first_node_in_group("game_camera")
	if camera != null:
		if camera.has_method("pulse_zoom"):
			camera.pulse_zoom(Vector2(1.75, 1.75), 0.10, 0.22)

		if camera.has_method("shake"):
			camera.shake(0.16, 5.0)

	await _pulse_portal()

	await _pull_player_to_portal(body)

	await _hide_player(body)

	body.global_position = target_marker.global_position

	if body.has_method("set_gravity_inverted"):
		body.set_gravity_inverted(invert_gravity_on_exit)

	if body.has_method("set_controls_inverted"):
		body.set_controls_inverted(invert_controls_on_exit)

	if body is CharacterBody2D:
		body.velocity = Vector2.ZERO

	await get_tree().create_timer(disappear_time).timeout

	await _show_player(body)

	if camera != null and camera.has_method("shake"):
		camera.shake(0.12, 4.0)

	await get_tree().create_timer(exit_lock_time).timeout

	if body is CharacterBody2D:
		body.velocity = Vector2.ZERO

	if body.has_method("unlock_movement"):
		body.unlock_movement()

	busy = false


func _pull_player_to_portal(body: Node2D) -> void:
	var original_scale: Vector2 = body.scale

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		body,
		"global_position",
		global_position,
		pull_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		body,
		"scale",
		original_scale * 0.45,
		pull_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	body.scale = original_scale


func _hide_player(body: Node) -> void:
	_set_canvas_visible(body, false)

	var pet := body.get_node_or_null("Pet")
	_set_canvas_visible(pet, false)


func _show_player(body: Node) -> void:
	_set_canvas_visible(body, true)

	var pet := body.get_node_or_null("Pet")
	_set_canvas_visible(pet, true)


func _set_canvas_visible(node: Node, value: bool) -> void:
	if node == null:
		return

	if node is CanvasItem:
		(node as CanvasItem).visible = value


func _pulse_portal() -> void:
	if visual == null:
		await get_tree().create_timer(0.08).timeout
		return

	var original_scale: Vector2 = visual.scale
	var original_modulate: Color = visual.modulate

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		visual,
		"scale",
		original_scale * 1.35,
		0.10
	)

	tween.tween_property(
		visual,
		"modulate:a",
		1.0,
		0.10
	)

	if portal_light != null:
		tween.tween_property(
			portal_light,
			"energy",
			2.8,
			0.10
		)

	await tween.finished

	var tween_back := create_tween()
	tween_back.set_parallel(true)

	tween_back.tween_property(
		visual,
		"scale",
		original_scale,
		0.12
	)

	tween_back.tween_property(
		visual,
		"modulate",
		original_modulate,
		0.12
	)

	if portal_light != null:
		tween_back.tween_property(
			portal_light,
			"energy",
			1.4,
			0.12
		)

	await tween_back.finished

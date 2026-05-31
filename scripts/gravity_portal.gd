extends Area2D

@export var target_marker_path: NodePath
@export var invert_gravity_on_enter := true
@export var exit_lock_time := 0.08

@onready var target_marker: Node2D = get_node_or_null(target_marker_path) as Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if target_marker == null:
		return

	if body.has_method("set_gravity_inverted"):
		body.set_gravity_inverted(invert_gravity_on_enter)

	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity = Vector2.ZERO

	if body.has_method("lock_movement"):
		body.lock_movement()

	body.global_position = target_marker.global_position

	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity = Vector2.ZERO

	if exit_lock_time > 0.0:
		await get_tree().create_timer(exit_lock_time).timeout
	else:
		await get_tree().process_frame

	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity = Vector2.ZERO

	if body.has_method("unlock_movement"):
		body.unlock_movement()

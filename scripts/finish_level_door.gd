extends Area2D

@export var finish_label_path: NodePath = NodePath("../FinishLabel")

@onready var finish_label: Label = get_node_or_null(finish_label_path) as Label

var finished := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if finished:
		return

	if body.name != "Player":
		return

	finished = true
	set_deferred("monitoring", false)

	if body.has_method("lock_movement"):
		body.lock_movement()

	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity = Vector2.ZERO

	if finish_label != null:
		finish_label.visible = true

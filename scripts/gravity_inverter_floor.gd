extends Area2D

@export var invert_gravity := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("set_gravity_inverted"):
		body.set_gravity_inverted(invert_gravity)

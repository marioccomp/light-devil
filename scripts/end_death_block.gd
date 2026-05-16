extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var active := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	deactivate()

func activate() -> void:
	active = true

	visible = true

	set_deferred("monitoring", true)
	collision_shape.set_deferred("disabled", false)

func deactivate() -> void:
	active = false

	visible = false

	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)

func _on_body_entered(body: Node) -> void:
	if not active:
		return

	if body.has_method("die"):
		body.die()

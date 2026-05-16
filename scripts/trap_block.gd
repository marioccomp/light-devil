extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var fall_speed: float = 520.0
@export var active_time: float = 1.4

var start_position: Vector2
var active := false
var falling := false

func _ready() -> void:
	start_position = global_position
	body_entered.connect(_on_body_entered)
	reset_trap()

func _physics_process(delta: float) -> void:
	if falling:
		global_position.y += fall_speed * delta

func activate() -> void:
	if active:
		return

	active = true
	falling = true

	global_position = start_position
	visible = true

	set_deferred("monitoring", true)
	collision_shape.set_deferred("disabled", false)

	_play_camera_danger_effect()

	await get_tree().create_timer(active_time).timeout

	reset_trap()

func reset_trap() -> void:
	active = false
	falling = false

	global_position = start_position
	visible = false

	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)

func _on_body_entered(body: Node) -> void:
	if not active:
		return

	if body.has_method("die"):
		body.die()

func _play_camera_danger_effect() -> void:
	var cameras := get_tree().get_nodes_in_group("game_camera")

	for camera in cameras:
		if camera.has_method("shake"):
			camera.shake(0.20, 9.0)

		if camera.has_method("pulse_zoom"):
			camera.pulse_zoom(Vector2(1.55, 1.55), 0.08, 0.18)

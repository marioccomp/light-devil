extends AnimatableBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: ColorRect = $Visual
@onready var detector: Area2D = $Detector

@export var delay_before_fall: float = 0.15
@export var fall_speed: float = 420.0
@export var reset_after: float = 1.5

var activated := false
var falling := false
var start_position: Vector2

func _ready() -> void:
	start_position = global_position
	detector.body_entered.connect(_on_detector_body_entered)

func _physics_process(delta: float) -> void:
	if falling:
		global_position.y += fall_speed * delta

func _on_detector_body_entered(body: Node) -> void:
	if activated:
		return

	if body.name != "Player":
		return

	activated = true

	await get_tree().create_timer(delay_before_fall).timeout

	collision_shape.set_deferred("disabled", true)
	falling = true

	await get_tree().create_timer(reset_after).timeout

	reset_false_floor()

func reset_false_floor() -> void:
	falling = false
	
	global_position = start_position
	
	visible = true
	collision_shape.set_deferred("disabled", false)
	
	activated = false


func _on_area_2d_body_entered(body):
	if body.name == "Player":
		body.die()

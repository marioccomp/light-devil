extends Area2D

@export var trap_block_path: NodePath
@export var starts_enabled: bool = true
@export var one_shot: bool = true
@export var show_visual: bool = false




@export_group("Activation Direction")
@export var override_activation_direction: bool = false
@export var activation_direction: Vector2 = Vector2.DOWN
@export_group("")



@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem

var trap_block: Node = null
var is_active := false
var was_used := false

func _ready() -> void:
	trap_block = get_node_or_null(trap_block_path)

	body_entered.connect(_on_body_entered)

	if visual != null:
		visual.visible = show_visual

	set_active(starts_enabled)

func set_active(value: bool) -> void:
	if one_shot and was_used and value:
		is_active = false
		set_deferred("monitoring", false)
		collision_shape.set_deferred("disabled", true)
		return

	is_active = value

	set_deferred("monitoring", value)
	collision_shape.set_deferred("disabled", not value)

func reset_trigger() -> void:
	was_used = false
	set_active(starts_enabled)

func _on_body_entered(body: Node) -> void:
	if not is_active:
		return

	if was_used:
		return

	if body.name != "Player":
		return

	if one_shot:
		was_used = true
		set_active(false)

	if trap_block == null:
		return

	if (
		override_activation_direction
		and trap_block.has_method("activate_with_direction")
	):
		trap_block.call(
			"activate_with_direction",
			activation_direction
		)
	elif trap_block.has_method("activate"):
		trap_block.call("activate")

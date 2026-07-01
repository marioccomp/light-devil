extends Area2D

@export_group("Light Reveal")
@export var reveal_only_with_pet_light: bool = false
@export var reveal_visual_path: NodePath = NodePath("Visual")
@export var reveal_radius: float = 240.0
@export var fade_distance: float = 60.0
@export_group("")

@onready var reveal_visual: CanvasItem = (
	get_node_or_null(reveal_visual_path) as CanvasItem
)

var pet: Node2D
var base_visual_color := Color.WHITE


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	_find_pet()

	if reveal_visual != null:
		base_visual_color = reveal_visual.modulate
		base_visual_color.a = 1.0

		if reveal_only_with_pet_light:
			_set_visual_alpha(0.0)


func _process(_delta: float) -> void:
	if not reveal_only_with_pet_light:
		return

	if reveal_visual == null:
		return

	if pet == null or not is_instance_valid(pet):
		_find_pet()

	if pet == null:
		_set_visual_alpha(0.0)
		return

	var light_power := 1.0

	if pet.has_method("get_light_power"):
		light_power = float(
			pet.call("get_light_power")
		)

	var current_radius := lerpf(
		reveal_radius * 0.45,
		reveal_radius,
		light_power
	)

	var distance_to_light := global_position.distance_to(
		pet.global_position
	)

	var fade_start := maxf(
		current_radius - fade_distance,
		0.0
	)

	var visibility_amount := 1.0 - smoothstep(
		fade_start,
		current_radius,
		distance_to_light
	)

	_set_visual_alpha(visibility_amount)


func _find_pet() -> void:
	var current_scene := get_tree().current_scene

	if current_scene == null:
		return

	pet = current_scene.get_node_or_null(
		"Player/Pet"
	) as Node2D


func _set_visual_alpha(value: float) -> void:
	if reveal_visual == null:
		return

	var new_color := base_visual_color
	new_color.a = clampf(value, 0.0, 1.0)

	reveal_visual.modulate = new_color


func _on_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()

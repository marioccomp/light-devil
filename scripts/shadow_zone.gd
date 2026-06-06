extends Area2D

@export var drain_per_second: float = 0.32
@export_range(0.0, 1.0, 0.01) var minimum_light_power: float = 0.18
@export var show_visual: bool = false

@export_group("Screen Darkness")
@export var shadow_color: Color = Color(0.10, 0.10, 0.16, 1.0)
@export_range(0.0, 1.0, 0.01) var min_shadow_blend: float = 0.18
@export_range(0.0, 1.0, 0.01) var max_shadow_blend: float = 0.62
@export var transition_speed: float = 4.5

@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem

var player_inside: Node = null
var canvas_modulate: CanvasModulate = null
var base_canvas_color: Color = Color(1, 1, 1, 1)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	canvas_modulate = get_tree().current_scene.get_node_or_null("CanvasModulate") as CanvasModulate

	if canvas_modulate != null:
		base_canvas_color = canvas_modulate.color

	if visual != null:
		visual.visible = show_visual


func _process(delta: float) -> void:
	var target_color: Color = base_canvas_color

	if player_inside != null:
		var pet := player_inside.get_node_or_null("Pet")

		if pet != null:
			if pet.has_method("drain_light"):
				pet.drain_light(drain_per_second * delta, minimum_light_power)

			var light_power: float = 1.0

			if pet.has_method("get_light_power"):
				light_power = pet.get_light_power()

			var darkness_blend: float = lerpf(max_shadow_blend, min_shadow_blend, light_power)
			target_color = base_canvas_color.lerp(shadow_color, darkness_blend)

	if canvas_modulate != null:
		canvas_modulate.color = canvas_modulate.color.lerp(
			target_color,
			minf(transition_speed * delta, 1.0)
		)


func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return

	player_inside = body


func _on_body_exited(body: Node) -> void:
	if body != player_inside:
		return

	player_inside = null


func _exit_tree() -> void:
	if canvas_modulate != null:
		canvas_modulate.color = base_canvas_color

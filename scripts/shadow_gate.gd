extends StaticBody2D

@export_range(0.0, 1.0, 0.01) var required_light_power: float = 0.65
@export var one_shot_open: bool = true
@export var open_time: float = 0.22
@export var close_again_if_weak: bool = false

@export_group("Recharge Crystal")
@export var recharge_crystal_path: NodePath
@export var respawn_crystal_when_weak: bool = true
@export var crystal_respawn_cooldown: float = 0.8

@onready var sensor: Area2D = get_node_or_null("Sensor") as Area2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem
@onready var gate_light: PointLight2D = get_node_or_null("GateLight") as PointLight2D
@onready var locked_label: Label = get_node_or_null("LockedLabel") as Label
@onready var recharge_crystal: Node = get_node_or_null(recharge_crystal_path)

var player_inside: Node = null
var opened := false
var busy := false
var can_respawn_crystal := true


func _ready() -> void:
	if sensor != null:
		sensor.body_entered.connect(_on_sensor_body_entered)
		sensor.body_exited.connect(_on_sensor_body_exited)

	if locked_label != null:
		locked_label.visible = false


func _process(_delta: float) -> void:
	if player_inside == null:
		return

	if opened and one_shot_open:
		return

	var pet := player_inside.get_node_or_null("Pet")

	if pet == null:
		return

	if not pet.has_method("is_light_strong"):
		return

	var light_is_strong: bool = pet.is_light_strong(required_light_power)

	if light_is_strong:
		open_gate()
	else:
		show_locked_feedback()
		_try_respawn_crystal()

		if opened and close_again_if_weak:
			close_gate()


func open_gate() -> void:
	if busy:
		return

	if opened and one_shot_open:
		return

	busy = true
	opened = true

	if locked_label != null:
		locked_label.visible = false

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	var camera := get_tree().get_first_node_in_group("game_camera")

	if camera != null and camera.has_method("pulse_zoom"):
		camera.pulse_zoom(Vector2(1.35, 1.35), 0.07, 0.14)

	await _play_open_effect()

	busy = false


func close_gate() -> void:
	if collision_shape != null:
		collision_shape.set_deferred("disabled", false)

	if visual != null:
		visual.visible = true
		visual.modulate.a = 1.0

	if gate_light != null:
		gate_light.energy = 1.2

	opened = false


func show_locked_feedback() -> void:
	if locked_label != null:
		locked_label.visible = true

	if visual != null:
		visual.modulate.a = 0.85


func _try_respawn_crystal() -> void:
	if not respawn_crystal_when_weak:
		return

	if not can_respawn_crystal:
		return

	if recharge_crystal == null:
		return

	if not recharge_crystal.has_method("respawn"):
		return

	can_respawn_crystal = false

	recharge_crystal.respawn()

	var camera := get_tree().get_first_node_in_group("game_camera")

	if camera != null and camera.has_method("shake"):
		camera.shake(0.10, 3.0)

	await get_tree().create_timer(crystal_respawn_cooldown).timeout

	can_respawn_crystal = true


func _play_open_effect() -> void:
	if visual == null:
		await get_tree().create_timer(open_time).timeout
		return

	var original_scale: Vector2 = visual.scale

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(visual, "scale", original_scale * Vector2(1.15, 1.35), open_time)
	tween.tween_property(visual, "modulate:a", 0.0, open_time)

	if gate_light != null:
		tween.tween_property(gate_light, "energy", 0.0, open_time)

	await tween.finished

	visual.visible = false
	visual.scale = original_scale


func _on_sensor_body_entered(body: Node) -> void:
	if body.name != "Player":
		return

	player_inside = body


func _on_sensor_body_exited(body: Node) -> void:
	if body != player_inside:
		return

	player_inside = null

	if locked_label != null:
		locked_label.visible = false

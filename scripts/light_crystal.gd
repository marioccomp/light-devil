extends Area2D

@export var recharge_amount: float = 1.0
@export var one_shot: bool = true
@export var pulse_light_energy: float = 2.8

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var visual: Node2D = get_node_or_null("Visual") as Node2D
@onready var crystal_light: PointLight2D = get_node_or_null("CrystalLight") as PointLight2D

var used := false
var busy := false

var original_visual_scale: Vector2 = Vector2.ONE
var original_light_energy: float = 1.4


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if visual != null:
		original_visual_scale = visual.scale

	if crystal_light != null:
		original_light_energy = crystal_light.energy


func _on_body_entered(body: Node) -> void:
	if busy:
		return

	if used and one_shot:
		return

	if body.name != "Player":
		return

	var pet := body.get_node_or_null("Pet")

	if pet == null:
		print("LightCrystal: Pet não encontrado no Player.")
		return

	if not pet.has_method("recharge_light"):
		print("LightCrystal: o Pet ainda não tem recharge_light().")
		return

	busy = true
	used = true

	pet.recharge_light(recharge_amount)

	var camera := get_tree().get_first_node_in_group("game_camera")

	if camera != null and camera.has_method("pulse_zoom"):
		camera.pulse_zoom(Vector2(1.45, 1.45), 0.07, 0.15)

	await _play_collect_effect()

	if one_shot:
		_disable_crystal()

	busy = false


func respawn() -> void:
	used = false
	busy = false

	monitoring = true
	monitorable = true

	if collision_shape != null:
		collision_shape.set_deferred("disabled", false)

	if visual != null:
		visual.visible = true
		visual.modulate.a = 1.0
		visual.scale = original_visual_scale

	if crystal_light != null:
		crystal_light.enabled = true
		crystal_light.energy = original_light_energy


func is_available() -> bool:
	return not used


func _disable_crystal() -> void:
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	set_deferred("monitoring", false)

	if visual != null:
		visual.modulate.a = 0.25

	if crystal_light != null:
		crystal_light.energy = 0.25


func _play_collect_effect() -> void:
	if visual == null:
		await get_tree().create_timer(0.10).timeout
		return

	var current_scale: Vector2 = visual.scale
	var current_light_energy: float = 0.0

	if crystal_light != null:
		current_light_energy = crystal_light.energy

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(visual, "scale", current_scale * 1.45, 0.10)

	if crystal_light != null:
		tween.tween_property(crystal_light, "energy", pulse_light_energy, 0.10)

	await tween.finished

	var tween_back := create_tween()
	tween_back.set_parallel(true)

	tween_back.tween_property(visual, "scale", current_scale, 0.14)

	if crystal_light != null:
		tween_back.tween_property(crystal_light, "energy", current_light_energy, 0.14)

	await tween_back.finished

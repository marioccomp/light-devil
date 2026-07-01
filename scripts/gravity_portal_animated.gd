extends Area2D

enum ExitGravityMode {
	USE_OLD_SETTING,
	DOWN,
	UP,
	LEFT,
	RIGHT
}

@export var target_marker_path: NodePath

@export var invert_gravity_on_exit: bool = true
@export var invert_controls_on_exit: bool = true
@export var one_shot: bool = true

@export_group("Exit Orientation")
@export_enum("Use Old Setting", "Down", "Up", "Left", "Right")
var exit_gravity_mode: int = ExitGravityMode.USE_OLD_SETTING

@export var rotate_exit_vectors_with_marker: bool = false
@export_group("")


@export var pull_time: float = 0.22
@export var disappear_time: float = 0.10
@export var exit_lock_time: float = 0.12

@export var rotate_visual: bool = false
@export var visual_rotation_speed: float = 1.4

@export_group("Exit Portal Animation")
@export var exit_portal_visual_path: NodePath

@export_group("Spit Player Out")
@export var spit_player_on_exit: bool = true
@export var spit_time: float = 0.18
@export var exit_position_offset: Vector2 = Vector2(55, 0)
@export var exit_velocity: Vector2 = Vector2(180, 0)

@onready var target_marker: Node2D = get_node_or_null(target_marker_path) as Node2D
@onready var visual: Node2D = get_node_or_null("Visual") as Node2D
@onready var exit_portal_visual: Node = get_node_or_null(exit_portal_visual_path)
@onready var portal_light: PointLight2D = get_node_or_null("PortalLight") as PointLight2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

var busy := false
var used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if visual != null and rotate_visual:
		visual.rotation += delta * visual_rotation_speed


func _on_body_entered(body: Node2D) -> void:
	if busy:
		return

	if used and one_shot:
		return

	if body.name != "Player":
		return

	if target_marker == null:
		print("Portal sem Target Marker configurado.")
		return

	busy = true
	used = true

	if one_shot and collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	if body.has_method("lock_movement"):
		body.lock_movement()

	if body is CharacterBody2D:
		body.velocity = Vector2.ZERO

	var camera := get_tree().get_first_node_in_group("game_camera")
	if camera != null:
		if camera.has_method("pulse_zoom"):
			camera.pulse_zoom(Vector2(1.75, 1.75), 0.10, 0.22)

		if camera.has_method("shake"):
			camera.shake(0.16, 5.0)

	await _pulse_portal()

	# Puxa o jogador para o centro do portal.
	await _pull_player_to_portal(body)

	# Agora o jogador some ANTES do portal fechar.
	# Isso faz parecer que o portal engoliu ele.
	_hide_player(body)

	await get_tree().create_timer(disappear_time).timeout

	# Portal de entrada fecha.
	await _play_entry_close()

	# Move o jogador invisível para o portal de saída.
	var resolved_exit_offset: Vector2 = exit_position_offset
	var resolved_exit_velocity: Vector2 = exit_velocity

	if rotate_exit_vectors_with_marker:
		resolved_exit_offset = exit_position_offset.rotated(
			target_marker.global_rotation
		)

		resolved_exit_velocity = exit_velocity.rotated(
			target_marker.global_rotation
		)

	var exit_start_position: Vector2 = target_marker.global_position
	var exit_end_position: Vector2 = (
		target_marker.global_position + resolved_exit_offset
	)

	body.global_position = exit_start_position

	_apply_exit_gravity(body)

	if body.has_method("set_controls_inverted"):
		body.set_controls_inverted(invert_controls_on_exit)

	if body is CharacterBody2D:
		body.velocity = Vector2.ZERO

	# Portal de saída abre.
	await _play_exit_open()

	# Jogador aparece no centro do portal de saída.
	_show_player(body)

	# Portal cospe o jogador para fora com um pequeno movimento.
	if spit_player_on_exit:
		await _spit_player(body, exit_end_position)
	else:
		body.global_position = exit_end_position

	if camera != null and camera.has_method("shake"):
		camera.shake(0.12, 4.0)

	await get_tree().create_timer(exit_lock_time).timeout

	if body is CharacterBody2D:
		if spit_player_on_exit:
			body.velocity = resolved_exit_velocity
		else:
			body.velocity = Vector2.ZERO

	if body.has_method("unlock_movement"):
		body.unlock_movement()

	busy = false

func _apply_exit_gravity(body: Node2D) -> void:
	
	if exit_gravity_mode == ExitGravityMode.USE_OLD_SETTING:
		if body.has_method("set_gravity_inverted"):
			body.call(
				"set_gravity_inverted",
				invert_gravity_on_exit
			)

		return

	if not body.has_method("set_gravity_direction"):
		push_warning(
			"Portal: Player não possui set_gravity_direction()."
		)
		return

	var new_direction := Vector2.DOWN

	match exit_gravity_mode:
		ExitGravityMode.DOWN:
			new_direction = Vector2.DOWN

		ExitGravityMode.UP:
			new_direction = Vector2.UP

		ExitGravityMode.LEFT:
			new_direction = Vector2.LEFT

		ExitGravityMode.RIGHT:
			new_direction = Vector2.RIGHT

	body.call("set_gravity_direction", new_direction)



func _pull_player_to_portal(body: Node2D) -> void:
	var original_scale: Vector2 = body.scale

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		body,
		"global_position",
		global_position,
		pull_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		body,
		"scale",
		original_scale * 0.35,
		pull_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	body.scale = original_scale


func _spit_player(body: Node2D, end_position: Vector2) -> void:
	var tween := create_tween()

	tween.tween_property(
		body,
		"global_position",
		end_position,
		spit_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished


func _play_entry_close() -> void:
	if visual == null:
		return

	if visual.has_method("play_close"):
		await visual.play_close()


func _play_exit_open() -> void:
	if exit_portal_visual == null:
		print("Portal: Exit Portal Visual Path não configurado.")
		return

	if exit_portal_visual.has_method("play_open"):
		await exit_portal_visual.play_open()


func _hide_player(body: Node) -> void:
	_set_canvas_visible(body, false)

	var pet := body.get_node_or_null("Pet")
	_set_canvas_visible(pet, false)


func _show_player(body: Node) -> void:
	_set_canvas_visible(body, true)

	var pet := body.get_node_or_null("Pet")
	_set_canvas_visible(pet, true)


func _set_canvas_visible(node: Node, value: bool) -> void:
	if node == null:
		return

	if node is CanvasItem:
		(node as CanvasItem).visible = value


func _pulse_portal() -> void:
	if visual == null:
		await get_tree().create_timer(0.08).timeout
		return

	var original_scale: Vector2 = visual.scale
	var original_modulate: Color = visual.modulate

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		visual,
		"scale",
		original_scale * 1.18,
		0.10
	)

	tween.tween_property(
		visual,
		"modulate:a",
		1.0,
		0.10
	)

	if portal_light != null:
		tween.tween_property(
			portal_light,
			"energy",
			2.2,
			0.10
		)

	await tween.finished

	var tween_back := create_tween()
	tween_back.set_parallel(true)

	tween_back.tween_property(
		visual,
		"scale",
		original_scale,
		0.12
	)

	tween_back.tween_property(
		visual,
		"modulate",
		original_modulate,
		0.12
	)

	if portal_light != null:
		tween_back.tween_property(
			portal_light,
			"energy",
			1.4,
			0.12
		)

	await tween_back.finished

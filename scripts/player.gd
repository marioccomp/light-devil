extends CharacterBody2D

@export var speed: float = 220.0
@export var jump_force: float = -430.0
@export var gravity: float = 1200.0
@export var death_delay: float = 0.85
@export var death_limit_y: float = 900.0
@export var death_limit_left_x: float = -100000.0
@export var death_limit_right_x: float = 100000.0
@export var death_limit_top_y: float = -100000.0
@export var normal_sprite_position: Vector2 = Vector2(0, -18)
@export var inverted_sprite_position: Vector2 = Vector2(0, 1)

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

var input_locked := false
var dead := false
var controls_inverted := false
var gravity_inverted := false

var gravity_direction := Vector2.DOWN
var base_collision_position := Vector2.ZERO
var base_anim_scale := Vector2.ONE

func _ready() -> void:
	if collision_shape != null:
		base_collision_position = collision_shape.position

	if anim != null:
		base_anim_scale = Vector2(
			absf(anim.scale.x),
			absf(anim.scale.y)
		)

	set_gravity_direction(Vector2.DOWN)

	if visual != null:
		visual.visible = false

	if anim != null and anim.sprite_frames != null:
		if anim.sprite_frames.has_animation("death"):
			anim.sprite_frames.set_animation_loop("death", false)

	_play_anim("idle")


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if input_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		return

	var movement_input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	var surface_direction := get_surface_direction()
	var direction := movement_input.dot(surface_direction)

	if controls_inverted:
		direction *= -1.0

	var gravity_speed := velocity.dot(gravity_direction)

	velocity = (
		surface_direction * direction * speed
		+ gravity_direction * gravity_speed
	)

	var world_movement := surface_direction * direction

	if world_movement.x < -0.01:
		_set_facing_left(false)
	elif world_movement.x > 0.01:
		_set_facing_left(true)

	if not is_on_floor():
		velocity += gravity_direction * gravity * delta
	else:
		gravity_speed = velocity.dot(gravity_direction)

		if gravity_speed > 0.0:
			velocity -= gravity_direction * gravity_speed

	if _is_jump_just_pressed() and is_on_floor():
		var surface_speed := velocity.dot(surface_direction)

		velocity = surface_direction * surface_speed
		velocity += -gravity_direction * absf(jump_force)

	move_and_slide()

	_update_animation()

	if (
		global_position.y > death_limit_y
		or global_position.y < death_limit_top_y
		or global_position.x < death_limit_left_x
		or global_position.x > death_limit_right_x
	):
		die()

func _update_animation() -> void:
	if anim == null:
		return

	if dead:
		return

	var surface_direction := get_surface_direction()

	if not is_on_floor():
		var gravity_speed := velocity.dot(gravity_direction)

		if gravity_speed < 0.0:
			_play_anim("jump")
		else:
			_play_anim("fall")

		return

	var surface_speed := velocity.dot(surface_direction)

	if absf(surface_speed) > 1.0:
		_play_anim("run")
	else:
		_play_anim("idle")


func _play_anim(anim_name: String) -> void:
	if anim == null:
		return

	if anim.sprite_frames == null:
		return

	if not anim.sprite_frames.has_animation(anim_name):
		return

	if anim.animation != anim_name:
		anim.play(anim_name)


func _set_facing_left(is_left: bool) -> void:
	if anim == null:
		return

	anim.flip_h = is_left


func lock_movement() -> void:
	input_locked = true
	velocity = Vector2.ZERO
	_update_animation()


func unlock_movement() -> void:
	if dead:
		return

	input_locked = false


func set_controls_inverted(enabled: bool) -> void:
	controls_inverted = enabled


func set_gravity_inverted(enabled: bool) -> void:
	if enabled:
		set_gravity_direction(Vector2.UP)
	else:
		set_gravity_direction(Vector2.DOWN)


func set_gravity_direction(new_direction: Vector2) -> void:
	if new_direction == Vector2.ZERO:
		return

	if absf(new_direction.x) > absf(new_direction.y):
		if new_direction.x > 0.0:
			gravity_direction = Vector2.RIGHT
		else:
			gravity_direction = Vector2.LEFT
	else:
		if new_direction.y > 0.0:
			gravity_direction = Vector2.DOWN
		else:
			gravity_direction = Vector2.UP

	gravity_inverted = gravity_direction == Vector2.UP
	up_direction = -gravity_direction

	var surface_direction := get_surface_direction()
	var surface_speed := velocity.dot(surface_direction)

	velocity = surface_direction * surface_speed

	_apply_orientation_visuals()


func is_gravity_inverted() -> bool:
	return gravity_direction == Vector2.UP


func get_gravity_direction() -> Vector2:
	return gravity_direction


func get_surface_direction() -> Vector2:
	return Vector2(
		gravity_direction.y,
		-gravity_direction.x
	)


func _is_jump_just_pressed() -> bool:
	if Input.is_action_just_pressed("jump"):
		return true

	var jump_direction := -gravity_direction

	if jump_direction == Vector2.UP:
		return Input.is_action_just_pressed("move_up")

	if jump_direction == Vector2.DOWN:
		return Input.is_action_just_pressed("move_down")

	if jump_direction == Vector2.LEFT:
		return Input.is_action_just_pressed("move_left")

	if jump_direction == Vector2.RIGHT:
		return Input.is_action_just_pressed("move_right")

	return false


func _apply_orientation_visuals() -> void:
	if collision_shape != null:
		if gravity_direction == Vector2.LEFT:
			collision_shape.rotation = PI / 2.0
			collision_shape.position = base_collision_position.rotated(PI / 2.0)

		elif gravity_direction == Vector2.RIGHT:
			collision_shape.rotation = -PI / 2.0
			collision_shape.position = base_collision_position.rotated(-PI / 2.0)

		else:
			collision_shape.rotation = 0.0
			collision_shape.position = base_collision_position

	if anim == null:
		return

	if gravity_direction == Vector2.DOWN:
		anim.rotation = 0.0
		anim.scale = base_anim_scale
		anim.position = normal_sprite_position

	elif gravity_direction == Vector2.UP:
		anim.rotation = 0.0
		anim.scale = Vector2(
			base_anim_scale.x,
			-base_anim_scale.y
		)
		anim.position = inverted_sprite_position

	elif gravity_direction == Vector2.LEFT:
		anim.rotation = PI / 2.0
		anim.scale = base_anim_scale
		anim.position = normal_sprite_position.rotated(PI / 2.0)

	elif gravity_direction == Vector2.RIGHT:
		anim.rotation = -PI / 2.0
		anim.scale = base_anim_scale
		anim.position = normal_sprite_position.rotated(-PI / 2.0)
		
func die() -> void:
	if dead:
		return

	dead = true
	_prepare_rune_death_hint()
	input_locked = true
	velocity = Vector2.ZERO

	_play_anim("death")

	await get_tree().create_timer(death_delay).timeout

	var level_manager := get_node_or_null("../LevelManager")

	if level_manager != null and level_manager.has_method("on_player_died"):
		level_manager.on_player_died(self)
	else:
		get_tree().reload_current_scene()


func respawn_at(new_position: Vector2) -> void:
	global_position = new_position
	velocity = Vector2.ZERO
	dead = false
	input_locked = false
	controls_inverted = false
	set_gravity_inverted(false)
	_play_anim("idle")


func force_fall() -> void:
	if dead:
		return

	var current_fall_speed := velocity.dot(gravity_direction)

	if current_fall_speed < 420.0:
		velocity += gravity_direction * (
			420.0 - current_fall_speed
		)
	
func _prepare_rune_death_hint() -> void:
	var hint_until_msec := int(get_tree().get_meta("control_rune_tip_until_msec", 0))

	if hint_until_msec <= 0:
		return

	if Time.get_ticks_msec() <= hint_until_msec:
		get_tree().set_meta(
			"pending_death_hint",
			"Cuidado, runas invertem seus controles"
		)

	if get_tree().has_meta("control_rune_tip_until_msec"):
		get_tree().remove_meta("control_rune_tip_until_msec")

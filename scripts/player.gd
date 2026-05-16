extends CharacterBody2D

@export var speed: float = 220.0
@export var jump_force: float = -430.0
@export var gravity: float = 1200.0
@export var death_delay: float = 0.85

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem

var input_locked := false
var dead := false


func _ready() -> void:
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

	var direction := Input.get_axis("move_left", "move_right")

	velocity.x = direction * speed

	if direction < 0:
		_set_facing_left(false)
	elif direction > 0:
		_set_facing_left(true)

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0:
			velocity.y = 0

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()

	_update_animation()

	if global_position.y > 900:
		die()


func _update_animation() -> void:
	if anim == null:
		return

	if dead:
		return

	if not is_on_floor():
		if velocity.y < 0:
			_play_anim("jump")
		else:
			_play_anim("fall")
		return

	if abs(velocity.x) > 1.0:
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


func die() -> void:
	if dead:
		return

	dead = true
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
	_play_anim("idle")


func force_fall() -> void:
	if dead:
		return

	velocity.y = max(velocity.y, 420.0)

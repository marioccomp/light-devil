extends Area2D

@export var fall_speed: float = 520.0
@export var active_time: float = 1.4
@export var fall_direction: Vector2 = Vector2.DOWN

@export var animation_name: String = "roll"
@export var animation_fps: float = 12.0

@export var rotate_sprite_while_falling: bool = false
@export var rotation_speed: float = 8.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trap_sprite: AnimatedSprite2D = $TrapSprite

var start_position: Vector2
var active := false
var falling := false


func _ready() -> void:
	start_position = global_position

	body_entered.connect(_on_body_entered)

	_configure_trap_sprite()
	reset_trap()


func _physics_process(delta: float) -> void:
	if not falling:
		return

	var direction := fall_direction.normalized()
	global_position += direction * fall_speed * delta

	if rotate_sprite_while_falling and trap_sprite != null:
		trap_sprite.rotation += rotation_speed * delta


func activate() -> void:
	if active:
		return

	active = true
	falling = true

	global_position = start_position
	visible = true

	set_deferred("monitoring", true)
	collision_shape.set_deferred("disabled", false)

	_start_boulder_animation()
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

	if trap_sprite != null:
		trap_sprite.stop()
		trap_sprite.frame = 0
		trap_sprite.rotation = 0.0


func _on_body_entered(body: Node) -> void:
	if not active:
		return

	if body.has_method("die"):
		body.die()


func _configure_trap_sprite() -> void:
	if trap_sprite == null:
		print("TrapBlock: TrapSprite não encontrado.")
		return

	if trap_sprite.sprite_frames == null:
		print("TrapBlock: TrapSprite está sem SpriteFrames.")
		return

	if not trap_sprite.sprite_frames.has_animation(animation_name):
		print("TrapBlock: animação '%s' não existe no TrapSprite." % animation_name)
		return

	trap_sprite.sprite_frames.set_animation_loop(animation_name, true)
	trap_sprite.sprite_frames.set_animation_speed(animation_name, animation_fps)

	trap_sprite.animation = animation_name
	trap_sprite.frame = 0


func _start_boulder_animation() -> void:
	if trap_sprite == null:
		print("TrapBlock: TrapSprite não encontrado na hora de tocar animação.")
		return

	if trap_sprite.sprite_frames == null:
		print("TrapBlock: TrapSprite está sem SpriteFrames na hora de tocar animação.")
		return

	if not trap_sprite.sprite_frames.has_animation(animation_name):
		print("TrapBlock: animação '%s' não existe no TrapSprite." % animation_name)
		return

	trap_sprite.visible = true
	trap_sprite.rotation = 0.0

	trap_sprite.stop()
	trap_sprite.animation = animation_name
	trap_sprite.frame = 0
	trap_sprite.play(animation_name)


func _play_camera_danger_effect() -> void:
	var cameras := get_tree().get_nodes_in_group("game_camera")

	for camera in cameras:
		if camera.has_method("shake"):
			camera.shake(0.20, 9.0)

		if camera.has_method("pulse_zoom"):
			camera.pulse_zoom(Vector2(1.55, 1.55), 0.08, 0.18)

extends AnimatedSprite2D

@export var idle_animation: StringName = "idle"
@export var open_animation: StringName = "open"
@export var close_animation: StringName = "close"

@export_group("Idle Movement")
@export var idle_motion_enabled: bool = true
@export var bob_amount: float = 3.0
@export var bob_speed: float = 3.2
@export var pulse_amount: float = 0.04
@export var pulse_speed: float = 2.6

var start_position: Vector2
var start_scale: Vector2
var transition_playing := false


func _ready() -> void:
	start_position = position
	start_scale = scale
	play_idle()


func _process(_delta: float) -> void:
	if not idle_motion_enabled:
		return

	if transition_playing:
		return

	var time := Time.get_ticks_msec() / 1000.0

	position = start_position + Vector2(
		0.0,
		sin(time * bob_speed) * bob_amount
	)

	var pulse := 1.0 + sin(time * pulse_speed) * pulse_amount
	scale = start_scale * pulse


func play_idle() -> void:
	if sprite_frames == null:
		return

	visible = true
	transition_playing = false

	if sprite_frames.has_animation(idle_animation):
		play(idle_animation)
	else:
		var animations := sprite_frames.get_animation_names()
		if animations.size() > 0:
			play(animations[0])


func play_open() -> void:
	if sprite_frames == null:
		return

	visible = true
	transition_playing = true
	position = start_position
	scale = start_scale

	if sprite_frames.has_animation(open_animation):
		play(open_animation)
		await animation_finished

	play_idle()


func play_close() -> void:
	if sprite_frames == null:
		return

	visible = true
	transition_playing = true
	position = start_position
	scale = start_scale

	if sprite_frames.has_animation(close_animation):
		play(close_animation)
		await animation_finished

	play_idle()

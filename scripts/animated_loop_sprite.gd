extends AnimatedSprite2D

@export var animation_to_play: StringName = "idle"


func _ready() -> void:
	if sprite_frames == null:
		return

	if sprite_frames.has_animation(animation_to_play):
		play(animation_to_play)
		return

	var animations := sprite_frames.get_animation_names()

	if animations.size() > 0:
		play(animations[0])

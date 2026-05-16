extends Node2D

@export var offset_when_player_faces_right := Vector2(-45, -42)
@export var offset_when_player_faces_left := Vector2(45, -42)

@export var follow_speed := 8.0
@export var bob_amount := 5.0
@export var bob_speed := 4.5

@onready var pet_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: CharacterBody2D


func _ready() -> void:
	top_level = true
	player = get_parent() as CharacterBody2D

	if pet_sprite != null:
		pet_sprite.play("float")

	if player != null:
		global_position = player.global_position + offset_when_player_faces_left


func _process(delta: float) -> void:
	if player == null:
		return

	var player_sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	var offset := offset_when_player_faces_left

	if player_sprite != null and player_sprite.flip_h:
		offset = offset_when_player_faces_right

	var time := Time.get_ticks_msec() / 1000.0
	var floating := Vector2(0, sin(time * bob_speed) * bob_amount)

	var target_position := player.global_position + offset + floating

	global_position = global_position.lerp(
		target_position,
		min(follow_speed * delta, 1.0)
	)

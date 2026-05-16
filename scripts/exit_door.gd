extends Area2D

@onready var level_manager: Node = $"../../LevelManager"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return

	if level_manager.has_method("on_exit_door_touched"):
		level_manager.on_exit_door_touched(body)

extends Area2D

@export var approach_duration: float = 0.35
@export var blink_count: int = 6
@export var blink_interval: float = 0.08
@export var close_delay: float = 0.10
@export var door_open_fps: float = 10.0
@export var door_close_fps: float = 10.0

@onready var level_manager: Node = $"../../LevelManager"
@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem
@onready var door_sprite: AnimatedSprite2D = get_node_or_null("DoorSprite") as AnimatedSprite2D
@onready var open_range: Area2D = get_node_or_null("OpenRange") as Area2D

var final_animation_running := false
var player_in_open_range := false
var door_is_open := false
var door_is_animating := false

var queued_open_after_animation := false
var queued_close_after_animation := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if open_range != null:
		open_range.body_entered.connect(_on_open_range_body_entered)
		open_range.body_exited.connect(_on_open_range_body_exited)
	else:
		print("ExitDoor: OpenRange não encontrado. Crie um Area2D filho chamado OpenRange.")

	if visual != null:
		visual.visible = false

	_configure_door_animations()
	_show_closed_frame()


func _on_open_range_body_entered(body: Node) -> void:
	if body.name != "Player":
		return

	player_in_open_range = true

	if final_animation_running:
		return

	await _open_door()


func _on_open_range_body_exited(body: Node) -> void:
	if body.name != "Player":
		return

	player_in_open_range = false

	if final_animation_running:
		return

	await _close_door_if_needed()


func _on_body_entered(body: Node) -> void:
	if final_animation_running:
		return

	if body.name != "Player":
		return

	var is_returning := false

	if level_manager != null:
		is_returning = bool(level_manager.get("returning"))

	# Primeira vez: porta falsa.
	# Só chama o LevelManager para mandar o jogador voltar ao início.
	if not is_returning:
		if level_manager != null and level_manager.has_method("on_exit_door_touched"):
			level_manager.on_exit_door_touched(body)
			await get_tree().process_frame
			_reset_door_after_fake_use()
		else:
			print("ExitDoor: LevelManager não encontrado ou método on_exit_door_touched não existe.")
		return

	# Segunda vez: porta final verdadeira.
	final_animation_running = true
	set_deferred("monitoring", false)

	if open_range != null:
		open_range.set_deferred("monitoring", false)

	await _handle_final_door_enter(body)


func _handle_final_door_enter(player: Node) -> void:
	if player.has_method("lock_movement"):
		player.lock_movement()

	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO

	await _ensure_door_open_for_final()

	await _move_player_to_door(player)
	await _blink_and_hide_player_and_pet(player)

	await get_tree().create_timer(close_delay).timeout

	await _close_door_force()

	if level_manager != null and level_manager.has_method("on_exit_door_touched"):
		level_manager.on_exit_door_touched(player)
	else:
		print("ExitDoor: LevelManager não encontrado ou método on_exit_door_touched não existe.")


func _move_player_to_door(player: Node) -> void:
	if player == null:
		return

	var tween := create_tween()
	tween.tween_property(
		player,
		"global_position:x",
		global_position.x,
		approach_duration
	)

	await tween.finished


func _blink_and_hide_player_and_pet(player: Node) -> void:
	var pet := player.get_node_or_null("Pet")

	for i in range(blink_count):
		_set_canvas_visible(player, false)
		_set_canvas_visible(pet, false)
		await get_tree().create_timer(blink_interval).timeout

		_set_canvas_visible(player, true)
		_set_canvas_visible(pet, true)
		await get_tree().create_timer(blink_interval).timeout

	_set_canvas_visible(player, false)
	_set_canvas_visible(pet, false)


func _set_canvas_visible(node: Node, value: bool) -> void:
	if node == null:
		return

	if node is CanvasItem:
		(node as CanvasItem).visible = value


func _open_door() -> void:
	queued_close_after_animation = false

	if door_is_open:
		_play_idle_open()
		return

	if door_is_animating:
		queued_open_after_animation = true
		return

	if not _door_is_ready():
		return

	if not door_sprite.sprite_frames.has_animation("open"):
		print("ExitDoor: animação 'open' não existe.")
		return

	queued_open_after_animation = false
	door_is_animating = true

	door_sprite.visible = true
	door_sprite.sprite_frames.set_animation_loop("open", false)
	door_sprite.sprite_frames.set_animation_speed("open", door_open_fps)

	door_sprite.stop()
	door_sprite.animation = "open"
	door_sprite.frame = 0
	door_sprite.play("open")

	await door_sprite.animation_finished

	door_is_animating = false
	door_is_open = true

	_play_idle_open()

	# Se o jogador saiu do range enquanto a porta abria, fecha em seguida.
	if not player_in_open_range and not final_animation_running:
		await _close_door_force()


func _close_door_if_needed() -> void:
	if final_animation_running:
		return

	if player_in_open_range:
		return

	if door_is_animating:
		queued_close_after_animation = true
		queued_open_after_animation = false
		return

	await _close_door_force()


func _close_door_force() -> void:
	queued_open_after_animation = false

	if door_is_animating:
		queued_close_after_animation = true
		return

	if not _door_is_ready():
		return

	if not door_is_open:
		_show_closed_frame()
		return

	if not door_sprite.sprite_frames.has_animation("close"):
		print("ExitDoor: animação 'close' não existe.")
		return

	queued_close_after_animation = false
	door_is_animating = true

	door_sprite.visible = true
	door_sprite.sprite_frames.set_animation_loop("close", false)
	door_sprite.sprite_frames.set_animation_speed("close", door_close_fps)

	door_sprite.stop()
	door_sprite.animation = "close"
	door_sprite.frame = 0
	door_sprite.play("close")

	await door_sprite.animation_finished

	door_is_animating = false
	door_is_open = false

	_show_closed_frame()

	# Correção principal:
	# Se o jogador voltou para o range enquanto a porta estava fechando,
	# abre de novo assim que terminar de fechar.
	if player_in_open_range and not final_animation_running:
		await _open_door()


func _ensure_door_open_for_final() -> void:
	while door_is_animating:
		await get_tree().process_frame

	if door_is_open:
		_play_idle_open()
		return

	await _open_door()


func _play_idle_open() -> void:
	if not _door_is_ready():
		return

	if door_sprite.sprite_frames.has_animation("idle_open"):
		door_sprite.visible = true
		door_sprite.sprite_frames.set_animation_loop("idle_open", true)
		door_sprite.sprite_frames.set_animation_speed("idle_open", 1.0)
		door_sprite.play("idle_open")


func _show_closed_frame() -> void:
	if not _door_is_ready():
		return

	door_sprite.visible = true
	door_sprite.stop()

	if door_sprite.sprite_frames.has_animation("open"):
		door_sprite.animation = "open"
		door_sprite.frame = 0
		door_is_open = false
		return

	if door_sprite.sprite_frames.has_animation("close"):
		var frame_count := door_sprite.sprite_frames.get_frame_count("close")

		if frame_count > 0:
			door_sprite.animation = "close"
			door_sprite.frame = frame_count - 1
			door_is_open = false


func _reset_door_after_fake_use() -> void:
	final_animation_running = false
	player_in_open_range = false
	door_is_animating = false
	door_is_open = false
	queued_open_after_animation = false
	queued_close_after_animation = false

	_show_closed_frame()

	if open_range != null:
		open_range.set_deferred("monitoring", true)

	set_deferred("monitoring", true)


func _configure_door_animations() -> void:
	if not _door_is_ready():
		return

	if door_sprite.sprite_frames.has_animation("open"):
		door_sprite.sprite_frames.set_animation_loop("open", false)
		door_sprite.sprite_frames.set_animation_speed("open", door_open_fps)

	if door_sprite.sprite_frames.has_animation("close"):
		door_sprite.sprite_frames.set_animation_loop("close", false)
		door_sprite.sprite_frames.set_animation_speed("close", door_close_fps)

	if door_sprite.sprite_frames.has_animation("idle_open"):
		door_sprite.sprite_frames.set_animation_loop("idle_open", true)
		door_sprite.sprite_frames.set_animation_speed("idle_open", 1.0)


func _door_is_ready() -> bool:
	if door_sprite == null:
		print("ExitDoor: DoorSprite não encontrado. Renomeie o AnimatedSprite2D para DoorSprite.")
		return false

	if door_sprite.sprite_frames == null:
		print("ExitDoor: DoorSprite está sem SpriteFrames.")
		return false

	return true

extends Node

@export_file("*.tscn") var next_phase_scene_path: String = ""
@export var end_death_block_offset_x: float = 30.0
@export var intro_camera_offset: Vector2 = Vector2(0, -90)
@export var return_hint_time: float = 2.8
@export var death_reload_delay: float = 1.35

@onready var player: CharacterBody2D = $"../Player"
@onready var game_camera: Camera2D = $"../Player/Camera2D"

@onready var exit_door: Area2D = $"../World/ExitDoor"
@onready var final_door_marker: Marker2D = $"../World/Markers/FinalDoorMarker"
@onready var start_door_marker: Marker2D = $"../World/Markers/StartDoorMarker"

@onready var end_death_block: Area2D = $"../World/EndDeathBlock"

@onready var trigger_left: Area2D = $"../World/TriggerLeft"
@onready var trigger_right: Area2D = $"../World/TriggerRight"

@onready var complete_label: Label = $"../UI/CompleteLabel"
@onready var return_hint_label: Label = $"../UI/ReturnHintLabel"
@onready var death_label: Label = $"../UI/DeathLabel"

@onready var end_menu: Control = $"../UI/EndMenu"
@onready var repeat_tutorial_button: Button = $"../UI/EndMenu/RepeatTutorialButton"
@onready var next_phase_button: Button = $"../UI/EndMenu/NextPhaseButton"
@onready var quit_button: Button = $"../UI/EndMenu/QuitButton"

var returning := false
var phase_finished := false
var player_died := false

var death_messages := [
	"Você morreu.",
	"A caverna ganhou essa rodada.",
	"Tutorial: 1 | Jogador: 0",
	"Quase... só que não."
]

func _ready() -> void:
	randomize()

	exit_door.global_position = final_door_marker.global_position

	end_death_block.global_position = final_door_marker.global_position + Vector2(end_death_block_offset_x, 0)

	if end_death_block.has_method("deactivate"):
		end_death_block.deactivate()

	if trigger_left.has_method("set_active"):
		trigger_left.set_active(true)

	if trigger_right.has_method("set_active"):
		trigger_right.set_active(false)

	complete_label.visible = false
	return_hint_label.visible = false
	death_label.visible = false
	end_menu.visible = false
	next_phase_button.visible = not next_phase_scene_path.is_empty()

	repeat_tutorial_button.pressed.connect(_on_repeat_tutorial_pressed)
	next_phase_button.pressed.connect(_on_next_phase_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	if player.has_method("lock_movement"):
		player.lock_movement()

	call_deferred("_play_intro_camera_sequence")

func _play_intro_camera_sequence() -> void:
	await get_tree().process_frame

	if phase_finished or player_died:
		return

	if game_camera.has_method("play_intro_pan"):
		var camera_target := final_door_marker.global_position + intro_camera_offset
		await game_camera.play_intro_pan(camera_target)

	if phase_finished or player_died:
		return

	if player.has_method("unlock_movement"):
		player.unlock_movement()

func on_exit_door_touched(_player_body: Node) -> void:
	if phase_finished or player_died:
		return

	if not returning:
		start_return_mode()
	else:
		complete_phase()

func start_return_mode() -> void:
	returning = true

	exit_door.global_position = start_door_marker.global_position

	end_death_block.global_position = final_door_marker.global_position + Vector2(end_death_block_offset_x, 0)

	if end_death_block.has_method("activate"):
		end_death_block.activate()

	if trigger_left.has_method("set_active"):
		trigger_left.set_active(false)

	if trigger_right.has_method("set_active"):
		trigger_right.set_active(true)

	_play_door_camera_effect()
	_show_return_hint()

	print("Porta falsa ativada. Agora volte para o início.")

func _show_return_hint() -> void:
	return_hint_label.text = "A porta era falsa... volte para o início!"
	return_hint_label.visible = true

	await get_tree().create_timer(return_hint_time).timeout

	if returning and not phase_finished and not player_died:
		return_hint_label.visible = false

func complete_phase() -> void:
	if player_died:
		return

	phase_finished = true

	return_hint_label.visible = false
	death_label.visible = false

	complete_label.visible = true
	end_menu.visible = true

	if player.has_method("lock_movement"):
		player.lock_movement()

	if trigger_left.has_method("set_active"):
		trigger_left.set_active(false)

	if trigger_right.has_method("set_active"):
		trigger_right.set_active(false)

	if game_camera.has_method("pulse_zoom"):
		game_camera.pulse_zoom(Vector2(1.65, 1.65), 0.12, 0.25)

	print("Fase concluída!")

func on_player_died(player_body: Node) -> void:
	if player_died or phase_finished:
		return

	player_died = true

	return_hint_label.visible = false
	complete_label.visible = false
	end_menu.visible = false

	if player_body.has_method("lock_movement"):
		player_body.lock_movement()

	death_label.text = death_messages.pick_random()
	death_label.visible = true

	if game_camera.has_method("shake"):
		game_camera.shake(0.18, 7.0)

	await get_tree().create_timer(death_reload_delay).timeout

	get_tree().reload_current_scene()

func _play_door_camera_effect() -> void:
	if game_camera.has_method("zoom_out_temporarily"):
		game_camera.zoom_out_temporarily(Vector2(1.05, 1.05), 0.45)

	if game_camera.has_method("shake"):
		game_camera.shake(0.12, 4.0)

func _on_repeat_tutorial_pressed() -> void:
	get_tree().reload_current_scene()

func _on_next_phase_pressed() -> void:
	if next_phase_scene_path.is_empty():
		print("Próxima fase ainda não foi implementada.")
		return

	get_tree().change_scene_to_file(next_phase_scene_path)

func _on_quit_pressed() -> void:
	get_tree().quit()

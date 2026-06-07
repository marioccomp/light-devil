extends Node

@export_file("*.tscn") var next_phase_scene_path: String = ""
@export var death_reload_delay: float = 1.35
@export var play_intro_camera: bool = true
@export var intro_camera_offset: Vector2 = Vector2(650, -90)
@onready var rune_hint_label: Label = get_tree().current_scene.get_node_or_null("UI/RuneHintLabel") as Label

@onready var player: CharacterBody2D = $"../Player"
@onready var game_camera: Camera2D = $"../Player/Camera2D"

@onready var complete_label: Label = $"../UI/CompleteLabel"
@onready var return_hint_label: Label = $"../UI/ReturnHintLabel"
@onready var death_label: Label = $"../UI/DeathLabel"

@onready var end_menu: Control = $"../UI/EndMenu"
@onready var repeat_tutorial_button: Button = $"../UI/EndMenu/RepeatTutorialButton"
@onready var next_phase_button: Button = $"../UI/EndMenu/NextPhaseButton"
@onready var quit_button: Button = $"../UI/EndMenu/QuitButton"

var returning := true
var phase_finished := false
var player_died := false

var death_messages := [
	"Você morreu.",
	"A prisão ganhou essa rodada.",
	"A sombra te alcançou.",
	"Quase... só que não."
]


func _ready() -> void:
	call_deferred("_show_pending_death_hint")
	randomize()

	complete_label.visible = false
	return_hint_label.visible = false
	death_label.visible = false
	end_menu.visible = false

	next_phase_button.visible = not next_phase_scene_path.is_empty()

	repeat_tutorial_button.pressed.connect(_on_repeat_pressed)
	next_phase_button.pressed.connect(_on_next_phase_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	if player.has_method("lock_movement"):
		player.lock_movement()

	call_deferred("_start_level")


func _start_level() -> void:
	await get_tree().process_frame

	if player_died or phase_finished:
		return

	var intro_key := "level_02_intro_already_played"
	var should_play_intro := play_intro_camera and not get_tree().has_meta(intro_key)

	if should_play_intro:
		get_tree().set_meta(intro_key, true)

		if game_camera != null and game_camera.has_method("play_intro_pan"):
			var target_position := player.global_position + intro_camera_offset
			await game_camera.play_intro_pan(target_position)

	if player.has_method("unlock_movement"):
		player.unlock_movement()


func on_exit_door_touched(_player_body: Node) -> void:
	complete_phase()


func complete_phase() -> void:
	if phase_finished or player_died:
		return

	phase_finished = true

	return_hint_label.visible = false
	death_label.visible = false

	complete_label.visible = true
	end_menu.visible = true

	if player.has_method("lock_movement"):
		player.lock_movement()

	if game_camera != null and game_camera.has_method("pulse_zoom"):
		game_camera.pulse_zoom(Vector2(1.65, 1.65), 0.12, 0.25)

	print("Fase 2 concluída!")


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

	if game_camera != null and game_camera.has_method("shake"):
		game_camera.shake(0.18, 7.0)

	await get_tree().create_timer(death_reload_delay).timeout

	get_tree().reload_current_scene()


func _on_repeat_pressed() -> void:
	get_tree().reload_current_scene()


func _on_next_phase_pressed() -> void:
	if next_phase_scene_path.is_empty():
		print("Próxima fase ainda não foi implementada.")
		return

	get_tree().change_scene_to_file(next_phase_scene_path)


func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _show_pending_death_hint() -> void:
	await get_tree().process_frame

	var hint_text := str(get_tree().get_meta("pending_death_hint", ""))

	if hint_text == "":
		return

	get_tree().remove_meta("pending_death_hint")

	if rune_hint_label == null:
		return

	rune_hint_label.text = hint_text
	rune_hint_label.visible = true
	rune_hint_label.modulate.a = 0.0

	var tween_in := create_tween()
	tween_in.tween_property(rune_hint_label, "modulate:a", 1.0, 0.20)

	await tween_in.finished
	await get_tree().create_timer(3.0).timeout

	if rune_hint_label == null:
		return

	var tween_out := create_tween()
	tween_out.tween_property(rune_hint_label, "modulate:a", 0.0, 0.25)

	await tween_out.finished

	if rune_hint_label != null:
		rune_hint_label.visible = false

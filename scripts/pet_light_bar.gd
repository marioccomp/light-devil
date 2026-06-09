extends ProgressBar

@export var percent_label_path: NodePath
@export var status_label_path: NodePath
@export var warning_label_path: NodePath

@onready var percent_label: Label = get_node_or_null(percent_label_path) as Label
@onready var status_label: Label = get_node_or_null(status_label_path) as Label
@onready var warning_label: Label = get_node_or_null(warning_label_path) as Label

var pet: Node = null
var previous_light_percent: float = -1.0
var warning_timer: float = 0.0


func _ready() -> void:
	min_value = 0
	max_value = 100
	value = 100

	if warning_label != null:
		warning_label.visible = false


func _process(delta: float) -> void:
	if pet == null:
		var current_scene: Node = get_tree().current_scene

		if current_scene == null:
			return

		var player: Node = current_scene.get_node_or_null("Player")

		if player == null:
			return

		pet = player.get_node_or_null("Pet")

	if pet == null:
		return

	if not pet.has_method("get_light_power"):
		return

	var light_percent: float = float(pet.get_light_power()) * 100.0

	value = light_percent

	if percent_label != null:
		percent_label.text = str(roundi(light_percent)) + "%"

	var is_losing_light: bool = false

	if previous_light_percent >= 0.0:
		is_losing_light = light_percent < previous_light_percent - 0.05

	if is_losing_light:
		warning_timer = 0.35

	if warning_timer > 0.0:
		warning_timer -= delta

	if warning_label != null:
		warning_label.visible = warning_timer > 0.0

	if status_label != null:
		if warning_timer > 0.0:
			status_label.text = "Luz drenando"
		elif light_percent < 35.0:
			status_label.text = "Luz fraca"
		elif light_percent < 70.0:
			status_label.text = "Luz media"
		else:
			status_label.text = "Luz forte"

	previous_light_percent = light_percent

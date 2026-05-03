extends Control

@export var trajectory_button: Button
@export var hand_button: Button
@export var practice_shots_label: Label
@export var measured_shots_label: Label

func _ready() -> void:
	set_button_text()

func set_button_text():
	trajectory_button.text = "Enabled" if ExperimentManager.using_trajectory else "Disabled"
	hand_button.text = "Right" if ExperimentManager.using_right_hand else "Left"
	practice_shots_label.text = str(ExperimentManager.shot_count_practice)
	measured_shots_label.text = str(ExperimentManager.shot_count_measured)


func _on_trajectory_button_pressed() -> void:
	ExperimentManager._toggle_using_trajectory()
	set_button_text()


func _on_hand_button_pressed() -> void:
	ExperimentManager._toggle_using_right_hand()
	set_button_text()


func _on_start_button_pressed() -> void:
	ExperimentManager._start_experiment()

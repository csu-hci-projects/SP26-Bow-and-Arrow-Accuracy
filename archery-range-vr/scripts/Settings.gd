extends Control

@export var trajectory_button: Button
@export var hand_button: Button
@export var practice_shots_label: Label
@export var measured_shots_label: Label
@export var name_edit: LineEdit

func _ready() -> void:
	trajectory_button = $VBoxContainer/GridContainer/trajectory_button
	hand_button = $VBoxContainer/GridContainer/hand_button
	practice_shots_label = $VBoxContainer/GridContainer/practice
	measured_shots_label = $VBoxContainer/GridContainer/measured
	name_edit = $VBoxContainer/GridContainer/LineEdit
	set_button_text()


func set_button_text():
	if not is_node_ready():
		await ready
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
	ExperimentManager.subject_name = name_edit.text
	ExperimentManager._start_experiment()

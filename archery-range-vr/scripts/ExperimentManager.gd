extends Node

var using_trajectory: bool = true
var trajectory_resource: BowSettingItem = load("res://settings/trajectory.tres")
var using_right_hand: bool = true
var hand_resource: BowSettingItem = load("res://settings/right_handed.tres")

var target_distances: Array[float] = [
	12.0,
	24.0,
	36.0
]
var shot_count_practice: int = 5
var shot_count_measured: int = 5

var experiment_scene: PackedScene = preload("res://scenes/game.tscn")

var current_shot_count: int = 0
var current_distance: int = 0

signal change_distance(distance: float)

func _toggle_using_trajectory():
	using_trajectory = !using_trajectory
	trajectory_resource.enabled = using_trajectory

func _toggle_using_right_hand():
	using_right_hand = !using_right_hand
	hand_resource.enabled = using_right_hand

func _start_experiment():
	if experiment_scene:
		get_tree().change_scene_to_packed(experiment_scene)

func _take_shot() -> int:
	current_shot_count += 1
	return current_shot_count

func _on_hit(shot_id: int, distance: float, distance_normal: float, distance_x: float = 0, distance_y: float = 0):
	current_shot_count += 1
	
	save_to_csv([
		shot_id,
		"practice",
		target_distances[current_distance],
		("yes" if using_trajectory else "no"),
		("right" if using_right_hand else "left"),
		distance,
		distance_x,
		distance_y,
		0.0
	])
	
	if current_shot_count / shot_count_measured > current_distance:
		current_distance += 1
		if current_distance < target_distances.size():
			change_distance.emit(target_distances[current_distance])


func save_to_csv(data_row: Array):
	var file_path = "user://experiment_results.csv"
	var file_exists = FileAccess.file_exists(file_path)
	
	var file = FileAccess.open(file_path, FileAccess.READ_WRITE if file_exists else FileAccess.WRITE)
	
	if not file:
		print("Error opening CSV file: ", FileAccess.get_open_error())
		return

	if not file_exists:
		var headers = [
			"shot_id", 
			"shot_type", 
			"target_distance", 
			"using_trajectory", 
			"hand", 
			"accuracy",
			"vertical_accuracy", 
			"horizontal_accuracy",
			"aim_time"
		]
		file.store_line(",".join(headers))
	else:
		file.seek_end()

	var line = ",".join(data_row)
	file.store_line(line)
	file.close()

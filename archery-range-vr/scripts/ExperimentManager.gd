extends Node

var subject_name: String = ""
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

var settings_scene: PackedScene = preload("res://scenes/settings.tscn")
var experiment_scene: PackedScene = preload("res://scenes/game.tscn")

var current_shot_count: int = 0
var current_distance: int = 0
var pull_start_time: int = 0
var pull_time: int = 0

var is_practice: bool = true
var is_waiting: bool = false
var is_shooting: bool = false

signal change_distance(distance: float)
signal setting_changed(item: BowSettingItem)

func _toggle_using_trajectory():
	using_trajectory = !using_trajectory
	trajectory_resource.enabled = using_trajectory


func _toggle_using_right_hand():
	using_right_hand = !using_right_hand
	hand_resource.enabled = using_right_hand


func _start_experiment():
	if experiment_scene:
		get_tree().change_scene_to_packed(experiment_scene)


func _end_experiment():
	if experiment_scene:
		subject_name = ""
		using_trajectory = true
		using_right_hand = true
		current_shot_count = 0
		current_distance = 0
		pull_start_time = 0
		pull_time = 0
		is_practice = true
		is_waiting = false
		is_shooting = false

		trajectory_resource = load("res://settings/trajectory.tres")
		hand_resource = load("res://settings/right_handed.tres")
		
		get_tree().change_scene_to_packed(settings_scene)


func _take_shot() -> int:
	current_shot_count += 1
	return current_shot_count


func clean_arrows():
	for arrow in get_tree().get_nodes_in_group("arrow"):
		arrow.queue_free()


func released():
	pull_time = Time.get_ticks_msec() - ExperimentManager.pull_start_time
	pull_start_time = 0
	is_shooting = true


func check_waiting():
	if current_shot_count % shot_count_measured == 0:
		is_waiting = true
		await get_tree().create_timer(1.0).timeout
		is_waiting = false


func _on_hit(shot_id: int, distance: float, distance_normal: float, distance_x: float = 0, distance_y: float = 0):
	is_shooting = false
	check_waiting()
	
	save_to_csv([
		shot_id,
		"practice" if is_practice else "measured",
		target_distances[current_distance],
		"yes" if using_trajectory else "no",
		"right" if using_right_hand else "left",
		distance,
		distance_x,
		distance_y,
		pull_time
	])
	pull_time = 0
	
	if current_shot_count / shot_count_measured > current_distance:
		await get_tree().create_timer(.6).timeout
		current_distance += 1
		clean_arrows()
		
		if current_distance < target_distances.size():
			change_distance.emit(target_distances[current_distance])
		else:
			if is_practice:
				is_practice = false
				current_shot_count = 0
				current_distance = 0
				change_distance.emit(target_distances[current_distance])
				using_trajectory = false
				trajectory_resource.enabled = false
				setting_changed.emit(trajectory_resource)
			else:
				_end_experiment()


func save_to_csv(data_row: Array):
	var file_path = "user://experiment_results_"+subject_name+".csv"
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

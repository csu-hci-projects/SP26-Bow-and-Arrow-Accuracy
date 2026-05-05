extends Node

var participant_id: String = ""
var using_trajectory: bool = true
var trajectory_resource: BowSettingItem = load("res://settings/trajectory.tres")
var using_right_hand: bool = true
var hand_resource: BowSettingItem = load("res://settings/right_handed.tres")

var target_distances: Array[float] = [
	10.0,
	20.0,
	30.0
]
var shot_count_practice: int = 5
var shot_count_measured: int = 5

var experiment_scene: PackedScene = preload("res://scenes/game.tscn")

var current_shot_count: int = 0
var current_distance: int = 0
var aim_start_time: float = 0.0

signal change_distance(distance: float)

func _toggle_using_trajectory():
	using_trajectory = !using_trajectory
	trajectory_resource.enabled = using_trajectory

func _toggle_using_right_hand():
	using_right_hand = !using_right_hand
	hand_resource.enabled = using_right_hand

func _start_experiment():
	var count_file = "user://participant_count.txt"
	var count: int = 1
	
	if FileAccess.file_exists(count_file):
		var f = FileAccess.open(count_file, FileAccess.READ)
		count = int(f.get_line()) + 1
		f.close()
	
	var f_write = FileAccess.open(count_file, FileAccess.WRITE)
	f_write.store_line(str(count))
	f_write.close()
	
	participant_id = "P" + str(count)
	print("Starting experiment for: ", participant_id)
	
	current_shot_count = 0
	current_distance = 0
	
	if experiment_scene:
		get_tree().change_scene_to_packed(experiment_scene)

func _take_shot() -> int:
	aim_start_time = Time.get_ticks_msec() / 1000.0
	return current_shot_count + 1

func _on_hit(shot_id: int, distance: float, distance_normal: float, distance_x: float = 0, distance_y: float = 0):
	current_shot_count += 1
	
	var shot_type: String = "practice"
	if current_shot_count > shot_count_practice:
		shot_type = "measured"
	
	var aim_end_time: float = Time.get_ticks_msec() / 1000.0
	var aim_time: float = aim_end_time - aim_start_time
	
	var hit: String = "no"
	if distance <= 1.0:
		hit = "yes"
	
	save_to_csv([
		participant_id,
		shot_id,
		shot_type,
		target_distances[current_distance],
		("yes" if using_trajectory else "no"),
		("right" if using_right_hand else "left"),
		distance,
		distance_x,
		distance_y,
		aim_time,
		hit
	])
	
	var total_shots_for_distance: int = shot_count_practice + shot_count_measured
	
	if current_shot_count >= total_shots_for_distance:
		current_distance += 1
		current_shot_count = 0
		
		if current_distance < target_distances.size():
			change_distance.emit(target_distances[current_distance])
		else:
			print("Experiment complete for: ", participant_id)

func save_to_csv(data_row: Array):
	var file_path = "user://experiment_results.csv"
	var file_exists = FileAccess.file_exists(file_path)
	
	var file = FileAccess.open(file_path, FileAccess.READ_WRITE if file_exists else FileAccess.WRITE)
	
	if not file:
		print("Error opening CSV file: ", FileAccess.get_open_error())
		return

	if not file_exists:
		var headers = [
			"participant_id",
			"shot_id", 
			"shot_type", 
			"target_distance", 
			"using_trajectory", 
			"hand", 
			"accuracy",
			"vertical_accuracy", 
			"horizontal_accuracy",
			"aim_time",
			"hit"
		]
		file.store_line(",".join(headers))
	else:
		file.seek_end()
	
	var string_row: Array[String] = []
	for item in data_row:
		string_row.append(str(item))

	var line = ",".join(string_row)
	file.store_line(line)
	file.close()

extends Node3D

@export var target: Node3D

func _ready() -> void:
	_set_target_distance(ExperimentManager.target_distances[0])
	ExperimentManager.change_distance.connect(_set_target_distance)

func _set_target_distance(distance: float):
	var tween = create_tween()

	tween.tween_property(target, "global_position:z", -distance, 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

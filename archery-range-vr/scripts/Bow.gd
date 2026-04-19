extends Node3D

@export_group("Physics")
@export var arrow: PackedScene
@export var max_velocity: float = 10

@export_group("Pivots")
@export var pivot_strength: float = 1
@export var pivot_top1: Node3D
@export var pivot_top2: Node3D
@export var pivot_bottom1: Node3D
@export var pivot_bottom2: Node3D

@export_group("References")
@export var bow_string: BowString
@export var bow_arrow: Node3D

@export_group("Audio")
@export var audio_source: AudioStreamPlayer3D
@export var pull_audio: AudioStream
@export var release_audio: AudioStream
var has_been_pulled = false

signal set_trajectory(launch_position: Vector3, launch_velocity: Vector3)
signal enable_trajectory(enabled: bool)

func _process(delta: float) -> void:
	if bow_string.target:
		bow_arrow.visible = true
		bow_arrow.global_position = bow_string.target.global_position
		bow_arrow.look_at(global_position, Vector3.UP)
	else:
		bow_arrow.visible = false

func shoot(power: float):
	var arrow_instance := arrow.instantiate() as RigidBody3D
	get_tree().root.add_child(arrow_instance)
	arrow_instance.global_transform = bow_arrow.global_transform
	arrow_instance.linear_velocity = -bow_arrow.global_transform.basis.z * power


func _on_string_pull(distance: float, power: float) -> void:
	if !has_been_pulled:
		audio_source.stream = pull_audio
		audio_source.play()
		has_been_pulled = true
	
	var bend_angle = distance * pivot_strength
	pivot_top1.rotation.x = bend_angle
	pivot_top2.rotation.x = bend_angle
	pivot_bottom1.rotation.x = -bend_angle
	pivot_bottom2.rotation.x = -bend_angle

	var velocity: Vector3 = -bow_arrow.global_transform.basis.z * power * max_velocity
	set_trajectory.emit(bow_arrow.global_position, velocity)


func _on_string_release(power: float) -> void:
	audio_source.stream = release_audio
	audio_source.play()
	has_been_pulled = false
	
	shoot(power * max_velocity)
	
	pivot_top1.rotation.x = 0
	pivot_top2.rotation.x = 0
	pivot_bottom1.rotation.x = 0
	pivot_bottom2.rotation.x = 0


func _on_bow_settings_button_toggled(item: BowSettingItem) -> void:
	if item.label == "Trajectory":
		enable_trajectory.emit(item.enabled)

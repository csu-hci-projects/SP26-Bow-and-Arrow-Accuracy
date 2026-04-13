extends Node3D

@export var arrow: PackedScene
@export var max_velocity: float = 10

@export var pivot_strength: float = 1
@export var pivot_top1: Node3D
@export var pivot_top2: Node3D
@export var pivot_bottom1: Node3D
@export var pivot_bottom2: Node3D

@export var bow_string: BowString
@export var bow_arrow: Node3D

func _process(delta: float) -> void:
	if bow_string.target:
		bow_arrow.visible = true
		bow_arrow.global_position = bow_string.target.global_position
		bow_arrow.look_at(global_position, Vector3.UP)
	else:
		bow_arrow.visible = false

func shoot(velocity: float):
	var arrow_instance := arrow.instantiate() as RigidBody3D
	get_tree().root.add_child(arrow_instance)
	arrow_instance.global_transform = bow_arrow.global_transform
	arrow_instance.linear_velocity = -bow_arrow.global_transform.basis.z * velocity


func _on_string_pull(distance: float) -> void:
	var bend_angle = distance * pivot_strength

	pivot_top1.rotation.x = bend_angle
	pivot_top2.rotation.x = bend_angle

	pivot_bottom1.rotation.x = -bend_angle
	pivot_bottom2.rotation.x = -bend_angle


func _on_string_release(power: float) -> void:
	shoot(power * max_velocity)
	
	pivot_top1.rotation.x = 0
	pivot_top2.rotation.x = 0
	pivot_bottom1.rotation.x = 0
	pivot_bottom2.rotation.x = 0

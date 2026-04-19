extends Area3D

@export var hit_point: PackedScene
@export var radius: float = 1

@export var audio_source: AudioStreamPlayer3D
@export var points_audio: Array[AudioStream]

signal on_hit_distance(distance: float, distance_normalized: float)

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is RigidBody3D:
		var plane = Plane(global_transform.basis.z, global_position)

		var hit = plane.intersects_ray(
			body.global_position,
			-body.linear_velocity.normalized()
		)
		
		var hit_pos = hit if hit else plane.project(body.global_position)
		
		body.global_position = hit_pos
		body.on_hit(0)
		
		var new_hit_point = hit_point.instantiate() as Node3D
		new_hit_point.position = to_local(hit_pos)
		add_child(new_hit_point)

		var local_hit = to_local(hit_pos)
		var distance = Vector2(local_hit.x, local_hit.y).length()
		var distance_normal = distance / radius

		on_hit_distance.emit(distance, distance_normal)
		
		var x = clampi(roundi(distance_normal * (points_audio.size() - 1)), 0, points_audio.size() - 1)
		audio_source.stream = points_audio[x]
		audio_source.play()

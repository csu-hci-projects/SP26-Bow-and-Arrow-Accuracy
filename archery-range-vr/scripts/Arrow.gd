extends RigidBody3D

@export var monitoring: bool = true
@export var visuals: Node3D
@export var collision: Node3D

@export var audio_source: AudioStreamPlayer3D
@export var hit_audio: Array[AudioStream]

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if monitoring:
		if linear_velocity.length() > 0.1:
			visuals.look_at(global_position + linear_velocity, Vector3.UP)
			visuals.rotate_object_local(Vector3.RIGHT, PI / 2)
			collision.look_at(global_position + linear_velocity, Vector3.UP)
			collision.rotate_object_local(Vector3.RIGHT, PI / 2)

func _on_body_entered(body: Node) -> void:
	if monitoring:
		on_hit(1)

func on_hit(hit_sound: int = 0):
	audio_source.stream = hit_audio[hit_sound]
	audio_source.play()
	monitoring = false
	freeze = true

extends RigidBody3D

@export var monitoring: bool = true
@export var visuals: Node3D
@export var collision: Node3D

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
		monitoring = false
		freeze = true

@tool
class_name FunctionPull
extends XRToolsHandPalmOffset

const DEFAULT_GRAB_MASK := 0b0000_0000_0000_0000_0000_0000_0000_0100

## Grip controller axis
@export var pickup_axis_action : String = "grip"
## Grab distance
@export var grab_distance : float = 0.3
## Grab collision mask
@export_flags_3d_physics var grab_collision_mask : int = DEFAULT_GRAB_MASK

# Public fields
var closest_object : Node3D = null
var picked_up_object : Node3D = null
var picked_up_ranged : bool = false
var grip_pressed : bool = false

# Private fields
var _object_in_grab_area := Array()
var _grab_area : Area3D
var _grab_collision : CollisionShape3D
var _current_target : Node = null

## Grip threshold (from configuration)
@onready var _grip_threshold : float = XRTools.get_grip_threshold()

signal grip_grabbed(target: Node)
signal grip_released(target: Node)

func _ready() -> void:
	_grab_collision = CollisionShape3D.new()
	_grab_collision.set_name("GrabCollisionShape")
	_grab_collision.shape = SphereShape3D.new()
	_grab_collision.shape.radius = grab_distance
	_grab_area = Area3D.new()
	_grab_area.set_name("GrabArea")
	_grab_area.collision_layer = 0
	_grab_area.collision_mask = grab_collision_mask
	_grab_area.add_child(_grab_collision)
	_grab_area.area_entered.connect(_on_grab_entered)
	_grab_area.body_entered.connect(_on_grab_entered)
	_grab_area.area_exited.connect(_on_grab_exited)
	_grab_area.body_exited.connect(_on_grab_exited)
	add_child(_grab_area)

func _process(_delta):
	closest_object = _get_closest_object()

	var grip_value = _controller.get_float(pickup_axis_action)
	if grip_pressed and grip_value < (_grip_threshold - 0.1):
		grip_pressed = false
		_on_grip_release()
	elif not grip_pressed and grip_value > (_grip_threshold + 0.1):
		grip_pressed = true
		_on_grip_pressed()

func _get_closest_object() -> Node3D:
	var closest : Node3D = null
	var closest_dist : float = INF

	for obj in _object_in_grab_area:
		var dist = global_position.distance_to(obj.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = obj

	return closest

func _on_grab_entered(target: Node3D) -> void:
	if not target.has_method("on_grabbed"):
		return
	if _object_in_grab_area.find(target) >= 0:
		return
	_object_in_grab_area.push_back(target)

func _on_grab_exited(target: Node3D) -> void:
	_object_in_grab_area.erase(target)

func _set_grab_collision_mask(new_value: int) -> void:
	grab_collision_mask = new_value
	if is_inside_tree() and _grab_area:
		_grab_area.collision_mask = new_value

func _on_grip_pressed() -> void:
	_current_target = _get_closest_object()
	if _current_target:
		emit_signal("grip_grabbed", _current_target)
		if _current_target.has_method("on_grabbed"):
			_current_target.on_grabbed(self)

func _on_grip_release() -> void:
	if _current_target:
		emit_signal("grip_released", _current_target)
		if _current_target.has_method("on_released"):
			_current_target.on_released(self)
		_current_target = null

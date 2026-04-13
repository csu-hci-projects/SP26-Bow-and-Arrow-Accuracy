extends Node3D

@export var enabled: bool = true

var bow_string: BowString
@export var start_position: Vector3
@export var end_position: Vector3
@export var pull_speed: float = 1.0

var _holding: bool = false
var _pull_t: float = 0.0

func _ready() -> void:
	bow_string = get_tree().root.find_child("string", true, false)

func _process(delta: float) -> void:
	if not enabled:
		return
	
	if _holding:
		_pull_t = move_toward(_pull_t, 1.0, pull_speed * delta)
		position = start_position.lerp(end_position, _pull_t)
		bow_string.on_grabbed(self)

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	
	if event is InputEventKey and event.keycode == KEY_W:
		if event.pressed and not event.echo:
			_on_w_pressed()
		elif not event.pressed:
			_on_w_released()

func _on_w_pressed() -> void:
	_holding = true

func _on_w_released() -> void:
	_holding = false
	_pull_t = 0.0
	position = start_position
	bow_string.on_released(self)

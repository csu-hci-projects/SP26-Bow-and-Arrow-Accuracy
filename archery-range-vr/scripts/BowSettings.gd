extends XRToolsHandPalmOffset

@export var settings: Array[BowSettingItem] = []
@export var label: Label3D
@export var label_parent: Node3D
@export var label_visibility_length: float = 5

var label_visibility_timer: float

signal button_toggled(item: BowSettingItem)

const BUTTON_ACTION_MAP = {
	BowSettingItem.BUTTON_NAME.AX: "ax_button",
	BowSettingItem.BUTTON_NAME.BY: "by_button"
}

func _ready():
	reconnect_controller()
	for item in settings:
		button_toggled.emit(item)
	set_label()

func reconnect_controller():
	if _controller and _controller.button_pressed.is_connected(_on_button_pressed):
		_controller.button_pressed.disconnect(_on_button_pressed)
	# XRToolsHandPalmOffset resolves _controller from its parent hierarchy
	# so call the parent ready logic to refresh it first
	await owner.get_tree().process_frame
	_controller.button_pressed.connect(_on_button_pressed)

func _process(_delta):
	if label_visibility_timer <= 0:
		label_parent.visible = false
	else:
		label_visibility_timer -= _delta

func _on_button_pressed(button: String):
	for item in settings:
		if BUTTON_ACTION_MAP[item.button] == button:
			item.enabled = !item.enabled
			button_toggled.emit(item)
			set_label()

func set_label():
	var lines: Array[String] = []
	for item in settings:
		var state = "Enabled" if item.enabled else "Disabled"
		lines.append(item.label + ": " + state)
	label.text = "\n".join(lines)
	label_parent.visible = true
	label_visibility_timer = label_visibility_length

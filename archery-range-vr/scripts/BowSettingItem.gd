class_name BowSettingItem extends Resource

enum BUTTON_NAME {
	AX,
	BY
}

@export var enabled: bool = true
@export var label: String = ""
@export var button: BUTTON_NAME

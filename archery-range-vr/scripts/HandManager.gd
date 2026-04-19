extends Node

@export var right_hand_parent: XRController3D
@export var left_hand_parent: XRController3D

@export var right_physics_hand: XRToolsPhysicsHand
@export var left_physics_hand: XRToolsPhysicsHand

var default_hand = true

func swap_hands():
	var right_children = right_hand_parent.get_children().filter(func(n): return n != right_physics_hand)
	var left_children = left_hand_parent.get_children().filter(func(n): return n != left_physics_hand)
	
	for node in right_children:
		node.reparent.call_deferred(left_hand_parent)
	
	for node in left_children:
		node.reparent.call_deferred(right_hand_parent)
	
	await get_tree().process_frame
	
	for node in right_children:
		node.transform = Transform3D.IDENTITY
		if node.has_method("reconnect_controller"):
			node.reconnect_controller()
	
	for node in left_children:
		node.transform = Transform3D.IDENTITY
		if node.has_method("reconnect_controller"):
			node.reconnect_controller()


func _on_bow_settings_button_toggled(item: BowSettingItem) -> void:
	if item.label == "Right Handed":
		if item.enabled != default_hand:
			swap_hands()
			default_hand = item.enabled
